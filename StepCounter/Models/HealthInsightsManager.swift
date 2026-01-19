//
//  HealthInsightsManager.swift
//  StepCounter
//
//  Менеджер продвинутой аналитики здоровья
//

import Foundation
import SwiftUI
import Combine

/// Менеджер Health Insights - продвинутая аналитика и прогнозы
final class HealthInsightsManager: ObservableObject {
    
    @Published var insights: [HealthInsight] = []
    @Published var patternAnalyses: [PatternAnalysis] = []
    @Published var predictions: [HealthPrediction] = []
    @Published var correlations: [HealthCorrelation] = []
    @Published var anomalies: [AnomalyDetection] = []
    @Published var trends: [TrendAnalysis] = []
    @Published var goalRecommendations: SMARTGoalRecommendation?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    /// Анализировать все данные и генерировать insights
    func analyzeData(
        dailySteps: [DailyStepData],
        monthlySteps: [MonthlyStepData],
        hourlySteps: [HourlyStepData],
        currentSteps: Int,
        currentDistance: Double,
        currentCalories: Double,
        streak: Int
    ) {
        // Очищаем старые данные
        insights.removeAll()
        
        // Выполняем различные виды анализа
        analyzePatterns(dailySteps: dailySteps, monthlySteps: monthlySteps, hourlySteps: hourlySteps)
        generatePredictions(dailySteps: dailySteps, currentSteps: currentSteps)
        detectCorrelations(dailySteps: dailySteps, hourlySteps: hourlySteps)
        detectAnomalies(dailySteps: dailySteps, currentSteps: currentSteps)
        analyzeTrends(dailySteps: dailySteps, monthlySteps: monthlySteps)
        recommendGoals(dailySteps: dailySteps, currentSteps: currentSteps)
        
        // Генерируем insights из результатов анализа
        generateInsights()
    }
    
    // MARK: - Pattern Analysis
    
    private func analyzePatterns(
        dailySteps: [DailyStepData],
        monthlySteps: [MonthlyStepData],
        hourlySteps: [HourlyStepData]
    ) {
        patternAnalyses.removeAll()
        
        // Анализ: Рабочие дни vs выходные
        let weekdaySteps = dailySteps.filter { isWeekday($0.date) }
        let weekendSteps = dailySteps.filter { !isWeekday($0.date) }
        
        if !weekdaySteps.isEmpty && !weekendSteps.isEmpty {
            let weekdayAvg = weekdaySteps.reduce(0) { $0 + $1.steps } / weekdaySteps.count
            let weekendAvg = weekendSteps.reduce(0) { $0 + $1.steps } / weekendSteps.count
            
            if abs(weekdayAvg - weekendAvg) > 1000 {
                let strength = min(1.0, abs(weekdayAvg - weekendAvg) / 10000.0)
                let isWeekendHigher = weekendAvg > weekdayAvg
                
                let pattern = PatternAnalysis(
                    type: .weekdayVsWeekend,
                    description: isWeekendHigher
                        ? "Вы активнее на \(weekendAvg - weekdayAvg) шагов в выходные дни"
                        : "Вы активнее на \(weekdayAvg - weekendAvg) шагов в рабочие дни",
                    strength: strength,
                    examples: [
                        "Средние шаги в рабочие дни: \(formatNumber(weekdayAvg))",
                        "Средние шаги в выходные: \(formatNumber(weekendAvg))"
                    ]
                )
                patternAnalyses.append(pattern)
            }
        }
        
        // Анализ времени дня
        if !hourlySteps.isEmpty {
            let morningSteps = hourlySteps.filter { $0.hour >= 6 && $0.hour < 12 }.reduce(0) { $0 + $1.steps }
            let afternoonSteps = hourlySteps.filter { $0.hour >= 12 && $0.hour < 18 }.reduce(0) { $0 + $1.steps }
            let eveningSteps = hourlySteps.filter { $0.hour >= 18 && $0.hour < 22 }.reduce(0) { $0 + $1.steps }
            
            let maxPeriod = max(morningSteps, afternoonSteps, eveningSteps)
            let totalSteps = morningSteps + afternoonSteps + eveningSteps
            
            if totalSteps > 0 {
                let bestTime = maxPeriod == morningSteps ? "утро" : (maxPeriod == afternoonSteps ? "день" : "вечер")
                let strength = Double(maxPeriod) / Double(totalSteps)
                
                let pattern = PatternAnalysis(
                    type: .timeOfDay,
                    description: "Вы наиболее активны в \(bestTime)",
                    strength: strength,
                    examples: [
                        "Утро (6-12): \(formatNumber(morningSteps)) шагов",
                        "День (12-18): \(formatNumber(afternoonSteps)) шагов",
                        "Вечер (18-22): \(formatNumber(eveningSteps)) шагов"
                    ]
                )
                patternAnalyses.append(pattern)
            }
        }
    }
    
    // MARK: - Predictions
    
    private func generatePredictions(dailySteps: [DailyStepData], currentSteps: Int) {
        predictions.removeAll()
        
        guard dailySteps.count >= 7 else { return }
        
        // Прогноз на следующую неделю
        let last7Days = Array(dailySteps.suffix(7))
        let avgSteps = last7Days.reduce(0) { $0 + $1.steps } / last7Days.count
        let weeklyPrediction = avgSteps * 7
        
        let trend = calculateTrend(last7Days)
        let confidence = calculatePredictionConfidence(dailySteps: last7Days)
        
        let prediction = HealthPrediction(
            metric: .steps,
            currentValue: Double(currentSteps),
            predictedValue: Double(weeklyPrediction),
            timeFrame: .week,
            confidence: confidence,
            description: trend > 0
                ? "При текущем темпе вы пройдёте примерно \(formatNumber(weeklyPrediction)) шагов за следующую неделю"
                : "При сохранении текущего темпа вы пройдёте примерно \(formatNumber(weeklyPrediction)) шагов за следующую неделю"
        )
        predictions.append(prediction)
        
        // Прогноз на месяц
        if dailySteps.count >= 14 {
            let last14Days = Array(dailySteps.suffix(14))
            let monthlyAvg = last14Days.reduce(0) { $0 + $1.steps } / last14Days.count
            let monthlyPrediction = monthlyAvg * 30
            
            let prediction2 = HealthPrediction(
                metric: .steps,
                currentValue: Double(currentSteps),
                predictedValue: Double(monthlyPrediction),
                timeFrame: .month,
                confidence: min(confidence, 0.8),
                description: "При текущем темпе вы пройдёте примерно \(formatNumber(monthlyPrediction)) шагов за месяц"
            )
            predictions.append(prediction2)
        }
    }
    
    // MARK: - Correlations
    
    private func detectCorrelations(dailySteps: [DailyStepData], hourlySteps: [HourlyStepData]) {
        correlations.removeAll()
        
        guard dailySteps.count >= 7 else { return }
        
        // Анализ корреляции: день недели
        let weekdaySteps = dailySteps.filter { isWeekday($0.date) }
        let weekendSteps = dailySteps.filter { !isWeekday($0.date) }
        
        if !weekdaySteps.isEmpty && !weekendSteps.isEmpty {
            let weekdayAvg = Double(weekdaySteps.reduce(0) { $0 + $1.steps }) / Double(weekdaySteps.count)
            let weekendAvg = Double(weekendSteps.reduce(0) { $0 + $1.steps }) / Double(weekendSteps.count)
            
            let diff = abs(weekdayAvg - weekendAvg)
            let avg = (weekdayAvg + weekendAvg) / 2
            
            if avg > 0 {
                let correlation = diff / avg
                
                if correlation > 0.2 {
                    let correlationObj = HealthCorrelation(
                        factor1: .weekday,
                        factor2: .steps,
                        correlationCoefficient: correlation > 0.5 ? 0.7 : 0.5,
                        description: weekendAvg > weekdayAvg
                            ? "Ваша активность выше на \(Int((correlation * 100)))% в выходные дни"
                            : "Ваша активность выше на \(Int((correlation * 100)))% в рабочие дни",
                        significance: min(correlation, 1.0)
                    )
                    correlations.append(correlationObj)
                }
            }
        }
    }
    
    // MARK: - Anomaly Detection
    
    private func detectAnomalies(dailySteps: [DailyStepData], currentSteps: Int) {
        anomalies.removeAll()
        
        guard dailySteps.count >= 7 else { return }
        
        // Вычисляем нормальный диапазон
        let last7Days = Array(dailySteps.suffix(7))
        let avgSteps = Double(last7Days.reduce(0) { $0 + $1.steps }) / Double(last7Days.count)
        let variance = last7Days.map { pow(Double($0.steps) - avgSteps, 2) }.reduce(0, +) / Double(last7Days.count)
        let stdDev = sqrt(variance)
        
        let normalMin = avgSteps - 2 * stdDev
        let normalMax = avgSteps + 2 * stdDev
        
        // Проверяем текущий день на аномалию
        if Double(currentSteps) < normalMin && currentSteps > 0 {
            let anomaly = AnomalyDetection(
                type: .suddenDrop,
                detectedDate: Date(),
                normalRange: (normalMin, normalMax),
                actualValue: Double(currentSteps),
                severity: abs(Double(currentSteps) - normalMin) > 5000 ? .critical : .warning,
                description: "Ваша активность сегодня ниже обычного на \(Int(avgSteps - Double(currentSteps))) шагов",
                suggestion: "Может быть хорошее время для короткой прогулки?"
            )
            anomalies.append(anomaly)
        } else if Double(currentSteps) > normalMax {
            let anomaly = AnomalyDetection(
                type: .suddenIncrease,
                detectedDate: Date(),
                normalRange: (normalMin, normalMax),
                actualValue: Double(currentSteps),
                severity: .positive,
                description: "Отличная работа! Вы прошли на \(Int(Double(currentSteps) - avgSteps)) шагов больше обычного! 🎉",
                suggestion: nil
            )
            anomalies.append(anomaly)
        }
        
        // Проверяем неактивность (несколько дней подряд низкая активность)
        let recentLowDays = last7Days.filter { $0.steps < normalMin }.count
        if recentLowDays >= 3 {
            let anomaly = AnomalyDetection(
                type: .inactivity,
                detectedDate: Date(),
                normalRange: (normalMin, normalMax),
                actualValue: avgSteps,
                severity: .warning,
                description: "За последнюю неделю у вас было \(recentLowDays) дней с низкой активностью",
                suggestion: "Попробуйте установить небольшую ежедневную цель и постепенно её увеличивать"
            )
            anomalies.append(anomaly)
        }
    }
    
    // MARK: - Trend Analysis
    
    private func analyzeTrends(dailySteps: [DailyStepData], monthlySteps: [MonthlyStepData]) {
        trends.removeAll()
        
        // Недельный тренд
        if dailySteps.count >= 14 {
            let firstWeek = Array(dailySteps.prefix(7))
            let lastWeek = Array(dailySteps.suffix(7))
            
            let firstWeekAvg = firstWeek.reduce(0) { $0 + $1.steps } / firstWeek.count
            let lastWeekAvg = lastWeek.reduce(0) { $0 + $1.steps } / lastWeek.count
            
            let change = Double(lastWeekAvg - firstWeekAvg) / Double(max(firstWeekAvg, 1)) * 100
            let direction: TrendAnalysis.TrendDirection = change > 5 ? .increasing : (change < -5 ? .decreasing : .stable)
            
            let trend = TrendAnalysis(
                period: .week,
                metric: .steps,
                trend: direction,
                changePercent: abs(change),
                description: direction == .increasing
                    ? "Ваша активность выросла на \(String(format: "%.1f", abs(change)))% за последнюю неделю"
                    : direction == .decreasing
                    ? "Ваша активность снизилась на \(String(format: "%.1f", abs(change)))% за последнюю неделю"
                    : "Ваша активность остаётся стабильной"
            )
            trends.append(trend)
        }
        
        // Месячный тренд
        if monthlySteps.count >= 2 {
            let firstMonth = monthlySteps.first!
            let lastMonth = monthlySteps.last!
            
            let change = Double(lastMonth.steps - firstMonth.steps) / Double(max(firstMonth.steps, 1)) * 100
            let direction: TrendAnalysis.TrendDirection = change > 5 ? .increasing : (change < -5 ? .decreasing : .stable)
            
            let trend = TrendAnalysis(
                period: .month,
                metric: .steps,
                trend: direction,
                changePercent: abs(change),
                description: direction == .increasing
                    ? "Ваша активность выросла на \(String(format: "%.1f", abs(change)))% по сравнению с прошлым месяцем"
                    : direction == .decreasing
                    ? "Ваша активность снизилась на \(String(format: "%.1f", abs(change)))% по сравнению с прошлым месяцем"
                    : "Ваша активность остаётся стабильной"
            )
            trends.append(trend)
        }
    }
    
    // MARK: - Goal Recommendations
    
    private func recommendGoals(dailySteps: [DailyStepData], currentSteps: Int) {
        guard dailySteps.count >= 7 else {
            goalRecommendations = nil
            return
        }
        
        let last7Days = Array(dailySteps.suffix(7))
        let avgSteps = last7Days.reduce(0) { $0 + $1.steps } / last7Days.count
        let maxSteps = last7Days.map { $0.steps }.max() ?? 0
        
        // Рекомендуем цель на основе среднего значения с небольшим увеличением
        let recommendedGoal: Int
        if avgSteps < 5000 {
            recommendedGoal = 5000
        } else if avgSteps < 10000 {
            // Увеличиваем цель на 10-20%
            recommendedGoal = Int(Double(avgSteps) * 1.15)
        } else {
            // Для активных пользователей - цель выше среднего, но достижимая
            recommendedGoal = Int(Double(avgSteps) * 1.1)
        }
        
        // Округляем до тысячи
        let roundedGoal = (recommendedGoal / 1000) * 1000
        
        let reason: String
        if roundedGoal > currentSteps {
            reason = "Ваш средний результат за неделю \(formatNumber(avgSteps)) шагов. Цель \(formatNumber(roundedGoal)) шагов будет мотивирующей и достижимой."
        } else {
            reason = "Ваша текущая цель \(formatNumber(currentSteps)) шагов оптимальна для вашего уровня активности."
        }
        
        goalRecommendations = SMARTGoalRecommendation(
            currentGoal: currentSteps,
            recommendedGoal: roundedGoal,
            reason: reason,
            timeFrame: "на следующую неделю",
            confidence: 0.75
        )
    }
    
    // MARK: - Generate Insights
    
    private func generateInsights() {
        // Генерируем insights из результатов анализа
        
        // Pattern insights
        for pattern in patternAnalyses {
            let insight = HealthInsight(
                type: .pattern,
                title: "Обнаружен паттерн",
                description: pattern.description,
                severity: .info,
                recommendation: "Используйте этот паттерн для планирования активности"
            )
            insights.append(insight)
        }
        
        // Prediction insights
        for prediction in predictions {
            let insight = HealthInsight(
                type: .prediction,
                title: "Прогноз активности",
                description: prediction.description,
                severity: .info,
                recommendation: nil
            )
            insights.append(insight)
        }
        
        // Correlation insights
        for correlation in correlations {
            let insight = HealthInsight(
                type: .correlation,
                title: "Обнаружена корреляция",
                description: correlation.description,
                severity: .info,
                recommendation: "Учитывайте этот фактор при планировании активности"
            )
            insights.append(insight)
        }
        
        // Anomaly insights
        for anomaly in anomalies {
            let insight = HealthInsight(
                type: .anomaly,
                title: anomaly.severity == .positive ? "Отличная работа!" : "Внимание",
                description: anomaly.description,
                severity: anomaly.severity,
                recommendation: anomaly.suggestion
            )
            insights.append(insight)
        }
        
        // Trend insights
        for trend in trends {
            let insight = HealthInsight(
                type: trend.trend == .increasing ? .achievement : .pattern,
                title: "Тренд активности",
                description: trend.description,
                severity: trend.trend == .increasing ? .positive : .info,
                recommendation: trend.trend == .increasing ? nil : "Попробуйте увеличить активность на 10%"
            )
            insights.append(insight)
        }
    }
    
    // MARK: - Helper Methods
    
    private func isWeekday(_ date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday != 1 && weekday != 7 // Не воскресенье и не суббота
    }
    
    private func calculateTrend(_ days: [DailyStepData]) -> Double {
        guard days.count >= 2 else { return 0 }
        let first = days.first!.steps
        let last = days.last!.steps
        return Double(last - first) / Double(max(first, 1))
    }
    
    private func calculatePredictionConfidence(dailySteps: [DailyStepData]) -> Double {
        guard dailySteps.count >= 7 else { return 0.5 }
        
        // Чем меньше вариативность, тем выше уверенность
        let values = dailySteps.map { Double($0.steps) }
        let avg = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - avg, 2) }.reduce(0, +) / Double(values.count)
        let stdDev = sqrt(variance)
        
        // Коэффициент вариации
        let cv = stdDev / max(avg, 1)
        
        // Конвертируем в уверенность (ниже CV = выше уверенность)
        return min(0.95, max(0.5, 1.0 - cv))
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}
