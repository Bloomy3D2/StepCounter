//
//  StatsView.swift
//  StepCounter
//
//  Экран статистики с графиками и анализом
//

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var healthManager: HealthManager
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var leaderboardManager = PublicLeaderboardManager.shared
    
    @State private var selectedPeriod = 0
    @State private var selectedDataPoint: (value: Int, date: String)? = nil
    @State private var showLeaderboard = false
    @State private var showPremium = false
    @State private var showAllMonths = false
    @State private var showAllDays = false
    @State private var showDetailedStats = false
    
    private var bgColor: Color { themeManager.backgroundColor }
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    private var accentBlue: Color { themeManager.accentBlue }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Лидеры (вверху)
                    leadersSection
                    
                    // Переключатель периода
                    Picker("Период", selection: $selectedPeriod) {
                        Text("Неделя").tag(0)
                        Text("Месяц").tag(1)
                        Text("Год").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedPeriod) { _, _ in
                        // Сбрасываем состояние показа всех месяцев, дней и детальной статистики при смене периода
                        showAllMonths = false
                        showAllDays = false
                        showDetailedStats = false
                    }
                    
                    // Сводка
                    summaryCards
                    
                    // График (кликабельный для показа детальной статистики)
                    chartView
                    
                    // Детальная статистика (показывается при нажатии на график)
                    if showDetailedStats {
                        detailedStatsList
                    }
                    
                    // Прогнозы и сравнение (Premium или предложение подписки)
                    if subscriptionManager.isPremium {
                    if selectedPeriod == 0 {
                        predictionsAndComparison
                        }
                    } else {
                        // Показываем промо Premium всегда, если нет Premium
                        premiumPromoSection
                    }
                    
                    // Рекорды
                    if selectedPeriod < 2 {
                        recordsView
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
            .navigationTitle("Статистика")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showLeaderboard) {
                PublicLeaderboardView()
            }
            .sheet(isPresented: $showPremium) {
                PremiumView()
            }
        }
    }
    
    private var summaryCards: some View {
        let data: [Any] = {
            switch selectedPeriod {
            case 0: return healthManager.weeklySteps
            case 1: return healthManager.monthlySteps
            default: return healthManager.yearlySteps
            }
        }()
        
        let totalSteps: Int = {
            switch selectedPeriod {
            case 0: return healthManager.weeklySteps.reduce(0) { $0 + $1.steps }
            case 1: return healthManager.monthlySteps.reduce(0) { $0 + $1.steps }
            default: return healthManager.yearlySteps.reduce(0) { $0 + $1.steps }
            }
        }()
        
        let avgSteps = data.isEmpty ? 0 : totalSteps / max(1, data.count)
        
        let daysGoalReached: Int = {
            switch selectedPeriod {
            case 0: return healthManager.weeklySteps.filter { $0.steps >= healthManager.stepGoal }.count
            case 1: return healthManager.monthlySteps.filter { $0.steps >= healthManager.stepGoal }.count
            default: return healthManager.yearlySteps.filter { $0.steps >= healthManager.stepGoal * 30 }.count
            }
        }()
        
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MiniStatCard(value: formatNumber(totalSteps), label: "Всего")
            MiniStatCard(value: formatNumber(avgSteps), label: selectedPeriod == 2 ? "В месяц" : "Среднее")
            MiniStatCard(value: "\(daysGoalReached)", label: selectedPeriod == 2 ? "Месяцев ✓" : "Дней ✓")
        }
    }
    
    private var chartView: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                showDetailedStats.toggle()
            }
            HapticManager.impact(style: .light)
        } label: {
        VStack(alignment: .leading, spacing: 16) {
                HStack {
            Text(selectedPeriod == 0 ? "Последние 7 дней" : selectedPeriod == 1 ? "Последние 30 дней" : "Последние 12 месяцев")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: showDetailedStats ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
            
            if selectedPeriod == 2 {
                // Годовой график
                yearlyChartContent
            } else {
                // Дневной график
                dailyChartContent
            }
        }
        .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .white.opacity(0.1), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var yearlyChartContent: some View {
        let data = healthManager.yearlySteps
        
        return Group {
            if data.isEmpty {
                Text("Нет данных")
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 12) {
                        ForEach(data) { monthData in
                            VStack(spacing: 6) {
                                let maxSteps = data.map { $0.steps }.max() ?? 1
                                let height = maxSteps > 0 ? CGFloat(monthData.steps) / CGFloat(maxSteps) * 100 : 0
                                
                                Text(formatNumber(monthData.steps))
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(LinearGradient(colors: [accentGreen, accentBlue], startPoint: .bottom, endPoint: .top))
                                    .frame(width: 24, height: max(4, height))
                                
                                Text(monthData.monthString)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                }
                .frame(height: 160)
            }
        }
    }
    
    private var dailyChartContent: some View {
        let data = selectedPeriod == 0 ? healthManager.weeklySteps : healthManager.monthlySteps
        
        return Group {
            if data.isEmpty {
                Text("Нет данных")
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: selectedPeriod == 0 ? 12 : 6) {
                        ForEach(data.suffix(selectedPeriod == 0 ? 7 : 30)) { dayData in
                            VStack(spacing: 6) {
                                let maxSteps = data.map { $0.steps }.max() ?? 1
                                let height = maxSteps > 0 ? CGFloat(dayData.steps) / CGFloat(maxSteps) * 100 : 0
                                
                                // Показываем количество шагов для недели и месяца
                                if selectedPeriod == 0 {
                                    Text("\(dayData.steps / 1000)k")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                } else if selectedPeriod == 1 {
                                    // Для месяца показываем в компактном формате
                                    Text(formatNumber(dayData.steps))
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        dayData.steps >= healthManager.stepGoal
                                        ? LinearGradient(colors: [accentGreen, accentBlue], startPoint: .bottom, endPoint: .top)
                                        : LinearGradient(colors: [.gray.opacity(0.5), .gray.opacity(0.3)], startPoint: .bottom, endPoint: .top)
                                    )
                                    .frame(width: selectedPeriod == 0 ? 30 : 8, height: max(4, height))
                                
                                if selectedPeriod == 0 {
                                    Text(dayData.dayString)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                    }
                }
                .frame(height: selectedPeriod == 0 ? 160 : 140)
            }
        }
    }
    
    // MARK: - Detailed Stats List
    
    private var detailedStatsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(selectedPeriod == 2 ? "По месяцам" : "По дням")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            if selectedPeriod == 2 {
                // Для года показываем месяцы
                yearlyDetailedList
            } else {
                // Для недели и месяца показываем дни
                dailyDetailedList
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
    }
    
    private var dailyDetailedList: some View {
        let data = selectedPeriod == 0 ? healthManager.weeklySteps : healthManager.monthlySteps
        let sortedData = data.sorted { $0.date > $1.date }
        
        // Для месяца показываем только первые 7 дней, для недели - все
        let displayLimit = selectedPeriod == 1 ? 7 : sortedData.count
        let shouldShowMoreButton = selectedPeriod == 1 && sortedData.count > displayLimit
        let displayedData = showAllDays || selectedPeriod == 0 ? sortedData : Array(sortedData.prefix(displayLimit))
        
        return Group {
            if sortedData.isEmpty {
                Text("Нет данных")
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(displayedData) { dayData in
                        DetailedDayRow(
                            dayData: dayData,
                            stepGoal: healthManager.stepGoal,
                            accentGreen: accentGreen
                        )
                    }
                    
                    // Кнопка "Показать еще" / "Скрыть" для месяца
                    if shouldShowMoreButton {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showAllDays.toggle()
                            }
                            HapticManager.impact(style: .light)
                        } label: {
                            HStack(spacing: 8) {
                                Text(showAllDays ? "Скрыть" : "Показать еще")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(accentGreen)
                                
                                Image(systemName: showAllDays ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(accentGreen)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(accentGreen.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(accentGreen.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    private var yearlyDetailedList: some View {
        let data = healthManager.yearlySteps
        let sortedData = data.sorted { $0.date > $1.date }
        let displayLimit = 7
        let shouldShowMoreButton = sortedData.count > displayLimit
        let displayedData = showAllMonths ? sortedData : Array(sortedData.prefix(displayLimit))
        
        return Group {
            if sortedData.isEmpty {
                Text("Нет данных")
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(displayedData) { monthData in
                        DetailedMonthRow(
                            monthData: monthData,
                            stepGoal: healthManager.stepGoal * 30, // Примерная цель на месяц
                            accentGreen: accentGreen
                        )
                    }
                    
                    // Кнопка "Показать еще" / "Скрыть"
                    if shouldShowMoreButton {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showAllMonths.toggle()
                            }
                            HapticManager.impact(style: .light)
                        } label: {
                            HStack(spacing: 8) {
                                Text(showAllMonths ? "Скрыть" : "Показать еще")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(accentGreen)
                                
                                Image(systemName: showAllMonths ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(accentGreen)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(accentGreen.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(accentGreen.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    private var recordsView: some View {
        let data = healthManager.monthlySteps
        let maxDay = data.max(by: { $0.steps < $1.steps })
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Рекорды")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                VStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)
                    Text("\(maxDay?.steps ?? 0)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Макс. шагов")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 24))
                        .foregroundColor(.cyan)
                    Text(maxDay?.dateString ?? "-")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("Лучший день")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
    }
    
    // MARK: - Predictions and Comparison
    
    private var predictionsAndComparison: some View {
        let weekData = healthManager.weeklySteps
        let avgThisWeek = weekData.isEmpty ? 0 : weekData.reduce(0) { $0 + $1.steps } / weekData.count
        let avgLastWeek = getLastWeekAverage()
        
        let trend = avgThisWeek > avgLastWeek ? "up" : avgThisWeek < avgLastWeek ? "down" : "stable"
        let trendPercent = avgLastWeek > 0 ? abs(Int((Double(avgThisWeek - avgLastWeek) / Double(avgLastWeek)) * 100)) : 0
        
        // Прогноз достижения цели
        let currentSteps = healthManager.todaySteps
        let currentHour = Calendar.current.component(.hour, from: Date())
        let avgStepsPerHour = currentHour > 0 ? currentSteps / currentHour : 0
        let projectedSteps = avgStepsPerHour * 24
        let goalProgress = Double(currentSteps) / Double(healthManager.stepGoal)
        
        return VStack(spacing: 16) {
            // Сравнение с прошлой неделей
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Сравнение с прошлой неделей")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Image(systemName: trend == "up" ? "arrow.up.right" : trend == "down" ? "arrow.down.right" : "minus")
                            .foregroundColor(trend == "up" ? accentGreen : trend == "down" ? .red : .gray)
                        Text("\(trendPercent)%")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(trend == "up" ? accentGreen : trend == "down" ? .red : .white)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Эта неделя")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    Text(formatNumber(avgThisWeek))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            
            // Прогноз достижения цели
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(accentGreen)
                    Text("Прогноз на сегодня")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Прогнозируемые шаги")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                        Text("\(formatNumber(projectedSteps))")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(projectedSteps >= healthManager.stepGoal ? accentGreen : .white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Прогресс")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                        Text("\(Int(goalProgress * 100))%")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(accentGreen)
                    }
                }
                
                // Прогресс-бар прогноза
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(projectedSteps >= healthManager.stepGoal ? accentGreen : .orange)
                            .frame(width: geo.size.width * min(1.0, Double(projectedSteps) / Double(healthManager.stepGoal)), height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
    }
    
    // MARK: - Helper Functions
    
    private func getLastWeekAverage() -> Int {
        let calendar = Calendar.current
        let now = Date()
        guard let lastWeekStart = calendar.date(byAdding: .day, value: -14, to: now),
              let lastWeekEnd = calendar.date(byAdding: .day, value: -7, to: now) else {
            return 0
        }
        
        let lastWeekData = healthManager.weeklySteps.filter { dayData in
            dayData.date >= lastWeekStart && dayData.date < lastWeekEnd
        }
        
        guard !lastWeekData.isEmpty else { return 0 }
        return lastWeekData.reduce(0) { $0 + $1.steps } / lastWeekData.count
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000000 {
            return String(format: "%.1fM", Double(number) / 1000000)
        } else if number >= 1000 {
            return String(format: "%.0fK", Double(number) / 1000)
        }
        return "\(number)"
    }
    
    // MARK: - Leaders Section
    
    private var leadersSection: some View {
        Button {
            HapticManager.impact(style: .light)
            showLeaderboard = true
        } label: {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3), Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)
                            .blur(radius: 8)
                        
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.65, blue: 0.0)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6), radius: 8)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Лидеры")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Топ участников сегодня")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                // Топ-3 лидера
                if !leaderboardManager.entries.isEmpty {
                    HStack(spacing: 16) {
                        ForEach(Array(leaderboardManager.entries.prefix(3).enumerated()), id: \.element.id) { index, entry in
                            VStack(spacing: 10) {
                                // Медаль с пульсацией для первого места
                                ZStack {
                                    if index == 0 {
                                        Circle()
                                            .fill(
                                                RadialGradient(
                                                    colors: [Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4), Color.clear],
                                                    center: .center,
                                                    startRadius: 10,
                                                    endRadius: 30
                                                )
                                            )
                                            .frame(width: 60, height: 60)
                                    }
                                    
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: index == 0 ? [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.65, blue: 0.0)] :
                                                index == 1 ? [Color(red: 0.7, green: 0.7, blue: 0.7), Color(red: 0.5, green: 0.5, blue: 0.5)] :
                                                [Color(red: 0.9, green: 0.6, blue: 0.3), Color(red: 0.7, green: 0.4, blue: 0.15)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: index == 0 ? 52 : 48, height: index == 0 ? 52 : 48)
                                        .shadow(color: index == 0 ? Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.5) : Color.clear, radius: 12)
                                    
                                    Image(systemName: "medal.fill")
                                        .font(.system(size: index == 0 ? 26 : 22))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.3), radius: 2)
                                }
                                
                                // Имя
                                Text(entry.displayName)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .frame(maxWidth: 70)
                                
                                // Шаги
                                Text(formatNumber(entry.steps))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(accentGreen)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(accentGreen.opacity(0.15))
                                    )
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.top, 4)
                } else {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                        Spacer()
                    }
                    .padding(.vertical, 20)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4), .white.opacity(0.1), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.2), radius: 24, x: 0, y: 12)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
        }
        .buttonStyle(PlainButtonStyle())
            .onAppear {
            leaderboardManager.loadLeaderboard(scope: .global, period: .daily)
        }
    }
    
    // MARK: - Premium Promo Section
    
    private var premiumPromoSection: some View {
        Button {
            HapticManager.impact(style: .light)
            showPremium = true
        } label: {
            VStack(spacing: 20) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3), Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .blur(radius: 8)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.65, blue: 0.0)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6), radius: 8)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Детальная статистика")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Разблокируйте Premium для прогнозов и сравнений")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                HStack(spacing: 12) {
                    FeatureBadge(icon: "chart.line.uptrend.xyaxis", text: "Прогнозы")
                    FeatureBadge(icon: "arrow.triangle.2.circlepath", text: "Сравнения")
                    FeatureBadge(icon: "sparkles", text: "Аналитика")
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4), .white.opacity(0.1), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.2), radius: 24, x: 0, y: 12)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Feature Badge

struct FeatureBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .frame(width: 14)
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundColor(.white.opacity(0.8))
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Detailed Day Row

struct DetailedDayRow: View {
    let dayData: DailyStepData
    let stepGoal: Int
    let accentGreen: Color
    
    private var isGoalReached: Bool {
        dayData.steps >= stepGoal
    }
    
    private var progress: Double {
        min(1.0, Double(dayData.steps) / Double(stepGoal))
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Дата
            VStack(alignment: .leading, spacing: 4) {
                Text(dayData.dayString)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(dayData.dateString)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(width: 80, alignment: .leading)
            
            // Прогресс-бар
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isGoalReached ? accentGreen : Color.orange.opacity(0.7))
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            
            // Шаги
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(dayData.steps)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isGoalReached ? accentGreen : .white)
                
                if isGoalReached {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(accentGreen)
                } else {
                    Text("\(Int((1.0 - progress) * 100))% до цели")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isGoalReached ? accentGreen.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

// MARK: - Detailed Month Row

struct DetailedMonthRow: View {
    let monthData: MonthlyStepData
    let stepGoal: Int
    let accentGreen: Color
    
    private var isGoalReached: Bool {
        monthData.steps >= stepGoal
    }
    
    private var progress: Double {
        min(1.0, Double(monthData.steps) / Double(stepGoal))
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Месяц
            VStack(alignment: .leading, spacing: 4) {
                Text(monthData.fullMonthString)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(monthData.monthString)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(width: 120, alignment: .leading)
            
            // Прогресс-бар
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isGoalReached ? accentGreen : Color.orange.opacity(0.7))
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            
            // Шаги
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatNumber(monthData.steps))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isGoalReached ? accentGreen : .white)
                
                if isGoalReached {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(accentGreen)
                } else {
                    Text("\(Int((1.0 - progress) * 100))% до цели")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isGoalReached ? accentGreen.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000000 {
            return String(format: "%.1fM", Double(number) / 1000000)
        } else if number >= 1000 {
            return String(format: "%.0fK", Double(number) / 1000)
        }
        return "\(number)"
    }
}
