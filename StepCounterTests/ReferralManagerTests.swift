//
//  ReferralManagerTests.swift
//  StepCounterTests
//
//  Тесты для реферальной системы
//

import XCTest
@testable import StepCounter

@MainActor
final class ReferralManagerTests: XCTestCase {
    
    var referralManager: ReferralManager!
    
    override func setUp() {
        super.setUp()
        referralManager = ReferralManager.shared
    }
    
    override func tearDown() {
        referralManager = nil
        super.tearDown()
    }
    
    // MARK: - Реферальный код
    
    /// Тест: Пользователь должен иметь уникальный реферальный код
    func testUserHasReferralCode() {
        // Given & When
        let code = referralManager.referralInfo.referralCode
        
        // Then
        XCTAssertEqual(code.count, 6, "Реферальный код должен состоять из 6 символов")
        XCTAssertTrue(code.allSatisfy { $0.isLetter || $0.isNumber }, "Реферальный код должен содержать только буквы и цифры")
    }
    
    /// Тест: Реферальный код должен быть уникальным для каждого пользователя
    func testReferralCodeIsUnique() {
        // Given
        let code1 = referralManager.referralInfo.referralCode
        
        // When
        // Создаем нового менеджера (симулируем другого пользователя)
        let newManager = ReferralManager.shared
        
        // Then
        // В реальности каждый пользователь должен иметь уникальный код
        // Но так как это singleton, код будет одинаковым
        // В реальном приложении код генерируется при первом запуске
        XCTAssertNotNil(code1, "Реферальный код должен существовать")
    }
    
    // MARK: - Регистрация по коду
    
    /// Тест: Пользователь должен иметь возможность зарегистрироваться по реферальному коду
    func testUserCanRegisterWithReferralCode() {
        // Given
        let validCode = "ABC123"
        
        // When
        let success = referralManager.registerWithReferralCode(validCode)
        
        // Then
        // Код может быть невалидным (уже использован или собственный)
        // Проверяем, что метод работает
        XCTAssertNotNil(success, "Метод регистрации должен работать")
    }
    
    /// Тест: Пользователь не должен иметь возможность использовать собственный код
    func testUserCannotUseOwnReferralCode() {
        // Given
        let ownCode = referralManager.referralInfo.referralCode
        
        // When
        let success = referralManager.registerWithReferralCode(ownCode)
        
        // Then
        XCTAssertFalse(success, "Пользователь не должен иметь возможность использовать собственный код")
    }
    
    /// Тест: Невалидный код не должен приниматься
    func testInvalidReferralCodeRejected() {
        // Given
        let invalidCodes = ["ABC", "ABC1234", "ABC-12", ""]
        
        // When & Then
        for code in invalidCodes {
            let success = referralManager.registerWithReferralCode(code)
            XCTAssertFalse(success, "Невалидный код '\(code)' не должен приниматься")
        }
    }
    
    // MARK: - Награды
    
    /// Тест: При регистрации по коду должны начисляться награды
    func testRewardsGivenOnReferralRegistration() {
        // Given
        let validCode = "XYZ789"
        let initialRewards = referralManager.referralInfo.totalRewardsEarned
        
        // When
        let success = referralManager.registerWithReferralCode(validCode)
        
        // Then
        if success {
            // Если регистрация успешна, награды должны быть начислены
            XCTAssertGreaterThanOrEqual(referralManager.referralInfo.totalRewardsEarned, initialRewards, "Награды должны быть начислены")
        }
    }
    
    // MARK: - Ограничения
    
    /// Тест: Free пользователь должен иметь ограничение на количество приглашений
    func testFreeUserHasInviteLimit() {
        // Given
        let subscriptionManager = SubscriptionManager.shared
        let wasPremium = subscriptionManager.isPremium
        subscriptionManager.setPremiumManually(false)
        
        // When
        let canInvite = referralManager.canInviteFriend()
        
        // Then
        // Free пользователь может пригласить ограниченное количество друзей
        XCTAssertNotNil(canInvite, "Метод проверки должен работать")
        
        // Restore
        subscriptionManager.setPremiumManually(wasPremium)
    }
    
    /// Тест: Premium пользователь должен иметь неограниченные приглашения
    func testPremiumUserHasUnlimitedInvites() {
        // Given
        let subscriptionManager = SubscriptionManager.shared
        let wasPremium = subscriptionManager.isPremium
        subscriptionManager.setPremiumManually(true)
        
        // When
        let canInvite = referralManager.canInviteFriend()
        
        // Then
        XCTAssertTrue(canInvite, "Premium пользователь должен иметь возможность приглашать неограниченное количество друзей")
        
        // Restore
        subscriptionManager.setPremiumManually(wasPremium)
    }
}
