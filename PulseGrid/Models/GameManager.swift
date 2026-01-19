//
//  GameManager.swift
//  PulseGrid
//
//  Менеджер игры
//

import SwiftUI
import Combine

/// Менеджер игры
final class GameManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Текущий уровень
    @Published var currentLevel: Int = 1
    
    /// Игровое поле
    @Published var grid: [[PulseCell]] = []
    
    /// Выбранные ячейки
    @Published var selectedCells: [GridPosition] = []
    
    /// Текущая фаза пульса (0.0 - 1.0)
    @Published var globalPulsePhase: Double = 0.0
    
    /// Очки
    @Published var score: Int = 0
    
    /// Комбо множитель
    @Published var combo: Int = 1
    
    /// Уровень пройден
    @Published var isLevelComplete: Bool = false
    
    /// Игра окончена
    @Published var isGameOver: Bool = false
    
    /// Оставшееся время
    @Published var timeRemaining: Double = 60.0
    
    /// Целевое количество очков
    @Published var targetScore: Int = 100
    
    /// Максимальный уровень
    @Published var maxUnlockedLevel: Int {
        didSet {
            UserDefaults.standard.set(maxUnlockedLevel, forKey: "pulseGridMaxLevel")
        }
    }
    
    /// Лучший счёт
    @Published var highScore: Int {
        didSet {
            UserDefaults.standard.set(highScore, forKey: "pulseGridHighScore")
        }
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var pulseTimer: Timer?
    private var gameTimer: Timer?
    
    /// BPM (ударов в минуту) — определяет скорость пульсации
    private var bpm: Double = 90.0
    
    /// Размер сетки
    private var gridSize: Int = 5
    
    // MARK: - Initialization
    
    init() {
        self.maxUnlockedLevel = max(1, UserDefaults.standard.integer(forKey: "pulseGridMaxLevel"))
        self.highScore = UserDefaults.standard.integer(forKey: "pulseGridHighScore")
    }
    
    // MARK: - Public Methods
    
    /// Начать уровень
    func startLevel(_ level: Int) {
        currentLevel = level
        configureLevel(level)
        generateGrid()
        startPulse()
        startGameTimer()
        
        score = 0
        combo = 1
        isLevelComplete = false
        isGameOver = false
        selectedCells = []
    }
    
    /// Конфигурация уровня
    private func configureLevel(_ level: Int) {
        // Увеличиваем сложность с каждым уровнем
        switch level {
        case 1...5:
            gridSize = 4
            bpm = 60 + Double(level) * 5
            timeRemaining = 90
            targetScore = 50 + level * 20
        case 6...10:
            gridSize = 5
            bpm = 80 + Double(level - 5) * 5
            timeRemaining = 75
            targetScore = 150 + (level - 5) * 30
        case 11...15:
            gridSize = 5
            bpm = 100 + Double(level - 10) * 5
            timeRemaining = 60
            targetScore = 300 + (level - 10) * 40
        case 16...20:
            gridSize = 6
            bpm = 120 + Double(level - 15) * 5
            timeRemaining = 50
            targetScore = 500 + (level - 15) * 50
        default:
            gridSize = 6
            bpm = min(160, 140 + Double(level - 20) * 2)
            timeRemaining = 45
            targetScore = 700 + (level - 20) * 60
        }
    }
    
    /// Генерация сетки
    private func generateGrid() {
        let colors: [PulseColor] = [.cyan, .pink, .green, .orange, .purple, .yellow]
        let phaseOffsets: [Double] = [0, 0.25, 0.5, 0.75]
        
        grid = (0..<gridSize).map { row in
            (0..<gridSize).map { col in
                let randomColor = colors.randomElement()!
                let randomPhase = phaseOffsets.randomElement()!
                return PulseCell(
                    color: randomColor,
                    phaseOffset: randomPhase,
                    position: GridPosition(row: row, col: col)
                )
            }
        }
    }
    
    /// Запуск пульсации
    private func startPulse() {
        pulseTimer?.invalidate()
        
        let interval = 60.0 / bpm / 60.0 // Обновление 60 раз в секунду
        pulseTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let beatDuration = 60.0 / self.bpm
            self.globalPulsePhase += interval / beatDuration
            
            if self.globalPulsePhase >= 1.0 {
                self.globalPulsePhase = 0.0
            }
        }
    }
    
    /// Запуск игрового таймера
    private func startGameTimer() {
        gameTimer?.invalidate()
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, !self.isLevelComplete, !self.isGameOver else { return }
            
            self.timeRemaining -= 0.1
            
            if self.timeRemaining <= 0 {
                self.timeRemaining = 0
                if self.score < self.targetScore {
                    self.gameOver()
                } else {
                    self.levelComplete()
                }
            }
        }
    }
    
    /// Выбрать ячейку
    func selectCell(at position: GridPosition) {
        guard position.row >= 0, position.row < gridSize,
              position.col >= 0, position.col < gridSize else { return }
        
        let cell = grid[position.row][position.col]
        
        // Если ячейка уже выбрана — убираем
        if let index = selectedCells.firstIndex(of: position) {
            selectedCells.remove(at: index)
            return
        }
        
        // Если это первая ячейка — добавляем
        if selectedCells.isEmpty {
            selectedCells.append(position)
            return
        }
        
        // Проверяем, соседняя ли ячейка
        guard let lastPosition = selectedCells.last,
              isAdjacent(lastPosition, position) else { return }
        
        // Проверяем совпадение цвета и фазы
        let lastCell = grid[lastPosition.row][lastPosition.col]
        
        if cell.color == lastCell.color && areCellsInSync(cell, lastCell) {
            selectedCells.append(position)
            
            // Проверяем, достаточно ли ячеек для матча
            if selectedCells.count >= 3 {
                processMatch()
            }
        } else {
            // Неправильный выбор — сбрасываем
            selectedCells = [position]
        }
    }
    
    /// Проверка соседства ячеек
    private func isAdjacent(_ pos1: GridPosition, _ pos2: GridPosition) -> Bool {
        let rowDiff = abs(pos1.row - pos2.row)
        let colDiff = abs(pos1.col - pos2.col)
        return (rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1)
    }
    
    /// Проверка синхронизации фаз
    private func areCellsInSync(_ cell1: PulseCell, _ cell2: PulseCell) -> Bool {
        let phase1 = (globalPulsePhase + cell1.phaseOffset).truncatingRemainder(dividingBy: 1.0)
        let phase2 = (globalPulsePhase + cell2.phaseOffset).truncatingRemainder(dividingBy: 1.0)
        
        // Допуск синхронизации (чем меньше, тем сложнее)
        let tolerance = 0.15
        let diff = abs(phase1 - phase2)
        return diff < tolerance || diff > (1.0 - tolerance)
    }
    
    /// Обработка матча
    private func processMatch() {
        let matchCount = selectedCells.count
        let baseScore = matchCount * 10
        let comboBonus = combo
        let totalScore = baseScore * comboBonus
        
        score += totalScore
        combo = min(combo + 1, 10)
        
        // Удаляем совпавшие ячейки и добавляем новые
        for position in selectedCells {
            grid[position.row][position.col].isMatched = true
        }
        
        // Анимация удаления и добавления новых
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refillGrid()
            self?.selectedCells = []
            
            // Проверяем победу
            if let self = self, self.score >= self.targetScore {
                self.levelComplete()
            }
        }
    }
    
    /// Заполнение сетки новыми ячейками
    private func refillGrid() {
        let colors: [PulseColor] = [.cyan, .pink, .green, .orange, .purple, .yellow]
        let phaseOffsets: [Double] = [0, 0.25, 0.5, 0.75]
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if grid[row][col].isMatched {
                    grid[row][col] = PulseCell(
                        color: colors.randomElement()!,
                        phaseOffset: phaseOffsets.randomElement()!,
                        position: GridPosition(row: row, col: col)
                    )
                }
            }
        }
    }
    
    /// Сброс комбо
    func resetCombo() {
        combo = 1
    }
    
    /// Уровень пройден
    private func levelComplete() {
        isLevelComplete = true
        pulseTimer?.invalidate()
        gameTimer?.invalidate()
        
        if currentLevel >= maxUnlockedLevel {
            maxUnlockedLevel = currentLevel + 1
        }
        
        if score > highScore {
            highScore = score
        }
    }
    
    /// Игра окончена
    private func gameOver() {
        isGameOver = true
        pulseTimer?.invalidate()
        gameTimer?.invalidate()
        
        if score > highScore {
            highScore = score
        }
    }
    
    /// Следующий уровень
    func nextLevel() {
        startLevel(currentLevel + 1)
    }
    
    /// Перезапуск уровня
    func restartLevel() {
        startLevel(currentLevel)
    }
    
    /// Остановка игры
    func stopGame() {
        pulseTimer?.invalidate()
        gameTimer?.invalidate()
    }
    
    /// Получить фазу для ячейки
    func getCellPhase(for cell: PulseCell) -> Double {
        return (globalPulsePhase + cell.phaseOffset).truncatingRemainder(dividingBy: 1.0)
    }
    
    /// Проверить, в пике ли фаза
    func isCellAtPeak(_ cell: PulseCell) -> Bool {
        let phase = getCellPhase(for: cell)
        return phase < 0.15 || phase > 0.85
    }
}

// MARK: - Models

/// Позиция на сетке
struct GridPosition: Equatable, Hashable {
    let row: Int
    let col: Int
}

/// Цвета пульсации
enum PulseColor: CaseIterable {
    case cyan, pink, green, orange, purple, yellow
    
    var color: Color {
        switch self {
        case .cyan: return Color(red: 0.4, green: 0.8, blue: 0.95)
        case .pink: return Color(red: 1.0, green: 0.45, blue: 0.5)
        case .green: return Color(red: 0.5, green: 0.9, blue: 0.5)
        case .orange: return Color(red: 1.0, green: 0.7, blue: 0.3)
        case .purple: return Color(red: 0.7, green: 0.5, blue: 0.95)
        case .yellow: return Color(red: 0.95, green: 0.9, blue: 0.4)
        }
    }
}

/// Ячейка с пульсацией
struct PulseCell: Identifiable {
    let id = UUID()
    let color: PulseColor
    let phaseOffset: Double
    let position: GridPosition
    var isMatched: Bool = false
}
