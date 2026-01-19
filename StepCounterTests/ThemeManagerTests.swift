//
//  ThemeManagerTests.swift
//  StepCounterTests
//
//  Тесты для системы тем
//

import XCTest
@testable import StepCounter

@MainActor
final class ThemeManagerTests: XCTestCase {
    
    var themeManager: ThemeManager!
    var subscriptionManager: SubscriptionManager!
    
    override func setUp() {
        super.setUp()
        themeManager = ThemeManager.shared
        subscriptionManager = SubscriptionManager.shared
    }
    
    override func tearDown() {
        // Восстанавливаем базовую тему
        themeManager.setTheme(.midnight)
        subscriptionManager.setPremiumManually(false)
        super.tearDown()
    }
    
    // MARK: - Установка темы
    
    /// Тест: Пользователь должен иметь возможность установить базовую тему
    func testUserCanSetBasicTheme() {
        // Given
        let basicTheme = AppTheme.midnight
        
        // When
        themeManager.setTheme(basicTheme)
        
        // Then
        XCTAssertEqual(themeManager.currentTheme.id, basicTheme.id, "Текущая тема должна быть установлена")
    }
    
    /// Тест: Free пользователь не должен иметь возможность установить Premium тему
    func testFreeUserCannotSetPremiumTheme() {
        // Given
        subscriptionManager.setPremiumManually(false)
        let premiumTheme = AppTheme.aurora // Premium тема
        
        // When
        themeManager.setTheme(premiumTheme)
        
        // Then
        // Premium тема не должна быть установлена для free пользователя
        XCTAssertNotEqual(themeManager.currentTheme.id, premiumTheme.id, "Premium тема не должна быть установлена для free пользователя")
    }
    
    /// Тест: Premium пользователь должен иметь возможность установить Premium тему
    func testPremiumUserCanSetPremiumTheme() {
        // Given
        subscriptionManager.setPremiumManually(true)
        let premiumTheme = AppTheme.aurora
        
        // When
        themeManager.setTheme(premiumTheme)
        
        // Then
        XCTAssertEqual(themeManager.currentTheme.id, premiumTheme.id, "Premium пользователь должен иметь возможность установить Premium тему")
    }
    
    // MARK: - Автопереключение темы
    
    /// Тест: Автопереключение темы должно работать
    func testAutoSwitchTheme() {
        // Given
        themeManager.autoSwitchEnabled = false
        
        // When
        themeManager.autoSwitchEnabled = true
        
        // Then
        XCTAssertTrue(themeManager.autoSwitchEnabled, "Автопереключение должно быть включено")
    }
    
    // MARK: - Сброс Premium темы
    
    /// Тест: Premium тема должна сбрасываться при истечении Premium
    func testPremiumThemeResetsOnPremiumExpiration() {
        // Given
        subscriptionManager.setPremiumManually(true)
        themeManager.setTheme(.aurora) // Premium тема
        
        // When
        subscriptionManager.setPremiumManually(false)
        Task { @MainActor in
            await themeManager.checkAndResetPremiumThemeIfNeeded()
        }
        
        // Then
        // Тема должна быть сброшена на базовую
        XCTAssertNotEqual(themeManager.currentTheme.id, AppTheme.aurora.id, "Premium тема должна быть сброшена")
    }
    
    // MARK: - Доступные темы
    
    /// Тест: Должны быть доступны базовые темы
    func testBasicThemesAvailable() {
        // Given & When
        let allThemes = AppTheme.allThemes
        
        // Then
        let basicThemes = allThemes.filter { !$0.isPremium }
        XCTAssertGreaterThan(basicThemes.count, 0, "Должны быть доступны базовые темы")
    }
    
    /// Тест: Premium темы должны быть доступны только Premium пользователям
    func testPremiumThemesOnlyForPremium() {
        // Given
        subscriptionManager.setPremiumManually(false)
        
        // When
        let allThemes = AppTheme.allThemes
        let premiumThemes = allThemes.filter { $0.isPremium }
        
        // Then
        XCTAssertGreaterThan(premiumThemes.count, 0, "Должны существовать Premium темы")
        // Но они не должны быть доступны для установки free пользователям
    }
}
