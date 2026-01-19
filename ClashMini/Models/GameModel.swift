//
//  GameModel.swift
//  ClashMini
//
//  Основная модель игры
//

import Foundation
import Combine

/// Состояние игры
enum GamePhase {
    case menu
    case playing
    case paused
    case victory
    case defeat
}

/// Игрок (наш или противник)
enum PlayerSide {
    case player
    case enemy
}

/// Основная модель состояния игры
final class GameModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var phase: GamePhase = .menu
    @Published var elixir: Double = 5.0
    @Published var enemyElixir: Double = 5.0
    @Published var playerCrowns: Int = 0
    @Published var enemyCrowns: Int = 0
    @Published var timeRemaining: TimeInterval = 180 // 3 минуты
    @Published var playerDeck: Deck
    @Published var isDoubleElixir: Bool = false
    
    // Здоровье башен
    @Published var playerKingHealth: Int = 500
    @Published var playerLeftTowerHealth: Int = 200
    @Published var playerRightTowerHealth: Int = 200
    
    @Published var enemyKingHealth: Int = 500
    @Published var enemyLeftTowerHealth: Int = 200
    @Published var enemyRightTowerHealth: Int = 200
    
    // Активные бустеры для текущей игры
    @Published var activeGameBoosters: Set<BoosterType> = []
    
    // Модификаторы от бустеров
    var damageMultiplier: Double {
        activeGameBoosters.contains(.strongUnits) ? 1.25 : 1.0
    }
    
    var elixirRegenMultiplier: Double {
        activeGameBoosters.contains(.fastElixir) ? 1.5 : 1.0
    }
    
    var kingShieldAmount: Int {
        activeGameBoosters.contains(.shield) ? 100 : 0
    }
    
    @Published var kingShieldRemaining: Int = 0
    
    // MARK: - Constants
    
    static let maxElixir: Double = 10.0
    static let elixirRegenRate: Double = 0.5 // за секунду (обычный режим)
    static let doubleElixirRegenRate: Double = 1.0
    static let doubleElixirTime: TimeInterval = 60 // последняя минута
    
    // MARK: - Private
    
    private var gameTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    init() {
        // Создаём колоду игрока
        self.playerDeck = Deck(cardTypes: [
            .knight, .archer, .giant, .goblin, .wizard, .dragon
        ])
    }
    
    // MARK: - Game Control
    
    func startGame() {
        phase = .playing
        playerCrowns = 0
        enemyCrowns = 0
        timeRemaining = 180
        isDoubleElixir = false
        
        // Применяем активные бустеры из магазина
        activeGameBoosters = ShopManager.shared.activeBoosters
        
        // Начальный эликсир (с бустером или без)
        elixir = activeGameBoosters.contains(.doubleElixir) ? 10.0 : 5.0
        enemyElixir = 5.0
        
        // Здоровье башен (с бустером +50% или без)
        let healthMultiplier = activeGameBoosters.contains(.extraHealth) ? 1.5 : 1.0
        playerKingHealth = Int(500.0 * healthMultiplier)
        playerLeftTowerHealth = Int(200.0 * healthMultiplier)
        playerRightTowerHealth = Int(200.0 * healthMultiplier)
        
        // Щит на главную башню
        kingShieldRemaining = kingShieldAmount
        
        enemyKingHealth = 500
        enemyLeftTowerHealth = 200
        enemyRightTowerHealth = 200
        
        // Перемешиваем колоду
        playerDeck.shuffleAndDraw()
        
        // Деактивируем бустеры после использования
        ShopManager.shared.deactivateAllBoosters()
        
        startTimers()
    }
    
    func pauseGame() {
        phase = .paused
        gameTimer?.invalidate()
    }
    
    func resumeGame() {
        phase = .playing
        startTimers()
    }
    
    func endGame(victory: Bool) {
        phase = victory ? .victory : .defeat
        gameTimer?.invalidate()
        
        // Награды за победу
        if victory {
            ShopManager.shared.rewardForVictory(crowns: playerCrowns)
        }
        
        // Сбрасываем активные бустеры
        activeGameBoosters.removeAll()
    }
    
    func returnToMenu() {
        phase = .menu
        gameTimer?.invalidate()
    }
    
    // MARK: - Elixir
    
    func canPlayCard(_ card: Card) -> Bool {
        return elixir >= Double(card.elixirCost)
    }
    
    func spendElixir(_ amount: Int) {
        elixir = max(0, elixir - Double(amount))
    }
    
    func playCard(_ card: Card) -> Card? {
        guard canPlayCard(card) else { return nil }
        spendElixir(card.elixirCost)
        return playerDeck.playCard(card)
    }
    
    // MARK: - Tower Damage
    
    func damageTower(side: PlayerSide, tower: TowerType, damage: Int) {
        switch (side, tower) {
        case (.player, .king):
            // Проверяем щит на королевской башне
            var actualDamage = damage
            if kingShieldRemaining > 0 {
                let absorbed = min(kingShieldRemaining, damage)
                kingShieldRemaining -= absorbed
                actualDamage = damage - absorbed
            }
            playerKingHealth = max(0, playerKingHealth - actualDamage)
            if playerKingHealth == 0 { checkGameOver() }
            
        case (.player, .leftPrincess):
            playerLeftTowerHealth = max(0, playerLeftTowerHealth - damage)
            if playerLeftTowerHealth == 0 {
                enemyCrowns += 1
                checkGameOver()
            }
            
        case (.player, .rightPrincess):
            playerRightTowerHealth = max(0, playerRightTowerHealth - damage)
            if playerRightTowerHealth == 0 {
                enemyCrowns += 1
                checkGameOver()
            }
            
        case (.enemy, .king):
            enemyKingHealth = max(0, enemyKingHealth - damage)
            if enemyKingHealth == 0 { checkGameOver() }
            
        case (.enemy, .leftPrincess):
            enemyLeftTowerHealth = max(0, enemyLeftTowerHealth - damage)
            if enemyLeftTowerHealth == 0 {
                playerCrowns += 1
                checkGameOver()
            }
            
        case (.enemy, .rightPrincess):
            enemyRightTowerHealth = max(0, enemyRightTowerHealth - damage)
            if enemyRightTowerHealth == 0 {
                playerCrowns += 1
                checkGameOver()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func startTimers() {
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.gameLoop()
        }
    }
    
    private func gameLoop() {
        guard phase == .playing else { return }
        
        // Обновляем время
        timeRemaining -= 0.1
        if timeRemaining <= 0 {
            timeRemaining = 0
            checkGameOver()
            return
        }
        
        // Проверяем режим двойного эликсира
        if timeRemaining <= GameModel.doubleElixirTime && !isDoubleElixir {
            isDoubleElixir = true
        }
        
        // Регенерация эликсира
        let baseRegenRate = isDoubleElixir ? GameModel.doubleElixirRegenRate : GameModel.elixirRegenRate
        let playerRegenRate = baseRegenRate * elixirRegenMultiplier
        elixir = min(GameModel.maxElixir, elixir + playerRegenRate * 0.1)
        enemyElixir = min(GameModel.maxElixir, enemyElixir + baseRegenRate * 0.1)
    }
    
    private func checkGameOver() {
        // Победа если уничтожена королевская башня противника
        if enemyKingHealth <= 0 {
            playerCrowns = 3
            endGame(victory: true)
            return
        }
        
        if playerKingHealth <= 0 {
            enemyCrowns = 3
            endGame(victory: false)
            return
        }
        
        // По истечении времени
        if timeRemaining <= 0 {
            if playerCrowns > enemyCrowns {
                endGame(victory: true)
            } else if enemyCrowns > playerCrowns {
                endGame(victory: false)
            } else {
                // Ничья — побеждает тот, у кого больше здоровья башен
                let playerTotal = playerKingHealth + playerLeftTowerHealth + playerRightTowerHealth
                let enemyTotal = enemyKingHealth + enemyLeftTowerHealth + enemyRightTowerHealth
                endGame(victory: playerTotal >= enemyTotal)
            }
        }
    }
}

/// Тип башни
enum TowerType {
    case king
    case leftPrincess
    case rightPrincess
}
