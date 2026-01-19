//
//  SeasonManager.swift
//  StepCounter
//
//  Система сезонов с наградами и лидербордами
//

import Foundation
import SwiftUI

// MARK: - Season

struct Season: Identifiable, Codable {
    let id: String
    let name: String // "Весна 2025"
    let startDate: Date
    let endDate: Date
    let theme: SeasonTheme
    var rewards: [SeasonReward]
    var leaderboard: SeasonLeaderboard
    
    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }
    
    var daysRemaining: Int {
        guard isActive else { return 0 }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, days)
    }
    
    var progress: Double {
        guard isActive else { return 0 }
        let totalDuration = endDate.timeIntervalSince(startDate)
        let elapsed = Date().timeIntervalSince(startDate)
        return min(1.0, max(0.0, elapsed / totalDuration))
    }
}

// MARK: - Season Theme

enum SeasonTheme: String, Codable, CaseIterable {
    case spring = "spring"
    case summer = "summer"
    case autumn = "autumn"
    case winter = "winter"
    
    var name: String {
        switch self {
        case .spring: return "Весна"
        case .summer: return "Лето"
        case .autumn: return "Осень"
        case .winter: return "Зима"
        }
    }
    
    var icon: String {
        switch self {
        case .spring: return "🌸"
        case .summer: return "☀️"
        case .autumn: return "🍂"
        case .winter: return "❄️"
        }
    }
    
    var colors: [Color] {
        switch self {
        case .spring:
            return [Color(hex: "FFB6C1"), Color(hex: "98FB98")]
        case .summer:
            return [Color(hex: "FFD700"), Color(hex: "FFA500")]
        case .autumn:
            return [Color(hex: "D2691E"), Color(hex: "CD853F")]
        case .winter:
            return [Color(hex: "E0E0E0"), Color(hex: "87CEEB")]
        }
    }
}

// MARK: - Season Reward

struct SeasonReward: Identifiable, Codable {
    let id: String
    let level: Int
    let title: String
    let description: String
    let rewardType: SeasonRewardType
    let rewardValue: Int
    var isUnlocked: Bool
    
    enum SeasonRewardType: String, Codable {
        case xp
        case premiumDays
        case theme
        case petAccessory
        case achievement
    }
}

// MARK: - Season Leaderboard Entry

struct SeasonLeaderboardEntry: Identifiable, Codable {
    let id: String
    let userId: String
    let userName: String
    let totalSteps: Int
    let rank: Int
    let avatar: String?
}

// MARK: - Season Leaderboard

struct SeasonLeaderboard: Codable {
    var entries: [SeasonLeaderboardEntry]
    var userRank: Int?
    var userSteps: Int
    
    var topEntries: [SeasonLeaderboardEntry] {
        Array(entries.prefix(10))
    }
}

// MARK: - Season Manager

@MainActor
final class SeasonManager: ObservableObject {
    static let shared = SeasonManager()
    
    @Published var currentSeason: Season?
    @Published var allSeasons: [Season] = []
    @Published var userSeasonXP: Int = 0
    @Published var userSeasonLevel: Int = 1
    
    private let storage = StorageManager.shared
    private let seasonsKey = "seasons"
    private let currentSeasonKey = "currentSeasonId"
    private let userSeasonXPKey = "userSeasonXP"
    
    private init() {
        Task { @MainActor in
            loadSeasons()
            initializeSeasons()
            updateCurrentSeason()
        }
    }
    
    // MARK: - Season Management
    
    func updateCurrentSeason() {
        currentSeason = allSeasons.first { $0.isActive }
        
        // Если нет активного сезона, создаем новый
        if currentSeason == nil {
            createNextSeason()
        }
    }
    
    private func initializeSeasons() {
        guard allSeasons.isEmpty else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        
        // Определяем текущий сезон
        let currentSeasonTheme: SeasonTheme
        switch month {
        case 3...5: currentSeasonTheme = .spring
        case 6...8: currentSeasonTheme = .summer
        case 9...11: currentSeasonTheme = .autumn
        default: currentSeasonTheme = .winter
        }
        
        // Создаем текущий сезон (3 месяца)
        let startDate = calendar.date(from: DateComponents(year: year, month: (month - 1) / 3 * 3 + 1, day: 1)) ?? now
        let endDate = calendar.date(byAdding: .month, value: 3, to: startDate) ?? now
        
        let season = Season(
            id: "season-\(year)-\(currentSeasonTheme.rawValue)",
            name: "\(currentSeasonTheme.name) \(year)",
            startDate: startDate,
            endDate: endDate,
            theme: currentSeasonTheme,
            rewards: generateSeasonRewards(for: currentSeasonTheme),
            leaderboard: SeasonLeaderboard(entries: [], userRank: nil, userSteps: 0)
        )
        
        allSeasons.append(season)
        saveSeasons()
    }
    
    private func createNextSeason() {
        guard let lastSeason = allSeasons.last else { return }
        
        let calendar = Calendar.current
        let nextStartDate = calendar.date(byAdding: .day, value: 1, to: lastSeason.endDate) ?? Date()
        let nextEndDate = calendar.date(byAdding: .month, value: 3, to: nextStartDate) ?? Date()
        
        // Определяем следующий сезон
        let nextTheme = getNextTheme(after: lastSeason.theme)
        let year = calendar.component(.year, from: nextStartDate)
        
        let season = Season(
            id: "season-\(year)-\(nextTheme.rawValue)",
            name: "\(nextTheme.name) \(year)",
            startDate: nextStartDate,
            endDate: nextEndDate,
            theme: nextTheme,
            rewards: generateSeasonRewards(for: nextTheme),
            leaderboard: SeasonLeaderboard(entries: [], userRank: nil, userSteps: 0)
        )
        
        allSeasons.append(season)
        saveSeasons()
        currentSeason = season
    }
    
    private func getNextTheme(after theme: SeasonTheme) -> SeasonTheme {
        switch theme {
        case .spring: return .summer
        case .summer: return .autumn
        case .autumn: return .winter
        case .winter: return .spring
        }
    }
    
    // MARK: - Rewards
    
    private func generateSeasonRewards(for theme: SeasonTheme) -> [SeasonReward] {
        var rewards: [SeasonReward] = []
        
        // 10 уровней наград
        for level in 1...10 {
            let xpNeeded = level * 1000 // 1000, 2000, 3000... XP на уровень
            
            var reward: SeasonReward
            switch level {
            case 1:
                reward = SeasonReward(
                    id: "\(theme.rawValue)-\(level)",
                    level: level,
                    title: "Старт сезона",
                    description: "\(xpNeeded) XP",
                    rewardType: .xp,
                    rewardValue: 500,
                    isUnlocked: false
                )
            case 3:
                reward = SeasonReward(
                    id: "\(theme.rawValue)-\(level)",
                    level: level,
                    title: "Тема сезона",
                    description: "Эксклюзивная тема \(theme.name)",
                    rewardType: .theme,
                    rewardValue: 0,
                    isUnlocked: false
                )
            case 5:
                reward = SeasonReward(
                    id: "\(theme.rawValue)-\(level)",
                    level: level,
                    title: "Премиум бонус",
                    description: "7 дней Premium",
                    rewardType: .premiumDays,
                    rewardValue: 7,
                    isUnlocked: false
                )
            case 10:
                reward = SeasonReward(
                    id: "\(theme.rawValue)-\(level)",
                    level: level,
                    title: "Чемпион сезона",
                    description: "Легендарное достижение",
                    rewardType: .achievement,
                    rewardValue: 0,
                    isUnlocked: false
                )
            default:
                reward = SeasonReward(
                    id: "\(theme.rawValue)-\(level)",
                    level: level,
                    title: "Уровень \(level)",
                    description: "\(xpNeeded) XP",
                    rewardType: .xp,
                    rewardValue: level * 100,
                    isUnlocked: false
                )
            }
            
            rewards.append(reward)
        }
        
        return rewards
    }
    
    // MARK: - User Progress
    
    func addSeasonXP(_ xp: Int) {
        guard currentSeason != nil else { return }
        
        userSeasonXP += xp
        storage.saveInt(userSeasonXP, forKey: userSeasonXPKey)
        
        // Проверяем, разблокировались ли награды
        checkUnlockedRewards()
        
        // Обновляем уровень
        userSeasonLevel = calculateSeasonLevel()
    }
    
    private func calculateSeasonLevel() -> Int {
        var totalXP = 0
        var level = 1
        
        for rewardLevel in 1...10 {
            let xpNeeded = rewardLevel * 1000
            totalXP += xpNeeded
            
            if userSeasonXP >= totalXP {
                level = rewardLevel + 1
            } else {
                break
            }
        }
        
        return min(level, 10)
    }
    
    private func checkUnlockedRewards() {
        guard var season = currentSeason else { return }
        
        let level = userSeasonLevel
        for index in season.rewards.indices {
            if season.rewards[index].level <= level && !season.rewards[index].isUnlocked {
                season.rewards[index].isUnlocked = true
                unlockReward(season.rewards[index])
            }
        }
        
        // Обновляем сезон
        if let seasonIndex = allSeasons.firstIndex(where: { $0.id == season.id }) {
            allSeasons[seasonIndex] = season
            currentSeason = season
            saveSeasons()
        }
    }
    
    private func unlockReward(_ reward: SeasonReward) {
        switch reward.rewardType {
        case .xp:
            // XP уже учтено
            break
        case .premiumDays:
            SubscriptionManager.shared.addPremiumDays(reward.rewardValue)
        case .theme:
            // Тема разблокирована, нужно добавить в ThemeManager
            break
        case .petAccessory:
            // Аксессуар разблокирован
            break
        case .achievement:
            // Достижение разблокировано
            break
        }
    }
    
    // MARK: - Leaderboard
    
    func updateUserSteps(_ steps: Int) {
        guard var season = currentSeason else { return }
        season.leaderboard.userSteps = steps
        currentSeason = season
        
        // Обновляем в списке
        if let index = allSeasons.firstIndex(where: { $0.id == season.id }) {
            allSeasons[index] = season
            saveSeasons()
        }
    }
    
    // MARK: - Storage
    
    private func loadSeasons() {
        if let loaded = storage.loadSafe([Season].self, forKey: seasonsKey) {
            allSeasons = loaded
        }
        
        if let loaded = storage.loadSafe(Int.self, forKey: userSeasonXPKey) {
            userSeasonXP = loaded
        }
    }
    
    private func saveSeasons() {
        do {
            try storage.save(allSeasons, forKey: seasonsKey)
            try storage.save(userSeasonXP, forKey: userSeasonXPKey)
        } catch {
            Logger.shared.logStorageError(error, key: seasonsKey)
        }
    }
}
