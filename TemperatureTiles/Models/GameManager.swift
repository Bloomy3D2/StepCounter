//
//  GameManager.swift
//  TemperatureTiles
//
//  Менеджер игры
//

import SwiftUI

/// Менеджер игры
final class GameManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Текущий уровень
    @Published var currentLevel: Int = 1
    
    /// Игровое поле
    @Published var grid: [[Tile]] = []
    
    /// Количество ходов
    @Published var movesCount: Int = 0
    
    /// Минимальное количество ходов для 3 звёзд
    @Published var targetMoves: Int = 5
    
    /// Уровень пройден
    @Published var isLevelComplete: Bool = false
    
    /// Заработанные звёзды
    @Published var earnedStars: Int = 0
    
    /// Максимальный уровень
    @Published var maxUnlockedLevel: Int {
        didSet {
            UserDefaults.standard.set(maxUnlockedLevel, forKey: "tempTilesMaxLevel")
        }
    }
    
    /// Общее количество звёзд
    @Published var totalStars: Int {
        didSet {
            UserDefaults.standard.set(totalStars, forKey: "tempTilesTotalStars")
        }
    }
    
    /// Звёзды за уровни
    @Published var levelStars: [Int: Int] = [:] {
        didSet {
            if let data = try? JSONEncoder().encode(levelStars) {
                UserDefaults.standard.set(data, forKey: "tempTilesLevelStars")
            }
        }
    }
    
    /// Размер сетки
    private(set) var gridSize: Int = 4
    
    // MARK: - Initialization
    
    init() {
        self.maxUnlockedLevel = max(1, UserDefaults.standard.integer(forKey: "tempTilesMaxLevel"))
        self.totalStars = UserDefaults.standard.integer(forKey: "tempTilesTotalStars")
        
        if let data = UserDefaults.standard.data(forKey: "tempTilesLevelStars"),
           let stars = try? JSONDecoder().decode([Int: Int].self, from: data) {
            self.levelStars = stars
        }
    }
    
    // MARK: - Public Methods
    
    /// Загрузить уровень
    func loadLevel(_ level: Int) {
        currentLevel = level
        movesCount = 0
        isLevelComplete = false
        earnedStars = 0
        
        generateLevel(level)
    }
    
    /// Генерация уровня
    private func generateLevel(_ level: Int) {
        // Настройка сложности
        switch level {
        case 1...5:
            gridSize = 3
            targetMoves = 3 + level
        case 6...10:
            gridSize = 4
            targetMoves = 5 + (level - 5)
        case 11...20:
            gridSize = 4
            targetMoves = 8 + (level - 10)
        default:
            gridSize = 5
            targetMoves = 12 + (level - 20)
        }
        
        // Генерируем сетку
        grid = generateGrid(for: level)
    }
    
    /// Генерация сетки для уровня
    private func generateGrid(for level: Int) -> [[Tile]] {
        switch level {
        case 1: return level1Grid()
        case 2: return level2Grid()
        case 3: return level3Grid()
        case 4: return level4Grid()
        case 5: return level5Grid()
        case 6: return level6Grid()
        case 7: return level7Grid()
        case 8: return level8Grid()
        case 9: return level9Grid()
        case 10: return level10Grid()
        default: return generateProceduralGrid(level: level)
        }
    }
    
    // MARK: - Уровни
    
    private func level1Grid() -> [[Tile]] {
        // Простой: 1 горячая, 1 холодная рядом
        [
            [.hot, .cold, .neutral],
            [.neutral, .neutral, .neutral],
            [.neutral, .neutral, .neutral]
        ]
    }
    
    private func level2Grid() -> [[Tile]] {
        [
            [.hot, .neutral, .cold],
            [.neutral, .neutral, .neutral],
            [.cold, .neutral, .hot]
        ]
    }
    
    private func level3Grid() -> [[Tile]] {
        [
            [.hot, .hot, .neutral],
            [.neutral, .neutral, .cold],
            [.neutral, .cold, .cold]
        ]
    }
    
    private func level4Grid() -> [[Tile]] {
        [
            [.cold, .neutral, .hot],
            [.neutral, .neutral, .neutral],
            [.hot, .neutral, .cold]
        ]
    }
    
    private func level5Grid() -> [[Tile]] {
        [
            [.hot, .cold, .hot],
            [.cold, .neutral, .cold],
            [.hot, .cold, .hot]
        ]
    }
    
    private func level6Grid() -> [[Tile]] {
        [
            [.hot, .neutral, .neutral, .cold],
            [.neutral, .cold, .hot, .neutral],
            [.neutral, .hot, .cold, .neutral],
            [.cold, .neutral, .neutral, .hot]
        ]
    }
    
    private func level7Grid() -> [[Tile]] {
        [
            [.hot, .hot, .cold, .cold],
            [.neutral, .neutral, .neutral, .neutral],
            [.neutral, .neutral, .neutral, .neutral],
            [.cold, .cold, .hot, .hot]
        ]
    }
    
    private func level8Grid() -> [[Tile]] {
        [
            [.cold, .neutral, .neutral, .hot],
            [.neutral, .hot, .cold, .neutral],
            [.neutral, .cold, .hot, .neutral],
            [.hot, .neutral, .neutral, .cold]
        ]
    }
    
    private func level9Grid() -> [[Tile]] {
        [
            [.hot, .cold, .hot, .cold],
            [.cold, .neutral, .neutral, .hot],
            [.hot, .neutral, .neutral, .cold],
            [.cold, .hot, .cold, .hot]
        ]
    }
    
    private func level10Grid() -> [[Tile]] {
        [
            [.hot, .hot, .hot, .neutral],
            [.cold, .neutral, .neutral, .cold],
            [.cold, .neutral, .neutral, .cold],
            [.neutral, .hot, .hot, .hot]
        ]
    }
    
    private func generateProceduralGrid(level: Int) -> [[Tile]] {
        var grid = Array(repeating: Array(repeating: Tile.neutral, count: gridSize), count: gridSize)
        
        let seed = level * 12345
        var random = SeededRandom(seed: seed)
        
        // Размещаем горячие и холодные плитки
        let pairCount = min(level / 2 + 2, gridSize * gridSize / 3)
        
        for _ in 0..<pairCount {
            // Горячая плитка
            var row = random.next() % gridSize
            var col = random.next() % gridSize
            while grid[row][col] != .neutral {
                row = random.next() % gridSize
                col = random.next() % gridSize
            }
            grid[row][col] = .hot
            
            // Холодная плитка
            row = random.next() % gridSize
            col = random.next() % gridSize
            while grid[row][col] != .neutral {
                row = random.next() % gridSize
                col = random.next() % gridSize
            }
            grid[row][col] = .cold
        }
        
        return grid
    }
    
    // MARK: - Игровая механика
    
    /// Тап на плитку
    func tapTile(row: Int, col: Int) {
        guard row >= 0, row < gridSize, col >= 0, col < gridSize else { return }
        guard !isLevelComplete else { return }
        
        let tile = grid[row][col]
        guard tile != .neutral else { return }
        
        // Активируем плитку
        activateTile(row: row, col: col)
        movesCount += 1
        
        // Хаптик
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Проверяем победу
        checkWinCondition()
    }
    
    /// Активация плитки
    private func activateTile(row: Int, col: Int) {
        let tile = grid[row][col]
        
        // Получаем соседей
        let neighbors = getNeighbors(row: row, col: col)
        
        for (nRow, nCol) in neighbors {
            let neighborTile = grid[nRow][nCol]
            
            if tile == .hot && neighborTile == .cold {
                // Горячая + холодная = обе нейтральные
                grid[row][col] = .neutral
                grid[nRow][nCol] = .neutral
                
                // Эффект
                playMergeEffect()
                return
            } else if tile == .cold && neighborTile == .hot {
                // Холодная + горячая = обе нейтральные
                grid[row][col] = .neutral
                grid[nRow][nCol] = .neutral
                
                playMergeEffect()
                return
            } else if tile == .hot && neighborTile == .neutral {
                // Горячая нагревает нейтральную
                grid[nRow][nCol] = .warm
            } else if tile == .cold && neighborTile == .neutral {
                // Холодная охлаждает нейтральную
                grid[nRow][nCol] = .cool
            } else if tile == .hot && neighborTile == .cool {
                // Горячая + прохладная = нейтральная
                grid[nRow][nCol] = .neutral
            } else if tile == .cold && neighborTile == .warm {
                // Холодная + тёплая = нейтральная
                grid[nRow][nCol] = .neutral
            }
        }
    }
    
    /// Получить соседние ячейки
    private func getNeighbors(row: Int, col: Int) -> [(Int, Int)] {
        var neighbors: [(Int, Int)] = []
        
        if row > 0 { neighbors.append((row - 1, col)) }
        if row < gridSize - 1 { neighbors.append((row + 1, col)) }
        if col > 0 { neighbors.append((row, col - 1)) }
        if col < gridSize - 1 { neighbors.append((row, col + 1)) }
        
        return neighbors
    }
    
    /// Эффект слияния
    private func playMergeEffect() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Проверка победы
    private func checkWinCondition() {
        // Победа: нет горячих и холодных плиток
        let hasExtreme = grid.flatMap { $0 }.contains { $0 == .hot || $0 == .cold }
        
        if !hasExtreme {
            isLevelComplete = true
            earnedStars = calculateStars()
            
            // Обновляем рекорд
            let previousStars = levelStars[currentLevel] ?? 0
            if earnedStars > previousStars {
                totalStars += earnedStars - previousStars
                levelStars[currentLevel] = earnedStars
            }
            
            // Разблокируем следующий уровень
            if currentLevel >= maxUnlockedLevel {
                maxUnlockedLevel = currentLevel + 1
            }
            
            // Хаптик
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    /// Подсчёт звёзд
    private func calculateStars() -> Int {
        if movesCount <= targetMoves {
            return 3
        } else if movesCount <= targetMoves + 2 {
            return 2
        } else {
            return 1
        }
    }
    
    /// Сброс уровня
    func resetLevel() {
        loadLevel(currentLevel)
    }
    
    /// Следующий уровень
    func nextLevel() {
        loadLevel(currentLevel + 1)
    }
    
    /// Общее количество уровней
    var totalLevels: Int { 30 }
}

// MARK: - Tile

/// Типы плиток
enum Tile: Equatable {
    case neutral  // Нейтральная (серая)
    case hot      // Горячая (красная)
    case cold     // Холодная (синяя)
    case warm     // Тёплая (оранжевая)
    case cool     // Прохладная (голубая)
    
    var color: Color {
        switch self {
        case .neutral:
            return Color(red: 0.3, green: 0.3, blue: 0.35)
        case .hot:
            return Color(red: 1.0, green: 0.3, blue: 0.2)
        case .cold:
            return Color(red: 0.2, green: 0.5, blue: 1.0)
        case .warm:
            return Color(red: 1.0, green: 0.6, blue: 0.3)
        case .cool:
            return Color(red: 0.4, green: 0.7, blue: 0.95)
        }
    }
    
    var icon: String {
        switch self {
        case .neutral: return ""
        case .hot: return "flame.fill"
        case .cold: return "snowflake"
        case .warm: return "sun.max.fill"
        case .cool: return "cloud.fill"
        }
    }
    
    var temperature: String {
        switch self {
        case .neutral: return "0°"
        case .hot: return "+100°"
        case .cold: return "-100°"
        case .warm: return "+50°"
        case .cool: return "-50°"
        }
    }
}

// MARK: - Seeded Random

struct SeededRandom {
    private var state: Int
    
    init(seed: Int) {
        self.state = seed
    }
    
    mutating func next() -> Int {
        state = (state &* 1103515245 &+ 12345) & 0x7fffffff
        return abs(state)
    }
}
