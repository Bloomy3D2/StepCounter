//
//  GroupChallengeManagerTests.swift
//  StepCounterTests
//
//  Тесты для групповых челленджей
//

import XCTest
@testable import StepCounter

@MainActor
final class GroupChallengeManagerTests: XCTestCase {
    
    var groupChallengeManager: GroupChallengeManager!
    var subscriptionManager: SubscriptionManager!
    
    override func setUp() {
        super.setUp()
        groupChallengeManager = GroupChallengeManager()
        subscriptionManager = SubscriptionManager.shared
    }
    
    override func tearDown() {
        groupChallengeManager = nil
        subscriptionManager.setPremiumManually(false)
        super.tearDown()
    }
    
    // MARK: - Создание челленджа
    
    /// Тест: Premium пользователь должен иметь возможность создать групповой челлендж
    func testPremiumUserCanCreateGroupChallenge() {
        // Given
        subscriptionManager.setPremiumManually(true)
        let challengeName = "Командный марафон"
        let challengeType = ChallengeType.steps
        let target = 100000
        let durationDays = 7
        let participants = ["user1", "user2", "user3"]
        
        // When
        let success = groupChallengeManager.createChallenge(
            name: challengeName,
            type: challengeType,
            target: target,
            durationDays: durationDays,
            participants: participants
        )
        
        // Then
        XCTAssertTrue(success, "Premium пользователь должен иметь возможность создать групповой челлендж")
        XCTAssertGreaterThan(groupChallengeManager.activeChallenges.count, 0, "Должен быть создан активный челлендж")
    }
    
    /// Тест: Free пользователь не должен иметь возможность создать групповой челлендж
    func testFreeUserCannotCreateGroupChallenge() {
        // Given
        subscriptionManager.setPremiumManually(false)
        let challengeName = "Командный марафон"
        let challengeType = ChallengeType.steps
        let target = 100000
        let durationDays = 7
        let participants = ["user1", "user2"]
        
        // When
        let success = groupChallengeManager.createChallenge(
            name: challengeName,
            type: challengeType,
            target: target,
            durationDays: durationDays,
            participants: participants
        )
        
        // Then
        XCTAssertFalse(success, "Free пользователь не должен иметь возможность создать групповой челлендж")
    }
    
    // MARK: - Ранги участников
    
    /// Тест: Участники должны иметь корректные ранги
    func testParticipantsHaveCorrectRanks() {
        // Given
        subscriptionManager.setPremiumManually(true)
        let participants = ["user1", "user2", "user3"]
        let success = groupChallengeManager.createChallenge(
            name: "Test Challenge",
            type: .steps,
            target: 10000,
            durationDays: 7,
            participants: participants
        )
        XCTAssertTrue(success, "Челлендж должен быть создан")
        
        // When
        guard let challenge = groupChallengeManager.activeChallenges.first else {
            XCTFail("Должен быть активный челлендж")
            return
        }
        
        // Then
        XCTAssertEqual(challenge.participants.count, participants.count, "Количество участников должно совпадать")
        for participant in challenge.participants {
            XCTAssertGreaterThan(participant.rank, 0, "Участник должен иметь ранг > 0")
        }
    }
    
    /// Тест: Участники должны быть отсортированы по прогрессу
    func testParticipantsSortedByProgress() {
        // Given
        subscriptionManager.setPremiumManually(true)
        let success = groupChallengeManager.createChallenge(
            name: "Test Challenge",
            type: .steps,
            target: 10000,
            durationDays: 7,
            participants: ["user1", "user2", "user3"]
        )
        XCTAssertTrue(success, "Челлендж должен быть создан")
        
        // When
        guard var challenge = groupChallengeManager.activeChallenges.first else {
            XCTFail("Должен быть активный челлендж")
            return
        }
        
        // Устанавливаем разный прогресс участникам
        for i in challenge.participants.indices {
            challenge.participants[i].progress = (i + 1) * 1000
        }
        challenge.updateRanks()
        
        // Then
        for i in 0..<challenge.participants.count - 1 {
            XCTAssertGreaterThanOrEqual(
                challenge.participants[i].progress,
                challenge.participants[i + 1].progress,
                "Участники должны быть отсортированы по убыванию прогресса"
            )
        }
    }
    
    // MARK: - Прогресс команды
    
    /// Тест: Прогресс команды должен рассчитываться корректно
    func testTeamProgressCalculation() {
        // Given
        subscriptionManager.setPremiumManually(true)
        let target = 10000
        let success = groupChallengeManager.createChallenge(
            name: "Test Challenge",
            type: .steps,
            target: target,
            durationDays: 7,
            participants: ["user1", "user2"]
        )
        XCTAssertTrue(success, "Челлендж должен быть создан")
        
        // When
        guard var challenge = groupChallengeManager.activeChallenges.first else {
            XCTFail("Должен быть активный челлендж")
            return
        }
        
        // Устанавливаем прогресс участникам
        challenge.participants[0].progress = 3000
        challenge.participants[1].progress = 2000
        
        // Then
        let totalProgress = challenge.totalProgress
        XCTAssertEqual(totalProgress, 5000, "Общий прогресс должен быть суммой прогрессов участников")
        
        let teamProgress = challenge.teamProgress
        XCTAssertEqual(teamProgress, 0.5, accuracy: 0.01, "Прогресс команды должен быть 50% при 5000/10000")
    }
}
