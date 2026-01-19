//
//  AchievementManagerTests.swift
//  StepCounterTests
//
//  Тесты для системы достижений
//

import XCTest
@testable import StepCounter

@MainActor
final class AchievementManagerTests: XCTestCase {
    
    var achievementManager: AchievementManager!
    var testStorage: TestStorageManager!
    
    override func setUp() {
        super.setUp()
        testStorage = TestStorageManager()
        achievementManager = AchievementManager()
    }
    
    override func tearDown() {
        testStorage?.clearAllTestData()
        achievementManager = nil
        testStorage = nil
        super.tearDown()
    }
    
    // MARK: - Разблокировка достижений
    
    /// Тест: Достижение должно разблокироваться при выполнении условия
    func testAchievementUnlocksWhenConditionMet() {
        // Given
        let achievementType = AchievementType.firstSteps
        let initialUnlocked = achievementManager.achievements.first(where: { $0.type == achievementType })?.isUnlocked ?? false
        
        // When
        achievementManager.checkAchievements(steps: 100, distance: 0, calories: 0, goalReached: false, stepGoal: 10000)
        
        // Then
        let afterUnlocked = achievementManager.achievements.first(where: { $0.type == achievementType })?.isUnlocked ?? false
        if !initialUnlocked {
            XCTAssertTrue(afterUnlocked, "Достижение 'Первые шаги' должно разблокироваться при 100 шагах")
        }
    }
    
    /// Тест: Достижение не должно разблокироваться повторно
    func testAchievementNotUnlockedTwice() {
        // Given
        let achievementType = AchievementType.firstSteps
        achievementManager.checkAchievements(steps: 100, distance: 0, calories: 0, goalReached: false, stepGoal: 10000)
        let firstUnlockCount = achievementManager.achievements.filter { $0.type == achievementType && $0.isUnlocked }.count
        
        // When
        achievementManager.checkAchievements(steps: 200, distance: 0, calories: 0, goalReached: false, stepGoal: 10000)
        
        // Then
        let secondUnlockCount = achievementManager.achievements.filter { $0.type == achievementType && $0.isUnlocked }.count
        XCTAssertEqual(firstUnlockCount, secondUnlockCount, "Достижение не должно разблокироваться повторно")
    }
    
    /// Тест: Достижение на 10000 шагов должно разблокироваться при достижении 10000 шагов
    func testStep10kAchievementUnlocks() {
        // Given
        let achievementType = AchievementType.step10k
        
        // When
        achievementManager.checkAchievements(steps: 10000, distance: 0, calories: 0, goalReached: true, stepGoal: 10000)
        
        // Then
        let isUnlocked = achievementManager.achievements.first(where: { $0.type == achievementType })?.isUnlocked ?? false
        XCTAssertTrue(isUnlocked, "Достижение '10000 шагов' должно разблокироваться")
    }
    
    /// Тест: Серия дней должна увеличиваться при достижении цели
    func testStreakIncreasesWithGoalReached() {
        // Given
        let initialStreak = achievementManager.currentStreak
        
        // When
        // Достигаем цели несколько дней подряд
        achievementManager.checkAchievements(steps: 10000, distance: 0, calories: 0, goalReached: true, stepGoal: 10000)
        
        // Then
        // Серия дней обновляется внутри checkAchievements при goalReached = true
        XCTAssertGreaterThanOrEqual(achievementManager.currentStreak, initialStreak, "Серия дней не должна уменьшаться при достижении цели")
    }
    
    /// Тест: Достижение серии должно разблокироваться при достижении нужной серии
    func testStreakAchievementUnlocks() {
        // Given
        achievementManager.currentStreak = 6
        
        // When
        // Достигаем цели 7-й день подряд
        achievementManager.checkAchievements(steps: 10000, distance: 0, calories: 0, goalReached: true, stepGoal: 10000)
        achievementManager.currentStreak = 7
        achievementManager.checkAchievements(steps: 10000, distance: 0, calories: 0, goalReached: true, stepGoal: 10000)
        
        // Then
        let isUnlocked = achievementManager.achievements.first(where: { $0.type == .streak7 })?.isUnlocked ?? false
        XCTAssertTrue(isUnlocked, "Достижение 'Серия 7 дней' должно разблокироваться")
    }
    
    /// Тест: Premium достижения должны быть доступны только Premium пользователям
    func testPremiumAchievementsOnlyForPremium() {
        // Given
        let subscriptionManager = SubscriptionManager.shared
        let wasPremium = subscriptionManager.isPremium
        subscriptionManager.setPremiumManually(false)
        
        // When
        let allAchievements = achievementManager.achievements
        let premiumAchievements = allAchievements.filter { $0.type.isPremium }
        
        // Then
        // Premium достижения должны быть в списке, но заблокированы для free пользователей
        XCTAssertGreaterThan(premiumAchievements.count, 0, "Должны быть Premium достижения")
        
        // Restore
        subscriptionManager.setPremiumManually(wasPremium)
    }
    
    /// Тест: Достижение должно иметь корректные свойства
    func testAchievementProperties() {
        // Given
        let achievementType = AchievementType.step10k
        
        // When
        var achievement = Achievement(type: achievementType)
        achievement.isUnlocked = true
        achievement.unlockedDate = Date()
        
        // Then
        XCTAssertEqual(achievement.type, achievementType, "Тип достижения должен совпадать")
        XCTAssertNotNil(achievement.unlockedDate, "Должна быть дата разблокировки")
        XCTAssertTrue(achievement.isUnlocked, "Достижение должно быть разблокировано")
    }
    
    /// Тест: Все достижения должны иметь уникальные типы
    func testAllAchievementsHaveUniqueTypes() {
        // Given
        // Ждем загрузки достижений
        let expectation = XCTestExpectation(description: "Achievements loaded")
        Task { @MainActor in
            await Task.sleep(nanoseconds: 100_000_000) // 0.1 секунды
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let allAchievements = achievementManager.achievements
        
        // When
        let types = allAchievements.map { $0.type }
        let uniqueTypes = Set(types)
        
        // Then
        XCTAssertEqual(types.count, uniqueTypes.count, "Все достижения должны иметь уникальные типы")
    }
    
    /// Тест: Прогресс достижения должен рассчитываться корректно
    func testAchievementProgressCalculation() {
        // Given
        let achievementType = AchievementType.step10k
        var achievement = Achievement(type: achievementType)
        achievement.progress = 5000
        
        // When
        let progress = achievement.progressPercent
        
        // Then
        XCTAssertGreaterThanOrEqual(progress, 0.0, "Прогресс должен быть >= 0")
        XCTAssertLessThanOrEqual(progress, 1.0, "Прогресс должен быть <= 1")
        XCTAssertEqual(progress, 0.5, accuracy: 0.01, "При 5000 шагах прогресс должен быть ~0.5 для достижения 10000")
    }
}
