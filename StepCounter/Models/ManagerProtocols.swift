//
//  ManagerProtocols.swift
//  StepCounter
//
//  Протоколы для всех менеджеров для улучшения тестируемости и архитектуры
//

import Foundation
import Combine
import SwiftUI

// MARK: - HealthManager Protocol

/// Протокол для менеджера HealthKit
protocol HealthManagerProtocol: ObservableObject {
    var todaySteps: Int { get set }
    var todayDistance: Double { get set }
    var todayCalories: Double { get set }
    var todayActiveMinutes: Int { get set }
    var hourlySteps: [HourlyStepData] { get set }
    var weeklySteps: [DailyStepData] { get set }
    var monthlySteps: [DailyStepData] { get set }
    var yearlySteps: [MonthlyStepData] { get set }
    var isAuthorized: Bool { get set }
    var errorMessage: String? { get set }
    var stepGoal: Int { get set }
    var debouncedSteps: AnyPublisher<Int, Never> { get }
    
    var goalProgress: Double { get }
    var remainingSteps: Int { get }
    var isGoalReached: Bool { get }
    var weeklyAverage: Int { get }
    
    func requestAuthorization()
    func fetchAllData()
    func fetchTodaySteps()
    func fetchTodayDistance()
    func fetchTodayCalories()
    func fetchTodayActiveMinutes()
    func fetchHourlySteps()
    func fetchWeeklySteps()
    func fetchMonthlySteps()
    func fetchYearlySteps()
    func clearCache()
}

// MARK: - LevelManager Protocol

/// Протокол для менеджера уровней и XP
protocol LevelManagerProtocol: ObservableObject {
    var player: PlayerData { get set }
    var dailyQuests: [DailyQuest] { get set }
    var showLevelUp: Bool { get set }
    var newLevel: Int { get set }
    var showRankUp: Bool { get set }
    var newRank: PlayerRank? { get set }
    var showStreakBonus: Bool { get set }
    var streakBonusAmount: Int { get set }
    var streakBonusTitle: String { get set }
    
    var levelProgress: Double { get }
    var xpToNextLevel: Int { get }
    var completedQuestsToday: Int { get }
    var totalQuestsToday: Int { get }
    
    func xpForLevel(_ level: Int) -> Int
    func addXP(_ amount: Int)
    func addSteps(_ steps: Int, distance: Double, calories: Double)
    func checkStreakBonuses()
    func setMaxLevel()
    func refreshQuest(_ questId: String, completion: @escaping (Bool) -> Void)
}

// MARK: - AchievementManager Protocol

/// Протокол для менеджера достижений
protocol AchievementManagerProtocol: ObservableObject {
    var achievements: [Achievement] { get set }
    var newlyUnlocked: Achievement? { get set }
    var currentStreak: Int { get set }
    var totalStepsEver: Int { get set }
    var totalDistanceEver: Double { get set }
    
    var unlockedCount: Int { get }
    var totalCount: Int { get }
    var unlockedAchievements: [Achievement] { get }
    var lockedAchievements: [Achievement] { get }
    var totalXPEarned: Int { get }
    
    func checkAchievements(steps: Int, distance: Double, calories: Double, goalReached: Bool, stepGoal: Int)
    func achievements(for category: AchievementCategory) -> [Achievement]
    func achievements(for rarity: AchievementRarity) -> [Achievement]
}

// MARK: - PetManager Protocol

/// Протокол для менеджера питомца
protocol PetManagerProtocol: ObservableObject {
    var pets: [Pet] { get set }
    var selectedPetId: UUID? { get set }
    var showEvolutionAnimation: Bool { get set }
    var newEvolution: PetEvolution? { get set }
    
    var pet: Pet? { get set }
    
    func feedPet(steps: Int)
}

// MARK: - ChallengeManager Protocol

/// Протокол для менеджера челленджей
protocol ChallengeManagerProtocol: ObservableObject {
    var activeChallenges: [Challenge] { get set }
    var completedChallenges: [Challenge] { get set }
    var newlyCompleted: Challenge? { get set }
    
    func updateProgress(steps: Int, distance: Double, calories: Double, streak: Int)
}

// MARK: - TournamentManager Protocol

/// Протокол для менеджера турниров
protocol TournamentManagerProtocol: ObservableObject {
    var currentTournament: Tournament? { get }
    
    func updateUserStepsFromWeekly(_ weeklySteps: [DailyStepData], tournamentStartDate: Date)
}

// MARK: - GroupChallengeManager Protocol

/// Протокол для менеджера групповых челленджей
protocol GroupChallengeManagerProtocol: ObservableObject {
    func updateUserProgress(type: ChallengeType, steps: Int, distance: Double, calories: Double)
}

// MARK: - StorageManager Protocol

/// Протокол для менеджера хранения данных
protocol StorageManagerProtocol {
    func save<T: Codable>(_ value: T, forKey key: String) throws
    func saveAsync<T: Codable>(_ value: T, forKey key: String)
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T?
    func loadSafe<T: Codable>(_ type: T.Type, forKey key: String) -> T?
    func saveArray<T: Codable>(_ array: [T], forKey key: String) throws
    func saveArraySafe<T: Codable>(_ array: [T], forKey key: String)
    func loadArray<T: Codable>(_ type: T.Type, forKey key: String) throws -> [T]
    func loadArraySafe<T: Codable>(_ type: T.Type, forKey key: String) -> [T]
    func remove(forKey key: String)
    func clearAll()
}

// MARK: - Protocol Conformance

// HealthManager уже соответствует протоколу (все методы и свойства есть)
extension HealthManager: HealthManagerProtocol {}

// LevelManager уже соответствует протоколу
extension LevelManager: LevelManagerProtocol {}

// AchievementManager уже соответствует протоколу
extension AchievementManager: AchievementManagerProtocol {}

// PetManager нужно проверить
extension PetManager: PetManagerProtocol {}

// ChallengeManager нужно проверить
extension ChallengeManager: ChallengeManagerProtocol {}

// TournamentManager нужно проверить
extension TournamentManager: TournamentManagerProtocol {}

// GroupChallengeManager нужно проверить
extension GroupChallengeManager: GroupChallengeManagerProtocol {}

// StorageManager уже соответствует протоколу
extension StorageManager: StorageManagerProtocol {}
