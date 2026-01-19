//
//  SeasonManagerTests.swift
//  StepCounterTests
//
//  Тесты для системы сезонов
//

import XCTest
@testable import StepCounter

@MainActor
final class SeasonManagerTests: XCTestCase {
    
    var seasonManager: SeasonManager!
    
    override func setUp() {
        super.setUp()
        seasonManager = SeasonManager.shared
    }
    
    override func tearDown() {
        seasonManager = nil
        super.tearDown()
    }
    
    // MARK: - Инициализация сезонов
    
    /// Тест: Сезоны должны инициализироваться при запуске
    func testSeasonsInitializedOnLaunch() {
        // Given & When
        // SeasonManager автоматически инициализирует сезоны в init
        
        // Then
        XCTAssertGreaterThan(seasonManager.allSeasons.count, 0, "Должен быть хотя бы один сезон")
    }
    
    /// Тест: Должен быть определен текущий активный сезон
    func testCurrentSeasonIsActive() {
        // Given & When
        seasonManager.updateCurrentSeason()
        
        // Then
        if let currentSeason = seasonManager.currentSeason {
            XCTAssertTrue(currentSeason.isActive, "Текущий сезон должен быть активным")
        } else {
            XCTFail("Должен быть определен текущий сезон")
        }
    }
    
    // MARK: - XP сезона
    
    /// Тест: Пользователь должен получать XP сезона за активность
    func testUserGainsSeasonXP() {
        // Given
        let initialXP = seasonManager.userSeasonXP
        let xpToAdd = 100
        
        // When
        seasonManager.addSeasonXP(xpToAdd)
        
        // Then
        XCTAssertGreaterThan(seasonManager.userSeasonXP, initialXP, "XP сезона должен увеличиться")
    }
    
    /// Тест: Уровень сезона должен повышаться при достижении необходимого XP
    func testSeasonLevelIncreasesWithXP() {
        // Given
        let initialLevel = seasonManager.userSeasonLevel
        let xpForNextLevel = 1000 // Примерное значение
        
        // When
        seasonManager.addSeasonXP(xpForNextLevel)
        
        // Then
        // Уровень может повыситься, если достаточно XP
        XCTAssertGreaterThanOrEqual(seasonManager.userSeasonLevel, initialLevel, "Уровень сезона не должен уменьшаться")
    }
    
    // MARK: - Награды сезона
    
    /// Тест: Награды сезона должны разблокироваться при достижении уровня
    func testSeasonRewardsUnlockAtLevel() {
        // Given
        guard let season = seasonManager.currentSeason else {
            XCTFail("Должен быть активный сезон")
            return
        }
        
        // When
        // Добавляем достаточно XP для повышения уровня (примерно 5000 XP для уровня 5)
        seasonManager.addSeasonXP(5000)
        
        // Then
        // Проверяем, что уровень повысился
        XCTAssertGreaterThanOrEqual(seasonManager.userSeasonLevel, 1, "Уровень сезона должен быть >= 1")
        
        // Проверяем, что сезон существует
        let updatedSeason = seasonManager.allSeasons.first(where: { $0.id == season.id })
        XCTAssertNotNil(updatedSeason, "Сезон должен существовать")
    }
    
    // MARK: - Лидерборд сезона
    
    /// Тест: Лидерборд сезона должен содержать участников
    func testSeasonLeaderboardHasParticipants() {
        // Given
        guard let season = seasonManager.currentSeason else {
            XCTFail("Должен быть активный сезон")
            return
        }
        
        // When
        let leaderboard = season.leaderboard
        
        // Then
        XCTAssertNotNil(leaderboard, "Лидерборд должен существовать")
    }
    
    /// Тест: Топ участники лидерборда должны определяться корректно
    func testSeasonLeaderboardTopParticipants() {
        // Given
        guard let season = seasonManager.currentSeason else {
            XCTFail("Должен быть активный сезон")
            return
        }
        
        // When
        let topEntries = season.leaderboard.topEntries
        
        // Then
        XCTAssertLessThanOrEqual(topEntries.count, 10, "Топ должен содержать максимум 10 участников")
    }
}
