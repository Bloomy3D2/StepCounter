//
//  DateFormatter+Extensions.swift
//  ChallengeApp
//
//  Централизованная утилита для парсинга ISO8601 дат
//

import Foundation

extension ISO8601DateFormatter {
    /// Гибкий форматтер с поддержкой fractional seconds
    nonisolated(unsafe) static let flexible: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    /// Форматтер без fractional seconds (fallback)
    nonisolated(unsafe) static let standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    /// Парсинг ISO8601 строки с автоматическим fallback
    /// - Parameter string: ISO8601 строка
    /// - Returns: Date или nil
    static func parse(_ string: String) -> Date? {
        return flexible.date(from: string) ?? standard.date(from: string)
    }
    
    /// Парсинг ISO8601 строки с fallback на текущую дату
    /// - Parameter string: ISO8601 строка
    /// - Returns: Date (никогда не nil)
    static func parseOrNow(_ string: String) -> Date {
        return parse(string) ?? Date()
    }
}
