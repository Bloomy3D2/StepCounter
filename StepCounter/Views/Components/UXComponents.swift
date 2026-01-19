//
//  UXComponents.swift
//  StepCounter
//
//  UX компоненты: FAB, Skeleton, Toast
//

import SwiftUI

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.impact(style: .medium)
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: color.opacity(0.4), radius: 12, x: 0, y: 6)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(FABButtonStyle(isPressed: $isPressed))
    }
}

struct FABButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.appSpring, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                isPressed = pressed
            }
    }
}

// MARK: - Skeleton Loading

struct SkeletonView: View {
    @State private var isAnimating = false
    
    let shape: ShapeType
    let width: CGFloat?
    let height: CGFloat?
    
    enum ShapeType {
        case rectangle
        case circle
        case rounded(CGFloat)
    }
    
    init(shape: ShapeType = .rounded(8), width: CGFloat? = nil, height: CGFloat? = nil) {
        self.shape = shape
        self.width = width
        self.height = height
    }
    
    var body: some View {
        Group {
            switch shape {
            case .rectangle:
                Rectangle()
                    .fill(skeletonGradient)
            case .circle:
                Circle()
                    .fill(skeletonGradient)
            case .rounded(let radius):
                RoundedRectangle(cornerRadius: radius)
                    .fill(skeletonGradient)
            }
        }
        .frame(width: width, height: height)
        .offset(x: isAnimating ? 200 : -200)
        .mask(
            Group {
                switch shape {
                case .rectangle: Rectangle()
                case .circle: Circle()
                case .rounded(let radius): RoundedRectangle(cornerRadius: radius)
                }
            }
        )
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
    
    private var skeletonGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.1),
                Color.white.opacity(0.2),
                Color.white.opacity(0.1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Skeleton Card

struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SkeletonView(shape: .rounded(8), width: 120, height: 16)
            SkeletonView(shape: .rounded(8), width: nil, height: 80)
            HStack {
                SkeletonView(shape: .rounded(8), width: 60, height: 12)
                Spacer()
                SkeletonView(shape: .rounded(8), width: 40, height: 12)
            }
        }
        .padding(16)
        .background(
            GlassCard(cornerRadius: 16, padding: 0) {
                Color.clear
            }
        )
    }
}

// MARK: - Toast Notification

struct ToastData: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let icon: String
    let color: Color
    let duration: TimeInterval
    
    static func success(_ message: String, duration: TimeInterval = 2.0) -> ToastData {
        ToastData(message: message, icon: "checkmark.circle.fill", color: .green, duration: duration)
    }
    
    static func error(_ message: String, duration: TimeInterval = 3.0) -> ToastData {
        ToastData(message: message, icon: "xmark.circle.fill", color: .red, duration: duration)
    }
    
    static func info(_ message: String, duration: TimeInterval = 2.0) -> ToastData {
        ToastData(message: message, icon: "info.circle.fill", color: .blue, duration: duration)
    }
    
    static func warning(_ message: String, duration: TimeInterval = 2.5) -> ToastData {
        ToastData(message: message, icon: "exclamationmark.triangle.fill", color: .orange, duration: duration)
    }
}

class ToastManager: ObservableObject {
    @Published var currentToast: ToastData?
    
    func show(_ toast: ToastData) {
        currentToast = toast
        
        DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
            if self.currentToast?.id == toast.id {
                withAnimation(.appSpring) {
                    self.currentToast = nil
                }
            }
        }
    }
    
    func dismiss() {
        withAnimation(.appSpring) {
            currentToast = nil
        }
    }
}

struct ToastView: View {
    let toast: ToastData
    @Binding var isPresented: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.icon)
                .font(.system(size: 20))
                .foregroundColor(toast.color)
            
            Text(toast.message)
                .font(.appCaption)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            GlassCard(
                cornerRadius: 16,
                padding: 0,
                glowColor: toast.color.opacity(0.3)
            ) {
                Color.clear
            }
        )
        .padding(.horizontal, 20)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onTapGesture {
            withAnimation(.appSpring) {
                isPresented = false
            }
        }
    }
}

struct ToastModifier: ViewModifier {
    @ObservedObject var toastManager = ToastManager.shared
    
    func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    if let toast = toastManager.currentToast {
                        ToastView(toast: toast, isPresented: Binding(
                            get: { toastManager.currentToast != nil },
                            set: { if !$0 { toastManager.dismiss() } }
                        ))
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    Spacer()
                }
                .animation(.appSpring, value: toastManager.currentToast?.id)
                .padding(.top, 60)
            )
    }
}

extension View {
    /// Показать Toast уведомление
    func toast(_ toast: ToastData?) {
        if let toast = toast {
            ToastManager.shared.show(toast)
        }
    }
    
    /// Модификатор для Toast системы
    func withToast() -> some View {
        modifier(ToastModifier())
    }
}

extension ToastManager {
    static let shared = ToastManager()
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        VStack(spacing: 30) {
            // Skeleton
            SkeletonCard()
            
            // FAB
            FloatingActionButton(
                icon: "plus",
                color: .blue
            ) {
                print("FAB tapped")
            }
            
            // Toast
            Button("Show Toast") {
                ToastManager.shared.show(.success("Успешно сохранено!"))
            }
        }
    }
}
