//
//  String+Localization.swift
//  ChallengeApp
//
//  Расширение для удобного использования локализации
//

import Foundation

extension String {
    /// Локализованная строка
    @MainActor
    var localized: String {
        LanguageManager.shared.localizedString(for: self)
    }
    
    /// Локализованная строка с комментарием
    @MainActor
    func localized(comment: String = "") -> String {
        LanguageManager.shared.localizedString(for: self, comment: comment)
    }
    
    /// Локализованная строка с аргументами
    @MainActor
    func localized(_ arguments: CVarArg...) -> String {
        let format = LanguageManager.shared.localizedString(for: self)
        return String(format: format, arguments: arguments)
    }
}
