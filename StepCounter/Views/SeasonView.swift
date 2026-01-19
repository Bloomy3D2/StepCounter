//
//  SeasonView.swift
//  StepCounter
//
//  Экран сезонов с наградами и прогрессом
//

import SwiftUI

struct SeasonView: View {
    @StateObject private var seasonManager = SeasonManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var showingRewards = false
    
    private var bgColor: Color { themeManager.backgroundColor }
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let season = seasonManager.currentSeason {
                        // Заголовок сезона
                        seasonHeader(season)
                        
                        // Прогресс сезона
                        seasonProgress(season)
                        
                        // Награды
                        seasonRewards(season)
                        
                        // Лидерборд
                        seasonLeaderboard(season)
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .ignoresSafeArea()
            )
            .navigationTitle("Сезоны")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Season Header
    
    private func seasonHeader(_ season: Season) -> some View {
        VStack(spacing: 16) {
            // Иконка сезона
            Text(season.theme.icon)
                .font(.system(size: 80))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // Название
            Text(season.name)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            // Дни осталось
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundColor(accentGreen)
                Text("Осталось \(season.daysRemaining) дней")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(cardColor.opacity(0.3))
            .clipShape(Capsule())
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardColor.opacity(0.2))
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: season.theme.colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(0.3)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(LinearGradient(
                    colors: season.theme.colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ), lineWidth: 2)
        )
    }
    
    // MARK: - Season Progress
    
    private func seasonProgress(_ season: Season) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Ваш прогресс")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("Уровень \(seasonManager.userSeasonLevel)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(accentGreen)
            }
            
            // Прогресс-бар
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 20)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: season.theme.colors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(season.progress), height: 20)
                        .animation(.spring(response: 0.6), value: season.progress)
                }
            }
            .frame(height: 20)
            
            HStack {
                Text("\(seasonManager.userSeasonXP) XP")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("Следующий уровень: \(nextLevelXP()) XP")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(20)
        .background(cardColor.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private func nextLevelXP() -> Int {
        let currentLevel = seasonManager.userSeasonLevel
        return currentLevel * 1000
    }
    
    // MARK: - Season Rewards
    
    private func seasonRewards(_ season: Season) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Награды сезона")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(season.rewards) { reward in
                        rewardCard(reward, seasonTheme: season.theme)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private func rewardCard(_ reward: SeasonReward, seasonTheme: SeasonTheme) -> some View {
        VStack(spacing: 12) {
            // Уровень
            Text("\(reward.level)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: seasonTheme.colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            
            // Иконка награды
            Image(systemName: rewardIcon(for: reward.rewardType))
                .font(.system(size: 32))
                .foregroundColor(reward.isUnlocked ? accentGreen : .white.opacity(0.5))
            
            // Название
            Text(reward.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Описание
            Text(reward.description)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(16)
        .frame(width: 140)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(reward.isUnlocked ? cardColor.opacity(0.4) : cardColor.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(reward.isUnlocked ? accentGreen : Color.white.opacity(0.2), lineWidth: 2)
                )
        )
        .opacity(reward.isUnlocked ? 1.0 : 0.7)
    }
    
    private func rewardIcon(for type: SeasonReward.SeasonRewardType) -> String {
        switch type {
        case .xp: return "star.fill"
        case .premiumDays: return "crown.fill"
        case .theme: return "paintbrush.fill"
        case .petAccessory: return "sparkles"
        case .achievement: return "trophy.fill"
        }
    }
    
    // MARK: - Season Leaderboard
    
    private func seasonLeaderboard(_ season: Season) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Лидеры сезона")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            if season.leaderboard.entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.5))
                    Text("Пока нет лидеров")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(cardColor.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(season.leaderboard.topEntries.enumerated()), id: \.element.id) { index, entry in
                        leaderboardRow(entry, rank: index + 1)
                    }
                }
                .padding(16)
                .background(cardColor.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
    }
    
    private func leaderboardRow(_ entry: SeasonLeaderboardEntry, rank: Int) -> some View {
        HStack(spacing: 12) {
            // Ранг
            Text("\(rank)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(rank <= 3 ? accentGreen : .white.opacity(0.8))
                .frame(width: 30)
            
            // Аватар
            Circle()
                .fill(LinearGradient(
                    colors: [accentGreen, accentGreen.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(entry.userName.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            // Имя
            Text(entry.userName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            // Шаги
            HStack(spacing: 4) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 14))
                Text("\(entry.totalSteps)")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(accentGreen)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.5))
            Text("Сезон скоро начнётся")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            Text("Следите за обновлениями")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}
