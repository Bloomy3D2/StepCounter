//
//  AppConstants.swift
//  StepCounter
//
//  Централизованные константы приложения
//

import Foundation
import SwiftUI

/// Централизованные константы приложения
enum AppConstants {
    
    // MARK: - Steps
    
    enum Steps {
        static let defaultGoal = 10000
        static let minGoal = 1000
        static let maxGoal = 50000
        static let almostThereThreshold = 1000 // Порог для уведомления "почти достигнуто"
    }
    
    // MARK: - Pet
    
    enum Pet {
        static let maxAccessoryXP = 500000
        static let feedXPPerStep = 1
    }
    
    // MARK: - XP & Rewards
    
    enum XP {
        static let perHundredSteps = 1 // 1 XP за 100 шагов
        static let bonusFor10kSteps = 20
        static let bonusFor15kSteps = 30
        static let bonusFor20kSteps = 50
        static let dailyGoalBonus = 50
        static let streak7Days = 1000
        static let streak30Days = 5000
        static let streak100Days = 20000
    }
    
    // MARK: - Quest Milestones
    
    enum QuestMilestones {
        static let steps5k = 5000
        static let steps8k = 8000
        static let steps10k = 10000
        static let steps12k = 12000
        static let steps15k = 15000
        static let steps20k = 20000
        static let distance3km = 3000
        static let distance5km = 5000
        static let distance10km = 10000
        static let calories200 = 200
        static let calories400 = 400
        static let calories600 = 600
    }
    
    // MARK: - HealthKit Validation
    
    enum HealthKitLimits {
        static let maxSteps = 1_000_000
        static let maxDistanceMeters = 500_000 // 500 км
        static let maxCalories = 10_000
        static let maxActiveMinutes = 1440 // 24 часа
        static let maxHourlySteps = 50_000
    }
    
    // MARK: - Layout
    
    enum Layout {
        static let cardPadding: CGFloat = 16
        static let cardCornerRadius: CGFloat = 16
        static let screenHorizontalPadding: CGFloat = 20
        static let screenVerticalPadding: CGFloat = 20
        static let cardSpacing: CGFloat = 12
        static let sectionSpacing: CGFloat = 24
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let defaultDuration: Double = 0.3
        static let springResponse: Double = 0.6
        static let springDamping: Double = 0.8
        static let bounceDuration: Double = 0.6
    }
    
    // MARK: - Colors (Default - для миграции на ThemeManager)
    
    enum DefaultColors {
        static let backgroundColor = Color(red: 0.02, green: 0.02, blue: 0.05)
        static let cardColor = Color(red: 0.08, green: 0.08, blue: 0.12)
        static let accentGreen = Color(red: 0.3, green: 0.85, blue: 0.5)
        static let accentBlue = Color(red: 0.3, green: 0.6, blue: 1.0)
        static let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
        static let accentGold = Color(red: 1.0, green: 0.84, blue: 0.0)
    }
    
    // MARK: - Font Sizes
    
    enum FontSize {
        static let largeTitle: CGFloat = 44
        static let title: CGFloat = 28
        static let headline: CGFloat = 22
        static let body: CGFloat = 17
        static let callout: CGFloat = 16
        static let subheadline: CGFloat = 15
        static let footnote: CGFloat = 13
        static let caption: CGFloat = 12
        static let caption2: CGFloat = 11
    }
    
    // MARK: - URLs
    
    enum URLs {
        /// URL политики конфиденциальности на GitHub Pages
        static let privacyPolicy = "https://bloomy3d2.github.io/StepCounter/privacy-policy.html"
    }
    
    // MARK: - Contact Information
    
    enum Contact {
        /// Email поддержки приложения
        static let supportEmail = "Miari14@yandex.ru"
    }
}

// MARK: - Notification Names

extension NSNotification.Name {
    static let premiumStatusChanged = NSNotification.Name("premiumStatusChanged")
}
