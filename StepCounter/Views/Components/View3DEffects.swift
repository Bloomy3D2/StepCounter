//
//  View3DEffects.swift
//  StepCounter
//
//  3D эффекты для медалей и карточек
//

import SwiftUI

// MARK: - 3D Rotation Modifier

struct Rotation3DModifier: ViewModifier {
    @State private var rotationX: CGFloat = 0
    @State private var rotationY: CGFloat = 0
    @State private var isPressed = false
    
    let maxRotation: CGFloat
    
    init(maxRotation: CGFloat = 15) {
        self.maxRotation = maxRotation
    }
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(rotationX),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.5
            )
            .rotation3DEffect(
                .degrees(rotationY),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.appSpring, value: isPressed)
            .onTapGesture {
                withAnimation(.appBouncy) {
                    rotationX = maxRotation
                    rotationY = maxRotation / 2
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        rotationX = 0
                        rotationY = 0
                    }
                }
                HapticManager.impact(style: .light)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isPressed {
                            isPressed = true
                        }
                        
                        let dragX = value.translation.width
                        let dragY = value.translation.height
                        
                        rotationY = min(max(-maxRotation, dragX / 10), maxRotation)
                        rotationX = min(max(-maxRotation, -dragY / 10), maxRotation)
                    }
                    .onEnded { _ in
                        withAnimation(.appSpring) {
                            rotationX = 0
                            rotationY = 0
                            isPressed = false
                        }
                    }
            )
    }
}

extension View {
    /// Применить 3D поворот при взаимодействии
    func rotation3D(maxRotation: CGFloat = 15) -> some View {
        modifier(Rotation3DEffectsModifier(maxRotation: maxRotation))
    }
}

// MARK: - Enhanced 3D Effects Modifier

struct Rotation3DEffectsModifier: ViewModifier {
    @State private var rotationX: CGFloat = 0
    @State private var rotationY: CGFloat = 0
    @State private var isPressed = false
    
    let maxRotation: CGFloat
    
    init(maxRotation: CGFloat = 15) {
        self.maxRotation = maxRotation
    }
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(rotationX),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.5
            )
            .rotation3DEffect(
                .degrees(rotationY),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.appSpring, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isPressed {
                            isPressed = true
                        }
                        
                        let dragX = value.translation.width
                        let dragY = value.translation.height
                        
                        rotationY = min(max(-maxRotation, dragX / 10), maxRotation)
                        rotationX = min(max(-maxRotation, -dragY / 10), maxRotation)
                    }
                    .onEnded { _ in
                        withAnimation(.appSpring) {
                            rotationX = 0
                            rotationY = 0
                            isPressed = false
                        }
                    }
            )
    }
}

// MARK: - Parallax Modifier

struct ParallaxModifier: ViewModifier {
    @State private var offset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: true)) {
                    offset = 5
                }
            }
    }
}

extension View {
    /// Легкий параллакс эффект
    func parallax() -> some View {
        modifier(ParallaxModifier())
    }
}

// MARK: - Depth Shadow Modifier

struct DepthShadowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius * 0.5, x: x * 0.5, y: y * 0.5)
            .shadow(color: color.opacity(0.3), radius: radius, x: x, y: y)
            .shadow(color: color.opacity(0.2), radius: radius * 1.5, x: x * 1.5, y: y * 1.5)
    }
}

extension View {
    /// Многослойные тени для глубины
    func depthShadow(color: Color = .black, radius: CGFloat = 10, x: CGFloat = 0, y: CGFloat = 5) -> some View {
        modifier(DepthShadowModifier(color: color, radius: radius, x: x, y: y))
    }
}

// MARK: - Glow Effect

struct GlowModifier: ViewModifier {
    let color: Color
    let intensity: CGFloat
    @State private var pulse: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                content
                    .blur(radius: intensity)
                    .opacity(0.6 + Foundation.sin(pulse) * 0.4)
                    .foregroundColor(color)
            )
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    pulse = .pi * 2
                }
            }
    }
}

extension View {
    /// Пульсирующее свечение
    func glowing(color: Color = .blue, intensity: CGFloat = 10) -> some View {
        modifier(GlowModifier(color: color, intensity: intensity))
    }
}

// MARK: - Cascade Animation

struct CascadeAnimation: ViewModifier {
    let delay: Double
    
    @State private var opacity: Double = 0
    @State private var offset: CGFloat = 20
    @State private var scale: CGFloat = 0.8
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .offset(y: offset)
            .scaleEffect(scale)
            .onAppear {
                // Анимируем только при первом появлении
                if !hasAppeared {
                    hasAppeared = true
                    withAnimation(.appSpring.delay(delay)) {
                        opacity = 1
                        offset = 0
                        scale = 1
                    }
                } else {
                    // При повторном появлении сразу показываем без анимации
                    opacity = 1
                    offset = 0
                    scale = 1
                }
            }
    }
}

extension View {
    /// Каскадное появление с задержкой
    func cascadeAppear(delay: Double = 0) -> some View {
        modifier(CascadeAnimation(delay: delay))
    }
}
