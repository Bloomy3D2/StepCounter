//
//  MockManagers.swift
//  ChallengeAppTests
//
//  Моки для тестирования
//

import Foundation
@testable import ChallengeApp

// MARK: - Mock Supabase Manager

class MockSupabaseManager: SupabaseManagerProtocol {
    var supabase: SupabaseClient {
        fatalError("MockSupabaseManager.supabase should not be accessed directly")
    }
    
    // Auth
    var signUpResult: Result<User, Error>?
    var signInResult: Result<User, Error>?
    var signInWithAppleResult: Result<User, Error>?
    var signInAnonymouslyResult: Result<User, Error>?
    var signOutError: Error?
    var getCurrentUserResult: User?
    
    // Challenges
    var getChallengesResult: [Challenge] = []
    var getChallengeResult: Challenge?
    var getUserChallengesResult: [UserChallenge] = []
    var joinChallengeResult: Result<UserChallenge, Error>?
    var completeDayError: Error?
    var failChallengeError: Error?
    
    // Balance
    var depositBalanceError: Error?
    var withdrawBalanceError: Error?
    
    func signUp(email: String, password: String, name: String) async throws -> User {
        if let result = signUpResult {
            return try result.get()
        }
        throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "signUp not mocked"])
    }
    
    func signIn(email: String, password: String) async throws -> User {
        if let result = signInResult {
            return try result.get()
        }
        throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "signIn not mocked"])
    }
    
    func signInWithApple(token: String) async throws -> User {
        if let result = signInWithAppleResult {
            return try result.get()
        }
        throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "signInWithApple not mocked"])
    }
    
    func signInAnonymously() async throws -> User {
        if let result = signInAnonymouslyResult {
            return try result.get()
        }
        throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "signInAnonymously not mocked"])
    }
    
    func signOut() async throws {
        if let error = signOutError {
            throw error
        }
    }
    
    func getCurrentUser() async throws -> User? {
        return getCurrentUserResult
    }
    
    func getChallenges() async throws -> [Challenge] {
        return getChallengesResult
    }
    
    func getChallenge(id: Int64) async throws -> Challenge? {
        return getChallengeResult
    }
    
    func getUserChallenges() async throws -> [UserChallenge] {
        return getUserChallengesResult
    }
    
    func joinChallenge(challengeId: Int64, userId: String) async throws -> UserChallenge {
        if let result = joinChallengeResult {
            return try result.get()
        }
        throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "joinChallenge not mocked"])
    }
    
    func completeDay(challengeId: Int64) async throws {
        if let error = completeDayError {
            throw error
        }
    }
    
    func failChallenge(challengeId: Int64) async throws {
        if let error = failChallengeError {
            throw error
        }
    }
    
    func depositBalance(amount: Double) async throws {
        if let error = depositBalanceError {
            throw error
        }
    }
    
    func withdrawBalance(amount: Double, accountDetails: String, method: WithdrawMethodType) async throws {
        if let error = withdrawBalanceError {
            throw error
        }
    }
}

// MARK: - Mock Cache Manager

class MockCacheManager: CacheManagerProtocol {
    var cache: [String: Any] = [:]
    var shouldReturnNil = false
    
    func get<T: Codable>(_ key: String, as type: T.Type) -> T? {
        if shouldReturnNil {
            return nil
        }
        return cache[key] as? T
    }
    
    func set<T: Codable>(_ value: T, forKey key: String, ttl: TimeInterval?) {
        cache[key] = value
    }
    
    func remove(_ key: String) {
        cache.removeValue(forKey: key)
    }
    
    func clear() {
        cache.removeAll()
    }
    
    func has(_ key: String) -> Bool {
        return cache[key] != nil
    }
    
    // MARK: - Convenience Methods (like CacheManager)
    
    func cacheChallenges(_ challenges: [Challenge]) {
        cache["challenges"] = challenges
    }
    
    func getCachedChallenges() -> [Challenge]? {
        return cache["challenges"] as? [Challenge]
    }
    
    func cacheUserChallenges(_ challenges: [UserChallenge]) {
        cache["userChallenges"] = challenges
    }
    
    func getCachedUserChallenges() -> [UserChallenge]? {
        return cache["userChallenges"] as? [UserChallenge]
    }
    
    func cacheUser(_ user: User) {
        cache["currentUser"] = user
    }
    
    func getCachedUser() -> User? {
        return cache["currentUser"] as? User
    }
}

// MARK: - Mock Network Retry

class MockNetworkRetry: NetworkRetryProtocol {
    var shouldFail = false
    var failError: Error?
    var attemptCount = 0
    
    func execute<T>(
        maxAttempts: Int,
        delay: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        attemptCount += 1
        
        if shouldFail {
            throw failError ?? NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock network error"])
        }
        
        return try await operation()
    }
}

// MARK: - Mock Payment Manager

class MockPaymentManager: PaymentManagerProtocol {
    @Published var isProcessing = false
    @Published var lastError: String?
    var useRealPayments = false
    
    var processPaymentResult: Bool = true
    var refundPaymentError: Error?
    
    func processPayment(
        amount: Double,
        challenge: Challenge,
        userId: String,
        paymentMethod: PaymentMethodType,
        cardDetails: CardDetails?
    ) async -> Bool {
        isProcessing = true
        defer { isProcessing = false }
        
        return processPaymentResult
    }
    
    func refundPayment(amount: Double) async throws {
        if let error = refundPaymentError {
            throw error
        }
    }
}

// MARK: - Mock YooKassa Client

class MockYooKassaClient: YooKassaClientProtocol {
    var createPaymentResult: YooKassaPayment?
    var createPaymentError: Error?
    
    var createTokenResult: YooKassaToken?
    var createTokenError: Error?
    
    var getPaymentResult: YooKassaPayment?
    var getPaymentError: Error?
    
    var createRefundResult: YooKassaRefund?
    var createRefundError: Error?
    
    func createPayment(
        amount: Double,
        description: String,
        returnUrl: String,
        metadata: [String: String],
        paymentMethod: String
    ) async throws -> YooKassaPayment {
        if let error = createPaymentError {
            throw error
        }
        if let result = createPaymentResult {
            return result
        }
        throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "createPayment not mocked"])
    }
    
    func createToken(
        cardNumber: String,
        expiryMonth: String,
        expiryYear: String,
        cvc: String
    ) async throws -> YooKassaToken {
        if let error = createTokenError {
            throw error
        }
        if let result = createTokenResult {
            return result
        }
        throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "createToken not mocked"])
    }
    
    func getPayment(paymentId: String) async throws -> YooKassaPayment {
        if let error = getPaymentError {
            throw error
        }
        if let result = getPaymentResult {
            return result
        }
        throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "getPayment not mocked"])
    }
    
    func createRefund(paymentId: String, amount: Double) async throws -> YooKassaRefund {
        if let error = createRefundError {
            throw error
        }
        if let result = createRefundResult {
            return result
        }
        throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "createRefund not mocked"])
    }
}
