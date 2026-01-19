//
//  HealthManager.swift
//  StepCounter
//
//  Менеджер для работы с HealthKit
//

import Foundation
import HealthKit
import Combine

/// Менеджер HealthKit
@MainActor
final class HealthManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Шаги за сегодня
    @Published var todaySteps: Int = 0 {
        didSet {
            // Отправляем в дебаунсированный поток
            stepsSubject.send(todaySteps)
        }
    }
    
    /// Дистанция за сегодня (метры)
    @Published var todayDistance: Double = 0
    
    /// Калории за сегодня
    @Published var todayCalories: Double = 0
    
    /// Время активности (минуты)
    @Published var todayActiveMinutes: Int = 0
    
    /// Шаги по часам за сегодня
    @Published var hourlySteps: [HourlyStepData] = []
    
    /// Шаги за неделю
    @Published var weeklySteps: [DailyStepData] = []
    
    /// Шаги за месяц
    @Published var monthlySteps: [DailyStepData] = []
    
    /// Шаги за год (по месяцам)
    @Published var yearlySteps: [MonthlyStepData] = []
    
    /// Состояния загрузки данных
    @Published var weeklyStepsState: LoadingState<[DailyStepData]> = .idle
    @Published var monthlyStepsState: LoadingState<[DailyStepData]> = .idle
    @Published var yearlyStepsState: LoadingState<[MonthlyStepData]> = .idle
    @Published var hourlyStepsState: LoadingState<[HourlyStepData]> = .idle
    
    /// Авторизация получена
    @Published var isAuthorized: Bool = false
    
    /// Ошибка
    @Published var errorMessage: String?
    
    /// Цель шагов
    @Published var stepGoal: Int {
        didSet {
            // Сохраняем в стандартный UserDefaults
            UserDefaults.standard.set(stepGoal, forKey: "stepGoal")
            // И в App Group для виджета
            if let sharedDefaults = UserDefaults(suiteName: "group.stepcounter.shared") {
                sharedDefaults.set(stepGoal, forKey: "stepGoal")
                sharedDefaults.synchronize()
            }
        }
    }
    
    // MARK: - Private Properties
    
    private let healthStore = HKHealthStore()
    private var observerQuery: HKObserverQuery?
    private var cancellables = Set<AnyCancellable>()
    
    // Дебаунсинг для оптимизации обновлений
    private let stepsSubject = PassthroughSubject<Int, Never>()
    
    /// Дебаунсированный Publisher для шагов (обновляется максимум раз в 0.5 секунды)
    var debouncedSteps: AnyPublisher<Int, Never> {
        stepsSubject
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Caching
    
    private var cachedWeeklySteps: [DailyStepData]?
    private var cachedMonthlySteps: [DailyStepData]?
    private var cachedYearlySteps: [MonthlyStepData]?
    private var cacheDate: Date?
    private let cacheValidityInterval: TimeInterval = 300 // 5 минут
    
    // Типы данных для чтения
    private let typesToRead: Set<HKObjectType> = {
        guard let steps = HKObjectType.quantityType(forIdentifier: .stepCount),
              let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
              let calories = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let exercise = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) else {
            return []
        }
        return [steps, distance, calories, exercise]
    }()
    
    // MARK: - Initialization
    
    init() {
        // Загружаем из App Group, если доступен, иначе из стандартного UserDefaults
        if let sharedDefaults = UserDefaults(suiteName: "group.stepcounter.shared"),
           let goal = sharedDefaults.object(forKey: "stepGoal") as? Int {
            self.stepGoal = goal
        } else {
            self.stepGoal = UserDefaults.standard.object(forKey: "stepGoal") as? Int ?? 10000
            // Синхронизируем с App Group
            if let sharedDefaults = UserDefaults(suiteName: "group.stepcounter.shared") {
                sharedDefaults.set(stepGoal, forKey: "stepGoal")
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Запросить авторизацию HealthKit
    func requestAuthorization() {
        // Проверяем согласие на обработку персональных данных
        guard PrivacyConsentManager.shared.hasConsent else {
            Logger.shared.logWarning("Попытка запросить авторизацию HealthKit без согласия на обработку ПДн")
            errorMessage = "Требуется согласие на обработку персональных данных"
            return
        }
        
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit недоступен на этом устройстве"
            return
        }
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthorized = true
                    self?.startObserving()
                    self?.fetchAllData()
                } else {
                    self?.errorMessage = error?.localizedDescription ?? "Не удалось получить доступ к HealthKit"
                }
            }
        }
    }
    
    /// Обновить все данные (приоритетные данные загружаются первыми)
    func fetchAllData() {
        // Проверяем согласие на обработку персональных данных
        guard PrivacyConsentManager.shared.hasConsent else {
            Logger.shared.logWarning("Попытка загрузить данные HealthKit без согласия на обработку ПДн")
            return
        }
        
        // Критичные данные - сразу
        fetchTodaySteps()
        fetchTodayDistance()
        fetchTodayCalories()
        
        // Менее критичные - с небольшой задержкой
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 сек
            fetchTodayActiveMinutes()
            fetchHourlySteps()
        }
        
        // Не критичные данные - в фоне
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 сек
            fetchWeeklySteps()
            fetchMonthlySteps()
            fetchYearlySteps()
        }
    }
    
    // MARK: - Fetching Data
    
    /// Получить шаги за сегодня
    func fetchTodaySteps() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.shared.logHealthKitError(error, operation: "fetchTodaySteps")
                    self?.errorMessage = "Ошибка получения шагов: \(error.localizedDescription)"
                    return
                }
                
                guard let result = result, let sum = result.sumQuantity() else {
                    self?.todaySteps = 0
                    return
                }
                let steps = Int(sum.doubleValue(for: .count()))
                // Валидация: шаги должны быть в разумных пределах
                if steps >= 0 && steps <= AppConstants.HealthKitLimits.maxSteps {
                    self?.todaySteps = steps
                } else {
                    Logger.shared.logWarning("Некорректные данные шагов: \(steps)")
                    self?.errorMessage = "Получены некорректные данные шагов"
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Получить дистанцию за сегодня
    func fetchTodayDistance() {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: distanceType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.shared.logHealthKitError(error, operation: "fetchTodayDistance")
                    self?.errorMessage = "Ошибка получения дистанции: \(error.localizedDescription)"
                    return
                }
                
                guard let result = result, let sum = result.sumQuantity() else {
                    self?.todayDistance = 0
                    return
                }
                let distance = sum.doubleValue(for: .meter())
                // Валидация: дистанция должна быть в разумных пределах
                if distance >= 0 && distance <= Double(AppConstants.HealthKitLimits.maxDistanceMeters) {
                    self?.todayDistance = distance
                } else {
                    Logger.shared.logWarning("Некорректные данные дистанции: \(distance) м")
                    self?.errorMessage = "Получены некорректные данные дистанции"
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Получить калории за сегодня
    func fetchTodayCalories() {
        guard let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: caloriesType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.shared.logHealthKitError(error, operation: "fetchTodayCalories")
                    self?.errorMessage = "Ошибка получения калорий: \(error.localizedDescription)"
                    return
                }
                
                guard let result = result, let sum = result.sumQuantity() else {
                    self?.todayCalories = 0
                    return
                }
                let calories = sum.doubleValue(for: .kilocalorie())
                // Валидация: калории должны быть в разумных пределах
                if calories >= 0 && calories <= Double(AppConstants.HealthKitLimits.maxCalories) {
                    self?.todayCalories = calories
                } else {
                    Logger.shared.logWarning("Некорректные данные калорий: \(calories)")
                    self?.errorMessage = "Получены некорректные данные калорий"
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Получить время активности
    func fetchTodayActiveMinutes() {
        guard let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: exerciseType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.shared.logHealthKitError(error, operation: "fetchTodayActiveMinutes")
                    self?.errorMessage = "Ошибка получения времени активности: \(error.localizedDescription)"
                    return
                }
                
                guard let result = result, let sum = result.sumQuantity() else {
                    self?.todayActiveMinutes = 0
                    return
                }
                let minutes = Int(sum.doubleValue(for: .minute()))
                // Валидация: время активности должно быть в разумных пределах
                if minutes >= 0 && minutes <= AppConstants.HealthKitLimits.maxActiveMinutes {
                    self?.todayActiveMinutes = minutes
                } else {
                    Logger.shared.logWarning("Некорректные данные времени активности: \(minutes) мин")
                    self?.errorMessage = "Получены некорректные данные времени активности"
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Получить шаги по часам
    func fetchHourlySteps() {
        // Устанавливаем состояние загрузки
        hourlyStepsState = .loading
        
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            hourlyStepsState = .error(LoadingError.invalidData)
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        var interval = DateComponents()
        interval.hour = 1
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: nil,
            options: .cumulativeSum,
            anchorDate: startOfDay,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { [weak self] _, results, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.shared.logHealthKitError(error, operation: "fetchHourlySteps")
                    self?.errorMessage = "Ошибка получения почасовых данных: \(error.localizedDescription)"
                    self?.hourlyStepsState = .error(LoadingError.unknown(error))
                    return
                }
                
                guard let results = results else {
                    Logger.shared.logWarning("fetchHourlySteps: results is nil")
                    self?.hourlySteps = []
                    self?.hourlyStepsState = .error(LoadingError.invalidData)
                    return
                }
                
                var hourlyData: [HourlyStepData] = []
                
                results.enumerateStatistics(from: startOfDay, to: now) { statistics, _ in
                    let hour = Calendar.current.component(.hour, from: statistics.startDate)
                    let stepsValue = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    let steps = Int(stepsValue)
                    // Валидация: шаги за час должны быть в разумных пределах
                    if steps >= 0 && steps <= AppConstants.HealthKitLimits.maxHourlySteps {
                        hourlyData.append(HourlyStepData(hour: hour, steps: steps))
                    } else {
                        Logger.shared.logWarning("Некорректные данные почасовых шагов: \(steps) для часа \(hour)")
                    }
                }
                
                self?.hourlySteps = hourlyData
                self?.hourlyStepsState = .loaded(hourlyData)
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Получить шаги за неделю (с кэшированием)
    func fetchWeeklySteps() {
        // Проверяем кэш
        if let cached = cachedWeeklySteps,
           let cacheDate = cacheDate,
           Date().timeIntervalSince(cacheDate) < cacheValidityInterval {
            weeklySteps = cached
            weeklyStepsState = .loaded(cached)
            return
        }
        
        // Устанавливаем состояние загрузки
        weeklyStepsState = .loading
        
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            weeklyStepsState = .error(LoadingError.invalidData)
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        guard let startOfWeek = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) else {
            Logger.shared.logWarning("Не удалось вычислить начало недели")
            return
        }
        
        var interval = DateComponents()
        interval.day = 1
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: nil,
            options: .cumulativeSum,
            anchorDate: startOfWeek,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { [weak self] _, results, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.shared.logHealthKitError(error, operation: "fetchWeeklySteps")
                    self?.errorMessage = "Ошибка получения недельных данных: \(error.localizedDescription)"
                    self?.weeklyStepsState = .error(LoadingError.unknown(error))
                    return
                }
                
                guard let results = results else {
                    Logger.shared.logWarning("fetchWeeklySteps: results is nil")
                    self?.weeklySteps = []
                    self?.weeklyStepsState = .error(LoadingError.invalidData)
                    return
                }
                
                var dailyData: [DailyStepData] = []
                
                results.enumerateStatistics(from: startOfWeek, to: now) { statistics, _ in
                    let steps = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    let stepsInt = Int(steps)
                    // Валидация: шаги должны быть в разумных пределах
                    if stepsInt >= 0 && stepsInt <= AppConstants.HealthKitLimits.maxSteps {
                        dailyData.append(DailyStepData(date: statistics.startDate, steps: stepsInt))
                    } else {
                        Logger.shared.logWarning("Некорректные данные недельных шагов: \(stepsInt) для даты \(statistics.startDate)")
                    }
                }
                
                self?.weeklySteps = dailyData
                self?.weeklyStepsState = .loaded(dailyData)
                // Обновляем кэш
                self?.cachedWeeklySteps = dailyData
                self?.cacheDate = Date()
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Получить шаги за месяц (с кэшированием)
    func fetchMonthlySteps() {
        // Проверяем кэш
        if let cached = cachedMonthlySteps,
           let cacheDate = cacheDate,
           Date().timeIntervalSince(cacheDate) < cacheValidityInterval {
            monthlySteps = cached
            monthlyStepsState = .loaded(cached)
            return
        }
        
        // Устанавливаем состояние загрузки
        monthlyStepsState = .loading
        
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            monthlyStepsState = .error(LoadingError.invalidData)
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: now)) else {
            Logger.shared.logWarning("Не удалось вычислить начало месяца")
            return
        }
        
        var interval = DateComponents()
        interval.day = 1
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: nil,
            options: .cumulativeSum,
            anchorDate: startOfMonth,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { [weak self] _, results, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.shared.logHealthKitError(error, operation: "fetchMonthlySteps")
                    self?.errorMessage = "Ошибка получения месячных данных: \(error.localizedDescription)"
                    self?.monthlyStepsState = .error(LoadingError.unknown(error))
                    return
                }
                
                guard let results = results else {
                    Logger.shared.logWarning("fetchMonthlySteps: results is nil")
                    self?.monthlySteps = []
                    self?.monthlyStepsState = .error(LoadingError.invalidData)
                    return
                }
                
                var dailyData: [DailyStepData] = []
                
                results.enumerateStatistics(from: startOfMonth, to: now) { statistics, _ in
                    let steps = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    let stepsInt = Int(steps)
                    // Валидация: шаги должны быть в разумных пределах
                    if stepsInt >= 0 && stepsInt <= AppConstants.HealthKitLimits.maxSteps {
                        dailyData.append(DailyStepData(date: statistics.startDate, steps: stepsInt))
                    } else {
                        Logger.shared.logWarning("Некорректные данные месячных шагов: \(stepsInt) для даты \(statistics.startDate)")
                    }
                }
                
                self?.monthlySteps = dailyData
                self?.monthlyStepsState = .loaded(dailyData)
                // Обновляем кэш
                self?.cachedMonthlySteps = dailyData
                self?.cacheDate = Date()
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Получить шаги за год (по месяцам, с кэшированием)
    func fetchYearlySteps() {
        // Проверяем кэш
        if let cached = cachedYearlySteps,
           let cacheDate = cacheDate,
           Date().timeIntervalSince(cacheDate) < cacheValidityInterval {
            yearlySteps = cached
            yearlyStepsState = .loaded(cached)
            return
        }
        
        // Устанавливаем состояние загрузки
        yearlyStepsState = .loading
        
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            yearlyStepsState = .error(LoadingError.invalidData)
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        guard let startOfYear = calendar.date(byAdding: .month, value: -11, to: startOfDay) else {
            Logger.shared.logWarning("Не удалось вычислить начало года")
            return
        }
        
        var interval = DateComponents()
        interval.month = 1
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: nil,
            options: .cumulativeSum,
            anchorDate: startOfYear,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { [weak self] _, results, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.shared.logHealthKitError(error, operation: "fetchYearlySteps")
                    self?.errorMessage = "Ошибка получения годовых данных: \(error.localizedDescription)"
                    self?.yearlyStepsState = .error(LoadingError.unknown(error))
                    return
                }
                
                guard let results = results else {
                    Logger.shared.logWarning("fetchYearlySteps: results is nil")
                    self?.yearlySteps = []
                    self?.yearlyStepsState = .error(LoadingError.invalidData)
                    return
                }
                
                var monthlyData: [MonthlyStepData] = []
                
                results.enumerateStatistics(from: startOfYear, to: now) { statistics, _ in
                    let steps = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    let stepsInt = Int(steps)
                    // Валидация: шаги должны быть в разумных пределах
                    if stepsInt >= 0 && stepsInt <= AppConstants.HealthKitLimits.maxSteps {
                        monthlyData.append(MonthlyStepData(date: statistics.startDate, steps: stepsInt))
                    } else {
                        Logger.shared.logWarning("Некорректные данные годовых шагов: \(stepsInt) для даты \(statistics.startDate)")
                    }
                }
                
                self?.yearlySteps = monthlyData
                self?.yearlyStepsState = .loaded(monthlyData)
                // Обновляем кэш
                self?.cachedYearlySteps = monthlyData
                self?.cacheDate = Date()
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Очистить кэш (вызывать при необходимости принудительного обновления)
    func clearCache() {
        cachedWeeklySteps = nil
        cachedMonthlySteps = nil
        cachedYearlySteps = nil
        cacheDate = nil
    }
    
    // MARK: - Observing
    
    /// Начать наблюдение за изменениями
    private func startObserving() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        observerQuery = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, error in
            if error == nil {
                DispatchQueue.main.async {
                    self?.fetchAllData()
                }
            }
        }
        
        if let query = observerQuery {
            healthStore.execute(query)
            
            // Включаем фоновые обновления
            healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { success, error in
                if success {
                    print("Background delivery enabled")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Прогресс до цели (0.0 - 1.0)
    var goalProgress: Double {
        guard stepGoal > 0 else { return 0 }
        return min(1.0, Double(todaySteps) / Double(stepGoal))
    }
    
    /// Оставшиеся шаги до цели
    var remainingSteps: Int {
        max(0, stepGoal - todaySteps)
    }
    
    /// Цель достигнута
    var isGoalReached: Bool {
        todaySteps >= stepGoal
    }
    
    /// Средние шаги за неделю
    var weeklyAverage: Int {
        guard !weeklySteps.isEmpty else { return 0 }
        let total = weeklySteps.reduce(0) { $0 + $1.steps }
        return total / weeklySteps.count
    }
}

// MARK: - Data Models

/// Данные шагов по часам
struct HourlyStepData: Identifiable {
    let id = UUID()
    let hour: Int
    let steps: Int
    
    var hourString: String {
        String(format: "%02d:00", hour)
    }
}

/// Данные шагов по дням
struct DailyStepData: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Int
    
    var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}

/// Данные шагов по месяцам
struct MonthlyStepData: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Int
    
    var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
    
    var fullMonthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
    
    var averagePerDay: Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: date)
        let daysInMonth = range?.count ?? 30
        return steps / daysInMonth
    }
}
