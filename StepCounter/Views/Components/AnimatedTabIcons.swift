//
//  AnimatedTabIcons.swift
//  StepCounter
//
//  Анимированные иконки для вкладок
//

import SwiftUI

// MARK: - Animated Walking Person Icon

struct AnimatedWalkingPerson: View {
    @State private var leftArmAngle: Double = -20
    @State private var rightArmAngle: Double = 20
    @State private var leftLegAngle: Double = 20
    @State private var rightLegAngle: Double = -20
    @State private var bodyOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Тело
            Circle()
                .fill(Color.white)
                .frame(width: 16, height: 16)
                .offset(y: bodyOffset)
            
            // Голова
            Circle()
                .fill(Color.white)
                .frame(width: 12, height: 12)
                .offset(y: -12 + bodyOffset)
            
            // Левая рука
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .frame(width: 3, height: 10)
                .offset(x: -8, y: -4 + bodyOffset)
                .rotationEffect(.degrees(leftArmAngle), anchor: .top)
            
            // Правая рука
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .frame(width: 3, height: 10)
                .offset(x: 8, y: -4 + bodyOffset)
                .rotationEffect(.degrees(rightArmAngle), anchor: .top)
            
            // Левая нога
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .frame(width: 3, height: 10)
                .offset(x: -6, y: 8 + bodyOffset)
                .rotationEffect(.degrees(leftLegAngle), anchor: .top)
            
            // Правая нога
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .frame(width: 3, height: 10)
                .offset(x: 6, y: 8 + bodyOffset)
                .rotationEffect(.degrees(rightLegAngle), anchor: .top)
        }
        .frame(width: 24, height: 32)
        .onAppear {
            startWalkingAnimation()
        }
    }
    
    private func startWalkingAnimation() {
        // Анимация рук
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            leftArmAngle = 20
            rightArmAngle = -20
        }
        
        // Анимация ног (противоположно рукам)
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            leftLegAngle = -20
            rightLegAngle = 20
        }
        
        // Легкое покачивание тела
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            bodyOffset = 1
        }
    }
}

// MARK: - Animated Bars Icon (Statistics)

struct AnimatedBarsIcon: View {
    @State private var bar1Height: CGFloat = 0.3
    @State private var bar2Height: CGFloat = 0.7
    @State private var bar3Height: CGFloat = 0.5
    @State private var bar4Height: CGFloat = 0.9
    
    var body: some View {
        HStack(spacing: 3) {
            // Бар 1
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .frame(width: 4, height: 16 * bar1Height)
            
            // Бар 2
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .frame(width: 4, height: 16 * bar2Height)
            
            // Бар 3
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .frame(width: 4, height: 16 * bar3Height)
            
            // Бар 4
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .frame(width: 4, height: 16 * bar4Height)
        }
        .frame(width: 20, height: 16, alignment: .bottom)
        .onAppear {
            startBarAnimation()
        }
    }
    
    private func startBarAnimation() {
        // Анимация каждого бара с разной задержкой
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            bar1Height = 0.7
        }
        
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.1)) {
            bar2Height = 0.3
        }
        
        withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true).delay(0.2)) {
            bar3Height = 0.9
        }
        
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true).delay(0.3)) {
            bar4Height = 0.4
        }
    }
}

// MARK: - Animated Route Icon (Compass/Map)

struct AnimatedRouteIcon: View {
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Внешний круг (компас)
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 20, height: 20)
            
            // Стрелка компаса
            Path { path in
                path.move(to: CGPoint(x: 10, y: 10))
                path.addLine(to: CGPoint(x: 10, y: 4))
            }
            .stroke(Color.white, lineWidth: 2)
            .rotationEffect(.degrees(rotationAngle))
            
            // Центральная точка
            Circle()
                .fill(Color.white)
                .frame(width: 4, height: 4)
                .scaleEffect(pulseScale)
        }
        .frame(width: 24, height: 24)
        .onAppear {
            startRouteAnimation()
        }
    }
    
    private func startRouteAnimation() {
        // Вращение стрелки
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        // Пульсация центральной точки
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.3
        }
    }
}

// MARK: - Animated Challenge Icon (Flag/Medal)

struct AnimatedChallengeIcon: View {
    @State private var flagWave: CGFloat = 0
    @State private var medalRotation: Double = 0
    @State private var sparkleOpacity: Double = 1.0
    
    var body: some View {
        ZStack {
            // Флаг
            Path { path in
                path.move(to: CGPoint(x: 4, y: 4))
                path.addLine(to: CGPoint(x: 4, y: 16))
                path.addLine(to: CGPoint(x: 12, y: 12))
                path.addLine(to: CGPoint(x: 12, y: 8))
                path.closeSubpath()
            }
            .fill(Color.white)
            .offset(x: flagWave)
            
            // Древко флага
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.white)
                .frame(width: 2, height: 16)
                .offset(x: -6)
            
            // Медаль/звезда
            Image(systemName: "star.fill")
                .font(.system(size: 8))
                .foregroundColor(.yellow)
                .offset(x: 8, y: -2)
                .rotationEffect(.degrees(medalRotation))
                .opacity(sparkleOpacity)
        }
        .frame(width: 20, height: 20)
        .onAppear {
            startChallengeAnimation()
        }
    }
    
    private func startChallengeAnimation() {
        // Волна флага
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            flagWave = 1
        }
        
        // Вращение медали
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            medalRotation = 360
        }
        
        // Мерцание
        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
            sparkleOpacity = 0.3
        }
    }
}

// MARK: - Modern Telegram-Style Tab Bar

struct CustomAnimatedTabBar: View {
    @Binding var selectedTab: MainTabView.TabSelection
    let accentGreen: Color
    
    var body: some View {
        HStack(spacing: 0) {
            // Сегодня
            ModernTabButton(
                icon: "figure.walk",
                title: "Сегодня",
                isSelected: selectedTab == .today,
                color: accentGreen
            ) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    selectedTab = .today
                }
            }
            
            // Статистика
            ModernTabButton(
                icon: "chart.bar.fill",
                title: "Статистика",
                isSelected: selectedTab == .stats,
                color: accentGreen
            ) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    selectedTab = .stats
                }
            }
            
            // Питомец
            ModernTabButton(
                icon: "pawprint.fill",
                title: "Питомец",
                isSelected: selectedTab == .pet,
                color: accentGreen
            ) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    selectedTab = .pet
                }
            }
            
            // Маршруты
            ModernTabButton(
                icon: "map.fill",
                title: "Маршруты",
                isSelected: selectedTab == .routes,
                color: accentGreen
            ) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    selectedTab = .routes
                }
            }
            
            // Челленджи
            ModernTabButton(
                icon: "flag.fill",
                title: "Челленджи",
                isSelected: selectedTab == .challenges,
                color: accentGreen
            ) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    selectedTab = .challenges
                }
            }
        }
        .frame(height: 64)
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 0)
        .background(
            ZStack {
                // Glassmorphism фон с более сильным размытием (как в Telegram)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        // Дополнительный слой размытия для более сильного эффекта
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.black.opacity(0.1))
                            .blur(radius: 20)
                    )
                    .overlay(
                        // Верхняя тонкая линия
                        VStack {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.white.opacity(0.12))
                                .frame(height: 0.5)
                                .padding(.horizontal, 20)
                            Spacer()
                        }
                    )
            }
        )
    }
}

// MARK: - Modern Tab Button (Telegram Style)

struct ModernTabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.impact(style: .light)
            action()
        }) {
            VStack(spacing: 4) {
                ZStack {
                    // Фон для выбранной кнопки
                    if isSelected {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 40, height: 40)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Иконка
                    Image(systemName: icon)
                        .font(.system(size: isSelected ? 20 : 18, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? color : .white.opacity(0.65))
                        .symbolEffect(.bounce, value: isSelected)
                        .frame(width: 24, height: 24)
                }
                .frame(width: 40, height: 40)
                
                // Текст
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? color : .white.opacity(0.65))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(height: 12)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}
