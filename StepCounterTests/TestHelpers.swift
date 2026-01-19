//
//  TestHelpers.swift
//  StepCounterTests
//
//  Вспомогательные функции и моки для тестов
//

import Foundation
import XCTest
@testable import StepCounter

// MARK: - Test UserDefaults

// MARK: - Test UserDefaults Helper
// Удалено - теперь suiteName хранится в TestStorageManager

// MARK: - Test Storage Manager

/// Тестовый менеджер хранения данных для изоляции тестов
/// Использует отдельный UserDefaults вместо наследования от StorageManager
@MainActor
class TestStorageManager {
    private let testDefaults: UserDefaults
    private let suiteName: String
    
    init() {
        let suite = "test.\(UUID().uuidString)"
        self.suiteName = suite
        self.testDefaults = UserDefaults(suiteName: suite)!
        testDefaults.removePersistentDomain(forName: suite)
    }
    
    func save<T: Codable>(_ value: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(value)
        testDefaults.set(data, forKey: key)
    }
    
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T {
        guard let data = testDefaults.data(forKey: key) else {
            throw NSError(domain: "TestStorage", code: 404, userInfo: [NSLocalizedDescriptionKey: "Key not found"])
        }
        return try JSONDecoder().decode(type, from: data)
    }
    
    func loadSafe<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        return try? load(type, forKey: key)
    }
    
    func saveBool(_ value: Bool, forKey key: String) {
        testDefaults.set(value, forKey: key)
    }
    
    func loadBool(forKey key: String) -> Bool {
        return testDefaults.bool(forKey: key)
    }
    
    func saveString(_ value: String, forKey key: String) {
        testDefaults.set(value, forKey: key)
    }
    
    func loadString(forKey key: String) -> String? {
        return testDefaults.string(forKey: key)
    }
    
    func remove(forKey key: String) {
        testDefaults.removeObject(forKey: key)
    }
    
    func saveInt(_ value: Int, forKey key: String) {
        testDefaults.set(value, forKey: key)
    }
    
    func loadInt(forKey key: String, defaultValue: Int = 0) -> Int {
        if testDefaults.object(forKey: key) == nil {
            return defaultValue
        }
        return testDefaults.integer(forKey: key)
    }
    
    func saveDate(_ value: Date, forKey key: String) {
        testDefaults.set(value, forKey: key)
    }
    
    func loadDate(forKey key: String) -> Date? {
        return testDefaults.object(forKey: key) as? Date
    }
    
    func saveArray<T: Codable>(_ array: [T], forKey key: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = []
        let data = try encoder.encode(array)
        testDefaults.set(data, forKey: key)
    }
    
    func saveArraySafe<T: Codable>(_ array: [T], forKey key: String) {
        do {
            try saveArray(array, forKey: key)
        } catch {
            // Игнорируем ошибки в тестах
        }
    }
    
    func loadArraySafe<T: Codable>(_ type: T.Type, forKey key: String) -> [T] {
        guard let data = testDefaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([T].self, from: data)) ?? []
    }
    
    func clearAllTestData() {
        if let domain = testDefaults.persistentDomain(forName: suiteName) {
            for key in domain.keys {
                testDefaults.removeObject(forKey: key)
            }
        }
    }
}

// MARK: - Test Date Helpers

extension Date {
    static func testDate(year: Int = 2025, month: Int = 1, day: Int = 15, hour: Int = 12, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
    
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    func addingHours(_ hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }
}

// MARK: - XCTest Extensions

extension XCTestCase {
    func waitForAsync(timeout: TimeInterval = 1.0) async {
        try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
    }
    
    func waitForMainActor(timeout: TimeInterval = 1.0) {
        let expectation = XCTestExpectation(description: "Wait for main actor")
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout + 0.5)
    }
}
