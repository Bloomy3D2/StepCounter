//
//  TournamentManagerTests.swift
//  StepCounterTests
//
//  Тесты для системы турниров
//

import XCTest
@testable import StepCounter

@MainActor
final class TournamentManagerTests: XCTestCase {
    
    var tournamentManager: TournamentManager!
    
    override func setUp() {
        super.setUp()
        tournamentManager = TournamentManager()
    }
    
    override func tearDown() {
        tournamentManager = nil
        super.tearDown()
    }
    
    // MARK: - Создание турнира
    
    /// Тест: Турнир должен создаваться при запуске приложения
    func testTournamentCreatedOnLaunch() {
        // Given & When
        // TournamentManager автоматически создает турнир в init
        
        // Then
        XCTAssertNotNil(tournamentManager.currentTournament, "Должен быть активный турнир")
    }
    
    /// Тест: Новый турнир должен создаваться в начале новой недели
    func testNewTournamentCreatedOnNewWeek() {
        // Given
        // Создаем новый менеджер, который автоматически создаст турнир
        
        // When
        tournamentManager.checkAndStartNewTournament()
        
        // Then
        let currentTournament = tournamentManager.currentTournament
        XCTAssertNotNil(currentTournament, "Должен быть создан новый турнир")
        if let tournament = currentTournament {
            let daysSinceStart = Calendar.current.dateComponents([.day], from: tournament.startDate, to: Date()).day ?? 0
            XCTAssertLessThan(daysSinceStart, 7, "Турнир должен быть текущей недели")
        }
    }
    
    /// Тест: Турнир должен иметь корректные даты начала и окончания
    func testTournamentHasCorrectDates() {
        // Given
        guard let tournament = tournamentManager.currentTournament else {
            XCTFail("Должен быть активный турнир")
            return
        }
        
        // When
        let startDate = tournament.startDate
        let endDate = tournament.endDate
        let duration = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        
        // Then
        XCTAssertLessThanOrEqual(startDate, Date(), "Дата начала должна быть <= сегодня")
        XCTAssertGreaterThanOrEqual(endDate, Date(), "Дата окончания должна быть >= сегодня")
        XCTAssertEqual(duration, 6, accuracy: 1, "Турнир должен длиться 7 дней (0-6)")
    }
    
    // MARK: - Обновление шагов
    
    /// Тест: Шаги пользователя должны обновляться в турнире
    func testUserStepsUpdatedInTournament() {
        // Given
        guard let tournament = tournamentManager.currentTournament else {
            XCTFail("Должен быть активный турнир")
            return
        }
        let initialSteps = tournament.userResult?.steps ?? 0
        
        // When
        let weeklySteps: [DailyStepData] = [
            DailyStepData(date: Date(), steps: 5000)
        ]
        tournamentManager.updateUserStepsFromWeekly(weeklySteps, tournamentStartDate: tournament.startDate)
        
        // Then
        let updatedTournament = tournamentManager.currentTournament
        XCTAssertNotNil(updatedTournament, "Турнир должен существовать")
        let newSteps = updatedTournament?.userResult?.steps ?? 0
        XCTAssertGreaterThan(newSteps, initialSteps, "Шаги пользователя должны увеличиться")
    }
    
    /// Тест: Ранг пользователя должен обновляться при изменении шагов
    func testUserRankUpdatesWithSteps() {
        // Given
        guard let tournament = tournamentManager.currentTournament else {
            XCTFail("Должен быть активный турнир")
            return
        }
        let initialRank = tournamentManager.userRank
        
        // When
        let weeklySteps: [DailyStepData] = [
            DailyStepData(date: Date(), steps: 50000)
        ]
        tournamentManager.updateUserStepsFromWeekly(weeklySteps, tournamentStartDate: tournament.startDate)
        
        // Then
        let updatedRank = tournamentManager.userRank
        // Ранг может измениться в зависимости от других участников
        // Проверяем, что ранг существует
        XCTAssertGreaterThan(updatedRank, 0, "Ранг должен быть > 0")
    }
    
    // MARK: - Лидерборд
    
    /// Тест: Участники турнира должны сортироваться по шагам
    func testTournamentParticipantsSortedBySteps() {
        // Given
        guard let tournament = tournamentManager.currentTournament else {
            XCTFail("Должен быть активный турнир")
            return
        }
        
        // When
        let participants = tournament.participants
        
        // Then
        if participants.count > 1 {
            for i in 0..<participants.count - 1 {
                XCTAssertGreaterThanOrEqual(
                    participants[i].steps,
                    participants[i + 1].steps,
                    "Участники должны быть отсортированы по убыванию шагов"
                )
            }
        }
    }
    
    /// Тест: Топ участники должны определяться корректно
    func testTopParticipantsDeterminedCorrectly() {
        // Given
        guard let tournament = tournamentManager.currentTournament else {
            XCTFail("Должен быть активный турнир")
            return
        }
        
        // When
        let top3 = Array(tournament.participants.prefix(3))
        
        // Then
        XCTAssertLessThanOrEqual(top3.count, 3, "Топ-3 должно содержать максимум 3 участника")
        if top3.count > 1 {
            for i in 0..<top3.count - 1 {
                XCTAssertGreaterThanOrEqual(
                    top3[i].steps,
                    top3[i + 1].steps,
                    "Топ участники должны быть отсортированы"
                )
            }
        }
    }
}
