//
//  GameState.swift
//  TicTacToe
//
//  Модель состояния игры
//

import Foundation

/// Игрок: X или O
enum Player: String {
    case x = "X"
    case o = "O"
    
    var next: Player {
        self == .x ? .o : .x
    }
}

/// Состояние ячейки на поле
enum CellState: Equatable {
    case empty
    case filled(Player)
    
    var symbol: String {
        switch self {
        case .empty:
            return ""
        case .filled(let player):
            return player.rawValue
        }
    }
}

/// Результат игры
enum GameResult: Equatable {
    case ongoing
    case win(Player)
    case draw
}

/// Основная модель игры
final class GameState: ObservableObject {
    
    /// Игровое поле 3x3
    @Published private(set) var board: [[CellState]]
    
    /// Текущий игрок
    @Published private(set) var currentPlayer: Player
    
    /// Результат игры
    @Published private(set) var result: GameResult
    
    /// Счёт игроков
    @Published private(set) var scoreX: Int = 0
    @Published private(set) var scoreO: Int = 0
    
    /// Выигрышная комбинация (для подсветки)
    @Published private(set) var winningCells: [(row: Int, col: Int)] = []
    
    init() {
        self.board = Array(repeating: Array(repeating: .empty, count: 3), count: 3)
        self.currentPlayer = .x
        self.result = .ongoing
    }
    
    /// Сделать ход в ячейку
    func makeMove(row: Int, col: Int) {
        guard result == .ongoing else { return }
        guard board[row][col] == .empty else { return }
        
        board[row][col] = .filled(currentPlayer)
        
        if let winningLine = checkWin(for: currentPlayer) {
            winningCells = winningLine
            result = .win(currentPlayer)
            updateScore(winner: currentPlayer)
        } else if isBoardFull() {
            result = .draw
        } else {
            currentPlayer = currentPlayer.next
        }
    }
    
    /// Проверка победы
    private func checkWin(for player: Player) -> [(row: Int, col: Int)]? {
        let target = CellState.filled(player)
        
        // Проверка строк
        for row in 0..<3 {
            if board[row].allSatisfy({ $0 == target }) {
                return [(row, 0), (row, 1), (row, 2)]
            }
        }
        
        // Проверка столбцов
        for col in 0..<3 {
            if board[0][col] == target && board[1][col] == target && board[2][col] == target {
                return [(0, col), (1, col), (2, col)]
            }
        }
        
        // Проверка диагоналей
        if board[0][0] == target && board[1][1] == target && board[2][2] == target {
            return [(0, 0), (1, 1), (2, 2)]
        }
        
        if board[0][2] == target && board[1][1] == target && board[2][0] == target {
            return [(0, 2), (1, 1), (2, 0)]
        }
        
        return nil
    }
    
    /// Проверка заполненности поля
    private func isBoardFull() -> Bool {
        board.allSatisfy { row in
            row.allSatisfy { $0 != .empty }
        }
    }
    
    /// Обновление счёта
    private func updateScore(winner: Player) {
        switch winner {
        case .x:
            scoreX += 1
        case .o:
            scoreO += 1
        }
    }
    
    /// Начать новую игру
    func resetGame() {
        board = Array(repeating: Array(repeating: .empty, count: 3), count: 3)
        currentPlayer = .x
        result = .ongoing
        winningCells = []
    }
    
    /// Сбросить счёт
    func resetScore() {
        scoreX = 0
        scoreO = 0
        resetGame()
    }
    
    /// Проверка, является ли ячейка выигрышной
    func isWinningCell(row: Int, col: Int) -> Bool {
        winningCells.contains { $0.row == row && $0.col == col }
    }
}
