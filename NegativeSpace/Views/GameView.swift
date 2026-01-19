//
//  GameView.swift
//  NegativeSpace
//
//  Игровой экран
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject var gameManager: GameManager
    @StateObject private var adManager = AdManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // Дизайн
    private let bgColor = Color(red: 0.05, green: 0.05, blue: 0.08)
    private let cardColor = Color(red: 0.1, green: 0.1, blue: 0.14)
    private let accentColor = Color(red: 0.4, green: 0.8, blue: 0.95)
    private let emptyColor = Color(red: 0.2, green: 0.2, blue: 0.28)
    
    // Состояния
    @State private var dragOffset: CGSize = .zero
    @State private var dragLocation: CGPoint = .zero
    @State private var isDragging = false
    
    private let cellSize: CGFloat = 60
    private let cellSpacing: CGFloat = 4
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Верхняя панель
                topBar
                
                Spacer()
                
                // Игровое поле
                gameBoard
                    .padding(.horizontal)
                
                Spacer()
                
                // Блоки для размещения
                blocksPanel
                
                // Кнопки управления
                controlButtons
            }
            .padding(.vertical)
            
            // Экран победы
            if gameManager.showVictory {
                victoryOverlay
            }
            
            // Экран "Время вышло"
            if gameManager.isTimeUp {
                timeUpOverlay
            }
        }
        .navigationBarHidden(true)
        .onDisappear {
            gameManager.stopTimer()
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        VStack(spacing: 12) {
            HStack {
                // Кнопка назад
                Button {
                    gameManager.stopTimer()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(cardColor)
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Номер уровня
                VStack(spacing: 2) {
                    Text("УРОВЕНЬ")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("\(gameManager.currentLevelIndex)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Подсказка
                Button {
                    gameManager.useHint()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(accentColor)
                        Text("\(gameManager.hints)")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(width: 60, height: 44)
                    .background(cardColor)
                    .clipShape(Capsule())
                }
                .disabled(gameManager.hints == 0)
                .opacity(gameManager.hints == 0 ? 0.5 : 1)
            }
            
            // Таймер и прогресс
            if gameManager.isTimedMode && gameManager.levelTime > 0 {
                timerBar
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Timer Bar
    
    private var timerBar: some View {
        VStack(spacing: 6) {
            HStack {
                // Звёзды цели
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        let threshold: Double = i == 0 ? 0 : (i == 1 ? 0.3 : 0.6)
                        let isFilled = gameManager.timeRemaining / gameManager.levelTime > threshold
                        
                        Image(systemName: isFilled ? "star.fill" : "star")
                            .font(.system(size: 14))
                            .foregroundColor(isFilled ? .yellow : .white.opacity(0.3))
                    }
                }
                
                Spacer()
                
                // Время
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .foregroundColor(timerColor)
                    Text(formatTime(gameManager.timeRemaining))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(timerColor)
                }
            }
            
            // Прогресс бар
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(timerColor)
                        .frame(width: geo.size.width * (gameManager.timeRemaining / gameManager.levelTime))
                        .animation(.linear(duration: 0.1), value: gameManager.timeRemaining)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardColor)
        )
    }
    
    private var timerColor: Color {
        let percent = gameManager.timeRemaining / gameManager.levelTime
        if percent > 0.6 {
            return .green
        } else if percent > 0.3 {
            return .yellow
        } else {
            return Color(red: 1.0, green: 0.45, blue: 0.5)
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Game Board
    
    private var gameBoard: some View {
        VStack(spacing: cellSpacing) {
            ForEach(0..<gameManager.gameBoard.count, id: \.self) { row in
                HStack(spacing: cellSpacing) {
                    ForEach(0..<gameManager.gameBoard[row].count, id: \.self) { col in
                        cellView(row: row, col: col)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardColor)
        )
    }
    
    private func cellView(row: Int, col: Int) -> some View {
        let cell = gameManager.gameBoard[row][col]
        
        return Button {
            if gameManager.selectedBlock != nil {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    gameManager.placeBlock(at: row, col: col)
                }
            }
        } label: {
            RoundedRectangle(cornerRadius: 10)
                .fill(cellColor(for: cell))
                .frame(width: cellSize, height: cellSize)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(cellBorderColor(for: cell, row: row, col: col), lineWidth: 2)
                )
                .shadow(
                    color: cell.color.opacity(cell == .empty ? 0 : 0.3),
                    radius: 4,
                    y: 2
                )
        }
        .disabled(cell != .empty || gameManager.selectedBlock == nil)
    }
    
    private func cellColor(for cell: CellState) -> Color {
        switch cell {
        case .empty:
            return emptyColor
        case .blocked:
            return .clear
        case .filled(let color):
            return color
        }
    }
    
    private func cellBorderColor(for cell: CellState, row: Int, col: Int) -> Color {
        if cell == .empty && gameManager.selectedBlock != nil {
            // Подсветка возможных позиций
            if gameManager.canPlaceBlock(gameManager.selectedBlock!, at: row, col: col) {
                return accentColor.opacity(0.8)
            }
        }
        
        switch cell {
        case .empty:
            return Color.white.opacity(0.1)
        case .blocked:
            return .clear
        case .filled(let color):
            return color.opacity(0.5)
        }
    }
    
    // MARK: - Blocks Panel
    
    private var blocksPanel: some View {
        VStack(spacing: 12) {
            HStack {
                Text("БЛОКИ")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                // Кнопка вращения
                if gameManager.selectedBlock != nil {
                    Button {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            gameManager.rotateSelectedBlock()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "rotate.right")
                            Text("Повернуть")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(accentColor.opacity(0.15))
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(gameManager.availableBlocks) { block in
                        BlockView(
                            block: block,
                            isSelected: gameManager.selectedBlock?.id == block.id,
                            cellSize: 24
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                gameManager.selectBlock(block)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardColor)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        VStack(spacing: 12) {
            // Кнопка для получения подсказок за рекламу
            if gameManager.hints < 3 {
                Button {
                    adManager.showRewardedAd { reward in
                        gameManager.addHints(reward)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.rectangle.fill")
                            .foregroundColor(.orange)
                        Text("Смотреть рекламу")
                        Text("+\(AdConfig.hintsReward)")
                            .fontWeight(.bold)
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                    }
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.8), Color.red.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!adManager.isRewardedAdReady)
                .opacity(adManager.isRewardedAdReady ? 1 : 0.5)
            }
            
            // Сброс
            HStack(spacing: 16) {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        gameManager.resetLevel()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Сброс")
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(cardColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Victory Overlay
    
    private var victoryOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Звёзды
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < gameManager.earnedStars ? "star.fill" : "star")
                            .font(.system(size: 40))
                            .foregroundColor(i < gameManager.earnedStars ? .yellow : .white.opacity(0.3))
                            .scaleEffect(i < gameManager.earnedStars ? 1.0 : 0.8)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.6)
                                .delay(Double(i) * 0.15),
                                value: gameManager.earnedStars
                            )
                    }
                }
                
                // Текст
                VStack(spacing: 8) {
                    Text("УРОВЕНЬ ПРОЙДЕН!")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Уровень \(gameManager.currentLevelIndex)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    // Статистика
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(gameManager.movesCount)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            Text("Ходов")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        if gameManager.isTimedMode {
                            VStack {
                                Text(formatTime(gameManager.levelTime - gameManager.timeRemaining))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Время")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                
                // Кнопки
                VStack(spacing: 12) {
                    // Следующий уровень
                    Button {
                        adManager.showInterstitialIfNeeded()
                        withAnimation {
                            gameManager.nextLevel()
                        }
                    } label: {
                        HStack {
                            Text("Следующий уровень")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    // К уровням
                    Button {
                        dismiss()
                    } label: {
                        Text("К списку уровней")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.16))
            )
            .padding(.horizontal, 32)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
    
    // MARK: - Time Up Overlay
    
    private var timeUpOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Иконка
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "clock.badge.xmark")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                }
                
                VStack(spacing: 8) {
                    Text("ВРЕМЯ ВЫШЛО!")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Попробуй ещё раз")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                VStack(spacing: 12) {
                    // Попробовать снова
                    Button {
                        withAnimation {
                            gameManager.resetLevel()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Попробовать снова")
                        }
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    // Смотреть рекламу за время
                    Button {
                        adManager.showRewardedAd { _ in
                            // Добавляем 30 секунд
                            gameManager.timeRemaining = 30
                            gameManager.isTimeUp = false
                            gameManager.toggleTimedMode() // Перезапуск таймера
                            gameManager.toggleTimedMode()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "play.rectangle.fill")
                                .foregroundColor(.orange)
                            Text("Смотреть рекламу (+30 сек)")
                        }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(cardColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    // К уровням
                    Button {
                        dismiss()
                    } label: {
                        Text("К списку уровней")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.16))
            )
            .padding(.horizontal, 32)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}

// MARK: - Block View

struct BlockView: View {
    let block: Block
    let isSelected: Bool
    let cellSize: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                ForEach(0..<block.shape.count, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<block.shape[row].count, id: \.self) { col in
                            if block.shape[row][col] {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(block.color)
                                    .frame(width: cellSize, height: cellSize)
                            } else {
                                Color.clear
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isSelected ? 0.15 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? block.color : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    GameView()
        .environmentObject({
            let manager = GameManager()
            manager.loadLevel(1)
            return manager
        }())
}
