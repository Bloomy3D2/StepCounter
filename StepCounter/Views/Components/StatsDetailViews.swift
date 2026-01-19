//
//  StatsDetailViews.swift
//  StepCounter
//
//  Детальные view для статистики (премиум функция)
//

import SwiftUI

// MARK: - Distance Detail View

@MainActor
struct DistanceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var healthManager: HealthManager
    let accentBlue: Color
    
    private var weeklyTotal: Double {
        healthManager.weeklySteps.reduce(0) { $0 + Double($1.steps) * 0.0008 } // Примерно 0.8 метра на шаг
    }
    
    private var monthlyTotal: Double {
        healthManager.monthlySteps.reduce(0) { $0 + Double($1.steps) * 0.0008 }
    }
    
    private var averagePerDay: Double {
        guard !healthManager.weeklySteps.isEmpty else { return 0 }
        return weeklyTotal / Double(healthManager.weeklySteps.count)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Основная карточка с прогресс-кольцом
                    ZStack {
                        GlassCard(cornerRadius: 24, padding: 32, glowColor: accentBlue.opacity(0.4)) {
                            VStack(spacing: 24) {
                                // Иконка с анимацией
                                ZStack {
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                colors: [
                                                    accentBlue.opacity(0.3),
                                                    accentBlue.opacity(0.1),
                                                    .clear
                                                ],
                                                center: .center,
                                                startRadius: 20,
                                                endRadius: 60
                                            )
                                        )
                                        .frame(width: 120, height: 120)
                                    
                                    Image(systemName: "figure.walk")
                                        .font(.system(size: 56, weight: .semibold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [accentBlue, accentBlue.opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                
                                // Значение
                                VStack(spacing: 8) {
                                    Text(String(format: "%.2f", healthManager.todayDistance / 1000))
                                        .font(.system(size: 56, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Text("км")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text("Дистанция сегодня")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                    }
                    
                    // Статистические карточки
                    VStack(spacing: 16) {
                        EnhancedStatCard(
                            icon: "calendar",
                            label: "Среднее за неделю",
                            value: String(format: "%.2f км", averagePerDay),
                            color: accentBlue,
                            trend: nil
                        )
                        
                        EnhancedStatCard(
                            icon: "chart.bar.fill",
                            label: "Всего за неделю",
                            value: String(format: "%.2f км", weeklyTotal),
                            color: accentBlue,
                            trend: nil
                        )
                        
                        EnhancedStatCard(
                            icon: "calendar.badge.clock",
                            label: "Всего за месяц",
                            value: String(format: "%.2f км", monthlyTotal),
                            color: accentBlue,
                            trend: nil
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(
                AnimatedGradientBackground(theme: ThemeManager.shared.currentTheme)
                .ignoresSafeArea()
            )
            .navigationTitle("Дистанция")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Calories Detail View

@MainActor
struct CaloriesDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var healthManager: HealthManager
    let accentOrange: Color
    
    private var weeklyTotal: Int {
        healthManager.weeklySteps.reduce(0) { $0 + Int(Double($1.steps) * 0.04) } // Примерно 0.04 калории на шаг
    }
    
    private var monthlyTotal: Int {
        healthManager.monthlySteps.reduce(0) { $0 + Int(Double($1.steps) * 0.04) }
    }
    
    private var averagePerDay: Int {
        guard !healthManager.weeklySteps.isEmpty else { return 0 }
        return weeklyTotal / healthManager.weeklySteps.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Основная карточка с прогресс-кольцом
                    ZStack {
                        GlassCard(cornerRadius: 24, padding: 32, glowColor: accentOrange.opacity(0.4)) {
                            VStack(spacing: 24) {
                                // Иконка с анимацией
                                ZStack {
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                colors: [
                                                    accentOrange.opacity(0.3),
                                                    accentOrange.opacity(0.1),
                                                    .clear
                                                ],
                                                center: .center,
                                                startRadius: 20,
                                                endRadius: 60
                                            )
                                        )
                                        .frame(width: 120, height: 120)
                                    
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 56, weight: .semibold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [accentOrange, accentOrange.opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                
                                // Значение
                                VStack(spacing: 8) {
                                    Text("\(Int(healthManager.todayCalories))")
                                        .font(.system(size: 56, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Text("ккал")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text("Сожжено сегодня")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                    }
                    
                    // Статистические карточки
                    VStack(spacing: 16) {
                        EnhancedStatCard(
                            icon: "calendar",
                            label: "Среднее за неделю",
                            value: "\(averagePerDay) ккал",
                            color: accentOrange,
                            trend: nil
                        )
                        
                        EnhancedStatCard(
                            icon: "chart.bar.fill",
                            label: "Всего за неделю",
                            value: "\(weeklyTotal) ккал",
                            color: accentOrange,
                            trend: nil
                        )
                        
                        EnhancedStatCard(
                            icon: "calendar.badge.clock",
                            label: "Всего за месяц",
                            value: "\(monthlyTotal) ккал",
                            color: accentOrange,
                            trend: nil
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(
                AnimatedGradientBackground(theme: ThemeManager.shared.currentTheme)
                .ignoresSafeArea()
            )
            .navigationTitle("Калории")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Activity Detail View

@MainActor
struct ActivityDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var healthManager: HealthManager
    let accentGreen: Color
    
    private var weeklyTotal: Int {
        healthManager.weeklySteps.reduce(0) { $0 + Int(Double($1.steps) / 100.0) } // Примерно 1 минута на 100 шагов
    }
    
    private var monthlyTotal: Int {
        healthManager.monthlySteps.reduce(0) { $0 + Int(Double($1.steps) / 100.0) }
    }
    
    private var averagePerDay: Int {
        guard !healthManager.weeklySteps.isEmpty else { return 0 }
        return weeklyTotal / healthManager.weeklySteps.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Основная карточка с прогресс-кольцом
                    ZStack {
                        GlassCard(cornerRadius: 24, padding: 32, glowColor: accentGreen.opacity(0.4)) {
                            VStack(spacing: 24) {
                                // Иконка с анимацией
                                ZStack {
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                colors: [
                                                    accentGreen.opacity(0.3),
                                                    accentGreen.opacity(0.1),
                                                    .clear
                                                ],
                                                center: .center,
                                                startRadius: 20,
                                                endRadius: 60
                                            )
                                        )
                                        .frame(width: 120, height: 120)
                                    
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 56, weight: .semibold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [accentGreen, accentGreen.opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                
                                // Значение
                                VStack(spacing: 8) {
                                    Text("\(healthManager.todayActiveMinutes)")
                                        .font(.system(size: 56, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Text("минут")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text("Активности сегодня")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                    }
                    
                    // Статистические карточки
                    VStack(spacing: 16) {
                        EnhancedStatCard(
                            icon: "calendar",
                            label: "Среднее за неделю",
                            value: "\(averagePerDay) мин",
                            color: accentGreen,
                            trend: nil
                        )
                        
                        EnhancedStatCard(
                            icon: "chart.bar.fill",
                            label: "Всего за неделю",
                            value: "\(weeklyTotal) мин",
                            color: accentGreen,
                            trend: nil
                        )
                        
                        EnhancedStatCard(
                            icon: "calendar.badge.clock",
                            label: "Всего за месяц",
                            value: "\(monthlyTotal) мин",
                            color: accentGreen,
                            trend: nil
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(
                AnimatedGradientBackground(theme: ThemeManager.shared.currentTheme)
                    .ignoresSafeArea()
            )
            .navigationTitle("Активность")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Average Detail View

@MainActor
struct AverageDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var healthManager: HealthManager
    let accentPurple: Color
    
    private var weeklyAverage: Int {
        guard !healthManager.weeklySteps.isEmpty else { return 0 }
        let total = healthManager.weeklySteps.reduce(0) { $0 + $1.steps }
        return total / healthManager.weeklySteps.count
    }
    
    private var monthlyAverage: Int {
        guard !healthManager.monthlySteps.isEmpty else { return 0 }
        let total = healthManager.monthlySteps.reduce(0) { $0 + $1.steps }
        return total / healthManager.monthlySteps.count
    }
    
    private var yearlyAverage: Int {
        guard !healthManager.yearlySteps.isEmpty else { return 0 }
        let total = healthManager.yearlySteps.reduce(0) { $0 + $1.steps }
        return total / healthManager.yearlySteps.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Основная карточка с прогресс-кольцом
                    ZStack {
                        GlassCard(cornerRadius: 24, padding: 32, glowColor: accentPurple.opacity(0.4)) {
                            VStack(spacing: 24) {
                                // Иконка с анимацией
                                ZStack {
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                colors: [
                                                    accentPurple.opacity(0.3),
                                                    accentPurple.opacity(0.1),
                                                    .clear
                                                ],
                                                center: .center,
                                                startRadius: 20,
                                                endRadius: 60
                                            )
                                        )
                                        .frame(width: 120, height: 120)
                                    
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 56, weight: .semibold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [accentPurple, accentPurple.opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                
                                // Значение
                                VStack(spacing: 8) {
                                    Text("\(weeklyAverage)")
                                        .font(.system(size: 56, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Text("шагов")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text("Среднее в день (неделя)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                    }
                    
                    // Статистические карточки
                    VStack(spacing: 16) {
                        EnhancedStatCard(
                            icon: "calendar",
                            label: "Среднее за неделю",
                            value: "\(weeklyAverage) шагов",
                            color: accentPurple,
                            trend: nil
                        )
                        
                        EnhancedStatCard(
                            icon: "chart.bar.fill",
                            label: "Среднее за месяц",
                            value: "\(monthlyAverage) шагов",
                            color: accentPurple,
                            trend: nil
                        )
                        
                        EnhancedStatCard(
                            icon: "calendar.badge.clock",
                            label: "Среднее за год",
                            value: "\(yearlyAverage) шагов",
                            color: accentPurple,
                            trend: nil
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(
                AnimatedGradientBackground(theme: ThemeManager.shared.currentTheme)
                .ignoresSafeArea()
            )
            .navigationTitle("Среднее")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Stat Row Component

// MARK: - Enhanced Stat Card

struct EnhancedStatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    let trend: String?
    
    init(icon: String, label: String, value: String, color: Color, trend: String? = nil) {
        self.icon = icon
        self.label = label
        self.value = value
        self.color = color
        self.trend = trend
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Иконка в круге
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.2),
                                color.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
            }
            
            // Текст
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                if let trend = trend {
                    HStack(spacing: 4) {
                        Image(systemName: trend.contains("↑") ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10))
                        Text(trend)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(trend.contains("↑") ? Color.green : Color.red)
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.4),
                                    color.opacity(0.1),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: color.opacity(0.2), radius: 15, x: 0, y: 8)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Stat Row Component (Legacy, для совместимости)

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32)
            
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.vertical, 8)
    }
}
