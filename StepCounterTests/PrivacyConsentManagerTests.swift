//
//  PrivacyConsentManagerTests.swift
//  StepCounterTests
//
//  Тесты для системы согласия на обработку данных
//

import XCTest
@testable import StepCounter

@MainActor
final class PrivacyConsentManagerTests: XCTestCase {
    
    var consentManager: PrivacyConsentManager!
    
    override func setUp() {
        super.setUp()
        consentManager = PrivacyConsentManager.shared
    }
    
    override func tearDown() {
        // Сбрасываем согласие после каждого теста
        consentManager.revokeConsent()
        super.tearDown()
    }
    
    // MARK: - Выдача согласия
    
    /// Тест: Пользователь должен иметь возможность дать согласие
    func testUserCanGiveConsent() {
        // Given
        consentManager.revokeConsent()
        
        // When
        consentManager.giveConsent()
        
        // Then
        XCTAssertTrue(consentManager.hasConsent, "Согласие должно быть дано")
        XCTAssertNotNil(consentManager.consentDate, "Должна быть установлена дата согласия")
    }
    
    /// Тест: При выдаче согласия должна сохраняться версия политики
    func testConsentSavesPolicyVersion() {
        // Given
        consentManager.revokeConsent()
        
        // When
        consentManager.giveConsent()
        
        // Then
        XCTAssertEqual(consentManager.consentPolicyVersion, "1.0", "Должна сохраняться версия политики")
    }
    
    // MARK: - Отзыв согласия
    
    /// Тест: Пользователь должен иметь возможность отозвать согласие
    func testUserCanRevokeConsent() {
        // Given
        consentManager.giveConsent()
        
        // When
        consentManager.revokeConsent()
        
        // Then
        XCTAssertFalse(consentManager.hasConsent, "Согласие должно быть отозвано")
        XCTAssertNil(consentManager.consentDate, "Дата согласия должна быть удалена")
    }
    
    // MARK: - Проверка необходимости согласия
    
    /// Тест: Экран согласия должен показываться если согласие не дано
    func testConsentScreenShownWhenNoConsent() {
        // Given
        consentManager.revokeConsent()
        
        // When
        let shouldShow = consentManager.shouldShowConsentScreen
        
        // Then
        XCTAssertTrue(shouldShow, "Экран согласия должен показываться если согласие не дано")
    }
    
    /// Тест: Экран согласия не должен показываться если согласие дано
    func testConsentScreenNotShownWhenConsentGiven() {
        // Given
        consentManager.giveConsent()
        
        // When
        let shouldShow = consentManager.shouldShowConsentScreen
        
        // Then
        XCTAssertFalse(shouldShow, "Экран согласия не должен показываться если согласие дано")
    }
    
    /// Тест: Экран согласия должен показываться при изменении версии политики
    func testConsentScreenShownOnPolicyVersionChange() {
        // Given
        consentManager.giveConsent()
        // Симулируем изменение версии политики
        consentManager.consentPolicyVersion = "0.9" // Старая версия
        
        // When
        let shouldShow = consentManager.shouldShowConsentScreen
        
        // Then
        XCTAssertTrue(shouldShow, "Экран согласия должен показываться при изменении версии политики")
    }
}
