//
//  NetworkRetry.swift
//  ChallengeApp
//
//  Retry логика для сетевых запросов
//

import Foundation

protocol NetworkRetryProtocol {
    func execute<T>(
        maxAttempts: Int,
        delay: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T
}

// MARK: - Default Implementation
extension NetworkRetryProtocol {
    func execute<T>(
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await execute(
            maxAttempts: 3,
            delay: 1.0,
            operation: operation
        )
    }
}

class NetworkRetry: NetworkRetryProtocol {
    nonisolated(unsafe) static let shared = NetworkRetry()
    
    private init() {
        Logger.shared.info("NetworkRetry initialized")
    }
    
    /// Выполнить операцию с повторными попытками
    /// - Parameters:
    ///   - maxAttempts: Максимальное количество попыток (по умолчанию 3)
    ///   - delay: Задержка между попытками в секундах (по умолчанию 1.0)
    ///   - operation: Асинхронная операция для выполнения
    /// - Returns: Результат операции
    /// - Throws: Ошибка после всех неудачных попыток
    func execute<T>(
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            // Проверяем отмену перед каждой попыткой
            try Task.checkCancellation()
            
            do {
                let result = try await operation()
                
                if attempt > 1 {
                    Logger.shared.info("Operation succeeded on attempt \(attempt)")
                }
                
                return result
            } catch is CancellationError {
                // НЕ ретраим отменённые задачи - сразу пробрасываем
                Logger.shared.debug("CancellationError caught, not retrying")
                throw CancellationError()
            } catch let error where error.localizedDescription.lowercased().contains("cancel") {
                // Также не ретраим ошибки связанные с отменой
                Logger.shared.debug("Cancel-related error caught: \(error.localizedDescription), not retrying")
                throw error
            } catch {
                lastError = error
                
                // Проверяем, стоит ли повторять
                let appError = ErrorHandler.handle(error)
                if !appError.isRetryable {
                    Logger.shared.warning("Error is not retryable: \(appError.errorDescription ?? "")")
                    throw error
                }
                
                // Если это не последняя попытка, ждем и повторяем
                if attempt < maxAttempts {
                    let exponentialDelay = delay * pow(2.0, Double(attempt - 1)) // Экспоненциальная задержка
                    Logger.shared.warning("Attempt \(attempt) failed, retrying in \(exponentialDelay)s... Error: \(error.localizedDescription)")
                    
                    try await Task.sleep(nanoseconds: UInt64(exponentialDelay * 1_000_000_000))
                } else {
                    Logger.shared.error("All \(maxAttempts) attempts failed. Last error: \(error.localizedDescription)")
                }
            }
        }
        
        // Все попытки исчерпаны
        throw lastError ?? NSError(domain: "NetworkRetry", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
    }
}

// MARK: - Convenience Extensions

extension NetworkRetry {
    /// Выполнить операцию с экспоненциальной задержкой
    func executeWithExponentialBackoff<T>(
        maxAttempts: Int = 3,
        initialDelay: TimeInterval = 1.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await execute(maxAttempts: maxAttempts, delay: initialDelay, operation: operation)
    }
    
    /// Выполнить операцию только для сетевых ошибок
    func executeForNetworkErrors<T>(
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await execute(maxAttempts: maxAttempts, delay: delay) {
            do {
                return try await operation()
            } catch {
                let appError = ErrorHandler.handle(error)
                // Повторяем только для сетевых ошибок
                switch appError {
                case .networkError, .networkTimeout, .networkUnavailable, .serviceUnavailable:
                    throw error
                default:
                    // Для других ошибок не повторяем
                    throw error
                }
            }
        }
    }
}
