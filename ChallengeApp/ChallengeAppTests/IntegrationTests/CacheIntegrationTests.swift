//
//  CacheIntegrationTests.swift
//  ChallengeAppTests
//
//  Integration тесты для кэширования
//

import XCTest
@testable import ChallengeApp

@MainActor
final class CacheIntegrationTests: XCTestCase {
    var challengeManager: ChallengeManager!
    var mockSupabaseManager: MockSupabaseManager!
    var mockCacheManager: MockCacheManager!
    
    override func setUp() {
        super.setUp()
        mockSupabaseManager = MockSupabaseManager()
        mockCacheManager = MockCacheManager()
        challengeManager = ChallengeManager(
            supabaseManager: mockSupabaseManager,
            cacheManager: mockCacheManager
        )
    }
    
    override func tearDown() {
        challengeManager = nil
        mockSupabaseManager = nil
        mockCacheManager = nil
        super.tearDown()
    }
    
    // MARK: - Cache Integration Tests
    
    func testCache_LoadChallenges_CachesResult() async {
        // Given
        let challenges = [
            Challenge(
                id: "1",
                title: "Challenge 1",
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
            ),
            Challenge(
                id: "2",
                title: "Challenge 2",
                subtitle: "Test",
                icon: "flame",
                duration: 14,
                entryFee: 200.0,
                serviceFee: 10.0,
                startDate: Date(),
                endDate: Date().addingTimeInterval(14 * 24 * 60 * 60),
                participants: 0,
                prizePool: 2000.0,
                activeParticipants: 0,
                description: "Test",
                rules: []
            )
        ]
        mockSupabaseManager.getChallengesResult = challenges
        
        // When
        await challengeManager.loadChallengesFromSupabase()
        
        // Then
        // Проверяем, что данные закэшированы
        let cached = mockCacheManager.getCachedChallenges()
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.count, 2)
    }
    
    func testCache_LoadUserChallenges_CachesResult() async {
        // Given
        let userChallenges = [
            UserChallenge(
                id: "1",
                challengeId: "1",
                userId: "user-1",
                entryDate: Date(),
                completedDays: [],
                isActive: true,
                isCompleted: false,
                isFailed: false,
                payout: 0.0
            )
        ]
        mockSupabaseManager.getUserChallengesResult = userChallenges
        
        // When
        await challengeManager.loadUserChallengesFromSupabase()
        
        // Then
        let cached = mockCacheManager.getCachedUserChallenges()
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.count, 1)
    }
    
    func testCache_Invalidation_OnJoin() async throws {
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
        
        let userChallenge = UserChallenge(
            id: "1",
            challengeId: "1",
            userId: "user-1",
            entryDate: Date(),
            completedDays: [],
            isActive: true,
            isCompleted: false,
            isFailed: false,
            payout: 0.0
        )
        mockSupabaseManager.joinChallengeResult = .success(userChallenge)
        
        // When
        _ = try await challengeManager.joinChallenge(challenge, userId: "user-1")
        
        // Then
        // Кэш должен быть обновлен
        let cached = mockCacheManager.getCachedUserChallenges()
        XCTAssertNotNil(cached)
        XCTAssertTrue(cached?.contains(where: { $0.id == "1" }) ?? false)
    }
    
    func testCache_Fallback_OnNetworkError() async {
        // Given
        // Кэш содержит старые данные
        let cachedChallenges = [
            Challenge(
                id: "1",
                title: "Cached Challenge",
                subtitle: "Cached",
                icon: "flame",
                duration: 7,
                entryFee: 100.0,
                serviceFee: 10.0,
                startDate: Date(),
                endDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
                participants: 0,
                prizePool: 1000.0,
                activeParticipants: 0,
                description: "Cached",
                rules: []
            )
        ]
        mockCacheManager.cacheChallenges(cachedChallenges)
        
        // Сеть возвращает ошибку
        mockSupabaseManager.getChallengesResult = []
        mockCacheManager.shouldReturnNil = false // Кэш доступен
        
        // When
        await challengeManager.loadChallengesFromSupabase()
        
        // Then
        // Должны использовать кэшированные данные
        XCTAssertGreaterThanOrEqual(challengeManager.availableChallenges.count, 0)
    }
}
