//
//  GameManager.swift
//  NegativeSpace
//
//  Менеджер игры: управление состоянием, уровнями, прогрессом
//

import SwiftUI

/// Основной менеджер игры
final class GameManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Текущий уровень
    @Published var currentLevel: Level?
    
    /// Индекс текущего уровня
    @Published var currentLevelIndex: Int = 0
    
    /// Состояние игрового поля
    @Published var gameBoard: [[CellState]] = []
    
    /// Доступные блоки для размещения
    @Published var availableBlocks: [Block] = []
    
    /// Выбранный блок
    @Published var selectedBlock: Block?
    
    /// Уровень пройден
    @Published var isLevelCompleted: Bool = false
    
    /// Показывать экран победы
    @Published var showVictory: Bool = false
    
    /// Максимальный разблокированный уровень
    @Published var maxUnlockedLevel: Int {
        didSet {
            UserDefaults.standard.set(maxUnlockedLevel, forKey: "maxUnlockedLevel")
        }
    }
    
    /// Количество подсказок
    @Published var hints: Int {
        didSet {
            UserDefaults.standard.set(hints, forKey: "hints")
        }
    }
    
    // MARK: - Новые свойства для усложнения
    
    /// Оставшееся время (секунды)
    @Published var timeRemaining: Double = 0
    
    /// Время для уровня (начальное)
    @Published var levelTime: Double = 0
    
    /// Режим с таймером включён
    @Published var isTimedMode: Bool = true
    
    /// Количество ходов
    @Published var movesCount: Int = 0
    
    /// Заработанные звёзды
    @Published var earnedStars: Int = 0
    
    /// Общее количество звёзд
    @Published var totalStars: Int {
        didSet {
            UserDefaults.standard.set(totalStars, forKey: "totalStars")
        }
    }
    
    /// Звёзды за уровни
    @Published var levelStars: [Int: Int] = [:] {
        didSet {
            if let data = try? JSONEncoder().encode(levelStars) {
                UserDefaults.standard.set(data, forKey: "levelStars")
            }
        }
    }
    
    /// Время вышло
    @Published var isTimeUp: Bool = false
    
    // MARK: - Private Properties
    
    private let levelGenerator = LevelGenerator()
    private var gameTimer: Timer?
    
    // MARK: - Initialization
    
    init() {
        self.maxUnlockedLevel = UserDefaults.standard.integer(forKey: "maxUnlockedLevel")
        self.hints = UserDefaults.standard.object(forKey: "hints") as? Int ?? 3
        self.totalStars = UserDefaults.standard.integer(forKey: "totalStars")
        
        // Загружаем звёзды за уровни
        if let data = UserDefaults.standard.data(forKey: "levelStars"),
           let stars = try? JSONDecoder().decode([Int: Int].self, from: data) {
            self.levelStars = stars
        }
        
        if maxUnlockedLevel == 0 {
            maxUnlockedLevel = 1
        }
    }
    
    // MARK: - Public Methods
    
    /// Загрузить уровень
    func loadLevel(_ index: Int) {
        currentLevelIndex = index
        currentLevel = levelGenerator.generateLevel(number: index)
        
        guard let level = currentLevel else { return }
        
        // Инициализация игрового поля
        gameBoard = level.targetShape.map { row in
            row.map { cell in
                cell ? .empty : .blocked
            }
        }
        
        // Копируем доступные блоки
        availableBlocks = level.blocks
        selectedBlock = nil
        isLevelCompleted = false
        showVictory = false
        isTimeUp = false
        movesCount = 0
        earnedStars = 0
        
        // Настройка времени в зависимости от сложности
        setupTimer(for: level)
    }
    
    /// Настройка таймера
    private func setupTimer(for level: Level) {
        gameTimer?.invalidate()
        
        // Время зависит от сложности и размера уровня
        let cellCount = level.targetShape.flatMap { $0 }.filter { $0 }.count
        let baseTime: Double
        
        switch level.difficulty {
        case .easy:
            baseTime = Double(cellCount) * 5 + 30  // Много времени
        case .medium:
            baseTime = Double(cellCount) * 4 + 20
        case .hard:
            baseTime = Double(cellCount) * 3 + 15
        case .expert:
            baseTime = Double(cellCount) * 2 + 10  // Мало времени
        }
        
        levelTime = baseTime
        timeRemaining = baseTime
        
        // Запуск таймера
        if isTimedMode {
            startTimer()
        }
    }
    
    /// Запуск таймера
    private func startTimer() {
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, !self.isLevelCompleted, !self.isTimeUp else { return }
            
            self.timeRemaining -= 0.1
            
            if self.timeRemaining <= 0 {
                self.timeRemaining = 0
                self.timeUp()
            }
        }
    }
    
    /// Время вышло
    private func timeUp() {
        isTimeUp = true
        gameTimer?.invalidate()
        
        // Хаптик
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    /// Остановить таймер
    func stopTimer() {
        gameTimer?.invalidate()
    }
    
    /// Переключить режим таймера
    func toggleTimedMode() {
        isTimedMode.toggle()
        if !isTimedMode {
            gameTimer?.invalidate()
        } else if !isLevelCompleted && !isTimeUp {
            startTimer()
        }
    }
    
    /// Выбрать блок
    func selectBlock(_ block: Block) {
        if selectedBlock?.id == block.id {
            selectedBlock = nil
        } else {
            selectedBlock = block
        }
        
        // Хаптик
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Повернуть выбранный блок на 90°
    func rotateSelectedBlock() {
        guard let block = selectedBlock,
              let index = availableBlocks.firstIndex(where: { $0.id == block.id }) else { return }
        
        let rotatedShape = rotateShape(block.shape)
        let rotatedBlock = Block(shape: rotatedShape, color: block.color)
        
        availableBlocks[index] = rotatedBlock
        selectedBlock = rotatedBlock
        
        // Хаптик
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Поворот матрицы на 90° по часовой стрелке
    private func rotateShape(_ shape: [[Bool]]) -> [[Bool]] {
        let rows = shape.count
        let cols = shape.first?.count ?? 0
        
        var rotated = Array(repeating: Array(repeating: false, count: rows), count: cols)
        
        for row in 0..<rows {
            for col in 0..<cols {
                rotated[col][rows - 1 - row] = shape[row][col]
            }
        }
        
        return rotated
    }
    
    /// Попробовать разместить блок на поле
    func placeBlock(at row: Int, col: Int) {
        guard let block = selectedBlock else { return }
        
        // Проверяем, можно ли разместить блок
        if canPlaceBlock(block, at: row, col: col) {
            // Размещаем блок
            for (rowOffset, blockRow) in block.shape.enumerated() {
                for (colOffset, cell) in blockRow.enumerated() {
                    if cell {
                        let targetRow = row + rowOffset
                        let targetCol = col + colOffset
                        gameBoard[targetRow][targetCol] = .filled(block.color)
                    }
                }
            }
            
            // Удаляем блок из доступных
            availableBlocks.removeAll { $0.id == block.id }
            selectedBlock = nil
            movesCount += 1
            
            // Хаптик
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // Проверяем победу
            checkWinCondition()
        }
    }
    
    /// Проверить, можно ли разместить блок
    func canPlaceBlock(_ block: Block, at row: Int, col: Int) -> Bool {
        for (rowOffset, blockRow) in block.shape.enumerated() {
            for (colOffset, cell) in blockRow.enumerated() {
                if cell {
                    let targetRow = row + rowOffset
                    let targetCol = col + colOffset
                    
                    // Проверяем границы
                    guard targetRow >= 0, targetRow < gameBoard.count,
                          targetCol >= 0, targetCol < gameBoard[0].count else {
                        return false
                    }
                    
                    // Проверяем, что ячейка пустая
                    if gameBoard[targetRow][targetCol] != .empty {
                        return false
                    }
                }
            }
        }
        return true
    }
    
    /// Проверить условие победы
    private func checkWinCondition() {
        // Победа, если все пустые ячейки заполнены
        let allFilled = gameBoard.allSatisfy { row in
            row.allSatisfy { cell in
                cell != .empty
            }
        }
        
        if allFilled && availableBlocks.isEmpty {
            isLevelCompleted = true
            gameTimer?.invalidate()
            
            // Подсчёт звёзд
            earnedStars = calculateStars()
            
            // Обновляем лучший результат для уровня
            let previousStars = levelStars[currentLevelIndex] ?? 0
            if earnedStars > previousStars {
                let starsDiff = earnedStars - previousStars
                totalStars += starsDiff
                levelStars[currentLevelIndex] = earnedStars
            }
            
            // Разблокируем следующий уровень
            if currentLevelIndex >= maxUnlockedLevel {
                maxUnlockedLevel = currentLevelIndex + 1
            }
            
            // Хаптик победы
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Показываем победу с задержкой
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    self.showVictory = true
                }
            }
        }
    }
    
    /// Подсчёт звёзд
    private func calculateStars() -> Int {
        guard levelTime > 0 else { return 3 }
        
        let timePercent = timeRemaining / levelTime
        
        // 3 звезды: > 60% времени осталось
        // 2 звезды: > 30% времени осталось
        // 1 звезда: прошёл уровень
        
        if timePercent > 0.6 {
            return 3
        } else if timePercent > 0.3 {
            return 2
        } else {
            return 1
        }
    }
    
    /// Сбросить уровень
    func resetLevel() {
        loadLevel(currentLevelIndex)
    }
    
    /// Следующий уровень
    func nextLevel() {
        loadLevel(currentLevelIndex + 1)
    }
    
    /// Использовать подсказку
    func useHint() {
        guard hints > 0, let block = availableBlocks.first else { return }
        
        // Находим правильное место для первого блока
        if let position = findCorrectPosition(for: block) {
            hints -= 1
            selectedBlock = block
            placeBlock(at: position.row, col: position.col)
        }
    }
    
    /// Найти правильную позицию для блока
    private func findCorrectPosition(for block: Block) -> (row: Int, col: Int)? {
        for row in 0..<gameBoard.count {
            for col in 0..<gameBoard[0].count {
                if canPlaceBlock(block, at: row, col: col) {
                    return (row, col)
                }
            }
        }
        return nil
    }
    
    /// Добавить подсказки (после просмотра рекламы)
    func addHints(_ count: Int) {
        hints += count
    }
}

// MARK: - Cell State

/// Состояние ячейки на поле
enum CellState: Equatable {
    case empty           // Пустая ячейка (нужно заполнить)
    case blocked         // Заблокированная ячейка (вне формы)
    case filled(Color)   // Заполненная блоком
    
    var color: Color {
        switch self {
        case .empty:
            return .clear
        case .blocked:
            return .clear
        case .filled(let color):
            return color
        }
    }
}
