//
//  Tower.swift
//  ClashMini
//
//  Красивые детализированные башни
//

import Foundation
import SpriteKit

/// Узел башни с профессиональной графикой
class TowerNode: SKNode {
    
    // MARK: - Properties
    
    let towerType: TowerType
    let side: PlayerSide
    
    var health: Int
    var maxHealth: Int
    var damage: Int = 20
    var attackRange: CGFloat = 150
    var attackSpeed: TimeInterval = 1.0
    var lastAttackTime: TimeInterval = 0
    var isDestroyed: Bool = false
    
    // MARK: - Visual Components
    
    private var towerNode: SKNode!
    private var cannonNode: SKNode?
    private var crownNode: SKNode?
    private var healthBarBg: SKShapeNode!
    private var healthBarFill: SKShapeNode!
    private var glowNode: SKShapeNode?
    private var flagNode: SKNode?
    
    // MARK: - Callbacks
    
    var onDestroyed: ((TowerType, PlayerSide) -> Void)?
    
    // MARK: - Init
    
    init(towerType: TowerType, side: PlayerSide) {
        self.towerType = towerType
        self.side = side
        
        switch towerType {
        case .king:
            self.health = 500
            self.maxHealth = 500
            self.damage = 30
            self.attackRange = 180
        case .leftPrincess, .rightPrincess:
            self.health = 200
            self.maxHealth = 200
            self.damage = 20
            self.attackRange = 150
        }
        
        super.init()
        setupTower()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Tower Setup
    
    private func setupTower() {
        towerNode = SKNode()
        addChild(towerNode)
        
        if towerType == .king {
            createKingTower()
        } else {
            createPrincessTower()
        }
        
        createHealthBar()
        createGlow()
        
        // Начальная анимация
        playAppearAnimation()
    }
    
    // MARK: - King Tower (Главная башня)
    
    private func createKingTower() {
        let baseWidth: CGFloat = 80
        let baseHeight: CGFloat = 100
        
        // Основание башни
        let basePath = createTowerBasePath(width: baseWidth, height: baseHeight)
        let base = SKShapeNode(path: basePath)
        base.fillColor = side == .player ?
            SKColor(red: 0.35, green: 0.5, blue: 0.75, alpha: 1) :
            SKColor(red: 0.75, green: 0.35, blue: 0.35, alpha: 1)
        base.strokeColor = side == .player ?
            SKColor(red: 0.25, green: 0.4, blue: 0.65, alpha: 1) :
            SKColor(red: 0.6, green: 0.25, blue: 0.25, alpha: 1)
        base.lineWidth = 4
        base.zPosition = 1
        towerNode.addChild(base)
        
        // Каменная текстура (линии)
        for i in 0..<5 {
            let stone = SKShapeNode(rectOf: CGSize(width: baseWidth - 10, height: 12), cornerRadius: 2)
            stone.fillColor = .clear
            stone.strokeColor = SKColor.black.withAlphaComponent(0.15)
            stone.lineWidth = 1
            stone.position = CGPoint(x: 0, y: CGFloat(i) * 18 - 35)
            stone.zPosition = 2
            towerNode.addChild(stone)
        }
        
        // Окна
        for xOffset in [-20, 20] {
            let window = SKShapeNode(rectOf: CGSize(width: 14, height: 22), cornerRadius: 7)
            window.fillColor = SKColor(red: 0.1, green: 0.08, blue: 0.15, alpha: 1)
            window.strokeColor = SKColor(red: 0.6, green: 0.5, blue: 0.4, alpha: 1)
            window.lineWidth = 2
            window.position = CGPoint(x: CGFloat(xOffset), y: 10)
            window.zPosition = 3
            towerNode.addChild(window)
            
            // Свет в окне
            let light = SKShapeNode(rectOf: CGSize(width: 8, height: 10), cornerRadius: 4)
            light.fillColor = SKColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 0.6)
            light.strokeColor = .clear
            light.position = CGPoint(x: CGFloat(xOffset), y: 12)
            light.zPosition = 4
            towerNode.addChild(light)
            
            // Анимация мерцания
            let flicker = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: Double.random(in: 0.5...1.5)),
                SKAction.fadeAlpha(to: 0.7, duration: Double.random(in: 0.5...1.5))
            ])
            light.run(SKAction.repeatForever(flicker))
        }
        
        // Дверь
        let door = SKShapeNode(rectOf: CGSize(width: 24, height: 35), cornerRadius: 12)
        door.fillColor = SKColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1)
        door.strokeColor = SKColor(red: 0.5, green: 0.4, blue: 0.25, alpha: 1)
        door.lineWidth = 3
        door.position = CGPoint(x: 0, y: -32)
        door.zPosition = 3
        towerNode.addChild(door)
        
        // Ручка двери
        let handle = SKShapeNode(circleOfRadius: 3)
        handle.fillColor = SKColor(red: 0.7, green: 0.6, blue: 0.3, alpha: 1)
        handle.strokeColor = .clear
        handle.position = CGPoint(x: 6, y: -32)
        handle.zPosition = 4
        towerNode.addChild(handle)
        
        // Зубцы башни
        createBattlements(count: 7, width: baseWidth, yPos: baseHeight / 2 - 5)
        
        // Корона на башне
        createCrown(yPos: baseHeight / 2 + 20)
        
        // Флаг
        createFlag(xPos: baseWidth / 2 - 5, yPos: baseHeight / 2 + 10)
        
        // Пушка
        createCannon(yPos: 35)
    }
    
    // MARK: - Princess Tower (Боковая башня)
    
    private func createPrincessTower() {
        let baseWidth: CGFloat = 55
        let baseHeight: CGFloat = 75
        
        // Основание башни (круглая)
        let base = SKShapeNode(path: createRoundTowerPath(width: baseWidth, height: baseHeight))
        base.fillColor = side == .player ?
            SKColor(red: 0.4, green: 0.55, blue: 0.75, alpha: 1) :
            SKColor(red: 0.75, green: 0.4, blue: 0.4, alpha: 1)
        base.strokeColor = side == .player ?
            SKColor(red: 0.3, green: 0.45, blue: 0.65, alpha: 1) :
            SKColor(red: 0.6, green: 0.3, blue: 0.3, alpha: 1)
        base.lineWidth = 3
        base.zPosition = 1
        towerNode.addChild(base)
        
        // Каменные полосы
        for i in 0..<4 {
            let stripe = SKShapeNode(rectOf: CGSize(width: baseWidth - 8, height: 2), cornerRadius: 1)
            stripe.fillColor = SKColor.black.withAlphaComponent(0.1)
            stripe.strokeColor = .clear
            stripe.position = CGPoint(x: 0, y: CGFloat(i) * 16 - 22)
            stripe.zPosition = 2
            towerNode.addChild(stripe)
        }
        
        // Окно (арка)
        let windowPath = CGMutablePath()
        windowPath.addArc(center: CGPoint(x: 0, y: 10), radius: 10, startAngle: 0, endAngle: .pi, clockwise: false)
        windowPath.addLine(to: CGPoint(x: -10, y: -5))
        windowPath.addLine(to: CGPoint(x: 10, y: -5))
        windowPath.closeSubpath()
        
        let window = SKShapeNode(path: windowPath)
        window.fillColor = SKColor(red: 0.08, green: 0.06, blue: 0.12, alpha: 1)
        window.strokeColor = SKColor(red: 0.55, green: 0.45, blue: 0.35, alpha: 1)
        window.lineWidth = 2
        window.position = CGPoint(x: 0, y: 5)
        window.zPosition = 3
        towerNode.addChild(window)
        
        // Зубцы
        createBattlements(count: 5, width: baseWidth, yPos: baseHeight / 2 - 5)
        
        // Конусная крыша
        createConicalRoof(width: baseWidth, yPos: baseHeight / 2)
        
        // Пушка/арбалет
        createCrossbow(yPos: 20)
    }
    
    // MARK: - Tower Parts
    
    private func createTowerBasePath(width: CGFloat, height: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let bottomWidth = width * 1.1
        
        path.move(to: CGPoint(x: -bottomWidth / 2, y: -height / 2))
        path.addLine(to: CGPoint(x: -width / 2, y: height / 2))
        path.addLine(to: CGPoint(x: width / 2, y: height / 2))
        path.addLine(to: CGPoint(x: bottomWidth / 2, y: -height / 2))
        path.closeSubpath()
        
        return path
    }
    
    private func createRoundTowerPath(width: CGFloat, height: CGFloat) -> CGPath {
        let path = CGMutablePath()
        
        // Скруглённые углы
        path.addRoundedRect(
            in: CGRect(x: -width / 2, y: -height / 2, width: width, height: height),
            cornerWidth: width / 4,
            cornerHeight: width / 4
        )
        
        return path
    }
    
    private func createBattlements(count: Int, width: CGFloat, yPos: CGFloat) {
        let spacing = width / CGFloat(count)
        let battlementWidth = spacing * 0.6
        let battlementHeight: CGFloat = 12
        
        for i in 0..<count {
            let xPos = -width / 2 + spacing / 2 + CGFloat(i) * spacing
            
            let battlement = SKShapeNode(rectOf: CGSize(width: battlementWidth, height: battlementHeight), cornerRadius: 2)
            battlement.fillColor = side == .player ?
                SKColor(red: 0.4, green: 0.55, blue: 0.8, alpha: 1) :
                SKColor(red: 0.8, green: 0.4, blue: 0.4, alpha: 1)
            battlement.strokeColor = side == .player ?
                SKColor(red: 0.3, green: 0.45, blue: 0.7, alpha: 1) :
                SKColor(red: 0.65, green: 0.3, blue: 0.3, alpha: 1)
            battlement.lineWidth = 2
            battlement.position = CGPoint(x: xPos, y: yPos + battlementHeight / 2)
            battlement.zPosition = 5
            towerNode.addChild(battlement)
        }
    }
    
    private func createCrown(yPos: CGFloat) {
        crownNode = SKNode()
        crownNode?.position = CGPoint(x: 0, y: yPos)
        crownNode?.zPosition = 10
        
        // Подставка
        let pedestal = SKShapeNode(rectOf: CGSize(width: 30, height: 8), cornerRadius: 3)
        pedestal.fillColor = SKColor(red: 0.7, green: 0.55, blue: 0.25, alpha: 1)
        pedestal.strokeColor = SKColor(red: 0.5, green: 0.4, blue: 0.2, alpha: 1)
        pedestal.lineWidth = 2
        crownNode?.addChild(pedestal)
        
        // Корона
        let crownPath = createCrownPath()
        let crown = SKShapeNode(path: crownPath)
        crown.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1)
        crown.strokeColor = SKColor(red: 0.85, green: 0.65, blue: 0.15, alpha: 1)
        crown.lineWidth = 2
        crown.position = CGPoint(x: 0, y: 12)
        crownNode?.addChild(crown)
        
        // Драгоценности на короне
        let gemColors: [SKColor] = [
            SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1),
            SKColor(red: 0.2, green: 0.7, blue: 0.9, alpha: 1),
            SKColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 1)
        ]
        
        for (i, xPos) in [-10, 0, 10].enumerated() {
            let gem = SKShapeNode(circleOfRadius: 4)
            gem.fillColor = gemColors[i]
            gem.strokeColor = .white
            gem.lineWidth = 1
            gem.position = CGPoint(x: CGFloat(xPos), y: 18)
            gem.glowWidth = 3
            crownNode?.addChild(gem)
        }
        
        towerNode.addChild(crownNode!)
        
        // Анимация качания
        let sway = SKAction.sequence([
            SKAction.rotate(byAngle: 0.05, duration: 1.5),
            SKAction.rotate(byAngle: -0.05, duration: 1.5)
        ])
        crownNode?.run(SKAction.repeatForever(sway))
    }
    
    private func createCrownPath() -> CGPath {
        let path = CGMutablePath()
        let width: CGFloat = 28
        let height: CGFloat = 18
        
        path.move(to: CGPoint(x: -width / 2, y: 0))
        path.addLine(to: CGPoint(x: -width / 2, y: height * 0.4))
        path.addLine(to: CGPoint(x: -width / 3, y: height))
        path.addLine(to: CGPoint(x: -width / 6, y: height * 0.5))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: width / 6, y: height * 0.5))
        path.addLine(to: CGPoint(x: width / 3, y: height))
        path.addLine(to: CGPoint(x: width / 2, y: height * 0.4))
        path.addLine(to: CGPoint(x: width / 2, y: 0))
        path.closeSubpath()
        
        return path
    }
    
    private func createConicalRoof(width: CGFloat, yPos: CGFloat) {
        let roofPath = CGMutablePath()
        roofPath.move(to: CGPoint(x: 0, y: 35))
        roofPath.addLine(to: CGPoint(x: -width / 2 - 5, y: 0))
        roofPath.addLine(to: CGPoint(x: width / 2 + 5, y: 0))
        roofPath.closeSubpath()
        
        let roof = SKShapeNode(path: roofPath)
        roof.fillColor = side == .player ?
            SKColor(red: 0.25, green: 0.35, blue: 0.55, alpha: 1) :
            SKColor(red: 0.55, green: 0.25, blue: 0.25, alpha: 1)
        roof.strokeColor = side == .player ?
            SKColor(red: 0.2, green: 0.28, blue: 0.45, alpha: 1) :
            SKColor(red: 0.45, green: 0.2, blue: 0.2, alpha: 1)
        roof.lineWidth = 2
        roof.position = CGPoint(x: 0, y: yPos)
        roof.zPosition = 6
        towerNode.addChild(roof)
        
        // Флажок на крыше
        let flagPole = SKShapeNode(rectOf: CGSize(width: 3, height: 20), cornerRadius: 1)
        flagPole.fillColor = SKColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1)
        flagPole.strokeColor = .clear
        flagPole.position = CGPoint(x: 0, y: yPos + 45)
        flagPole.zPosition = 7
        towerNode.addChild(flagPole)
        
        let flag = SKShapeNode(path: createSmallFlagPath())
        flag.fillColor = side == .player ?
            SKColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1) :
            SKColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1)
        flag.strokeColor = .clear
        flag.position = CGPoint(x: 8, y: yPos + 52)
        flag.zPosition = 8
        towerNode.addChild(flag)
        
        // Анимация флага
        let wave = SKAction.sequence([
            SKAction.scaleX(to: 0.85, duration: 0.4),
            SKAction.scaleX(to: 1.0, duration: 0.4)
        ])
        flag.run(SKAction.repeatForever(wave))
    }
    
    private func createSmallFlagPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -8, y: 0))
        path.addLine(to: CGPoint(x: 10, y: 4))
        path.addLine(to: CGPoint(x: -8, y: 8))
        path.closeSubpath()
        return path
    }
    
    private func createFlag(xPos: CGFloat, yPos: CGFloat) {
        flagNode = SKNode()
        flagNode?.position = CGPoint(x: xPos, y: yPos)
        flagNode?.zPosition = 10
        
        // Древко
        let pole = SKShapeNode(rectOf: CGSize(width: 4, height: 45), cornerRadius: 2)
        pole.fillColor = SKColor(red: 0.45, green: 0.35, blue: 0.25, alpha: 1)
        pole.strokeColor = SKColor(red: 0.35, green: 0.25, blue: 0.18, alpha: 1)
        pole.lineWidth = 1
        pole.position = CGPoint(x: 0, y: 22)
        flagNode?.addChild(pole)
        
        // Флаг
        let flagPath = createFlagPath()
        let flag = SKShapeNode(path: flagPath)
        flag.fillColor = side == .player ?
            SKColor(red: 0.25, green: 0.45, blue: 0.85, alpha: 1) :
            SKColor(red: 0.85, green: 0.25, blue: 0.25, alpha: 1)
        flag.strokeColor = side == .player ?
            SKColor(red: 0.2, green: 0.35, blue: 0.7, alpha: 1) :
            SKColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1)
        flag.lineWidth = 1
        flag.position = CGPoint(x: 15, y: 35)
        flagNode?.addChild(flag)
        
        // Эмблема на флаге
        let emblem = SKShapeNode(circleOfRadius: 6)
        emblem.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1)
        emblem.strokeColor = .clear
        emblem.position = CGPoint(x: 15, y: 35)
        flagNode?.addChild(emblem)
        
        towerNode.addChild(flagNode!)
        
        // Анимация развевания
        let wave = SKAction.sequence([
            SKAction.rotate(byAngle: 0.08, duration: 0.6),
            SKAction.rotate(byAngle: -0.08, duration: 0.6)
        ])
        flagNode?.run(SKAction.repeatForever(wave))
    }
    
    private func createFlagPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -15, y: 0))
        path.addQuadCurve(to: CGPoint(x: 20, y: 5), control: CGPoint(x: 5, y: 8))
        path.addQuadCurve(to: CGPoint(x: -15, y: 15), control: CGPoint(x: 10, y: 12))
        path.closeSubpath()
        return path
    }
    
    private func createCannon(yPos: CGFloat) {
        cannonNode = SKNode()
        cannonNode?.position = CGPoint(x: 0, y: yPos)
        cannonNode?.zPosition = 8
        
        // Основание пушки
        let mount = SKShapeNode(rectOf: CGSize(width: 30, height: 15), cornerRadius: 5)
        mount.fillColor = SKColor(red: 0.35, green: 0.3, blue: 0.25, alpha: 1)
        mount.strokeColor = SKColor(red: 0.25, green: 0.2, blue: 0.15, alpha: 1)
        mount.lineWidth = 2
        cannonNode?.addChild(mount)
        
        // Ствол пушки
        let barrel = SKShapeNode(rectOf: CGSize(width: 35, height: 14), cornerRadius: 4)
        barrel.fillColor = SKColor(red: 0.3, green: 0.28, blue: 0.25, alpha: 1)
        barrel.strokeColor = SKColor(red: 0.2, green: 0.18, blue: 0.15, alpha: 1)
        barrel.lineWidth = 2
        barrel.position = CGPoint(x: 0, y: 12)
        cannonNode?.addChild(barrel)
        
        // Дуло
        let muzzle = SKShapeNode(circleOfRadius: 8)
        muzzle.fillColor = SKColor(red: 0.15, green: 0.12, blue: 0.1, alpha: 1)
        muzzle.strokeColor = SKColor(red: 0.25, green: 0.22, blue: 0.2, alpha: 1)
        muzzle.lineWidth = 2
        muzzle.position = CGPoint(x: 0, y: 22)
        cannonNode?.addChild(muzzle)
        
        // Декоративные кольца на стволе
        for yOffset in [5, 15] {
            let ring = SKShapeNode(rectOf: CGSize(width: 16, height: 3), cornerRadius: 1)
            ring.fillColor = SKColor(red: 0.5, green: 0.45, blue: 0.35, alpha: 1)
            ring.strokeColor = .clear
            ring.position = CGPoint(x: 0, y: CGFloat(yOffset))
            cannonNode?.addChild(ring)
        }
        
        towerNode.addChild(cannonNode!)
    }
    
    private func createCrossbow(yPos: CGFloat) {
        cannonNode = SKNode()
        cannonNode?.position = CGPoint(x: 0, y: yPos)
        cannonNode?.zPosition = 8
        
        // Основание
        let base = SKShapeNode(rectOf: CGSize(width: 20, height: 12), cornerRadius: 3)
        base.fillColor = SKColor(red: 0.45, green: 0.35, blue: 0.25, alpha: 1)
        base.strokeColor = SKColor(red: 0.35, green: 0.25, blue: 0.18, alpha: 1)
        base.lineWidth = 2
        cannonNode?.addChild(base)
        
        // Дуга арбалета
        let bowPath = CGMutablePath()
        bowPath.addArc(center: CGPoint(x: 0, y: 8), radius: 18, startAngle: .pi * 0.2, endAngle: .pi * 0.8, clockwise: false)
        
        let bow = SKShapeNode(path: bowPath)
        bow.strokeColor = SKColor(red: 0.5, green: 0.35, blue: 0.2, alpha: 1)
        bow.lineWidth = 5
        bow.lineCap = .round
        cannonNode?.addChild(bow)
        
        // Тетива
        let stringPath = CGMutablePath()
        stringPath.move(to: CGPoint(x: -16, y: 14))
        stringPath.addLine(to: CGPoint(x: 0, y: 5))
        stringPath.addLine(to: CGPoint(x: 16, y: 14))
        
        let string = SKShapeNode(path: stringPath)
        string.strokeColor = SKColor(red: 0.85, green: 0.8, blue: 0.7, alpha: 1)
        string.lineWidth = 2
        cannonNode?.addChild(string)
        
        // Стрела
        let arrow = createArrowForCrossbow()
        arrow.position = CGPoint(x: 0, y: 8)
        cannonNode?.addChild(arrow)
        
        towerNode.addChild(cannonNode!)
    }
    
    private func createArrowForCrossbow() -> SKNode {
        let arrow = SKNode()
        
        let shaft = SKShapeNode(rectOf: CGSize(width: 3, height: 20), cornerRadius: 1)
        shaft.fillColor = SKColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1)
        shaft.strokeColor = .clear
        arrow.addChild(shaft)
        
        let tipPath = CGMutablePath()
        tipPath.move(to: CGPoint(x: 0, y: 15))
        tipPath.addLine(to: CGPoint(x: 4, y: 10))
        tipPath.addLine(to: CGPoint(x: -4, y: 10))
        tipPath.closeSubpath()
        
        let tip = SKShapeNode(path: tipPath)
        tip.fillColor = SKColor(red: 0.7, green: 0.7, blue: 0.75, alpha: 1)
        tip.strokeColor = .clear
        arrow.addChild(tip)
        
        return arrow
    }
    
    // MARK: - Health Bar
    
    private func createHealthBar() {
        let isKing = towerType == .king
        let barWidth: CGFloat = isKing ? 70 : 50
        let barHeight: CGFloat = 10
        let yPos: CGFloat = isKing ? 70 : 55
        
        // Фон
        healthBarBg = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 5)
        healthBarBg.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 0.9)
        healthBarBg.strokeColor = SKColor.white.withAlphaComponent(0.4)
        healthBarBg.lineWidth = 2
        healthBarBg.position = CGPoint(x: 0, y: yPos)
        healthBarBg.zPosition = 50
        addChild(healthBarBg)
        
        updateHealthBar()
    }
    
    private func updateHealthBar() {
        healthBarFill?.removeFromParent()
        
        let isKing = towerType == .king
        let barWidth: CGFloat = isKing ? 70 : 50
        let barHeight: CGFloat = 8
        let yPos: CGFloat = isKing ? 70 : 55
        
        let healthPercent = CGFloat(max(0, health)) / CGFloat(maxHealth)
        let fillWidth = (barWidth - 4) * healthPercent
        
        healthBarFill = SKShapeNode(rectOf: CGSize(width: max(0, fillWidth), height: barHeight), cornerRadius: 4)
        
        // Цвет в зависимости от здоровья
        if healthPercent > 0.6 {
            healthBarFill.fillColor = side == .player ?
                SKColor(red: 0.3, green: 0.85, blue: 0.45, alpha: 1) :
                SKColor(red: 0.95, green: 0.4, blue: 0.4, alpha: 1)
        } else if healthPercent > 0.3 {
            healthBarFill.fillColor = SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1)
        } else {
            healthBarFill.fillColor = SKColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 1)
        }
        
        healthBarFill.strokeColor = .clear
        let offsetX = -(barWidth - 4 - fillWidth) / 2
        healthBarFill.position = CGPoint(x: offsetX, y: yPos)
        healthBarFill.zPosition = 51
        addChild(healthBarFill)
    }
    
    // MARK: - Glow Effect
    
    private func createGlow() {
        let glowRadius: CGFloat = towerType == .king ? 60 : 45
        
        glowNode = SKShapeNode(circleOfRadius: glowRadius)
        glowNode?.fillColor = side == .player ?
            SKColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 0.1) :
            SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.1)
        glowNode?.strokeColor = .clear
        glowNode?.zPosition = -5
        addChild(glowNode!)
        
        // Пульсация
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 1.5),
            SKAction.scale(to: 1.0, duration: 1.5)
        ])
        glowNode?.run(SKAction.repeatForever(pulse))
    }
    
    // MARK: - Animations
    
    private func playAppearAnimation() {
        towerNode.setScale(0)
        towerNode.alpha = 0
        
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.3)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.15)
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        
        towerNode.run(SKAction.group([
            SKAction.sequence([scaleUp, scaleDown]),
            fadeIn
        ]))
    }
    
    // MARK: - Combat
    
    func takeDamage(_ amount: Int) {
        guard !isDestroyed else { return }
        
        health -= amount
        updateHealthBar()
        
        // Эффект тряски
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -6, y: 0, duration: 0.04),
            SKAction.moveBy(x: 12, y: 0, duration: 0.04),
            SKAction.moveBy(x: -12, y: 0, duration: 0.04),
            SKAction.moveBy(x: 6, y: 0, duration: 0.04)
        ])
        towerNode.run(shake)
        
        // Вспышка
        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.6, duration: 0.05),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.15)
        ])
        towerNode.run(flash)
        
        // Частицы обломков
        createDamageDebris()
        
        if health <= 0 {
            destroy()
        }
    }
    
    private func createDamageDebris() {
        for _ in 0..<4 {
            let debris = SKShapeNode(rectOf: CGSize(width: 6, height: 6), cornerRadius: 1)
            debris.fillColor = side == .player ?
                SKColor(red: 0.4, green: 0.55, blue: 0.75, alpha: 1) :
                SKColor(red: 0.75, green: 0.4, blue: 0.4, alpha: 1)
            debris.strokeColor = .clear
            debris.position = CGPoint(
                x: CGFloat.random(in: -20...20),
                y: CGFloat.random(in: 0...30)
            )
            debris.zPosition = 40
            addChild(debris)
            
            let flyAway = SKAction.move(
                by: CGVector(dx: CGFloat.random(in: -50...50), dy: CGFloat.random(in: 30...60)),
                duration: 0.4
            )
            let fall = SKAction.move(by: CGVector(dx: 0, dy: -80), duration: 0.3)
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -3...3), duration: 0.7)
            let fade = SKAction.fadeOut(withDuration: 0.7)
            
            debris.run(SKAction.group([
                SKAction.sequence([flyAway, fall]),
                rotate,
                fade
            ])) {
                debris.removeFromParent()
            }
        }
    }
    
    private func destroy() {
        isDestroyed = true
        
        // Большой взрыв
        createDestructionExplosion()
        
        // Анимация разрушения
        let collapse = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.15, duration: 0.1),
                SKAction.colorize(with: .orange, colorBlendFactor: 0.7, duration: 0.1)
            ]),
            SKAction.group([
                SKAction.scale(to: 0.2, duration: 0.4),
                SKAction.fadeOut(withDuration: 0.4),
                SKAction.rotate(byAngle: 0.3, duration: 0.4)
            ])
        ])
        
        towerNode.run(collapse)
        healthBarBg.run(SKAction.fadeOut(withDuration: 0.2))
        healthBarFill?.run(SKAction.fadeOut(withDuration: 0.2))
        glowNode?.run(SKAction.fadeOut(withDuration: 0.3))
        
        // Callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.onDestroyed?(self?.towerType ?? .king, self?.side ?? .player)
        }
    }
    
    private func createDestructionExplosion() {
        // Огненный взрыв
        let explosion = SKShapeNode(circleOfRadius: 10)
        explosion.fillColor = SKColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1)
        explosion.strokeColor = SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 1)
        explosion.lineWidth = 5
        explosion.glowWidth = 20
        explosion.position = .zero
        explosion.zPosition = 100
        addChild(explosion)
        
        explosion.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 8, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))
        
        // Обломки
        for _ in 0..<15 {
            let debris = SKShapeNode(rectOf: CGSize(
                width: CGFloat.random(in: 8...16),
                height: CGFloat.random(in: 8...16)
            ), cornerRadius: 2)
            debris.fillColor = side == .player ?
                SKColor(red: 0.4, green: 0.55, blue: 0.75, alpha: 1) :
                SKColor(red: 0.75, green: 0.4, blue: 0.4, alpha: 1)
            debris.strokeColor = SKColor.black.withAlphaComponent(0.3)
            debris.lineWidth = 1
            debris.position = .zero
            debris.zPosition = 99
            addChild(debris)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 60...120)
            let endPos = CGPoint(
                x: cos(angle) * distance,
                y: sin(angle) * distance
            )
            
            let fly = SKAction.move(to: endPos, duration: 0.5)
            fly.timingMode = .easeOut
            let fall = SKAction.moveBy(x: 0, y: -50, duration: 0.3)
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -5...5), duration: 0.8)
            let fade = SKAction.fadeOut(withDuration: 0.8)
            
            debris.run(SKAction.group([
                SKAction.sequence([fly, fall]),
                rotate,
                fade
            ])) {
                debris.removeFromParent()
            }
        }
        
        // Дым
        for _ in 0..<8 {
            let smoke = SKShapeNode(circleOfRadius: CGFloat.random(in: 15...25))
            smoke.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 0.6)
            smoke.strokeColor = .clear
            smoke.position = CGPoint(
                x: CGFloat.random(in: -20...20),
                y: CGFloat.random(in: -10...20)
            )
            smoke.zPosition = 98
            addChild(smoke)
            
            smoke.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: CGFloat.random(in: -30...30), y: CGFloat.random(in: 40...80), duration: 1.0),
                    SKAction.scale(to: 2.5, duration: 1.0),
                    SKAction.fadeOut(withDuration: 1.0)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }
    
    // MARK: - Attack
    
    func attack(target: UnitNode, currentTime: TimeInterval) {
        guard !isDestroyed else { return }
        guard currentTime - lastAttackTime >= attackSpeed else { return }
        lastAttackTime = currentTime
        
        // Анимация отдачи пушки
        if let cannon = cannonNode {
            let recoil = SKAction.sequence([
                SKAction.moveBy(x: 0, y: -5, duration: 0.05),
                SKAction.moveBy(x: 0, y: 5, duration: 0.1)
            ])
            cannon.run(recoil)
        }
        
        // Создаём снаряд
        let projectile = createCannonball()
        projectile.position = CGPoint(x: position.x, y: position.y + 35)
        projectile.zPosition = 60
        self.parent?.addChild(projectile)
        
        // Полёт снаряда
        let moveAction = SKAction.move(to: target.position, duration: 0.2)
        projectile.run(moveAction) { [weak self] in
            self?.createImpactEffect(at: target.position)
            projectile.removeFromParent()
            target.takeDamage(self?.damage ?? 0)
        }
    }
    
    private func createCannonball() -> SKNode {
        let ball = SKNode()
        
        // Ядро
        let core = SKShapeNode(circleOfRadius: 10)
        core.fillColor = SKColor(red: 0.25, green: 0.25, blue: 0.3, alpha: 1)
        core.strokeColor = SKColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1)
        core.lineWidth = 2
        ball.addChild(core)
        
        // Блик
        let shine = SKShapeNode(circleOfRadius: 4)
        shine.fillColor = SKColor.white.withAlphaComponent(0.4)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: -3, y: 3)
        ball.addChild(shine)
        
        // След
        let trail = SKShapeNode(circleOfRadius: 6)
        trail.fillColor = side == .player ?
            SKColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 0.5) :
            SKColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 0.5)
        trail.strokeColor = .clear
        trail.zPosition = -1
        ball.addChild(trail)
        
        // Анимация следа
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.5, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        trail.run(SKAction.repeatForever(pulse))
        
        return ball
    }
    
    private func createImpactEffect(at position: CGPoint) {
        // Вспышка
        let flash = SKShapeNode(circleOfRadius: 20)
        flash.fillColor = .white
        flash.strokeColor = .clear
        flash.alpha = 0.9
        flash.position = position
        flash.zPosition = 70
        self.parent?.addChild(flash)
        
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2, duration: 0.1),
                SKAction.fadeOut(withDuration: 0.1)
            ]),
            SKAction.removeFromParent()
        ]))
        
        // Волна
        let wave = SKShapeNode(circleOfRadius: 10)
        wave.fillColor = .clear
        wave.strokeColor = side == .player ?
            SKColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1) :
            SKColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 1)
        wave.lineWidth = 4
        wave.position = position
        wave.zPosition = 69
        self.parent?.addChild(wave)
        
        wave.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 4, duration: 0.25),
                SKAction.fadeOut(withDuration: 0.25)
            ]),
            SKAction.removeFromParent()
        ]))
    }
    
    func distanceTo(_ node: SKNode) -> CGFloat {
        let dx = node.position.x - position.x
        let dy = node.position.y - position.y
        return sqrt(dx * dx + dy * dy)
    }
}
