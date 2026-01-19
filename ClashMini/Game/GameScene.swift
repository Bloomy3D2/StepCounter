//
//  GameScene.swift
//  ClashMini
//
//  Красивая игровая сцена SpriteKit
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    // MARK: - Properties
    
    weak var gameModel: GameModel?
    
    // Башни
    private var playerKingTower: TowerNode!
    private var playerLeftTower: TowerNode!
    private var playerRightTower: TowerNode!
    private var enemyKingTower: TowerNode!
    private var enemyLeftTower: TowerNode!
    private var enemyRightTower: TowerNode!
    
    // Юниты
    private var playerUnits: [UnitNode] = []
    private var enemyUnits: [UnitNode] = []
    
    // Поле боя
    private var arenaNode: SKNode!
    
    // Зона размещения
    private var placementZone: SKShapeNode?
    private var selectedCard: Card?
    
    // ИИ
    private var lastAIActionTime: TimeInterval = 0
    private var aiActionInterval: TimeInterval = 3.0
    
    // Время
    private var lastUpdateTime: TimeInterval = 0
    
    // Цвета
    private let grassLight = SKColor(red: 0.25, green: 0.55, blue: 0.25, alpha: 1)
    private let grassDark = SKColor(red: 0.2, green: 0.48, blue: 0.2, alpha: 1)
    private let riverColor = SKColor(red: 0.2, green: 0.55, blue: 0.85, alpha: 1)
    private let bridgeColor = SKColor(red: 0.55, green: 0.4, blue: 0.25, alpha: 1)
    
    // MARK: - Scene Setup
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.15, green: 0.35, blue: 0.15, alpha: 1)
        setupArena()
        setupTowers()
        setupDecorations()
    }
    
    private func setupArena() {
        arenaNode = SKNode()
        arenaNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(arenaNode)
        
        // Красивый травяной фон с паттерном
        createGrassPattern()
        
        // Красивая река
        createRiver()
        
        // Мосты
        createBridges()
        
        // Зоны игроков
        createPlayerZones()
    }
    
    private func createGrassPattern() {
        let tileSize: CGFloat = 35
        let tilesX = Int(size.width / tileSize) + 2
        let tilesY = Int(size.height / tileSize) + 2
        
        for x in 0..<tilesX {
            for y in 0..<tilesY {
                let isLight = (x + y) % 2 == 0
                let baseColor = isLight ? grassLight : grassDark
                
                // Добавляем случайную вариацию цвета
                let variation = CGFloat.random(in: -0.02...0.02)
                let color = SKColor(
                    red: baseColor.redComponent + variation,
                    green: baseColor.greenComponent + variation,
                    blue: baseColor.blueComponent,
                    alpha: 1
                )
                
                let tile = SKShapeNode(rectOf: CGSize(width: tileSize, height: tileSize))
                tile.fillColor = color
                tile.strokeColor = .clear
                tile.position = CGPoint(
                    x: CGFloat(x) * tileSize - size.width / 2 + tileSize / 2,
                    y: CGFloat(y) * tileSize - size.height / 2 + tileSize / 2
                )
                tile.zPosition = -20
                arenaNode.addChild(tile)
            }
        }
        
        // Декоративные элементы на траве
        for _ in 0..<30 {
            let decoration = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            decoration.fillColor = SKColor(red: 0.3, green: 0.6, blue: 0.3, alpha: 0.3)
            decoration.strokeColor = .clear
            decoration.position = CGPoint(
                x: CGFloat.random(in: -size.width/2...size.width/2),
                y: CGFloat.random(in: -size.height/2...size.height/2)
            )
            decoration.zPosition = -15
            arenaNode.addChild(decoration)
        }
    }
    
    private func createRiver() {
        let riverWidth = size.width + 40
        let riverHeight: CGFloat = 50
        
        // Основа реки
        let riverPath = CGMutablePath()
        riverPath.addRoundedRect(
            in: CGRect(x: -riverWidth/2, y: -riverHeight/2, width: riverWidth, height: riverHeight),
            cornerWidth: 5,
            cornerHeight: 5
        )
        
        let river = SKShapeNode(path: riverPath)
        river.fillColor = riverColor
        river.strokeColor = SKColor(red: 0.3, green: 0.65, blue: 0.95, alpha: 1)
        river.lineWidth = 3
        river.position = CGPoint(x: 0, y: 0)
        river.zPosition = -10
        arenaNode.addChild(river)
        
        // Анимированные волны
        for i in 0..<8 {
            let wave = SKShapeNode(ellipseOf: CGSize(width: 30, height: 8))
            wave.fillColor = SKColor.white.withAlphaComponent(0.15)
            wave.strokeColor = .clear
            let xPos = CGFloat(i) * (riverWidth / 8) - riverWidth / 2 + 40
            wave.position = CGPoint(x: xPos, y: CGFloat.random(in: -10...10))
            wave.zPosition = -9
            arenaNode.addChild(wave)
            
            // Анимация волн
            let moveRight = SKAction.moveBy(x: 50, y: 0, duration: 2.0)
            let moveLeft = SKAction.moveBy(x: -50, y: 0, duration: 2.0)
            let fadeIn = SKAction.fadeAlpha(to: 0.25, duration: 1.0)
            let fadeOut = SKAction.fadeAlpha(to: 0.1, duration: 1.0)
            
            let sequence = SKAction.sequence([
                SKAction.group([moveRight, fadeIn]),
                SKAction.group([moveLeft, fadeOut])
            ])
            wave.run(SKAction.repeatForever(sequence))
        }
        
        // Берега реки
        for side in [-1, 1] {
            let bank = SKShapeNode(rectOf: CGSize(width: riverWidth, height: 8), cornerRadius: 4)
            bank.fillColor = SKColor(red: 0.4, green: 0.35, blue: 0.2, alpha: 1)
            bank.strokeColor = SKColor(red: 0.3, green: 0.25, blue: 0.15, alpha: 1)
            bank.lineWidth = 1
            bank.position = CGPoint(x: 0, y: CGFloat(side) * (riverHeight / 2 + 2))
            bank.zPosition = -8
            arenaNode.addChild(bank)
        }
    }
    
    private func createBridges() {
        let bridgePositions: [CGFloat] = [-size.width / 4, size.width / 4]
        
        for xPos in bridgePositions {
            createBridge(at: CGPoint(x: xPos, y: 0))
        }
    }
    
    private func createBridge(at position: CGPoint) {
        let bridgeWidth: CGFloat = 70
        let bridgeHeight: CGFloat = 60
        
        // Основание моста
        let bridgeBase = SKShapeNode(rectOf: CGSize(width: bridgeWidth, height: bridgeHeight), cornerRadius: 8)
        bridgeBase.fillColor = bridgeColor
        bridgeBase.strokeColor = SKColor(red: 0.65, green: 0.5, blue: 0.35, alpha: 1)
        bridgeBase.lineWidth = 3
        bridgeBase.position = position
        bridgeBase.zPosition = -5
        arenaNode.addChild(bridgeBase)
        
        // Доски на мосту
        for i in 0..<4 {
            let plank = SKShapeNode(rectOf: CGSize(width: bridgeWidth - 12, height: 10), cornerRadius: 3)
            plank.fillColor = SKColor(red: 0.5, green: 0.35, blue: 0.2, alpha: 1)
            plank.strokeColor = SKColor(red: 0.4, green: 0.28, blue: 0.15, alpha: 0.5)
            plank.lineWidth = 1
            plank.position = CGPoint(
                x: position.x,
                y: position.y + CGFloat(i - 1) * 14 - 7
            )
            plank.zPosition = -4
            arenaNode.addChild(plank)
        }
        
        // Перила моста
        for side in [-1, 1] {
            let rail = SKShapeNode(rectOf: CGSize(width: 6, height: bridgeHeight + 10), cornerRadius: 3)
            rail.fillColor = SKColor(red: 0.45, green: 0.32, blue: 0.18, alpha: 1)
            rail.strokeColor = SKColor(red: 0.35, green: 0.25, blue: 0.12, alpha: 1)
            rail.lineWidth = 2
            rail.position = CGPoint(
                x: position.x + CGFloat(side) * (bridgeWidth / 2 - 3),
                y: position.y
            )
            rail.zPosition = -3
            arenaNode.addChild(rail)
        }
    }
    
    private func createPlayerZones() {
        // Зона игрока (синяя подсветка)
        let playerZonePath = CGMutablePath()
        playerZonePath.addRect(CGRect(
            x: -size.width / 2,
            y: -size.height / 2,
            width: size.width,
            height: size.height / 2 - 30
        ))
        
        let playerZone = SKShapeNode(path: playerZonePath)
        playerZone.fillColor = SKColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 0.05)
        playerZone.strokeColor = .clear
        playerZone.zPosition = -12
        arenaNode.addChild(playerZone)
        
        // Зона противника (красная подсветка)
        let enemyZonePath = CGMutablePath()
        enemyZonePath.addRect(CGRect(
            x: -size.width / 2,
            y: 30,
            width: size.width,
            height: size.height / 2 - 30
        ))
        
        let enemyZone = SKShapeNode(path: enemyZonePath)
        enemyZone.fillColor = SKColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 0.05)
        enemyZone.strokeColor = .clear
        enemyZone.zPosition = -12
        arenaNode.addChild(enemyZone)
    }
    
    private func setupDecorations() {
        // Добавляем деревья и кусты по краям
        let decorations = ["🌳", "🌲", "🌴", "🪨", "🌿"]
        
        // Левый край
        for i in 0..<6 {
            let deco = SKLabelNode(text: decorations.randomElement()!)
            deco.fontSize = CGFloat.random(in: 25...40)
            deco.position = CGPoint(
                x: -size.width / 2 + CGFloat.random(in: 20...50),
                y: CGFloat(i) * (size.height / 6) - size.height / 2 + 50
            )
            deco.zPosition = 100
            deco.alpha = 0.4
            arenaNode.addChild(deco)
        }
        
        // Правый край
        for i in 0..<6 {
            let deco = SKLabelNode(text: decorations.randomElement()!)
            deco.fontSize = CGFloat.random(in: 25...40)
            deco.position = CGPoint(
                x: size.width / 2 - CGFloat.random(in: 20...50),
                y: CGFloat(i) * (size.height / 6) - size.height / 2 + 50
            )
            deco.zPosition = 100
            deco.alpha = 0.4
            arenaNode.addChild(deco)
        }
    }
    
    private func setupTowers() {
        let centerX: CGFloat = 0
        let sideOffset: CGFloat = size.width / 3.2
        
        // Башни игрока (внизу)
        let playerKingY = -size.height / 2 + 110
        let playerPrincessY = -size.height / 2 + 200
        
        playerKingTower = TowerNode(towerType: .king, side: .player)
        playerKingTower.position = CGPoint(x: centerX, y: playerKingY)
        playerKingTower.zPosition = 5
        playerKingTower.onDestroyed = { [weak self] _, _ in
            self?.gameModel?.damageTower(side: .player, tower: .king, damage: 9999)
        }
        arenaNode.addChild(playerKingTower)
        
        playerLeftTower = TowerNode(towerType: .leftPrincess, side: .player)
        playerLeftTower.position = CGPoint(x: -sideOffset, y: playerPrincessY)
        playerLeftTower.zPosition = 5
        playerLeftTower.onDestroyed = { [weak self] _, _ in
            self?.gameModel?.damageTower(side: .player, tower: .leftPrincess, damage: 9999)
        }
        arenaNode.addChild(playerLeftTower)
        
        playerRightTower = TowerNode(towerType: .rightPrincess, side: .player)
        playerRightTower.position = CGPoint(x: sideOffset, y: playerPrincessY)
        playerRightTower.zPosition = 5
        playerRightTower.onDestroyed = { [weak self] _, _ in
            self?.gameModel?.damageTower(side: .player, tower: .rightPrincess, damage: 9999)
        }
        arenaNode.addChild(playerRightTower)
        
        // Башни противника (вверху)
        let enemyKingY = size.height / 2 - 110
        let enemyPrincessY = size.height / 2 - 200
        
        enemyKingTower = TowerNode(towerType: .king, side: .enemy)
        enemyKingTower.position = CGPoint(x: centerX, y: enemyKingY)
        enemyKingTower.zPosition = 5
        enemyKingTower.onDestroyed = { [weak self] _, _ in
            self?.gameModel?.damageTower(side: .enemy, tower: .king, damage: 9999)
        }
        arenaNode.addChild(enemyKingTower)
        
        enemyLeftTower = TowerNode(towerType: .leftPrincess, side: .enemy)
        enemyLeftTower.position = CGPoint(x: -sideOffset, y: enemyPrincessY)
        enemyLeftTower.zPosition = 5
        enemyLeftTower.onDestroyed = { [weak self] _, _ in
            self?.gameModel?.damageTower(side: .enemy, tower: .leftPrincess, damage: 9999)
        }
        arenaNode.addChild(enemyLeftTower)
        
        enemyRightTower = TowerNode(towerType: .rightPrincess, side: .enemy)
        enemyRightTower.position = CGPoint(x: sideOffset, y: enemyPrincessY)
        enemyRightTower.zPosition = 5
        enemyRightTower.onDestroyed = { [weak self] _, _ in
            self?.gameModel?.damageTower(side: .enemy, tower: .rightPrincess, damage: 9999)
        }
        arenaNode.addChild(enemyRightTower)
        
        // Добавляем свечение вокруг башен
        addTowerGlow(to: playerKingTower, color: .blue)
        addTowerGlow(to: enemyKingTower, color: .red)
    }
    
    private func addTowerGlow(to tower: TowerNode, color: SKColor) {
        let glow = SKShapeNode(circleOfRadius: 50)
        glow.fillColor = color.withAlphaComponent(0.1)
        glow.strokeColor = .clear
        glow.zPosition = -1
        tower.addChild(glow)
        
        // Анимация пульсации
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 1.0),
            SKAction.scale(to: 1.0, duration: 1.0)
        ])
        glow.run(SKAction.repeatForever(pulse))
    }
    
    // MARK: - Card Selection
    
    func selectCard(_ card: Card) {
        selectedCard = card
        showPlacementZone()
    }
    
    func deselectCard() {
        selectedCard = nil
        hidePlacementZone()
    }
    
    private func showPlacementZone() {
        hidePlacementZone()
        
        let zoneHeight = size.height / 2 - 100
        let zonePath = CGMutablePath()
        zonePath.addRoundedRect(
            in: CGRect(x: -size.width/2 + 30, y: -size.height/2 + 50, width: size.width - 60, height: zoneHeight),
            cornerWidth: 20,
            cornerHeight: 20
        )
        
        placementZone = SKShapeNode(path: zonePath)
        placementZone?.fillColor = SKColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 0.15)
        placementZone?.strokeColor = SKColor(red: 0.4, green: 1.0, blue: 0.5, alpha: 0.6)
        placementZone?.lineWidth = 4
        placementZone?.glowWidth = 8
        placementZone?.zPosition = 50
        arenaNode.addChild(placementZone!)
        
        // Анимация пульсации
        let pulseAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.7, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        ])
        placementZone?.run(SKAction.repeatForever(pulseAction))
    }
    
    private func hidePlacementZone() {
        placementZone?.removeFromParent()
        placementZone = nil
    }
    
    // MARK: - Unit Spawning
    
    func spawnUnit(card: Card, at position: CGPoint, side: PlayerSide) {
        let unit = UnitNode(cardType: card.type, side: side)
        
        // Конвертируем позицию в координаты арены
        let arenaPosition = CGPoint(
            x: position.x - size.width / 2,
            y: position.y - size.height / 2
        )
        unit.position = arenaPosition
        unit.zPosition = 10
        arenaNode.addChild(unit)
        
        // Эффект появления
        createSpawnEffect(at: arenaPosition, color: side == .player ? .blue : .red)
        
        if side == .player {
            playerUnits.append(unit)
        } else {
            enemyUnits.append(unit)
        }
    }
    
    private func createSpawnEffect(at position: CGPoint, color: SKColor) {
        // Круговая волна
        let ring = SKShapeNode(circleOfRadius: 10)
        ring.fillColor = .clear
        ring.strokeColor = color.withAlphaComponent(0.8)
        ring.lineWidth = 4
        ring.position = position
        ring.zPosition = 9
        arenaNode.addChild(ring)
        
        let expand = SKAction.scale(to: 4, duration: 0.4)
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        ring.run(SKAction.group([expand, fadeOut])) {
            ring.removeFromParent()
        }
        
        // Частицы
        for _ in 0..<8 {
            let particle = SKShapeNode(circleOfRadius: 4)
            particle.fillColor = color.withAlphaComponent(0.7)
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 9
            arenaNode.addChild(particle)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance: CGFloat = 40
            let endPos = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )
            
            let move = SKAction.move(to: endPos, duration: 0.3)
            let fade = SKAction.fadeOut(withDuration: 0.3)
            particle.run(SKAction.group([move, fade])) {
                particle.removeFromParent()
            }
        }
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if let card = selectedCard, let model = gameModel {
            let arenaLocation = CGPoint(x: location.x - size.width / 2, y: location.y - size.height / 2)
            
            // Проверяем, что касание в зоне игрока
            if arenaLocation.y < -30 && arenaLocation.y > -size.height / 2 + 100 {
                if model.canPlayCard(card) {
                    if let playedCard = model.playCard(card) {
                        spawnUnit(card: playedCard, at: location, side: .player)
                        deselectCard()
                    }
                }
            }
        }
    }
    
    // MARK: - Game Loop
    
    override func update(_ currentTime: TimeInterval) {
        guard gameModel?.phase == .playing else { return }
        
        let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        lastUpdateTime = currentTime
        
        updateUnits(currentTime: currentTime, deltaTime: deltaTime)
        updateTowers(currentTime: currentTime)
        updateAI(currentTime: currentTime)
        cleanupDeadUnits()
    }
    
    private func updateUnits(currentTime: TimeInterval, deltaTime: TimeInterval) {
        for unit in playerUnits where unit.state != .dead {
            updateUnit(unit, enemies: enemyUnits, enemyTowers: [enemyLeftTower, enemyRightTower, enemyKingTower].compactMap { $0 }, currentTime: currentTime, deltaTime: deltaTime)
        }
        
        for unit in enemyUnits where unit.state != .dead {
            updateUnit(unit, enemies: playerUnits, enemyTowers: [playerLeftTower, playerRightTower, playerKingTower].compactMap { $0 }, currentTime: currentTime, deltaTime: deltaTime)
        }
    }
    
    private func updateUnit(_ unit: UnitNode, enemies: [UnitNode], enemyTowers: [TowerNode], currentTime: TimeInterval, deltaTime: TimeInterval) {
        var nearestTarget: SKNode?
        var nearestDistance: CGFloat = .infinity
        
        for enemy in enemies where enemy.state != .dead {
            let distance = unit.distanceTo(enemy)
            if distance < nearestDistance {
                nearestDistance = distance
                nearestTarget = enemy
            }
        }
        
        for tower in enemyTowers where !tower.isDestroyed {
            let distance = unit.distanceTo(tower)
            if distance < nearestDistance {
                nearestDistance = distance
                nearestTarget = tower
            }
        }
        
        if let target = nearestTarget {
            if nearestDistance <= unit.attackRange {
                unit.attack(target: target, currentTime: currentTime)
            } else {
                unit.moveToward(target.position, deltaTime: deltaTime)
            }
        } else {
            let targetY: CGFloat = unit.side == .player ? size.height / 2 - 110 : -size.height / 2 + 110
            unit.moveToward(CGPoint(x: 0, y: targetY), deltaTime: deltaTime)
        }
    }
    
    private func updateTowers(currentTime: TimeInterval) {
        for tower in [playerKingTower, playerLeftTower, playerRightTower].compactMap({ $0 }) where !tower.isDestroyed {
            if let target = findNearestEnemy(to: tower, from: enemyUnits) {
                tower.attack(target: target, currentTime: currentTime)
            }
        }
        
        for tower in [enemyKingTower, enemyLeftTower, enemyRightTower].compactMap({ $0 }) where !tower.isDestroyed {
            if let target = findNearestEnemy(to: tower, from: playerUnits) {
                tower.attack(target: target, currentTime: currentTime)
            }
        }
    }
    
    private func findNearestEnemy(to tower: TowerNode, from units: [UnitNode]) -> UnitNode? {
        var nearest: UnitNode?
        var nearestDistance: CGFloat = tower.attackRange
        
        for unit in units where unit.state != .dead {
            let distance = tower.distanceTo(unit)
            if distance < nearestDistance {
                nearestDistance = distance
                nearest = unit
            }
        }
        
        return nearest
    }
    
    private func cleanupDeadUnits() {
        playerUnits.removeAll { $0.state == .dead || $0.parent == nil }
        enemyUnits.removeAll { $0.state == .dead || $0.parent == nil }
    }
    
    // MARK: - AI
    
    private func updateAI(currentTime: TimeInterval) {
        guard currentTime - lastAIActionTime >= aiActionInterval else { return }
        guard let model = gameModel else { return }
        
        let availableCards = CardType.allCases.filter { Double($0.elixirCost) <= model.enemyElixir }
        guard let cardType = availableCards.randomElement() else { return }
        
        model.enemyElixir -= Double(cardType.elixirCost)
        
        let randomX = CGFloat.random(in: -size.width / 3.5...size.width / 3.5)
        let spawnY = size.height / 2 + size.height / 4 - 50
        
        let card = Card(type: cardType)
        spawnUnit(card: card, at: CGPoint(x: randomX + size.width / 2, y: spawnY), side: .enemy)
        
        lastAIActionTime = currentTime
        aiActionInterval = TimeInterval.random(in: 2.0...4.5)
    }
    
    // MARK: - Reset
    
    func resetGame() {
        playerUnits.forEach { $0.removeFromParent() }
        enemyUnits.forEach { $0.removeFromParent() }
        playerUnits.removeAll()
        enemyUnits.removeAll()
        
        [playerKingTower, playerLeftTower, playerRightTower, enemyKingTower, enemyLeftTower, enemyRightTower].forEach {
            $0?.removeFromParent()
        }
        setupTowers()
        
        lastUpdateTime = 0
        lastAIActionTime = 0
        selectedCard = nil
        hidePlacementZone()
    }
}

// MARK: - SKColor Extension

extension SKColor {
    var redComponent: CGFloat {
        var r: CGFloat = 0
        getRed(&r, green: nil, blue: nil, alpha: nil)
        return r
    }
    
    var greenComponent: CGFloat {
        var g: CGFloat = 0
        getRed(nil, green: &g, blue: nil, alpha: nil)
        return g
    }
    
    var blueComponent: CGFloat {
        var b: CGFloat = 0
        getRed(nil, green: nil, blue: &b, alpha: nil)
        return b
    }
}
