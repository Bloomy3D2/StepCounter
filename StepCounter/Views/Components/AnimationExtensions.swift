//
//  AnimationExtensions.swift
//  StepCounter
//
//  Расширения для плавных spring-анимаций
//

import SwiftUI

// MARK: - Custom Animations

extension Animation {
    /// Стандартная spring-анимация приложения
    static var appSpring: Animation {
        .spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.3)
    }
    
    /// Пружинная анимация (более упругая)
    static var appBouncy: Animation {
        .spring(response: 0.4, dampingFraction: 0.6)
    }
    
    /// Мягкая анимация
    static var appSmooth: Animation {
        .spring(response: 0.6, dampingFraction: 0.8)
    }
    
    /// Быстрая анимация
    static var appQuick: Animation {
        .spring(response: 0.3, dampingFraction: 0.7)
    }
    
    /// Медленная анимация для важных переходов
    static var appSlow: Animation {
        .spring(response: 0.8, dampingFraction: 0.75)
    }
}

// MARK: - View Extensions

extension View {
    /// Применить стандартную spring-анимацию
    func withAppSpring() -> some View {
        self.animation(.appSpring, value: UUID())
    }
    
    /// Плавное появление с пружиной
    func springAppear(delay: Double = 0) -> some View {
        self
            .transition(.scale.combined(with: .opacity))
            .animation(.appBouncy.delay(delay), value: UUID())
    }
}
