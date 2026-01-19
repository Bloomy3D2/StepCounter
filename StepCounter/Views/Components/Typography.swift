//
//  Typography.swift
//  StepCounter
//
//  Система типографики для выразительного визуала
//

import SwiftUI

// MARK: - Typography Styles

extension Font {
    /// Главные числа (шаги, метрики)
    static var appLargeNumber: Font {
        .system(size: 64, weight: .bold, design: .rounded)
    }
    
    /// Большие числа (вторичные метрики)
    static var appMediumNumber: Font {
        .system(size: 48, weight: .bold, design: .rounded)
    }
    
    /// Средние числа
    static var appSmallNumber: Font {
        .system(size: 32, weight: .semibold, design: .rounded)
    }
    
    /// Заголовок экрана
    static var appScreenTitle: Font {
        .system(size: 34, weight: .bold, design: .rounded)
    }
    
    /// Большой заголовок
    static var appLargeTitle: Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }
    
    /// Заголовок секции
    static var appSectionTitle: Font {
        .system(size: 22, weight: .semibold, design: .rounded)
    }
    
    /// Обычный заголовок
    static var appTitle: Font {
        .system(size: 18, weight: .semibold, design: .rounded)
    }
    
    /// Текст
    static var appBody: Font {
        .system(size: 16, weight: .regular, design: .default)
    }
    
    /// Мелкий текст
    static var appCaption: Font {
        .system(size: 14, weight: .medium, design: .default)
    }
    
    /// Очень мелкий текст
    static var appSmallCaption: Font {
        .system(size: 12, weight: .medium, design: .default)
    }
}

// MARK: - Text Styling Modifiers

extension Text {
    /// Стиль для главного числа (шаги)
    func largeNumberStyle(color: Color = .white) -> some View {
        self
            .font(.appLargeNumber)
            .foregroundColor(color)
            .kerning(-2) // Уменьшаем межбуквенное расстояние для чисел
    }
    
    /// Стиль для заголовка экрана
    func screenTitleStyle(color: Color = .white) -> some View {
        self
            .font(.appScreenTitle)
            .foregroundColor(color)
    }
    
    /// Стиль для меток
    func labelStyle(color: Color = .white.opacity(0.6)) -> some View {
        self
            .font(.appCaption)
            .foregroundColor(color)
    }
}

// MARK: - Animated Number View

/// Анимированное число с плавным переходом
struct AnimatedNumber: View {
    let value: Int
    let font: Font
    let color: Color
    let formatter: (Int) -> String
    
    @State private var displayedValue: Int = 0
    
    init(
        value: Int,
        font: Font = .appLargeNumber,
        color: Color = .white,
        formatter: @escaping (Int) -> String = { "\($0)" }
    ) {
        self.value = value
        self.font = font
        self.color = color
        self.formatter = formatter
    }
    
    var body: some View {
        Text(formatter(displayedValue))
            .font(font)
            .foregroundColor(color)
            .monospacedDigit() // Одинаковая ширина цифр
            .contentTransition(.numericText())
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: displayedValue)
            .onAppear {
                displayedValue = value
            }
            .onChange(of: value) { _, newValue in
                // Плавное изменение с пружинной анимацией
                let duration = min(Double(abs(newValue - displayedValue)) / 1000.0, 1.0)
                
                withAnimation(.spring(response: duration, dampingFraction: 0.8)) {
                    displayedValue = newValue
                }
            }
    }
}

// MARK: - Gradient Text

/// Текст с градиентом
struct GradientText: View {
    let text: String
    let font: Font
    let gradient: LinearGradient
    
    init(
        _ text: String,
        font: Font = .appLargeTitle,
        gradient: LinearGradient
    ) {
        self.text = text
        self.font = font
        self.gradient = gradient
    }
    
    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(gradient)
    }
}

#Preview {
    VStack(spacing: 30) {
        // Главное число
        VStack(spacing: 8) {
            AnimatedNumber(value: 10234)
            Text("шагов сегодня")
                .labelStyle()
        }
        
        // Градиентный текст
        GradientText(
            "StepCounter",
            gradient: LinearGradient(
                colors: [.green, .blue, .purple],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        
        // Типографика разных размеров
        VStack(alignment: .leading, spacing: 12) {
            Text("Экран")
                .font(.appScreenTitle)
            
            Text("Заголовок секции")
                .font(.appSectionTitle)
            
            Text("Обычный заголовок")
                .font(.appTitle)
            
            Text("Основной текст приложения с информацией")
                .font(.appBody)
            
            Text("Мелкий текст")
                .font(.appCaption)
        }
    }
    .padding()
    .background(Color(red: 0.02, green: 0.02, blue: 0.05))
}
