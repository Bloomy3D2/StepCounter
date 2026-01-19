//
//  GameView.swift
//  PulseGrid
//
//  Игровой экран
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var audioManager: AudioManager
    @Environment(\.dismiss) private var dismiss
    
    // Дизайн
    private let bgColor = Color(red: 0.03, green: 0.03, blue: 0.06)
    private let cardColor = Color(red: 0.08, green: 0.08, blue: 0.12)
    private let accentCyan = Color(red: 0.4, green: 0.8, blue: 0.95)
    private let accentPink = Color(red: 1.0, green: 0.45, blue: 0.5)
    
    private let cellSize: CGFloat = 55
    private let cellSpacing: CGFloat = 6
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Верхняя панель
                topBar
                
                // Прогресс и комбо
                progressBar
                
                Spacer()
                
                // Игровое поле
                gameGrid
                
                Spacer()
                
                // Нижняя панель
                bottomInfo
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
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            // Назад
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
            
            // Уровень
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
                    .stroke(
                        timerColor,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
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
        if gameManager.timeRemaining > 20 {
            return accentCyan
        } else if gameManager.timeRemaining > 10 {
            return .yellow
        } else {
            return accentPink
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        VStack(spacing: 8) {
            // Очки и цель
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
                    .background(
                        Capsule()
                            .fill(Color.yellow.opacity(0.15))
                    )
                }
                
                Spacer()
                
                // Очки
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
            
            // Прогресс бар
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [accentCyan, accentPink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * min(1.0, Double(gameManager.score) / Double(gameManager.targetScore)))
                        .animation(.spring(response: 0.3), value: gameManager.score)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Game Grid
    
    private var gameGrid: some View {
        VStack(spacing: cellSpacing) {
            ForEach(0..<gameManager.grid.count, id: \.self) { row in
                HStack(spacing: cellSpacing) {
                    ForEach(0..<gameManager.grid[row].count, id: \.self) { col in
                        let cell = gameManager.grid[row][col]
                        PulseCellView(
                            cell: cell,
                            phase: gameManager.getCellPhase(for: cell),
                            isSelected: gameManager.selectedCells.contains(cell.position),
                            size: cellSize
                        ) {
                            audioManager.playSelectSound()
                            gameManager.selectCell(at: cell.position)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardColor)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Bottom Info
    
    private var bottomInfo: some View {
        VStack(spacing: 12) {
            // Пульсирующий индикатор ритма
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { i in
                    let phase = (gameManager.globalPulsePhase + Double(i) * 0.25).truncatingRemainder(dividingBy: 1.0)
                    let scale = 0.6 + sin(phase * .pi * 2) * 0.4
                    
                    Circle()
                        .fill(
                            phase < 0.15 || phase > 0.85
                                ? accentCyan
                                : accentCyan.opacity(0.3)
                        )
                        .frame(width: 12, height: 12)
                        .scaleEffect(scale)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 20)
            .background(
                Capsule()
                    .fill(cardColor)
            )
            
            // Подсказка
            Text("Соединяй блоки одного цвета в момент пульса")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Victory Overlay
    
    private var victoryOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Иконка
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
                        .background(
                            LinearGradient(
                                colors: [accentCyan, accentPink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("К уровням")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.14))
            )
            .padding(.horizontal, 32)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
    
    // MARK: - Game Over Overlay
    
    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Иконка
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
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("К уровням")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.14))
            )
            .padding(.horizontal, 32)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}

// MARK: - Pulse Cell View

struct PulseCellView: View {
    let cell: PulseCell
    let phase: Double
    let isSelected: Bool
    let size: CGFloat
    let action: () -> Void
    
    private var scale: CGFloat {
        let sineValue = sin(phase * .pi * 2)
        return 0.85 + CGFloat(sineValue) * 0.15
    }
    
    private var opacity: Double {
        let sineValue = sin(phase * .pi * 2)
        return 0.6 + sineValue * 0.4
    }
    
    private var isAtPeak: Bool {
        phase < 0.15 || phase > 0.85
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Фоновое свечение при пике
                if isAtPeak {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(cell.color.color.opacity(0.3))
                        .blur(radius: 8)
                        .scaleEffect(1.2)
                }
                
                // Основная ячейка
                RoundedRectangle(cornerRadius: 12)
                    .fill(cell.color.color.opacity(opacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.white : Color.clear,
                                lineWidth: 3
                            )
                    )
                    .scaleEffect(scale)
                
                // Индикатор выбора
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
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
        .environmentObject(AudioManager())
}
