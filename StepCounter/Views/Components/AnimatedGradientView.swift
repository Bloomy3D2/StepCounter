//
//  AnimatedGradientView.swift
//  StepCounter
//
//  Анимированный градиент для Premium тем
//

import SwiftUI

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    let theme: AppTheme
    
    var body: some View {
        if theme.isAnimated {
            // Для анимированных тем используем TimelineView для плавной анимации
            TimelineView(.periodic(from: .now, by: 0.016)) { context in
                AnimatedGradientContent(theme: theme, date: context.date)
            }
        } else {
            // Для обычных тем - статичный градиент
            LinearGradient(
                colors: theme.primaryGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct AnimatedGradientContent: View {
    let theme: AppTheme
    let date: Date
    
    private var angle: Double {
        // Вращение градиента (полный оборот за 8 секунд)
        let elapsed = date.timeIntervalSince1970
        return (elapsed.truncatingRemainder(dividingBy: 8.0) / 8.0) * 360
    }
    
    private var brightness: Double {
        // Пульсация яркости (цикл каждые 3 секунды)
        let elapsed = date.timeIntervalSince1970
        return (sin((elapsed.truncatingRemainder(dividingBy: 6.0) / 6.0) * 2 * .pi) + 1) / 2
    }
    
    var body: some View {
        ZStack {
            // Основной градиент с вращением
            LinearGradient(
                colors: theme.primaryGradientColors,
                startPoint: animatedStartPoint,
                endPoint: animatedEndPoint
            )
            
            // Дополнительный слой для глубины
            LinearGradient(
                colors: brightenedColors,
                startPoint: animatedEndPoint,
                endPoint: animatedStartPoint
            )
            .opacity(0.3)
        }
    }
    
    private var animatedStartPoint: UnitPoint {
        let radians = angle * .pi / 180
        let radius: Double = 0.4
        let x = 0.5 + radius * cos(radians)
        let y = 0.5 + radius * sin(radians)
        return UnitPoint(x: max(0, min(1, x)), y: max(0, min(1, y)))
    }
    
    private var animatedEndPoint: UnitPoint {
        let radians = (angle + 180) * .pi / 180
        let radius: Double = 0.4
        let x = 0.5 + radius * cos(radians)
        let y = 0.5 + radius * sin(radians)
        return UnitPoint(x: max(0, min(1, x)), y: max(0, min(1, y)))
    }
    
    private var brightenedColors: [Color] {
        theme.primaryGradientColors.map { color in
            adjustBrightness(color: color, amount: brightness)
        }
    }
    
    private func adjustBrightness(color: Color, amount: Double) -> Color {
        // Плавное изменение яркости для эффекта переливания
        let components = color.cgColor?.components ?? [0, 0, 0, 1]
        
        // Изменяем яркость в диапазоне ±10%
        let brightnessShift = (amount - 0.5) * 0.2 // Преобразуем 0-1 в -0.1 до +0.1
        
        let r = min(1.0, max(0.0, components[0] + brightnessShift))
        let g = min(1.0, max(0.0, components[1] + brightnessShift))
        let b = min(1.0, max(0.0, components[2] + brightnessShift))
        let a = components.count > 3 ? components[3] : 1.0
        
        return Color(red: r, green: g, blue: b, opacity: a)
    }
}
