//
//  ChallengeManager.swift
//  ChallengeApp
//
//  Менеджер для управления челленджами
//

import Foundation
import Combine

/// ChallengeManager с thread-safety через @MainActor
/// Все операции выполняются на главном потоке, что предотвращает race conditions
@MainActor
final class ChallengeManager: ChallengeManagerProtocol, ObservableObject {
    @Published var availableChallenges: [Challenge] = []
    @Published var userChallenges: [UserChallenge] = []
    @Published var activeChallenge: UserChallenge?
    @Published var isLoading = false
    @Published var lastError: String?
    
    private let userDefaults = UserDefaults.standard
    private let challengesKey = "availableChallenges"
    private let userChallengesKey = "userChallenges"
    // supabaseManager thread-safe (SupabaseClient internally handles concurrency)
    private let supabaseManager: any SupabaseManagerProtocol
    private let cacheManager: any CacheManagerProtocol
    
    init(supabaseManager: any SupabaseManagerProtocol = DIContainer.shared.supabase, 
         cacheManager: any CacheManagerProtocol = DIContainer.shared.cacheManager) {
        self.supabaseManager = supabaseManager
        self.cacheManager = cacheManager
        loadChallenges()
        loadUserChallenges()
        checkActiveChallenge()
    }
    
    // MARK: - Supabase Integration
    
    /// Загрузить челленджи из Supabase (реализация протокола с параметром)
    func loadChallengesFromSupabase(forceRefresh: Bool) async {
        // @MainActor гарантирует выполнение на главном потоке
        isLoading = true
        lastError = nil
        
        // Если требуется принудительное обновление, очищаем кэш
        if forceRefresh {
            Logger.shared.info("Force refresh requested, clearing cache and loading from server")
            cacheManager.remove("challenges")
        }
        
        // 1. Проверяем кэш - если есть и не требуется принудительное обновление, используем его
        if !forceRefresh, let cachedChallenges = cacheManager.getCachedChallenges() {
            Logger.shared.info("Loading challenges from cache, count: \(cachedChallenges.count)")
            // @MainActor гарантирует выполнение на главном потоке
            self.availableChallenges = cachedChallenges
            self.isLoading = false
            return
        }
        
        // 2. Загружаем из сети с retry
        // Выполняем сетевой вызов вне MainActor контекста для безопасности
        do {
            let challenges = try await Task.detached { [supabaseManager] in
                try await DIContainer.shared.networkRetry.execute {
                    try await supabaseManager.getChallenges()
                }
            }.value
            
            // 3. Кэшируем результат
            cacheManager.cacheChallenges(challenges)
            
            // @MainActor гарантирует выполнение на главном потоке
            self.availableChallenges = challenges
            self.isLoading = false
            // Сохраняем в локальное хранилище для офлайн режима
            self.saveChallenges()
        } catch is CancellationError {
            // Не логируем CancellationError как ошибку
            self.isLoading = false
        } catch {
            self.isLoading = false
            self.lastError = error.localizedDescription
            Logger.shared.error("Error loading challenges from Supabase", error: error)
            
            // Fallback на локальные данные, если есть
            if !self.availableChallenges.isEmpty {
                Logger.shared.info("Keeping existing local challenges (\(self.availableChallenges.count) items)")
            } else {
                // Fallback на локальные данные из UserDefaults
                self.loadChallenges()
            }
        }
    }
    
    /// Загрузить челленджи пользователя из Supabase
    // Реализация протокола (без параметров) - для обратной совместимости
    func loadUserChallengesFromSupabase() async {
        await loadUserChallengesFromSupabase(forceRefresh: false)
    }
    
    /// Загрузить челленджи из Supabase (без параметров - для обратной совместимости)
    func loadChallengesFromSupabase() async {
        await loadChallengesFromSupabase(forceRefresh: false)
    }
    
    // Внутренний метод с параметром forceRefresh
    func loadUserChallengesFromSupabase(forceRefresh: Bool) async {
        // @MainActor гарантирует выполнение на главном потоке
        isLoading = true
        
        // 1. Проверяем кэш - если есть и не требуется принудительное обновление, используем его
        if !forceRefresh, let cachedUserChallenges = cacheManager.getCachedUserChallenges() {
            Logger.shared.info("Loading user challenges from cache, count: \(cachedUserChallenges.count)")
            self.userChallenges = cachedUserChallenges
            self.isLoading = false
            self.checkActiveChallenge()
            return // ВАЖНО: выходим, если есть кэш и не требуется принудительное обновление
        }
        
        // Если требуется принудительное обновление, очищаем кэш
        if forceRefresh {
            Logger.shared.info("Force refresh requested, clearing cache and loading from server")
            cacheManager.remove("userChallenges")
        }
        
        // 2. Загружаем из сети с retry (только если кэша нет)
        do {
            // Выполняем сетевой вызов вне MainActor контекста для безопасности
            let userChallenges = try await Task.detached { [supabaseManager] in
                try await DIContainer.shared.networkRetry.execute {
                    try await supabaseManager.getUserChallenges()
                }
            }.value
            
            // 3. Логируем статусы загруженных user_challenges
            Logger.shared.info("Loaded \(userChallenges.count) user challenges from server:")
            for uc in userChallenges {
                Logger.shared.info("  - Challenge \(uc.challengeId): isActive=\(uc.isActive), isCompleted=\(uc.isCompleted), isFailed=\(uc.isFailed), payout=\(uc.payout ?? 0)")
            }
            
            // 4. Кэшируем результат
            cacheManager.cacheUserChallenges(userChallenges)
            
            // @MainActor гарантирует выполнение на главном потоке
            self.userChallenges = userChallenges
            self.isLoading = false
            self.checkActiveChallenge()
            // Сохраняем в локальное хранилище
            self.saveUserChallenges()
        } catch is CancellationError {
            // Не логируем CancellationError как ошибку
            self.isLoading = false
        } catch {
            self.isLoading = false
            Logger.shared.error("Error loading user challenges from Supabase", error: error)
            
            // Fallback на локальные данные, если есть
            if !self.userChallenges.isEmpty {
                Logger.shared.info("Keeping existing local userChallenges (\(self.userChallenges.count) items)")
            } else {
                // Fallback на локальные данные из UserDefaults
                self.loadUserChallenges()
            }
        }
    }
    
    /// Синхронизировать все данные с Supabase
    func syncWithSupabase() async {
        await loadChallengesFromSupabase()
        await loadUserChallengesFromSupabase()
    }
    
    // MARK: - Load Data
    func loadChallenges() {
        // Локальные челленджи отключены. Не читаем и не храним availableChallenges на диске.
        userDefaults.removeObject(forKey: challengesKey)
        self.availableChallenges = []
    }
    
    func loadUserChallenges() {
        if let data = userDefaults.data(forKey: userChallengesKey),
           let userChallenges = try? JSONDecoder().decode([UserChallenge].self, from: data) {
            self.userChallenges = userChallenges
        }
    }
    
    func saveUserChallenges() {
        if let data = try? JSONEncoder().encode(userChallenges) {
            userDefaults.set(data, forKey: userChallengesKey)
        }
    }
    
    // MARK: - Challenge Management
    func joinChallenge(_ challenge: Challenge, userId: String) async throws -> UserChallenge {
        // Прямая оплата - оплата уже прошла, просто вступаем в челлендж
        // Пытаемся через Supabase
        if let challengeId = Int64(challenge.id) {
            do {
                // Выполняем сетевой вызов вне MainActor контекста для безопасности
                let userChallenge = try await Task.detached { [supabaseManager] in
                    try await supabaseManager.joinChallenge(challengeId: challengeId, userId: userId)
                }.value
                
                Logger.shared.info("Successfully joined challenge \(challengeId), reloading user challenges from server...")
                
                // ВАЖНО: Очищаем кэш перед перезагрузкой, чтобы получить актуальные данные
                cacheManager.remove("userChallenges")
                
                // ВАЖНО: Перезагружаем userChallenges с сервера, чтобы получить актуальные данные
                // Это гарантирует, что кэш обновится и следующая проверка isAlreadyParticipating будет корректной
                do {
                    // Небольшая задержка для гарантии, что данные в БД уже сохранены
                    try await Task.sleep(nanoseconds: UInt64(TimingConstants.shortDelay * 1_000_000_000))
                    
                    // Выполняем сетевой вызов вне MainActor контекста для безопасности
                    let updatedUserChallenges = try await Task.detached { [supabaseManager] in
                        try await supabaseManager.getUserChallenges()
                    }.value
                    
                    Logger.shared.info("User challenges reloaded after join, count: \(updatedUserChallenges.count)")
                    for uc in updatedUserChallenges {
                        Logger.shared.info("  - UserChallenge id=\(uc.id), challengeId=\(uc.challengeId), userId=\(uc.userId), isActive=\(uc.isActive)")
                    }
                    
                    // @MainActor гарантирует выполнение на главном потоке
                    self.userChallenges = updatedUserChallenges
                    self.cacheManager.cacheUserChallenges(updatedUserChallenges)
                    self.saveUserChallenges()
                    
                    // Находим только что созданный userChallenge и устанавливаем его как active
                    if let newActiveChallenge = updatedUserChallenges.first(where: { $0.challengeId == challenge.id && $0.isActive }) {
                        self.activeChallenge = newActiveChallenge
                        Logger.shared.info("Active challenge set: id=\(newActiveChallenge.id), challengeId=\(newActiveChallenge.challengeId)")
                    } else {
                        Logger.shared.warning("No active challenge found after join for challengeId=\(challenge.id)")
                    }
                } catch {
                    Logger.shared.warning("Failed to reload user challenges after join, using returned userChallenge", error: error)
                    // Fallback: используем userChallenge, который вернул joinChallenge
                    // @MainActor гарантирует выполнение на главном потоке
                    if !self.userChallenges.contains(where: { $0.id == userChallenge.id }) {
                        self.userChallenges.append(userChallenge)
                        Logger.shared.info("Added userChallenge to local array: id=\(userChallenge.id)")
                    }
                    self.activeChallenge = userChallenge
                    self.cacheManager.cacheUserChallenges(self.userChallenges)
                    self.saveUserChallenges()
                }
                
                return userChallenge
            } catch {
                Logger.shared.error("Error joining challenge via Supabase", error: error)
                
                // Преобразуем в AppError
                throw ErrorHandler.handle(error)
            }
        } else {
            // Локальные челленджи запрещены — только БД.
            throw AppError.invalidData("Invalid challenge ID: \(challenge.id)")
        }
    }
    
    /// Завершить день по challengeId (требуется протоколом)
    func completeDay(challengeId: Int64) async throws {
        // Ищем userChallenge по challengeId
        guard let userChallenge = userChallenges.first(where: { $0.challengeId == String(challengeId) }) else {
            throw AppError.invalidData("User challenge not found for challengeId: \(challengeId)")
        }
        try await completeDay(for: userChallenge)
    }
    
    func completeDay(for userChallenge: UserChallenge) async throws {
        Logger.shared.info("✅ ChallengeManager.completeDay: Starting, userChallengeId=\(userChallenge.id), challengeId=\(userChallenge.challengeId), currentDay=\(userChallenge.currentDay), hasCompletedToday=\(userChallenge.hasCompletedToday)")
        Logger.shared.debug("✅ ChallengeManager.completeDay: Local state - isActive=\(userChallenge.isActive), isCompleted=\(userChallenge.isCompleted), isFailed=\(userChallenge.isFailed)")
        
                // Пытаемся через Supabase
        if let challengeId = Int64(userChallenge.challengeId) {
            do {
                Logger.shared.info("✅ ChallengeManager.completeDay: Calling Supabase, challengeId=\(challengeId)")
                // Выполняем сетевой вызов вне MainActor контекста для безопасности
                try await Task.detached { [supabaseManager] in
                    try await supabaseManager.completeDay(challengeId: challengeId)
                }.value
                Logger.shared.info("✅ ChallengeManager.completeDay: Supabase success")
                
                // ВАЖНО: Загружаем обновленные данные с сервера чтобы получить payout и обновленный баланс
                Logger.shared.info("✅ ChallengeManager.completeDay: Reloading user challenges and user data to get payout and updated balance")
                
                // Загружаем обновленные user_challenges (с payout)
                do {
                    // Выполняем сетевой вызов вне MainActor контекста для безопасности
                    let updatedUserChallenges = try await Task.detached { [supabaseManager] in
                        try await supabaseManager.getUserChallenges()
                    }.value
                    // @MainActor гарантирует выполнение на главном потоке
                    // Обновляем userChallenges с данными с сервера
                    self.userChallenges = updatedUserChallenges
                    self.cacheManager.cacheUserChallenges(updatedUserChallenges)
                    self.saveUserChallenges()
                    self.checkActiveChallenge()
                    Logger.shared.info("✅ ChallengeManager.completeDay: Updated userChallenges from server, count=\(updatedUserChallenges.count)")
                } catch {
                    Logger.shared.warning("⚠️ ChallengeManager.completeDay: Failed to reload user challenges, using local update", error: error)
                    // Fallback на локальное обновление
                    // @MainActor гарантирует выполнение на главном потоке
                    self.completeDayLocal(for: userChallenge)
                }
                
                // Загружаем обновленные данные пользователя (с балансом)
                // Это обновит кэш, и AppState получит обновленные данные при следующем обращении
                do {
                    // Выполняем сетевой вызов вне MainActor контекста для безопасности
                    let updatedUser = try await Task.detached { [supabaseManager] in
                        try await supabaseManager.getCurrentUser()
                    }.value
                    
                    if let updatedUser = updatedUser {
                        Logger.shared.info("✅ ChallengeManager.completeDay: User balance updated, userId=\(updatedUser.id), balance=\(updatedUser.balance), honestStreak=\(updatedUser.honestStreak)")
                        
                        // Обновляем честную серию при успешном завершении дня
                        // (честное завершение = честное действие)
                        try await updateHonestStreak(userId: updatedUser.id, isHonest: true)
                        
                        // Отправляем уведомление для обновления UI (честная серия)
                        NotificationCenter.default.post(name: NSNotification.Name("UserDataUpdated"), object: nil)
                    }
                } catch {
                    Logger.shared.warning("⚠️ ChallengeManager.completeDay: Failed to reload user data", error: error)
                }
                
            } catch {
                Logger.shared.error("❌ ChallengeManager.completeDay: Supabase failed, using local fallback", error: error)
                
                // Если ошибка 400 - возможно, user_challenge уже завершён/провален в БД или день уже отмечен
                // Обновляем данные с сервера, чтобы синхронизировать состояние
                let errorMessage = error.localizedDescription
                if errorMessage.contains("400") || errorMessage.contains("Active challenge not found") {
                    Logger.shared.warning("completeDay returned 400 - challenge may be already completed/failed in DB. Syncing with server...")
                    do {
                        // Выполняем сетевой вызов вне MainActor контекста для безопасности
                        let updatedUserChallenges = try await Task.detached { [supabaseManager] in
                            try await supabaseManager.getUserChallenges()
                        }.value
                        // @MainActor гарантирует выполнение на главном потоке
                        self.userChallenges = updatedUserChallenges
                        self.cacheManager.cacheUserChallenges(updatedUserChallenges)
                        self.saveUserChallenges()
                        self.checkActiveChallenge()
                        Logger.shared.info("Synced userChallenges from server after 400 error, count: \(updatedUserChallenges.count)")
                        
                        // Проверяем, был ли день уже отмечен или челлендж завершён/провален
                        if let updatedUserChallenge = updatedUserChallenges.first(where: { $0.id == userChallenge.id }) {
                            let calendar = Calendar.current
                            let today = calendar.startOfDay(for: Date())
                            let isTodayCompleted = updatedUserChallenge.completedDays.contains { calendar.isDate($0, inSameDayAs: today) }
                            
                            if isTodayCompleted {
                                // День уже отмечен - это нормально, не пробрасываем ошибку
                                Logger.shared.info("Day already completed on server, UI will update automatically")
                                return
                            } else if updatedUserChallenge.isCompleted {
                                throw AppError.challengeAlreadyCompleted
                            } else if updatedUserChallenge.isFailed {
                                throw AppError.challengeAlreadyFailed
                            } else {
                                // Непонятная ситуация - пробрасываем общую ошибку
                                throw AppError.serverError("Не удалось отметить выполнение. Возможно, челлендж уже завершён или провален.")
                            }
                        } else {
                            // userChallenge не найден - возможно, челлендж был удалён
                            throw AppError.challengeNotFound
                        }
                    } catch {
                        Logger.shared.warning("Failed to sync with server after 400 error", error: error)
                        // Пробрасываем ошибку дальше, чтобы UI мог показать сообщение
                        throw error
                    }
                }
                
                // Для других ошибок пробрасываем их дальше
                throw ErrorHandler.handle(error)
            }
        } else {
            Logger.shared.warning("Invalid challengeId, using local fallback")
            // Fallback на локальное хранилище
            // @MainActor гарантирует выполнение на главном потоке
            self.completeDayLocal(for: userChallenge)
        }
        
        Logger.shared.info("=== completeDay END ===")
    }
    
    /// Локальное завершение дня (fallback)
    private func completeDayLocal(for userChallenge: UserChallenge) {
        Logger.shared.info("=== completeDayLocal START === id: \(userChallenge.id)")
        
        guard let index = userChallenges.firstIndex(where: { $0.id == userChallenge.id }) else {
            Logger.shared.warning("completeDayLocal: userChallenge not found with id: \(userChallenge.id)")
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        Logger.shared.debug("completeDayLocal: completedDays before: \(userChallenges[index].completedDays.count)")
        
        if !userChallenges[index].completedDays.contains(where: { calendar.isDate($0, inSameDayAs: today) }) {
            userChallenges[index].completedDays.append(today)
            Logger.shared.info("completeDayLocal: Added today to completedDays")
        } else {
            Logger.shared.info("completeDayLocal: Today already completed")
        }
        
        // Проверяем, завершен ли челлендж
        if let challenge = availableChallenges.first(where: { $0.id == userChallenge.challengeId }) {
            Logger.shared.debug("completeDayLocal: completedDays: \(userChallenges[index].completedDays.count), duration: \(challenge.duration)")
            
            if userChallenges[index].completedDays.count >= challenge.duration {
                Logger.shared.info("completeDayLocal: Challenge COMPLETED! Setting isCompleted=true, isActive=false")
                userChallenges[index].isCompleted = true
                userChallenges[index].isActive = false
                calculatePayout(for: &userChallenges[index], challenge: challenge)
                
                // Сбрасываем activeChallenge при завершении
                if activeChallenge?.id == userChallenge.id {
                    activeChallenge = nil
                    Logger.shared.info("completeDayLocal: Cleared activeChallenge")
                }
            } else {
                // Обновляем activeChallenge только если это текущий челлендж
                if activeChallenge?.id == userChallenge.id {
                    activeChallenge = userChallenges[index]
                    Logger.shared.info("completeDayLocal: Updated activeChallenge")
                }
            }
        }
        
        // ВАЖНО: Кэшируем обновленные данные (НЕ удаляем кэш!)
        cacheManager.cacheUserChallenges(userChallenges)
        Logger.shared.info("completeDayLocal: Cached userChallenges count: \(userChallenges.count)")
        
        saveUserChallenges()
        Logger.shared.info("=== completeDayLocal END ===")
    }
    
    /// Провалить челлендж по challengeId (требуется протоколом)
    func failChallenge(challengeId: Int64) async throws {
        // Ищем userChallenge по challengeId
        guard let userChallenge = userChallenges.first(where: { $0.challengeId == String(challengeId) }) else {
            throw AppError.invalidData("User challenge not found for challengeId: \(challengeId)")
        }
        try await failChallenge(userChallenge)
    }
    
    func failChallenge(_ userChallenge: UserChallenge) async throws {
        Logger.shared.info("❌ ChallengeManager.failChallenge: Starting, userChallengeId=\(userChallenge.id), challengeId=\(userChallenge.challengeId), userId=\(userChallenge.userId)")
        
        // Пытаемся через Supabase
        if let challengeId = Int64(userChallenge.challengeId) {
            do {
                Logger.shared.info("❌ ChallengeManager.failChallenge: Calling Supabase, challengeId=\(challengeId)")
                // Выполняем сетевой вызов вне MainActor контекста для безопасности
                try await Task.detached { [supabaseManager] in
                    try await supabaseManager.failChallenge(challengeId: challengeId)
                }.value
                Logger.shared.info("✅ ChallengeManager.failChallenge: Supabase success")
                
                // Обновляем честную серию при честном провале
                // (честный провал = пользователь сам признал провал)
                try await updateHonestStreak(userId: userChallenge.userId, isHonest: true)
                
                // Обновляем локальное состояние сразу для быстрого отклика UI
                // @MainActor гарантирует выполнение на главном потоке
                Logger.shared.info("❌ ChallengeManager.failChallenge: Updating local state")
                self.failChallengeLocal(userChallenge)
                
                // ВАЖНО: Принудительно обновляем данные с сервера после успешного провала
                // чтобы получить актуальный статус из БД и перезаписать локальные изменения
                Logger.shared.info("❌ ChallengeManager.failChallenge: Reloading user challenges from server after fail")
                await self.loadUserChallengesFromSupabase(forceRefresh: true)
                
                // Отправляем уведомление для обновления UI (честная серия)
                NotificationCenter.default.post(name: NSNotification.Name("UserDataUpdated"), object: nil)
            } catch {
                Logger.shared.error("❌ ChallengeManager.failChallenge: Supabase failed, using local fallback", error: error)
                // Fallback на локальное хранилище
                // @MainActor гарантирует выполнение на главном потоке
                Logger.shared.warning("❌ ChallengeManager.failChallenge: Using local fallback")
                self.failChallengeLocal(userChallenge)
            }
        } else {
            Logger.shared.warning("Invalid challengeId, using local fallback")
            // Fallback на локальное хранилище
            // @MainActor гарантирует выполнение на главном потоке
            self.failChallengeLocal(userChallenge)
        }
        
        Logger.shared.info("=== failChallenge END ===")
    }
    
    /// Локальный провал челленджа (fallback)
    private func failChallengeLocal(_ userChallenge: UserChallenge) {
        Logger.shared.info("=== failChallengeLocal START === userChallengeId: \(userChallenge.id)")
        
        guard let index = userChallenges.firstIndex(where: { $0.id == userChallenge.id }) else {
            Logger.shared.warning("failChallengeLocal: userChallenge not found")
            return
        }
        
        userChallenges[index].isFailed = true
        userChallenges[index].isActive = false
        Logger.shared.info("failChallengeLocal: Set isFailed=true, isActive=false")
        
        // Обновляем статистику челленджа
        if let challenge = availableChallenges.first(where: { $0.id == userChallenge.challengeId }) {
            if let challengeIndex = availableChallenges.firstIndex(where: { $0.id == challenge.id }) {
                availableChallenges[challengeIndex].activeParticipants = max(0, availableChallenges[challengeIndex].activeParticipants - 1)
            }
        }
        
        // Сбрасываем активный челлендж если это он
        if userChallenge.id == activeChallenge?.id {
            activeChallenge = nil
            Logger.shared.info("failChallengeLocal: Cleared activeChallenge")
        }
        
        // ВАЖНО: Кэшируем обновленные данные (НЕ удаляем кэш!)
        cacheManager.cacheUserChallenges(userChallenges)
        cacheManager.cacheChallenges(availableChallenges)
        Logger.shared.info("failChallengeLocal: Cached data")
        
        saveChallenges()
        saveUserChallenges()
        Logger.shared.info("=== failChallengeLocal END ===")
    }
    
    func checkActiveChallenge() {
        // Проверяем, что текущий activeChallenge все еще активен
        if let current = activeChallenge {
            if let updated = userChallenges.first(where: { $0.id == current.id }) {
                if updated.isFailed || updated.isCompleted || !updated.isActive {
                    activeChallenge = nil
                } else {
                    activeChallenge = updated
                }
            } else {
                activeChallenge = nil
            }
        }
        
        // Если activeChallenge == nil — ставим первый активный челлендж, чтобы «Мой прогресс» не был пустым
        if activeChallenge == nil {
            let first = userChallenges.first { uc in
                uc.isActive && !uc.isCompleted && !uc.isFailed
            }
            if let first = first {
                activeChallenge = first
            }
        }
    }
    
    func getChallenge(id: Int64) -> Challenge? {
        // Конвертируем Int64 в String для поиска
        return availableChallenges.first { $0.id == String(id) }
    }
    
    /// Единая проверка участия: challengeId + userId (lowercased). Использовать в Detail и на карточках.
    func participatingUserChallenge(challengeId: String, userId: String?) -> UserChallenge? {
        guard let uid = userId, !uid.isEmpty else { return nil }
        let n = uid.lowercased()
        return userChallenges.first {
            $0.challengeId == challengeId && $0.userId.lowercased() == n
        }
    }
    
    // MARK: - Helper Methods
    private func calculatePayout(for userChallenge: inout UserChallenge, challenge: Challenge) {
        // Простая логика: призовой фонд делится между всеми победителями
        let winners = userChallenges.filter { $0.challengeId == challenge.id && $0.isCompleted }
        if winners.count > 0 {
            userChallenge.payout = challenge.prizePool / Double(winners.count)
        }
    }
    
    private func saveChallenges() {
        // Не сохраняем availableChallenges на диск (только Supabase + memory-cache).
        userDefaults.removeObject(forKey: challengesKey)
    }
    
    
    func getStats(for userId: String) -> ChallengeStats {
        let normalized = userId.lowercased()
        let userChallengesList = userChallenges.filter { $0.userId.lowercased() == normalized }
        let completed = userChallengesList.filter { $0.isCompleted }.count
        let failed = userChallengesList.filter { $0.isFailed }.count
        let earned = userChallengesList.compactMap { $0.payout }.reduce(0, +)
        
        // Рассчитываем реальную сумму потерь из entryFee каждого проваленного челленджа
        let lost = userChallengesList
            .filter { $0.isFailed }
            .compactMap { failedUserChallenge -> Double? in
                // Находим соответствующий челлендж, чтобы получить entryFee
                if let challenge = availableChallenges.first(where: { $0.id == failedUserChallenge.challengeId }) {
                    return challenge.entryFee
                }
                return nil
            }
            .reduce(0, +)
        
        return ChallengeStats(
            totalChallenges: userChallengesList.count,
            completedChallenges: completed,
            failedChallenges: failed,
            totalEarned: earned,
            totalLost: lost
        )
    }
    
    // MARK: - Debug / Reset
    
    /// Очистить все локальные данные и загрузить с сервера
    func clearLocalData() async {
        Logger.shared.warning("=== CLEARING ALL LOCAL DATA ===")
        
        // Очищаем UserDefaults
        userDefaults.removeObject(forKey: challengesKey)
        userDefaults.removeObject(forKey: userChallengesKey)
        
        // Очищаем кэш
        cacheManager.remove("challenges")
        cacheManager.remove("userChallenges")
        
        // Очищаем локальные переменные
        // @MainActor гарантирует выполнение на главном потоке
        self.availableChallenges = []
        self.userChallenges = []
        self.activeChallenge = nil
        
        Logger.shared.info("Local data cleared. Loading data from server...")
        
        // Загружаем данные с сервера
        await syncWithSupabase()
        
        Logger.shared.info("Data reloaded from server")
    }
    
    // MARK: - Honest Streak
    
    /// Обновить честную серию пользователя
    private func updateHonestStreak(userId: String, isHonest: Bool) async throws {
        guard isHonest else {
            // Если действие нечестное - сбрасываем серию
                Logger.shared.info("🔄 ChallengeManager.updateHonestStreak: Resetting streak (dishonest action), userId=\(userId)")
            do {
                // Выполняем сетевой вызов вне MainActor контекста для безопасности
                let newStreak = try await Task.detached { [supabaseManager] in
                    try await supabaseManager.resetHonestStreak(userId: userId)
                }.value
                Logger.shared.info("🔄 ChallengeManager.updateHonestStreak: Streak reset, userId=\(userId), newStreak=\(newStreak)")
                
                // Обновляем данные пользователя с сервера для синхронизации UI
                // UI обновится через getCurrentUser, который используется в других местах
                do {
                    // Выполняем сетевой вызов вне MainActor контекста для безопасности
                    let updatedUser = try await Task.detached { [supabaseManager] in
                        try await supabaseManager.getCurrentUser()
                    }.value
                    
                    if let updatedUser = updatedUser {
                        Logger.shared.info("🔄 ChallengeManager.updateHonestStreak: User data refreshed, newStreak=\(updatedUser.honestStreak)")
                    }
                } catch {
                    Logger.shared.warning("🔄 ChallengeManager.updateHonestStreak: Failed to refresh user data", error: error)
                }
            } catch {
                Logger.shared.error("🔄 ChallengeManager.updateHonestStreak: Failed to reset streak", error: error)
                // Не пробрасываем ошибку, так как это не критично
            }
            return
        }
        
        Logger.shared.info("🔄 ChallengeManager.updateHonestStreak: Incrementing streak (honest action), userId=\(userId)")
        do {
            // Выполняем сетевой вызов вне MainActor контекста для безопасности
            let newStreak = try await Task.detached { [supabaseManager] in
                try await supabaseManager.incrementHonestStreak(userId: userId)
            }.value
            Logger.shared.info("✅ ChallengeManager.updateHonestStreak: Streak incremented, userId=\(userId), newStreak=\(newStreak)")
            
            // Обновляем данные пользователя с сервера для синхронизации UI
                // UI обновится через getCurrentUser, который используется в других местах
                do {
                    // Выполняем сетевой вызов вне MainActor контекста для безопасности
                    let updatedUser = try await Task.detached { [supabaseManager] in
                        try await supabaseManager.getCurrentUser()
                    }.value
                    
                    if let updatedUser = updatedUser {
                    Logger.shared.info("✅ ChallengeManager.updateHonestStreak: User data refreshed, newStreak=\(updatedUser.honestStreak)")
                }
            } catch {
                Logger.shared.warning("✅ ChallengeManager.updateHonestStreak: Failed to refresh user data", error: error)
            }
        } catch {
            Logger.shared.error("🔄 ChallengeManager.updateHonestStreak: Failed to increment streak", error: error)
            // Не пробрасываем ошибку, так как это не критично для основной функциональности
        }
    }
}
