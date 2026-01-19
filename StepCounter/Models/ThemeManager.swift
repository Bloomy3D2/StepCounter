//
//  ThemeManager.swift
//  StepCounter
//
//  Система тем для персонализации визуала
//

import Foundation
import SwiftUI

// MARK: - App Theme

struct AppTheme: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let displayName: String
    let description: String // Описание темы для UI
    let icon: String
    let isPremium: Bool
    let isAnimated: Bool // Анимированная тема (только для Premium)
    
    // Цвета
    let backgroundColor: ThemeColor
    let cardMaterial: MaterialType
    let primaryGradient: [ThemeColor]
    let accentColors: AccentColors
    let textColors: TextColors
    
    // Градиенты
    var primaryGradientColors: [Color] {
        primaryGradient.map { $0.color }
    }
    
    var backgroundColorValue: Color {
        backgroundColor.color
    }
    
    static func == (lhs: AppTheme, rhs: AppTheme) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Theme Color

struct ThemeColor: Codable {
    let r: Double
    let g: Double
    let b: Double
    let a: Double
    
    var color: Color {
        Color(red: r, green: g, blue: b, opacity: a)
    }
    
    init(color: Color) {
        // Упрощенное преобразование
        let components = color.cgColor?.components ?? [0, 0, 0, 1]
        self.r = Double(components[0])
        self.g = Double(components.count > 1 ? components[1] : 0)
        self.b = Double(components.count > 2 ? components[2] : 0)
        self.a = Double(components.count > 3 ? components[3] : 1)
    }
    
    init(r: Double, g: Double, b: Double, a: Double = 1.0) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
}

// MARK: - Material Type

enum MaterialType: String, Codable {
    case ultraThin
    case thin
    case regular
    case thick
    case ultraThick
    
    var material: Material {
        switch self {
        case .ultraThin: return .ultraThinMaterial
        case .thin: return .thinMaterial
        case .regular: return .regularMaterial
        case .thick: return .thickMaterial
        case .ultraThick: return .ultraThickMaterial
        }
    }
}

// MARK: - Accent Colors

struct AccentColors: Codable {
    let primary: ThemeColor
    let secondary: ThemeColor
    let tertiary: ThemeColor
    
    var primaryColor: Color { primary.color }
    var secondaryColor: Color { secondary.color }
    var tertiaryColor: Color { tertiary.color }
}

// MARK: - Text Colors

struct TextColors: Codable {
    let primary: ThemeColor
    let secondary: ThemeColor
    let tertiary: ThemeColor
    
    var primaryColor: Color { primary.color }
    var secondaryColor: Color { secondary.color }
    var tertiaryColor: Color { tertiary.color }
}

// MARK: - Default Themes

extension AppTheme {
    // Midnight (текущая тёмная тема)
    static let midnight = AppTheme(
        id: "midnight",
        name: "Midnight",
        displayName: "Полночь",
        description: "Классическая тёмная тема для комфортного использования",
        icon: "moon.stars.fill",
        isPremium: false,
        isAnimated: false,
        backgroundColor: ThemeColor(r: 0.02, g: 0.02, b: 0.05),
        cardMaterial: .ultraThin,
        primaryGradient: [
            ThemeColor(r: 0.02, g: 0.02, b: 0.05),
            ThemeColor(r: 0.08, g: 0.08, b: 0.12)
        ],
        accentColors: AccentColors(
            primary: ThemeColor(r: 0.3, g: 0.85, b: 0.5), // зеленый
            secondary: ThemeColor(r: 0.3, g: 0.6, b: 1.0), // синий
            tertiary: ThemeColor(r: 1.0, g: 0.6, b: 0.2) // оранжевый
        ),
        textColors: TextColors(
            primary: ThemeColor(r: 1.0, g: 1.0, b: 1.0),
            secondary: ThemeColor(r: 0.6, g: 0.6, b: 0.6),
            tertiary: ThemeColor(r: 0.4, g: 0.4, b: 0.4)
        )
    )
    
    // Aurora (зелено-синие градиенты) - анимированная
    static let aurora = AppTheme(
        id: "aurora",
        name: "Aurora",
        displayName: "Северное сияние",
        description: "Завораживающие переливы зелёных и синих оттенков",
        icon: "sparkles",
        isPremium: true,
        isAnimated: true,
        backgroundColor: ThemeColor(r: 0.1, g: 0.13, b: 0.18),
        cardMaterial: .ultraThin,
        primaryGradient: [
            ThemeColor(r: 0.1, g: 0.13, b: 0.18),
            ThemeColor(r: 0.06, g: 0.15, b: 0.25),
            ThemeColor(r: 0.04, g: 0.2, b: 0.3)
        ],
        accentColors: AccentColors(
            primary: ThemeColor(r: 0.0, g: 0.83, b: 1.0), // циан
            secondary: ThemeColor(r: 0.0, g: 1.0, b: 0.53), // зелёный
            tertiary: ThemeColor(r: 0.4, g: 0.7, b: 1.0) // светло-синий
        ),
        textColors: TextColors(
            primary: ThemeColor(r: 1.0, g: 1.0, b: 1.0),
            secondary: ThemeColor(r: 0.7, g: 0.8, b: 0.9),
            tertiary: ThemeColor(r: 0.5, g: 0.6, b: 0.7)
        )
    )
    
    // Sunset (оранжево-розовые тона)
    static let sunset = AppTheme(
        id: "sunset",
        name: "Sunset",
        displayName: "Закат",
        description: "Тёплые оранжевые и розовые тона заходящего солнца",
        icon: "sun.horizon.fill",
        isPremium: true,
        isAnimated: false,
        backgroundColor: ThemeColor(r: 0.15, g: 0.1, b: 0.12),
        cardMaterial: .ultraThin,
        primaryGradient: [
            ThemeColor(r: 0.15, g: 0.1, b: 0.12),
            ThemeColor(r: 0.2, g: 0.12, b: 0.15),
            ThemeColor(r: 0.25, g: 0.15, b: 0.18)
        ],
        accentColors: AccentColors(
            primary: ThemeColor(r: 1.0, g: 0.6, b: 0.2), // оранжевый
            secondary: ThemeColor(r: 1.0, g: 0.45, b: 0.5), // розовый
            tertiary: ThemeColor(r: 1.0, g: 0.84, b: 0.0) // золотой
        ),
        textColors: TextColors(
            primary: ThemeColor(r: 1.0, g: 1.0, b: 1.0),
            secondary: ThemeColor(r: 0.9, g: 0.8, b: 0.7),
            tertiary: ThemeColor(r: 0.7, g: 0.6, b: 0.5)
        )
    )
    
    // Ocean (сине-бирюзовые оттенки)
    static let ocean = AppTheme(
        id: "ocean",
        name: "Ocean",
        displayName: "Океан",
        description: "Глубокие синие и бирюзовые оттенки морской глубины",
        icon: "water.waves",
        isPremium: true,
        isAnimated: true,
        backgroundColor: ThemeColor(r: 0.05, g: 0.1, b: 0.15),
        cardMaterial: .ultraThin,
        primaryGradient: [
            ThemeColor(r: 0.05, g: 0.1, b: 0.15),
            ThemeColor(r: 0.08, g: 0.15, b: 0.22),
            ThemeColor(r: 0.1, g: 0.2, b: 0.28)
        ],
        accentColors: AccentColors(
            primary: ThemeColor(r: 0.2, g: 0.7, b: 0.9), // бирюзовый
            secondary: ThemeColor(r: 0.0, g: 0.6, b: 1.0), // синий
            tertiary: ThemeColor(r: 0.4, g: 0.8, b: 1.0) // светло-голубой
        ),
        textColors: TextColors(
            primary: ThemeColor(r: 1.0, g: 1.0, b: 1.0),
            secondary: ThemeColor(r: 0.7, g: 0.85, b: 0.95),
            tertiary: ThemeColor(r: 0.5, g: 0.7, b: 0.8)
        )
    )
    
    // Forest (зелёные тона)
    static let forest = AppTheme(
        id: "forest",
        name: "Forest",
        displayName: "Лес",
        description: "Свежие зелёные оттенки природной гармонии",
        icon: "leaf.fill",
        isPremium: true,
        isAnimated: false,
        backgroundColor: ThemeColor(r: 0.08, g: 0.12, b: 0.08),
        cardMaterial: .ultraThin,
        primaryGradient: [
            ThemeColor(r: 0.08, g: 0.12, b: 0.08),
            ThemeColor(r: 0.1, g: 0.15, b: 0.1),
            ThemeColor(r: 0.12, g: 0.18, b: 0.12)
        ],
        accentColors: AccentColors(
            primary: ThemeColor(r: 0.3, g: 0.85, b: 0.5), // зелёный
            secondary: ThemeColor(r: 0.2, g: 0.7, b: 0.4), // тёмно-зелёный
            tertiary: ThemeColor(r: 0.5, g: 0.9, b: 0.6) // светло-зелёный
        ),
        textColors: TextColors(
            primary: ThemeColor(r: 1.0, g: 1.0, b: 1.0),
            secondary: ThemeColor(r: 0.7, g: 0.9, b: 0.7),
            tertiary: ThemeColor(r: 0.5, g: 0.7, b: 0.5)
        )
    )
    
    // Neon (яркие неоновые акценты)
    static let neon = AppTheme(
        id: "neon",
        name: "Neon",
        displayName: "Неон",
        description: "Яркие неоновые акценты для смелого стиля",
        icon: "bolt.fill",
        isPremium: true,
        isAnimated: true,
        backgroundColor: ThemeColor(r: 0.05, g: 0.02, b: 0.08),
        cardMaterial: .ultraThin,
        primaryGradient: [
            ThemeColor(r: 0.05, g: 0.02, b: 0.08),
            ThemeColor(r: 0.08, g: 0.03, b: 0.12),
            ThemeColor(r: 0.1, g: 0.04, b: 0.15)
        ],
        accentColors: AccentColors(
            primary: ThemeColor(r: 1.0, g: 0.2, b: 1.0), // розовый неон
            secondary: ThemeColor(r: 0.2, g: 1.0, b: 1.0), // циан неон
            tertiary: ThemeColor(r: 1.0, g: 1.0, b: 0.2) // жёлтый неон
        ),
        textColors: TextColors(
            primary: ThemeColor(r: 1.0, g: 1.0, b: 1.0),
            secondary: ThemeColor(r: 0.9, g: 0.7, b: 0.9),
            tertiary: ThemeColor(r: 0.7, g: 0.5, b: 0.7)
        )
    )
    
    // Все темы
    static let allThemes: [AppTheme] = [
        .midnight, .aurora, .sunset, .ocean, .forest, .neon
    ]
}

// MARK: - Theme Manager

@MainActor
final class ThemeManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = ThemeManager()
    
    // MARK: - Published
    @Published var currentTheme: AppTheme = .midnight
    @Published var autoSwitchEnabled: Bool = false
    
    // MARK: - Private
    private let themeKey = "selectedTheme"
    private let autoSwitchKey = "autoSwitchTheme"
    private var timer: Timer?
    
    // MARK: - Init
    
    private init() {
        loadTheme()
        setupAutoSwitch()
    }
    
    // MARK: - Theme Management
    
    @MainActor
    func setTheme(_ theme: AppTheme) {
        guard currentTheme.id != theme.id else { return }
        
        // Проверяем Premium доступ перед установкой Premium темы
        let subscriptionManager = SubscriptionManager.shared
        if theme.isPremium && !subscriptionManager.isPremium {
            print("⚠️ Попытка установить Premium тему '\(theme.displayName)' без активной подписки")
            return
        }
        
        currentTheme = theme
        saveTheme()
    }
    
    func loadTheme() {
        let storage = StorageManager.shared
        if let themeId = storage.loadString(forKey: themeKey),
           let theme = AppTheme.allThemes.first(where: { $0.id == themeId }) {
            currentTheme = theme
        }
        
        autoSwitchEnabled = storage.loadBool(forKey: autoSwitchKey)
        
        // Проверяем, не закончилась ли Premium подписка
        checkAndResetPremiumThemeIfNeeded()
    }
    
    /// Проверяет Premium статус и сбрасывает Premium тему на базовую при необходимости
    func checkAndResetPremiumThemeIfNeeded() {
        let subscriptionManager = SubscriptionManager.shared
        
        // Если текущая тема Premium, но Premium подписка не активна - меняем на базовую
        if currentTheme.isPremium && !subscriptionManager.isPremium {
            setTheme(.midnight)
            print("ℹ️ Premium тема '\(currentTheme.displayName)' сброшена на базовую 'Полночь' (Premium истек)")
        }
    }
    
    func saveTheme() {
        StorageManager.shared.saveString(currentTheme.id, forKey: themeKey)
    }
    
    // MARK: - Auto Switch
    
    func toggleAutoSwitch() {
        // Проверяем Premium перед переключением
        guard SubscriptionManager.shared.isPremium else {
            // Если Premium отключен, выключаем автопереключение
            if autoSwitchEnabled {
                autoSwitchEnabled = false
                StorageManager.shared.saveBool(false, forKey: autoSwitchKey)
                setupAutoSwitch()
            }
            return
        }
        
        autoSwitchEnabled.toggle()
        StorageManager.shared.saveBool(autoSwitchEnabled, forKey: autoSwitchKey)
        setupAutoSwitch()
    }
    
    func setupAutoSwitch() {
        timer?.invalidate()
        
        // Проверяем Premium перед запуском автопереключения
        let isPremium = SubscriptionManager.shared.isPremium
        if !isPremium && autoSwitchEnabled {
            // Если Premium отключен, выключаем автопереключение
            autoSwitchEnabled = false
            StorageManager.shared.saveBool(false, forKey: autoSwitchKey)
            return
        }
        
        if autoSwitchEnabled && isPremium {
            timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.checkTimeAndSwitch()
                }
            }
            Task { @MainActor in
                checkTimeAndSwitch()
            }
        }
    }
    
    private func checkTimeAndSwitch() {
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Утро (6-12): Sunset
        if hour >= 6 && hour < 12 {
            if currentTheme.id != "sunset" {
                setTheme(.sunset)
            }
        }
        // День (12-18): Ocean
        else if hour >= 12 && hour < 18 {
            if currentTheme.id != "ocean" {
                setTheme(.ocean)
            }
        }
        // Вечер/Ночь (18-6): Midnight или Aurora
        else {
            if hour >= 18 || hour < 6 {
                if currentTheme.id != "midnight" && currentTheme.id != "aurora" {
                    setTheme(.midnight)
                }
            }
        }
    }
    
    // MARK: - Available Themes
    
    func availableThemes() -> [AppTheme] {
        // Показываем все темы, включая Premium (они будут заблокированы в UI)
        return AppTheme.allThemes
    }
}

// MARK: - ThemeManager Extension для удобного доступа к цветам

extension ThemeManager {
    /// Фон приложения
    var backgroundColor: Color {
        currentTheme.backgroundColorValue
    }
    
    /// Цвет карточки (из градиента или по умолчанию)
    var cardColor: Color {
        // Используем второй цвет из градиента как цвет карточки
        if currentTheme.primaryGradient.count > 1 {
            return currentTheme.primaryGradient[1].color
        }
        // Fallback на темный цвет карточки
        return Color(red: 0.08, green: 0.08, blue: 0.12)
    }
    
    /// Основной акцентный цвет (зеленый)
    var accentGreen: Color {
        currentTheme.accentColors.primaryColor
    }
    
    /// Вторичный акцентный цвет (синий)
    var accentBlue: Color {
        currentTheme.accentColors.secondaryColor
    }
    
    /// Третичный акцентный цвет (оранжевый)
    var accentOrange: Color {
        currentTheme.accentColors.tertiaryColor
    }
    
    /// Основной цвет текста
    var textPrimary: Color {
        currentTheme.textColors.primaryColor
    }
    
    /// Вторичный цвет текста
    var textSecondary: Color {
        currentTheme.textColors.secondaryColor
    }
}
