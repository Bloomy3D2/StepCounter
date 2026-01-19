//
//  HomeView.swift
//  StepCounter
//
//  Главный экран "Сегодня" с шагами, статистикой и квестами
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var achievementManager: AchievementManager
    @EnvironmentObject var levelManager: LevelManager
    @EnvironmentObject var petManager: PetManager
    @EnvironmentObject var tournamentManager: TournamentManager
    @EnvironmentObject var locationManager: LocationManager
    
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var consentManager = PrivacyConsentManager.shared
    @State private var showPremium = false
    @State private var showConfetti = false
    @State private var showProfile = false
    @State private var showThemeSettings = false
    @State private var showGoalSettings = false
    @State private var showSettings = false
    @State private var showTournamentDetail = false
    @State private var showDistanceDetail = false
    @State private var showCaloriesDetail = false
    @State private var showActivityDetail = false
    @State private var showAverageDetail = false
    
    @Binding var selectedTab: MainTabView.TabSelection
    
    private var bgColor: Color { themeManager.backgroundColor }
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.currentTheme.accentColors.primaryColor }
    private var accentBlue: Color { themeManager.currentTheme.accentColors.secondaryColor }
    private var accentOrange: Color { themeManager.currentTheme.accentColors.tertiaryColor }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Предупреждение об ограниченном режиме
                    if !consentManager.hasConsent {
                        limitedModeBanner
                    }
                    
                    // Уровень и XP (кликабельная для перехода в профиль)
                    Button {
                        HapticManager.impact(style: .light)
                        showProfile = true
                    } label: {
                        levelBanner
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityButton(
                        label: "Уровень \(levelManager.player.level), \(levelManager.player.rank.name)",
                        hint: "Открывает профиль с детальной информацией"
                    )
                    
                    // Питомец мини
                    if let pet = petManager.pet {
                        PetMiniBanner(
                            pet: pet,
                            accentGreen: accentGreen,
                            accentBlue: accentBlue,
                            onTap: {
                                selectedTab = .pet
                            }
                        )
                    }
                    
                    // Серия дней
                    if achievementManager.currentStreak > 0 {
                        streakBanner
                    }
                    
                    // Круговой прогресс - центрируем
                    HStack {
                        Spacer()
                        progressCircle
                        Spacer()
                    }
                    
                    // Статистика дня
                    todayStats
                    
                    // Ежедневные квесты
                    dailyQuestsPreview
                    
                    // Еженедельный турнир
                    if let tournament = tournamentManager.currentTournament {
                        tournamentBanner(tournament)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 80)
            }
            .background(
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .ignoresSafeArea()
            )
            .navigationTitle("Сегодня")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    profileAvatarMenu
                }
            }
            .refreshable {
                HapticManager.selection()
                healthManager.fetchAllData()
            }
            .sheet(isPresented: $showPremium) {
                PremiumView()
            }
            .sheet(isPresented: $showProfile) {
                ProfileLevelView()
            }
            .sheet(isPresented: $showThemeSettings) {
                ThemeSettingsView()
            }
            .sheet(isPresented: $showGoalSettings) {
                GoalSettingsView()
                    .environmentObject(healthManager)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(healthManager)
                    .environmentObject(locationManager)
                    .environmentObject(petManager)
            }
            .sheet(isPresented: $showDistanceDetail) {
                DistanceDetailView(healthManager: healthManager, accentBlue: accentBlue)
            }
            .sheet(isPresented: $showCaloriesDetail) {
                CaloriesDetailView(healthManager: healthManager, accentOrange: accentOrange)
            }
            .sheet(isPresented: $showActivityDetail) {
                ActivityDetailView(healthManager: healthManager, accentGreen: accentGreen)
            }
            .sheet(isPresented: $showAverageDetail) {
                AverageDetailView(healthManager: healthManager, accentPurple: Color.purple)
            }
            .sheet(isPresented: $showTournamentDetail) {
                if let tournament = tournamentManager.currentTournament {
                    TournamentDetailView(tournament: tournament)
                        .environmentObject(tournamentManager)
                        .environmentObject(healthManager)
                        .environmentObject(levelManager)
                }
            }
            .confetti(isPresented: $showConfetti)
            .onChange(of: healthManager.isGoalReached) { _, reached in
                if reached {
                    showConfetti = true
                    HapticManager.notification(.success)
                    
                    // Автоматически скрываем через 2.5 секунды
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        showConfetti = false
                    }
                }
            }
        }
    } // body
    
    // MARK: - Settings Button
    
    private var profileAvatarMenu: some View {
        Button {
            HapticManager.impact(style: .light)
            showSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private var limitedModeBanner: some View {
        Button {
            showSettings = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ограниченный режим")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Некоторые функции недоступны. Дайте согласие в настройках")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var levelBanner: some View {
        GlassCard(cornerRadius: 16, padding: 16) {
            HStack(spacing: 12) {
                // Кружок с аватаром профиля (кликабельный для перехода в профиль)
                Button {
                    HapticManager.impact(style: .light)
                    showProfile = true
                } label: {
                ZStack {
                        // Фоновое кольцо с градиентом
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [levelManager.player.rank.color, accentGreen],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 60, height: 60)
                        
                        // Прогресс кольцо
                        Circle()
                            .trim(from: 0, to: levelManager.levelProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [levelManager.player.rank.color, accentGreen],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        // Внутренний круг с аватаром
                    Circle()
                            .fill(
                                LinearGradient(
                                    colors: [levelManager.player.rank.color.opacity(0.3), accentGreen.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 54, height: 54)
                    
                        // Иконка профиля
                    Image(systemName: levelManager.player.rank.iconName)
                            .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(levelManager.player.rank.color)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Информация об уровне
                VStack(alignment: .leading, spacing: 4) {
                    Text("Уровень \(levelManager.player.level)")
                        .font(.appTitle)
                        .foregroundColor(.white)
                    
                    Text(levelManager.player.rank.name)
                        .font(.appCaption)
                        .foregroundColor(levelManager.player.rank.color)
                    
                    // Прогресс бар
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 6)
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [levelManager.player.rank.color, levelManager.player.rank.color.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * levelManager.levelProgress, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                
                Spacer()
                
                // XP и стрелка
                VStack(alignment: .trailing, spacing: 4) {
                Text("\(levelManager.player.totalXP) XP")
                    .font(.appSmallCaption)
                    .foregroundColor(.white.opacity(0.6))
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
    }
    
    
    private var streakBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.system(size: 28))
                .foregroundColor(.orange)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(achievementManager.currentStreak) дней подряд!")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text("Отличная серия, продолжайте!")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            LinearGradient(colors: [.orange.opacity(0.3), .red.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Серия дней")
        .accessibilityValue("\(achievementManager.currentStreak) дней подряд")
        .accessibilityHint("Отличная серия, продолжайте")
    }
    
    private var progressCircle: some View {
        Button {
            HapticManager.impact(style: .light)
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = .stats
            }
        } label: {
            ZStack {
                // Glassmorphism прогресс-кольцо
                GlassProgressRing(
                    progress: healthManager.goalProgress,
                    lineWidth: 20,
                    colors: [accentGreen, accentBlue],
                    glowColor: accentGreen
                )
                .frame(width: 220, height: 220)
                
                VStack(spacing: 10) {
                    // Иконка
                    Image(systemName: healthManager.isGoalReached ? "checkmark.circle.fill" : "figure.walk")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(healthManager.isGoalReached ? accentGreen : .white.opacity(0.6))
                        .frame(height: 32)
                    
                    // Анимированное число с крупной типографикой
                    AnimatedNumber(
                        value: healthManager.todaySteps,
                        font: .appLargeNumber,
                        color: .white
                    )
                    .frame(height: 50)
                    .multilineTextAlignment(.center)
                    
                    // Цель
                    if healthManager.stepGoal > 0 {
                        Text("из \(healthManager.stepGoal)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(height: 18)
                    } else {
                        Text("шагов")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(height: 18)
                    }
                    
                    // Статус цели
                    if healthManager.isGoalReached {
                        Text("🎉 Цель достигнута!")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(accentGreen)
                            .frame(height: 16)
                    } else if healthManager.stepGoal > 0 {
                        Text("Осталось \(healthManager.remainingSteps)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(accentOrange)
                            .frame(height: 16)
                    }
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            }
            .frame(width: 220, height: 220)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Прогресс шагов")
        .accessibilityValue("\(healthManager.todaySteps) из \(healthManager.stepGoal) шагов")
        .accessibilityHint("Нажмите для открытия детальной статистики")
        .accessibilityAddTraits(.updatesFrequently)
    }
    
    private var todayStats: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            // Дистанция
            Button {
                HapticManager.impact(style: .light)
                if subscriptionManager.isPremium {
                    showDistanceDetail = true
                } else {
                    showPremium = true
                }
            } label: {
                GlassStatCard(
                    icon: "figure.walk",
                    value: String(format: "%.1f км", healthManager.todayDistance / 1000),
                    label: "Дистанция",
                    color: accentBlue,
                    isLocked: !subscriptionManager.isPremium
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Калории
            Button {
                HapticManager.impact(style: .light)
                if subscriptionManager.isPremium {
                    showCaloriesDetail = true
                } else {
                    showPremium = true
                }
            } label: {
                GlassStatCard(
                    icon: "flame.fill",
                    value: "\(Int(healthManager.todayCalories))",
                    label: "Калории",
                    color: accentOrange,
                    isLocked: !subscriptionManager.isPremium
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Активность
            Button {
                HapticManager.impact(style: .light)
                if subscriptionManager.isPremium {
                    showActivityDetail = true
                } else {
                    showPremium = true
                }
            } label: {
                GlassStatCard(
                    icon: "clock.fill",
                    value: "\(healthManager.todayActiveMinutes) мин",
                    label: "Активность",
                    color: accentGreen,
                    isLocked: !subscriptionManager.isPremium
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Среднее/день
            Button {
                HapticManager.impact(style: .light)
                if subscriptionManager.isPremium {
                    showAverageDetail = true
                } else {
                    showPremium = true
                }
            } label: {
                GlassStatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    value: "\(healthManager.weeklyAverage)",
                    label: "Среднее/день",
                    color: .purple,
                    isLocked: !subscriptionManager.isPremium
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var dailyQuestsPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ежедневные квесты")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .accessibilityHeader("Ежедневные квесты")
                
                Spacer()
                
                Text("\(levelManager.completedQuestsToday)/\(levelManager.totalQuestsToday)")
                    .font(.system(size: 12))
                    .foregroundColor(accentGreen)
                    .accessibilityLabel("Выполнено \(levelManager.completedQuestsToday) из \(levelManager.totalQuestsToday) квестов")
            }
            
            ForEach(levelManager.dailyQuests) { quest in
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        // Статус и премиум индикатор
                        ZStack {
                            Image(systemName: quest.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(quest.isCompleted ? accentGreen : .gray)
                                .accessibilityHidden(true)
                            
                            // Премиум корона
                            if quest.isPremium {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.yellow)
                                    .offset(x: 8, y: -8)
                                    .accessibilityHidden(true)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(quest.title)
                                    .font(.system(size: 13))
                                    .foregroundColor(quest.isCompleted ? .white.opacity(0.5) : .white)
                                    .strikethrough(quest.isCompleted)
                                
                                // Премиум бейдж
                                if quest.isPremium {
                                    if subscriptionManager.isPremium {
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.yellow)
                                            .accessibilityHidden(true)
                                    } else {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                            .accessibilityHidden(true)
                                    }
                                }
                            }
                            
                            // Прогресс бар
                            if !quest.isCompleted {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 3)
                                        
                                        Capsule()
                                            .fill(quest.isPremium && !subscriptionManager.isPremium ? Color.gray.opacity(0.5) : accentGreen)
                                            .frame(width: geo.size.width * quest.progressPercent, height: 3)
                                    }
                                }
                                .frame(height: 3)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("+\(quest.xpReward) XP")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.yellow)
                                .accessibilityLabel("Награда \(quest.xpReward) опыта")
                            
                            // Кнопка обновления (только для невыполненных квестов)
                            if !quest.isCompleted {
                                Button {
                                    HapticManager.impact(style: .light)
                                    levelManager.refreshQuest(quest.id) { success in
                                        if success {
                                            HapticManager.notification(.success)
                                        } else {
                                            HapticManager.notification(.error)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                        .accessibilityHidden(true)
                                }
                                .accessibilityButton(
                                    label: "Обновить квест \(quest.title)",
                                    hint: "Обновить квест через просмотр рекламы"
                                )
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(quest.isCompleted ? "Квест выполнен: \(quest.title)" : "Квест: \(quest.title)")
                    .accessibilityValue(quest.isCompleted ? "Выполнено" : "Прогресс \(quest.progress) из \(quest.requirement)")
                    .accessibilityHint(quest.isPremium && !subscriptionManager.isPremium ? "Требуется Premium подписка" : quest.isCompleted ? "" : "Награда \(quest.xpReward) опыта")
                }
            }
            .accessibilityList(title: "Ежедневные квесты", itemCount: levelManager.dailyQuests.count)
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
    }
    
    // MARK: - Tournament Banner
    
    @ViewBuilder
    private func tournamentBanner(_ tournament: WeeklyTournament) -> some View {
        let userRank = tournamentManager.userRank
        
        Button {
            HapticManager.impact(style: .light)
            showTournamentDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                Text("Еженедельный турнир")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if userRank > 0 {
                    HStack(spacing: 4) {
                        Text("№\(userRank)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(userRank <= 3 ? .yellow : .white)
                        if userRank <= 3 {
                            Image(systemName: "medal.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            
            // Прогресс недели
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Дней осталось: \(tournament.daysRemaining)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("\(Int(tournament.progress * 100))%")
                        .font(.system(size: 12))
                        .foregroundColor(accentGreen)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [accentGreen, accentBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * tournament.progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
            
            // Топ-3 участника
            if userRank <= 10 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Топ участников")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    
                    ForEach(Array(tournament.participants.prefix(3).enumerated()), id: \.element.id) { index, participant in
                        HStack(spacing: 8) {
                            // Медаль для топ-3
                            if index < 3 {
                                Image(systemName: "medal.fill")
                                    .foregroundColor([.yellow, .gray, Color(red: 0.8, green: 0.5, blue: 0.2)][index])
                                    .font(.system(size: 14))
                            } else {
                                Text("\(participant.rank)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                            }
                            
                            Text(participant.name)
                                .font(.system(size: 13, weight: participant.id == "user" ? .bold : .regular))
                                .foregroundColor(participant.id == "user" ? accentGreen : .white)
                            
                            Spacer()
                            
                            Text(formatNumber(participant.steps))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
            }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [.yellow.opacity(0.3), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000000 {
            return String(format: "%.1fM", Double(number) / 1000000)
        } else if number >= 1000 {
            return String(format: "%.0fK", Double(number) / 1000)
        }
        return "\(number)"
    }
} // HomeView

// MARK: - Pet Mini Banner Component

struct PetMiniBanner: View {
    let pet: Pet
    let accentGreen: Color
    let accentBlue: Color
    let onTap: () -> Void
    
    @State private var petPulse = false
    
    var body: some View {
        Button {
            HapticManager.impact(style: .light)
            onTap()
        } label: {
            GlassCard(cornerRadius: 20, padding: 16, glowColor: accentGreen.opacity(0.3)) {
                HStack(spacing: 16) {
                    // Анимированный эмодзи питомца
                    ZStack {
                        // Свечение вокруг питомца
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [accentGreen.opacity(0.3), accentBlue.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .blur(radius: 8)
                            .opacity(petPulse ? 0.8 : 0.5)
                        
                        Text(pet.type.emoji)
                            .font(.system(size: 40))
                            .scaleEffect(petPulse ? 1.05 : 1.0)
                            .rotation3DEffect(
                                .degrees(petPulse ? 5 : 0),
                                axis: (x: 1, y: 0, z: 0)
                            )
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                            petPulse = true
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        // Имя питомца
                        Text(pet.name)
                            .font(.appTitle)
                            .foregroundColor(.white)
                        
                        // Настроение
                        HStack(spacing: 6) {
                            Text(pet.mood.emoji)
                                .font(.system(size: 14))
                            Text(pet.mood.message)
                                .font(.appCaption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // Эволюция
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                                .foregroundColor(accentGreen)
                            Text(pet.evolution.name)
                                .font(.appSmallCaption)
                                .foregroundColor(accentGreen)
                        }
                    }
                    
                    Spacer()
                    
                    // Иконка перехода
                    VStack(spacing: 4) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                        
                        // Маленький индикатор XP/прогресса (если есть)
                        let xpProgress = min(1.0, Double(pet.totalXP % 100) / 100.0)
                        if xpProgress > 0 {
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 3)
                                    .frame(width: 32, height: 32)
                                
                                Circle()
                                    .trim(from: 0, to: xpProgress)
                                    .stroke(
                                        LinearGradient(
                                            colors: [accentGreen, accentBlue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                    )
                                    .frame(width: 32, height: 32)
                                    .rotationEffect(.degrees(-90))
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
