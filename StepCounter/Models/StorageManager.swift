//
//  StorageManager.swift
//  StepCounter
//
//  Централизованный менеджер для работы с UserDefaults
//

import Foundation

// Logger доступен глобально, так как определен в Logger.swift в том же модуле

/// Ошибки StorageManager
enum StorageError: LocalizedError {
    case encodingFailed(Error)
    case decodingFailed(Error)
    case keyNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed(let error):
            return "Ошибка кодирования данных: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Ошибка декодирования данных: \(error.localizedDescription)"
        case .keyNotFound(let key):
            return "Ключ не найден: \(key)"
        }
    }
}

/// Единый менеджер для всех операций сохранения/загрузки данных
/// Все операции выполняются на главном потоке для thread-safety
@MainActor
final class StorageManager {
    static let shared = StorageManager()
    
    private init() {}
    
    // MARK: - Codable Types
    
    /// Сохранить Codable объект
    /// - Parameters:
    ///   - object: Объект для сохранения
    ///   - key: Ключ для сохранения
    /// - Throws: StorageError при ошибке кодирования
    func save<T: Codable>(_ object: T, forKey key: String) throws {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [] // Убираем форматирование для скорости
            let data = try encoder.encode(object)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            throw StorageError.encodingFailed(error)
        }
    }
    
    /// Загрузить Codable объект
    /// - Parameters:
    ///   - type: Тип объекта для загрузки
    ///   - key: Ключ для загрузки
    /// - Returns: Загруженный объект или nil
    /// - Throws: StorageError при ошибке декодирования
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        } catch {
            throw StorageError.decodingFailed(error)
        }
    }
    
    /// Загрузить Codable объект (безопасная версия, возвращает nil при ошибке)
    func loadSafe<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        do {
            return try load(type, forKey: key)
        } catch {
            Logger.shared.logStorageError(error, key: key)
            return nil
        }
    }
    
    // MARK: - String
    
    /// Сохранить строку
    func saveString(_ value: String, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    /// Загрузить строку
    func loadString(forKey key: String) -> String? {
        UserDefaults.standard.string(forKey: key)
    }
    
    // MARK: - Bool
    
    /// Сохранить Bool
    func saveBool(_ value: Bool, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    /// Загрузить Bool
    func loadBool(forKey key: String, defaultValue: Bool = false) -> Bool {
        if UserDefaults.standard.object(forKey: key) == nil {
            return defaultValue
        }
        return UserDefaults.standard.bool(forKey: key)
    }
    
    // MARK: - Int
    
    /// Сохранить Int
    func saveInt(_ value: Int, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    /// Загрузить Int
    func loadInt(forKey key: String, defaultValue: Int = 0) -> Int {
        if UserDefaults.standard.object(forKey: key) == nil {
            return defaultValue
        }
        return UserDefaults.standard.integer(forKey: key)
    }
    
    // MARK: - Double
    
    /// Сохранить Double
    func saveDouble(_ value: Double, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    /// Загрузить Double
    func loadDouble(forKey key: String, defaultValue: Double = 0.0) -> Double {
        if UserDefaults.standard.object(forKey: key) == nil {
            return defaultValue
        }
        return UserDefaults.standard.double(forKey: key)
    }
    
    // MARK: - Data
    
    /// Сохранить Data
    func saveData(_ data: Data, forKey key: String) {
        UserDefaults.standard.set(data, forKey: key)
    }
    
    /// Загрузить Data
    func loadData(forKey key: String) -> Data? {
        UserDefaults.standard.data(forKey: key)
    }
    
    // MARK: - Date
    
    /// Сохранить Date
    func saveDate(_ date: Date, forKey key: String) {
        UserDefaults.standard.set(date, forKey: key)
    }
    
    /// Загрузить Date
    func loadDate(forKey key: String) -> Date? {
        UserDefaults.standard.object(forKey: key) as? Date
    }
    
    // MARK: - Array (generic)
    
    /// Сохранить массив Codable объектов
    func saveArray<T: Codable>(_ array: [T], forKey key: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = []
        let data = try encoder.encode(array)
        UserDefaults.standard.set(data, forKey: key)
    }
    
    /// Сохранить массив Codable объектов (безопасная версия)
    func saveArraySafe<T: Codable>(_ array: [T], forKey key: String) {
        do {
            try saveArray(array, forKey: key)
        } catch {
            Logger.shared.logStorageError(error, key: key)
        }
    }
    
    /// Загрузить массив Codable объектов
    func loadArray<T: Codable>(_ type: T.Type, forKey key: String) throws -> [T] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        let decoder = JSONDecoder()
        return try decoder.decode([T].self, from: data)
    }
    
    /// Загрузить массив Codable объектов (безопасная версия)
    func loadArraySafe<T: Codable>(_ type: T.Type, forKey key: String) -> [T] {
        do {
            return try loadArray(type, forKey: key)
        } catch {
            Logger.shared.logStorageError(error, key: key)
            return []
        }
    }
    
    /// Асинхронное сохранение Codable объекта
    func saveAsync<T: Codable>(_ value: T, forKey key: String) {
        Task { @MainActor in
            do {
                try save(value, forKey: key)
            } catch {
                Logger.shared.logStorageError(error, key: key)
            }
        }
    }
    
    // MARK: - Remove
    
    /// Удалить значение
    func remove(forKey key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    /// Очистить все данные
    func clearAll() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
}
