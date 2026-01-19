//
//  GameView.swift
//  TemperatureTiles
//
//  Игровой экран
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss
    
    // Дизайн
    private let bgColor = Color(red: 0.08, green: 0.06, blue: 0.1)
    private let cardColor = Color(red: 0.12, green: 0.1, blue: 0.15)
    private let hotColor = Color(red: 1.0, green: 0.3, blue: 0.2)
    private let coldColor = Color(red: 0.2, green: 0.5, blue: 1.0)
    
    @State private var animatingTiles: Set<String> = []
    
    var body: some View {
        ZStack {
            // Фон
            LinearGradient(
                colors: [
                    coldColor.opacity(0.1),
                    bgColor,
                    hotColor.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Верхняя панель
                topBar
                
                // Информация о ходах
                movesInfo
                
                Spacer()
                
                // Игровое поле
                gameGrid
                
                Spacer()
                
                // Подсказка
                hintView
                
                // Кнопки
                controlButtons
            }
            .padding(.vertical)
            
            // Победа
            if gameManager.isLevelComplete {
                victoryOverlay
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            Button {
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
            
            VStack(spacing: 2) {
                Text("УРОВЕНЬ")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                
                Text("\(gameManager.currentLevel)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Сброс
            Button {
                withAnimation(.spring(response: 0.3)) {
                    gameManager.resetLevel()
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(cardColor)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Moves Info
    
    private var movesInfo: some View {
        HStack(spacing: 20) {
            // Ходы
            VStack(spacing: 4) {
                Text("\(gameManager.movesCount)")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("Ходов")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Разделитель
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1, height: 40)
            
            // Цель
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        let threshold = i == 0 ? gameManager.targetMoves + 3 : (i == 1 ? gameManager.targetMoves + 1 : gameManager.targetMoves)
                        let isFilled = gameManager.movesCount <= threshold
                        
                        Image(systemName: isFilled ? "star.fill" : "star")
                            .font(.system(size: 16))
                            .foregroundColor(isFilled ? .yellow : .white.opacity(0.3))
                    }
                }
                Text("≤\(gameManager.targetMoves) для ⭐⭐⭐")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardColor)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Game Grid
    
    private var gameGrid: some View {
        let cellSize: CGFloat = min(70, (UIScreen.main.bounds.width - 80) / CGFloat(gameManager.gridSize))
        
        return VStack(spacing: 8) {
            ForEach(0..<gameManager.gridSize, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0..<gameManager.gridSize, id: \.self) { col in
                        TileView(
                            tile: gameManager.grid[row][col],
                            isAnimating: animatingTiles.contains("\(row)-\(col)"),
                            size: cellSize
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                gameManager.tapTile(row: row, col: col)
                            }
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
    
    // MARK: - Hint
    
    private var hintView: some View {
        HStack(spacing: 12) {
            // Горячее
            HStack(spacing: 6) {
                Circle()
                    .fill(hotColor)
                    .frame(width: 16, height: 16)
                Text("+")
                    .foregroundColor(.white.opacity(0.5))
                Circle()
                    .fill(coldColor)
                    .frame(width: 16, height: 16)
                Text("=")
                    .foregroundColor(.white.opacity(0.5))
                Circle()
                    .fill(Color(red: 0.3, green: 0.3, blue: 0.35))
                    .frame(width: 16, height: 16)
            }
            .font(.system(size: 14, weight: .medium))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(cardColor)
        )
    }
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        EmptyView() // Кнопка сброса уже в topBar
    }
    
    // MARK: - Victory Overlay
    
    private var victoryOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Звёзды
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < gameManager.earnedStars ? "star.fill" : "star")
                            .font(.system(size: 40))
                            .foregroundColor(i < gameManager.earnedStars ? .yellow : .white.opacity(0.3))
                            .scaleEffect(i < gameManager.earnedStars ? 1.0 : 0.8)
                    }
                }
                
                VStack(spacing: 8) {
                    Text("УРОВЕНЬ ПРОЙДЕН!")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Ходов: \(gameManager.movesCount)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                VStack(spacing: 12) {
                    Button {
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
                                colors: [coldColor, hotColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
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
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(red: 0.12, green: 0.1, blue: 0.15))
            )
            .padding(.horizontal, 32)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}

// MARK: - Tile View

struct TileView: View {
    let tile: Tile
    let isAnimating: Bool
    let size: CGFloat
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Фон плитки
                RoundedRectangle(cornerRadius: 12)
                    .fill(tile.color)
                    .shadow(color: tile.color.opacity(0.5), radius: isPressed ? 2 : 6, y: 2)
                
                // Иконка
                if !tile.icon.isEmpty {
                    Image(systemName: tile.icon)
                        .font(.system(size: size * 0.4, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .frame(width: size, height: size)
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(tile == .neutral || tile == .warm || tile == .cool)
        .opacity(tile == .neutral ? 0.5 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
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
