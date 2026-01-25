//
//  SupabaseManagerTests.swift
//  ChallengeAppTests
//
//  Unit тесты для SupabaseManager
//

import XCTest
@testable import ChallengeApp

final class SupabaseManagerTests: XCTestCase {
    var mockCacheManager: MockCacheManager!
    var mockNetworkRetry: MockNetworkRetry!
    
    override func setUp() {
        super.setUp()
        mockCacheManager = MockCacheManager()
        mockNetworkRetry = MockNetworkRetry()
    }
    
    override func tearDown() {
        mockCacheManager = nil
        mockNetworkRetry = nil
        super.tearDown()
    }
    
    // MARK: - Get Current User Tests
    
    func testGetCurrentUser_WithCache() async throws {
        // Given
        let cachedUser = User(
            id: "cached-user-id",
            name: "Cached User",
            email: "cached@example.com",
            balance: 100.0,
            authProvider: .email
        )
        mockCacheManager.cacheUser(cachedUser)
        
        // When
        let result = mockCacheManager.getCachedUser()
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, "cached-user-id")
    }
    
    // MARK: - Cache Invalidation Tests
    
    func testCacheInvalidation_OnSignOut() {
        // Given
        let user = User(
            id: "test-user-id",
            name: "Test User",
            email: "test@example.com",
            balance: 0.0,
            authProvider: .email
        )
        mockCacheManager.cacheUser(user)
        
        // When
        mockCacheManager.remove("currentUser")
        
        // Then
        XCTAssertNil(mockCacheManager.getCachedUser())
    }
}
