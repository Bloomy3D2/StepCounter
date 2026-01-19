//
//  AnimatedTabIcon.swift
//  StepCounter
//
//  Анимированные иконки для таб-бара
//

import SwiftUI

struct AnimatedTabIcon: View {
    let icon: String
    let animationType: AnimationType
    let triggerAnimation: Bool
    
    @State private var isAnimating = false
    @State private var animationOffset: CGFloat = 0
    @State private var animationScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    
    enum AnimationType {
        case walk      // Движение (для "Сегодня")
        case chart     // График (для "Статистика")
        case pawprint  // Лапка (для "Питомец")
        case map       // Карта (для "Маршруты")
    }
    
    var body: some View {
        Group {
            switch animationType {
            case .walk:
                Image(systemName: icon)
                    .offset(x: isAnimating ? animationOffset : 0)
            case .chart:
                Image(systemName: icon)
                    .offset(y: isAnimating ? animationOffset : 0)
            case .pawprint:
                Image(systemName: icon)
                    .scaleEffect(animationScale)
            case .map:
                Image(systemName: icon)
                    .rotationEffect(.degrees(rotationAngle))
            }
        }
        .onChange(of: triggerAnimation) { oldValue, newValue in
            if newValue && !oldValue {
                startAnimation()
            }
        }
    }
    
    private func startAnimation() {
        switch animationType {
        case .walk:
            // Движение вправо-влево для человечка (2-3 сек)
            isAnimating = true
            animationOffset = 0
            
            withAnimation(.easeInOut(duration: 0.4).repeatCount(6, autoreverses: true)) {
                animationOffset = 12
            } completion: {
                isAnimating = false
                animationOffset = 0
            }
        case .chart:
            // Движение вверх-вниз для графика (2-3 сек)
            isAnimating = true
            animationOffset = 0
            
            withAnimation(.easeInOut(duration: 0.5).repeatCount(5, autoreverses: true)) {
                animationOffset = -10
            } completion: {
                isAnimating = false
                animationOffset = 0
            }
        case .pawprint:
            // Пульсация для лапки (2-3 сек)
            animationScale = 1.0
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).repeatCount(6, autoreverses: true)) {
                animationScale = 1.3
            } completion: {
                animationScale = 1.0
            }
        case .map:
            // Вращение для карты (2-3 сек)
            rotationAngle = 0
            
            withAnimation(.linear(duration: 2.5)) {
                rotationAngle = 360
            } completion: {
                rotationAngle = 0
            }
        }
    }
}
