//
//  ChallengeManager.swift
//  StepCounter
//
//  Личные челленджи
//

import Foundation
import SwiftUI

/// Тип челленджа
enum ChallengeType: String, Codable, CaseIterable {
    case dailySteps = "daily_steps"
    case weeklySteps = "weekly_steps"
    case weeklyDistance = "weekly_distance"
    case streakDays = "streak_days"
    case dailyCalories = "daily_calories"
    
    var title: String {
        switch self {
        case .dailySteps: return "Шаги за день"
        case .weeklySteps: return "Шаги за неделю"
        case .weeklyDistance: return "Дистанция за неделю"
        case .streakDays: return "Дней подряд"
        case .dailyCalories: return "Калории за день"
        }
    }
    
    var icon: String {
        switch self {
        case .dailySteps: return "figure.walk"
        case .weeklySteps: return "figure.walk.motion"
        case .weeklyDistance: return "map"
        case .streakDays: return "flame.fill"
        case .dailyCalories: return "flame"
        }
    }
    
    var unit: String {
        switch self {
        case .dailySteps, .weeklySteps: return "шагов"
        case .weeklyDistance: return "км"
        case .streakDays: return "дней"
        case .dailyCalories: return "ккал"
        }
    }
    
    var color: Color {
        switch self {
        case .dailySteps: return .green
        case .weeklySteps: return .blue
        case .weeklyDistance: return .cyan
        case .streakDays: return .orange
        case .dailyCalories: return .red
        }
    }
    
    var presets: [Int] {
        switch self {
        case .dailySteps: return [5000, 8000, 10000, 12000, 15000, 20000]
        case .weeklySteps: return [35000, 50000, 70000, 100000]
        case .weeklyDistance: return [10, 20, 30, 50, 100]
        case .streakDays: return [3, 7, 14, 21, 30]
        case .dailyCalories: return [300, 500, 700, 1000]
        }
    }
    
    /// Является ли челлендж продвинутым (требует Premium)
    var isPremium: Bool {
        // Продвинутые челленджи - это марафоны и групповые (уже реализованы через GroupChallengeManager)
        // Здесь можно отметить сложные персональные челленджи
        return false // Все базовые ChallengeType бесплатны, продвинутые - через GroupChallenge
    }
}

/// Челлендж
struct Challenge: Identifiable, Codable {
    let id: UUID
    let type: ChallengeType
    let target: Int
    let startDate: Date
    let endDate: Date
    var currentProgress: Int
    var isCompleted: Bool
    var completedDate: Date?
    
    init(type: ChallengeType, target: Int, durationDays: Int) {
        self.id = UUID()
        self.type = type
        self.target = target
        self.startDate = Date()
        self.endDate = Calendar.current.date(byAdding: .day, value: durationDays, to: Date()) ?? Date()
        self.currentProgress = 0
        self.isCompleted = false
        self.completedDate = nil
    }
    
    var progressPercent: Double {
        guard target > 0 else { return 0 }
        return min(1.0, Double(currentProgress) / Double(target))
    }
    
    var daysRemaining: Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, days)
    }
    
    var isExpired: Bool {
        Date() > endDate && !isCompleted
    }
    
    var isActive: Bool {
        !isCompleted && !isExpired
    }
    
    var statusText: String {
        if isCompleted {
            return "✅ Выполнено"
        } else if isExpired {
            return "❌ Не выполнено"
        } else if daysRemaining == 0 {
            return "⏰ Последний день"
        } else {
            return "📅 Осталось \(daysRemaining) дн."
        }
    }
}

/// Менеджер челленджей
final class ChallengeManager: ObservableObject {
    
    @Published var activeChallenges: [Challenge] = []
    @Published var completedChallenges: [Challenge] = []
    @Published var newlyCompleted: Challenge?
    
    private let activeKey = "activeChallenges"
    private let completedKey = "completedChallenges"
    
    private var hasLoaded = false
    
    init() {
        // Не загружаем в init - загрузим при первом обращении
    }
    
    // MARK: - Persistence
    
    @MainActor
    func ensureLoaded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        
        // Загружаем синхронно - UserDefaults быстрый
        let storage = StorageManager.shared
        if let active: [Challenge] = storage.loadSafe([Challenge].self, forKey: activeKey) {
            activeChallenges = active
        }
        if let completed: [Challenge] = storage.loadSafe([Challenge].self, forKey: completedKey) {
            completedChallenges = completed
        }
        
        // Проверку истекших откладываем
        Task { @MainActor [weak self] in
            self?.checkExpiredChallenges()
        }
    }
    
    @MainActor
    private func saveChallenges() {
        let storage = StorageManager.shared
        do {
            try storage.save(activeChallenges, forKey: activeKey)
            try storage.save(completedChallenges, forKey: completedKey)
        } catch {
            Logger.shared.logStorageError(error, key: activeKey)
        }
    }
    
    // MARK: - Challenge Management
    
    @MainActor
    func createChallenge(type: ChallengeType, target: Int, durationDays: Int) {
        // ensureLoaded уже должен быть вызван из view при открытии
        let challenge = Challenge(type: type, target: target, durationDays: durationDays)
        activeChallenges.append(challenge)
        // Копируем данные и сохраняем асинхронно
        let active = activeChallenges
        let completed = completedChallenges
        let activeKey = self.activeKey
        let completedKey = self.completedKey
        Task { @MainActor in
            let storage = StorageManager.shared
            do {
                try storage.save(active, forKey: activeKey)
                try storage.save(completed, forKey: completedKey)
            } catch {
                #if DEBUG
                print("⚠️ ChallengeManager.saveChallenges error: \(error.localizedDescription)")
                #endif
            }
        }
    }
    
    @MainActor
    func deleteChallenge(_ challenge: Challenge) {
        activeChallenges.removeAll { $0.id == challenge.id }
        saveChallenges()
    }
    
    @MainActor
    func updateProgress(steps: Int, distance: Double, calories: Double, streak: Int) {
        for i in activeChallenges.indices {
            var challenge = activeChallenges[i]
            
            switch challenge.type {
            case .dailySteps:
                challenge.currentProgress = steps
            case .weeklySteps:
                // Для недельных нужна сумма за неделю (упрощённо используем текущие шаги)
                challenge.currentProgress = steps
            case .weeklyDistance:
                challenge.currentProgress = Int(distance / 1000) // в км
            case .streakDays:
                challenge.currentProgress = streak
            case .dailyCalories:
                challenge.currentProgress = Int(calories)
            }
            
            // Проверяем выполнение
            if challenge.currentProgress >= challenge.target && !challenge.isCompleted {
                challenge.isCompleted = true
                challenge.completedDate = Date()
                newlyCompleted = challenge
                
                // Haptic
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
            
            activeChallenges[i] = challenge
        }
        
        // Перемещаем выполненные
        let completed = activeChallenges.filter { $0.isCompleted }
        completedChallenges.append(contentsOf: completed)
        activeChallenges.removeAll { $0.isCompleted }
        
        saveChallenges()
    }
    
    @MainActor
    private func checkExpiredChallenges() {
        let expired = activeChallenges.filter { $0.isExpired }
        completedChallenges.append(contentsOf: expired)
        activeChallenges.removeAll { $0.isExpired }
        saveChallenges()
    }
    
    // MARK: - Stats
    
    var totalCompleted: Int {
        completedChallenges.filter { $0.isCompleted }.count
    }
    
    var totalFailed: Int {
        completedChallenges.filter { !$0.isCompleted }.count
    }
    
    var successRate: Double {
        let total = completedChallenges.count
        guard total > 0 else { return 0 }
        return Double(totalCompleted) / Double(total)
    }
}
