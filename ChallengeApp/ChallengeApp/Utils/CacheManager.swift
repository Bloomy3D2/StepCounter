//
//  CacheManager.swift
//  ChallengeApp
//
//  Менеджер кэширования данных
//

import Foundation

protocol CacheManagerProtocol {
    func get<T: Codable>(_ key: String, as type: T.Type) -> T?
    func set<T: Codable>(_ value: T, forKey key: String, ttl: TimeInterval?)
    func remove(_ key: String)
    func clear()
    func has(_ key: String) -> Bool
    
    // Convenience methods for specific types
    func cacheChallenges(_ challenges: [Challenge])
    func getCachedChallenges() -> [Challenge]?
    func cacheUserChallenges(_ challenges: [UserChallenge])
    func getCachedUserChallenges() -> [UserChallenge]?
    func cacheUser(_ user: User)
    func getCachedUser() -> User?
}

class CacheManager: CacheManagerProtocol {
    nonisolated(unsafe) static let shared = CacheManager()
    
    private struct CacheEntry: Codable {
        let data: Data
        let expiresAt: Date?
        
        var isExpired: Bool {
            guard let expiresAt = expiresAt else { return false }
            return Date() > expiresAt
        }
    }
    
    private let cache = NSCache<NSString, NSData>()
    private let userDefaults = UserDefaults.standard
    private let cachePrefix = "cache_"
    
    private init() {
        // Настройка кэша в памяти
        cache.countLimit = 100 // Максимум 100 объектов
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
        
        Logger.shared.info("CacheManager initialized")
    }
    
    // MARK: - Public Methods
    
    private func getMemoryOnly<T: Codable>(_ key: String, as type: T.Type) -> T? {
        let fullKey = cachePrefix + key
        
        if let cachedData = cache.object(forKey: fullKey as NSString) as Data? {
            if let entry = try? JSONDecoder().decode(CacheEntry.self, from: cachedData) {
                if entry.isExpired {
                    cache.removeObject(forKey: fullKey as NSString)
                    return nil
                }
                if let value = try? JSONDecoder().decode(type, from: entry.data) {
                    Logger.shared.debug("Cache hit (memory-only): \(key)")
                    return value
                }
            }
        }
        
        Logger.shared.debug("Cache miss (memory-only): \(key)")
        return nil
    }
    
    private func setMemoryOnly<T: Codable>(_ value: T, forKey key: String, ttl: TimeInterval? = nil) {
        let fullKey = cachePrefix + key
        
        guard let data = try? JSONEncoder().encode(value) else {
            Logger.shared.warning("Failed to encode value for cache key: \(key)")
            return
        }
        
        let expiresAt = ttl.map { Date().addingTimeInterval($0) }
        let entry = CacheEntry(data: data, expiresAt: expiresAt)
        
        guard let entryData = try? JSONEncoder().encode(entry) else {
            Logger.shared.warning("Failed to encode cache entry for key: \(key)")
            return
        }
        
        cache.setObject(entryData as NSData, forKey: fullKey as NSString)
        Logger.shared.debug("Cached value for key (memory-only): \(key), TTL: \(ttl?.description ?? "none")")
    }
    
    func get<T: Codable>(_ key: String, as type: T.Type) -> T? {
        let fullKey = cachePrefix + key
        
        // 1. Проверяем кэш в памяти
        if let cachedData = cache.object(forKey: fullKey as NSString) as Data? {
            if let entry = try? JSONDecoder().decode(CacheEntry.self, from: cachedData) {
                if entry.isExpired {
                    cache.removeObject(forKey: fullKey as NSString)
                    userDefaults.removeObject(forKey: fullKey)
                    return nil
                }
                
                if let value = try? JSONDecoder().decode(type, from: entry.data) {
                    Logger.shared.debug("Cache hit (memory): \(key)")
                    return value
                }
            }
        }
        
        // 2. Проверяем UserDefaults
        if let cachedData = userDefaults.data(forKey: fullKey) {
            if let entry = try? JSONDecoder().decode(CacheEntry.self, from: cachedData) {
                if entry.isExpired {
                    userDefaults.removeObject(forKey: fullKey)
                    return nil
                }
                
                if let value = try? JSONDecoder().decode(type, from: entry.data) {
                    // Восстанавливаем в кэш памяти
                    cache.setObject(cachedData as NSData, forKey: fullKey as NSString)
                    Logger.shared.debug("Cache hit (disk): \(key)")
                    return value
                }
            }
        }
        
        Logger.shared.debug("Cache miss: \(key)")
        return nil
    }
    
    func set<T: Codable>(_ value: T, forKey key: String, ttl: TimeInterval? = nil) {
        let fullKey = cachePrefix + key
        
        guard let data = try? JSONEncoder().encode(value) else {
            Logger.shared.warning("Failed to encode value for cache key: \(key)")
            return
        }
        
        let expiresAt = ttl.map { Date().addingTimeInterval($0) }
        let entry = CacheEntry(data: data, expiresAt: expiresAt)
        
        guard let entryData = try? JSONEncoder().encode(entry) else {
            Logger.shared.warning("Failed to encode cache entry for key: \(key)")
            return
        }
        
        // Сохраняем в кэш памяти
        cache.setObject(entryData as NSData, forKey: fullKey as NSString)
        
        // Сохраняем в UserDefaults (для персистентности)
        userDefaults.set(entryData, forKey: fullKey)
        
        Logger.shared.debug("Cached value for key: \(key), TTL: \(ttl?.description ?? "none")")
    }
    
    func remove(_ key: String) {
        let fullKey = cachePrefix + key
        cache.removeObject(forKey: fullKey as NSString)
        userDefaults.removeObject(forKey: fullKey)
        Logger.shared.debug("Removed cache for key: \(key)")
    }
    
    func clear() {
        cache.removeAllObjects()
        
        // Очищаем все ключи с префиксом cache_
        let keys = userDefaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(cachePrefix) }
        keys.forEach { userDefaults.removeObject(forKey: $0) }
        
        Logger.shared.info("Cache cleared")
    }
    
    func has(_ key: String) -> Bool {
        let fullKey = cachePrefix + key
        
        // Проверяем кэш в памяти
        if cache.object(forKey: fullKey as NSString) != nil {
            return true
        }
        
        // Проверяем UserDefaults
        if userDefaults.data(forKey: fullKey) != nil {
            return true
        }
        
        return false
    }
}

// MARK: - Convenience Extensions

extension CacheManager {
    /// Кэшировать челленджи (долгий TTL - статичные данные)
    func cacheChallenges(_ challenges: [Challenge]) {
        if AppConfig.isConfigured {
            // При включённом Supabase: не оставляем следов на диске — только кэш в памяти.
            setMemoryOnly(challenges, forKey: "challenges", ttl: AppConfig.challengesCacheTTL)
            userDefaults.removeObject(forKey: cachePrefix + "challenges")
        } else {
            set(challenges, forKey: "challenges", ttl: AppConfig.challengesCacheTTL)
        }
    }
    
    /// Получить кэшированные челленджи
    func getCachedChallenges() -> [Challenge]? {
        if AppConfig.isConfigured {
            // При включённом Supabase: читаем только из памяти и чистим диск.
            userDefaults.removeObject(forKey: cachePrefix + "challenges")
            return getMemoryOnly("challenges", as: [Challenge].self)
        }
        return get("challenges", as: [Challenge].self)
    }
    
    /// Кэшировать челленджи пользователя (короткий TTL - критичные данные)
    func cacheUserChallenges(_ challenges: [UserChallenge]) {
        set(challenges, forKey: "userChallenges", ttl: AppConfig.userChallengesCacheTTL)
    }
    
    /// Получить кэшированные челленджи пользователя
    func getCachedUserChallenges() -> [UserChallenge]? {
        return get("userChallenges", as: [UserChallenge].self)
    }
    
    /// Кэшировать профиль пользователя (очень короткий TTL - баланс критичен)
    func cacheUser(_ user: User) {
        set(user, forKey: "currentUser", ttl: AppConfig.userBalanceCacheTTL)
    }
    
    /// Получить кэшированный профиль пользователя
    func getCachedUser() -> User? {
        return get("currentUser", as: User.self)
    }
}
