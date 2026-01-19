//
//  ReferralManager.swift
//  StepCounter
//
//  Система приглашений друзей (реферальная программа)
//

import Foundation
import Combine

/// Реферальная информация пользователя
struct ReferralInfo: Codable {
    let referralCode: String // Уникальный код пользователя
    let invitedCount: Int // Сколько друзей приглашено
    let completedCount: Int // Сколько зарегистрировалось по коду
    let totalRewardsEarned: Int // Всего получено наград (XP)
    let lastRewardDate: Date? // Дата последней награды
    
    static let `default` = ReferralInfo(
        referralCode: generateReferralCode(),
        invitedCount: 0,
        completedCount: 0,
        totalRewardsEarned: 0,
        lastRewardDate: nil
    )
    
    private static func generateReferralCode() -> String {
        // Генерируем уникальный код из 6 символов (буквы и цифры)
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }
}

/// Награда за реферала
struct ReferralReward: Codable {
    let referralCode: String
    let newUserReward: Int // XP для нового пользователя
    let referrerReward: Int // XP для пригласившего
    let premiumDaysForNewUser: Int // Дни Premium для нового
    let premiumDaysForReferrer: Int // Дни Premium для пригласившего
    let date: Date
}

/// Менеджер реферальной системы
@MainActor
final class ReferralManager: ObservableObject {
    static let shared = ReferralManager()
    
    @Published var referralInfo: ReferralInfo
    @Published var pendingRewards: [ReferralReward] = []
    
    private let referralInfoKey = "referralInfo"
    private let pendingRewardsKey = "pendingRewards"
    private let storage = StorageManager.shared
    
    // Награды
    private let newUserXP = 1000
    private let referrerXP = 2000
    private let newUserPremiumDays = 7
    private let referrerPremiumDays = 7
    
    private init() {
        // Загружаем или создаём новую реферальную информацию
        if let saved = storage.loadSafe(ReferralInfo.self, forKey: referralInfoKey) {
            referralInfo = saved
        } else {
            referralInfo = ReferralInfo.default
            saveReferralInfo()
        }
        
        pendingRewards = storage.loadSafe([ReferralReward].self, forKey: pendingRewardsKey) ?? []
    }
    
    // MARK: - Public Methods
    
    /// Регистрация по реферальному коду (для нового пользователя при первом запуске)
    func registerWithReferralCode(_ code: String) -> Bool {
        // Проверяем, что код валидный и не собственный
        guard code.count == 6,
              code != referralInfo.referralCode,
              code.allSatisfy({ $0.isLetter || $0.isNumber }) else {
            return false
        }
        
        // Сохраняем использованный код (чтобы не использовать повторно)
        let usedCodesKey = "usedReferralCodes"
        var usedCodes = storage.loadSafe([String].self, forKey: usedCodesKey) ?? []
        
        guard !usedCodes.contains(code) else {
            return false // Код уже использован
        }
        
        usedCodes.append(code)
        do {
            try storage.save(usedCodes, forKey: usedCodesKey)
        } catch {
            Logger.shared.logStorageError(error, key: usedCodesKey)
        }
        
        // Создаём награду для текущего пользователя (нового)
        let reward = ReferralReward(
            referralCode: code,
            newUserReward: newUserXP,
            referrerReward: referrerXP,
            premiumDaysForNewUser: newUserPremiumDays,
            premiumDaysForReferrer: referrerPremiumDays,
            date: Date()
        )
        
        pendingRewards.append(reward)
        savePendingRewards()
        
        // Применяем награду новому пользователю
        applyNewUserReward(reward)
        
        return true
    }
    
    /// Применение награды для нового пользователя
    private func applyNewUserReward(_ reward: ReferralReward) {
        // Даём Premium дни (сохраняем в UserDefaults)
        let premiumDaysKey = "premiumDaysFromReferral"
        let currentDays = storage.loadInt(forKey: premiumDaysKey)
        try? storage.save(currentDays + reward.premiumDaysForNewUser, forKey: premiumDaysKey)
        
        // XP будет добавлен через levelManager (передаётся извне)
    }
    
    /// Применение награды для пригласившего (вызывается при регистрации нового пользователя)
    func applyReferrerReward(for code: String, levelManager: LevelManager? = nil) {
        // Находим награду для этого кода
        guard let rewardIndex = pendingRewards.firstIndex(where: { $0.referralCode == code }) else {
            return
        }
        
        let reward = pendingRewards[rewardIndex]
        
        // Обновляем статистику
        var updatedInfo = referralInfo
        updatedInfo = ReferralInfo(
            referralCode: updatedInfo.referralCode,
            invitedCount: updatedInfo.invitedCount,
            completedCount: updatedInfo.completedCount + 1,
            totalRewardsEarned: updatedInfo.totalRewardsEarned + reward.referrerReward,
            lastRewardDate: Date()
        )
        referralInfo = updatedInfo
        saveReferralInfo()
        
        // Применяем награду пригласившему
        if let levelManager = levelManager {
            levelManager.addXP(reward.referrerReward)
        }
        
        // Premium дни
        let premiumDaysKey = "premiumDaysFromReferral"
        let currentDays = storage.loadInt(forKey: premiumDaysKey)
        try? storage.save(currentDays + reward.premiumDaysForReferrer, forKey: premiumDaysKey)
        
        // Удаляем награду из ожидающих
        pendingRewards.remove(at: rewardIndex)
        savePendingRewards()
    }
    
    /// Проверка возможности пригласить друга
    func canInviteFriend() -> Bool {
        let subscriptionManager = SubscriptionManager.shared
        let hasUnlimitedFriends = subscriptionManager.hasAccess(to: .unlimitedFriends)
        
        // Для free пользователей: максимум 10 приглашений
        let maxFriendsForFree = 10
        if hasUnlimitedFriends {
            return true
        } else {
            return referralInfo.invitedCount < maxFriendsForFree
        }
    }
    
    /// Генерация ссылки для приглашения
    func generateInviteLink() -> String {
        // Deep link или обычная ссылка
        let baseURL = "https://stepcounter.app/invite" // Замените на реальный домен
        return "\(baseURL)/\(referralInfo.referralCode)"
    }
    
    /// Текст для sharing
    func generateInviteText() -> String {
        return """
        🚶 Присоединяйся к StepCounter - трекеру шагов!
        
        Используй мой код: \(referralInfo.referralCode)
        
        Получи 7 дней Premium и 1000 XP! 🎁
        
        \(generateInviteLink())
        """
    }
    
    // MARK: - Persistence
    
    private func saveReferralInfo() {
        do {
            try storage.save(referralInfo, forKey: referralInfoKey)
        } catch {
            Logger.shared.logStorageError(error, key: referralInfoKey)
        }
    }
    
    private func savePendingRewards() {
        do {
            try storage.save(pendingRewards, forKey: pendingRewardsKey)
        } catch {
            Logger.shared.logStorageError(error, key: pendingRewardsKey)
        }
    }
}
