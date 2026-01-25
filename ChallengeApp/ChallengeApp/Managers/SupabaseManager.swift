//
//  SupabaseManager.swift
//  ChallengeApp
//
//  Менеджер для работы с Supabase
//

import Foundation
import Supabase

final class SupabaseManager: SupabaseManagerProtocol, @unchecked Sendable {
    static let shared = SupabaseManager()
    
    private let client: SupabaseClient?
    private let cacheManager: any CacheManagerProtocol
    private let networkRetry: any NetworkRetryProtocol
    
    private init(cacheManager: any CacheManagerProtocol = DIContainer.shared.cacheManager,
                 networkRetry: any NetworkRetryProtocol = DIContainer.shared.networkRetry) {
        self.cacheManager = cacheManager
        self.networkRetry = networkRetry
        
        // Инициализируем client напрямую в init для Sendable conformance
        if let url = URL(string: AppConfig.supabaseURL),
           (url.scheme == "https" || url.scheme == "http"),
           url.host != nil {
            self.client = SupabaseClient(
                supabaseURL: url,
                supabaseKey: AppConfig.supabaseKey
            )
            Logger.shared.info("Supabase client initialized successfully")
        } else {
            Logger.shared.error("Supabase URL not configured or invalid")
            self.client = nil
        }
    }
    
    var supabase: SupabaseClient {
        guard let client = client else {
            fatalError("Supabase client not initialized. Check your credentials.")
        }
        return client
    }
}

// MARK: - Auth Extensions
extension SupabaseManager {
    
    func signUp(email: String, password: String, name: String) async throws -> User {
        // Создаем пользователя без дополнительных данных (создадим профиль отдельно)
        let response = try await supabase.auth.signUp(
            email: email,
            password: password
        )
        
        // Проверяем, что пользователь создан
        guard response.user != nil else {
            throw AppError.invalidData("Не удалось создать пользователя. Проверьте правильность данных.")
        }
        
        // Если требуется подтверждение email, создаем профиль, но пользователь не будет авторизован
        // В этом случае session будет nil
        do {
            _ = try await supabase.auth.session
            // Если есть сессия, создаем профиль и возвращаем пользователя
            return try await createUserProfile(userId: response.user.id, email: email, name: name, authProvider: "EMAIL")
        } catch {
            // Если сессии нет (требуется подтверждение email), все равно создаем профиль
            // Пользователю нужно будет подтвердить email перед входом
            do {
                _ = try await createUserProfile(userId: response.user.id, email: email, name: name, authProvider: "EMAIL")
            } catch {
                // Игнорируем ошибку создания профиля, если нет сессии
                Logger.shared.warning("Could not create profile without session", error: error)
            }
            
            throw AppError.emailNotConfirmed
        }
    }
    
    func signIn(email: String, password: String) async throws -> User {
        do {
            let response = try await supabase.auth.signIn(email: email, password: password)
            
            // Get user profile, create if doesn't exist
            do {
                let user = try await getUserProfile(userId: response.user.id)
                // Кэшируем пользователя
                cacheManager.cacheUser(user)
                return user
            } catch {
                // Если профиля нет, создаем его
                let user = try await createUserProfile(
                    userId: response.user.id,
                    email: response.user.email ?? email,
                    name: response.user.email?.components(separatedBy: "@").first ?? "User",
                    authProvider: "EMAIL"
                )
                // Кэшируем пользователя
                cacheManager.cacheUser(user)
                return user
            }
        } catch {
            Logger.shared.error("Failed to sign in", error: error)
            
            // Преобразуем в AppError
            let errorMessage = error.localizedDescription.lowercased()
            if errorMessage.contains("invalid login credentials") || errorMessage.contains("неверный") {
                throw AppError.invalidCredentials
            } else if errorMessage.contains("email not confirmed") || errorMessage.contains("не подтвержден") {
                throw AppError.emailNotConfirmed
            } else {
                throw ErrorHandler.handle(error)
            }
        }
    }
    
    func signInWithApple(token: String) async throws -> User {
        // Sign in with Apple через Supabase
        let response = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: token
            )
        )
        
        let user = response.user
        
        // Get or create user profile
        do {
            let userProfile = try await getUserProfile(userId: user.id)
            // Кэшируем пользователя
            cacheManager.cacheUser(userProfile)
            return userProfile
        } catch {
            // Create if doesn't exist
            let userName: String
            // Извлекаем имя из userMetadata (AnyJSON)
            if let fullNameValue = user.userMetadata["full_name"] {
                switch fullNameValue {
                case .string(let name):
                    userName = name
                default:
                    userName = "User"
                }
            } else {
                userName = "User"
            }
            
            let userProfile = try await createUserProfile(
                userId: user.id,
                email: user.email ?? "",
                name: userName,
                authProvider: "APPLE"
            )
            // Кэшируем пользователя
            cacheManager.cacheUser(userProfile)
            return userProfile
        }
    }
    
    func signInAnonymously() async throws -> User {
        // Анонимный вход через Supabase
        let response = try await supabase.auth.signInAnonymously()
        let user = response.user
        
        // Get or create user profile
        do {
            return try await getUserProfile(userId: user.id)
        } catch {
            // Create if doesn't exist
            return try await createUserProfile(
                userId: user.id,
                email: "",
                name: "Гость",
                authProvider: "ANONYMOUS"
            )
        }
    }
    
    func signOut() async throws {
        try await networkRetry.execute { [self] in
            try await self.supabase.auth.signOut()
        }
        
        // Очищаем кэш пользователя
        cacheManager.remove("currentUser")
    }
    
    func getCurrentUser() async throws -> User? {
        do {
            let session = try await supabase.auth.session
            
            // Проверяем, не истекла ли сессия (важно при emitLocalSessionAsInitialSession: true)
            if session.isExpired {
                Logger.shared.warning("Session is expired, attempting refresh...")
                // Пытаемся обновить сессию
                do {
                    _ = try await supabase.auth.refreshSession()
                    Logger.shared.info("Session refreshed successfully")
                } catch {
                    Logger.shared.warning("Failed to refresh expired session", error: error)
                    // Если не удалось обновить, используем кэш или возвращаем nil
                    if let cachedUser = cacheManager.getCachedUser() {
                        Logger.shared.info("Using cached user after failed refresh")
                        return cachedUser
                    }
                    return nil
                }
            }
            
            // Проверяем кэш
            if let cachedUser = cacheManager.getCachedUser() {
                Logger.shared.debug("Loading user from cache")
                return cachedUser
            }
            
            // Загружаем из сети с retry
            let user = try await networkRetry.execute { [self] in
                try await self.getUserProfile(userId: session.user.id)
            }
            
            // Кэшируем результат
            cacheManager.cacheUser(user)
            
            return user
        } catch {
            // Нет активной сессии - проверяем кэш
            if let cachedUser = cacheManager.getCachedUser() {
                Logger.shared.info("No session, using cached user")
                return cachedUser
            }
            return nil
        }
    }
    
    func depositBalance(amount: Double) async throws {
        guard let session = try? await supabase.auth.session else {
            throw AppError.authenticationRequired
        }
        
        let userId = session.user.id
        
        // Предпочтительный путь: SECURITY DEFINER функция на стороне БД.
        // Она атомарно:
        // - увеличивает баланс
        // - создаёт запись в payments (обходит RLS)
        struct DepositResponse: Decodable {
            let success: Bool
            let newBalance: Double
            
            enum CodingKeys: String, CodingKey {
                case success
                case newBalance = "new_balance"
            }
        }
        
        do {
            struct UpdateUserBalanceParams: Encodable, Sendable {
                let p_user_id: String
                let p_amount: Double
            }
            
            let response: DepositResponse = try await supabase
                .rpc(
                    "update_user_balance",
                    params: UpdateUserBalanceParams(
                        p_user_id: userId.uuidString,
                        p_amount: amount
                    )
                )
                .execute()
                .value
            
            if response.success {
                Logger.shared.info("Balance updated via RPC: newBalance=\(response.newBalance)")
            } else {
                Logger.shared.warning("update_user_balance returned success=false")
            }
            
            cacheManager.remove("currentUser")
            return
        } catch {
            // Fallback: старый путь (может не создать payments запись из-за RLS, но баланс обновит).
            Logger.shared.warning("depositBalance: RPC update_user_balance failed, falling back to direct update", error: error)
        }
        
        // ---- Fallback (legacy) ----
        
        // Получаем текущий баланс
        let currentUser: User
        do {
            currentUser = try await getUserProfile(userId: userId)
        } catch {
            Logger.shared.error("Failed to get user profile before deposit", error: error)
            // Если не удалось получить профиль, пробуем использовать кэш
            if let cachedUser = cacheManager.getCachedUser() {
                Logger.shared.info("Using cached user for deposit calculation")
                currentUser = cachedUser
            } else {
                throw AppError.authenticationRequired
            }
        }
        
        let newBalance = currentUser.balance + amount
        
        // Обновляем баланс в базе данных (увеличиваем на amount)
        struct BalanceUpdate: Codable { let balance: Double }
        let update = BalanceUpdate(balance: newBalance)
        
        do {
            _ = try await networkRetry.execute { [self] in
                try await self.supabase
                    .from("users")
                    .update(update)
                    .eq("id", value: userId.uuidString)
                    .execute()
            }
            Logger.shared.info("Balance updated successfully (fallback): \(currentUser.balance) -> \(newBalance)")
        } catch {
            Logger.shared.error("Failed to update balance in database", error: error)
            throw AppError.serverError("Не удалось обновить баланс. Попробуйте ещё раз.")
        }
        
        // Инвалидируем кэш пользователя
        cacheManager.remove("currentUser")
        
        // Создаем запись о пополнении в таблице payments (может быть заблокировано RLS — игнорируем)
        struct PaymentInsert: Codable {
            let user_id: String
            let type: String
            let status: String
            let amount: Double
            let description: String
        }
        
        let payment = PaymentInsert(
            user_id: userId.uuidString,
            type: "DEPOSIT",
            status: "COMPLETED",
            amount: amount,
            description: "Пополнение баланса"
        )
        
        do {
            _ = try await supabase
                .from("payments")
                .insert(payment)
                .execute()
            Logger.shared.info("Payment record created successfully for deposit (fallback): \(amount)")
        } catch {
            Logger.shared.warning("Failed to create payment record (fallback; balance already updated)", error: error)
        }
    }
    
    func withdrawBalance(amount: Double, accountDetails: String, method: WithdrawMethodType, challengeId: Int64? = nil) async throws {
        // Для обратной совместимости: если challengeId указан, используем старый метод
        // (для внутренних операций, не связанных с YooKassa)
        if challengeId != nil {
            return try await withdrawBalanceLegacy(amount: amount, accountDetails: accountDetails, method: method, challengeId: challengeId)
        }
        
        // Для реальных выплат используем Edge Function с YooKassa
        Logger.shared.info("💰 SupabaseManager.withdrawBalance: Creating payout via YooKassa - amount=\(amount), method=\(method.rawValue)")
        
        // Извлекаем данные из accountDetails (для обратной совместимости)
        // В будущем лучше передавать cardNumber, phoneNumber, bankAccount отдельно
        let cardNumber = extractCardNumber(from: accountDetails)
        let phoneNumber = extractPhoneNumber(from: accountDetails)
        let bankAccount = extractBankAccount(from: accountDetails)
        
        // Вызываем Edge Function для создания выплаты через YooKassa
        struct CreatePayoutBody: Codable {
            let amount: Double
            let method: String // "card", "sbp", "bank_account"
            let cardNumber: String?
            let phoneNumber: String?
            let bankAccount: String?
            let description: String?
        }
        
        struct CreatePayoutResponse: Codable {
            let success: Bool?
            let payout: PayoutInfo?
            let newBalance: Double?
            let error: String?
        }
        
        struct PayoutInfo: Codable {
            let id: String
            let status: String
            let amount: PayoutAmount?
            let createdAt: String?
        }
        
        struct PayoutAmount: Codable {
            let value: String
            let currency: String
        }
        
        let payoutMethod: String
        switch method {
        case .card:
            payoutMethod = "card"
        case .sbp:
            payoutMethod = "sbp"
        case .bankAccount:
            payoutMethod = "bank_account"
        case .`internal`:
            // Для внутренних операций используем старый метод
            return try await withdrawBalanceLegacy(amount: amount, accountDetails: accountDetails, method: method, challengeId: nil)
        }
        
        let body = CreatePayoutBody(
            amount: amount,
            method: payoutMethod,
            cardNumber: cardNumber,
            phoneNumber: phoneNumber,
            bankAccount: bankAccount,
            description: accountDetails
        )
        
        Logger.shared.info("📤 Calling create-payout Edge Function...")
        
        do {
            let result: CreatePayoutResponse = try await callEdgeFunctionDirectly(
                functionName: "create-payout",
                body: body
            )
            
            if let error = result.error {
                Logger.shared.error("❌ create-payout Edge Function returned error: \(error)")
                throw AppError.serverError(error)
            }
            
            guard let success = result.success, success == true else {
                let errorMsg = result.error ?? "Неизвестная ошибка при создании выплаты"
                Logger.shared.error("❌ create-payout Edge Function returned invalid response")
                throw AppError.serverError(errorMsg)
            }
            
            Logger.shared.info("✅ Payout created successfully: payoutId=\(result.payout?.id ?? "unknown"), newBalance=\(result.newBalance ?? 0)")
            
            // Инвалидируем кэш пользователя
            cacheManager.remove("currentUser")
            
        } catch {
            Logger.shared.error("❌ Error creating payout via Edge Function:", error: error)
            throw error
        }
    }
    
    // Старый метод для обратной совместимости (внутренние операции)
    private func withdrawBalanceLegacy(amount: Double, accountDetails: String, method: WithdrawMethodType, challengeId: Int64?) async throws {
        guard let session = try? await supabase.auth.session else {
            throw AppError.authenticationRequired
        }
        
        let userId = session.user.id
        
        // Идемпотентность для списания входа в челлендж:
        // если уже есть COMPLETED ENTRY_FEE для этого user+challenge — повторно НЕ списываем.
        if let challengeId {
            struct ExistingPaymentRow: Decodable {
                let id: Int64
            }
            
            do {
                let existing: [ExistingPaymentRow] = try await supabase
                    .from("payments")
                    .select("id")
                    .eq("user_id", value: userId.uuidString)
                    .eq("challenge_id", value: String(challengeId))
                    .eq("type", value: "ENTRY_FEE")
                    .eq("status", value: "COMPLETED")
                    .limit(1)
                    .execute()
                    .value
                
                if !existing.isEmpty {
                    Logger.shared.warning("withdrawBalanceLegacy: ENTRY_FEE already exists for user+challenge, skipping duplicate withdrawal. userId=\(userId.uuidString), challengeId=\(challengeId)")
                    return
                }
            } catch {
                // Если по какой-то причине не удалось проверить историю платежей — продолжаем обычный поток.
                Logger.shared.warning("withdrawBalanceLegacy: Failed to check existing ENTRY_FEE, continuing", error: error)
            }
        }
        
        // Получаем текущий баланс
        let currentUser = try await getUserProfile(userId: userId)
        
        // Проверяем достаточность средств
        guard currentUser.balance >= amount else {
            throw AppError.insufficientFunds
        }
        
        let newBalance = currentUser.balance - amount
        
        // Обновляем баланс в базе данных (уменьшаем на amount)
        struct BalanceUpdate: Codable {
            let balance: Double
        }
        
        let update = BalanceUpdate(balance: newBalance)
        
        _ = try await networkRetry.execute { [self] in
            try await self.supabase
                .from("users")
                .update(update)
                .eq("id", value: userId.uuidString)
                .execute()
        }
        
        // Инвалидируем кэш пользователя
        cacheManager.remove("currentUser")
        
        // Создаем запись о платеже в таблице payments
        struct PaymentInsert: Codable {
            let user_id: String
            let challenge_id: Int64?
            let type: String
            let status: String
            let amount: Double
            let description: String
            
            enum CodingKeys: String, CodingKey {
                case user_id
                case challenge_id
                case type
                case status
                case amount
                case description
            }
        }
        
        // Определяем тип платежа: если указан challengeId, это ENTRY_FEE, иначе WITHDRAWAL
        let paymentType = challengeId != nil ? "ENTRY_FEE" : "WITHDRAWAL"
        let paymentStatus = challengeId != nil ? "COMPLETED" : "PENDING"
        
        let payment = PaymentInsert(
            user_id: userId.uuidString,
            challenge_id: challengeId,
            type: paymentType,
            status: paymentStatus,
            amount: amount,
            description: accountDetails
        )
        
        _ = try await supabase
            .from("payments")
            .insert(payment)
            .execute()
    }
    
    // Helper функции для извлечения данных из accountDetails (для обратной совместимости)
    private func extractCardNumber(from accountDetails: String) -> String? {
        if accountDetails.contains("Карта:") {
            let parts = accountDetails.components(separatedBy: "Карта:")
            if parts.count > 1 {
                return parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
    
    private func extractPhoneNumber(from accountDetails: String) -> String? {
        if accountDetails.contains("СБП:") {
            let parts = accountDetails.components(separatedBy: "СБП:")
            if parts.count > 1 {
                return parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
    
    private func extractBankAccount(from accountDetails: String) -> String? {
        if accountDetails.contains("Счет:") {
            let parts = accountDetails.components(separatedBy: "Счет:")
            if parts.count > 1 {
                return parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
    
    // MARK: - Private Helpers
    
    private func createUserProfile(userId: UUID, email: String, name: String, authProvider: String) async throws -> User {
        // Используем Codable структуру для вставки
        struct UserProfileInsert: Codable {
            let id: String
            let email: String
            let name: String
            let balance: Double
            let auth_provider: String
        }
        
        let profile = UserProfileInsert(
            id: userId.uuidString,
            email: email,
            name: name,
            balance: 0.0,
            auth_provider: authProvider
        )
        
        _ = try await supabase
            .from("users")
            .insert(profile)
            .execute()
        
        return User(
            id: userId.uuidString,
            name: name,
            email: email,
            balance: 0.0,
            authProvider: User.AuthProvider(rawValue: authProvider.lowercased()) ?? .anonymous,
            createdAt: Date()
        )
    }
    
    func updateUserAvatar(avatarUrl: String) async throws {
        guard let session = try? await supabase.auth.session else {
            throw AppError.authenticationRequired
        }
        
        let userId = session.user.id
        
        struct AvatarUpdate: Codable {
            let avatar_url: String
        }
        
        let update = AvatarUpdate(avatar_url: avatarUrl)
        
        _ = try await networkRetry.execute { [self] in
            try await self.supabase
                .from("users")
                .update(update)
                .eq("id", value: userId.uuidString)
                .execute()
        }
        
        // Инвалидируем кэш пользователя
        cacheManager.remove("currentUser")
        
        Logger.shared.info("✅ Avatar URL updated successfully: \(avatarUrl)")
    }
    
    // MARK: - Challenge Statistics Helpers
    
    private struct UserChallengeIdRow: Codable {
        let id: Int64
    }
    
    /// Получить количество участников, выполнивших день сегодня
    private func getCompletedTodayCount(challengeId: Int64) async throws -> Int {
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10) // YYYY-MM-DD
        
        // Прямой запрос: получаем user_challenge_ids для этого челленджа
        let userChallenges: [UserChallengeIdRow] = try await supabase
            .from("user_challenges")
            .select("id")
            .eq("challenge_id", value: String(challengeId))
            .execute()
            .value
        
        let userChallengeIds = Set(userChallenges.map { $0.id })
        
        // Получаем completed_days за сегодня
        struct CompletedDayResponse: Codable {
            let userChallengeId: Int64
            
            enum CodingKeys: String, CodingKey {
                case userChallengeId = "user_challenge_id"
            }
        }
        
        let completedDays: [CompletedDayResponse] = try await supabase
            .from("completed_days")
            .select("user_challenge_id")
            .eq("completed_date", value: String(today))
            .execute()
            .value
        
        // Фильтруем только те, которые относятся к этому челленджу
        let count = completedDays.filter { userChallengeIds.contains($0.userChallengeId) }.count
        
        return count
    }
    
    /// Получить количество участников, выбывших сегодня
    private func getFailedTodayCount(challengeId: Int64) async throws -> Int {
        let today = ISO8601DateFormatter().string(from: Date())
        let todayStart = String(today.prefix(10)) + "T00:00:00"
        let todayEnd = String(today.prefix(10)) + "T23:59:59"
        
        // Получаем всех, кто провалился сегодня
        let failed: [UserChallengeIdRow] = try await supabase
            .from("user_challenges")
            .select("id")
            .eq("challenge_id", value: String(challengeId))
            .eq("is_failed", value: true)
            .gte("failed_at", value: todayStart)
            .lte("failed_at", value: todayEnd)
            .execute()
            .value
        
        return failed.count
    }
    
    private func getUserProfile(userId: UUID) async throws -> User {
        do {
            let response: [UserProfileResponse] = try await supabase
                .from("users")
                .select()
                .eq("id", value: userId.uuidString)
                .execute()
                .value
            
            guard let profile = response.first else {
                Logger.shared.warning("User profile not found for userId: \(userId.uuidString)")
                throw AppError.dataNotFound
            }
            
            return User(
                id: profile.id,
                name: profile.name,
                email: profile.email,
                balance: profile.balance,
                authProvider: User.AuthProvider(rawValue: profile.authProvider.lowercased()) ?? .anonymous,
                createdAt: profile.toCreatedDate(),
                honestStreak: profile.honestStreak,
                avatarUrl: profile.avatarUrl
            )
        } catch let decodingError as DecodingError {
            Logger.shared.error("Decoding error in getUserProfile for userId: \(userId.uuidString)", error: decodingError)
            throw AppError.dataCorrupted
        } catch {
            Logger.shared.error("Error getting user profile for userId: \(userId.uuidString)", error: error)
            throw error
        }
    }
    
    // MARK: - Balance Status
    
    /// Получить статусы баланса пользователя
    func getBalanceStatus() async throws -> BalanceStatus {
        guard let user = try await getCurrentUser(),
              let uuid = UUID(uuidString: user.id) else {
            return BalanceStatus(available: 0, onVerification: 0, pendingWithdrawal: 0, verificationTimeRemaining: nil)
        }
        
        struct PaymentResponse: Codable {
            let type: String
            let status: String
            let amount: Double
            let created_at: String
            let processed_at: String?
        }
        
        let payments: [PaymentResponse] = try await networkRetry.execute { [self] in
            try await self.supabase
                .from("payments")
                .select("type, status, amount, created_at, processed_at")
                .eq("user_id", value: uuid.uuidString)
                .execute()
                .value
        }
        
        // Средства на проверке (депозиты со статусом PENDING)
        let onVerification = payments
            .filter { $0.type == "DEPOSIT" && $0.status == "PENDING" }
            .reduce(0.0) { $0 + $1.amount }
        
        // Средства ожидающие вывода (выводы со статусом PENDING)
        let pendingWithdrawal = payments
            .filter { $0.type == "WITHDRAWAL" && $0.status == "PENDING" }
            .reduce(0.0) { $0 + $1.amount }
        
        // Доступные средства = баланс - на проверке - ожидающие вывода
        let available = max(0, user.balance - onVerification - pendingWithdrawal)
        
        // Время проверки (24 часа с момента создания депозита)
        let verificationTimeRemaining: TimeInterval? = {
            guard let pendingDeposit = payments
                .filter({ $0.type == "DEPOSIT" && $0.status == "PENDING" })
                .sorted(by: { $0.created_at < $1.created_at })
                .first else {
                return nil
            }
            
            // Парсим дату с поддержкой разных форматов
            guard let createdAt = ISO8601DateFormatter.parse(pendingDeposit.created_at) else {
                return nil
            }
            
            let verificationDuration: TimeInterval = 24 * 60 * 60 // 24 часа
            let elapsed = Date().timeIntervalSince(createdAt)
            let remaining = verificationDuration - elapsed
            return max(0, remaining)
        }()
        
        return BalanceStatus(
            available: available,
            onVerification: onVerification,
            pendingWithdrawal: pendingWithdrawal,
            verificationTimeRemaining: verificationTimeRemaining
        )
    }
    
    /// Получить дату создания последнего депозита на проверке
    func getPendingDepositCreatedAt() async throws -> Date? {
        guard let user = try await getCurrentUser(),
              let uuid = UUID(uuidString: user.id) else {
            return nil
        }
        
        struct PaymentResponse: Codable {
            let created_at: String
        }
        
        let payments: [PaymentResponse] = try await networkRetry.execute { [self] in
            try await self.supabase
                .from("payments")
                .select("created_at")
                .eq("user_id", value: uuid.uuidString)
                .eq("type", value: "DEPOSIT")
                .eq("status", value: "PENDING")
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value
        }
        
        guard let payment = payments.first else {
            return nil
        }
        
        // Парсим дату с поддержкой разных форматов
        return ISO8601DateFormatter.parse(payment.created_at)
    }
    
    /// Получить историю транзакций пользователя (пополнения, вход в челлендж, вывод, выплаты)
    func getUserPayments(limit: Int = 50) async throws -> [PaymentTransaction] {
        guard let user = try await getCurrentUser(),
              let uuid = UUID(uuidString: user.id) else {
            return []
        }
        
        struct PaymentRow: Codable {
            let id: Int64
            let type: String
            let status: String
            let amount: Double
            let created_at: String
            let description: String?
            let challenge_id: Int64?
            
            enum CodingKeys: String, CodingKey {
                case id, type, status, amount, description
                case created_at
                case challenge_id
            }
        }
        
        let rows: [PaymentRow] = try await networkRetry.execute { [self] in
            try await self.supabase
                .from("payments")
                .select("id, type, status, amount, created_at, description, challenge_id")
                .eq("user_id", value: uuid.uuidString)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
        }
        
        func parseCreatedAt(_ s: String) -> Date {
            return ISO8601DateFormatter.parseOrNow(s)
        }
        
        return rows.map { row in
            PaymentTransaction(
                id: row.id,
                type: row.type,
                status: row.status,
                amount: row.amount,
                createdAt: parseCreatedAt(row.created_at),
                description: row.description,
                challengeId: row.challenge_id
            )
        }
    }
}

// MARK: - Balance Status Model

struct BalanceStatus {
    let available: Double
    let onVerification: Double
    let pendingWithdrawal: Double
    let verificationTimeRemaining: TimeInterval? // в секундах
    
    var formattedVerificationTime: String? {
        guard let remaining = verificationTimeRemaining, remaining > 0 else {
            return nil
        }
        
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}

/// Элемент истории транзакций для отображения в профиле
struct PaymentTransaction: Identifiable {
    let id: Int64
    let type: String   // DEPOSIT, ENTRY_FEE, WITHDRAWAL, PAYOUT
    let status: String // PENDING, COMPLETED, FAILED, REFUNDED
    let amount: Double
    let createdAt: Date
    let description: String?
    let challengeId: Int64?
}

// MARK: - Challenge Extensions
extension SupabaseManager {
    
    func getChallenges() async throws -> [Challenge] {
        // Фильтруем только активные челленджи, которые еще не завершились
        let now = ISO8601DateFormatter().string(from: Date())
        let response: [ChallengeResponse] = try await supabase
            .from("challenges")
            .select()
            .eq("is_active", value: true)
            .gte("end_date", value: now) // end_date >= NOW() - завершённые (например, "вчерашний") не показываем
            .execute()
            .value
        
        // Загружаем правила и статистику для каждого челленджа
        var challenges: [Challenge] = []
        for challengeResponse in response {
            // Загружаем статистику: выполнило сегодня, выбыло сегодня
            let completedToday = (try? await getCompletedTodayCount(challengeId: challengeResponse.id)) ?? 0
            let failedToday = (try? await getFailedTodayCount(challengeId: challengeResponse.id)) ?? 0
            
            var challenge = challengeResponse.toChallenge(completedToday: completedToday, failedToday: failedToday)
            
            // Загружаем правила из таблицы challenge_rules
            struct ChallengeRuleResponse: Codable {
                let rule: String
                let orderIndex: Int
                
                enum CodingKeys: String, CodingKey {
                    case rule
                    case orderIndex = "order_index"
                }
            }
            
            do {
                let rulesResponse: [ChallengeRuleResponse] = try await supabase
                    .from("challenge_rules")
                    .select()
                    .eq("challenge_id", value: String(challengeResponse.id))
                    .order("order_index", ascending: true)
                    .execute()
                    .value
                
                challenge.rules = rulesResponse.map { $0.rule }
            } catch {
                // Некритично: показываем челленджи даже если правила недоступны (например, из-за RLS).
                Logger.shared.warning("Failed to load rules for challengeId=\(challengeResponse.id), using empty rules", error: error)
                challenge.rules = []
            }
            challenges.append(challenge)
        }
        
        // Сортируем челленджи по длительности (от меньшего к большему)
        challenges.sort { $0.duration < $1.duration }
        
        return challenges
    }
    
    func getChallenge(id: Int64) async throws -> Challenge? {
        let response: ChallengeResponse = try await supabase
            .from("challenges")
            .select()
            .eq("id", value: String(id))
            .single()
            .execute()
            .value
        
        // Загружаем статистику
        let completedToday = try await getCompletedTodayCount(challengeId: response.id)
        let failedToday = try await getFailedTodayCount(challengeId: response.id)
        
        var challenge = response.toChallenge(completedToday: completedToday, failedToday: failedToday)
        
        // Загружаем правила
        struct ChallengeRuleResponse: Codable {
            let rule: String
            let orderIndex: Int
            
            enum CodingKeys: String, CodingKey {
                case rule
                case orderIndex = "order_index"
            }
        }
        
        let rulesResponse: [ChallengeRuleResponse] = try await supabase
            .from("challenge_rules")
            .select()
            .eq("challenge_id", value: String(response.id))
            .order("order_index", ascending: true)
            .execute()
            .value
        
        challenge.rules = rulesResponse.map { $0.rule }
        return challenge
    }
    
    func joinChallenge(challengeId: Int64, userId: String) async throws -> UserChallenge {
        // Проверяем и восстанавливаем сессию, если нужно
        // userId передается для совместимости с протоколом, но не используется напрямую
        // (сессия определяет пользователя автоматически)
        do {
            _ = try await supabase.auth.session
        } catch {
            // Если сессии нет, пытаемся авторизовать анонимно
            Logger.shared.warning("No active session, attempting anonymous sign in...")
            do {
                _ = try await signInAnonymously()
            } catch {
                // Если анонимный вход отключен, пробрасываем ошибку
                // Пользователь должен войти через AuthView
                Logger.shared.error("Anonymous sign-in failed", error: error)
                throw AppError.authenticationRequired
            }
        }
        
        // Call Edge Function
        struct JoinChallengeBody: Codable {
            let challengeId: Int64
        }
        
        // Гибкая структура для парсинга ответа
        struct JoinChallengeResponse: Codable {
            let success: Bool?
            let data: UserChallengeResponse?
            let error: String?
            let userChallengeId: Int64?
            
            enum CodingKeys: String, CodingKey {
                case success, data, error
                case userChallengeId = "user_challenge_id"
            }
        }
        
        let body = JoinChallengeBody(challengeId: challengeId)
        
        Logger.shared.info("Calling join-challenge Edge Function with challengeId: \(challengeId)")
        
        do {
            // Используем прямой HTTP запрос для получения полного ответа, включая тело ошибки
            let result: JoinChallengeResponse = try await callEdgeFunctionDirectly(
                functionName: "join-challenge",
                body: body
            )
            
            Logger.shared.info("Edge Function response: success=\(result.success ?? false), error=\(result.error ?? "none")")
            if let errorMsg = result.error {
                Logger.shared.error("Edge Function error message: \(errorMsg)")
            }
            
            // Проверяем на ошибку
            if let errorMessage = result.error {
                Logger.shared.error("Edge Function returned error: \(errorMessage)")
                throw AppError.serverError(mapEdgeFunctionError(errorMessage))
            }
            
            // Проверяем успешный ответ
            guard let success = result.success, success == true else {
                let errorMsg = result.error ?? "Неизвестная ошибка при вступлении в челлендж"
                Logger.shared.error("Edge Function returned invalid response")
                throw AppError.serverError(mapEdgeFunctionError(errorMsg))
            }
            
            // Если есть data - используем её
            if let userChallengeResponse = result.data {
                Logger.shared.info("Successfully joined challenge \(challengeId)")
                return userChallengeResponse.toUserChallenge()
            }
            
            // Если нет data, но есть userChallengeId - загружаем данные
            if let ucId = result.userChallengeId {
                Logger.shared.info("Got user_challenge_id: \(ucId), fetching full data...")
                let userChallenge = try await fetchUserChallenge(id: ucId)
                return userChallenge
            }
            
            throw AppError.invalidData("Ответ сервера не содержит данные о челлендже")
            
        } catch let error as AppError {
            throw error
        } catch let decodingError as DecodingError {
            Logger.shared.error("Decoding error: \(decodingError)")
            Logger.shared.error("Decoding error details: \(String(describing: decodingError))")
            
            // Пытаемся извлечь контекст из decoding error
            switch decodingError {
            case .keyNotFound(let key, let context):
                Logger.shared.error("Key not found: \(key.stringValue), path: \(context.codingPath)")
            case .typeMismatch(let type, let context):
                Logger.shared.error("Type mismatch: \(type), path: \(context.codingPath)")
            case .valueNotFound(let type, let context):
                Logger.shared.error("Value not found: \(type), path: \(context.codingPath)")
            case .dataCorrupted(let context):
                Logger.shared.error("Data corrupted: \(context.debugDescription), path: \(context.codingPath)")
            @unknown default:
                Logger.shared.error("Unknown decoding error: \(decodingError)")
            }
            
            throw AppError.serverError("Ошибка обработки ответа сервера. Попробуйте ещё раз.")
        } catch {
            let errorDescription = error.localizedDescription
            Logger.shared.error("❌ Error calling join-challenge Edge Function: \(errorDescription)")
            
            // Пытаемся извлечь конкретное сообщение об ошибке из NSError
            let nsError = error as NSError
            let userInfo = nsError.userInfo
            
            Logger.shared.error("NSError domain: \(nsError.domain), code: \(nsError.code)")
            Logger.shared.error("NSError userInfo keys: \(userInfo.keys)")
            
            // Логируем все ключи userInfo для диагностики
            for (key, value) in userInfo {
                Logger.shared.error("  userInfo[\(key)] = \(value)")
            }
            
            // Пытаемся извлечь сообщение об ошибке из response body
            var extractedErrorMessage: String? = nil
            var extractedErrorCode: String? = nil
            var extractedErrorDetails: String? = nil
            
            if let underlyingError = userInfo[NSUnderlyingErrorKey] as? NSError {
                Logger.shared.error("Underlying error: \(underlyingError.localizedDescription)")
                Logger.shared.error("Underlying error domain: \(underlyingError.domain), code: \(underlyingError.code)")
                Logger.shared.error("Underlying error userInfo: \(underlyingError.userInfo)")
                
                // Пытаемся найти error message в userInfo
                if let errorMessage = underlyingError.userInfo["message"] as? String {
                    extractedErrorMessage = errorMessage
                    Logger.shared.error("Extracted error message from userInfo: \(errorMessage)")
                } else if let errorData = underlyingError.userInfo["data"] as? Data {
                    Logger.shared.error("Found error data, attempting to parse JSON...")
                    // Пытаемся распарсить JSON из data
                    if let json = try? JSONSerialization.jsonObject(with: errorData) as? [String: Any] {
                        Logger.shared.error("Parsed error JSON: \(json)")
                        if let errorMsg = json["error"] as? String {
                            extractedErrorMessage = errorMsg
                        }
                        if let code = json["code"] as? String {
                            extractedErrorCode = code
                        }
                        if let details = json["details"] as? String {
                            extractedErrorDetails = details
                        }
                    }
                }
            }
            
            // Также проверяем прямые ключи в userInfo
            if let errorMessage = userInfo["message"] as? String {
                extractedErrorMessage = errorMessage
                Logger.shared.error("Extracted error message from direct userInfo: \(errorMessage)")
            }
            if let errorMessage = userInfo["error"] as? String {
                extractedErrorMessage = errorMessage
                Logger.shared.error("Extracted error message from 'error' key: \(errorMessage)")
            }
            if let errorData = userInfo["data"] as? Data {
                Logger.shared.error("Found error data in direct userInfo, attempting to parse...")
                if let json = try? JSONSerialization.jsonObject(with: errorData) as? [String: Any] {
                    Logger.shared.error("Parsed error JSON from direct userInfo: \(json)")
                    if let errorMsg = json["error"] as? String {
                        extractedErrorMessage = errorMsg
                    }
                    if let code = json["code"] as? String {
                        extractedErrorCode = code
                    }
                    if let details = json["details"] as? String {
                        extractedErrorDetails = details
                    }
                } else if let errorString = String(data: errorData, encoding: .utf8) {
                    Logger.shared.error("Error data as string: \(errorString)")
                    // Пытаемся распарсить как JSON строку
                    if let jsonData = errorString.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                        if let errorMsg = json["error"] as? String {
                            extractedErrorMessage = errorMsg
                        }
                    }
                }
            }
            
            // Проверяем известные ошибки
            // Также проверяем domain для нашего нового формата ошибок
            let isHttpError = errorDescription.contains("400") || 
                             errorDescription.contains("non-2xx") ||
                             nsError.domain == "EdgeFunctionError" ||
                             (nsError.code >= 400 && nsError.code < 500)
            
            if isHttpError {
                Logger.shared.error("❌ Edge Function returned HTTP error (code: \(nsError.code))")
                Logger.shared.error("Extracted error message: \(extractedErrorMessage ?? "nil")")
                Logger.shared.error("Extracted error code: \(extractedErrorCode ?? "nil")")
                Logger.shared.error("Extracted error details: \(extractedErrorDetails ?? "nil")")
                
                // Используем извлеченное сообщение или описание ошибки
                let errorMessage = extractedErrorMessage ?? errorDescription
                
                // Проверяем, содержит ли ошибка информацию о том, что пользователь уже участвует
                let lowercasedMessage = errorMessage.lowercased()
                if lowercasedMessage.contains("already joined") || 
                   lowercasedMessage.contains("user already joined") ||
                   lowercasedMessage.contains("already joined this challenge") {
                    Logger.shared.warning("⚠️ User already joined this challenge - detected from error message")
                    throw AppError.alreadyJoined
                }
                
                // Проверяем другие известные ошибки
                if lowercasedMessage.contains("challenge not found") || 
                   lowercasedMessage.contains("inactive") ||
                   lowercasedMessage.contains("not found or inactive") {
                    Logger.shared.error("❌ Challenge not found or inactive")
                    throw AppError.serverError("Челлендж не найден или недоступен")
                }
                
                if lowercasedMessage.contains("challenge has already ended") {
                    Logger.shared.error("❌ Challenge has already ended")
                    throw AppError.serverError("Челлендж уже завершен")
                }
                
                if lowercasedMessage.contains("insufficient balance") {
                    Logger.shared.error("❌ Insufficient balance")
                    throw AppError.insufficientFunds
                }
                
                // Пытаемся определить конкретную причину ошибки через ErrorHandler
                let appError = ErrorHandler.handle(error)
                
                // Если это уже известная ошибка (например, alreadyJoined), используем её
                if case .alreadyJoined = appError {
                    throw appError
                }
                
                // Иначе показываем общее сообщение с дополнительной информацией
                let finalMessage = extractedErrorMessage ?? "Не удалось вступить в челлендж. Возможно, вы уже участвуете в этом челлендже или он недоступен. Проверьте раздел «Мои челленджи»."
                Logger.shared.error("❌ Final error message: \(finalMessage)")
                throw AppError.serverError(finalMessage)
            }
            
            throw ErrorHandler.handle(error)
        }
    }
    
    /// Загрузить UserChallenge по ID
    private func fetchUserChallenge(id: Int64) async throws -> UserChallenge {
        let response: [UserChallengeResponse] = try await supabase
            .from("user_challenges")
            .select("*, challenge:challenges(*)")
            .eq("id", value: String(id))
            .execute()
            .value
        
        guard let first = response.first else {
            throw AppError.dataNotFound
        }
        
        return first.toUserChallenge()
    }
    
    /// Структура для парсинга ошибок от Edge Functions
    private struct EdgeFunctionErrorResponse: Codable {
        let error: String
        let code: String?
        let details: String?
        let hint: String?
    }
    
    /// Прямой HTTP запрос к Edge Function для получения полного ответа, включая тело ошибки
    private func callEdgeFunctionDirectly<T: Codable, R: Codable>(
        functionName: String,
        body: T
    ) async throws -> R {
        // Получаем URL и токен
        guard let supabaseURL = URL(string: AppConfig.supabaseURL) else {
            throw AppError.serverError("Invalid Supabase URL")
        }
        
        let functionURL = supabaseURL.appendingPathComponent("functions/v1/\(functionName)")
        
        // Получаем токен авторизации
        let session = try await supabase.auth.session
        let accessToken = session.accessToken
        
        // Создаем запрос
        var request = URLRequest(url: functionURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfig.supabaseKey, forHTTPHeaderField: "apikey")
        
        // Кодируем тело запроса
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)
        
        Logger.shared.info("🌐 Direct HTTP request to Edge Function: \(functionName)")
        Logger.shared.info("   URL: \(functionURL.absoluteString)")
        
        // Выполняем запрос
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.serverError("Invalid response type")
        }
        
        Logger.shared.info("📥 HTTP Response: status=\(httpResponse.statusCode)")
        
        // Логируем тело ответа для диагностики
        if let responseString = String(data: data, encoding: .utf8) {
            Logger.shared.info("📥 Response body: \(responseString)")
        }
        
        // Если статус не 2xx, пытаемся распарсить ошибку
        if !(200...299).contains(httpResponse.statusCode) {
            // Пытаемся распарсить JSON с ошибкой
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? String {
                Logger.shared.error("❌ Edge Function error: \(errorMessage)")
                
                // Пытаемся декодировать как EdgeFunctionErrorResponse
                if let errorResponse = try? JSONDecoder().decode(EdgeFunctionErrorResponse.self, from: data) {
                    Logger.shared.error("   Code: \(errorResponse.code ?? "nil")")
                    Logger.shared.error("   Details: \(errorResponse.details ?? "nil")")
                    Logger.shared.error("   Hint: \(errorResponse.hint ?? "nil")")
                    
                    // Бросаем ошибку с детальным сообщением
                    let nsError = NSError(
                        domain: "EdgeFunctionError",
                        code: httpResponse.statusCode,
                        userInfo: [
                            "error": errorMessage,
                            "code": errorResponse.code ?? "",
                            "details": errorResponse.details ?? "",
                            "data": data
                        ]
                    )
                    throw nsError
                }
            }
            
            // Если не удалось распарсить, бросаем общую ошибку
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            Logger.shared.error("❌ Edge Function HTTP \(httpResponse.statusCode): \(errorMessage)")
            
            let nsError = NSError(
                domain: "EdgeFunctionError",
                code: httpResponse.statusCode,
                userInfo: [
                    "message": "Edge Function returned HTTP \(httpResponse.statusCode)",
                    "data": data
                ]
            )
            throw nsError
        }
        
        // Декодируем успешный ответ.
        // Важно: часть наших моделей использует явные CodingKeys со snake_case.
        // Поэтому сначала пробуем default keys, а если не вышло — fallback на convertFromSnakeCase
        // (некоторые edge functions возвращают camelCase/snake_case без явных CodingKeys в моделях).
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(R.self, from: data)
        } catch {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(R.self, from: data)
        }
    }
    
    /// Преобразует ошибки Edge Function в понятные пользователю сообщения
    private func mapEdgeFunctionError(_ error: String) -> String {
        switch error.lowercased() {
        case let e where e.contains("row-level security") || e.contains("row level security") || e.contains("rls"):
            return "Недостаточно прав для операции (RLS). Обновите политики Supabase."
        case let e where e.contains("challenge not found") || e.contains("inactive"):
            return "Челлендж не найден или неактивен"
        case let e where e.contains("already ended"):
            return "Челлендж уже завершён"
        case let e where e.contains("user not found"):
            return "Пользователь не найден. Попробуйте перезайти в приложение."
        case let e where e.contains("already joined"):
            return "Вы уже участвуете в этом челлендже"
        case let e where e.contains("insufficient balance"):
            return "Недостаточно средств на балансе"
        case let e where e.contains("not started"):
            return "Челлендж ещё не начался"
        default:
            return error
        }
    }
    
    func completeDay(challengeId: Int64) async throws {
        Logger.shared.info("=== SupabaseManager.completeDay START === challengeId: \(challengeId)")
        
        // Проверяем сессию
        do {
            let session = try await supabase.auth.session
            Logger.shared.info("completeDay: Session found for user: \(session.user.id)")
        } catch {
            // Если сессии нет, пробрасываем ошибку
            Logger.shared.warning("No active session for completeDay")
            throw AppError.authenticationRequired
        }
        
        // Edge Function ожидает camelCase: challengeId
        struct CompleteDayBody: Codable {
            let challengeId: Int64
        }
        
        let body = CompleteDayBody(challengeId: challengeId)
        Logger.shared.info("completeDay: Calling Edge Function with challengeId: \(challengeId)")
        
        struct CompleteDayResponse: Codable {
            let success: Bool?
            let error: String?
            let data: CompleteDayData?
        }
        
        struct CompleteDayData: Codable {
            let completedDays: Int?
            let isCompleted: Bool?
            let payout: Double?
        }
        
        do {
            // Используем прямой HTTP вызов, чтобы получать тело ошибки (Supabase SDK для invoke
            // часто возвращает "400" без details).
            let result: CompleteDayResponse = try await callEdgeFunctionDirectly(
                functionName: "complete-day",
                body: body
            )
            
            if let errorMessage = result.error {
                Logger.shared.error("completeDay: Edge Function returned error: \(errorMessage)")
                throw AppError.serverError(mapEdgeFunctionError(errorMessage))
            }
            
            Logger.shared.info("=== SupabaseManager.completeDay SUCCESS ===")
        } catch {
            Logger.shared.error("completeDay: Edge Function FAILED", error: error)
            let nsError = error as NSError
            
            // Если удалось вытащить сообщение от функции — показываем понятно пользователю
            if let errorMessage = nsError.userInfo["error"] as? String {
                throw AppError.serverError(mapEdgeFunctionError(errorMessage))
            }
            
            if let errorData = nsError.userInfo["data"] as? Data,
               let errorString = String(data: errorData, encoding: .utf8) {
                Logger.shared.error("completeDay: Error response data: \(errorString)")
                if let json = try? JSONSerialization.jsonObject(with: errorData) as? [String: Any],
                   let errorMsg = json["error"] as? String {
                    throw AppError.serverError(mapEdgeFunctionError(errorMsg))
                }
            }
            
            throw ErrorHandler.handle(error)
        }
    }
    
    func failChallenge(challengeId: Int64) async throws {
        Logger.shared.info("=== SupabaseManager.failChallenge START === challengeId: \(challengeId)")
        
        // Проверяем и обновляем сессию
        var session: Session
        do {
            session = try await supabase.auth.session
            
            // Проверяем, не истекла ли сессия
            if session.isExpired {
                Logger.shared.warning("failChallenge: Session expired, attempting refresh...")
                do {
                    let refreshed = try await supabase.auth.refreshSession()
                    Logger.shared.info("failChallenge: Session refreshed successfully")
                    session = refreshed
                } catch {
                    Logger.shared.error("failChallenge: Failed to refresh session", error: error)
                    throw AppError.authenticationRequired
                }
            }
            
            Logger.shared.info("failChallenge: Session found for user: \(session.user.id)")
        } catch {
            Logger.shared.error("failChallenge: No active session", error: error)
            throw AppError.authenticationRequired
        }
        
        // Edge Function ожидает camelCase: challengeId
        struct FailChallengeBody: Codable {
            let challengeId: Int64
        }
        
        let body = FailChallengeBody(challengeId: challengeId)
        Logger.shared.info("failChallenge: Calling Edge Function with challengeId: \(challengeId)")
        Logger.shared.info("failChallenge: Session accessToken prefix: \(session.accessToken.prefix(20))...")
        Logger.shared.info("failChallenge: Session expiresAt: \(session.expiresAt)")
        Logger.shared.info("failChallenge: Session isExpired: \(session.isExpired)")
        
        do {
            // Supabase SDK автоматически передает токен из текущей сессии
            // Но убеждаемся, что сессия актуальна
            try await supabase.functions
                .invoke("fail-challenge", options: FunctionInvokeOptions(body: body))
            
            Logger.shared.info("=== SupabaseManager.failChallenge SUCCESS ===")
        } catch {
            Logger.shared.error("failChallenge: Edge Function FAILED", error: error)
            let nsError = error as NSError
            Logger.shared.error("failChallenge: Error domain: \(nsError.domain), code: \(nsError.code)")
            Logger.shared.error("failChallenge: Error description: \(error.localizedDescription)")
            
            // Пытаемся извлечь детали ошибки из response
            if let errorData = nsError.userInfo["data"] as? Data,
               let errorString = String(data: errorData, encoding: .utf8) {
                Logger.shared.error("failChallenge: Error response data: \(errorString)")
                
                // Пытаемся распарсить JSON из ответа
                if let json = try? JSONSerialization.jsonObject(with: errorData) as? [String: Any] {
                    if let errorMsg = json["error"] as? String {
                        Logger.shared.error("failChallenge: Extracted error message: \(errorMsg)")
                    }
                    if let details = json["details"] as? String {
                        Logger.shared.error("failChallenge: Extracted error details: \(details)")
                    }
                }
            }
            
            // FALLBACK: Если Edge Function вернул 401, пытаемся обновить напрямую через Supabase client
            // Это работает только если RLS политики для UPDATE созданы
            if nsError.code == 0 && error.localizedDescription.contains("401") {
                Logger.shared.warning("failChallenge: Edge Function returned 401, attempting direct update via Supabase client...")
                
                do {
                    // Находим user_challenge_id по challenge_id
                    guard let user = try await getCurrentUser(),
                          let uuid = UUID(uuidString: user.id) else {
                        throw AppError.dataNotFound
                    }
                    
                    // Ищем user_challenge по challenge_id
                    Logger.shared.info("failChallenge: Looking for user_challenge with challengeId=\(challengeId), userId=\(uuid.uuidString)")
                    
                    // Упрощенная структура для поиска только по id
                    struct UserChallengeIdResponse: Codable {
                        let id: Int64
                    }
                    
                    let userChallenges: [UserChallengeIdResponse] = try await supabase
                        .from("user_challenges")
                        .select("id")
                        .eq("user_id", value: uuid.uuidString)
                        .eq("challenge_id", value: String(challengeId))
                        .execute()
                        .value
                    
                    guard let userChallengeResponse = userChallenges.first else {
                        Logger.shared.error("failChallenge: User challenge not found for direct update - challengeId=\(challengeId), userId=\(uuid.uuidString)")
                        Logger.shared.error("failChallenge: This might mean RLS policies are blocking SELECT or the record doesn't exist")
                        throw AppError.dataNotFound
                    }
                    
                    Logger.shared.info("failChallenge: Found user_challenge id=\(userChallengeResponse.id), attempting direct update...")
                    
                    // Обновляем напрямую через Supabase client
                    struct FailChallengeUpdate: Codable {
                        let is_failed: Bool
                        let is_active: Bool
                        let failed_at: String
                    }
                    
                    let failedAtString = ISO8601DateFormatter.flexible.string(from: Date())
                    
                    let update = FailChallengeUpdate(
                        is_failed: true,
                        is_active: false,
                        failed_at: failedAtString
                    )
                    
                    Logger.shared.info("failChallenge: Update payload - is_failed=true, is_active=false, failed_at=\(failedAtString)")
                    
                    // Используем execute() без .value, так как update может не возвращать данные
                    // Если RLS блокирует, получим ошибку здесь
                    _ = try await supabase
                        .from("user_challenges")
                        .update(update)
                        .eq("id", value: String(userChallengeResponse.id))
                        .execute()
                    
                    // Проверяем, что обновление действительно произошло
                    Logger.shared.info("failChallenge: Update executed, verifying in database...")
                    
                    // Упрощенная структура для проверки
                    struct UserChallengeVerifyResponse: Codable {
                        let id: Int64
                        let is_failed: Bool
                        let is_active: Bool
                        
                        enum CodingKeys: String, CodingKey {
                            case id
                            case is_failed
                            case is_active
                        }
                    }
                    
                    let verifyChallenges: [UserChallengeVerifyResponse] = try await supabase
                        .from("user_challenges")
                        .select("id, is_failed, is_active")
                        .eq("id", value: String(userChallengeResponse.id))
                        .execute()
                        .value
                    
                    if let verified = verifyChallenges.first {
                        Logger.shared.info("failChallenge: Verified - id=\(verified.id), is_failed=\(verified.is_failed), is_active=\(verified.is_active)")
                        
                        if verified.is_failed && !verified.is_active {
                            Logger.shared.info("failChallenge: Direct update via Supabase client SUCCESS - verified in DB")
                            Logger.shared.info("=== SupabaseManager.failChallenge SUCCESS (via direct update) ===")
                            return
                        } else {
                            Logger.shared.error("failChallenge: Update executed but verification failed - is_failed=\(verified.is_failed), is_active=\(verified.is_active)")
                            Logger.shared.error("failChallenge: This means RLS policies are blocking the update or not working correctly!")
                            throw AppError.serverError("Update executed but verification failed - RLS may be blocking")
                        }
                    } else {
                        Logger.shared.error("failChallenge: Update executed but could not verify - record not found")
                        throw AppError.dataNotFound
                    }
                } catch {
                    Logger.shared.error("failChallenge: Direct update also FAILED", error: error)
                    Logger.shared.error("failChallenge: This likely means RLS policies for UPDATE are missing!")
                    Logger.shared.error("=== SupabaseManager.failChallenge FAILED ===")
                    throw error
                }
            }
            
            Logger.shared.error("=== SupabaseManager.failChallenge FAILED ===")
            throw error
        }
    }
    
    func getActiveChallenge() async throws -> UserChallenge? {
        guard let user = try await getCurrentUser(),
              let uuid = UUID(uuidString: user.id) else {
            return nil
        }
        
        let response: [UserChallengeResponse] = try await supabase
            .from("user_challenges")
            .select("*, challenge:challenges(*)")
            .eq("user_id", value: uuid.uuidString)
            .eq("is_active", value: true)
            .execute()
            .value
        
        guard let first = response.first else { return nil }
        
        // Загружаем completed_days
        struct CompletedDayResponse: Codable {
            let completedDate: Date
            
            enum CodingKeys: String, CodingKey {
                case completedDate = "completed_date"
            }
        }
        
        var userChallenge = first.toUserChallenge()
        let completedDaysResponse: [CompletedDayResponse] = try await supabase
            .from("completed_days")
            .select()
            .eq("user_challenge_id", value: String(first.id))
            .execute()
            .value
        
        userChallenge.completedDays = completedDaysResponse.map { $0.completedDate }
        return userChallenge
    }
    
    func getUserChallenges() async throws -> [UserChallenge] {
        guard let user = try await getCurrentUser(),
              let uuid = UUID(uuidString: user.id) else {
            throw AppError.dataNotFound
        }
        
        // Загружаем с retry
        let response: [UserChallengeResponse] = try await networkRetry.execute { [self] in
            try await self.supabase
                .from("user_challenges")
                .select("*, challenge:challenges(*)")
                .eq("user_id", value: uuid.uuidString)
                .execute()
                .value
        }
        
        // Логируем количество загруженных записей для диагностики
        Logger.shared.info("🔍 SupabaseManager.getUserChallenges: Loaded \(response.count) challenges from DB")
        
        // Загружаем completed_days для каждого челленджа
        struct CompletedDayResponse: Codable {
            let completedDate: String // ISO8601 строка
            
            enum CodingKeys: String, CodingKey {
                case completedDate = "completed_date"
            }
            
            func toDate() -> Date {
                return ISO8601DateFormatter.parseOrNow(completedDate)
            }
        }
        
        var userChallenges: [UserChallenge] = []
        for ucResponse in response {
            // Логируем сырые данные с сервера для диагностики
            Logger.shared.info("🔍 SupabaseManager.getUserChallenges: Raw response - id=\(ucResponse.id), challengeId=\(ucResponse.challengeId), isActive=\(ucResponse.isActive), isCompleted=\(ucResponse.isCompleted), isFailed=\(ucResponse.isFailed)")
            
            // КРИТИЧЕСКАЯ ПРОВЕРКА: Если данные с сервера неправильные, логируем предупреждение
            if !ucResponse.isActive && !ucResponse.isCompleted && !ucResponse.isFailed {
                Logger.shared.error("❌ CRITICAL: Server returned invalid state - id=\(ucResponse.id), challengeId=\(ucResponse.challengeId), isActive=\(ucResponse.isActive), isCompleted=\(ucResponse.isCompleted), isFailed=\(ucResponse.isFailed)")
                Logger.shared.error("   This challenge should be marked as FAILED but server returned isFailed=false!")
            }
            
            var userChallenge = ucResponse.toUserChallenge()
            
            // Загружаем completed_days
            let completedDaysResponse: [CompletedDayResponse] = try await supabase
                .from("completed_days")
                .select()
                .eq("user_challenge_id", value: String(ucResponse.id))
                .execute()
                .value
            
            userChallenge.completedDays = completedDaysResponse.map { $0.toDate() }
            
            // Логируем проваленные челленджи для диагностики
            if userChallenge.isFailed {
                Logger.shared.info("🔍 SupabaseManager.getUserChallenges: Found FAILED challenge - id=\(userChallenge.id), challengeId=\(userChallenge.challengeId), isActive=\(userChallenge.isActive), isCompleted=\(userChallenge.isCompleted), completedDaysCount=\(userChallenge.completedDays.count)")
            } else if !userChallenge.isActive && !userChallenge.isCompleted {
                // Логируем неактивные и незавершенные челленджи (возможно проваленные, но isFailed=false)
                Logger.shared.warning("⚠️ SupabaseManager.getUserChallenges: Inactive but not failed challenge - id=\(userChallenge.id), challengeId=\(userChallenge.challengeId), isActive=\(userChallenge.isActive), isCompleted=\(userChallenge.isCompleted), isFailed=\(userChallenge.isFailed)")
            }
            
            userChallenges.append(userChallenge)
        }
        
        Logger.shared.info("🔍 SupabaseManager.getUserChallenges: Total loaded=\(userChallenges.count), failed=\(userChallenges.filter { $0.isFailed }.count), completed=\(userChallenges.filter { $0.isCompleted }.count), active=\(userChallenges.filter { $0.isActive && !$0.isCompleted && !$0.isFailed }.count)")
        
        return userChallenges
    }
    
}

// MARK: - Response Models
private struct UserProfileResponse: Codable {
    let id: String
    let email: String
    let name: String
    let balance: Double
    let authProvider: String
    let createdAt: String // ISO8601 строка
    let honestStreak: Int // Честная серия
    let avatarUrl: String? // URL аватарки
    
    enum CodingKeys: String, CodingKey {
        case id, email, name, balance
        case authProvider = "auth_provider"
        case createdAt = "created_at"
        case honestStreak = "honest_streak"
        case avatarUrl = "avatar_url"
    }
    
    func toCreatedDate() -> Date {
        return ISO8601DateFormatter.parseOrNow(createdAt)
    }
}

private struct ChallengeResponse: Codable {
    let id: Int64
    let title: String
    let subtitle: String
    let icon: String
    let duration: Int
    let entryFee: Double
    let serviceFeePercent: Double
    let startDate: String // ISO8601 строка
    let endDate: String   // ISO8601 строка
    let participants: Int
    let prizePool: Double
    let activeParticipants: Int
    let description: String?
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, icon, duration, description
        case entryFee = "entry_fee"
        case serviceFeePercent = "service_fee_percent"
        case startDate = "start_date"
        case endDate = "end_date"
        case participants
        case prizePool = "prize_pool"
        case activeParticipants = "active_participants"
        case isActive = "is_active"
    }
    
    private func parseDate(_ dateString: String) -> Date {
        return ISO8601DateFormatter.parseOrNow(dateString)
    }
    
    func toChallenge(completedToday: Int = 0, failedToday: Int = 0) -> Challenge {
        return Challenge(
            id: String(id),
            title: title,
            subtitle: subtitle,
            icon: icon,
            duration: duration,
            entryFee: entryFee,
            serviceFee: serviceFeePercent,
            startDate: parseDate(startDate),
            endDate: parseDate(endDate),
            participants: participants,
            prizePool: prizePool,
            activeParticipants: activeParticipants,
            completedToday: completedToday,
            failedToday: failedToday,
            description: description ?? "",
            rules: [] // Load separately if needed
        )
    }
}

private struct UserChallengeResponse: Codable {
    let id: Int64
    let userId: String
    let challengeId: Int64
    let entryDate: String // Приходит как ISO8601 строка
    let isActive: Bool
    let isCompleted: Bool
    let isFailed: Bool
    let payout: Double?
    let challenge: ChallengeResponse?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case challengeId = "challenge_id"
        case entryDate = "entry_date"
        case isActive = "is_active"
        case isCompleted = "is_completed"
        case isFailed = "is_failed"
        case payout
        case challenge
    }
    
    func toUserChallenge() -> UserChallenge {
        // Парсим дату из строки
        let parsedDate = ISO8601DateFormatter.parseOrNow(entryDate)
        
        // Логируем статусы для диагностики проваленных челленджей
        if isFailed {
            Logger.shared.info("🔍 UserChallengeResponse.toUserChallenge: FAILED challenge detected - id=\(id), challengeId=\(challengeId), isActive=\(isActive), isCompleted=\(isCompleted), isFailed=\(isFailed)")
        }
        
        return UserChallenge(
            id: String(id),
            challengeId: String(challengeId),
            userId: userId,
            entryDate: parsedDate,
            completedDays: [], // Load separately
            isActive: isActive,
            isCompleted: isCompleted,
            isFailed: isFailed,
            payout: payout
        )
    }
}

// MARK: - Honest Streak Extension
extension SupabaseManager {
    
    func incrementHonestStreak(userId: String) async throws -> Int {
        Logger.shared.info("🔄 SupabaseManager.incrementHonestStreak: Starting, userId=\(userId)")
        
        do {
            let response: Int = try await supabase.rpc("increment_honest_streak", params: [
                "p_user_id": userId
            ]).execute().value
            
            Logger.shared.info("✅ SupabaseManager.incrementHonestStreak: Success, userId=\(userId), newStreak=\(response)")
            return response
        } catch {
            Logger.shared.error("❌ SupabaseManager.incrementHonestStreak: Failed", error: error)
            throw ErrorHandler.handle(error)
        }
    }
    
    func resetHonestStreak(userId: String) async throws -> Int {
        Logger.shared.info("🔄 SupabaseManager.resetHonestStreak: Starting, userId=\(userId)")
        
        do {
            let response: Int = try await supabase.rpc("reset_honest_streak", params: [
                "p_user_id": userId
            ]).execute().value
            
            Logger.shared.info("✅ SupabaseManager.resetHonestStreak: Success, userId=\(userId), newStreak=\(response)")
            return response
        } catch {
            Logger.shared.error("❌ SupabaseManager.resetHonestStreak: Failed", error: error)
            throw ErrorHandler.handle(error)
        }
    }
}

// MARK: - Analytics
extension SupabaseManager {
    
    private struct AnalyticsEventInsertRow: Encodable, Sendable {
        let user_id: UUID
        let session_id: UUID
        let event_name: String
        let challenge_id: Int64?
        let amount: Double?
        let props: [String: String]
    }
    
    /// Best-effort analytics insert into `public.analytics_events`.
    /// Never throws by design (analytics must not break product flows).
    func trackEvent(
        eventName: String,
        sessionId: UUID,
        challengeId: Int64? = nil,
        amount: Double? = nil,
        props: [String: String] = [:]
    ) async {
        guard AppConfig.isConfigured else { return }
        
        do {
            let session = try await supabase.auth.session
            let row = AnalyticsEventInsertRow(
                user_id: session.user.id,
                session_id: sessionId,
                event_name: eventName,
                challenge_id: challengeId,
                amount: amount,
                props: props
            )
            
            _ = try await supabase
                .from("analytics_events")
                .insert(row)
                .execute()
        } catch {
            // Keep logs low-noise: debug only.
            Logger.shared.log(.debug, "📊 SupabaseManager.trackEvent: failed (ignored) - event=\(eventName)", error: error)
        }
    }
}
