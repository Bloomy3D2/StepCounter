//
//  HealthInsightsView.swift
//  StepCounter
//
//  Экран продвинутой аналитики здоровья
//

import SwiftUI

struct HealthInsightsView: View {
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var achievementManager: AchievementManager
    @StateObject private var insightsManager = HealthInsightsManager()
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var selectedInsight: HealthInsight?
    @State private var selectedTab: Tab = .insights
    
    enum Tab: String, CaseIterable {
        case insights = "Инсайты"
        case predictions = "Прогнозы"
        case patterns = "Паттерны"
        case trends = "Тренды"
    }
    
    private var bgColor: Color { themeManager.backgroundColor }
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.currentTheme.accentColors.primaryColor }
    private var accentBlue: Color { themeManager.currentTheme.accentColors.secondaryColor }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Переключатель вкладок
                tabPicker
                
                ScrollView {
                    VStack(spacing: 24) {
                        switch selectedTab {
                        case .insights:
                            insightsContent
                        case .predictions:
                            predictionsContent
                        case .patterns:
                            patternsContent
                        case .trends:
                            trendsContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .ignoresSafeArea()
            )
            .navigationTitle("Аналитика")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                analyzeData()
            }
            .onChange(of: healthManager.todaySteps) { _, _ in
                analyzeData()
            }
            .sheet(item: $selectedInsight) { insight in
                InsightDetailView(insight: insight)
            }
        }
    }
    
    // MARK: - Tab Picker
    
    private var tabPicker: some View {
        Picker("Вкладка", selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    // MARK: - Insights Content
    
    private var insightsContent: some View {
        VStack(spacing: 16) {
            if insightsManager.insights.isEmpty {
                emptyInsightsState
            } else {
                ForEach(insightsManager.insights.prefix(10)) { insight in
                    InsightCard(insight: insight) {
                        selectedInsight = insight
                    }
                }
            }
        }
    }
    
    // MARK: - Predictions Content
    
    private var predictionsContent: some View {
        VStack(spacing: 16) {
            if insightsManager.predictions.isEmpty {
                emptyState(message: "Недостаточно данных для прогнозов")
            } else {
                ForEach(insightsManager.predictions, id: \.description) { prediction in
                    PredictionCard(prediction: prediction)
                }
            }
            
            // Рекомендация цели
            if let goalRec = insightsManager.goalRecommendations {
                GoalRecommendationCard(recommendation: goalRec)
            }
        }
    }
    
    // MARK: - Patterns Content
    
    private var patternsContent: some View {
        VStack(spacing: 16) {
            if insightsManager.patternAnalyses.isEmpty {
                emptyState(message: "Паттерны будут обнаружены после анализа данных")
            } else {
                ForEach(insightsManager.patternAnalyses, id: \.description) { pattern in
                    PatternCard(pattern: pattern)
                }
            }
            
            // Корреляции
            if !insightsManager.correlations.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Корреляции")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    ForEach(insightsManager.correlations, id: \.description) { correlation in
                        CorrelationCard(correlation: correlation)
                    }
                }
            }
        }
    }
    
    // MARK: - Trends Content
    
    private var trendsContent: some View {
        VStack(spacing: 16) {
            if insightsManager.trends.isEmpty {
                emptyState(message: "Тренды будут доступны после накопления данных")
            } else {
                ForEach(insightsManager.trends, id: \.description) { trend in
                    TrendCard(trend: trend)
                }
            }
            
            // Аномалии
            if !insightsManager.anomalies.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Обнаруженные аномалии")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    ForEach(insightsManager.anomalies, id: \.detectedDate) { anomaly in
                        AnomalyCard(anomaly: anomaly)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty States
    
    private var emptyInsightsState: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(accentBlue.opacity(0.6))
            
            Text("Нет инсайтов")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("Инсайты появятся после анализа вашей активности")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    private func emptyState(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 50))
                .foregroundColor(accentBlue.opacity(0.6))
            
            Text(message)
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    // MARK: - Helper Methods
    
    private func analyzeData() {
        insightsManager.analyzeData(
            dailySteps: healthManager.weeklySteps,
            monthlySteps: healthManager.yearlySteps,
            hourlySteps: healthManager.hourlySteps,
            currentSteps: healthManager.todaySteps,
            currentDistance: healthManager.todayDistance,
            currentCalories: healthManager.todayCalories,
            streak: achievementManager.currentStreak
        )
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let insight: HealthInsight
    let onTap: () -> Void
    
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: insight.type.icon)
                    .font(.title2)
                    .foregroundColor(insight.type.color)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(insight.type.color.opacity(0.2))
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(insight.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: insight.severity.icon)
                            .font(.caption)
                            .foregroundColor(insight.severity.color)
                    }
                    
                    Text(insight.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                    
                    if let recommendation = insight.recommendation {
                        Text(recommendation)
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.accentColors.primaryColor)
                            .lineLimit(1)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Prediction Card

struct PredictionCard: View {
    let prediction: HealthPrediction
    
    private var timeFrameText: String {
        switch prediction.timeFrame {
        case .week: return "на следующую неделю"
        case .month: return "на следующий месяц"
        case .quarter: return "на следующий квартал"
        case .year: return "на следующий год"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "crystal.ball.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Text("Прогноз")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(prediction.confidence * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.2))
                    )
            }
            
            Text(prediction.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Текущее значение")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text(formatNumber(Int(prediction.currentValue)))
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Прогноз \(timeFrameText)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text(formatNumber(Int(prediction.predictedValue)))
                        .font(.headline)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Pattern Card

struct PatternCard: View {
    let pattern: PatternAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Обнаружен паттерн")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Text(pattern.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
            
            // Примеры
            VStack(alignment: .leading, spacing: 4) {
                ForEach(pattern.examples, id: \.self) { example in
                    Text("• \(example)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.top, 8)
            
            // Сила паттерна
            HStack {
                Text("Сила паттерна")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                ProgressView(value: pattern.strength)
                    .tint(.blue)
                Text("\(Int(pattern.strength * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .frame(width: 40)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Correlation Card

struct CorrelationCard: View {
    let correlation: HealthCorrelation
    
    var body: some View {
        HStack {
            Image(systemName: "link")
                .font(.title3)
                .foregroundColor(.cyan)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(correlation.description)
                    .font(.body)
                    .foregroundColor(.white)
                
                Text("Значимость: \(Int(correlation.significance * 100))%")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Trend Card

struct TrendCard: View {
    let trend: TrendAnalysis
    
    private var trendIcon: String {
        switch trend.trend {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "minus"
        }
    }
    
    private var trendColor: Color {
        switch trend.trend {
        case .increasing: return .green
        case .decreasing: return .orange
        case .stable: return .gray
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: trendIcon)
                .font(.title2)
                .foregroundColor(trendColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(trend.description)
                    .font(.body)
                    .foregroundColor(.white)
                
                Text("Изменение: \(String(format: "%.1f", trend.changePercent))%")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Anomaly Card

struct AnomalyCard: View {
    let anomaly: AnomalyDetection
    
    var body: some View {
        HStack {
            Image(systemName: anomaly.severity.icon)
                .font(.title2)
                .foregroundColor(anomaly.severity.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(anomaly.description)
                    .font(.body)
                    .foregroundColor(.white)
                
                if let suggestion = anomaly.suggestion {
                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(anomaly.severity.color)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Goal Recommendation Card

struct GoalRecommendationCard: View {
    let recommendation: SMARTGoalRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("Рекомендация цели")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Text(recommendation.reason)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Текущая цель")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text(formatNumber(recommendation.currentGoal))
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                if recommendation.recommendedGoal != recommendation.currentGoal {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.white.opacity(0.5))
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Рекомендуемая")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text(formatNumber(recommendation.recommendedGoal))
                            .font(.headline)
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.yellow.opacity(0.5), lineWidth: 2)
                )
        )
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Insight Detail View

struct InsightDetailView: View {
    let insight: HealthInsight
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Заголовок
                    HStack {
                        Image(systemName: insight.type.icon)
                            .font(.largeTitle)
                            .foregroundColor(insight.type.color)
                        
                        VStack(alignment: .leading) {
                            Text(insight.title)
                                .font(.title2.bold())
                            Text(insight.type.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Описание
                    Text(insight.description)
                        .font(.body)
                    
                    // Рекомендация
                    if let recommendation = insight.recommendation {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Рекомендация")
                                .font(.headline)
                            Text(recommendation)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.gray.opacity(0.1))
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Инсайт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}
