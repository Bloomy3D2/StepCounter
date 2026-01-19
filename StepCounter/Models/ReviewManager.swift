//
//  ReviewManager.swift
//  StepCounter
//
//  Менеджер для запросов отзывов в App Store
//

import Foundation
import StoreKit

@MainActor
final class ReviewManager {
    static let shared = ReviewManager()
    
    private let minDaysSinceLastRequest = 90 // 90 дней между запросами
    private let minAchievementsUnlocked = 3 // Минимум 3 достижения
    private let minDaysUsed = 3 // Минимум 3 дня использования
    
    private let lastRequestDateKey = "lastReviewRequestDate"
    private let reviewRequestCountKey = "reviewRequestCount"
    private let appInstallDateKey = "appInstallDate"
    
    private init() {
        // Устанавливаем дату установки при первом запуске
        let storage = StorageManager.shared
        if storage.loadDate(forKey: appInstallDateKey) == nil {
            storage.saveDate(Date(), forKey: appInstallDateKey)
        }
    }
    
    // MARK: - Request Review
    
    /// Запросить отзыв, если условия подходят
    func requestReviewIfAppropriate() {
        // Проверяем все условия
        guard shouldRequestReview() else { return }
        
        // Запрашиваем отзыв через StoreKit
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
            
            // Сохраняем дату запроса
            let storage = StorageManager.shared
            storage.saveDate(Date(), forKey: lastRequestDateKey)
            
            // Увеличиваем счётчик запросов
            let count = storage.loadInt(forKey: reviewRequestCountKey)
            storage.saveInt(count + 1, forKey: reviewRequestCountKey)
        }
    }
    
    // MARK: - Check Conditions
    
    private func shouldRequestReview() -> Bool {
        let storage = StorageManager.shared
        
        // Проверка 1: Прошло достаточно времени с последнего запроса
        if let lastRequestDate = storage.loadDate(forKey: lastRequestDateKey) {
            let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastRequestDate, to: Date()).day ?? 0
            if daysSinceLastRequest < minDaysSinceLastRequest {
                return false
            }
        }
        
        // Проверка 2: Приложение используется минимум N дней
        if let installDate = storage.loadDate(forKey: appInstallDateKey) {
            let daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
            if daysSinceInstall < minDaysUsed {
                return false
            }
        }
        
        // Проверка 3: Не более 3 запросов за всё время
        let requestCount = storage.loadInt(forKey: reviewRequestCountKey)
        if requestCount >= 3 {
            return false
        }
        
        return true
    }
    
    // MARK: - Convenience Methods
    
    /// Запросить отзыв после достижения цели
    func requestReviewAfterGoal(achievementsUnlocked: Int) {
        // Запрашиваем, если разблокировано достаточно достижений
        if achievementsUnlocked >= minAchievementsUnlocked {
            requestReviewIfAppropriate()
        }
    }
    
    /// Запросить отзыв после N-го достижения
    func requestReviewAfterAchievement(count: Int) {
        if count == minAchievementsUnlocked {
            requestReviewIfAppropriate()
        }
    }
}
