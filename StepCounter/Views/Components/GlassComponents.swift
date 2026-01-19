//
//  GlassComponents.swift
//  StepCounter
//
//  Glassmorphism компоненты для премиального визуала
//

import SwiftUI

// MARK: - Glass Card

/// Универсальная карточка с эффектом стекла
struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let padding: CGFloat
    let glowColor: Color?
    let content: Content
    
    init(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 20,
        glowColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.glowColor = glowColor
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Основной стеклянный фон
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    
                    // Градиентная граница
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.3),
                                    .white.opacity(0.1),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                    
                    // Свечение (если указано)
                    if let glowColor = glowColor {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(glowColor.opacity(0.4), lineWidth: 2)
                            .blur(radius: 8)
                    }
                }
                .shadow(
                    color: .black.opacity(0.3),
                    radius: 20,
                    x: 0,
                    y: 10
                )
                .shadow(
                    color: glowColor?.opacity(0.2) ?? .clear,
                    radius: 15,
                    x: 0,
                    y: 5
                )
            )
    }
}

// MARK: - Glass Panel

/// Полупрозрачная панель для наложения на контент
struct GlassPanel: View {
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = 16) {
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Glass Button

/// Кнопка с эффектом стекла
struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let gradient: LinearGradient?
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    
    @State private var isPressed = false
    
    init(
        _ title: String,
        icon: String? = nil,
        gradient: LinearGradient? = nil,
        hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.gradient = gradient
        self.hapticStyle = hapticStyle
    }
    
    var body: some View {
        Button(action: {
            HapticManager.impact(style: hapticStyle)
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    if let gradient = gradient {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(gradient)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.3), .clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                    }
                }
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
    }
}

// MARK: - Press Events View Modifier

struct PressEvents: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(
        onPress: @escaping () -> Void,
        onRelease: @escaping () -> Void
    ) -> some View {
        self.modifier(PressEvents(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Haptic Manager

struct HapticManager {
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Glass Progress Ring

/// Прогресс-кольцо с эффектом стекла
struct GlassProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let colors: [Color]
    let glowColor: Color?
    
    @State private var animatedProgress: Double = 0
    
    init(
        progress: Double,
        lineWidth: CGFloat = 20,
        colors: [Color] = [.green, .blue],
        glowColor: Color? = nil
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.colors = colors
        self.glowColor = glowColor
    }
    
    var body: some View {
        ZStack {
            // Фон
            Circle()
                .stroke(
                    Color.white.opacity(0.1),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
            
            // Прогресс с градиентом
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: colors,
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: glowColor?.opacity(0.6) ?? colors.first?.opacity(0.5) ?? .clear,
                    radius: 15,
                    x: 0,
                    y: 0
                )
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Glass Stat Card

/// Карточка статистики с эффектом стекла
struct GlassStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let iconSize: CGFloat
    let isLocked: Bool
    
    init(
        icon: String,
        value: String,
        label: String,
        color: Color,
        iconSize: CGFloat = 24,
        isLocked: Bool = false
    ) {
        self.icon = icon
        self.value = value
        self.label = label
        self.color = color
        self.iconSize = iconSize
        self.isLocked = isLocked
    }
    
    var body: some View {
        ZStack {
            GlassCard(cornerRadius: 16, padding: 16, glowColor: color.opacity(0.3)) {
                VStack(spacing: 12) {
                    // Иконка
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: icon)
                            .font(.system(size: iconSize, weight: .semibold))
                            .foregroundColor(color)
                            .accessibilityHidden(true)
                    }
                    .frame(height: 44)
                    
                    // Значение
                    Text(value)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(height: 30)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    
                    // Метка
                    HStack(spacing: 4) {
                        Text(label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                        
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .frame(height: 16)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 120)
            }
            
            // Затемнение и иконка замка для заблокированных карточек
            if isLocked {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.4))
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("Premium")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)\(isLocked ? ", требуется Premium" : "")")
    }
}

#Preview {
    ZStack {
        // Фон для демонстрации
        LinearGradient(
            colors: [Color(red: 0.02, green: 0.02, blue: 0.05), Color(red: 0.1, green: 0.1, blue: 0.15)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 20) {
            GlassCard(glowColor: .green) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("10,234")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("шагов сегодня")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            GlassProgressRing(
                progress: 0.75,
                colors: [.green, .blue],
                glowColor: .green
            )
            .frame(width: 150, height: 150)
            
            HStack(spacing: 12) {
                GlassStatCard(
                    icon: "figure.walk",
                    value: "5.2 км",
                    label: "Дистанция",
                    color: .blue
                )
                
                GlassStatCard(
                    icon: "flame.fill",
                    value: "245",
                    label: "Калории",
                    color: .orange
                )
            }
            
            GlassButton("Оформить Premium", icon: "crown.fill", gradient: LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)) {
                print("Premium")
            }
        }
        .padding()
    }
}
