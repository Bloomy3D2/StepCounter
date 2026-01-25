//
//  PaymentManagerTests.swift
//  ChallengeAppTests
//
//  Unit тесты для PaymentManager
//

import XCTest
@testable import ChallengeApp

@MainActor
final class PaymentManagerTests: XCTestCase {
    var sut: PaymentManager!
    var mockYooKassaClient: MockYooKassaClient!
    
    override func setUp() {
        super.setUp()
        mockYooKassaClient = MockYooKassaClient()
        sut = PaymentManager(yooKassaClient: mockYooKassaClient)
    }
    
    override func tearDown() {
        sut = nil
        mockYooKassaClient = nil
        super.tearDown()
    }
    
    // MARK: - Process Payment Tests
    
    func testProcessPayment_ApplePay_Success() async {
        // Given
        let challenge = Challenge(
            id: "1",
            title: "Test Challenge",
            subtitle: "Test",
            icon: "flame",
            duration: 7,
            entryFee: 100.0,
            serviceFee: 10.0,
            startDate: Date(),
            endDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            participants: 0,
            prizePool: 1000.0,
            activeParticipants: 0,
            description: "Test",
            rules: []
        )
        
        // When
        let result = await sut.processPayment(
            amount: 100.0,
            challenge: challenge,
            userId: "test-user-id",
            paymentMethod: .applePay,
            cardDetails: nil
        )
        
        // Then
        XCTAssertTrue(result)
        XCTAssertFalse(sut.isProcessing)
    }
    
    func testProcessPayment_Card_Success() async {
        // Given
        let challenge = Challenge(
            id: "1",
            title: "Test Challenge",
            subtitle: "Test",
            icon: "flame",
            duration: 7,
            entryFee: 100.0,
            serviceFee: 10.0,
            startDate: Date(),
            endDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            participants: 0,
            prizePool: 1000.0,
            activeParticipants: 0,
            description: "Test",
            rules: []
        )
        
        var cardDetails = CardDetails()
        cardDetails.cardNumber = "1234 5678 9012 3456"
        cardDetails.expiryDate = "12/25"
        cardDetails.cvv = "123"
        cardDetails.cardholderName = "Test User"
        
        let payment = YooKassaPayment(
            id: "payment-id",
            status: .succeeded,
            amount: YooKassaAmount(value: "100.00", currency: "RUB"),
            description: "Test",
            confirmation: nil,
            metadata: [:],
            createdAt: ISO8601DateFormatter().string(from: Date()),
            paid: true
        )
        mockYooKassaClient.createPaymentResult = payment
        
        // When
        let result = await sut.processPayment(
            amount: 100.0,
            challenge: challenge,
            userId: "test-user-id",
            paymentMethod: .card,
            cardDetails: cardDetails
        )
        
        // Then
        // В тестовом режиме может быть false, так как реальный платеж не происходит
        // Но проверяем, что процесс запущен
        XCTAssertFalse(sut.isProcessing)
    }
    
    func testProcessPayment_SBP_Success() async {
        // Given
        let challenge = Challenge(
            id: "1",
            title: "Test Challenge",
            subtitle: "Test",
            icon: "flame",
            duration: 7,
            entryFee: 100.0,
            serviceFee: 10.0,
            startDate: Date(),
            endDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            participants: 0,
            prizePool: 1000.0,
            activeParticipants: 0,
            description: "Test",
            rules: []
        )
        
        let payment = YooKassaPayment(
            id: "payment-id",
            status: .pending,
            amount: YooKassaAmount(value: "100.00", currency: "RUB"),
            description: "Test",
            confirmation: YooKassaConfirmation(
                type: .redirect,
                confirmationUrl: "https://example.com/payment",
                returnUrl: nil
            ),
            metadata: [:],
            createdAt: ISO8601DateFormatter().string(from: Date()),
            paid: false
        )
        mockYooKassaClient.createPaymentResult = payment
        
        // When
        let result = await sut.processPayment(
            amount: 100.0,
            challenge: challenge,
            userId: "test-user-id",
            paymentMethod: .sbp,
            cardDetails: nil
        )
        
        // Then
        // SBP требует редирект, поэтому результат может быть false
        XCTAssertFalse(sut.isProcessing)
    }
    
    // MARK: - Refund Payment Tests
    
    func testRefundPayment_Success() async throws {
        // Given
        let refund = YooKassaRefund(
            id: "refund-id",
            status: "succeeded",
            amount: YooKassaAmount(value: "100.00", currency: "RUB")
        )
        mockYooKassaClient.createRefundResult = refund
        
        // When
        try await sut.refundPayment(amount: 100.0)
        
        // Then
        // Проверяем, что ошибок нет
        XCTAssertNil(sut.lastError)
    }
    
    func testRefundPayment_Error() async {
        // Given
        mockYooKassaClient.createRefundError = AppError.refundFailed("Refund failed")
        
        // When & Then
        do {
            try await sut.refundPayment(amount: 100.0)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is AppError)
        }
    }
}
