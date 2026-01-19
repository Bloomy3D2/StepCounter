//
//  ConfettiView.swift
//  StepCounter
//
//  Анимация конфетти при достижении цели
//

import SwiftUI

struct ConfettiView: View {
    @State private var isAnimating = false
    let duration: Double
    
    init(duration: Double = 2.0) {
        self.duration = duration
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<50, id: \.self) { index in
                    ConfettiPiece(
                        index: index,
                        screenWidth: geometry.size.width,
                        screenHeight: geometry.size.height,
                        isAnimating: $isAnimating,
                        duration: duration
                    )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            HapticManager.notification(.success)
            isAnimating = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                isAnimating = false
            }
        }
    }
}

struct ConfettiPiece: View {
    let index: Int
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    @Binding var isAnimating: Bool
    let duration: Double
    
    @State private var xOffset: CGFloat = 0
    @State private var yOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    private var colors: [Color] {
        [.green, .blue, .purple, .pink, .orange, .yellow, .cyan, .red]
    }
    
    private var randomColor: Color {
        colors.randomElement() ?? .yellow
    }
    
    var body: some View {
        Rectangle()
            .fill(randomColor)
            .frame(width: 8, height: 8)
            .cornerRadius(2)
            .offset(x: xOffset, y: yOffset)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                animate()
            }
    }
    
    private func animate() {
        // Случайная начальная позиция (сверху экрана)
        let startX = CGFloat.random(in: -screenWidth/2...screenWidth/2)
        let endX = startX + CGFloat.random(in: -100...100)
        let endY = screenHeight + 200
        
        // Анимация падения
        withAnimation(
            .easeOut(duration: Double.random(in: 1.0...duration))
        ) {
            xOffset = endX
            yOffset = endY
            rotation = Double.random(in: 0...720)
        }
        
        // Затухание
        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.8) {
            withAnimation(.easeOut(duration: duration * 0.2)) {
                opacity = 0
            }
        }
    }
}

// MARK: - Confetti Modifier

extension View {
    func confetti(isPresented: Binding<Bool>) -> some View {
        self.overlay(
            Group {
                if isPresented.wrappedValue {
                    ConfettiView()
                        .transition(.opacity)
                }
            }
        )
    }
}

#Preview {
    ZStack {
        Color(red: 0.02, green: 0.02, blue: 0.05)
            .ignoresSafeArea()
        
        VStack {
            Text("Нажмите для конфетти")
                .foregroundColor(.white)
                .padding()
        }
    }
    .confetti(isPresented: .constant(true))
}
