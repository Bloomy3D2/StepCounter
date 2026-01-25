//
//  ActiveChallengeView.swift
//  ChallengeApp
//
//  Активный челлендж (сердце продукта)
//

import SwiftUI
import Combine

struct ActiveChallengeView: View {
    // Опциональный параметр - если передан, показываем его; если нет - ищем активный
    var userChallengeId: String? = nil
    
    @EnvironmentObject var challengeManager: ChallengeManager
    @EnvironmentObject var appState: AppState
    @State private var showingFailureConfirmation = false
    @State private var confirmationCount = 0
    @State private var failedChallengeForSheet: Challenge? = nil
    @State private var victoryChallengeForSheet: Challenge? = nil
    @State private var victoryPayout: Double = 0
    @State private var victoryWinnersCount: Int = 0
    @State private var isProcessing = false
    @State private var isCompletingDay = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: AnyCancellable?
    @Environment(\.dismiss) private var dismiss
    
    // Находим конкретный userChallenge по ID или берем activeChallenge
    private var currentUserChallenge: UserChallenge? {
        if let id = userChallengeId {
            return challengeManager.userChallenges.first { $0.id == id && $0.isActive }
        }
        return challengeManager.activeChallenge
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(.container, edges: [.top])
            
            if let activeChallenge = currentUserChallenge,
               let challenge = challengeManager.availableChallenges.first(where: { $0.id == activeChallenge.challengeId }) {
                let now = Date()
                let isLockedUntilStart = now < challenge.startDate
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Название
                        VStack(spacing: 8) {
                            Text(challenge.title)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text(String(format: "active.day_of".localized, activeChallenge.currentDay, challenge.duration))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 20)
                        
                        // Таймер до конца дня (крупный, заметный)
                        if !activeChallenge.hasCompletedToday {
                            VStack(spacing: 8) {
                                Text(isLockedUntilStart ? "detail.start_in".localized : "active.time_until_end".localized)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text(formatTimeRemaining(timeRemaining))
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .monospacedDigit()
                            }
                            .padding(24)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(20)
                            .padding(.horizontal, 20)
                        }
                        
                        // Если челлендж ещё не начался — показываем подсказку и блокируем действия
                        if isLockedUntilStart {
                            VStack(spacing: 8) {
                                Text("Челлендж ещё не начался")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Отметка выполнения и провал будут доступны после старта.")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(Color.orange.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.orange.opacity(0.35), lineWidth: 1)
                            )
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                        }
                        
                        // Главная кнопка
                        VStack(spacing: 24) {
                            if activeChallenge.hasCompletedToday {
                                VStack(spacing: 16) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(.green)
                                    
                                    Text("active.excellent_tomorrow".localized)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .padding(40)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.green.opacity(0.2))
                                )
                            } else {
                                // Кнопки "Выполнил" и "Провалился" (большие, по центру)
                                VStack(spacing: 16) {
                                    Button(action: {
                                        guard !isCompletingDay else {
                                            Logger.shared.warning("⚠️ ActiveChallengeView: Button already processing, ignoring tap")
                                            return
                                        }
                                        
                                        Logger.shared.info("✅ ActiveChallengeView: User tapped 'Выполнил' - userChallengeId=\(activeChallenge.id), challengeId=\(activeChallenge.challengeId), currentDay=\(activeChallenge.currentDay), hasCompletedToday=\(activeChallenge.hasCompletedToday)")
                                        
                                        Task {
                                            await MainActor.run {
                                                isCompletingDay = true
                                            }
                                            
                                            do {
                                                let manager = challengeManager
                                                await AnalyticsManager.shared.track(
                                                    "complete_day_attempt",
                                                    challengeId: Int64(challenge.id),
                                                    props: [
                                                        "challenge_id": challenge.id,
                                                        "user_challenge_id": activeChallenge.id,
                                                        "day": "\(activeChallenge.currentDay)"
                                                    ]
                                                )
                                                Logger.shared.info("✅ ActiveChallengeView: Calling completeDay - userChallengeId=\(activeChallenge.id)")
                                                try await manager.completeDay(for: activeChallenge)
                                                Logger.shared.info("✅ ActiveChallengeView: Day completed successfully - refreshing user data")
                                                
                                                // Обновляем баланс пользователя после успешного завершения дня
                                                await appState.refreshUser()
                                                
                                                await AnalyticsManager.shared.track(
                                                    "complete_day_success",
                                                    challengeId: Int64(challenge.id),
                                                    props: [
                                                        "challenge_id": challenge.id,
                                                        "user_challenge_id": activeChallenge.id,
                                                        "day": "\(activeChallenge.currentDay)"
                                                    ]
                                                )
                                                
                                                // НЕ перезагружаем user challenges сразу, чтобы не перезаписать локальные изменения
                                                // UI обновится автоматически через @Published userChallenges
                                                Logger.shared.info("✅ ActiveChallengeView: User data refreshed, UI will update automatically")
                                                
                                                stopTimer()
                                                Logger.shared.info("✅ ActiveChallengeView: Timer stopped after day completion")
                                            } catch {
                                                Logger.shared.error("❌ ActiveChallengeView: Error completing day", error: error)
                                                Logger.shared.error("❌ ActiveChallengeView: Error details - userChallengeId=\(activeChallenge.id), challengeId=\(activeChallenge.challengeId), currentDay=\(activeChallenge.currentDay)")
                                                
                                                let appError = ErrorHandler.handle(error)
                                                await AnalyticsManager.shared.track(
                                                    "complete_day_failed",
                                                    challengeId: Int64(challenge.id),
                                                    props: [
                                                        "challenge_id": challenge.id,
                                                        "user_challenge_id": activeChallenge.id,
                                                        "day": "\(activeChallenge.currentDay)",
                                                        "error": appError.errorDescription ?? "unknown"
                                                    ]
                                                )
                                                
                                                await MainActor.run {
                                                    errorMessage = appError.errorDescription ?? "active.error_complete".localized
                                                    if let suggestion = appError.recoverySuggestion {
                                                        errorMessage += "\n\n\(suggestion)"
                                                    }
                                                    showingError = true
                                                    Logger.shared.error("❌ ActiveChallengeView: Error shown to user - message=\(errorMessage)")
                                                }
                                            }
                                            
                                            await MainActor.run {
                                                isCompletingDay = false
                                            }
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                            Text("active.complete".localized)
                                        }
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 64)
                                        .background((isLockedUntilStart || isCompletingDay) ? Color.gray : Color.green)
                                        .cornerRadius(16)
                                    }
                                    .disabled(isLockedUntilStart || isCompletingDay || activeChallenge.hasCompletedToday)
                                    
                                    Button(action: {
                                        Logger.shared.info("❌ ActiveChallengeView: User tapped 'Провалился', userChallengeId=\(activeChallenge.id), currentDay=\(activeChallenge.currentDay)")
                                        showingFailureConfirmation = true
                                    }) {
                                        HStack {
                                            Image(systemName: "xmark.circle.fill")
                                            Text("active.fail".localized)
                                        }
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 64)
                                        .background(isLockedUntilStart ? Color.gray.opacity(0.35) : Color.red.opacity(0.3))
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(isLockedUntilStart ? Color.gray.opacity(0.6) : Color.red, lineWidth: 2)
                                        )
                                    }
                                    .disabled(isLockedUntilStart || isProcessing || isCompletingDay)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Статус
                        VStack(spacing: 16) {
                            HStack {
                                Text("active.remaining_participants".localized)
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text("\(challenge.activeParticipants)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Text("active.completed_today".localized)
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text("\(challenge.completedToday)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            
                            HStack {
                                Text("active.dropped_today".localized)
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text("\(challenge.failedToday)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                        )
                        .padding(.horizontal, 20)
                        
                        .alert("active.confirm_title".localized, isPresented: $showingFailureConfirmation) {
                            Button("active.confirm_cancel".localized, role: .cancel) {
                                confirmationCount = 0
                            }
                            Button("active.confirm_confirm".localized, role: .destructive) {
                                Task {
                                    await handleFailChallenge(activeChallenge: activeChallenge, challenge: challenge)
                                }
                            }
                        } message: {
                            Text("active.confirm_message".localized)
                        }
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("active.no_active".localized)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .navigationTitle("active.progress_title".localized)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            Logger.shared.info("📱 ActiveChallengeView appeared, userChallengeId=\(userChallengeId ?? "nil")")
            // Устанавливаем activeChallenge только если передан конкретный ID
            if let id = userChallengeId,
               let uc = challengeManager.userChallenges.first(where: { $0.id == id && $0.isActive }) {
                challengeManager.activeChallenge = uc
                Logger.shared.info("📱 ActiveChallengeView: Set activeChallenge, challengeId=\(uc.challengeId), currentDay=\(uc.currentDay)")
            } else if let active = currentUserChallenge {
                Logger.shared.info("📱 ActiveChallengeView: Using currentUserChallenge, challengeId=\(active.challengeId), currentDay=\(active.currentDay), hasCompletedToday=\(active.hasCompletedToday)")
            } else {
                Logger.shared.warning("📱 ActiveChallengeView: No active challenge found")
            }
            
            // Запускаем таймер, если есть активный челлендж и день не завершен
            if let uc = currentUserChallenge,
               let ch = challengeManager.availableChallenges.first(where: { $0.id == uc.challengeId }),
               !uc.hasCompletedToday {
                Logger.shared.info("⏱️ ActiveChallengeView: Starting timer, timeRemaining=\(formatTimeRemaining(timeRemaining))")
                startTimer(for: ch)
            } else {
                Logger.shared.info("⏱️ ActiveChallengeView: Timer not started (no active challenge or day completed)")
            }
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: currentUserChallenge?.isCompleted) { _, isCompleted in
            if isCompleted == true, let userChallenge = currentUserChallenge,
               let challenge = challengeManager.availableChallenges.first(where: { $0.id == userChallenge.challengeId }) {
                victoryPayout = userChallenge.payout ?? 0
                let winners = challengeManager.userChallenges.filter { $0.challengeId == challenge.id && $0.isCompleted }
                victoryWinnersCount = winners.count
                victoryChallengeForSheet = challenge
            }
        }
        .fullScreenCover(item: $failedChallengeForSheet, onDismiss: {
            // После закрытия экрана провала - возвращаемся на список челленджей
            dismiss()
        }) { challenge in
            FailureView(challenge: challenge)
        }
        .fullScreenCover(item: $victoryChallengeForSheet, onDismiss: {
            // После закрытия экрана победы - возвращаемся на список челленджей
            dismiss()
        }) { challenge in
            VictoryView(challenge: challenge, payout: victoryPayout, winnersCount: victoryWinnersCount)
        }
        .alert("active.confirm_title".localized, isPresented: $showingFailureConfirmation) {
            Button("active.confirm_cancel".localized, role: .cancel) {
                Logger.shared.info("❌ ActiveChallengeView: User cancelled failure confirmation")
                confirmationCount = 0
            }
            Button("active.confirm_confirm".localized, role: .destructive) {
                if let activeChallenge = currentUserChallenge,
                   let challenge = challengeManager.availableChallenges.first(where: { $0.id == activeChallenge.challengeId }) {
                    Logger.shared.info("❌ ActiveChallengeView: User confirmed failure, userChallengeId=\(activeChallenge.id)")
                    Task {
                        await handleFailChallenge(activeChallenge: activeChallenge, challenge: challenge)
                    }
                } else {
                    Logger.shared.error("❌ ActiveChallengeView: Cannot fail challenge - activeChallenge or challenge not found")
                }
            }
        } message: {
            Text("active.confirm_message".localized)
        }
        .alert("active.error_title".localized, isPresented: $showingError) {
            Button("common.ok".localized, role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleFailChallenge(activeChallenge: UserChallenge, challenge: Challenge) async {
        Logger.shared.info("❌ ActiveChallengeView.handleFailChallenge: Starting, userChallengeId=\(activeChallenge.id), challengeId=\(challenge.id)")
        isProcessing = true
        
        do {
            let manager = challengeManager
            await AnalyticsManager.shared.track(
                "fail_attempt",
                challengeId: Int64(challenge.id),
                props: [
                    "challenge_id": challenge.id,
                    "user_challenge_id": activeChallenge.id,
                    "day": "\(activeChallenge.currentDay)"
                ]
            )
            try await manager.failChallenge(activeChallenge)
            Logger.shared.info("❌ ActiveChallengeView.handleFailChallenge: Challenge failed successfully")
            await AnalyticsManager.shared.track(
                "fail_success",
                challengeId: Int64(challenge.id),
                props: [
                    "challenge_id": challenge.id,
                    "user_challenge_id": activeChallenge.id,
                    "day": "\(activeChallenge.currentDay)"
                ]
            )
            await MainActor.run {
                isProcessing = false
                failedChallengeForSheet = challenge
                stopTimer()
                Logger.shared.info("❌ ActiveChallengeView.handleFailChallenge: Showing FailureView")
            }
        } catch {
            Logger.shared.error("❌ ActiveChallengeView.handleFailChallenge: Failed to fail challenge", error: error)
            await AnalyticsManager.shared.track(
                "fail_failed",
                challengeId: Int64(challenge.id),
                props: [
                    "challenge_id": challenge.id,
                    "user_challenge_id": activeChallenge.id,
                    "day": "\(activeChallenge.currentDay)",
                    "error": error.localizedDescription
                ]
            )
            await MainActor.run {
                isProcessing = false
                errorMessage = "active.error_fail".localized
                showingError = true
            }
        }
    }
    
    // MARK: - Timer Methods
    
    private func formatTimeRemaining(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func updateTimer(for challenge: Challenge) {
        let now = Date()
        
        // До старта показываем countdown до start_date
        if now < challenge.startDate {
            timeRemaining = max(0, challenge.startDate.timeIntervalSince(now))
            return
        }
        
        // После старта показываем время до конца текущих суток (UTC),
        // чтобы совпадать с логикой сервера (CURRENT_DATE в Supabase = UTC).
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else {
            return
        }
        
        let deadline = min(nextDay, challenge.endDate)
        timeRemaining = max(0, deadline.timeIntervalSince(now))
    }
    
    private func startTimer(for challenge: Challenge) {
        updateTimer(for: challenge)
        Logger.shared.debug("⏱️ ActiveChallengeView.startTimer: Timer started, timeRemaining=\(formatTimeRemaining(timeRemaining))")
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                updateTimer(for: challenge)
                if timeRemaining <= 0 {
                    Logger.shared.info("⏱️ ActiveChallengeView: Timer reached zero, stopping")
                    stopTimer()
                }
            }
    }
    
    private func stopTimer() {
        Logger.shared.debug("⏱️ ActiveChallengeView.stopTimer: Timer stopped")
        timer?.cancel()
        timer = nil
    }
}
