//
//  ChallengeManagerTests.swift
//  ChallengeAppTests
//
//  Unit тесты для ChallengeManager
//

import XCTest
@testable import ChallengeApp

@MainActor
final class ChallengeManagerTests: XCTestCase {
    var sut: ChallengeManager!
    var mockSupabaseManager: MockSupabaseManager!
    var mockCacheManager: MockCacheManager!
    
    override func setUp() {
        super.setUp()
        mockSupabaseManager = MockSupabaseManager()
        mockCacheManager = MockCacheManager()
        sut = ChallengeManager(
            supabaseManager: mockSupabaseManager,
            cacheManager: mockCacheManager
        )
    }
    
    override func tearDown() {
        sut = nil
        mockSupabaseManager = nil
        mockCacheManager = nil
        super.tearDown()
    }
    
    // MARK: - Load Challenges Tests
    
    func testLoadChallengesFromSupabase_Success() async {
        // Given
        let expectedChallenges = [
            Challenge(
                id: "1",
                title: "Test Challenge",
                description: "Test Description",
                entryFee: 100.0,
                prizePool: 1000.0,
                duration: 7,
                startDate: Date(),
                endDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
                rules: ["Rule 1", "Rule 2"],
                isActive: true
            )
        ]
        mockSupabaseManager.getChallengesResult = expectedChallenges
        
        // When
        await sut.loadChallengesFromSupabase()
        
        // Then
        XCTAssertEqual(sut.availableChallenges.count, 1)
        XCTAssertEqual(sut.availableChallenges.first?.id, "1")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.lastError)
        
        // Проверяем, что данные закэшированы
        let cached = mockCacheManager.getCachedChallenges()
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.count, 1)
    }
    
    func testLoadChallengesFromSupabase_WithCache() async {
        // Given
        let cachedChallenges = [
            Challenge(
                id: "1",
                title: "Cached Challenge",
                subtitle: "Cached",
                icon: "flame",
                duration: 5,
                entryFee: 50.0,
                serviceFee: 10.0,
                startDate: Date(),
                endDate: Date().addingTimeInterval(5 * 24 * 60 * 60),
                participants: 0,
                prizePool: 500.0,
                activeParticipants: 0,
                description: "Cached",
                rules: []
            )
        ]
        mockCacheManager.cacheChallenges(cachedChallenges)
        
        let networkChallenges = [
            Challenge(
                id: "2",
                title: "Network Challenge",
                subtitle: "Network",
                icon: "flame",
                duration: 10,
                entryFee: 200.0,
                serviceFee: 10.0,
                startDate: Date(),
                endDate: Date().addingTimeInterval(10 * 24 * 60 * 60),
                participants: 0,
                prizePool: 2000.0,
                activeParticipants: 0,
                description: "Network",
                rules: []
            )
        ]
        mockSupabaseManager.getChallengesResult = networkChallenges
        
        // When
        await sut.loadChallengesFromSupabase()
        
        // Then
        // Сначала показываются кэшированные данные
        // Затем обновляются из сети
        XCTAssertEqual(sut.availableChallenges.count, 1)
        XCTAssertEqual(sut.availableChallenges.first?.id, "2") // Обновлено из сети
    }
    
    func testLoadChallengesFromSupabase_NetworkError() async {
        // Given
        mockSupabaseManager.getChallengesResult = []
        // Симулируем ошибку сети через отсутствие результата
        mockCacheManager.shouldReturnNil = true
        
        // When
        await sut.loadChallengesFromSupabase()
        
        // Then
        XCTAssertNotNil(sut.lastError)
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Load User Challenges Tests
    
    func testLoadUserChallengesFromSupabase_Success() async {
        // Given
        let expectedUserChallenges = [
            UserChallenge(
                id: "1",
                challengeId: "1",
                userId: "test-user-id",
                entryDate: Date(),
                completedDays: [],
                isActive: true,
                isCompleted: false,
                isFailed: false,
                payout: 0.0
            )
        ]
        mockSupabaseManager.getUserChallengesResult = expectedUserChallenges
        
        // When
        await sut.loadUserChallengesFromSupabase()
        
        // Then
        XCTAssertEqual(sut.userChallenges.count, 1)
        XCTAssertFalse(sut.isLoading)
        
        // Проверяем кэш
        let cached = mockCacheManager.getCachedUserChallenges()
        XCTAssertNotNil(cached)
    }
    
    // MARK: - Join Challenge Tests
    
    func testJoinChallenge_Success() async throws {
        // Given
        let challenge = Challenge(
            id: "1",
            title: "Test Challenge",
            subtitle: "Test",
            icon: "flame",
            duration: 7,
            entryFee: 100.0,
            serviceFee: 10.0,
            startDate: Date(),
            endDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            participants: 0,
            prizePool: 1000.0,
            activeParticipants: 0,
            description: "Test",
            rules: []
        )
        
        let expectedUserChallenge = UserChallenge(
            id: "1",
            challengeId: "1",
            userId: "test-user-id",
            entryDate: Date(),
            completedDays: [],
            isActive: true,
            isCompleted: false,
            isFailed: false,
            payout: 0.0
        )
        
        mockSupabaseManager.joinChallengeResult = .success(expectedUserChallenge)
        
        // When
        let result = try await sut.joinChallenge(challenge, userId: "test-user-id")
        
        // Then
        XCTAssertEqual(result.id, "1")
        XCTAssertEqual(result.challengeId, "1")
        XCTAssertTrue(sut.userChallenges.contains(where: { $0.id == "1" }))
        XCTAssertEqual(sut.activeChallenge?.id, "1")
    }
    
    func testJoinChallenge_AlreadyJoined() async {
        // Given
        let challenge = Challenge(
            id: "1",
            title: "Test Challenge",
            subtitle: "Test",
            icon: "flame",
            duration: 7,
            entryFee: 100.0,
            serviceFee: 10.0,
            startDate: Date(),
            endDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            participants: 0,
            prizePool: 1000.0,
            activeParticipants: 0,
            description: "Test",
            rules: []
        )
        
        mockSupabaseManager.joinChallengeResult = .failure(
            AppError.alreadyJoined
        )
        
        // When & Then
        do {
            _ = try await sut.joinChallenge(challenge, userId: "test-user-id")
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is AppError)
            if let appError = error as? AppError {
                XCTAssertEqual(appError, AppError.alreadyJoined)
            }
        }
    }
    
    // MARK: - Complete Day Tests
    
    func testCompleteDay_Success() async throws {
        // Given
        let userChallenge = UserChallenge(
            id: "1",
            challengeId: "1",
            userId: "test-user-id",
            entryDate: Date(),
            completedDays: [],
            isActive: true,
            isCompleted: false,
            isFailed: false,
            payout: 0.0
        )
        sut.userChallenges = [userChallenge]
        mockSupabaseManager.completeDayError = nil
        
        // When
        try await sut.completeDay(for: userChallenge)
        
        // Then
        // Проверяем, что день добавлен локально
        let updated = sut.userChallenges.first(where: { $0.id == "1" })
        XCTAssertNotNil(updated)
        XCTAssertEqual(updated?.completedDays.count, 1)
    }
    
    // MARK: - Fail Challenge Tests
    
    func testFailChallenge_Success() async throws {
        // Given
        let userChallenge = UserChallenge(
            id: "1",
            challengeId: "1",
            userId: "test-user-id",
            entryDate: Date(),
            completedDays: [],
            isActive: true,
            isCompleted: false,
            isFailed: false,
            payout: 0.0
        )
        sut.userChallenges = [userChallenge]
        sut.activeChallenge = userChallenge
        mockSupabaseManager.failChallengeError = nil
        
        // When
        try await sut.failChallenge(userChallenge)
        
        // Then
        let updated = sut.userChallenges.first(where: { $0.id == 1 })
        XCTAssertNotNil(updated)
        XCTAssertTrue(updated?.isFailed ?? false)
        XCTAssertFalse(updated?.isActive ?? true)
        XCTAssertNil(sut.activeChallenge)
    }
    
    // MARK: - Get Challenge Tests
    
    func testGetChallenge_Exists() {
        // Given
        let challenge = Challenge(
            id: "1",
            title: "Test",
            subtitle: "Test",
            icon: "flame",
            duration: 7,
            entryFee: 100.0,
            serviceFee: 10.0,
            startDate: Date(),
            endDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            participants: 0,
            prizePool: 1000.0,
            activeParticipants: 0,
            description: "Test",
            rules: []
        )
        sut.availableChallenges = [challenge]
        
        // When - getChallenge принимает Int64, но Challenge.id это String
        // Конвертируем String в Int64 для теста
        // getChallenge принимает Int64, конвертируем String id в Int64
        let challengeId = Int64(challenge.id) ?? 1
        let result = sut.getChallenge(id: challengeId)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, "1")
    }
    
    func testGetChallenge_NotExists() {
        // Given
        sut.availableChallenges = []
        
        // When
        let result = sut.getChallenge(id: 999)
        
        // Then
        XCTAssertNil(result)
    }
}
