//
//  ChallengesListView.swift
//  ChallengeApp
//
//  Главный экран - лента челленджей
//

import SwiftUI

struct ChallengesListView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var challengeManager: ChallengeManager
    @State private var showingProfile = false
    @State private var tick = Date()
    @State private var didTrackView = false
    
    // Получаем активные челленджи пользователя (сравнение userId без учёта регистра)
    private var activeUserChallenges: [UserChallenge] {
        guard let userId = appState.currentUser?.id else {
            Logger.shared.debug("🔍 ChallengesListView.activeUserChallenges: No user ID - returning empty array")
            return []
        }
        let n = userId.lowercased()
        let active = challengeManager.userChallenges.filter {
            $0.userId.lowercased() == n && $0.isActive && !$0.isCompleted && !$0.isFailed
        }
        
        Logger.shared.debug("🔍 ChallengesListView.activeUserChallenges: userId=\(userId), totalUserChallenges=\(challengeManager.userChallenges.count), activeCount=\(active.count)")
        
        return active
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea(.container, edges: [.top])
                
                if challengeManager.isLoading && challengeManager.availableChallenges.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else {
                    // Всегда показываем список всех доступных челленджей
                    // Статус участия отображается на карточке каждого челленджа
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(challengeManager.availableChallenges) { challenge in
                                ChallengeCardWrapper(
                                    challenge: challenge,
                                    challengeManager: challengeManager,
                                    currentUserId: appState.currentUser?.id
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    .onAppear {
                        Logger.shared.debug("📱 ChallengesListView: Showing challenges list - activeCount=\(activeUserChallenges.count), availableCount=\(challengeManager.availableChallenges.count)")
                        if !didTrackView {
                            didTrackView = true
                            let availableCount = challengeManager.availableChallenges.count
                            Task {
                                await AnalyticsManager.shared.track(
                                    "view_challenges_list",
                                    props: [
                                        "available_count": "\(availableCount)",
                                        "active_count": "\(activeUserChallenges.count)"
                                    ]
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("nav.active_challenges".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    AvatarCircleButton(
                        avatarURLString: appState.currentUser?.avatarUrl,
                        size: 32
                    ) {
                        showingProfile = true
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
                    .environmentObject(appState)
                    .environmentObject(challengeManager)
            }
            .task {
                // Загружаем данные при появлении (без forceRefresh, чтобы не перезаписать локальные изменения)
                Logger.shared.info("📱 ChallengesListView: onAppear - loading data")
                if let userId = appState.currentUser?.id {
                    Logger.shared.info("📱 ChallengesListView: User authenticated - userId=\(userId), loading challenges")
                    let manager = challengeManager
                    await manager.loadChallengesFromSupabase(forceRefresh: false)
                    Logger.shared.info("📱 ChallengesListView: Challenges loaded - count=\(manager.availableChallenges.count)")
                    await manager.loadUserChallengesFromSupabase(forceRefresh: false)
                    Logger.shared.info("📱 ChallengesListView: User challenges loaded - count=\(manager.userChallenges.count), activeCount=\(activeUserChallenges.count)")
                } else {
                    Logger.shared.warning("⚠️ ChallengesListView: No user authenticated - skipping data load")
                }
            }
            .refreshable {
                if appState.currentUser != nil {
                    let manager = challengeManager
                    await manager.loadChallengesFromSupabase(forceRefresh: true)
                    await manager.loadUserChallengesFromSupabase(forceRefresh: true)
                }
            }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                tick = Date()
            }
        }
    }
}

// MARK: - Challenge Card
struct ChallengeCard: View {
    let challenge: Challenge
    let challengeManager: ChallengeManager
    let currentUserId: String?
    @State private var tick: Date = Date()
    
    private var userChallenge: UserChallenge? {
        challengeManager.participatingUserChallenge(challengeId: challenge.id, userId: currentUserId)
    }
    
    private var isParticipating: Bool {
        guard let uc = userChallenge else { return false }
        return uc.isActive && !uc.isCompleted && !uc.isFailed
    }
    
    private var shouldShowCountdown: Bool {
        challenge.startDate > tick
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            infoRowView
            if shouldShowCountdown {
                countdownView
            }
            statusButtonView
        }
        .padding(20)
        .background(cardBackground)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            tick = Date()
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Image(systemName: challenge.icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(challenge.subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
    }
    
    private var infoRowView: some View {
        HStack(spacing: 20) {
            Label("\(challenge.participants)", systemImage: "person.2.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Label(challenge.formattedEntryFee, systemImage: "rublesign.circle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    private var countdownView: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.orange)
            
            Text("detail.start_in".localized)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            
            Text(challenge.formattedTimeUntilStart)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.orange)
                .monospacedDigit()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private var statusButtonView: some View {
        HStack {
            Spacer()
            if let userChallenge = userChallenge {
                statusView(for: userChallenge)
            } else {
                joinButton
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    private func statusView(for userChallenge: UserChallenge) -> some View {
        if userChallenge.isActive && !userChallenge.isCompleted && !userChallenge.isFailed {
            activeStatusView
        } else if userChallenge.isCompleted {
            completedStatusView
        } else if userChallenge.isFailed {
            failedStatusView
        } else {
            joinButton
        }
    }
    
    private var activeStatusView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("challenge.you_participate".localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.green.opacity(0.2))
        .clipShape(Capsule())
    }
    
    private var completedStatusView: some View {
        HStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .foregroundColor(.yellow)
            Text("challenge.completed".localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.yellow.opacity(0.2))
        .clipShape(Capsule())
    }
    
    private var failedStatusView: some View {
        HStack(spacing: 8) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
            Text("challenge.failed".localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.red.opacity(0.2))
        .clipShape(Capsule())
    }
    
    private var joinButton: some View {
        Text(String(format: "challenge.join".localized, challenge.formattedEntryFee))
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.black)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.white)
            .clipShape(Capsule())
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Challenge Card Wrapper

private struct ChallengeCardWrapper: View {
    let challenge: Challenge
    let challengeManager: ChallengeManager
    let currentUserId: String?
    
    private var userChallenge: UserChallenge? {
        challengeManager.participatingUserChallenge(challengeId: challenge.id, userId: currentUserId)
    }
    
    var body: some View {
        // Открываем ActiveChallengeView только для активных (не проваленных и не завершенных) челленджей
        if let uc = userChallenge, uc.isActive && !uc.isCompleted && !uc.isFailed {
            NavigationLink(destination: ActiveChallengeView(userChallengeId: uc.id)) {
                ChallengeCard(
                    challenge: challenge,
                    challengeManager: challengeManager,
                    currentUserId: currentUserId
                )
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            // Для всех остальных случаев (не участвует, провален, завершен) открываем детали
            NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                ChallengeCard(
                    challenge: challenge,
                    challengeManager: challengeManager,
                    currentUserId: currentUserId
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}
