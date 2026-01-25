//
//  YooKassaClient.swift
//  ChallengeApp
//
//  Клиент для работы с API ЮKassa
//

import Foundation
import CryptoKit

// MARK: - Models

struct YooKassaPayment: Codable {
    let id: String
    let status: PaymentStatus
    let amount: YooKassaAmount
    let description: String?
    let confirmation: YooKassaConfirmation?
    let metadata: [String: String]?
    let createdAt: String
    let paid: Bool
    // Дополнительные поля из API, которые могут быть в ответе
    let test: Bool?
    let refundable: Bool?
    
    // Не определяем CodingKeys - используем автоматическое преобразование через .convertFromSnakeCase
}

enum PaymentStatus: String, Codable {
    case pending = "pending"
    case waitingForCapture = "waiting_for_capture"
    case succeeded = "succeeded"
    case canceled = "canceled"
}

struct YooKassaAmount: Codable {
    let value: String
    let currency: String
}

struct YooKassaConfirmation: Codable {
    let type: ConfirmationType
    let confirmationUrl: String?
    let returnUrl: String?
    
    // Не определяем CodingKeys - используем автоматическое преобразование через .convertFromSnakeCase
}

enum ConfirmationType: String, Codable {
    case redirect = "redirect"
    case embedded = "embedded"
    case qr = "qr"
}

struct YooKassaPaymentRequest: Codable {
    let amount: YooKassaAmount
    let description: String
    let confirmation: YooKassaConfirmation
    let capture: Bool
    let metadata: [String: String]?
    let paymentMethodData: PaymentMethodData?
    
    enum CodingKeys: String, CodingKey {
        case amount, description, confirmation, capture, metadata
        case paymentMethodData = "payment_method_data"
    }
}

struct PaymentMethodData: Codable {
    let type: String
}

struct YooKassaToken: Codable {
    let value: String
    let type: String
}

struct YooKassaTokenRequest: Codable {
    let number: String
    let cvc: String
    let expiryMonth: String
    let expiryYear: String
}

struct YooKassaRefund: Codable {
    let id: String
    let status: String
    let amount: YooKassaAmount
}

struct YooKassaRefundRequest: Codable {
    let paymentId: String
    let amount: YooKassaAmount
    
    enum CodingKeys: String, CodingKey {
        case paymentId = "payment_id"
        case amount
    }
}

// MARK: - Client

class YooKassaClient: YooKassaClientProtocol {
    nonisolated(unsafe) static let shared = YooKassaClient()
    
    private let shopId: String
    private let secretKey: String
    private let baseURL: String
    private let isTestMode: Bool
    
    init(shopId: String? = nil, secretKey: String? = nil, isTestMode: Bool? = nil) {
        // Используем AppConfig для получения ключей
        // Приоритет: параметры > AppConfig > дефолтные значения
        self.shopId = shopId ?? AppConfig.yooKassaShopId
        self.secretKey = secretKey ?? AppConfig.yooKassaSecretKey
        self.isTestMode = isTestMode ?? AppConfig.yooKassaIsTestMode
        
        // URL одинаковый для тестового и продакшн режима
        self.baseURL = "https://api.yookassa.ru/v3"
        
        // Логируем режим работы
        if self.shopId == "YOUR_SHOP_ID" || self.secretKey == "YOUR_SECRET_KEY" {
            Logger.shared.warning("YooKassa keys not configured, using default values. Payment will not work!")
        } else {
            Logger.shared.info("YooKassa client initialized in \(isTestMode == true ? "test" : "production") mode")
        }
    }
    
    // MARK: - Payment Creation
    
    func createPayment(
        amount: Double,
        description: String,
        returnUrl: String,
        metadata: [String: String]? = nil,
        paymentMethod: String? = nil,
        receiptEmail: String? = nil
    ) async throws -> YooKassaPayment {
        let url = URL(string: "\(baseURL)/payments")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "Idempotence-Key")
        
        var paymentRequest: [String: Any] = [
            "amount": [
                "value": String(format: "%.2f", amount),
                "currency": "RUB"
            ],
            "description": description,
            "confirmation": [
                "type": "redirect",
                "return_url": returnUrl
            ],
            "capture": true
        ]
        
        if let metadata = metadata {
            paymentRequest["metadata"] = metadata
        }
        
        if let paymentMethod = paymentMethod {
            paymentRequest["payment_method_data"] = ["type": paymentMethod]
        }
        
        // Добавляем receipt для отправки чека на email
        if let email = receiptEmail, !email.isEmpty {
            paymentRequest["receipt"] = [
                "customer": [
                    "email": email
                ],
                "items": [
                    [
                        "description": description,
                        "quantity": "1",
                        "amount": [
                            "value": String(format: "%.2f", amount),
                            "currency": "RUB"
                        ],
                        "vat_code": "1" // НДС не облагается (для большинства услуг)
                    ]
                ]
            ]
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: paymentRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YooKassaError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            Logger.shared.error("❌ YooKassa API error: HTTP \(httpResponse.statusCode) - \(errorMessage)")
            throw YooKassaError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        // Логируем ответ для отладки (первые 500 символов)
        if let responseString = String(data: data, encoding: .utf8) {
            let preview = String(responseString.prefix(500))
            Logger.shared.info("📥 YooKassa API response: \(preview)\(responseString.count > 500 ? "..." : "")")
        }
        
        // Проверяем, что данные не пустые
        guard !data.isEmpty else {
            Logger.shared.error("❌ YooKassa API returned empty response")
            throw YooKassaError.decodingError("Пустой ответ от сервера")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            return try decoder.decode(YooKassaPayment.self, from: data)
        } catch let decodingError as DecodingError {
            // Логируем детали ошибки декодирования
            let errorDetails = decodeErrorDetails(decodingError)
            Logger.shared.error("❌ YooKassa payment decoding error: \(errorDetails)")
            
            // Пытаемся извлечь полезную информацию из ответа
            if let jsonString = String(data: data, encoding: .utf8) {
                Logger.shared.error("📄 Response JSON: \(jsonString)")
            }
            
            throw YooKassaError.decodingError("Не удалось обработать ответ от сервера оплаты")
        }
    }
    
    // MARK: - Tokenization (для безопасного хранения карт)
    
    func createToken(cardNumber: String, expiryMonth: String, expiryYear: String, cvc: String) async throws -> YooKassaToken {
        let url = URL(string: "\(baseURL)/tokens")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let tokenRequest: [String: Any] = [
            "type": "bank_card",
            "bank_card": [
                "number": cardNumber.replacingOccurrences(of: " ", with: ""),
                "expiry_month": expiryMonth,
                "expiry_year": expiryYear,
                "csc": cvc
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: tokenRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YooKassaError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw YooKassaError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(YooKassaToken.self, from: data)
    }
    
    // MARK: - Payment Status Check
    
    func getPayment(paymentId: String) async throws -> YooKassaPayment {
        let url = URL(string: "\(baseURL)/payments/\(paymentId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YooKassaError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw YooKassaError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(YooKassaPayment.self, from: data)
    }
    
    // MARK: - Refund
    
    func createRefund(paymentId: String, amount: Double) async throws -> YooKassaRefund {
        let url = URL(string: "\(baseURL)/refunds")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "Idempotence-Key")
        
        let refundRequest: [String: Any] = [
            "payment_id": paymentId,
            "amount": [
                "value": String(format: "%.2f", amount),
                "currency": "RUB"
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: refundRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YooKassaError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw YooKassaError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(YooKassaRefund.self, from: data)
    }
    
    // MARK: - Helper
    
    private var base64Auth: String {
        let credentials = "\(shopId):\(secretKey)"
        return Data(credentials.utf8).base64EncodedString()
    }
}

// MARK: - Errors

enum YooKassaError: LocalizedError {
    case invalidResponse
    case apiError(Int, String)
    case invalidCredentials
    case paymentNotFound
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Неверный ответ от сервера оплаты"
        case .apiError(let code, let message):
            // Парсим сообщение об ошибке от API для более понятного сообщения
            let userMessage = parseApiErrorMessage(message)
            return userMessage
        case .invalidCredentials:
            return "Неверные учетные данные. Обратитесь в поддержку."
        case .paymentNotFound:
            return "Платеж не найден"
        case .decodingError(let message):
            return "Не удалось обработать ответ от сервера оплаты. Попробуйте еще раз."
        }
    }
    
    /// Парсинг сообщения об ошибке от API для пользователя
    private func parseApiErrorMessage(_ message: String) -> String {
        let lowercased = message.lowercased()
        
        // Ошибки авторизации
        if lowercased.contains("unauthorized") || lowercased.contains("401") {
            return "Ошибка авторизации. Проверьте настройки оплаты."
        }
        
        // Ошибки валидации
        if lowercased.contains("validation") || lowercased.contains("invalid") {
            return "Неверные данные для оплаты. Проверьте введенную информацию."
        }
        
        // Ошибки недостатка средств
        if lowercased.contains("insufficient") || lowercased.contains("недостаточно") {
            return "Недостаточно средств для оплаты."
        }
        
        // Общая ошибка API
        return "Ошибка при создании платежа. Попробуйте еще раз или выберите другой способ оплаты."
    }
}

// MARK: - Decoding Error Helper

extension YooKassaClient {
    /// Детальное описание ошибки декодирования для логирования
    private func decodeErrorDetails(_ error: DecodingError) -> String {
        switch error {
        case .typeMismatch(let type, let context):
            return "Type mismatch for type \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
        case .valueNotFound(let type, let context):
            return "Value not found for type \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
        case .keyNotFound(let key, let context):
            return "Key '\(key.stringValue)' not found at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
        case .dataCorrupted(let context):
            return "Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)"
        @unknown default:
            return "Unknown decoding error: \(error.localizedDescription)"
        }
    }
}
