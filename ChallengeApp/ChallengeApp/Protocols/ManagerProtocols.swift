//
//  ManagerProtocols.swift
//  ChallengeApp
//
//  Протоколы для менеджеров (для Dependency Injection)
//

import Foundation
import Supabase

// MARK: - Supabase Manager Protocol

@preconcurrency
protocol SupabaseManagerProtocol: Sendable {
    var supabase: SupabaseClient { get }
    
    // Auth
    func signUp(email: String, password: String, name: String) async throws -> User
    func signIn(email: String, password: String) async throws -> User
    func signInWithApple(token: String) async throws -> User
    func signInAnonymously() async throws -> User
    func signOut() async throws
    func getCurrentUser() async throws -> User?
    
    // Challenges
    func getChallenges() async throws -> [Challenge]
    func getChallenge(id: Int64) async throws -> Challenge?
    func getUserChallenges() async throws -> [UserChallenge]
    func joinChallenge(challengeId: Int64, userId: String) async throws -> UserChallenge
    func completeDay(challengeId: Int64) async throws
    func failChallenge(challengeId: Int64) async throws
    
    // Balance
    func depositBalance(amount: Double) async throws
    func withdrawBalance(amount: Double, accountDetails: String, method: WithdrawMethodType, challengeId: Int64?) async throws
    func getBalanceStatus() async throws -> BalanceStatus
    func getPendingDepositCreatedAt() async throws -> Date?
    
    // Honest Streak
    func incrementHonestStreak(userId: String) async throws -> Int
    func resetHonestStreak(userId: String) async throws -> Int
}

// MARK: - Auth Manager Protocol

protocol AuthManagerProtocol: ObservableObject {
    var isAuthenticating: Bool { get }
    var lastError: String? { get }
    
    func signUp(email: String, password: String, name: String) async throws -> User
    func signIn(email: String, password: String) async throws -> User
    func signInWithApple() async -> User?
    func signOut() async throws
}

// MARK: - Challenge Manager Protocol

@MainActor
protocol ChallengeManagerProtocol: ObservableObject {
    var availableChallenges: [Challenge] { get }
    var userChallenges: [UserChallenge] { get }
    var activeChallenge: UserChallenge? { get }
    var isLoading: Bool { get }
    var lastError: String? { get }
    
    func loadChallengesFromSupabase(forceRefresh: Bool) async
    func loadUserChallengesFromSupabase(forceRefresh: Bool) async
    func syncWithSupabase() async
    func joinChallenge(_ challenge: Challenge, userId: String) async throws -> UserChallenge
    func completeDay(challengeId: Int64) async throws
    func failChallenge(challengeId: Int64) async throws
    func getChallenge(id: Int64) -> Challenge?
}

// MARK: - Payment Manager Protocol

protocol PaymentManagerProtocol: ObservableObject {
    var isProcessing: Bool { get }
    var lastError: String? { get }
    var useRealPayments: Bool { get }
    
    func processPayment(
        amount: Double,
        challenge: Challenge,
        userId: String,
        paymentMethod: PaymentMethodType,
        cardDetails: CardDetails?,
        receiptEmail: String?
    ) async -> Bool
    
    func refundPayment(amount: Double) async throws
}

// MARK: - YooKassa Client Protocol

protocol YooKassaClientProtocol {
    func createPayment(
        amount: Double,
        description: String,
        returnUrl: String,
        metadata: [String: String]?,
        paymentMethod: String?,
        receiptEmail: String?
    ) async throws -> YooKassaPayment
    
    func createToken(
        cardNumber: String,
        expiryMonth: String,
        expiryYear: String,
        cvc: String
    ) async throws -> YooKassaToken
    
    func getPayment(paymentId: String) async throws -> YooKassaPayment
    
    func createRefund(paymentId: String, amount: Double) async throws -> YooKassaRefund
}
