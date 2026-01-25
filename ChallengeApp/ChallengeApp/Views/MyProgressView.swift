//
//  MyProgressView.swift
//  ChallengeApp
//
//  Мой прогресс
//

import SwiftUI

struct MyProgressView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var challengeManager: ChallengeManager
    @State private var displayedCount = 5 // Начинаем с 5 челленджей
    @State private var didTrackView = false
    private let initialCount = 5
    private let loadMoreCount = 10 // По 10 при каждом нажатии
    
    var stats: ChallengeStats {
        guard let userId = appState.currentUser?.id else {
            return ChallengeStats(totalChallenges: 0, completedChallenges: 0, failedChallenges: 0, totalEarned: 0, totalLost: 0)
        }
        return challengeManager.getStats(for: userId)
    }
    
    var filteredUserChallenges: [UserChallenge] {
        guard let userId = appState.currentUser?.id else {
            Logger.shared.warning("MyProgressView: No current user ID")
            return []
        }
        
        // Нормализуем UUID для сравнения (убираем дефисы и приводим к нижнему регистру)
        let normalizedUserId = userId.lowercased().replacingOccurrences(of: "-", with: "")
        
        let filtered = challengeManager.userChallenges.filter { uc in
            let normalizedUcUserId = uc.userId.lowercased().replacingOccurrences(of: "-", with: "")
            return normalizedUcUserId == normalizedUserId || uc.userId == userId
        }
        
        // Логируем проваленные челленджи для диагностики
        let failedChallenges = filtered.filter { $0.isFailed }
        if !failedChallenges.isEmpty {
            Logger.shared.info("📊 MyProgressView: Found \(failedChallenges.count) failed challenges out of \(filtered.count) total")
            for uc in failedChallenges {
                Logger.shared.info("  - Failed: id=\(uc.id), challengeId=\(uc.challengeId), isActive=\(uc.isActive), isCompleted=\(uc.isCompleted), isFailed=\(uc.isFailed)")
            }
        }
        
        // Логируем только при аномалиях (пустой список при наличии данных)
        if filtered.isEmpty && !challengeManager.userChallenges.isEmpty {
            Logger.shared.warning("MyProgressView: No matching user challenges - userId: \(userId), total: \(challengeManager.userChallenges.count)")
            for uc in challengeManager.userChallenges {
                Logger.shared.warning("MyProgressView: uc id=\(uc.id), challengeId=\(uc.challengeId), userId=\(uc.userId)")
            }
        }
        
        // Сортируем по дате входа (последние первыми)
        return filtered.sorted { uc1, uc2 in
            uc1.entryDate > uc2.entryDate
        }
    }
    
    // Отображаемые челленджи (с учетом пагинации)
    var displayedChallenges: [UserChallenge] {
        Array(filteredUserChallenges.prefix(displayedCount))
    }
    
    // Есть ли еще челленджи для загрузки
    var hasMoreChallenges: Bool {
        filteredUserChallenges.count > displayedCount
    }
    
    // Количество оставшихся челленджей
    var remainingCount: Int {
        max(0, filteredUserChallenges.count - displayedCount)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea(.container, edges: [.top])
                
                if challengeManager.isLoading && filteredUserChallenges.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Общая статистика
                            VStack(spacing: 16) {
                                Text("stats.total_stats".localized)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack(spacing: 16) {
                                    StatCard(title: "stats.participations".localized, value: "\(stats.totalChallenges)", icon: "person.fill")
                                    StatCard(title: "stats.wins".localized, value: "\(stats.completedChallenges)", icon: "checkmark.circle.fill")
                                }
                                
                                HStack(spacing: 16) {
                                    StatCard(title: "stats.failures".localized, value: "\(stats.failedChallenges)", icon: "xmark.circle.fill", color: .red)
                                    StatCard(title: "stats.earned".localized, value: String(format: "%.0f ₽", stats.totalEarned), icon: "arrow.up.circle.fill", color: .green)
                                }
                                
                                if stats.totalLost > 0 {
                                    StatCard(title: "stats.lost".localized, value: String(format: "%.0f ₽", stats.totalLost), icon: "arrow.down.circle.fill", color: .red)
                                }
                                
                                if stats.totalChallenges > 0 {
                                    VStack(spacing: 8) {
                                        Text("stats.win_rate".localized)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                        
                                        Text(String(format: "%.1f%%", stats.winRate))
                                            .font(.system(size: 32, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.1))
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Список челленджей пользователя
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("stats.my_challenges".localized)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text("\(filteredUserChallenges.count)")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.2))
                                        )
                                }
                                .padding(.horizontal, 20)
                                
                                if filteredUserChallenges.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "trophy")
                                            .font(.system(size: 48))
                                            .foregroundColor(.white.opacity(0.3))
                                        
                                        Text("stats.no_challenges".localized)
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                } else {
                                    // Отображаем только первые displayedCount челленджей
                                    ForEach(displayedChallenges) { userChallenge in
                                        if let challenge = challengeManager.availableChallenges.first(where: { $0.id == userChallenge.challengeId }) {
                                            ChallengeHistoryRow(userChallenge: userChallenge, challenge: challenge)
                                                .padding(.horizontal, 20)
                                        } else {
                                            ChallengeHistoryRowFallback(userChallenge: userChallenge)
                                                .padding(.horizontal, 20)
                                        }
                                    }
                                    
                                    // Кнопка "Посмотреть еще" если есть еще челленджи
                                    if hasMoreChallenges {
                                        Button(action: {
                                            withAnimation {
                                                displayedCount += loadMoreCount
                                            }
                                        }) {
                                            HStack {
                                                Text("progress.load_more".localized)
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.white)
                                                
                                                if remainingCount > 0 {
                                                    Text("(\(remainingCount))")
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(.white.opacity(0.7))
                                                }
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.white.opacity(0.1))
                                            )
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.top, 8)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 20) // Отступ снизу, чтобы контент не перекрывался tab bar
                    }
                    .refreshable {
                        // При pull-to-refresh принудительно обновляем данные
                        let manager = challengeManager
                        await manager.loadUserChallengesFromSupabase(forceRefresh: true)
                        await manager.loadChallengesFromSupabase(forceRefresh: true)
                    }
                }
            }
            .navigationTitle("progress.title".localized)
            .navigationBarTitleDisplayMode(.large)
            .task {
                // Небольшая задержка, чтобы дать время локальным изменениям примениться
                // (например, после нажатия "Выполнил" в ActiveChallengeView)
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 секунды
                
                // Загружаем данные при открытии экрана (используем кэш, если данные свежие)
                // НЕ используем forceRefresh, чтобы не перезаписывать локальные изменения
                Logger.shared.info("MyProgressView: Loading data on appear (using cache if available)")
                let manager = challengeManager
                await manager.loadUserChallengesFromSupabase(forceRefresh: false)
                await manager.loadChallengesFromSupabase(forceRefresh: false)
            }
            .onAppear {
                Logger.shared.info("MyProgressView: onAppear - userChallenges count: \(challengeManager.userChallenges.count), currentUser: \(appState.currentUser?.id ?? "nil")")
                if !didTrackView {
                    didTrackView = true
                    Task {
                        await AnalyticsManager.shared.track(
                            "view_history",
                            props: ["user_challenges_count": "\(filteredUserChallenges.count)"]
                        )
                    }
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .white
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

/// Строка в «Мой прогресс», когда челлендж не найден в availableChallenges
struct ChallengeHistoryRowFallback: View {
    let userChallenge: UserChallenge
    
    var body: some View {
        HStack {
            Image(systemName: "flag.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "stats.challenge_number".localized, userChallenge.challengeId))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                if userChallenge.isActive && !userChallenge.isCompleted && !userChallenge.isFailed {
                    Text("\("stats.day".localized) \(userChallenge.currentDay)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue.opacity(0.8))
                }
            }
            
            Spacer()
            
            if userChallenge.isCompleted {
                VStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)
                    Text("stats.victory".localized)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.yellow)
                }
            } else if userChallenge.isFailed {
                VStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                    Text("stats.failure".localized)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.red)
                }
            } else if userChallenge.isActive {
                VStack(spacing: 4) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    Text("stats.active".localized)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct ChallengeHistoryRow: View {
    let userChallenge: UserChallenge
    let challenge: Challenge
    
    var body: some View {
        HStack {
            Image(systemName: challenge.icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(challenge.subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                // Показываем прогресс для активных
                if userChallenge.isActive && !userChallenge.isCompleted && !userChallenge.isFailed {
                    Text(String(format: "progress.day_of".localized, userChallenge.currentDay, challenge.duration))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue.opacity(0.8))
                }
            }
            
            Spacer()
            
            // Статус
            if userChallenge.isCompleted {
                VStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)
                    Text("stats.victory".localized)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.yellow)
                }
            } else if userChallenge.isFailed {
                VStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                    Text("stats.failure".localized)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.red)
                    // Показываем сумму потерь
                    Text(String(format: "-%.0f ₽", challenge.entryFee))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)
                }
            } else if userChallenge.isActive {
                VStack(spacing: 4) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    Text("stats.active".localized)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}
