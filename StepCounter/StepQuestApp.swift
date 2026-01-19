//
//  StepQuestApp.swift
//  StepQuest
//
//  Шагомер с HealthKit, достижениями, питомцем, путешествиями и уровнями
//

import SwiftUI
import UIKit
import Combine

@main
struct StepQuestApp: App {
    
    init() {
        // Настройка внешнего вида TabBar и NavigationBar для экрана "Еще"
        setupTabBarAppearance()
        setupNavigationBarAppearance()
        setupTableViewAppearance()
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    private func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        if #available(iOS 15.0, *) {
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    private func setupTableViewAppearance() {
        // Настройка фона для таблицы в экране "Еще"
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
        
        // Настройка внешнего вида ячеек
        if #available(iOS 15.0, *) {
            UITableView.appearance().sectionHeaderTopPadding = 0
        }
    }
    // MARK: - Dependency Injection Container
    @StateObject private var container = DIContainer.shared
    
    // MARK: - Managers (получаем через DI Container, но используем конкретные типы для SwiftUI)
    
    private var healthManager: HealthManager {
        container.healthManager as! HealthManager
    }
    
    private var achievementManager: AchievementManager {
        container.achievementManager as! AchievementManager
    }
    
    private var challengeManager: ChallengeManager {
        container.challengeManager as! ChallengeManager
    }
    
    private var locationManager: LocationManager {
        container.locationManager
    }
    
    private var petManager: PetManager {
        container.petManager as! PetManager
    }
    
    private var levelManager: LevelManager {
        container.levelManager as! LevelManager
    }
    
    private var groupChallengeManager: GroupChallengeManager {
        container.groupChallengeManager as! GroupChallengeManager
    }
    
    private var tournamentManager: TournamentManager {
        container.tournamentManager as! TournamentManager
    }
    
    private var seasonManager: SeasonManager {
        container.seasonManager
    }
    
    @StateObject private var consentManager = PrivacyConsentManager.shared
    
    var body: some Scene {
        WindowGroup {
            if consentManager.shouldShowConsentScreen {
                PrivacyConsentView(hasConsent: $consentManager.hasConsent)
            } else {
                MainTabView()
                    .environmentObject(healthManager)
                    .environmentObject(achievementManager)
                    .environmentObject(challengeManager)
                    .environmentObject(locationManager)
                    .environmentObject(petManager)
                    .environmentObject(levelManager)
                    .environmentObject(tournamentManager)
                    .environmentObject(groupChallengeManager)
                    .onAppear {
                        // Настройка DataCoordinator через DI Container
                        container.setupDataCoordinator()
                    
                    // Тяжелые операции - асинхронно, не блокируем UI
                    Task { @MainActor in
                        // Запрос авторизации HealthKit (может быть медленным)
                        healthManager.requestAuthorization()
                        NotificationManager.shared.requestAuthorization()
                    }
                }
                .onReceive(healthManager.debouncedSteps) { steps in
                    // Используем DataCoordinator для оптимизации обновлений
                    // Дебаунсинг уменьшает количество обновлений
                    DataCoordinator.shared.onStepsChanged(
                        steps: steps,
                        distance: healthManager.todayDistance,
                        calories: healthManager.todayCalories,
                        goalReached: healthManager.isGoalReached,
                        stepGoal: healthManager.stepGoal,
                        streak: achievementManager.currentStreak
                    )
                    
                    // Обновляем турнир с учетом недельных шагов
                    if let tournament = tournamentManager.currentTournament {
                        tournamentManager.updateUserStepsFromWeekly(
                            healthManager.weeklySteps,
                            tournamentStartDate: tournament.startDate
                        )
                    }
                }
                // Сохраняем onChange для немедленного обновления UI (без дебаунсинга)
                .onChange(of: healthManager.todaySteps) { _, _ in
                    // UI обновляется сразу, но тяжелые операции через дебаунсинг
                }
                .onChange(of: healthManager.weeklySteps.count) { _, _ in
                    // При обновлении недельных данных также обновляем турнир
                    if let tournament = tournamentManager.currentTournament {
                        tournamentManager.updateUserStepsFromWeekly(
                            healthManager.weeklySteps,
                            tournamentStartDate: tournament.startDate
                        )
                    }
                }
                .onChange(of: healthManager.isGoalReached) { _, reached in
                    if reached {
                        DataCoordinator.shared.onGoalReached()
                        
                        // Запрос отзыва после достижения цели (если разблокировано 3+ достижения)
                        ReviewManager.shared.requestReviewAfterGoal(
                            achievementsUnlocked: achievementManager.unlockedCount
                        )
                    }
                }
                .onChange(of: achievementManager.newlyUnlocked) { _, achievement in
                    if let achievement = achievement {
                        DataCoordinator.shared.onAchievementUnlocked(title: achievement.type.title)
                        
                        // Запрос отзыва после 3-го достижения
                        ReviewManager.shared.requestReviewAfterAchievement(
                            count: achievementManager.unlockedCount
                        )
                    }
                    }
            }
        }
    }
}

/// Главный TabView
struct MainTabView: View {
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var achievementManager: AchievementManager
    @EnvironmentObject var petManager: PetManager
    @EnvironmentObject var levelManager: LevelManager
    
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var showAchievementPopup = false
    @State private var unlockedAchievement: Achievement?
    @State private var showLevelUpPopup = false
    @State private var showStreakBonusPopup = false
    @State private var selectedTab: TabSelection = .today
    @State private var previousTab: TabSelection = .today
    @State private var animationTrigger: UUID = UUID()
    
    private let accentGreen = Color(red: 0.3, green: 0.85, blue: 0.5)
    
    enum TabSelection: Int {
        case today = 0
        case stats = 1
        case pet = 2
        case routes = 3
        case challenges = 4
        case achievements = 5
        case profile = 6
        case settings = 7
    }
    
    var body: some View {
        ZStack {
            // Фон с темой
            LinearGradient(
                colors: themeManager.currentTheme.primaryGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .id(themeManager.currentTheme.id)
            .ignoresSafeArea()
            
            // Контент вкладок с правильными отступами
            Group {
                switch selectedTab {
                case .today:
                    HomeView(selectedTab: $selectedTab)
                case .stats:
                    StatsView()
                case .pet:
                    PetView()
                case .routes:
                    RoutesView()
                case .challenges:
                    ChallengesView()
                default:
                    HomeView(selectedTab: $selectedTab)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                // TabBar с автоматическими отступами для контента
                CustomAnimatedTabBar(selectedTab: $selectedTab, accentGreen: accentGreen)
                    .padding(.bottom, 0)
            }
            .preferredColorScheme(.dark)
            .onChange(of: selectedTab) { oldValue, newValue in
                if oldValue != newValue {
                    previousTab = oldValue
                    animationTrigger = UUID()
                    HapticManager.impact(style: .light)
                    animateTabIcon(for: newValue)
                }
            }
            
            // Popup достижения
            if showAchievementPopup, let achievement = unlockedAchievement {
                AchievementPopup(achievement: achievement) {
                    withAnimation {
                        showAchievementPopup = false
                    }
                }
            }
            
            // Popup повышения уровня
            if showLevelUpPopup {
                LevelUpPopup(level: levelManager.newLevel, rank: levelManager.player.rank) {
                    withAnimation {
                        showLevelUpPopup = false
                        levelManager.showLevelUp = false
                    }
                }
            }
            
            // Popup бонуса за стрик
            if showStreakBonusPopup {
                StreakBonusPopup(
                    title: levelManager.streakBonusTitle,
                    bonus: levelManager.streakBonusAmount
                ) {
                    withAnimation {
                        showStreakBonusPopup = false
                        levelManager.showStreakBonus = false
                    }
                }
            }
        }
        .onChange(of: achievementManager.newlyUnlocked) { _, achievement in
            if let achievement = achievement {
                unlockedAchievement = achievement
                withAnimation(.spring()) {
                    showAchievementPopup = true
                }
                achievementManager.newlyUnlocked = nil
            }
        }
        .onChange(of: levelManager.showLevelUp) { _, show in
            if show {
                withAnimation(.spring()) {
                    showLevelUpPopup = true
                }
            }
        }
        .onChange(of: levelManager.showStreakBonus) { _, show in
            if show {
                withAnimation(.spring()) {
                    showStreakBonusPopup = true
                }
            }
        }
        .onChange(of: themeManager.currentTheme.id) { _, _ in
            // Обновление appearance при смене темы для экрана "Еще"
            updateAppearanceForTheme(themeManager.currentTheme)
        }
        .onChange(of: subscriptionManager.isPremium) { oldValue, newValue in
            // Если Premium закончился, проверяем и сбрасываем Premium тему
            if oldValue && !newValue {
                themeManager.checkAndResetPremiumThemeIfNeeded()
            }
        }
        .onAppear {
            // Применение темы при первом появлении
            updateAppearanceForTheme(themeManager.currentTheme)
            // Проверяем Premium статус и сбрасываем Premium тему при необходимости
            themeManager.checkAndResetPremiumThemeIfNeeded()
        }
    }
    
    private func updateAppearanceForTheme(_ theme: AppTheme) {
        // Обновление фона для UITableView (экран "Еще")
        let gradientColors = theme.primaryGradientColors
        if let firstColor = gradientColors.first {
            UITableView.appearance().backgroundColor = UIColor(firstColor)
        }
        
        // Обновление NavigationBar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundColor = .clear
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        if #available(iOS 15.0, *) {
            UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        }
    }
    
    private func animateTabIcon(for tab: TabSelection) {
        // Используем UIKit для анимации иконок таб-бара
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                  let tabBarController = findTabBarController(in: window.rootViewController) else {
                return
            }
            
            guard let tabBarItems = tabBarController.tabBar.items, tabBarItems.count > tab.rawValue else {
                return
            }
            
            let tabBarItem = tabBarItems[tab.rawValue]
            
            // Анимация для разных табов
            switch tab {
            case .today:
                // Анимация ходьбы для человечка - имитация движения ног/рук (2.5 сек)
                animateWalkingIcon(tabBarItem: tabBarItem, duration: 2.5)
            case .stats:
                // Анимация движения полосок графика вверх-вниз (2.5 сек)
                animateBarsMovement(tabBarItem: tabBarItem, duration: 2.5)
            case .pet:
                // Анимация прыжка/прыгания для питомца (2.5 сек)
                animatePetJump(tabBarItem: tabBarItem, duration: 2.5)
            case .routes:
                // Вращение для карты (2-3 сек)
                animateIconRotation(tabBarItem: tabBarItem, duration: 2.5)
            case .challenges:
                // Пульсация для флага
                animateIconScale(tabBarItem: tabBarItem, duration: 2.5)
            default:
                break
            }
        }
    }
    
    private func findTabBarController(in viewController: UIViewController?) -> UITabBarController? {
        if let tabBarController = viewController as? UITabBarController {
            return tabBarController
        }
        
        for child in viewController?.children ?? [] {
            if let found = findTabBarController(in: child) {
                return found
            }
        }
        
        return nil
    }
    
    // Анимация ходьбы - имитация движения ног/рук через вертикальное подпрыгивание (шаги)
    private func animateWalkingIcon(tabBarItem: UITabBarItem, duration: TimeInterval) {
        guard let view = tabBarItem.value(forKey: "view") as? UIView else { return }
        
        // Вертикальная анимация для имитации поднятия ног при ходьбе
        // Серия подпрыгиваний разной высоты создает эффект шагов
        let stepAnimation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        // Значения: начало, подъем ноги 1, опускание, подъем ноги 2, опускание, и т.д.
        stepAnimation.values = [0, -3, -1, -3, -1, -3, -1, 0]
        stepAnimation.keyTimes = [0, 0.15, 0.3, 0.45, 0.6, 0.75, 0.9, 1.0]
        stepAnimation.duration = duration
        stepAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // Очень небольшой наклон вперед-назад для имитации движения корпуса при ходьбе
        let leanAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        // Небольшой наклон вперед при каждом шаге (имитация движения корпуса)
        leanAnimation.values = [0, 0.03, -0.02, 0.03, -0.02, 0.03, -0.02, 0]
        leanAnimation.keyTimes = [0, 0.15, 0.3, 0.45, 0.6, 0.75, 0.9, 1.0]
        leanAnimation.duration = duration
        leanAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        view.layer.add(stepAnimation, forKey: "walkingSteps")
        view.layer.add(leanAnimation, forKey: "walkingLean")
    }
    
    // Анимация движения полосок графика вверх-вниз
    private func animateBarsMovement(tabBarItem: UITabBarItem, duration: TimeInterval) {
        guard let view = tabBarItem.value(forKey: "view") as? UIView else { return }
        
        // Вертикальная анимация с разной интенсивностью для имитации движения полосок
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        // Создаем волнообразное движение: вверх-вниз с разной амплитудой
        animation.values = [0, -4, 2, -3, 1, 0]
        animation.keyTimes = [0, 0.2, 0.4, 0.6, 0.8, 1.0]
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        view.layer.add(animation, forKey: "barsMovement")
    }
    
    // Анимация прыжка для питомца
    private func animatePetJump(tabBarItem: UITabBarItem, duration: TimeInterval) {
        guard let view = tabBarItem.value(forKey: "view") as? UIView else { return }
        
        // Комбинация прыжка (вверх-вниз) и небольшого качания
        let jumpAnimation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        jumpAnimation.values = [0, -6, 0, -5, 0, -4, 0] // Серия прыжков разной высоты
        jumpAnimation.duration = duration
        jumpAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // Небольшое масштабирование при прыжке
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.values = [1.0, 1.1, 1.0, 1.08, 1.0, 1.05, 1.0]
        scaleAnimation.duration = duration
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        view.layer.add(jumpAnimation, forKey: "petJump")
        view.layer.add(scaleAnimation, forKey: "petScale")
    }
    
    private func animateIconScale(tabBarItem: UITabBarItem, duration: TimeInterval) {
        guard let view = tabBarItem.value(forKey: "view") as? UIView else { return }
        
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [1.0, 1.3, 1.0, 1.2, 1.0]
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        view.layer.add(animation, forKey: "pulse")
    }
    
    private func animateIconRotation(tabBarItem: UITabBarItem, duration: TimeInterval) {
        guard let view = tabBarItem.value(forKey: "view") as? UIView else { return }
        
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = CGFloat.pi * 2
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        view.layer.add(animation, forKey: "rotation")
    }
}

// MARK: - Helper Views


struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    private let cardColor = Color(red: 0.08, green: 0.08, blue: 0.12)
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(RoundedRectangle(cornerRadius: 16).fill(cardColor))
    }
}

struct MiniStatCard: View {
    let value: String
    let label: String
    
    var body: some View {
        GlassCard(cornerRadius: 12, padding: 16) {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Achievement Popup

struct AchievementPopup: View {
    let achievement: Achievement
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            VStack(spacing: 24) {
                // Красивая 3D медаль
                ZStack {
                    // Свечение
                    Circle()
                        .fill(achievement.type.rarity.glowColor)
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                    
                    // Рамка медали
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: achievement.type.rarity.frameColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    // Внутренний круг с градиентом
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: achievement.type.medalGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 82, height: 82)
                        .overlay(
                            Ellipse()
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.5), .clear],
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                )
                                .frame(width: 60, height: 30)
                                .offset(y: -15)
                        )
                    
                    // Символ
                    Text(achievement.type.medalSymbol)
                        .font(.system(size: 40))
                }
                
                // Редкость
                HStack(spacing: 6) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: achievement.type.rarity.frameColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 10, height: 10)
                    Text(achievement.type.rarity.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Text("🎉 Новое достижение!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(achievement.type.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(achievement.type.description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                
                // XP бонус
                Text("+\(achievement.type.rarity.xpBonus) XP")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.yellow)
                
                Button { onDismiss() } label: {
                    Text("Отлично!")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 150)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: achievement.type.medalGradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
            }
            .padding(32)
            .background(RoundedRectangle(cornerRadius: 28).fill(Color(red: 0.1, green: 0.1, blue: 0.14)))
            .padding(40)
        }
        .transition(.opacity.combined(with: .scale))
    }
}

// MARK: - Level Up Popup

struct LevelUpPopup: View {
    let level: Int
    let rank: PlayerRank
    let onDismiss: () -> Void
    
    private let accentGreen = Color(red: 0.3, green: 0.85, blue: 0.5)
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            VStack(spacing: 24) {
                Text("⬆️")
                    .font(.system(size: 60))
                
                Text("Уровень повышен!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("Уровень \(level)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                HStack {
                    Image(systemName: rank.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(rank.color)
                    Text(rank.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(rank.color)
                }
                
                Button { onDismiss() } label: {
                    Text("Продолжить")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 150)
                        .padding(.vertical, 14)
                        .background(accentGreen)
                        .clipShape(Capsule())
                }
            }
            .padding(32)
            .background(RoundedRectangle(cornerRadius: 28).fill(Color(red: 0.1, green: 0.1, blue: 0.14)))
            .padding(40)
        }
        .transition(.opacity.combined(with: .scale))
    }
}

// MARK: - Streak Bonus Popup

struct StreakBonusPopup: View {
    let title: String
    let bonus: Int
    let onDismiss: () -> Void
    
    private let accentGreen = Color(red: 0.3, green: 0.85, blue: 0.5)
    private let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            VStack(spacing: 24) {
                Text("🎉")
                    .font(.system(size: 60))
                
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)
                    
                    Text("+\(bonus) XP")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(accentGreen)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(
                    Capsule()
                        .fill(accentGreen.opacity(0.2))
                        .overlay(
                            Capsule()
                                .stroke(accentGreen, lineWidth: 2)
                        )
                )
                
                Text("Продолжайте в том же духе!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                Button { onDismiss() } label: {
                    Text("Отлично!")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 150)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [accentOrange, accentOrange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
            }
            .padding(32)
            .background(RoundedRectangle(cornerRadius: 28).fill(Color(red: 0.1, green: 0.1, blue: 0.14)))
            .padding(40)
        }
        .transition(.opacity.combined(with: .scale))
    }
}
