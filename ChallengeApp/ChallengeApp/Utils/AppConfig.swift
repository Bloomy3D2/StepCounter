//
//  AppConfig.swift
//  ChallengeApp
//
//  Конфигурация приложения
//

import Foundation

struct AppConfig: Sendable {
    // MARK: - Supabase Configuration
    
    // Значения читаются из GeneratedConfig.swift (генерируется автоматически из .xcconfig файлов)
    // Build Script → читает .xcconfig → генерирует GeneratedConfig.swift → используется здесь
    
    static let supabaseURL: String = {
        // 0. Проверяем GeneratedConfig (генерируется из .xcconfig во время сборки)
        // Это самый надежный способ - значения компилируются прямо в код
        let generated = GeneratedConfig.supabaseURL
        if !generated.isEmpty && generated != "YOUR_SUPABASE_URL" {
            Logger.shared.info("🔑 AppConfig: Supabase URL from GeneratedConfig")
            return generated
        }
        
        // 1. Проверяем Info.plist (основной источник - безопасно, не попадает в git)
        // Ключи добавляются через INFOPLIST_KEY_SUPABASE_URL в .xcconfig
        if let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String, !url.isEmpty {
            Logger.shared.info("🔑 AppConfig: Supabase URL from Info.plist")
            return url
        }
        
        // 2. Проверяем переменные окружения (для тестирования/CI)
        if let url = ProcessInfo.processInfo.environment["SUPABASE_URL"], !url.isEmpty {
            Logger.shared.info("🔑 AppConfig: Supabase URL from environment")
            return url
        }
        
        // 3. Fallback на дефолтное значение (только для разработки)
        // ⚠️ В продакшене должен быть настроен Info.plist или переменные окружения!
        Logger.shared.warning("⚠️ AppConfig: Supabase URL not found, using default")
        return "YOUR_SUPABASE_URL"
    }()
    
    static let supabaseKey: String = {
        // 0. Проверяем GeneratedConfig (генерируется из .xcconfig во время сборки)
        let generated = GeneratedConfig.supabaseKey
        if !generated.isEmpty && generated != "YOUR_SUPABASE_KEY" {
            Logger.shared.info("🔑 AppConfig: Supabase Key from GeneratedConfig")
            return generated
        }
        
        // 1. Проверяем Info.plist (основной источник - безопасно, не попадает в git)
        // Ключи добавляются через INFOPLIST_KEY_SUPABASE_KEY в .xcconfig
        if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_KEY") as? String, !key.isEmpty {
            Logger.shared.info("🔑 AppConfig: Supabase Key from Info.plist")
            return key
        }
        
        // 2. Проверяем переменные окружения (для тестирования/CI)
        if let key = ProcessInfo.processInfo.environment["SUPABASE_KEY"], !key.isEmpty {
            Logger.shared.info("🔑 AppConfig: Supabase Key from environment")
            return key
        }
        
        // 3. Fallback на дефолтное значение (только для разработки)
        // ⚠️ В продакшене должен быть настроен Info.plist или переменные окружения!
        Logger.shared.warning("⚠️ AppConfig: Supabase Key not found, using default")
        return "YOUR_SUPABASE_KEY"
    }()
    
    // MARK: - YooKassa Configuration
    
    // Значения читаются из GeneratedConfig.swift (генерируется автоматически из .xcconfig файлов)
    // Build Script → читает .xcconfig → генерирует GeneratedConfig.swift → используется здесь
    
    static let yooKassaShopId: String = {
        // 1. Проверяем GeneratedConfig (генерируется из .xcconfig во время сборки)
        // Это самый надежный способ - значения компилируются прямо в код
        let generated = GeneratedConfig.yooKassaShopId
        if !generated.isEmpty && generated != "YOUR_SHOP_ID" {
            Logger.shared.info("🔑 AppConfig: YooKassa Shop ID from GeneratedConfig: \(generated)")
            return generated
        }
        
        // 2. Проверяем Info.plist (fallback)
        if let shopId = Bundle.main.object(forInfoDictionaryKey: "YOOKASSA_SHOP_ID") as? String, !shopId.isEmpty {
            Logger.shared.info("🔑 AppConfig: YooKassa Shop ID from Info.plist: \(shopId)")
            return shopId
        }
        
        // 3. Проверяем переменные окружения (для тестирования)
        if let shopId = ProcessInfo.processInfo.environment["YOOKASSA_SHOP_ID"], !shopId.isEmpty {
            Logger.shared.info("🔑 AppConfig: YooKassa Shop ID from environment: \(shopId)")
            return shopId
        }
        
        // 4. Fallback на дефолтное значение
        Logger.shared.warning("⚠️ AppConfig: YooKassa Shop ID not found, using default")
        return "YOUR_SHOP_ID"
    }()
    
    static let yooKassaSecretKey: String = {
        // 1. Проверяем GeneratedConfig (генерируется из .xcconfig во время сборки)
        let generated = GeneratedConfig.yooKassaSecretKey
        if !generated.isEmpty && generated != "YOUR_SECRET_KEY" {
            Logger.shared.info("🔑 AppConfig: YooKassa Secret Key from GeneratedConfig: \(generated.prefix(20))...")
            return generated
        }
        
        // 2. Проверяем Info.plist (fallback)
        if let secretKey = Bundle.main.object(forInfoDictionaryKey: "YOOKASSA_SECRET_KEY") as? String, !secretKey.isEmpty {
            Logger.shared.info("🔑 AppConfig: YooKassa Secret Key from Info.plist: \(secretKey.prefix(20))...")
            return secretKey
        }
        
        // 3. Проверяем переменные окружения (для тестирования)
        if let secretKey = ProcessInfo.processInfo.environment["YOOKASSA_SECRET_KEY"], !secretKey.isEmpty {
            Logger.shared.info("🔑 AppConfig: YooKassa Secret Key from environment: \(secretKey.prefix(20))...")
            return secretKey
        }
        
        // 4. Fallback на дефолтное значение
        Logger.shared.warning("⚠️ AppConfig: YooKassa Secret Key not found, using default")
        return "YOUR_SECRET_KEY"
    }()
    
    static let yooKassaIsTestMode: Bool = {
        // 1. Проверяем GeneratedConfig (генерируется из .xcconfig во время сборки)
        let generated = GeneratedConfig.yooKassaIsTestMode
        Logger.shared.info("🔑 AppConfig: YooKassa Test Mode from GeneratedConfig: \(generated)")
        return generated
        
        // 2. Fallback на Info.plist (если GeneratedConfig не работает)
        // if let testMode = Bundle.main.object(forInfoDictionaryKey: "YOOKASSA_TEST_MODE") as? Bool {
        //     return testMode
        // }
        // 
        // if let testModeString = Bundle.main.object(forInfoDictionaryKey: "YOOKASSA_TEST_MODE") as? String {
        //     return testModeString.lowercased() == "true" || testModeString == "YES"
        // }
        // 
        // // 3. Автоматически определяем по ключам:
        // let secretKey = yooKassaSecretKey
        // if secretKey.hasPrefix("test_") {
        //     return true
        // }
        // return false
    }()
    
    // MARK: - App Configuration
    
    static let appURLScheme = "challengeapp"
    static let paymentReturnURL = "\(appURLScheme)://payment/success"
    
    // MARK: - Cache Configuration
    
    /// Общий TTL по умолчанию (для обратной совместимости)
    static let cacheTTL: TimeInterval = 300 // 5 минут
    
    /// TTL для списка челленджей (статичные данные, редко меняются)
    /// Можно кэшировать долго - обновляются только при создании новых челленджей
    static let challengesCacheTTL: TimeInterval = 1800 // 30 минут
    
    /// TTL для участия пользователя в челленджах (критичные данные)
    /// Очень короткий TTL - статусы меняются часто (выполнение дня, провал, завершение)
    /// Должен быть таким же коротким, как баланс, т.к. статусы критичны для UX
    static let userChallengesCacheTTL: TimeInterval = 30 // 30 секунд
    
    /// TTL для баланса пользователя (критичные данные)
    /// Очень короткий TTL - баланс меняется при оплатах, выводах, выигрышах
    static let userBalanceCacheTTL: TimeInterval = 30 // 30 секунд
    
    // MARK: - Network Configuration
    
    static let networkTimeout: TimeInterval = 30.0
    static let maxRetryAttempts = 3
    static let retryDelay: TimeInterval = 1.0
    
    // MARK: - Validation
    
    static var isConfigured: Bool {
        // Проверяем, что критичные настройки не дефолтные
        return (supabaseURL != "YOUR_SUPABASE_URL" && !supabaseURL.isEmpty) &&
               (supabaseKey != "YOUR_SUPABASE_KEY" && supabaseKey.count > 50)
    }
}
