//
//  GameView.swift
//  OrbitMatch
//
//  Игровой экран
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss
    
    // Дизайн
    private let bgColor = Color(red: 0.02, green: 0.02, blue: 0.05)
    private let cardColor = Color(red: 0.07, green: 0.07, blue: 0.11)
    private let accentCyan = Color(red: 0.4, green: 0.85, blue: 0.95)
    private let accentPink = Color(red: 1.0, green: 0.45, blue: 0.55)
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            // Звёзды
            starsBackground
            
            VStack(spacing: 16) {
                // Верхняя панель
                topBar
                
                // Прогресс
                progressBar
                
                Spacer()
                
                // Игровое поле с орбитами
                orbitField
                
                Spacer()
                
                // Подсказка
                hint
            }
            .padding(.vertical)
            
            // Оверлеи
            if gameManager.isLevelComplete {
                victoryOverlay
            }
            
            if gameManager.isGameOver {
                gameOverOverlay
            }
        }
        .navigationBarHidden(true)
        .onDisappear {
            gameManager.stopGame()
        }
    }
    
    // MARK: - Stars
    
    private var starsBackground: some View {
        GeometryReader { geo in
            ForEach(0..<20, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.1...0.4)))
                    .frame(width: CGFloat.random(in: 1...2))
                    .position(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: CGFloat.random(in: 0...geo.size.height)
                    )
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            Button {
                gameManager.stopGame()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(cardColor)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("УРОВЕНЬ")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                
                Text("\(gameManager.currentLevel)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Таймер
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 3)
                    .frame(width: 44, height: 44)
                
                Circle()
                    .trim(from: 0, to: gameManager.timeRemaining / 60.0)
                    .stroke(timerColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(gameManager.timeRemaining))")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(timerColor)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var timerColor: Color {
        gameManager.timeRemaining > 20 ? accentCyan : (gameManager.timeRemaining > 10 ? .yellow : accentPink)
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        VStack(spacing: 8) {
            HStack {
                // Комбо
                if gameManager.combo > 1 {
                    HStack(spacing: 4) {
                        Text("×\(gameManager.combo)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                        Text("COMBO")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.yellow.opacity(0.7))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.yellow.opacity(0.15)))
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(gameManager.score)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("/")
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("\(gameManager.targetScore)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [accentCyan, accentPink], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * min(1.0, Double(gameManager.score) / Double(gameManager.targetScore)))
                        .animation(.spring(response: 0.3), value: gameManager.score)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Orbit Field
    
    private var orbitField: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            
            ZStack {
                // Прицел (линия вверх)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [accentCyan.opacity(0.8), accentCyan.opacity(0)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 4, height: geo.size.height / 2 - 30)
                    .position(x: center.x, y: geo.size.height / 4)
                
                // Центральная точка
                Circle()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
                    .position(center)
                
                // Орбиты
                ForEach(gameManager.orbits) { orbit in
                    // Линия орбиты
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        .frame(width: orbit.radius * 2, height: orbit.radius * 2)
                        .position(center)
                    
                    // Шарики
                    ForEach(orbit.balls) { ball in
                        if !ball.isMatched {
                            let angle = gameManager.getCurrentAngle(for: ball, orbit: orbit)
                            let x = center.x + cos(angle) * orbit.radius
                            let y = center.y + sin(angle) * orbit.radius
                            let inTarget = gameManager.isBallInTargetZone(ball, orbit: orbit)
                            
                            ZStack {
                                // Свечение в зоне прицела
                                if inTarget {
                                    Circle()
                                        .fill(ball.color.color.opacity(0.4))
                                        .frame(width: 35, height: 35)
                                        .blur(radius: 8)
                                }
                                
                                Circle()
                                    .fill(ball.color.color)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(inTarget ? 0.8 : 0.3), lineWidth: inTarget ? 2 : 1)
                                    )
                                    .scaleEffect(inTarget ? 1.2 : 1.0)
                            }
                            .position(x: x, y: y)
                            .animation(.easeInOut(duration: 0.1), value: inTarget)
                        }
                    }
                }
                
                // Зона тапа
                Circle()
                    .fill(Color.clear)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .contentShape(Circle())
                    .onTapGesture {
                        gameManager.tapToMatch()
                    }
            }
        }
        .frame(height: 350)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Hint
    
    private var hint: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "hand.tap.fill")
                    .foregroundColor(accentCyan)
                
                Text("Тапни, когда шарики одного цвета на линии!")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule().fill(cardColor)
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Victory Overlay
    
    private var victoryOverlay: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(accentCyan.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.yellow)
                }
                
                VStack(spacing: 8) {
                    Text("УРОВЕНЬ ПРОЙДЕН!")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Очки: \(gameManager.score)")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                VStack(spacing: 12) {
                    Button {
                        gameManager.nextLevel()
                    } label: {
                        HStack {
                            Text("Следующий уровень")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient(colors: [accentCyan, accentPink], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    Button { dismiss() } label: {
                        Text("К уровням")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(32)
            .background(RoundedRectangle(cornerRadius: 28).fill(Color(red: 0.1, green: 0.1, blue: 0.14)))
            .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Game Over Overlay
    
    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(accentPink.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "clock.badge.xmark")
                        .font(.system(size: 50))
                        .foregroundColor(accentPink)
                }
                
                VStack(spacing: 8) {
                    Text("ВРЕМЯ ВЫШЛО")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Очки: \(gameManager.score) / \(gameManager.targetScore)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                VStack(spacing: 12) {
                    Button {
                        gameManager.restartLevel()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Попробовать снова")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(accentPink)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    Button { dismiss() } label: {
                        Text("К уровням")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(32)
            .background(RoundedRectangle(cornerRadius: 28).fill(Color(red: 0.1, green: 0.1, blue: 0.14)))
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Preview

#Preview {
    GameView()
        .environmentObject({
            let manager = GameManager()
            manager.startLevel(1)
            return manager
        }())
}
