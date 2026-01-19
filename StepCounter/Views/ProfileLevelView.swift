//
//  ProfileLevelView.swift
//  StepCounter
//
//  Экран профиля с уровнями и XP
//

import SwiftUI

struct ProfileLevelView: View {
    @EnvironmentObject var levelManager: LevelManager
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var achievementManager: AchievementManager
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var showLevelUpAnimation = false
    @State private var showAchievements = false
    @State private var showInviteFriends = false
    @State private var showRanks = false
    @State private var themeUpdateTrigger = UUID()
    
    private var bgColor: Color { themeManager.backgroundColor }
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Профиль
                    profileCard
                    
                    // Достижения (кликабельный блок)
                    achievementsCard
                    
                    // Пригласить друзей
                    inviteFriendsCard
                    
                    // Звания
                    ranksCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .id(themeManager.currentTheme.id)
                    .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: themeManager.currentTheme.id)
            )
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAchievements) {
                AchievementsView()
            }
            .sheet(isPresented: $showInviteFriends) {
                InviteFriendsView()
            }
            .sheet(isPresented: $showRanks) {
                RanksView()
                    .environmentObject(levelManager)
            }
            .onChange(of: themeManager.currentTheme.id) { oldValue, newValue in
                if oldValue != newValue {
                    themeUpdateTrigger = UUID()
                }
            }
        }
    }
    
    // MARK: - Profile Card
    
    private var profileCard: some View {
        VStack(spacing: 20) {
            // Аватар и уровень
            ZStack {
                // Фоновое кольцо
                Circle()
                    .stroke(cardColor, lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                // Прогресс до следующего уровня
                Circle()
                    .trim(from: 0, to: levelManager.levelProgress)
                    .stroke(
                        LinearGradient(colors: [levelManager.player.rank.color, accentGreen], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                // Эмодзи звания
                VStack(spacing: 4) {
                    Image(systemName: levelManager.player.rank.iconName)
                        .font(.system(size: 40))
                        .foregroundColor(levelManager.player.rank.color)
                    Text("Ур. \(levelManager.player.level)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            
            // Звание и премиум статус
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Text(levelManager.player.rank.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(levelManager.player.rank.color)
                    
                    // Премиум бейдж
                    if subscriptionManager.isPremium {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 12))
                            Text("Premium")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.yellow.opacity(0.3), .orange.opacity(0.2)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                }
                
                Text("\(levelManager.player.totalXP) XP")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Прогресс до следующего уровня
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 10)
                        
                        Capsule()
                            .fill(LinearGradient(colors: [levelManager.player.rank.color, accentGreen], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * levelManager.levelProgress, height: 10)
                    }
                }
                .frame(height: 10)
                
                Text("\(levelManager.xpToNextLevel) XP до уровня \(levelManager.player.level + 1)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 24).fill(cardColor))
    }
    
    // MARK: - Achievements Card
    
    private var achievementsCard: some View {
        Button {
            HapticManager.impact(style: .light)
            showAchievements = true
        } label: {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                    HStack(spacing: 12) {
                        // Иконка достижений
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Достижения")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                            Text("\(achievementManager.unlockedCount) из \(achievementManager.totalCount)")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
            }
                    }
                    
                    Spacer()
                    
                    // Прогресс кольцо
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .trim(from: 0, to: Double(achievementManager.unlockedCount) / Double(achievementManager.totalCount))
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))
                
                        Text("\(Int((Double(achievementManager.unlockedCount) / Double(achievementManager.totalCount)) * 100))%")
                            .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                // Мини-превью последних достижений
                if !achievementManager.unlockedAchievements.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(achievementManager.unlockedAchievements.prefix(5))) { achievement in
                                ZStack {
                                    Circle()
                .fill(
                    LinearGradient(
                                                colors: achievement.type.rarity.frameColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                                        .frame(width: 50, height: 50)
                                    
                                    Circle()
                                        .fill(Color(red: 0.08, green: 0.08, blue: 0.12))
                                        .frame(width: 42, height: 42)
                                    
                                    Image(systemName: achievement.type.medalIcon)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(
                            LinearGradient(
                                                colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
            .padding(20)
            .background(
                GlassCard(cornerRadius: 20, padding: 0) {
                    Color.clear
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Invite Friends Card
    
    private var inviteFriendsCard: some View {
        let referralManager = ReferralManager.shared
        
        return Button {
            HapticManager.impact(style: .light)
            showInviteFriends = true
        } label: {
            GlassCard(cornerRadius: 20, padding: 20, glowColor: Color(hex: "FFD700").opacity(0.3)) {
                HStack(spacing: 16) {
                    // Иконка
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Пригласить друзей")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
                        Text("\(referralManager.referralInfo.completedCount) приглашено • Получи награды!")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Ranks Card
    
    private var ranksCard: some View {
        Button {
            HapticManager.impact(style: .light)
            showRanks = true
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    HStack(spacing: 12) {
                        // Иконка званий
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [levelManager.player.rank.color, levelManager.player.rank.color.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: levelManager.player.rank.iconName)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Звания")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("\(unlockedRanksCount) из \(PlayerRank.allCases.count)")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    Spacer()
                    
                    // Прогресс кольцо
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .trim(from: 0, to: Double(unlockedRanksCount) / Double(PlayerRank.allCases.count))
                            .stroke(
                                LinearGradient(
                                    colors: [levelManager.player.rank.color, levelManager.player.rank.color.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int((Double(unlockedRanksCount) / Double(PlayerRank.allCases.count)) * 100))%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                // Мини-превью званий (горизонтальный скролл, как у достижений)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(PlayerRank.allCases.prefix(5).enumerated()), id: \.element) { index, rank in
                            RankView(
                                rank: rank,
                                isUnlocked: levelManager.player.level >= rank.minLevel,
                                isCurrent: levelManager.player.rank == rank
                            )
                            .cascadeAppear(delay: Double(index) * 0.05)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2) // Дополнительный отступ сверху и снизу
                }
            }
            .padding(20)
            .background(
                GlassCard(cornerRadius: 20, padding: 0) {
                    Color.clear
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var unlockedRanksCount: Int {
        PlayerRank.allCases.filter { levelManager.player.level >= $0.minLevel }.count
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000000 {
            return String(format: "%.1fM", Double(number) / 1000000)
        } else if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000)
        }
        return "\(number)"
    }
}

// MARK: - Quest Row

struct QuestRow: View {
    let quest: DailyQuest
    
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    private var accentGreen: Color { themeManager.accentGreen }
    
    var body: some View {
        HStack(spacing: 12) {
            // Статус
            ZStack {
                Circle()
                    .fill(quest.isCompleted ? accentGreen.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                if quest.isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundColor(accentGreen)
                        .font(.system(size: 16, weight: .bold))
                } else {
                    Text("\(Int(quest.progressPercent * 100))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Премиум корона
                if quest.isPremium {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                        .offset(x: 14, y: -14)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(quest.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(quest.isCompleted ? .white.opacity(0.5) : .white)
                        .strikethrough(quest.isCompleted)
                    
                    // Премиум бейдж
                    if quest.isPremium {
                        if subscriptionManager.isPremium {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Прогресс бар
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(quest.isCompleted ? accentGreen : (quest.isPremium && !subscriptionManager.isPremium ? Color.gray.opacity(0.5) : .orange))
                            .frame(width: geo.size.width * quest.progressPercent, height: 4)
                    }
                }
                .frame(height: 4)
            }
            
            Spacer()
            
            // Награда
            VStack(spacing: 2) {
                Text("+\(quest.xpReward)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(quest.isCompleted ? accentGreen : .yellow)
                Text("XP")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03)))
        .opacity(quest.isPremium && !subscriptionManager.isPremium ? 0.6 : 1.0)
    }
}

// MARK: - All Time Stat Card

struct AllTimeStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    @StateObject private var themeManager = ThemeManager.shared
    
    private var cardColor: Color { themeManager.cardColor }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 12).fill(cardColor))
    }
}

// MARK: - Premium Feature Row

struct PremiumFeatureRow: View {
    let feature: PremiumFeature
    
    @StateObject private var themeManager = ThemeManager.shared
    
    private var cardColor: Color { themeManager.cardColor }
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: feature.icon)
                .font(.system(size: 16))
                .foregroundColor(.yellow)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(feature.description)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(cardColor.opacity(0.6))
        )
    }
}

// MARK: - Rank View (в стиле медалей достижений)

struct RankView: View {
    let rank: PlayerRank
    let isUnlocked: Bool
    let isCurrent: Bool
    
    @State private var rotationAngle: Double = 0
    @State private var rotationY: Double = 0
    @State private var rotationX: Double = 0
    @State private var isPressed = false
    @State private var glowIntensity: Double = 0.5
    
    var body: some View {
        ZStack {
            // Внешняя рамка (как у достижений - 50x50)
            Circle()
                .fill(
                    LinearGradient(
                        colors: isUnlocked
                            ? [rank.color, rank.color.opacity(0.7), rank.color.opacity(0.5)]
                            : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    // Металлический блик сверху
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(isUnlocked ? 0.6 : 0.1), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .frame(width: 36, height: 18)
                        .offset(y: -18)
                )
                .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                .shadow(color: isUnlocked ? rank.color.opacity(0.3) : .clear, radius: 8, x: 0, y: 0)
            
            // Внутренний круг (как у достижений - 42x42)
            Circle()
                .fill(
                    isUnlocked
                        ? Color(red: 0.08, green: 0.08, blue: 0.12)
                        : Color.gray.opacity(0.2)
                )
                .frame(width: 42, height: 42)
            
            // Иконка звания (как у достижений - размер 18, с ограничением размера)
            if isUnlocked {
                Image(systemName: rank.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [rank.color, rank.color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)
                    .clipped()
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(width: 38, height: 38)
                    .clipped()
            }
            
            // Индикатор текущего звания (внутри границ)
            if isCurrent {
                Circle()
                    .stroke(rank.color, lineWidth: 2)
                    .frame(width: 50, height: 50)
            }
        }
        .frame(width: 50, height: 50)
        .clipShape(Circle())
    }
}

#Preview {
    ProfileLevelView()
        .environmentObject(LevelManager())
        .environmentObject(HealthManager())
}
