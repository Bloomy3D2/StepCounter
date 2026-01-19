//
//  HealthInsights.swift
//  StepCounter
//
//  Модели для продвинутой аналитики здоровья
//

import Foundation
import SwiftUI

// MARK: - Health Insight

struct HealthInsight: Identifiable {
    let id: UUID
    let type: InsightType
    let title: String
    let description: String
    let severity: Severity
    let date: Date
    let recommendation: String?
    
    init(
        type: InsightType,
        title: String,
        description: String,
        severity: Severity = .info,
        recommendation: String? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.description = description
        self.severity = severity
        self.date = Date()
        self.recommendation = recommendation
    }
}

// MARK: - Insight Type

enum InsightType: String, Codable {
    case pattern        // Анализ паттернов
    case prediction     // Прогнозы
    case correlation    // Корреляции
    case anomaly        // Аномалии
    case recommendation // Рекомендации
    case achievement    // Достижения
    
    var icon: String {
        switch self {
        case .pattern: return "chart.line.uptrend.xyaxis"
        case .prediction: return "crystal.ball"
        case .correlation: return "link"
        case .anomaly: return "exclamationmark.triangle"
        case .recommendation: return "lightbulb"
        case .achievement: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .pattern: return .blue
        case .prediction: return .purple
        case .correlation: return .cyan
        case .anomaly: return .orange
        case .recommendation: return .yellow
        case .achievement: return .green
        }
    }
}

// MARK: - Severity

enum Severity: String, Codable {
    case info       // Информация
    case positive   // Положительный
    case warning    // Предупреждение
    case critical   // Критический
    
    var icon: String {
        switch self {
        case .info: return "info.circle"
        case .positive: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .critical: return "xmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .positive: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Pattern Analysis

struct PatternAnalysis {
    let type: PatternType
    let description: String
    let strength: Double // 0.0 - 1.0
    let examples: [String]
    
    enum PatternType {
        case weekdayVsWeekend    // Рабочие дни vs выходные
        case timeOfDay           // Время дня
        case weeklyTrend         // Недельный тренд
        case monthlySeasonal     // Сезонность по месяцам
    }
}

// MARK: - Prediction

struct HealthPrediction {
    let metric: PredictionMetric
    let currentValue: Double
    let predictedValue: Double
    let timeFrame: TimeFrame
    let confidence: Double // 0.0 - 1.0
    let description: String
    
    enum PredictionMetric {
        case steps
        case distance
        case calories
        case weightLoss
        case streakDays
    }
    
    enum TimeFrame {
        case week
        case month
        case quarter
        case year
    }
}

// MARK: - Correlation

struct HealthCorrelation {
    let factor1: CorrelationFactor
    let factor2: CorrelationFactor
    let correlationCoefficient: Double // -1.0 до 1.0
    let description: String
    let significance: Double // 0.0 - 1.0
    
    enum CorrelationFactor {
        case sleep          // Сон
        case weather        // Погода
        case mood           // Настроение
        case weekday        // День недели
        case timeOfDay      // Время дня
        case heartRate      // Пульс
        case calories       // Калории
        case distance       // Дистанция
        case steps          // Шаги
    }
}

// MARK: - Anomaly Detection

struct AnomalyDetection {
    let type: AnomalyType
    let detectedDate: Date
    let normalRange: (min: Double, max: Double)
    let actualValue: Double
    let severity: Severity
    let description: String
    let suggestion: String?
    
    enum AnomalyType {
        case suddenDrop      // Резкое снижение активности
        case suddenIncrease  // Резкое увеличение активности
        case inactivity      // Неактивность
        case unusualTime     // Необычное время активности
    }
}

// MARK: - Trend Analysis

struct TrendAnalysis {
    let period: Period
    let metric: TrendMetric
    let trend: TrendDirection
    let changePercent: Double
    let description: String
    
    enum Period {
        case week
        case month
        case quarter
        case year
    }
    
    enum TrendMetric {
        case steps
        case distance
        case calories
        case activeDays
        case averageSpeed
    }
    
    enum TrendDirection {
        case increasing
        case decreasing
        case stable
    }
}

// MARK: - SMART Goal Recommendation

struct SMARTGoalRecommendation {
    let currentGoal: Int
    let recommendedGoal: Int
    let reason: String
    let timeFrame: String // "на следующую неделю"
    let confidence: Double
    
    var changePercent: Double {
        guard currentGoal > 0 else { return 0 }
        return Double(recommendedGoal - currentGoal) / Double(currentGoal) * 100
    }
}
