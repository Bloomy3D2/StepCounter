//
//  StorageManagerTests.swift
//  StepCounterTests
//
//  Тесты для менеджера хранения данных
//

import XCTest
@testable import StepCounter

@MainActor
final class StorageManagerTests: XCTestCase {
    
    var storageManager: StorageManager!
    var testStorage: TestStorageManager!
    
    override func setUp() {
        super.setUp()
        storageManager = StorageManager.shared
        testStorage = TestStorageManager()
    }
    
    override func tearDown() {
        if let storage = testStorage {
            storage.clearAllTestData()
        }
        testStorage = nil
        super.tearDown()
    }
    
    // MARK: - Codable Types
    
    /// Тест: Codable объект должен сохраняться и загружаться
    func testSaveAndLoadCodable() {
        // Given
        struct TestStruct: Codable, Equatable {
            let name: String
            let value: Int
        }
        let testObject = TestStruct(name: "Test", value: 42)
        let key = "testCodable"
        
        // When
        do {
            try testStorage.save(testObject, forKey: key)
            let loaded = testStorage.loadSafe(TestStruct.self, forKey: key)
            
            // Then
            XCTAssertNotNil(loaded, "Объект должен быть загружен")
            XCTAssertEqual(loaded, testObject, "Загруженный объект должен совпадать с сохраненным")
        } catch {
            XCTFail("Ошибка при сохранении/загрузке: \(error)")
        }
    }
    
    /// Тест: Несуществующий ключ должен возвращать nil
    func testLoadNonExistentKeyReturnsNil() {
        // Given
        struct TestStruct: Codable {
            let value: Int
        }
        let key = "nonExistentKey"
        
        // When
        let loaded = testStorage.loadSafe(TestStruct.self, forKey: key)
        
        // Then
        XCTAssertNil(loaded, "Несуществующий ключ должен возвращать nil")
    }
    
    // MARK: - String
    
    /// Тест: Строка должна сохраняться и загружаться
    func testSaveAndLoadString() {
        // Given
        let testString = "Test String"
        let key = "testString"
        
        // When
        testStorage.saveString(testString, forKey: key)
        let loaded = testStorage.loadString(forKey: key)
        
        // Then
        XCTAssertEqual(loaded, testString, "Загруженная строка должна совпадать с сохраненной")
    }
    
    // MARK: - Bool
    
    /// Тест: Bool значение должно сохраняться и загружаться
    func testSaveAndLoadBool() {
        // Given
        let testBool = true
        let key = "testBool"
        
        // When
        testStorage.saveBool(testBool, forKey: key)
        let loaded = testStorage.loadBool(forKey: key)
        
        // Then
        XCTAssertEqual(loaded, testBool, "Загруженное Bool значение должно совпадать с сохраненным")
    }
    
    /// Тест: Bool значение по умолчанию должно быть false
    func testBoolDefaultValueIsFalse() {
        // Given
        let key = "nonExistentBool"
        
        // When
        let loaded = testStorage.loadBool(forKey: key)
        
        // Then
        XCTAssertFalse(loaded, "Несуществующий Bool должен возвращать false")
    }
    
    // MARK: - Int
    
    /// Тест: Int значение должно сохраняться и загружаться
    func testSaveAndLoadInt() {
        // Given
        let testInt = 42
        let key = "testInt"
        
        // When
        testStorage.saveInt(testInt, forKey: key)
        let loaded = testStorage.loadInt(forKey: key)
        
        // Then
        XCTAssertEqual(loaded, testInt, "Загруженное Int значение должно совпадать с сохраненным")
    }
    
    // MARK: - Date
    
    /// Тест: Date должна сохраняться и загружаться
    func testSaveAndLoadDate() {
        // Given
        let testDate = Date()
        let key = "testDate"
        
        // When
        testStorage.saveDate(testDate, forKey: key)
        let loaded = testStorage.loadDate(forKey: key)
        
        // Then
        XCTAssertNotNil(loaded, "Дата должна быть загружена")
        if let loaded = loaded {
            let timeDifference = abs(loaded.timeIntervalSince(testDate))
            XCTAssertLessThan(timeDifference, 1.0, "Загруженная дата должна совпадать с сохраненной (с точностью до секунды)")
        }
    }
    
    // MARK: - Array
    
    /// Тест: Массив должен сохраняться и загружаться
    func testSaveAndLoadArray() {
        // Given
        let testArray = [1, 2, 3, 4, 5]
        let key = "testArray"
        
        // When
        do {
            try testStorage.saveArray(testArray, forKey: key)
            let loaded = testStorage.loadArraySafe(Int.self, forKey: key)
            
            // Then
            XCTAssertNotNil(loaded, "Массив должен быть загружен")
            XCTAssertEqual(loaded, testArray, "Загруженный массив должен совпадать с сохраненным")
        } catch {
            XCTFail("Ошибка при сохранении/загрузке массива: \(error)")
        }
    }
    
    // MARK: - Remove
    
    /// Тест: Удаление ключа должно работать
    func testRemoveKey() {
        // Given
        let key = "testRemove"
        testStorage.saveString("Test", forKey: key)
        
        // When
        testStorage.remove(forKey: key)
        let loaded = testStorage.loadString(forKey: key)
        
        // Then
        XCTAssertNil(loaded, "Удаленный ключ должен возвращать nil")
    }
}
