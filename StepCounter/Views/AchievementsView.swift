//
//  AchievementsView.swift
//  StepCounter
//
//  Экран достижений с уникальными 3D-медалями
//

import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var achievementManager: AchievementManager
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var selectedCategory: AchievementCategory?
    @State private var selectedAchievement: Achievement?
    
    private var bgColor: Color { themeManager.backgroundColor }
    private var cardColor: Color { themeManager.cardColor }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Сводка с XP
                    summaryCard
                    
                    // Фильтр по категориям
                    categoryFilter
                    
                    // Статистика редкости
                    rarityStats
                    
                    // Сетка медалей
                    medalsGrid
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
            .background(
                LinearGradient(
                    colors: themeManager.currentTheme.primaryGradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .id(themeManager.currentTheme.id)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: themeManager.currentTheme.id)
            )
            .navigationTitle("Достижения")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedAchievement) { achievement in
                AchievementDetailView(achievement: achievement)
            }
        }
    }
    
    // MARK: - Summary Card
    
    private var summaryCard: some View {
        VStack(spacing: 16) {
        HStack(spacing: 20) {
                // Прогресс кольцо
            ZStack {
                    // Фон
                Circle()
                        .stroke(cardColor, lineWidth: 10)
                        .frame(width: 90, height: 90)
                
                    // Прогресс
                Circle()
                    .trim(from: 0, to: Double(achievementManager.unlockedCount) / Double(achievementManager.totalCount))
                        .stroke(
                            AngularGradient(
                                colors: [.green, .cyan, .blue, .purple, .green],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(achievementManager.unlockedCount)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("из \(achievementManager.totalCount)")
                            .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
                VStack(alignment: .leading, spacing: 10) {
                    // XP
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(achievementManager.totalXPEarned) XP")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    }
                
                // Серия
                    HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        Text("\(achievementManager.currentStreak) дней")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Общие шаги
                    HStack(spacing: 6) {
                        Image(systemName: "figure.walk")
                            .foregroundColor(.green)
                        Text(formatNumber(achievementManager.totalStepsEver))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.1), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - Category Filter
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryPill(
                    name: "Все",
                    icon: "square.grid.2x2.fill",
                    color: .white,
                    isSelected: selectedCategory == nil
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = nil
                    }
                }
                
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    CategoryPill(
                        name: category.name,
                        icon: category.icon,
                        color: category.color,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Rarity Stats
    
    private var rarityStats: some View {
        HStack(spacing: 12) {
            ForEach([AchievementRarity.common, .rare, .epic, .legendary], id: \.self) { rarity in
                let count = achievementManager.achievements(for: rarity).filter { $0.isUnlocked }.count
                let total = achievementManager.achievements(for: rarity).count
                
                VStack(spacing: 6) {
                    // Мини-медаль
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: rarity.frameColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                        
                        Text("\(count)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("\(count)/\(total)")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(cardColor))
    }
    
    // MARK: - Medals Grid
    
    private var medalsGrid: some View {
        let filteredAchievements = selectedCategory == nil
            ? achievementManager.achievements
            : achievementManager.achievements(for: selectedCategory!)
        
        return LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            spacing: 20
        ) {
            ForEach(Array(filteredAchievements.enumerated()), id: \.element.id) { index, achievement in
                MedalView(
                    achievement: achievement,
                    isDetailOpen: selectedAchievement?.id == achievement.id
                )
                .contentShape(Rectangle())
                .simultaneousGesture(
                    TapGesture()
                        .onEnded { _ in
                            HapticManager.impact(style: .light)
                            selectedAchievement = achievement
                        }
                )
                .cascadeAppear(delay: Double(index) * 0.05)
            }
        }
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

// MARK: - Category Pill

struct CategoryPill: View {
    let name: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(name)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color.opacity(0.3) : Color.white.opacity(0.05))
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? color : Color.clear, lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Medal View (3D эффект как в Apple Watch с переворачиванием)

struct MedalView: View {
    let achievement: Achievement
    let isDetailOpen: Bool // Флаг, указывающий, открыт ли детальный просмотр
    
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var rotationAngle: Double = 0
    @State private var rotationY: Double = 0
    @State private var rotationX: Double = 0
    @State private var flipRotation: Double = 0 // Для переворачивания медали
    @State private var isPressed = false
    @State private var glowIntensity: Double = 0.5
    @State private var showBack = false
    
    private let appName = "StepCounter"
    
    // Проверяем, заблокировано ли достижение из-за Premium
    private var isLockedByPremium: Bool {
        achievement.type.isPremium && !subscriptionManager.isPremium
    }
    
    // Фактически заблокировано (либо не разблокировано, либо заблокировано Premium)
    private var isEffectivelyLocked: Bool {
        !achievement.isUnlocked || isLockedByPremium
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Медаль с возможностью переворачивания
            ZStack {
                // Лицевая сторона медали
                if !showBack {
                    medalFrontSide
                        .rotation3DEffect(
                            .degrees(flipRotation),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .opacity(flipRotation < 90 ? 1 : 0)
                }
                
                // Обратная сторона медали
                if showBack {
                    medalBackSide
                        .rotation3DEffect(
                            .degrees(flipRotation - 180),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .opacity(flipRotation > 90 ? 1 : 0)
                }
            }
            .frame(width: 68, height: 68)
            .rotation3DEffect(
                .degrees(rotationX),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.8
            )
            .rotation3DEffect(
                .degrees(rotationY),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.8
            )
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: rotationX)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: rotationY)
            .onTapGesture {
                if achievement.isUnlocked && !isLockedByPremium {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        flipRotation += 180
                        showBack.toggle()
                    }
                    HapticManager.impact(style: .light)
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isPressed {
                            isPressed = true
                        }
                        
                        let dragX = value.translation.width
                        let dragY = value.translation.height
                        
                        rotationY = min(max(-25, dragX / 3), 25)
                        rotationX = min(max(-25, -dragY / 3), 25)
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            rotationX = 0
                            rotationY = 0
                            isPressed = false
                        }
                    }
            )
            .onAppear {
                if achievement.isUnlocked && !isLockedByPremium {
                    // Плавное непрерывное вращение (как в Apple Watch)
                    withAnimation(
                        .linear(duration: 8)
                        .repeatForever(autoreverses: false)
                    ) {
                        rotationAngle = 360
                    }
                    
                    // Пульсирующее свечение
                    withAnimation(
                        .easeInOut(duration: 2)
                        .repeatForever(autoreverses: true)
                    ) {
                        glowIntensity = 0.8
                    }
                }
            }
            .onChange(of: isDetailOpen) { oldValue, newValue in
                // Сбрасываем состояние медали при закрытии детального просмотра
                if oldValue && !newValue {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showBack = false
                        flipRotation = 0
                        rotationX = 0
                        rotationY = 0
                    }
                }
            }
            
            // Название
            Text(achievement.type.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isEffectivelyLocked ? .white.opacity(0.4) : .white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 26)
            
            // Premium бейдж для заблокированных Premium-достижений
            if isLockedByPremium {
                HStack(spacing: 2) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.yellow)
                    Text("Premium")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.yellow.opacity(0.2))
                )
            }
        }
    }
    
    // MARK: - Лицевая сторона медали
    
    private var medalFrontSide: some View {
        ZStack {
            // Внешнее свечение (пульсирующее)
            if achievement.isUnlocked && !isLockedByPremium {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                achievement.type.rarity.glowColor.opacity(glowIntensity),
                                achievement.type.rarity.glowColor.opacity(0)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 12)
            }
            
            // Внешняя золотая рамка (в стиле Apple Fitness)
            Circle()
                .fill(
                    LinearGradient(
                        colors: isEffectivelyLocked
                            ? [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]
                            : [Color(hex: "FFD700"), Color(hex: "FFA500"), Color(hex: "FF8C00")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 68, height: 68)
                .overlay(
                    // Металлический блик сверху
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(isEffectivelyLocked ? 0.1 : 0.6), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .frame(width: 50, height: 25)
                        .offset(y: -25)
                )
                .shadow(color: .black.opacity(0.6), radius: 10, x: 0, y: 5)
                .shadow(color: isEffectivelyLocked ? .clear : Color(hex: "FFD700").opacity(0.4), radius: 15, x: 0, y: 0)
            
            // Средняя рамка (объем)
            Circle()
                .fill(
                    LinearGradient(
                        colors: isEffectivelyLocked
                            ? [Color.gray.opacity(0.25), Color.gray.opacity(0.15)]
                            : achievement.type.rarity.frameColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                .overlay(
                    // Боковой блик
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(achievement.isUnlocked ? 0.3 : 0.05), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 30, height: 60)
                        .rotationEffect(.degrees(rotationAngle * 0.1))
                )
            
            // Внутренний круг с темным фоном (в стиле Apple Fitness)
            Circle()
                .fill(
                    isEffectivelyLocked
                        ? Color.gray.opacity(0.2)
                        : Color(red: 0.08, green: 0.08, blue: 0.12)
                )
                .frame(width: 52, height: 52)
                .overlay(
                    // Главный 3D блик (движущийся)
                    GeometryReader { geometry in
                        Ellipse()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        .white.opacity(isEffectivelyLocked ? 0.1 : 0.7),
                                        .white.opacity(isEffectivelyLocked ? 0.05 : 0.3),
                                        .clear
                                    ],
                                    center: UnitPoint(
                                        x: 0.5 + 0.3 * cos(rotationAngle * .pi / 180),
                                        y: 0.3 + 0.2 * sin(rotationAngle * .pi / 180)
                                    ),
                                    startRadius: 5,
                                    endRadius: 25
                                )
                            )
                            .frame(width: 50, height: 50)
                    }
                )
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
            
            // Уникальная иконка медали (SF Symbols в стиле Apple Fitness)
            if isEffectivelyLocked {
                // Если Premium-достижение заблокировано Premium, показываем корону
                if isLockedByPremium {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.yellow.opacity(0.6), Color.yellow.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray.opacity(0.3))
                }
            } else {
                Image(systemName: achievement.type.medalIcon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            
            // Прогресс кольцо (если не разблокировано и не Premium-заблокировано)
            if !achievement.isUnlocked && achievement.progress > 0 && !isLockedByPremium {
                Circle()
                    .trim(from: 0, to: achievement.progressPercent)
                    .stroke(
                        LinearGradient(
                            colors: [achievement.type.category.color, achievement.type.category.color.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: achievement.type.category.color.opacity(0.5), radius: 4)
            }
        }
    }
    
    // MARK: - Обратная сторона медали
    
    private var medalBackSide: some View {
        ZStack {
            // Фон медали (металлический)
            Circle()
                .fill(
                    LinearGradient(
                        colors: achievement.type.rarity.frameColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 68, height: 68)
                .shadow(color: .black.opacity(0.6), radius: 10, x: 0, y: 5)
            
            // Внутренний круг с текстом
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.15, green: 0.15, blue: 0.2), Color(red: 0.1, green: 0.1, blue: 0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
            
            // Информация на обратной стороне
            VStack(spacing: 4) {
                // Имя пользователя (или "Пользователь")
                Text(getUserName())
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                
                // Дата получения
                if let date = achievement.unlockedDate {
                    Text(formatShortDate(date))
                        .font(.system(size: 6))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
                
                // Подпись приложения
                Text(appName)
                    .font(.system(size: 5, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    .lineLimit(1)
            }
            .padding(.horizontal, 6)
        }
    }
    
    private func getUserName() -> String {
        // Получаем имя пользователя из системы или используем дефолтное
        if let userName = ProcessInfo.processInfo.environment["USER"] {
            return userName.capitalized
        }
        return "Пользователь"
    }
    
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d.M.yy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}

// MARK: - Achievement Detail View

struct AchievementDetailView: View {
    let achievement: Achievement
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var rotationAngle: Double = 0
    @State private var showConfetti = false
    @State private var hasAnimated = false
    @State private var showPremium = false
    
    private var bgColor: Color { themeManager.backgroundColor }
    
    // Проверяем, заблокировано ли достижение из-за Premium
    private var isLockedByPremium: Bool {
        achievement.type.isPremium && !subscriptionManager.isPremium
    }
    
    // Фактически заблокировано
    private var isEffectivelyLocked: Bool {
        !achievement.isUnlocked || isLockedByPremium
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                
                // Большая медаль
                largeMedal
                
                // Информация
                VStack(spacing: 12) {
                    Text(achievement.type.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
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
                            .frame(width: 12, height: 12)
                        
                        Text(achievement.type.rarity.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Text(achievement.type.description)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Прогресс или дата
                if isEffectivelyLocked {
                    if isLockedByPremium {
                        // Premium-достижение заблокировано
                        VStack(spacing: 16) {
                            VStack(spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.yellow)
                                    
                                    Text("Premium достижение")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                Text("Это достижение доступно только для Premium пользователей")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                            
                            Button {
                                showPremium = true
                                HapticManager.impact(style: .medium)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 16))
                                    
                                    Text("Получить Premium")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [Color.yellow, Color.orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                                .shadow(color: .yellow.opacity(0.5), radius: 10)
                            }
                        }
                        .padding(.top, 20)
                    } else {
                        // Обычное заблокированное достижение - прогресс бар
                        VStack(spacing: 12) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 8)
                                    
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: achievement.type.medalGradient,
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * achievement.progressPercent, height: 8)
                                }
                            }
                            .frame(height: 8)
                            .padding(.horizontal, 40)
                            
                            Text("\(achievement.progress) / \(achievement.type.requirement)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.top, 20)
                    }
                } else {
                    // Разблокировано
                    VStack(spacing: 12) {
                        VStack(spacing: 8) {
                            Text("Разблокировано")
                                .font(.system(size: 13))
                                .foregroundColor(.green)
                            
                            if let date = achievement.unlockedDate {
                                Text(formatDate(date))
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            Text("+\(achievement.type.rarity.xpBonus) XP")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                        
                        // Кнопка "Поделиться"
                        ShareButton(
                            icon: "square.and.arrow.up",
                            title: "Поделиться достижением"
                        ) {
                            HapticManager.impact(style: .medium)
                            // Показываем sharing сразу - ShareManager оптимизирован для быстрого отклика
                            ShareManager.shared.shareAchievement(achievement)
                        }
                    }
                    .padding(.top, 20)
                }
                
                Spacer()
                Spacer()
        }
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .sheet(isPresented: $showPremium) {
                PremiumView()
            }
        }
    }
    
    private var largeMedal: some View {
        ZStack {
            // Свечение
            if achievement.isUnlocked && !isLockedByPremium {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "FFD700").opacity(0.6), .clear],
                            center: .center,
                            startRadius: 40,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)
            }
            
            // Золотая рамка (в стиле Apple Fitness)
            Circle()
                .fill(
                    LinearGradient(
                        colors: isEffectivelyLocked
                            ? [Color.gray.opacity(0.3)]
                            : [Color(hex: "FFD700"), Color(hex: "FFA500"), Color(hex: "FF8C00")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 140)
                .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 8)
                .shadow(color: isEffectivelyLocked ? .clear : Color(hex: "FFD700").opacity(0.3), radius: 20)
            
            // Внутренний круг с темным фоном
            Circle()
                .fill(
                    isEffectivelyLocked
                        ? Color.gray.opacity(0.2)
                        : Color(red: 0.08, green: 0.08, blue: 0.12)
                )
                .frame(width: 116, height: 116)
                .overlay(
                    // 3D блик
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(isEffectivelyLocked ? 0.1 : 0.5), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .frame(width: 90, height: 40)
                        .offset(y: -25)
                )
            
            // Уникальная иконка медали (SF Symbols)
            if isEffectivelyLocked {
                if isLockedByPremium {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.yellow.opacity(0.7), Color.yellow.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.gray.opacity(0.3))
                }
            } else {
                Image(systemName: achievement.type.medalIcon)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
            }
        }
        .rotation3DEffect(
            .degrees(rotationAngle),
            axis: (x: 0, y: 1, z: 0),
            perspective: 1.0
        )
        .id(achievement.id) // Принудительное обновление при открытии
        .onAppear {
            // Сбрасываем состояние при каждом появлении
            rotationAngle = 0
            hasAnimated = false
            
            if achievement.isUnlocked && !isLockedByPremium {
                // Небольшая задержка перед анимацией
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Вращение на 360 градусов при появлении
                    withAnimation(
                        .easeOut(duration: 1.5)
                    ) {
                        rotationAngle = 360
                    }
                    
                    // После полного оборота - плавное покачивание
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        withAnimation(
                            .easeInOut(duration: 2)
                            .repeatForever(autoreverses: true)
                        ) {
                            rotationAngle = 375
                        }
                        hasAnimated = true
                    }
                }
            }
        }
        .onDisappear {
            // Сбрасываем анимацию при закрытии
            rotationAngle = 0
            hasAnimated = false
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}


// MARK: - Preview

#Preview {
    AchievementsView()
        .environmentObject(AchievementManager())
}
