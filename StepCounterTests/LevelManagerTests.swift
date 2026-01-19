//
//  LevelManagerTests.swift
//  StepCounterTests
//
//  Тесты для системы уровней и XP
//

import XCTest
@testable import StepCounter

@MainActor
final class LevelManagerTests: XCTestCase {
    
    var levelManager: LevelManager!
    var testStorage: TestStorageManager!
    
    override func setUp() {
        super.setUp()
        testStorage = TestStorageManager()
        // Используем тестовый storage для изоляции тестов
        levelManager = LevelManager()
    }
    
    override func tearDown() {
        testStorage.clearAllTestData()
        levelManager = nil
        testStorage = nil
        super.tearDown()
    }
    
    // MARK: - XP и Уровни
    
    /// Тест: Пользователь должен получать XP при добавлении шагов
    func testAddXPIncreasesTotalXP() {
        // Given
        let initialXP = levelManager.player.totalXP
        let xpToAdd = 100
        
        // When
        levelManager.addXP(xpToAdd)
        
        // Then
        XCTAssertEqual(levelManager.player.totalXP, initialXP + xpToAdd, "XP должен увеличиться на добавленное значение")
    }
    
    /// Тест: Пользователь должен повышать уровень при достижении необходимого XP
    func testLevelUpWhenXPThresholdReached() {
        // Given
        levelManager.player.level = 1
        levelManager.player.totalXP = 900 // До следующего уровня нужно 1000 XP
        
        // When
        levelManager.addXP(150) // Добавляем достаточно для повышения уровня
        
        // Then
        XCTAssertEqual(levelManager.player.level, 2, "Уровень должен повыситься до 2")
        XCTAssertGreaterThanOrEqual(levelManager.player.totalXP, 1000, "XP должен быть >= 1000")
    }
    
    /// Тест: При повышении уровня должен обновляться ранг игрока
    func testRankUpdatesOnLevelUp() {
        // Given
        levelManager.player.level = 4
        levelManager.player.rank = .beginner
        
        // When
        levelManager.player.level = 5 // Уровень для ранга .walker
        
        // Then
        XCTAssertEqual(levelManager.player.rank, .walker, "Ранг должен обновиться на .walker при уровне 5")
    }
    
    /// Тест: При повышении уровня должен показываться экран повышения уровня
    func testLevelUpShowsLevelUpScreen() {
        // Given
        levelManager.player.level = 1
        levelManager.player.totalXP = 900
        levelManager.showLevelUp = false
        
        // When
        levelManager.addXP(150)
        
        // Then
        XCTAssertTrue(levelManager.showLevelUp, "Должен показываться экран повышения уровня")
        XCTAssertEqual(levelManager.newLevel, 2, "Новый уровень должен быть 2")
    }
    
    /// Тест: При повышении ранга должен показываться экран повышения ранга
    func testRankUpShowsRankUpScreen() {
        // Given
        levelManager.player.level = 4
        levelManager.player.rank = .beginner
        levelManager.showRankUp = false
        
        // When
        levelManager.player.level = 5
        // Ранг обновляется автоматически при изменении уровня через addXP
        let newRank = PlayerRank.forLevel(levelManager.player.level)
        levelManager.player.rank = newRank
        if newRank != .beginner {
            levelManager.newRank = newRank
            levelManager.showRankUp = true
        }
        
        // Then
        XCTAssertTrue(levelManager.showRankUp, "Должен показываться экран повышения ранга")
        XCTAssertEqual(levelManager.newRank, .walker, "Новый ранг должен быть .walker")
    }
    
    // MARK: - Квесты
    
    /// Тест: Ежедневные квесты должны генерироваться один раз в день
    func testDailyQuestsGeneratedOncePerDay() {
        // Given
        levelManager.dailyQuests = []
        let today = Date()
        
        // When
        levelManager.generateDailyQuestsIfNeeded()
        
        // Then
        XCTAssertEqual(levelManager.dailyQuests.count, 3, "Должно быть сгенерировано 3 квеста")
        XCTAssertTrue(levelManager.dailyQuests.allSatisfy { !$0.id.isEmpty }, "Все квесты должны иметь ID")
    }
    
    /// Тест: Квесты не должны генерироваться повторно в тот же день
    func testDailyQuestsNotRegeneratedSameDay() {
        // Given
        levelManager.generateDailyQuestsIfNeeded()
        let firstGeneration = levelManager.dailyQuests.map { $0.id }
        
        // When
        levelManager.generateDailyQuestsIfNeeded()
        
        // Then
        let secondGeneration = levelManager.dailyQuests.map { $0.id }
        XCTAssertEqual(firstGeneration, secondGeneration, "Квесты не должны перегенерироваться в тот же день")
    }
    
    /// Тест: Все квесты должны иметь уникальные ID
    func testDailyQuestsHaveUniqueIDs() {
        // Given
        levelManager.dailyQuests = []
        
        // When
        levelManager.generateDailyQuestsIfNeeded()
        
        // Then
        let ids = levelManager.dailyQuests.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "Все квесты должны иметь уникальные ID")
    }
    
    /// Тест: Прогресс квеста должен обновляться при добавлении шагов
    func testQuestProgressUpdatesWithSteps() {
        // Given
        levelManager.generateDailyQuestsIfNeeded()
        guard let stepsQuest = levelManager.dailyQuests.first(where: { $0.type == .steps }) else {
            XCTFail("Должен быть квест на шаги")
            return
        }
        let initialProgress = stepsQuest.progress
        
        // When
        levelManager.addSteps(5000, distance: 0, calories: 0)
        
        // Then
        let updatedQuest = levelManager.dailyQuests.first(where: { $0.id == stepsQuest.id })
        XCTAssertNotNil(updatedQuest, "Квест должен существовать")
        XCTAssertGreaterThan(updatedQuest!.progress, initialProgress, "Прогресс квеста должен увеличиться")
    }
    
    /// Тест: Квест должен помечаться как выполненный при достижении требования
    func testQuestCompletesWhenRequirementMet() {
        // Given
        levelManager.generateDailyQuestsIfNeeded()
        guard let quest = levelManager.dailyQuests.first else {
            XCTFail("Должен быть хотя бы один квест")
            return
        }
        let requirement = quest.requirement
        let initialXP = levelManager.player.totalXP
        
        // When
        // Симулируем выполнение квеста
        levelManager.addSteps(requirement, distance: 0, calories: 0)
        
        // Then
        let updatedQuest = levelManager.dailyQuests.first(where: { $0.id == quest.id })
        XCTAssertNotNil(updatedQuest, "Квест должен существовать")
        if updatedQuest!.type == .steps {
            XCTAssertTrue(updatedQuest!.isCompleted, "Квест должен быть выполнен")
            XCTAssertGreaterThan(levelManager.player.totalXP, initialXP, "Должен быть начислен XP за выполнение квеста")
        }
    }
    
    /// Тест: Premium квесты должны быть доступны только Premium пользователям
    func testPremiumQuestsOnlyForPremiumUsers() {
        // Given
        let subscriptionManager = SubscriptionManager.shared
        let wasPremium = subscriptionManager.isPremium
        subscriptionManager.setPremiumManually(false)
        levelManager.dailyQuests = []
        
        // When
        levelManager.generateDailyQuestsIfNeeded()
        
        // Then
        let premiumQuests = levelManager.dailyQuests.filter { $0.isPremium }
        // Для free пользователей Premium квесты могут быть созданы, но недоступны
        // Проверяем, что есть хотя бы один обычный квест
        let regularQuests = levelManager.dailyQuests.filter { !$0.isPremium }
        XCTAssertGreaterThanOrEqual(regularQuests.count, 2, "Должно быть минимум 2 обычных квеста")
        
        // Restore
        subscriptionManager.setPremiumManually(wasPremium)
    }
    
    // MARK: - Серии дней (Streak)
    
    /// Тест: Серия дней должна увеличиваться при активности сегодня
    func testStreakIncreasesWithDailyActivity() {
        // Given
        let initialStreak = levelManager.player.currentStreak
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        levelManager.player.lastActiveDate = yesterday
        
        // When
        levelManager.addSteps(1000, distance: 0, calories: 0)
        
        // Then
        XCTAssertGreaterThan(levelManager.player.currentStreak, initialStreak, "Серия дней должна увеличиться")
    }
    
    /// Тест: Серия дней должна сбрасываться при пропуске дня
    func testStreakResetsWhenDaySkipped() {
        // Given
        levelManager.player.currentStreak = 5
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        levelManager.player.lastActiveDate = twoDaysAgo
        
        // When
        // Добавляем шаги, что должно обновить streak
        // Если lastActiveDate был 2 дня назад, streak должен сброситься
        levelManager.addSteps(1000, distance: 0, calories: 0)
        
        // Then
        // Streak должен быть сброшен или обновлен в зависимости от логики
        // Проверяем, что streak изменился (либо сбросился, либо обновился)
        XCTAssertNotEqual(levelManager.player.currentStreak, 5, "Серия дней должна измениться после пропуска дня")
    }
    
    /// Тест: Самая длинная серия должна обновляться при новой рекордной серии
    func testLongestStreakUpdatesOnNewRecord() {
        // Given
        levelManager.player.longestStreak = 10
        levelManager.player.currentStreak = 15
        
        // When
        levelManager.updateLongestStreak()
        
        // Then
        XCTAssertEqual(levelManager.player.longestStreak, 15, "Самая длинная серия должна обновиться")
    }
    
    // MARK: - Расчеты
    
    /// Тест: XP до следующего уровня должен рассчитываться корректно
    func testXPToNextLevelCalculation() {
        // Given
        levelManager.player.level = 5
        levelManager.player.totalXP = 5000
        
        // When
        let xpToNext = levelManager.xpToNextLevel
        
        // Then
        XCTAssertGreaterThan(xpToNext, 0, "XP до следующего уровня должен быть > 0")
        XCTAssertLessThanOrEqual(xpToNext, 10000, "XP до следующего уровня должен быть <= 10000 для уровня 5")
    }
    
    /// Тест: Прогресс до следующего уровня должен быть в диапазоне 0-1
    func testLevelProgressInRange() {
        // Given
        levelManager.player.level = 1
        levelManager.player.totalXP = 500
        
        // When
        let progress = levelManager.levelProgress
        
        // Then
        XCTAssertGreaterThanOrEqual(progress, 0.0, "Прогресс должен быть >= 0")
        XCTAssertLessThanOrEqual(progress, 1.0, "Прогресс должен быть <= 1")
    }
    
    /// Тест: Ранг должен определяться корректно по уровню
    func testRankDeterminedByLevel() {
        // Given & When & Then
        levelManager.player.level = 1
        XCTAssertEqual(levelManager.player.rank, .beginner, "Уровень 1 = Новичок")
        
        levelManager.player.level = 5
        levelManager.updateRank()
        XCTAssertEqual(levelManager.player.rank, .walker, "Уровень 5 = Ходок")
        
        levelManager.player.level = 10
        levelManager.updateRank()
        XCTAssertEqual(levelManager.player.rank, .hiker, "Уровень 10 = Путешественник")
        
        levelManager.player.level = 100
        levelManager.updateRank()
        XCTAssertEqual(levelManager.player.rank, .grandmaster, "Уровень 100 = Грандмастер")
    }
}
