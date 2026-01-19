//
//  StepCounterWidget.swift
//  StepCounterWidget
//
//  Виджет для Home Screen
//

import WidgetKit
import SwiftUI
import HealthKit

// MARK: - Timeline Entry

struct StepEntry: TimelineEntry {
    let date: Date
    let steps: Int
    let goal: Int
    let distance: Double
    let calories: Int
    let activeMinutes: Int
    let yesterdaySteps: Int
    let petEmoji: String?
    let petName: String?
    let petLevel: Int?
    let petXP: Int?
    let petNextLevelXP: Int?
    let streakDays: Int
    let hourlySteps: [Int] // 24 значения для графика
    
    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1.0, Double(steps) / Double(goal))
    }
    
    var isGoalReached: Bool {
        steps >= goal
    }
    
    var stepsChange: Int {
        steps - yesterdaySteps
    }
    
    var stepsChangePercent: Double {
        guard yesterdaySteps > 0 else { return 0 }
        return (Double(stepsChange) / Double(yesterdaySteps)) * 100
    }
    
    var petProgress: Double {
        guard let petXP = petXP, let petNextLevelXP = petNextLevelXP, petNextLevelXP > 0 else { return 0 }
        // Вычисляем прогресс к следующему уровню
        // Предполагаем, что текущий уровень начинается с petXP - некоторого значения
        // Для простоты используем прогресс от 0 до следующего уровня
        return min(1.0, Double(petXP) / Double(petNextLevelXP))
    }
}

// MARK: - Timeline Provider

struct StepProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> StepEntry {
        StepEntry(
            date: Date(),
            steps: 7500,
            goal: 10000,
            distance: 5200,
            calories: 320,
            activeMinutes: 45,
            yesterdaySteps: 8200,
            petEmoji: "🐩",
            petName: "Пудель",
            petLevel: 5,
            petXP: 2500,
            petNextLevelXP: 3000,
            streakDays: 7,
            hourlySteps: Array(repeating: 0, count: 24)
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (StepEntry) -> Void) {
        let entry = StepEntry(
            date: Date(),
            steps: 7500,
            goal: 10000,
            distance: 5200,
            calories: 320,
            activeMinutes: 45,
            yesterdaySteps: 8200,
            petEmoji: "🐩",
            petName: "Пудель",
            petLevel: 5,
            petXP: 2500,
            petNextLevelXP: 3000,
            streakDays: 7,
            hourlySteps: Array(repeating: 0, count: 24)
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<StepEntry>) -> Void) {
        fetchAllData { steps, distance, calories, activeMinutes, yesterdaySteps, hourlySteps, petData in
            let goal = UserDefaults(suiteName: "group.stepcounter.shared")?.integer(forKey: "stepGoal") ?? 10000
            
            let entry = StepEntry(
                date: Date(),
                steps: steps,
                goal: goal,
                distance: distance,
                calories: calories,
                activeMinutes: activeMinutes,
                yesterdaySteps: yesterdaySteps,
                petEmoji: petData?.emoji,
                petName: petData?.name,
                petLevel: petData?.level,
                petXP: petData?.xp,
                petNextLevelXP: petData?.nextLevelXP,
                streakDays: petData?.streak ?? 0,
                hourlySteps: hourlySteps
            )
            
            // Обновляем каждые 10 минут (улучшено с 15)
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 10, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    // Структура для данных питомца
    struct PetData {
        let emoji: String
        let name: String
        let level: Int
        let xp: Int
        let nextLevelXP: Int
        let streak: Int
    }
    
    private func fetchAllData(completion: @escaping (Int, Double, Int, Int, Int, [Int], PetData?) -> Void) {
        let healthStore = HKHealthStore()
        let sharedDefaults = UserDefaults(suiteName: "group.stepcounter.shared")
        
        guard HKHealthStore.isHealthDataAvailable(),
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount),
              let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
              let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
              let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else {
            completion(0, 0, 0, 0, 0, Array(repeating: 0, count: 24), nil)
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfDay)!
        
        let todayPredicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let yesterdayPredicate = HKQuery.predicateForSamples(withStart: startOfYesterday, end: startOfDay, options: .strictStartDate)
        
        var steps = 0
        var distance = 0.0
        var calories = 0
        var activeMinutes = 0
        var yesterdaySteps = 0
        var hourlySteps = Array(repeating: 0, count: 24)
        
        let group = DispatchGroup()
        
        // Шаги сегодня
        group.enter()
        let stepsQuery = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: todayPredicate,
            options: .cumulativeSum
        ) { _, result, _ in
            if let sum = result?.sumQuantity() {
                steps = Int(sum.doubleValue(for: .count()))
            }
            group.leave()
        }
        healthStore.execute(stepsQuery)
        
        // Шаги вчера
        group.enter()
        let yesterdayStepsQuery = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: yesterdayPredicate,
            options: .cumulativeSum
        ) { _, result, _ in
            if let sum = result?.sumQuantity() {
                yesterdaySteps = Int(sum.doubleValue(for: .count()))
            }
            group.leave()
        }
        healthStore.execute(yesterdayStepsQuery)
        
        // Шаги по часам за сегодня (24 часа с начала дня)
        group.enter()
        let hourlyQuery = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: todayPredicate,
            anchorDate: startOfDay,
            intervalComponents: DateComponents(hour: 1)
        )
        hourlyQuery.initialResultsHandler = { _, results, _ in
            if let statsCollection = results {
                let endDate = min(now, calendar.date(byAdding: .hour, value: 24, to: startOfDay)!)
                statsCollection.enumerateStatistics(from: startOfDay, to: endDate) { statistics, _ in
                    if let sum = statistics.sumQuantity() {
                        let hour = calendar.component(.hour, from: statistics.startDate)
                        if hour >= 0 && hour < 24 {
                            hourlySteps[hour] = Int(sum.doubleValue(for: .count()))
                        }
                    }
                }
            }
            group.leave()
        }
        healthStore.execute(hourlyQuery)
        
        // Дистанция
        group.enter()
        let distanceQuery = HKStatisticsQuery(
            quantityType: distanceType,
            quantitySamplePredicate: todayPredicate,
            options: .cumulativeSum
        ) { _, result, _ in
            if let sum = result?.sumQuantity() {
                distance = sum.doubleValue(for: .meter())
            }
            group.leave()
        }
        healthStore.execute(distanceQuery)
        
        // Калории
        group.enter()
        let caloriesQuery = HKStatisticsQuery(
            quantityType: caloriesType,
            quantitySamplePredicate: todayPredicate,
            options: .cumulativeSum
        ) { _, result, _ in
            if let sum = result?.sumQuantity() {
                calories = Int(sum.doubleValue(for: .kilocalorie()))
            }
            group.leave()
        }
        healthStore.execute(caloriesQuery)
        
        // Время активности
        group.enter()
        let exerciseQuery = HKStatisticsQuery(
            quantityType: exerciseType,
            quantitySamplePredicate: todayPredicate,
            options: .cumulativeSum
        ) { _, result, _ in
            if let sum = result?.sumQuantity() {
                activeMinutes = Int(sum.doubleValue(for: .minute()))
            }
            group.leave()
        }
        healthStore.execute(exerciseQuery)
        
        group.notify(queue: .main) {
            // Загружаем данные питомца из App Group
            var petData: PetData? = nil
            if let petEmoji = sharedDefaults?.string(forKey: "petEmoji"),
               let petName = sharedDefaults?.string(forKey: "petName"),
               let petLevel = sharedDefaults?.integer(forKey: "petLevel") as Int?,
               petLevel > 0 {
                let petXP = sharedDefaults?.integer(forKey: "petXP") ?? 0
                let petNextLevelXP = sharedDefaults?.integer(forKey: "petNextLevelXP") ?? 1000
                let streak = sharedDefaults?.integer(forKey: "streakDays") ?? 0
                petData = PetData(
                    emoji: petEmoji,
                    name: petName,
                    level: petLevel,
                    xp: petXP,
                    nextLevelXP: petNextLevelXP,
                    streak: streak
                )
            }
            
            completion(steps, distance, calories, activeMinutes, yesterdaySteps, hourlySteps, petData)
        }
    }
}

// MARK: - Widget Views

struct SmallWidgetView: View {
    let entry: StepEntry
    
    private let accentGreen = Color(red: 0.3, green: 0.85, blue: 0.5)
    
    var body: some View {
        VStack(spacing: 4) {
                // Питомец (если есть) - компактно
                if let petEmoji = entry.petEmoji {
                    HStack(spacing: 3) {
                        Text(petEmoji)
                            .font(.system(size: 14))
                        if let petLevel = entry.petLevel {
                            Text("Lv\(petLevel)")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(accentGreen)
                        }
                    }
                }
                
                // Круговой прогресс
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 7)
                        .frame(width: 68, height: 68)
                    
                    Circle()
                        .trim(from: 0, to: entry.progress)
                        .stroke(
                            LinearGradient(
                                colors: [accentGreen, Color(red: 0.2, green: 0.9, blue: 0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 7, lineCap: .round)
                        )
                        .frame(width: 68, height: 68)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: accentGreen.opacity(0.4), radius: 6, x: 0, y: 2)
                    
                    VStack(spacing: 0) {
                        Text(formatSteps(entry.steps))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Text("шагов")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                // Статус цели - компактно
                if entry.isGoalReached {
                    Text("🎉 Цель!")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(accentGreen)
                        .lineLimit(1)
                } else {
                    let remaining = entry.goal - entry.steps
                    Text("\(formatNumber(remaining)) до цели")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                
                // Серия дней - компактно
                if entry.streakDays > 0 {
                    HStack(spacing: 2) {
                        Text("🔥")
                            .font(.system(size: 7))
                        Text("\(entry.streakDays)")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000000 {
            return String(format: "%.1fМ", Double(steps) / 1000000.0)
        } else if steps >= 1000 {
            return String(format: "%.1fК", Double(steps) / 1000.0)
        }
        return "\(steps)"
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fК", Double(number) / 1000.0)
        }
        return "\(number)"
    }
}

struct MediumWidgetView: View {
    let entry: StepEntry
    
    private let accentGreen = Color(red: 0.3, green: 0.85, blue: 0.5)

    var body: some View {
        HStack(spacing: 12) {
                // Круговой прогресс
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 9)
                        .frame(width: 88, height: 88)
                    
                    Circle()
                        .trim(from: 0, to: entry.progress)
                        .stroke(
                            LinearGradient(
                                colors: [accentGreen, Color(red: 0.2, green: 0.9, blue: 0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 9, lineCap: .round)
                        )
                        .frame(width: 88, height: 88)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: accentGreen.opacity(0.4), radius: 8, x: 0, y: 3)
                    
                    VStack(spacing: 1) {
                        Text(formatSteps(entry.steps))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text("из \(formatNumber(entry.goal))")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    // Статус или сравнение
                    if entry.isGoalReached {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(accentGreen)
                                .font(.system(size: 11))
                            Text("Цель!")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(accentGreen)
                                .lineLimit(1)
                        }
                    } else if entry.yesterdaySteps > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: entry.stepsChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .foregroundColor(entry.stepsChange >= 0 ? accentGreen : .orange)
                                .font(.system(size: 9))
                            Text("\(abs(entry.stepsChangePercent), specifier: "%.0f")%")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(entry.stepsChange >= 0 ? accentGreen : .orange)
                                .lineLimit(1)
                            Text("вчера")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    // Мини-график
                    if !entry.hourlySteps.allSatisfy({ $0 == 0 }) {
                        SparklineView(data: entry.hourlySteps)
                            .frame(height: 18)
                    }
                    
                    // Метрики - компактно
                    HStack(spacing: 8) {
                        CompactMetricItem(icon: "figure.walk", value: String(format: "%.1f", entry.distance / 1000), unit: "км", color: .cyan)
                        CompactMetricItem(icon: "flame.fill", value: "\(entry.calories)", unit: "ккал", color: .orange)
                        if entry.activeMinutes > 0 {
                            CompactMetricItem(icon: "clock.fill", value: "\(entry.activeMinutes)", unit: "м", color: .blue)
                        }
                    }
                    
                    // Питомец и серия - компактно
                    HStack(spacing: 6) {
                        if let petEmoji = entry.petEmoji {
                            HStack(spacing: 3) {
                                Text(petEmoji)
                                    .font(.system(size: 11))
                                if let petLevel = entry.petLevel {
                                    Text("Lv\(petLevel)")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(accentGreen)
                                        .lineLimit(1)
                                }
                            }
                        }
                        
                        if entry.streakDays > 0 {
                            Spacer()
                            HStack(spacing: 2) {
                                Text("🔥")
                                    .font(.system(size: 9))
                                Text("\(entry.streakDays)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.orange)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000000 {
            return String(format: "%.1fМ", Double(steps) / 1000000.0)
        } else if steps >= 1000 {
            return String(format: "%.1fК", Double(steps) / 1000.0)
        }
        return "\(steps)"
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fК", Double(number) / 1000.0)
        }
        return "\(number)"
    }
}

struct CompactMetricItem: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 8))
            Text(value)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
            Text(unit)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}


struct SparklineView: View {
    let data: [Int]

    var body: some View {
        GeometryReader { geometry in
            let maxValue = data.max() ?? 1
            let width = geometry.size.width
            let height = geometry.size.height
            let stepX = width / CGFloat(max(data.count, 1))
            
            Path { path in
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalizedValue = maxValue > 0 ? CGFloat(value) / CGFloat(maxValue) : 0
                    let y = height - (normalizedValue * height)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                LinearGradient(
                    colors: [Color(red: 0.3, green: 0.85, blue: 0.5), Color.cyan],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
        }
    }
}

struct LargeWidgetView: View {
    let entry: StepEntry
    
    private let accentGreen = Color(red: 0.3, green: 0.85, blue: 0.5)

    var body: some View {
        VStack(spacing: 10) {
                // Заголовок
                HStack {
                    Text("Шагомер")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(formatDate(entry.date))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Основной контент
                HStack(spacing: 12) {
                    // Круговой прогресс
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 10)
                            .frame(width: 95, height: 95)
                        
                        Circle()
                            .trim(from: 0, to: entry.progress)
                            .stroke(
                                LinearGradient(
                                    colors: [accentGreen, Color(red: 0.2, green: 0.9, blue: 0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .frame(width: 95, height: 95)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: accentGreen.opacity(0.4), radius: 8, x: 0, y: 3)
                        
                        VStack(spacing: 2) {
                            if entry.isGoalReached {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(accentGreen)
                            }
                            Text(formatSteps(entry.steps))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                            Text("из \(formatNumber(entry.goal))")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    // Правая часть
                    VStack(alignment: .leading, spacing: 8) {
                        // Сравнение с вчера - компактно
                        if entry.yesterdaySteps > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: entry.stepsChange >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                                    .foregroundColor(entry.stepsChange >= 0 ? accentGreen : .orange)
                                    .font(.system(size: 10))
                                Text("\(abs(entry.stepsChange), specifier: "%d")")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Text("(\(abs(entry.stepsChangePercent), specifier: "%.0f")%)")
                                    .font(.system(size: 10))
                                    .foregroundColor(entry.stepsChange >= 0 ? accentGreen : .orange)
                                    .lineLimit(1)
                                Text("вчера")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                        
                        // График активности
                        if !entry.hourlySteps.allSatisfy({ $0 == 0 }) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Активность")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                SparklineView(data: entry.hourlySteps)
                                    .frame(height: 24)
                            }
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                        
                        // Питомец - компактно
                        if let petEmoji = entry.petEmoji, let petName = entry.petName {
                            HStack(spacing: 5) {
                                Text(petEmoji)
                                    .font(.system(size: 18))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 2) {
                                        Text(petName)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        if let petLevel = entry.petLevel {
                                            Text("Lv\(petLevel)")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(accentGreen)
                                                .lineLimit(1)
                                        }
                                    }
                                    
                                    // Прогресс XP
                                    if let petXP = entry.petXP, let petNextLevelXP = entry.petNextLevelXP, petNextLevelXP > 0 {
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(Color.secondary.opacity(0.3))
                                                    .frame(height: 2)
                                                
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [accentGreen, Color.cyan],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                                    .frame(width: geo.size.width * entry.petProgress, height: 2)
                                            }
                                        }
                                        .frame(height: 2)
                                        
                                        Text("XP: \(petXP)/\(petNextLevelXP)")
                                            .font(.system(size: 7))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                    }
                }
                
                // Статистика внизу - компактно
                HStack(spacing: 6) {
                    CompactStatItem(icon: "figure.walk", value: String(format: "%.1f", entry.distance / 1000), unit: "км", color: .cyan)
                    CompactStatItem(icon: "flame.fill", value: "\(entry.calories)", unit: "ккал", color: .orange)
                    if entry.activeMinutes > 0 {
                        CompactStatItem(icon: "clock.fill", value: "\(entry.activeMinutes)", unit: "м", color: .blue)
                    }
                    CompactStatItem(icon: "percent", value: "\(Int(entry.progress * 100))", unit: "%", color: accentGreen)
                    if entry.streakDays > 0 {
                        CompactStatItem(icon: "flame.fill", value: "\(entry.streakDays)", unit: "дн", color: .orange)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000000 {
            return String(format: "%.1fМ", Double(steps) / 1000000.0)
        } else if steps >= 1000 {
            return String(format: "%.1fК", Double(steps) / 1000.0)
        }
        return "\(steps)"
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fК", Double(number) / 1000.0)
        }
        return "\(number)"
    }
}

struct CompactStatItem: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            VStack(spacing: 1) {
                Text(value)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(unit)
                    .font(.system(size: 7))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.ultraThinMaterial)
        )
    }
}


// MARK: - Widget Configuration

struct StepCounterWidget: Widget {
    let kind: String = "StepCounterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StepProvider()) { entry in
            StepCounterWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Шагомер")
        .description("Отслеживайте свои шаги прямо с Home Screen")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct StepCounterWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: StepEntry
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .accessoryCircular:
            LockScreenCircularWidget(entry: entry)
        case .accessoryRectangular:
            LockScreenRectangularWidget(entry: entry)
        case .accessoryInline:
            LockScreenInlineWidget(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Lock Screen Widgets

struct LockScreenCircularWidget: View {
    let entry: StepEntry
    private let accentGreen = Color(red: 0.3, green: 0.85, blue: 0.5)
    
    var body: some View {
        ZStack {
            // Круговой прогресс
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: entry.progress)
                .stroke(accentGreen, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 0) {
                Text("\(Int(entry.progress * 100))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
                Text(formatSteps(entry.steps))
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            return String(format: "%.1fК", Double(steps) / 1000.0)
        }
        return "\(steps)"
    }
}

struct LockScreenRectangularWidget: View {
    let entry: StepEntry
    private let accentGreen = Color(red: 0.3, green: 0.85, blue: 0.5)
    
    var body: some View {
        HStack(spacing: 8) {
            // Иконка
            Image(systemName: "figure.walk")
                .foregroundColor(accentGreen)
                .font(.system(size: 14))
            
            // Прогресс-бар
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accentGreen)
                        .frame(width: geo.size.width * entry.progress, height: 4)
                }
            }
            .frame(height: 4)
            
            // Шаги
            Text(formatSteps(entry.steps))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            return String(format: "%.1fК", Double(steps) / 1000.0)
        }
        return "\(steps)"
    }
}

struct LockScreenInlineWidget: View {
    let entry: StepEntry
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "figure.walk")
            Text("\(formatSteps(entry.steps)) шагов")
        }
        .font(.system(size: 12))
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            return String(format: "%.1fК", Double(steps) / 1000.0)
        }
        return "\(steps)"
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    StepCounterWidget()
} timeline: {
    StepEntry(
        date: Date(),
        steps: 7500,
        goal: 10000,
        distance: 5200,
        calories: 320,
        activeMinutes: 45,
        yesterdaySteps: 8200,
        petEmoji: "🐩",
        petName: "Пудель",
        petLevel: 5,
        petXP: 2500,
        petNextLevelXP: 3000,
        streakDays: 7,
        hourlySteps: [0, 0, 0, 0, 0, 0, 200, 500, 800, 600, 400, 300, 500, 700, 600, 500, 400, 300, 200, 100, 0, 0, 0, 0]
    )
    StepEntry(
        date: Date(),
        steps: 10500,
        goal: 10000,
        distance: 7800,
        calories: 450,
        activeMinutes: 60,
        yesterdaySteps: 8200,
        petEmoji: "🐩",
        petName: "Пудель",
        petLevel: 5,
        petXP: 2800,
        petNextLevelXP: 3000,
        streakDays: 7,
        hourlySteps: [0, 0, 0, 0, 0, 0, 200, 500, 800, 600, 400, 300, 500, 700, 600, 500, 400, 300, 200, 100, 0, 0, 0, 0]
    )
}
