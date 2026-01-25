//
//  Logger.swift
//  ChallengeApp
//
//  Централизованное логирование
//

import Foundation
import OSLog

enum LogLevel: String {
    case debug = "🔍"
    case info = "ℹ️"
    case warning = "⚠️"
    case error = "❌"
    case critical = "🚨"
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }
}

class Logger {
    nonisolated(unsafe) static let shared = Logger()
    
    private let subsystem = Bundle.main.bundleIdentifier ?? "com.challengeapp"
    private let category = "ChallengeApp"
    private let osLogger: OSLog
    
    private init() {
        osLogger = OSLog(subsystem: subsystem, category: category)
    }
    
    // MARK: - Public Methods
    
    func log(
        _ level: LogLevel,
        _ message: String,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        let errorInfo = error != nil ? " - Error: \(error!.localizedDescription)" : ""
        let logMessage = "\(level.rawValue) [\(fileName):\(line)] \(function) - \(message)\(errorInfo)"
        
        #if DEBUG
        // В DEBUG режиме выводим в консоль
        print(logMessage)
        
        // Также логируем в системный лог
        os_log("%{public}@", log: osLogger, type: level.osLogType, logMessage)
        #else
        // В продакшене только системный лог и отправка критичных ошибок
        os_log("%{public}@", log: osLogger, type: level.osLogType, logMessage)
        
        // Критичные ошибки можно отправлять в Sentry/Firebase Crashlytics
        // Для интеграции с системой мониторинга добавьте вызов здесь:
        // if level == .critical || level == .error {
        //     Sentry.captureError(error ?? NSError(domain: "Logger", code: -1, userInfo: [NSLocalizedDescriptionKey: message]))
        // }
        #endif
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message, error: error, file: file, function: function, line: line)
    }
    
    func error(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message, error: error, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(.critical, message, error: error, file: file, function: function, line: line)
    }
}

// MARK: - Convenience Extensions

extension Logger {
    /// Логирование сетевых запросов
    func networkRequest(_ method: String, url: String, file: String = #file, function: String = #function, line: Int = #line) {
        debug("🌐 \(method) \(url)", file: file, function: function, line: line)
    }
    
    /// Логирование сетевых ответов
    func networkResponse(_ statusCode: Int, url: String, file: String = #file, function: String = #function, line: Int = #line) {
        if statusCode >= 200 && statusCode < 300 {
            info("✅ \(statusCode) \(url)", file: file, function: function, line: line)
        } else {
            error("❌ \(statusCode) \(url)", file: file, function: function, line: line)
        }
    }
    
    /// Логирование платежей
    func payment(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        info("💳 \(message)", file: file, function: function, line: line)
    }
    
    /// Логирование авторизации
    func auth(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        info("🔐 \(message)", file: file, function: function, line: line)
    }
}
