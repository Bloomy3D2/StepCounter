//
//  WatchHealthManager.swift
//  StepCounter Watch App
//
//  Менеджер HealthKit для Apple Watch
//

import Foundation
import HealthKit
import WatchKit

final class WatchHealthManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var todaySteps: Int = 0
    @Published var todayDistance: Double = 0
    @Published var todayCalories: Double = 0
    @Published var heartRate: Int = 0
    @Published var stepGoal: Int = 10000
    @Published var isAuthorized: Bool = false
    
    // MARK: - Private Properties
    
    private let healthStore = HKHealthStore()
    private var observerQuery: HKObserverQuery?
    
    private let typesToRead: Set<HKObjectType> = {
        guard let steps = HKObjectType.quantityType(forIdentifier: .stepCount),
              let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
              let calories = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return []
        }
        return [steps, distance, calories, heartRate]
    }()
    
    // MARK: - Initialization
    
    init() {
        if let savedGoal = UserDefaults.standard.object(forKey: "stepGoal") as? Int {
            self.stepGoal = savedGoal
        }
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, _ in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthorized = true
                    self?.startObserving()
                    self?.fetchAllData()
                }
            }
        }
    }
    
    // MARK: - Fetch Data
    
    func fetchAllData() {
        fetchTodaySteps()
        fetchTodayDistance()
        fetchTodayCalories()
        fetchHeartRate()
    }
    
    func fetchTodaySteps() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, _ in
            DispatchQueue.main.async {
                guard let result = result, let sum = result.sumQuantity() else {
                    self?.todaySteps = 0
                    return
                }
                self?.todaySteps = Int(sum.doubleValue(for: .count()))
            }
        }
        
        healthStore.execute(query)
    }
    
    func fetchTodayDistance() {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: distanceType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, _ in
            DispatchQueue.main.async {
                guard let result = result, let sum = result.sumQuantity() else {
                    self?.todayDistance = 0
                    return
                }
                self?.todayDistance = sum.doubleValue(for: .meter())
            }
        }
        
        healthStore.execute(query)
    }
    
    func fetchTodayCalories() {
        guard let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: caloriesType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, _ in
            DispatchQueue.main.async {
                guard let result = result, let sum = result.sumQuantity() else {
                    self?.todayCalories = 0
                    return
                }
                self?.todayCalories = sum.doubleValue(for: .kilocalorie())
            }
        }
        
        healthStore.execute(query)
    }
    
    func fetchHeartRate() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, _ in
            DispatchQueue.main.async {
                guard let sample = samples?.first as? HKQuantitySample else {
                    self?.heartRate = 0
                    return
                }
                self?.heartRate = Int(sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Observing
    
    private func startObserving() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        observerQuery = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, _ in
            DispatchQueue.main.async {
                self?.fetchAllData()
            }
        }
        
        if let query = observerQuery {
            healthStore.execute(query)
        }
    }
    
    // MARK: - Helpers
    
    var goalProgress: Double {
        guard stepGoal > 0 else { return 0 }
        return min(1.0, Double(todaySteps) / Double(stepGoal))
    }
    
    var isGoalReached: Bool {
        todaySteps >= stepGoal
    }
}
