//
//  GameManager.swift
//  OrbitMatch
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
    
    /// Орбиты с шариками
    @Published var orbits: [Orbit] = []
    
    /// Текущий угол вращения (в радианах)
    @Published var rotationAngle: Double = 0
    
    /// Очки
    @Published var score: Int = 0
    
    /// Целевые очки
    @Published var targetScore: Int = 100
    
    /// Оставшееся время
    @Published var timeRemaining: Double = 60
    
    /// Уровень пройден
    @Published var isLevelComplete: Bool = false
    
    /// Игра окончена
    @Published var isGameOver: Bool = false
    
    /// Последний матч (для анимации)
    @Published var lastMatchPositions: [CGPoint] = []
    
    /// Комбо
    @Published var combo: Int = 1
    
    /// Максимальный уровень
    @Published var maxUnlockedLevel: Int {
        didSet {
            UserDefaults.standard.set(maxUnlockedLevel, forKey: "orbitMatchMaxLevel")
        }
    }
    
    /// Рекорд
    @Published var highScore: Int {
        didSet {
            UserDefaults.standard.set(highScore, forKey: "orbitMatchHighScore")
        }
    }
    
    // MARK: - Private Properties
    
    private var rotationTimer: Timer?
    private var gameTimer: Timer?
    private var rotationSpeed: Double = 0.02
    
    // MARK: - Initialization
    
    init() {
        self.maxUnlockedLevel = max(1, UserDefaults.standard.integer(forKey: "orbitMatchMaxLevel"))
        self.highScore = UserDefaults.standard.integer(forKey: "orbitMatchHighScore")
    }
    
    // MARK: - Public Methods
    
    /// Начать уровень
    func startLevel(_ level: Int) {
        currentLevel = level
        configureLevel(level)
        generateOrbits()
        startRotation()
        startGameTimer()
        
        score = 0
        combo = 1
        isLevelComplete = false
        isGameOver = false
        lastMatchPositions = []
    }
    
    /// Конфигурация уровня
    private func configureLevel(_ level: Int) {
        switch level {
        case 1...5:
            rotationSpeed = 0.015 + Double(level) * 0.002
            timeRemaining = 90
            targetScore = 50 + level * 15
        case 6...10:
            rotationSpeed = 0.025 + Double(level - 5) * 0.003
            timeRemaining = 75
            targetScore = 120 + (level - 5) * 25
        case 11...15:
            rotationSpeed = 0.04 + Double(level - 10) * 0.003
            timeRemaining = 60
            targetScore = 250 + (level - 10) * 35
        case 16...20:
            rotationSpeed = 0.055 + Double(level - 15) * 0.004
            timeRemaining = 50
            targetScore = 400 + (level - 15) * 50
        default:
            rotationSpeed = min(0.1, 0.075 + Double(level - 20) * 0.002)
            timeRemaining = 45
            targetScore = 650 + (level - 20) * 60
        }
    }
    
    /// Генерация орбит
    private func generateOrbits() {
        let colors: [OrbColor] = [.cyan, .pink, .green, .orange, .purple, .yellow]
        let orbitCount = min(3 + currentLevel / 5, 5)
        
        orbits = (0..<orbitCount).map { orbitIndex in
            let ballCount = 4 + (orbitIndex % 2)
            let radius = 60.0 + Double(orbitIndex) * 50.0
            let speedMultiplier = orbitIndex % 2 == 0 ? 1.0 : -1.0 // Чередование направления
            
            let balls = (0..<ballCount).map { ballIndex in
                let angle = (Double(ballIndex) / Double(ballCount)) * 2 * .pi
                let color = colors.randomElement()!
                return OrbBall(
                    color: color,
                    baseAngle: angle,
                    orbitIndex: orbitIndex,
                    ballIndex: ballIndex
                )
            }
            
            return Orbit(
                radius: radius,
                balls: balls,
                speedMultiplier: speedMultiplier
            )
        }
    }
    
    /// Запуск вращения
    private func startRotation() {
        rotationTimer?.invalidate()
        
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { [weak self] _ in
            guard let self = self, !self.isLevelComplete, !self.isGameOver else { return }
            self.rotationAngle += self.rotationSpeed
        }
    }
    
    /// Запуск таймера игры
    private func startGameTimer() {
        gameTimer?.invalidate()
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, !self.isLevelComplete, !self.isGameOver else { return }
            
            self.timeRemaining -= 0.1
            
            if self.timeRemaining <= 0 {
                self.timeRemaining = 0
                if self.score >= self.targetScore {
                    self.levelComplete()
                } else {
                    self.gameOver()
                }
            }
        }
    }
    
    /// Тап для сбора выстроенных шариков
    func tapToMatch() {
        let matchedBalls = findAlignedBalls()
        
        if matchedBalls.count >= 3 {
            // Успешный матч!
            let basePoints = matchedBalls.count * 15
            let comboMultiplier = combo
            score += basePoints * comboMultiplier
            combo = min(combo + 1, 10)
            
            // Удаляем совпавшие шарики
            removeBalls(matchedBalls)
            
            // Добавляем новые
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.respawnBalls()
            }
            
            // Проверяем победу
            if score >= targetScore {
                levelComplete()
            }
            
            // Хаптик
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } else {
            // Промах — сбрасываем комбо
            combo = 1
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    /// Поиск выстроенных шариков (по вертикали от центра)
    private func findAlignedBalls() -> [(orbitIndex: Int, ballIndex: Int, color: OrbColor)] {
        var aligned: [(orbitIndex: Int, ballIndex: Int, color: OrbColor)] = []
        
        // Угол "прицела" — вертикаль вверх (90 градусов)
        let targetAngle = -Double.pi / 2
        let tolerance = 0.25 // Допуск в радианах
        
        for (orbitIndex, orbit) in orbits.enumerated() {
            for (ballIndex, ball) in orbit.balls.enumerated() {
                let currentAngle = normalizeAngle(ball.baseAngle + rotationAngle * orbit.speedMultiplier)
                let diff = abs(normalizeAngle(currentAngle - targetAngle))
                
                if diff < tolerance || diff > (2 * .pi - tolerance) {
                    aligned.append((orbitIndex, ballIndex, ball.color))
                }
            }
        }
        
        // Проверяем, что все одного цвета
        if aligned.count >= 3 {
            let colors = aligned.map { $0.color }
            let firstColor = colors[0]
            if colors.allSatisfy({ $0 == firstColor }) {
                return aligned
            }
        }
        
        return []
    }
    
    /// Нормализация угла в диапазон [0, 2π]
    private func normalizeAngle(_ angle: Double) -> Double {
        var normalized = angle.truncatingRemainder(dividingBy: 2 * .pi)
        if normalized < 0 { normalized += 2 * .pi }
        return normalized
    }
    
    /// Удаление шариков
    private func removeBalls(_ balls: [(orbitIndex: Int, ballIndex: Int, color: OrbColor)]) {
        for ball in balls {
            if ball.orbitIndex < orbits.count {
                orbits[ball.orbitIndex].balls[ball.ballIndex].isMatched = true
            }
        }
    }
    
    /// Добавление новых шариков
    private func respawnBalls() {
        let colors: [OrbColor] = [.cyan, .pink, .green, .orange, .purple, .yellow]
        
        for orbitIndex in 0..<orbits.count {
            for ballIndex in 0..<orbits[orbitIndex].balls.count {
                if orbits[orbitIndex].balls[ballIndex].isMatched {
                    let newColor = colors.randomElement()!
                    orbits[orbitIndex].balls[ballIndex] = OrbBall(
                        color: newColor,
                        baseAngle: orbits[orbitIndex].balls[ballIndex].baseAngle,
                        orbitIndex: orbitIndex,
                        ballIndex: ballIndex
                    )
                }
            }
        }
    }
    
    /// Уровень пройден
    private func levelComplete() {
        isLevelComplete = true
        rotationTimer?.invalidate()
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
        rotationTimer?.invalidate()
        gameTimer?.invalidate()
        
        if score > highScore {
            highScore = score
        }
    }
    
    /// Следующий уровень
    func nextLevel() {
        startLevel(currentLevel + 1)
    }
    
    /// Перезапуск
    func restartLevel() {
        startLevel(currentLevel)
    }
    
    /// Остановка
    func stopGame() {
        rotationTimer?.invalidate()
        gameTimer?.invalidate()
    }
    
    /// Получить текущий угол шарика
    func getCurrentAngle(for ball: OrbBall, orbit: Orbit) -> Double {
        return ball.baseAngle + rotationAngle * orbit.speedMultiplier
    }
    
    /// Проверить, находится ли шарик в зоне прицела
    func isBallInTargetZone(_ ball: OrbBall, orbit: Orbit) -> Bool {
        let currentAngle = normalizeAngle(getCurrentAngle(for: ball, orbit: orbit))
        let targetAngle = -Double.pi / 2 + 2 * .pi // Нормализованный угол вверх
        let normalizedTarget = normalizeAngle(targetAngle)
        let diff = abs(currentAngle - normalizedTarget)
        return diff < 0.3 || diff > (2 * .pi - 0.3)
    }
}

// MARK: - Models

/// Цвета шариков
enum OrbColor: CaseIterable {
    case cyan, pink, green, orange, purple, yellow
    
    var color: Color {
        switch self {
        case .cyan: return Color(red: 0.4, green: 0.85, blue: 0.95)
        case .pink: return Color(red: 1.0, green: 0.45, blue: 0.55)
        case .green: return Color(red: 0.5, green: 0.9, blue: 0.55)
        case .orange: return Color(red: 1.0, green: 0.7, blue: 0.35)
        case .purple: return Color(red: 0.7, green: 0.5, blue: 0.95)
        case .yellow: return Color(red: 0.95, green: 0.9, blue: 0.45)
        }
    }
}

/// Орбита
struct Orbit: Identifiable {
    let id = UUID()
    let radius: Double
    var balls: [OrbBall]
    let speedMultiplier: Double // 1.0 или -1.0 для направления
}

/// Шарик на орбите
struct OrbBall: Identifiable {
    let id = UUID()
    let color: OrbColor
    let baseAngle: Double
    let orbitIndex: Int
    let ballIndex: Int
    var isMatched: Bool = false
}
