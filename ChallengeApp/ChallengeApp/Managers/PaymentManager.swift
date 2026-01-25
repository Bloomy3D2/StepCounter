//
//  PaymentManager.swift
//  ChallengeApp
//
//  Менеджер для обработки платежей (прямая оплата)
//

import Foundation
import StoreKit
import PassKit
import Combine
import UIKit

enum PaymentMethodType {
    case applePay
    case card
    case sbp // Система быстрых платежей
}

enum WithdrawMethodType: String, Codable {
    case card = "CARD"
    case bankAccount = "BANK_ACCOUNT"
    case sbp = "SBP"
    case `internal` = "INTERNAL" // Для внутренних операций (списание с баланса при вступлении в челлендж)
}

// Модель данных карты
struct CardDetails {
    var cardNumber: String = ""
    var expiryDate: String = "" // MM/YY
    var cvv: String = ""
    var cardholderName: String = ""
    
    var isValid: Bool {
        cardNumber.count == 19 && // 16 цифр + 3 пробела
        expiryDate.count == 5 && // MM/YY
        cvv.count == 3 &&
        !cardholderName.isEmpty
    }
    
    // Форматирование номера карты (добавление пробелов)
    mutating func formatCardNumber() {
        let cleaned = cardNumber.replacingOccurrences(of: " ", with: "")
        var formatted = ""
        for (index, char) in cleaned.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted.append(char)
        }
        cardNumber = String(formatted.prefix(19))
    }
    
    // Форматирование срока действия
    mutating func formatExpiryDate() {
        let cleaned = expiryDate.replacingOccurrences(of: "/", with: "")
        if cleaned.count >= 2 {
            var formatted = String(cleaned.prefix(2))
            if cleaned.count > 2 {
                formatted += "/" + String(cleaned.dropFirst(2).prefix(2))
            }
            expiryDate = formatted
        }
    }
}

final class PaymentManager: NSObject, PaymentManagerProtocol, @unchecked Sendable {
    @Published var isProcessing = false
    @Published var lastError: String?
    
    private let yooKassaClient: YooKassaClientProtocol
    private var currentPaymentId: String? // Для возможности возврата
    
    init(yooKassaClient: YooKassaClientProtocol = DIContainer.shared.yooKassaClient) {
        self.yooKassaClient = yooKassaClient
        super.init()
    }
    
    // Режим работы: true = реальные платежи, false = симуляция (для тестирования)
    var useRealPayments: Bool {
        // Автоматически определяем режим на основе наличия реальных ключей
        let shopId = AppConfig.yooKassaShopId
        let secretKey = AppConfig.yooKassaSecretKey
        let isTestMode = AppConfig.yooKassaIsTestMode
        
        // Если ключи не дефолтные и не тестовый режим, значит настроены реальные платежи
        let hasRealKeys = shopId != "YOUR_SHOP_ID" && 
                         secretKey != "YOUR_SECRET_KEY" &&
                         !shopId.isEmpty &&
                         !secretKey.isEmpty
        
        // Можно принудительно включить/выключить через UserDefaults (для тестирования)
        if UserDefaults.standard.object(forKey: "useRealPayments") != nil {
            return UserDefaults.standard.bool(forKey: "useRealPayments")
        }
        
        // Автоматически: реальные платежи, если есть реальные ключи и не тестовый режим
        return hasRealKeys && !isTestMode
    }
    
    func processPayment(
        amount: Double,
        challenge: Challenge,
        userId: String,
        paymentMethod: PaymentMethodType,
        cardDetails: CardDetails? = nil,
        receiptEmail: String? = nil
    ) async -> Bool {
        // Проверка на отмену задачи
        guard !Task.isCancelled else {
            Task { @MainActor in
                isProcessing = false
                lastError = "Платеж отменен"
            }
            return false
        }
        
        Task { @MainActor in
            isProcessing = true
            lastError = nil
        }
        
        // Валидация суммы
        guard amount > 0 else {
            Task { @MainActor in
                isProcessing = false
                lastError = "Неверная сумма платежа"
            }
            return false
        }
        
        do {
            let result: Bool
            
            if useRealPayments {
                // Реальная интеграция с ЮKassa
                switch paymentMethod {
                case .applePay:
                    // Apple Pay через ЮKassa (пока используем симуляцию)
                    result = try await processApplePayPayment(amount: amount, challenge: challenge, userId: userId, receiptEmail: receiptEmail)
                    
                case .card:
                    guard let cardDetails = cardDetails, cardDetails.isValid else {
                        Task { @MainActor in
                            isProcessing = false
                            lastError = "Неверные данные карты"
                        }
                        return false
                    }
                    result = try await processCardPayment(amount: amount, challenge: challenge, userId: userId, cardDetails: cardDetails, receiptEmail: receiptEmail)
                    
                case .sbp:
                    result = try await processSBPPayment(amount: amount, challenge: challenge, userId: userId, receiptEmail: receiptEmail)
                }
            } else {
                // Симуляция для тестирования
                switch paymentMethod {
                case .applePay, .card:
                    result = try await simulatePayment()
                case .sbp:
                    result = try await simulateSBPPayment(amount: amount, challenge: challenge)
                }
            }
            
            Task { @MainActor in
                isProcessing = false
            }
            
            return result
            
        } catch {
            Task { @MainActor in
                isProcessing = false
                lastError = error.localizedDescription
            }
            return false
        }
    }
    
    private func simulatePayment() async throws -> Bool {
        // Проверка на отмену
        try Task.checkCancellation()
        
        // Симулируем задержку обработки платежа
        try await Task.sleep(nanoseconds: UInt64(TimingConstants.paymentSimulationDelay * 1_000_000_000))
        
        // Проверка на отмену после задержки
        try Task.checkCancellation()
        
        // В реальности здесь:
        // 1. Создание платежа через Apple Pay / Stripe
        // 2. Обработка через платежный шлюз
        // 3. Получение подтверждения
        // 4. Сохранение транзакции в базе данных через Supabase
        // 5. Обработка ошибок платежной системы
        
        // В продакшене симуляция всегда успешна
        // Реальные платежи обрабатываются через YooKassa
        
        return true
    }
    
    // MARK: - Real Payment Methods
    
    private func processCardPayment(
        amount: Double,
        challenge: Challenge,
        userId: String,
        cardDetails: CardDetails,
        receiptEmail: String?
    ) async throws -> Bool {
        // 1. Токенизация карты (безопасное хранение)
        let expiryParts = cardDetails.expiryDate.split(separator: "/")
        guard expiryParts.count == 2,
              let month = Int(expiryParts[0]),
              let year = Int("20\(expiryParts[1])") else {
            throw NSError(
                domain: "PaymentError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Неверный срок действия карты"]
            )
        }
        
        let cardNumber = cardDetails.cardNumber.replacingOccurrences(of: " ", with: "")
        let token = try await yooKassaClient.createToken(
            cardNumber: cardNumber,
            expiryMonth: String(format: "%02d", month),
            expiryYear: String(year),
            cvc: cardDetails.cvv
        )
        
        // 2. Создание платежа
        let returnUrl = AppConfig.paymentReturnURL
        let metadata = [
            "challenge_id": String(challenge.id),
            "user_id": userId
        ]
        
        let payment = try await yooKassaClient.createPayment(
            amount: amount,
            description: "Оплата челленджа: \(challenge.title)",
            returnUrl: returnUrl,
            metadata: metadata,
            paymentMethod: "bank_card",
            receiptEmail: receiptEmail
        )
        
        currentPaymentId = payment.id
        
        // Уведомляем о создании платежа с paymentId
        NotificationCenter.default.post(
            name: NSNotification.Name("PaymentCreated"),
            object: nil,
            userInfo: ["payment_id": payment.id, "challenge_id": challenge.id]
        )
        
        // 3. Если требуется 3D Secure или редирект
        if let confirmationUrlString = payment.confirmation?.confirmationUrl,
           let confirmationUrl = URL(string: confirmationUrlString) {
            Task { @MainActor in
                UIApplication.shared.open(confirmationUrl, options: [:]) { success in
                    if !success {
                        Logger.shared.warning("Не удалось открыть URL подтверждения")
                    }
                }
            }
            
            // Ждем callback через webhook или polling
            // В реальности статус будет обновлен через webhook
            // Здесь можно использовать polling как fallback
            return try await waitForPaymentConfirmation(paymentId: payment.id)
        }
        
        // 4. Если оплата сразу успешна
        return payment.status == PaymentStatus.succeeded
    }
    
    private func processSBPPayment(
        amount: Double,
        challenge: Challenge,
        userId: String,
        receiptEmail: String?
    ) async throws -> Bool {
        // 1. Создание платежа через ЮKassa с методом СБП
        let returnUrl = AppConfig.paymentReturnURL
        let metadata = [
            "challenge_id": String(challenge.id),
            "user_id": userId
        ]
        
        let payment = try await yooKassaClient.createPayment(
            amount: amount,
            description: "Оплата челленджа: \(challenge.title)",
            returnUrl: returnUrl,
            metadata: metadata,
            paymentMethod: "sbp",
            receiptEmail: receiptEmail
        )
        
        currentPaymentId = payment.id
        
        // Уведомляем о создании платежа с paymentId
        NotificationCenter.default.post(
            name: NSNotification.Name("PaymentCreated"),
            object: nil,
            userInfo: ["payment_id": payment.id, "challenge_id": challenge.id]
        )
        
        // 2. Получаем URL для редиректа на СБП
        guard let confirmationUrlString = payment.confirmation?.confirmationUrl,
              let confirmationUrl = URL(string: confirmationUrlString) else {
            throw NSError(
                domain: "PaymentError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Не удалось получить ссылку для оплаты СБП"]
            )
        }
        
        // 3. Открываем URL в Safari
        Task { @MainActor in
            UIApplication.shared.open(confirmationUrl, options: [:]) { success in
                if !success {
                    Logger.shared.warning("Не удалось открыть URL СБП")
                } else {
                    Logger.shared.payment("Открыт URL СБП: \(confirmationUrl)")
                }
            }
        }
        
        // 4. Ждем callback через webhook
        // В реальности статус будет обновлен через webhook
        return try await waitForPaymentConfirmation(paymentId: payment.id)
    }
    
    private func processApplePayPayment(
        amount: Double,
        challenge: Challenge,
        userId: String,
        receiptEmail: String?
    ) async throws -> Bool {
        // Apple Pay через ЮKassa (пока используем симуляцию)
        // В будущем: интеграция с PKPaymentAuthorizationController
        return try await simulatePayment()
    }
    
    // MARK: - Payment Status Check
    
    private func waitForPaymentConfirmation(paymentId: String, maxAttempts: Int = TimingConstants.paymentPollingMaxAttempts) async throws -> Bool {
        // Polling для проверки статуса (fallback, если webhook не сработал)
        // В реальности webhook должен обработать платеж автоматически
        for _ in 1...maxAttempts {
            try Task.checkCancellation()
            
            let payment = try await yooKassaClient.getPayment(paymentId: paymentId)
            
            switch payment.status {
            case PaymentStatus.succeeded:
                return true
            case PaymentStatus.canceled:
                throw NSError(
                    domain: "PaymentError",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Платеж отменен"]
                )
            case .pending, .waitingForCapture:
                // Продолжаем ждать
                try await Task.sleep(nanoseconds: UInt64(TimingConstants.defaultDelay * 1_000_000_000))
            }
        }
        
        // Timeout - платеж все еще pending
        // В реальности webhook должен обработать это
        throw NSError(
            domain: "PaymentError",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Превышено время ожидания подтверждения платежа"]
        )
    }
    
    // MARK: - Refund
    
    func refundPayment(amount: Double) async throws {
        guard let paymentId = currentPaymentId else {
            throw NSError(
                domain: "PaymentError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "ID платежа не найден"]
            )
        }
        
        let refund = try await yooKassaClient.createRefund(paymentId: paymentId, amount: amount)
        Logger.shared.payment("Возврат средств инициирован: \(refund.id)")
    }
    
    // MARK: - Legacy Simulation (для тестирования)
    
    private func simulateSBPPayment(amount: Double, challenge: Challenge) async throws -> Bool {
        // Симуляция для тестирования (когда useRealPayments = false)
        let transactionId = UUID().uuidString
        let amountKopecks = Int(amount * 100)
        let sbpURLString = "https://qr.nspk.ru/\(amountKopecks)/\(transactionId)"
        
        guard let url = URL(string: sbpURLString) else {
            throw NSError(
                domain: "PaymentError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Не удалось создать ссылку для оплаты СБП"]
            )
        }
        
        Task { @MainActor in
            UIApplication.shared.open(url, options: [:]) { success in
                if !success {
                    Logger.shared.warning("Не удалось открыть URL СБП: \(sbpURLString)")
                } else {
                    Logger.shared.payment("Открыт URL СБП: \(sbpURLString)")
                }
            }
        }
        
        Logger.shared.info("Ожидание завершения оплаты СБП...")
        try await Task.sleep(nanoseconds: 5_000_000_000)
        try Task.checkCancellation()
        
        return true
    }
    
    func withdrawFunds(amount: Double, userId: String) async -> Bool {
        Task { @MainActor in
            isProcessing = true
            lastError = nil
        }
        
        // Симулируем вывод средств
        try? await Task.sleep(nanoseconds: UInt64(TimingConstants.withdrawalSimulationDelay * 1_000_000_000))
        
        Task { @MainActor in
            isProcessing = false
        }
        
        return true
    }
    
    // MARK: - Deposit Payment
    
    func processDepositPayment(
        amount: Double,
        userId: String,
        receiptEmail: String,
        paymentMethod: PaymentMethodType
    ) async throws -> Bool {
        Logger.shared.payment("💳 PaymentManager.processDepositPayment: START - amount=\(amount), userId=\(userId), method=\(paymentMethod)")
        
        Task { @MainActor in
            isProcessing = true
            lastError = nil
        }
        
        defer {
            Task { @MainActor in
                isProcessing = false
            }
        }
        
        let returnUrl = AppConfig.paymentReturnURL
        let metadata = [
            "type": "deposit",
            "user_id": userId
        ]
        
        let paymentMethodString: String
        switch paymentMethod {
        case .applePay:
            paymentMethodString = "bank_card" // Apple Pay обрабатывается как карта
        case .card:
            paymentMethodString = "bank_card"
        case .sbp:
            paymentMethodString = "sbp"
        }
        
        let payment = try await yooKassaClient.createPayment(
            amount: amount,
            description: "Пополнение баланса",
            returnUrl: returnUrl,
            metadata: metadata,
            paymentMethod: paymentMethodString,
            receiptEmail: receiptEmail
        )
        
        currentPaymentId = payment.id
        
        // Уведомляем о создании платежа
        NotificationCenter.default.post(
            name: NSNotification.Name("DepositPaymentCreated"),
            object: nil,
            userInfo: ["payment_id": payment.id, "user_id": userId, "amount": amount]
        )
        
        // Если требуется редирект
        if let confirmationUrlString = payment.confirmation?.confirmationUrl,
           let confirmationUrl = URL(string: confirmationUrlString) {
            Task { @MainActor in
                UIApplication.shared.open(confirmationUrl, options: [:]) { success in
                    if !success {
                        Logger.shared.warning("Не удалось открыть URL подтверждения")
                    }
                }
            }
            
            // Ждем подтверждения через webhook
            return try await waitForPaymentConfirmation(paymentId: payment.id)
        }
        
        // Если оплата сразу успешна
        return payment.status == PaymentStatus.succeeded
    }
}
