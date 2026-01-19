//
//  ContentView.swift
//  TicTacToe
//
//  Главный экран игры
//

import SwiftUI

struct ContentView: View {
    @StateObject private var gameState = GameState()
    @State private var showResetAlert = false
    
    // Цветовая палитра
    private let backgroundColor = Color(red: 0.07, green: 0.07, blue: 0.12)
    private let cardColor = Color(red: 0.12, green: 0.12, blue: 0.18)
    private let accentX = Color(red: 0.4, green: 0.8, blue: 0.95) // Голубой для X
    private let accentO = Color(red: 1.0, green: 0.45, blue: 0.5) // Розовый для O
    private let textColor = Color.white
    
    var body: some View {
        ZStack {
            // Градиентный фон
            LinearGradient(
                colors: [
                    backgroundColor,
                    Color(red: 0.1, green: 0.08, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Декоративные круги на фоне
            GeometryReader { geometry in
                Circle()
                    .fill(accentX.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -100, y: -50)
                
                Circle()
                    .fill(accentO.opacity(0.1))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: geometry.size.width - 100, y: geometry.size.height - 200)
            }
            
            VStack(spacing: 30) {
                // Заголовок
                headerView
                
                // Счёт
                scoreView
                
                // Статус игры
                statusView
                
                // Игровое поле
                gameBoard
                
                // Кнопки управления
                controlButtons
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .alert("Сбросить счёт?", isPresented: $showResetAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Сбросить", role: .destructive) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    gameState.resetScore()
                }
            }
        } message: {
            Text("Счёт обоих игроков будет обнулён")
        }
    }
    
    // MARK: - Заголовок
    
    private var headerView: some View {
        HStack(spacing: 4) {
            Text("КРЕСТИКИ")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(accentX)
            
            Text("×")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(textColor.opacity(0.5))
            
            Text("НОЛИКИ")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(accentO)
        }
    }
    
    // MARK: - Счёт
    
    private var scoreView: some View {
        HStack(spacing: 20) {
            // Игрок X
            VStack(spacing: 8) {
                Text("X")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(accentX)
                
                Text("\(gameState.scoreX)")
                    .font(.system(size: 48, weight: .black, design: .monospaced))
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                gameState.currentPlayer == .x && gameState.result == .ongoing
                                    ? accentX.opacity(0.5)
                                    : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
            
            // Разделитель
            Text(":")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(textColor.opacity(0.3))
            
            // Игрок O
            VStack(spacing: 8) {
                Text("O")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(accentO)
                
                Text("\(gameState.scoreO)")
                    .font(.system(size: 48, weight: .black, design: .monospaced))
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                gameState.currentPlayer == .o && gameState.result == .ongoing
                                    ? accentO.opacity(0.5)
                                    : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
    }
    
    // MARK: - Статус игры
    
    private var statusView: some View {
        Group {
            switch gameState.result {
            case .ongoing:
                HStack(spacing: 8) {
                    Text("Ход:")
                        .foregroundColor(textColor.opacity(0.7))
                    
                    Text(gameState.currentPlayer.rawValue)
                        .foregroundColor(gameState.currentPlayer == .x ? accentX : accentO)
                        .fontWeight(.bold)
                }
                
            case .win(let player):
                HStack(spacing: 8) {
                    Text("🎉")
                    Text("Победил \(player.rawValue)!")
                        .foregroundColor(player == .x ? accentX : accentO)
                        .fontWeight(.bold)
                    Text("🎉")
                }
                
            case .draw:
                Text("🤝 Ничья! 🤝")
                    .foregroundColor(textColor.opacity(0.8))
            }
        }
        .font(.system(size: 22, weight: .semibold, design: .rounded))
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .background(
            Capsule()
                .fill(cardColor)
        )
    }
    
    // MARK: - Игровое поле
    
    private var gameBoard: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { col in
                        CellView(
                            state: gameState.board[row][col],
                            isWinning: gameState.isWinningCell(row: row, col: col),
                            accentX: accentX,
                            accentO: accentO,
                            cardColor: cardColor
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                gameState.makeMove(row: row, col: col)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardColor.opacity(0.5))
        )
    }
    
    // MARK: - Кнопки управления
    
    private var controlButtons: some View {
        HStack(spacing: 16) {
            // Новая игра
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    gameState.resetGame()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Новая игра")
                }
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(textColor)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [accentX.opacity(0.8), accentX.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            }
            
            // Сброс счёта
            Button {
                showResetAlert = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                    Text("Сброс")
                }
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(textColor.opacity(0.8))
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(cardColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(textColor.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
    }
}

// MARK: - Ячейка игрового поля

struct CellView: View {
    let state: CellState
    let isWinning: Bool
    let accentX: Color
    let accentO: Color
    let cardColor: Color
    let action: () -> Void
    
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(cellBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(cellBorder, lineWidth: isWinning ? 3 : 1)
                    )
                
                Text(state.symbol)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(symbolColor)
                    .scaleEffect(scale)
            }
            .frame(width: 95, height: 95)
        }
        .buttonStyle(CellButtonStyle())
        .onChange(of: state) { oldValue, newValue in
            if newValue != .empty {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.2
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.1)) {
                    scale = 1.0
                }
            }
        }
    }
    
    private var cellBackground: AnyShapeStyle {
        if isWinning {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [symbolColor.opacity(0.3), symbolColor.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            return AnyShapeStyle(Color(red: 0.15, green: 0.15, blue: 0.22))
        }
    }
    
    private var cellBorder: Color {
        if isWinning {
            return symbolColor
        }
        return Color.white.opacity(0.1)
    }
    
    private var symbolColor: Color {
        switch state {
        case .empty:
            return .clear
        case .filled(let player):
            return player == .x ? accentX : accentO
        }
    }
}

// MARK: - Стиль кнопки ячейки

struct CellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
