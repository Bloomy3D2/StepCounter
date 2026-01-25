//
//  LanguageManager.swift
//  ChallengeApp
//
//  Менеджер для управления языком приложения
//

import Foundation
import SwiftUI

/// Поддерживаемые языки
enum AppLanguage: String, CaseIterable, Identifiable {
    case russian = "ru"
    case english = "en"
    case chinese = "zh-Hans"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .russian:
            return "Русский"
        case .english:
            return "English"
        case .chinese:
            return "中文"
        }
    }
    
    var nativeDisplayName: String {
        switch self {
        case .russian:
            return "Русский"
        case .english:
            return "English"
        case .chinese:
            return "简体中文"
        }
    }
    
    /// Получить локализатор для языка
    var locale: Locale {
        Locale(identifier: rawValue)
    }
}

/// Менеджер языков приложения
@MainActor
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
            updateBundle()
            // Принудительно обновляем UI
            objectWillChange.send()
        }
    }
    
    private var bundle: Bundle?
    private let userDefaults = UserDefaults.standard
    
    private init() {
        // Загружаем сохраненный язык или используем системный
        if let savedLanguage = userDefaults.string(forKey: "appLanguage"),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            // Определяем язык по системным настройкам
            let systemLanguage = Locale.preferredLanguages.first ?? "en"
            if systemLanguage.hasPrefix("ru") {
                self.currentLanguage = .russian
            } else if systemLanguage.hasPrefix("zh") {
                self.currentLanguage = .chinese
            } else {
                self.currentLanguage = .english
            }
        }
        updateBundle()
    }
    
    /// Обновить bundle для текущего языка
    private func updateBundle() {
        // Используем стандартный механизм локализации iOS
        // Устанавливаем предпочтительный язык
        UserDefaults.standard.set([currentLanguage.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Пытаемся найти bundle для языка
        if let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.bundle = bundle
        } else {
            // Если файл локализации не найден, используем основной bundle
            self.bundle = Bundle.main
        }
    }
    
    /// Получить локализованную строку
    func localizedString(for key: String, comment: String = "") -> String {
        // Сначала пытаемся использовать наш bundle
        if let bundle = bundle {
            let localized = bundle.localizedString(forKey: key, value: nil, table: nil)
            // Если строка не найдена, возвращаем ключ
            if localized != key {
                return localized
            }
        }
        
        // Если не найдено, используем стандартный механизм
        return NSLocalizedString(key, comment: comment)
    }
    
    /// Установить язык
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        // Уведомляем об изменении языка
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }
}

extension NSNotification.Name {
    static let languageChanged = NSNotification.Name("languageChanged")
}
