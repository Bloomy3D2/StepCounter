//
//  PrivacyConsentManager.swift
//  StepCounter
//
//  Менеджер для управления согласием на обработку персональных данных
//

import Foundation

/// Менеджер согласия на обработку персональных данных
@MainActor
final class PrivacyConsentManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = PrivacyConsentManager()
    
    // MARK: - Published Properties
    
    /// Согласие дано
    @Published var hasConsent: Bool = false
    
    /// Версия политики конфиденциальности, с которой дано согласие
    @Published var consentPolicyVersion: String = "1.0"
    
    /// Дата и время согласия
    @Published var consentDate: Date?
    
    // MARK: - Private Properties
    
    private let consentKey = "privacyConsentGiven"
    private let consentVersionKey = "privacyConsentVersion"
    private let consentDateKey = "privacyConsentDate"
    private let hasSeenOnboardingKey = "hasSeenOnboarding"
    
    // Текущая версия политики конфиденциальности
    private let currentPolicyVersion = "1.0"
    
    // MARK: - Initialization
    
    private init() {
        loadConsentStatus()
    }
    
    // MARK: - Public Methods
    
    /// Проверить, нужно ли показать экран согласия
    var shouldShowConsentScreen: Bool {
        // Показываем экран если:
        // 1. Пользователь еще не видел onboarding (первый запуск) ИЛИ
        // 2. Согласие не дано ИЛИ
        // 3. Версия политики изменилась (нужно пересогласие)
        if !hasSeenOnboarding {
            return true // Первый запуск - всегда показываем
        }
        
        if !hasConsent {
            return true // Согласие не дано - показываем
        }
        
        if consentPolicyVersion != currentPolicyVersion {
            return true // Версия политики изменилась - нужно пересогласие
        }
        
        return false // Все условия выполнены - не показываем
    }
    
    /// Проверить, видел ли пользователь onboarding
    var hasSeenOnboarding: Bool {
        UserDefaults.standard.bool(forKey: hasSeenOnboardingKey)
    }
    
    /// Дать согласие на обработку персональных данных
    func giveConsent() {
        hasConsent = true
        consentPolicyVersion = currentPolicyVersion
        consentDate = Date()
        
        saveConsentStatus()
        
        Logger.shared.logInfo("Пользователь дал согласие на обработку ПДн. Версия политики: \(currentPolicyVersion)")
    }
    
    /// Отозвать согласие
    func revokeConsent() {
        hasConsent = false
        consentDate = nil
        
        saveConsentStatus()
        
        Logger.shared.logInfo("Пользователь отозвал согласие на обработку ПДн")
    }
    
    /// Отметить, что пользователь видел onboarding
    func markOnboardingSeen() {
        UserDefaults.standard.set(true, forKey: hasSeenOnboardingKey)
    }
    
    /// Получить информацию о согласии
    var consentInfo: ConsentInfo {
        ConsentInfo(
            hasConsent: hasConsent,
            version: consentPolicyVersion,
            date: consentDate
        )
    }
    
    // MARK: - Private Methods
    
    private func loadConsentStatus() {
        hasConsent = UserDefaults.standard.bool(forKey: consentKey)
        consentPolicyVersion = UserDefaults.standard.string(forKey: consentVersionKey) ?? "1.0"
        
        if let dateData = UserDefaults.standard.object(forKey: consentDateKey) as? Date {
            consentDate = dateData
        }
    }
    
    private func saveConsentStatus() {
        UserDefaults.standard.set(hasConsent, forKey: consentKey)
        UserDefaults.standard.set(consentPolicyVersion, forKey: consentVersionKey)
        
        if let date = consentDate {
            UserDefaults.standard.set(date, forKey: consentDateKey)
        } else {
            UserDefaults.standard.removeObject(forKey: consentDateKey)
        }
    }
}

// MARK: - Consent Info

struct ConsentInfo {
    let hasConsent: Bool
    let version: String
    let date: Date?
    
    var formattedDate: String? {
        guard let date = date else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy, HH:mm"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}
