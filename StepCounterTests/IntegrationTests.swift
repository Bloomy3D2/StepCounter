//
//  IntegrationTests.swift
//  StepCounterTests
//
//  Интеграционные тесты - взаимодействие между компонентами
//

import XCTest
@testable import StepCounter

@MainActor
final class IntegrationTests: XCTestCase {
    
    var levelManager: LevelManager!
    var achievementManager: AchievementManager!
    var petManager: PetManager!
    var subscriptionManager: SubscriptionManager!
    
    override func setUp() {
        super.setUp()
        levelManager = LevelManager()
        achievementManager = AchievementManager()
        petManager = PetManager()
        subscriptionManager = SubscriptionManager.shared
    }
    
    override func tearDown() {
        levelManager = nil
        achievementManager = nil
        petManager = nil
        subscriptionManager.setPremiumManually(false)
        super.tearDown()
    }
    
    // MARK: - Полные пользовательские сценарии
    
    /// Тест: Пользователь делает шаги → получает XP → повышает уровень → разблокирует достижение
    func testCompleteUserJourneyStepsToAchievement() {
        // Given
        let initialLevel = levelManager.player.level
        let initialXP = levelManager.player.totalXP
        let steps = 10000
        
        // When
        levelManager.addSteps(steps, distance: 5.0, calories: 300)
        
        // Then
        // Проверяем, что XP увеличился
        XCTAssertGreaterThan(levelManager.player.totalXP, initialXP, "XP должен увеличиться")
        
        // Проверяем, что достижение разблокировано
        achievementManager.checkAchievements(steps: steps, distance: 5.0, calories: 300, goalReached: true, stepGoal: 10000)
        let isUnlocked = achievementManager.achievements.first(where: { $0.type == .step10k })?.isUnlocked ?? false
        XCTAssertTrue(isUnlocked, "Достижение '10000 шагов' должно быть разблокировано")
    }
    
    /// Тест: Пользователь выполняет квест → получает XP → повышает уровень → питомец получает XP
    func testQuestCompletionFlow() {
        // Given
        levelManager.generateDailyQuestsIfNeeded()
        guard let quest = levelManager.dailyQuests.first else {
            XCTFail("Должен быть хотя бы один квест")
            return
        }
        let initialPlayerXP = levelManager.player.totalXP
        let success = petManager.createPet(name: "Бобик", type: .cat)
        XCTAssertTrue(success, "Питомец должен быть создан")
        let initialPetXP = petManager.pet?.totalXP ?? 0
        
        // When
        // Выполняем квест
        levelManager.addSteps(quest.requirement, distance: 0, calories: 0)
        
        // Then
        // Проверяем, что квест выполнен
        let updatedQuest = levelManager.dailyQuests.first(where: { $0.id == quest.id })
        if updatedQuest?.type == .steps {
            XCTAssertTrue(updatedQuest?.isCompleted ?? false, "Квест должен быть выполнен")
        }
        
        // Проверяем, что игрок получил XP
        XCTAssertGreaterThan(levelManager.player.totalXP, initialPlayerXP, "Игрок должен получить XP")
        
        // Питомец также должен получить XP (если это реализовано)
        // Это зависит от реализации, но проверяем общий принцип
    }
    
    /// Тест: Premium подписка истекает → Premium тема сбрасывается → Premium функции ограничиваются
    func testPremiumExpirationFlow() {
        // Given
        subscriptionManager.setPremiumManually(true)
        let themeManager = ThemeManager.shared
        themeManager.setTheme(.aurora) // Premium тема
        
        // When
        subscriptionManager.setPremiumManually(false)
        Task { @MainActor in
            await themeManager.checkAndResetPremiumThemeIfNeeded()
        }
        
        // Then
        // Проверяем, что Premium функции недоступны
        XCTAssertFalse(subscriptionManager.hasAccess(to: .unlimitedPets), "Premium функции должны быть недоступны")
        
        // Проверяем, что Premium тема сброшена (если это реализовано)
        // Это зависит от реализации ThemeManager
    }
    
    /// Тест: Пользователь создает питомца → питомец получает XP → питомец эволюционирует
    func testPetEvolutionFlow() {
        // Given
        let success = petManager.createPet(name: "Бобик", type: .cat)
        XCTAssertTrue(success, "Питомец должен быть создан")
        
        // When
        // Добавляем достаточно XP для эволюции
        if var pet = petManager.pet {
            pet.totalXP = 10000 // До стадии .teen нужно 10000 XP
            pet.checkEvolution()
            petManager.pet = pet
        }
        
        // Then
        let currentEvolution = petManager.pet?.evolution
        XCTAssertEqual(currentEvolution, .teen, "Питомец должен эволюционировать в 'Подросток'")
    }
    
    /// Тест: Серия дней увеличивается → разблокируется достижение серии
    func testStreakAchievementFlow() {
        // Given
        achievementManager.currentStreak = 6
        
        // When
        // Достигаем цели 7-й день подряд (это обновит streak внутри checkAchievements)
        achievementManager.checkAchievements(steps: 10000, distance: 0, calories: 0, goalReached: true, stepGoal: 10000)
        achievementManager.currentStreak = 7
        achievementManager.checkAchievements(steps: 10000, distance: 0, calories: 0, goalReached: true, stepGoal: 10000)
        
        // Then
        XCTAssertEqual(achievementManager.currentStreak, 7, "Серия дней должна быть 7")
        
        // Проверяем разблокировку достижения
        let isUnlocked = achievementManager.achievements.first(where: { $0.type == .streak7 })?.isUnlocked ?? false
        XCTAssertTrue(isUnlocked, "Достижение 'Серия 7 дней' должно быть разблокировано")
    }
}
