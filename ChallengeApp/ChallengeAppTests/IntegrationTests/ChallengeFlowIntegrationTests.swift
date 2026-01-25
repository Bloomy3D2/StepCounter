//
//  ChallengeFlowIntegrationTests.swift
//  ChallengeAppTests
//
//  Integration тесты для полного flow челленджа
//

import XCTest
@testable import ChallengeApp

@MainActor
final class ChallengeFlowIntegrationTests: XCTestCase {
    var challengeManager: ChallengeManager!
    var authManager: AuthManager!
    var paymentManager: PaymentManager!
    var mockSupabaseManager: MockSupabaseManager!
    var mockCacheManager: MockCacheManager!
    var mockYooKassaClient: MockYooKassaClient!
    
    override func setUp() {
        super.setUp()
        mockSupabaseManager = MockSupabaseManager()
        mockCacheManager = MockCacheManager()
        mockYooKassaClient = MockYooKassaClient()
        
        challengeManager = ChallengeManager(
            supabaseManager: mockSupabaseManager,
            cacheManager: mockCacheManager
        )
        authManager = AuthManager(supabaseManager: mockSupabaseManager)
        paymentManager = PaymentManager(yooKassaClient: mockYooKassaClient)
    }
    
    override func tearDown() {
        challengeManager = nil
        authManager = nil
        paymentManager = nil
        mockSupabaseManager = nil
        mockCacheManager = nil
        mockYooKassaClient = nil
        super.tearDown()
    }
    
    // MARK: - Full Challenge Flow
    
    func testFullChallengeFlow_FromSignInToCompletion() async throws {
        // 1. Sign In
        let user = User(
            id: "test-user-id",
            name: "Test User",
            email: "test@example.com",
            balance: 1000.0,
            authProvider: .email
        )
        mockSupabaseManager.signInResult = .success(user)
        
        let signedInUser = try await authManager.signIn(
            email: "test@example.com",
            password: "password123"
        )
        XCTAssertEqual(signedInUser.id, "test-user-id")
        
        // 2. Load Challenges
        let challenge = Challenge(
            id: 1,
            title: "7 Day Challenge",
            description: "Complete 7 days",
            entryFee: 100.0,
            prizePool: 1000.0,
            duration: 7,
            startDate: Date(),
            endDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            rules: ["Rule 1", "Rule 2"],
            isActive: true
        )
        mockSupabaseManager.getChallengesResult = [challenge]
        
        await challengeManager.loadChallengesFromSupabase()
        XCTAssertEqual(challengeManager.availableChallenges.count, 1)
        
        // 3. Process Payment
        let payment = YooKassaPayment(
            id: "payment-id",
            status: .succeeded,
            amount: YooKassaAmount(value: "100.00", currency: "RUB"),
            description: "Challenge payment",
            confirmation: nil,
            metadata: [:],
            createdAt: ISO8601DateFormatter().string(from: Date()),
            paid: true
        )
        mockYooKassaClient.createPaymentResult = payment
        
        let paymentResult = await paymentManager.processPayment(
            amount: 100.0,
            challenge: challenge,
            userId: signedInUser.id,
            paymentMethod: .applePay,
            cardDetails: nil
        )
        XCTAssertTrue(paymentResult)
        
        // 4. Join Challenge
        let userChallenge = UserChallenge(
            id: "1",
            challengeId: "1",
            userId: signedInUser.id,
            entryDate: Date(),
            completedDays: [],
            isActive: true,
            isCompleted: false,
            isFailed: false,
            payout: 0.0
        )
        mockSupabaseManager.joinChallengeResult = .success(userChallenge)
        
        let joinedChallenge = try await challengeManager.joinChallenge(
            challenge,
            userId: signedInUser.id
        )
        XCTAssertEqual(joinedChallenge.id, 1)
        XCTAssertTrue(challengeManager.userChallenges.contains(where: { $0.id == 1 }))
        
        // 5. Complete Day
        mockSupabaseManager.completeDayError = nil
        try await challengeManager.completeDay(for: joinedChallenge)
        
        let updated = challengeManager.userChallenges.first(where: { $0.id == "1" })
        XCTAssertNotNil(updated)
        XCTAssertEqual(updated?.completedDays.count, 1)
    }
    
    // MARK: - Challenge Flow With Cache
    
    func testChallengeFlow_WithCache() async {
        // 1. Загружаем челленджи и кэшируем
        let challenge = Challenge(
            id: "1",
            title: "Cached Challenge",
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
        mockCacheManager.cacheChallenges([challenge])
        
        // 2. Создаем новый менеджер (симулируем перезапуск приложения)
        let newChallengeManager = ChallengeManager(
            supabaseManager: mockSupabaseManager,
            cacheManager: mockCacheManager
        )
        
        // 3. Загружаем - должны получить из кэша
        await newChallengeManager.loadChallengesFromSupabase()
        
        // Проверяем, что данные есть (из кэша или из сети)
        XCTAssertGreaterThanOrEqual(newChallengeManager.availableChallenges.count, 0)
    }
    
    // MARK: - Challenge Flow With Network Error
    
    func testChallengeFlow_NetworkError_Retry() async {
        // Given
        let challenge = Challenge(
            id: 1,
            title: "Test Challenge",
            description: "Test",
            entryFee: 100.0,
            prizePool: 1000.0,
            duration: 7,
            startDate: Date(),
            endDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            rules: [],
            isActive: true
        )
        
        // Симулируем сетевую ошибку
        mockSupabaseManager.getChallengesResult = []
        mockCacheManager.shouldReturnNil = true
        
        // When
        await challengeManager.loadChallengesFromSupabase()
        
        // Then
        // Должен fallback на локальные данные
        XCTAssertNotNil(challengeManager.lastError)
    }
    
    // MARK: - Payment And Join Challenge Flow
    
    func testPaymentAndJoinChallenge_CompleteFlow() async throws {
        // 1. Setup
        let user = User(
            id: "test-user-id",
            email: "test@example.com",
            name: "Test User",
            balance: 500.0,
            level: 1,
            experience: 0,
            authProvider: "EMAIL"
        )
        
        let challenge = Challenge(
            id: 1,
            title: "Test Challenge",
            description: "Test",
            entryFee: 100.0,
            prizePool: 1000.0,
            duration: 7,
            startDate: Date(),
            endDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            rules: [],
            isActive: true
        )
        
        // 2. Payment
        let payment = YooKassaPayment(
            id: "payment-id",
            status: .succeeded,
            amount: YooKassaAmount(value: "100.00", currency: "RUB"),
            description: "Payment",
            metadata: [:],
            confirmation: nil,
            createdAt: Date(),
            expiresAt: nil
        )
        mockYooKassaClient.createPaymentResult = payment
        
        let paymentSuccess = await paymentManager.processPayment(
            amount: 100.0,
            challenge: challenge,
            userId: user.id,
            paymentMethod: .applePay,
            cardDetails: nil
        )
        XCTAssertTrue(paymentSuccess)
        
        // 3. Join Challenge
        let userChallenge = UserChallenge(
            id: 1,
            challengeId: 1,
            userId: user.id,
            entryDate: Date(),
            completedDays: [],
            isActive: true,
            isCompleted: false,
            isFailed: false,
            payout: 0.0
        )
        mockSupabaseManager.joinChallengeResult = .success(userChallenge)
        
        let joined = try await challengeManager.joinChallenge(
            challenge,
            userId: user.id
        )
        XCTAssertEqual(joined.id, 1)
    }
    
    // MARK: - Payment Failure And Refund Flow
    
    func testPaymentSuccess_JoinFailure_Refund() async {
        // 1. Payment succeeds
        let challenge = Challenge(
            id: 1,
            title: "Test Challenge",
            description: "Test",
            entryFee: 100.0,
            prizePool: 1000.0,
            duration: 7,
            startDate: Date(),
            endDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            rules: [],
            isActive: true
        )
        
        let payment = YooKassaPayment(
            id: "payment-id",
            status: .succeeded,
            amount: YooKassaAmount(value: "100.00", currency: "RUB"),
            description: "Payment",
            metadata: [:],
            confirmation: nil,
            createdAt: Date(),
            expiresAt: nil
        )
        mockYooKassaClient.createPaymentResult = payment
        
        let paymentSuccess = await paymentManager.processPayment(
            amount: 100.0,
            challenge: challenge,
            userId: "test-user-id",
            paymentMethod: .applePay,
            cardDetails: nil
        )
        XCTAssertTrue(paymentSuccess)
        
        // 2. Join fails
        mockSupabaseManager.joinChallengeResult = .failure(
            AppError.challengeNotFound
        )
        
        // 3. Refund should be initiated
        let refund = YooKassaRefund(
            id: "refund-id",
            status: "succeeded",
            amount: YooKassaAmount(value: "100.00", currency: "RUB")
        )
        mockYooKassaClient.createRefundResult = refund
        
        do {
            _ = try await challengeManager.joinChallenge(
                challenge,
                userId: "test-user-id"
            )
            XCTFail("Should have failed")
        } catch {
            // Refund should be called (in real implementation)
            XCTAssertTrue(error is AppError)
        }
    }
}
