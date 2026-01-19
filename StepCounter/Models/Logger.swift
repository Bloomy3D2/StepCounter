//
//  Logger.swift
//  StepCounter
//
//  Централизованная система логирования
//

import Foundation
import OSLog

/// Уровни логирования
enum LogLevel {
    case debug
    case info
    case warning
    case error
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

/// Централизованный логгер
@MainActor
final class Logger {
    static let shared = Logger()
    
    private let subsystem = Bundle.main.bundleIdentifier ?? "com.stepcounter"
    private let category = "StepCounter"
    private let osLogger: os.Logger
    
    private init() {
        osLogger = os.Logger(subsystem: subsystem, category: category)
    }
    
    /// Логировать сообщение
    /// - Parameters:
    ///   - message: Текст сообщения
    ///   - level: Уровень логирования
    ///   - file: Имя файла (автоматически)
    ///   - function: Имя функции (автоматически)
    ///   - line: Номер строки (автоматически)
    func log(
        _ message: String,
        level: LogLevel = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        
        // Используем OSLog для системного логирования
        osLogger.log(level: level.osLogType, "\(logMessage)")
        
        // В DEBUG режиме также выводим в консоль
        #if DEBUG
        print("\(level.emoji) \(logMessage)")
        #endif
    }
    
    /// Логировать ошибку
    func logError(
        _ error: Error,
        context: String = "",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let message = context.isEmpty
            ? "\(error.localizedDescription)"
            : "\(context): \(error.localizedDescription)"
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    /// Логировать предупреждение
    func logWarning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    /// Логировать информацию
    func logInfo(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    /// Логировать отладочную информацию
    func logDebug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        #if DEBUG
        log(message, level: .debug, file: file, function: function, line: line)
        #endif
    }
}

// MARK: - Convenience Extensions

extension Logger {
    /// Быстрое логирование ошибки Storage
    func logStorageError(_ error: Error, key: String) {
        logError(error, context: "StorageManager error for key: \(key)")
    }
    
    /// Быстрое логирование ошибки HealthKit
    func logHealthKitError(_ error: Error, operation: String) {
        logError(error, context: "HealthKit \(operation) failed")
    }
}
