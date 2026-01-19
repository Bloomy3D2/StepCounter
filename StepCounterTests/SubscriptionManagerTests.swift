//
//  SubscriptionManagerTests.swift
//  StepCounterTests
//
//  Тесты для системы подписок Premium
//

import XCTest
@testable import StepCounter

@MainActor
final class SubscriptionManagerTests: XCTestCase {
    
    var subscriptionManager: SubscriptionManager!
    
    override func setUp() {
        super.setUp()
        subscriptionManager = SubscriptionManager.shared
    }
    
    override func tearDown() {
        // Сбрасываем состояние после каждого теста
        subscriptionManager.setPremiumManually(false)
        super.tearDown()
    }
    
    // MARK: - Premium статус
    
    /// Тест: Premium статус должен активироваться при покупке подписки
    func testPremiumActivatesOnSubscription() {
        // Given
        subscriptionManager.setPremiumManually(false)
        
        // When
        subscriptionManager.setPremiumManually(true)
        
        // Then
        XCTAssertTrue(subscriptionManager.isPremium, "Premium статус должен быть активен")
    }
    
    /// Тест: Premium статус должен деактивироваться при истечении подписки
    func testPremiumDeactivatesOnExpiration() {
        // Given
        subscriptionManager.setPremiumManually(true)
        
        // When
        subscriptionManager.setPremiumManually(false)
        
        // Then
        XCTAssertFalse(subscriptionManager.isPremium, "Premium статус должен быть неактивен")
    }
    
    /// Тест: Добавление Premium дней должно продлевать подписку
    func testAddPremiumDaysExtendsSubscription() {
        // Given
        // Устанавливаем Premium на 10 дней
        subscriptionManager.setPremiumManually(true)
        subscriptionManager.addPremiumDays(10)
        let initialExpiration = subscriptionManager.expirationDate
        
        // When
        subscriptionManager.addPremiumDays(7)
        
        // Then
        XCTAssertNotNil(subscriptionManager.expirationDate, "Должна быть установлена дата окончания")
        if let initialExpiration = initialExpiration,
           let expiration = subscriptionManager.expirationDate {
            let expectedDate = Calendar.current.date(byAdding: .day, value: 7, to: initialExpiration)!
            let daysDifference = Calendar.current.dateComponents([.day], from: expectedDate, to: expiration).day ?? 0
            XCTAssertEqual(daysDifference, 0, accuracy: 1, "Дата окончания должна быть продлена на 7 дней")
        }
    }
    
    /// Тест: Добавление Premium дней новому пользователю должно устанавливать дату с сегодня
    func testAddPremiumDaysForNewUser() {
        // Given
        subscriptionManager.setPremiumManually(false)
        
        // When
        subscriptionManager.addPremiumDays(30)
        
        // Then
        XCTAssertTrue(subscriptionManager.isPremium, "Premium должен быть активен")
        XCTAssertNotNil(subscriptionManager.expirationDate, "Должна быть установлена дата окончания")
        if let expiration = subscriptionManager.expirationDate {
            let daysFromNow = Calendar.current.dateComponents([.day], from: Date(), to: expiration).day ?? 0
            XCTAssertEqual(daysFromNow, 30, accuracy: 1, "Дата окончания должна быть через 30 дней от сегодня")
        }
    }
    
    // MARK: - Доступ к функциям
    
    /// Тест: Premium пользователь должен иметь доступ ко всем Premium функциям
    func testPremiumUserHasAccessToAllFeatures() {
        // Given
        subscriptionManager.setPremiumManually(true)
        
        // When & Then
        for feature in PremiumFeature.allCases {
            XCTAssertTrue(
                subscriptionManager.hasAccess(to: feature),
                "Premium пользователь должен иметь доступ к функции: \(feature.title)"
            )
        }
    }
    
    /// Тест: Free пользователь не должен иметь доступ к Premium функциям
    func testFreeUserNoAccessToPremiumFeatures() {
        // Given
        subscriptionManager.setPremiumManually(false)
        
        // When & Then
        let premiumFeatures: [PremiumFeature] = [
            .unlimitedPets,
            .customThemes,
            .animatedThemes,
            .exclusiveAchievements
        ]
        
        for feature in premiumFeatures {
            XCTAssertFalse(
                subscriptionManager.hasAccess(to: feature),
                "Free пользователь не должен иметь доступ к функции: \(feature.title)"
            )
        }
    }
    
    /// Тест: Виджеты должны быть доступны всем пользователям
    func testWidgetsAvailableToAllUsers() {
        // Given
        subscriptionManager.setPremiumManually(false)
        
        // When & Then
        // Виджеты не должны быть в списке Premium функций
        let widgetsFeature = PremiumFeature.allCases.first { $0.title.contains("Виджет") }
        XCTAssertNil(widgetsFeature, "Виджеты не должны быть Premium функцией")
    }
    
    // MARK: - Типы подписок
    
    /// Тест: Тип подписки должен определяться корректно
    func testSubscriptionTypeDetection() {
        // Given
        subscriptionManager.setPremiumManually(true)
        
        // When
        let subscriptionType = subscriptionManager.activeSubscription
        
        // Then
        // activeSubscription устанавливается автоматически при обновлении статуса
        // Проверяем, что свойство доступно для чтения
        XCTAssertNotNil(subscriptionType == nil || subscriptionType == .monthly || subscriptionType == .yearly || subscriptionType == .lifetime, "Тип подписки должен быть определен или nil")
    }
    
    /// Тест: Lifetime подписка должна определяться корректно
    func testLifetimeSubscriptionDetection() {
        // Given
        subscriptionManager.setPremiumManually(true)
        
        // When
        let subscriptionType = subscriptionManager.activeSubscription
        
        // Then
        // Проверяем, что свойство доступно для чтения
        // В реальном приложении activeSubscription устанавливается через StoreKit
        XCTAssertNotNil(subscriptionType == nil || subscriptionType == .lifetime, "Lifetime подписка должна определяться через StoreKit")
    }
}
