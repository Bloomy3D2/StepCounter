//
//  AppError.swift
//  ChallengeApp
//
//  Унифицированные ошибки приложения
//

import Foundation

enum AppError: LocalizedError {
    // MARK: - Network Errors
    case networkError(Error)
    case networkTimeout
    case networkUnavailable
    
    // MARK: - Authentication Errors
    case authenticationRequired
    case invalidCredentials
    case emailNotConfirmed
    case sessionExpired
    
    // MARK: - Validation Errors
    case invalidData(String)
    case invalidEmail
    case invalidPassword
    case invalidAmount
    
    // MARK: - Payment Errors
    case paymentFailed(String)
    case paymentCancelled
    case paymentTimeout
    case refundFailed(String)
    case insufficientFunds
    
    // MARK: - Challenge Errors
    case challengeNotFound
    case challengeNotActive
    case challengeAlreadyEnded
    case challengeAlreadyCompleted
    case challengeAlreadyFailed
    case alreadyJoined
    case challengeNotStarted
    case cannotJoinChallenge(String)
    
    // MARK: - Data Errors
    case dataNotFound
    case dataCorrupted
    case saveFailed
    
    // MARK: - Server Errors
    case serverError(String)
    case serviceUnavailable
    
    // MARK: - Cancellation
    case operationCancelled
    
    // MARK: - Unknown
    case unknown(Error)
    
    // MARK: - Error Descriptions
    
    var errorDescription: String? {
        switch self {
        // Network
        case .networkError(let error):
            return "Ошибка сети: \(error.localizedDescription)"
        case .networkTimeout:
            return "Превышено время ожидания. Проверьте подключение к интернету."
        case .networkUnavailable:
            return "Нет подключения к интернету. Проверьте настройки сети."
        
        // Authentication
        case .authenticationRequired:
            return "Требуется авторизация. Пожалуйста, войдите в приложение."
        case .invalidCredentials:
            return "Неверный email или пароль."
        case .emailNotConfirmed:
            return "Email не подтвержден. Проверьте почту и подтвердите регистрацию."
        case .sessionExpired:
            return "Сессия истекла. Пожалуйста, войдите снова."
        
        // Validation
        case .invalidData(let message):
            return "Неверные данные: \(message)"
        case .invalidEmail:
            return "Неверный формат email."
        case .invalidPassword:
            return "Пароль должен содержать минимум 6 символов."
        case .invalidAmount:
            return "Неверная сумма."
        
        // Payment
        case .paymentFailed(let message):
            return "Ошибка платежа: \(message)"
        case .paymentCancelled:
            return "Платеж отменен."
        case .paymentTimeout:
            return "Превышено время ожидания платежа."
        case .refundFailed(let message):
            return "Ошибка возврата средств: \(message)"
        case .insufficientFunds:
            return "Недостаточно средств."
        
        // Challenge
        case .challengeNotFound:
            return "Челлендж не найден."
        case .challengeNotActive:
            return "Челлендж неактивен."
        case .challengeAlreadyEnded:
            return "Челлендж уже закончился."
        case .challengeAlreadyCompleted:
            return "Челлендж уже завершён."
        case .challengeAlreadyFailed:
            return "Челлендж уже провален."
        case .alreadyJoined:
            return "Вы уже участвуете в этом челлендже."
        case .challengeNotStarted:
            return "Челлендж еще не начался."
        case .cannotJoinChallenge(let reason):
            return "Не удалось вступить в челлендж: \(reason)"
        
        // Data
        case .dataNotFound:
            return "Данные не найдены."
        case .dataCorrupted:
            return "Данные повреждены."
        case .saveFailed:
            return "Не удалось сохранить данные."
        
        // Server
        case .serverError(let message):
            return "Ошибка сервера: \(message)"
        case .serviceUnavailable:
            return "Сервис временно недоступен. Попробуйте позже."
        
        // Cancellation
        case .operationCancelled:
            return "Операция отменена."
        
        // Unknown
        case .unknown(let error):
            // Не показываем технические сообщения пользователю
            let errorDesc = error.localizedDescription
            if errorDesc.contains("couldn't be read") || 
               errorDesc.contains("missing") ||
               errorDesc.contains("decoding") ||
               errorDesc.contains("DecodingError") {
                return "Произошла ошибка при обработке данных."
            }
            return errorDesc.isEmpty ? "Произошла неизвестная ошибка." : "Произошла ошибка. Попробуйте еще раз."
        }
    }
    
    // MARK: - Recovery Suggestions
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError, .networkTimeout, .networkUnavailable:
            return "Проверьте подключение к интернету и попробуйте снова."
        case .authenticationRequired, .sessionExpired:
            return "Войдите в приложение снова."
        case .emailNotConfirmed:
            return "Проверьте почту и перейдите по ссылке подтверждения."
        case .paymentFailed, .paymentTimeout:
            return "Попробуйте еще раз или выберите другой способ оплаты."
        case .challengeNotFound, .challengeNotActive:
            return "Выберите другой челлендж."
        case .alreadyJoined:
            return "Вы уже участвуете в этом челлендже."
        default:
            return "Попробуйте еще раз. Если проблема сохраняется, обратитесь в поддержку."
        }
    }
    
    // MARK: - Helper Methods
    
    /// Проверка, является ли ошибка критичной (требует возврата средств)
    var isCritical: Bool {
        switch self {
        case .paymentFailed, .refundFailed:
            return true
        default:
            return false
        }
    }
    
    /// Проверка, можно ли повторить операцию
    var isRetryable: Bool {
        switch self {
        case .networkError, .networkTimeout, .networkUnavailable, .serviceUnavailable:
            return true
        default:
            return false
        }
    }
}

// MARK: - Error Handler

class ErrorHandler {
    /// Преобразование любой ошибки в AppError
    static func handle(_ error: Error) -> AppError {
        // Если уже AppError, возвращаем как есть
        if let appError = error as? AppError {
            return appError
        }
        
        // CancellationError - не ретраим
        if error is CancellationError {
            return .operationCancelled
        }
        
        // Парсим NSError
        let nsError = error as NSError
        let errorMessage = error.localizedDescription.lowercased()
        let errorDomain = nsError.domain
        
        // Ошибки с cancel/cancelled в тексте - также не ретраим
        if errorMessage.contains("cancel") {
            return .operationCancelled
        }
        
        // Сетевые ошибки
        if errorDomain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorTimedOut:
                return .networkTimeout
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return .networkUnavailable
            default:
                return .networkError(error)
            }
        }
        
        // Ошибки авторизации
        if errorDomain == "AuthError" {
            if errorMessage.contains("invalid") || errorMessage.contains("неверный") {
                return .invalidCredentials
            }
            if errorMessage.contains("email") && errorMessage.contains("confirm") {
                return .emailNotConfirmed
            }
            if nsError.code == 401 {
                return .authenticationRequired
            }
        }
        
        // Ошибки платежей
        if errorDomain == "PaymentError" || errorDomain == "YooKassaError" || errorDomain.contains("YooKassa") {
            if errorMessage.contains("cancel") || errorMessage.contains("отменен") {
                return .paymentCancelled
            }
            if errorMessage.contains("timeout") || errorMessage.contains("время") {
                return .paymentTimeout
            }
            // Ошибки декодирования от YooKassa - показываем понятное сообщение
            if errorMessage.contains("decoding") || errorMessage.contains("не удалось обработать") {
                return .paymentFailed("Не удалось обработать ответ от сервера оплаты. Попробуйте еще раз.")
            }
            // Ошибки авторизации
            if errorMessage.contains("авторизации") || errorMessage.contains("credentials") || errorMessage.contains("unauthorized") {
                return .paymentFailed("Ошибка авторизации. Обратитесь в поддержку.")
            }
            return .paymentFailed(error.localizedDescription)
        }
        
        // Ошибки Row-Level Security (RLS)
        if errorMessage.contains("row-level security") || errorMessage.contains("violates.*policy") || 
           errorMessage.contains("new row violates") || errorMessage.contains("policy violation") {
            // Определяем, какая таблица вызвала ошибку
            if errorMessage.contains("payments") {
                return .serverError("Недостаточно прав для выполнения операции. Пожалуйста, убедитесь, что вы авторизованы, и попробуйте ещё раз. Если проблема сохраняется, обратитесь в поддержку.")
            }
            if errorMessage.contains("user_challenges") {
                return .serverError("Недостаточно прав для участия в челлендже. Пожалуйста, убедитесь, что вы авторизованы, и попробуйте ещё раз.")
            }
            if errorMessage.contains("users") {
                return .authenticationRequired
            }
            return .serverError("Недостаточно прав для выполнения операции. Пожалуйста, убедитесь, что вы авторизованы, и попробуйте ещё раз.")
        }
        
        // Ошибки челленджей (проверяем независимо от domain, так как Edge Function может возвращать разные форматы)
        if errorMessage.contains("already joined") || 
           errorMessage.contains("уже участвуете") ||
           errorMessage.contains("user already joined") ||
           errorMessage.contains("already joined this challenge") {
            return .alreadyJoined
        }
        
        if errorDomain == "JoinChallengeError" || errorDomain.contains("join") || errorDomain.contains("challenge") {
            if errorMessage.contains("not found") || errorMessage.contains("не найден") {
                return .challengeNotFound
            }
            if errorMessage.contains("not started") || errorMessage.contains("не начался") {
                return .challengeNotStarted
            }
            if errorMessage.contains("ended") || errorMessage.contains("закончился") {
                return .challengeAlreadyEnded
            }
            return .cannotJoinChallenge(error.localizedDescription)
        }
        
        // HTTP ошибки
        if errorDomain.contains("HTTP") || errorDomain.contains("http") {
            switch nsError.code {
            case 401:
                return .authenticationRequired
            case 404:
                return .dataNotFound
            case 500...599:
                return .serverError(error.localizedDescription)
            case 503:
                return .serviceUnavailable
            default:
                return .serverError(error.localizedDescription)
            }
        }
        
        // Ошибки декодирования (DecodingError)
        if error is DecodingError {
            Logger.shared.error("Decoding error occurred", error: error)
            return .dataCorrupted
        }
        
        // Проверяем, является ли это ошибкой декодирования по тексту
        let errorDesc = error.localizedDescription.lowercased()
        if errorDesc.contains("couldn't be read") || 
           errorDesc.contains("missing") ||
           errorDesc.contains("decoding") ||
           errorDesc.contains("decode") {
            Logger.shared.error("Data decoding error", error: error)
            return .dataCorrupted
        }
        
        // Неизвестная ошибка
        return .unknown(error)
    }
    
    /// Получить пользовательское сообщение об ошибке
    static func userFriendlyMessage(for error: Error) -> String {
        let appError = handle(error)
        return appError.errorDescription ?? "Произошла ошибка. Попробуйте еще раз."
    }
    
    /// Получить предложение по исправлению
    static func recoverySuggestion(for error: Error) -> String? {
        let appError = handle(error)
        return appError.recoverySuggestion
    }
}
