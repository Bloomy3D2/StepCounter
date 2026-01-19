//
//  Unit.swift
//  ClashMini
//
//  Юнит с красивыми нарисованными персонажами
//

import Foundation
import SpriteKit

/// Состояние юнита
enum UnitState {
    case idle
    case moving
    case attacking
    case dead
}

/// Узел юнита для SpriteKit
class UnitNode: SKNode {
    
    // MARK: - Properties
    
    let cardType: CardType
    let side: PlayerSide
    var unitId: UUID = UUID()
    
    var health: Int
    var maxHealth: Int
    var damage: Int
    var attackSpeed: TimeInterval
    var moveSpeed: CGFloat
    var attackRange: CGFloat
    
    var state: UnitState = .idle
    var target: SKNode?
    var lastAttackTime: TimeInterval = 0
    
    // MARK: - Visual Components
    
    private var characterNode: SKNode!
    private var shadowNode: SKShapeNode!
    private var healthBarBackground: SKShapeNode!
    private var healthBarFill: SKShapeNode!
    private var selectionRing: SKShapeNode!
    
    private let unitSize: CGFloat = 44
    
    // MARK: - Init
    
    init(cardType: CardType, side: PlayerSide) {
        self.cardType = cardType
        self.side = side
        self.health = cardType.health
        self.maxHealth = cardType.health
        self.damage = cardType.damage
        self.attackSpeed = cardType.attackSpeed
        self.moveSpeed = cardType.moveSpeed
        self.attackRange = cardType.attackRange
        
        super.init()
        
        setupCharacter()
        createHealthBar()
        playSpawnAnimation()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupCharacter() {
        // Тень
        shadowNode = SKShapeNode(ellipseOf: CGSize(width: unitSize * 0.7, height: unitSize * 0.25))
        shadowNode.fillColor = SKColor.black.withAlphaComponent(0.35)
        shadowNode.strokeColor = .clear
        shadowNode.position = CGPoint(x: 0, y: -unitSize * 0.4)
        shadowNode.zPosition = -2
        addChild(shadowNode)
        
        // Кольцо команды
        selectionRing = SKShapeNode(circleOfRadius: unitSize * 0.55)
        selectionRing.fillColor = .clear
        selectionRing.strokeColor = side == .player ?
            SKColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.8) :
            SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.8)
        selectionRing.lineWidth = 3
        selectionRing.glowWidth = 4
        selectionRing.position = CGPoint(x: 0, y: -unitSize * 0.25)
        selectionRing.zPosition = -1
        addChild(selectionRing)
        
        // Создаём персонажа
        let teamColor = side == .player ?
            SKColor(red: 0.3, green: 0.5, blue: 0.85, alpha: 1) :
            SKColor(red: 0.85, green: 0.3, blue: 0.3, alpha: 1)
        
        switch cardType {
        case .knight:
            characterNode = CharacterSprites.createKnight(teamColor: teamColor)
        case .archer:
            characterNode = CharacterSprites.createArcher(teamColor: teamColor)
        case .giant:
            characterNode = CharacterSprites.createGiant(teamColor: teamColor)
        case .goblin:
            characterNode = CharacterSprites.createGoblin(teamColor: teamColor)
        case .wizard:
            characterNode = CharacterSprites.createWizard(teamColor: teamColor)
        case .dragon:
            characterNode = CharacterSprites.createDragon(teamColor: teamColor)
        }
        
        characterNode.zPosition = 1
        addChild(characterNode)
        
        // Idle анимация
        startIdleAnimation()
    }
    
    private func startIdleAnimation() {
        guard cardType != .dragon else { return } // Дракон уже имеет анимацию
        
        let breathe = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 2, duration: 0.5),
            SKAction.moveBy(x: 0, y: -2, duration: 0.5)
        ])
        characterNode.run(SKAction.repeatForever(breathe))
    }
    
    // MARK: - Health Bar
    
    private func createHealthBar() {
        let barWidth: CGFloat = unitSize * 0.85
        let barHeight: CGFloat = 7
        let yPos = unitSize * 0.55
        
        healthBarBackground = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 3)
        healthBarBackground.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 0.9)
        healthBarBackground.strokeColor = SKColor.white.withAlphaComponent(0.3)
        healthBarBackground.lineWidth = 1
        healthBarBackground.position = CGPoint(x: 0, y: yPos)
        healthBarBackground.zPosition = 20
        addChild(healthBarBackground)
        
        updateHealthBar()
    }
    
    private func updateHealthBar() {
        healthBarFill?.removeFromParent()
        
        let barWidth: CGFloat = unitSize * 0.85
        let barHeight: CGFloat = 5
        let yPos = unitSize * 0.55
        
        let healthPercent = CGFloat(max(0, health)) / CGFloat(maxHealth)
        let fillWidth = (barWidth - 2) * healthPercent
        
        healthBarFill = SKShapeNode(rectOf: CGSize(width: max(0, fillWidth), height: barHeight), cornerRadius: 2)
        healthBarFill.fillColor = side == .player ?
            SKColor(red: 0.3, green: 0.85, blue: 0.4, alpha: 1) :
            SKColor(red: 0.95, green: 0.35, blue: 0.35, alpha: 1)
        healthBarFill.strokeColor = .clear
        
        let offsetX = -(barWidth - 2 - fillWidth) / 2
        healthBarFill.position = CGPoint(x: offsetX, y: yPos)
        healthBarFill.zPosition = 21
        addChild(healthBarFill)
    }
    
    // MARK: - Spawn Animation
    
    private func playSpawnAnimation() {
        self.setScale(0)
        self.alpha = 0
        
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        
        self.run(SKAction.group([
            SKAction.sequence([scaleUp, scaleDown]),
            fadeIn
        ]))
        
        // Эффект появления
        let ring = SKShapeNode(circleOfRadius: 5)
        ring.fillColor = .clear
        ring.strokeColor = side == .player ?
            SKColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1) :
            SKColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 1)
        ring.lineWidth = 3
        ring.glowWidth = 5
        ring.zPosition = -3
        addChild(ring)
        
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 10, duration: 0.4),
                SKAction.fadeOut(withDuration: 0.4)
            ]),
            SKAction.removeFromParent()
        ]))
    }
    
    // MARK: - Combat
    
    func takeDamage(_ amount: Int) {
        health -= amount
        updateHealthBar()
        
        // Вспышка урона
        let flash = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.7, duration: 0.05),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.15)
        ])
        characterNode.run(flash)
        
        // Тряска
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -3, y: 0, duration: 0.03),
            SKAction.moveBy(x: 6, y: 0, duration: 0.03),
            SKAction.moveBy(x: -3, y: 0, duration: 0.03)
        ])
        self.run(shake)
        
        // Частицы урона
        createDamageParticles()
        
        if health <= 0 {
            die()
        }
    }
    
    private func createDamageParticles() {
        for _ in 0..<5 {
            let particle = SKShapeNode(circleOfRadius: 3)
            particle.fillColor = .red
            particle.strokeColor = .clear
            particle.position = CGPoint(
                x: CGFloat.random(in: -15...15),
                y: CGFloat.random(in: 0...20)
            )
            particle.zPosition = 30
            addChild(particle)
            
            let moveUp = SKAction.moveBy(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: 10...30), duration: 0.3)
            let fade = SKAction.fadeOut(withDuration: 0.3)
            particle.run(SKAction.group([moveUp, fade])) {
                particle.removeFromParent()
            }
        }
    }
    
    private func die() {
        state = .dead
        
        // Эффект смерти
        if let scene = self.scene {
            ParticleEffects.createDeathEffect(at: self.position, color: cardType.color, in: scene)
        }
        
        // Анимация исчезновения
        let spin = SKAction.rotate(byAngle: .pi, duration: 0.3)
        let shrink = SKAction.scale(to: 0, duration: 0.3)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        
        self.run(SKAction.group([spin, shrink, fade])) {
            self.removeFromParent()
        }
    }
    
    func attack(target: SKNode, currentTime: TimeInterval) {
        guard currentTime - lastAttackTime >= attackSpeed else { return }
        lastAttackTime = currentTime
        state = .attacking
        
        // Анимация атаки
        let attackPunch = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.08),
            SKAction.scale(to: 1.0, duration: 0.12)
        ])
        characterNode.run(attackPunch)
        
        // Поворот к цели
        let dx = target.position.x - position.x
        if dx > 5 {
            characterNode.xScale = abs(characterNode.xScale)
        } else if dx < -5 {
            characterNode.xScale = -abs(characterNode.xScale)
        }
        
        // Снаряд для дальнобойных
        if attackRange > 50 {
            createProjectile(to: target)
        } else {
            createMeleeEffect(towards: target)
        }
        
        // Урон
        if let unitTarget = target as? UnitNode {
            unitTarget.takeDamage(damage)
        } else if let towerTarget = target as? TowerNode {
            towerTarget.takeDamage(damage)
        }
    }
    
    private func createProjectile(to target: SKNode) {
        guard let scene = self.scene else { return }
        
        let projectile = createProjectileNode()
        projectile.position = self.position
        projectile.zPosition = 15
        scene.addChild(projectile)
        
        let dx = target.position.x - position.x
        let dy = target.position.y - position.y
        let angle = atan2(dy, dx)
        projectile.zRotation = angle - .pi / 2
        
        let moveAction = SKAction.move(to: target.position, duration: 0.25)
        projectile.run(moveAction) {
            ParticleEffects.createMagicImpact(at: target.position, color: self.cardType.color, in: scene)
            projectile.removeFromParent()
        }
    }
    
    private func createProjectileNode() -> SKNode {
        let proj = SKNode()
        
        switch cardType {
        case .archer:
            // Стрела
            let shaft = SKShapeNode(rectOf: CGSize(width: 3, height: 22), cornerRadius: 1)
            shaft.fillColor = SKColor(red: 0.5, green: 0.38, blue: 0.25, alpha: 1)
            shaft.strokeColor = .clear
            proj.addChild(shaft)
            
            let tipPath = CGMutablePath()
            tipPath.move(to: CGPoint(x: 0, y: 16))
            tipPath.addLine(to: CGPoint(x: 4, y: 11))
            tipPath.addLine(to: CGPoint(x: -4, y: 11))
            tipPath.closeSubpath()
            let tip = SKShapeNode(path: tipPath)
            tip.fillColor = SKColor(red: 0.7, green: 0.7, blue: 0.75, alpha: 1)
            tip.strokeColor = .clear
            proj.addChild(tip)
            
        case .wizard:
            // Магический шар
            let glow = SKShapeNode(circleOfRadius: 12)
            glow.fillColor = SKColor(red: 0.5, green: 0.4, blue: 1.0, alpha: 0.4)
            glow.strokeColor = .clear
            proj.addChild(glow)
            
            let core = SKShapeNode(circleOfRadius: 7)
            core.fillColor = SKColor(red: 0.6, green: 0.5, blue: 1.0, alpha: 1)
            core.strokeColor = .white
            core.lineWidth = 2
            core.glowWidth = 8
            proj.addChild(core)
            
        case .dragon:
            // Огненный шар
            let outer = SKShapeNode(circleOfRadius: 12)
            outer.fillColor = SKColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 0.7)
            outer.strokeColor = .clear
            proj.addChild(outer)
            
            let inner = SKShapeNode(circleOfRadius: 8)
            inner.fillColor = SKColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 1)
            inner.strokeColor = SKColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1)
            inner.lineWidth = 2
            inner.glowWidth = 10
            proj.addChild(inner)
            
        default:
            let ball = SKShapeNode(circleOfRadius: 6)
            ball.fillColor = cardType.color
            ball.strokeColor = .white
            ball.lineWidth = 2
            ball.glowWidth = 4
            proj.addChild(ball)
        }
        
        return proj
    }
    
    private func createMeleeEffect(towards target: SKNode) {
        guard let scene = self.scene else { return }
        
        let dx = target.position.x - position.x
        ParticleEffects.createSlashEffect(
            at: CGPoint(x: position.x + (dx > 0 ? 20 : -20), y: position.y + 10),
            direction: dx > 0 ? 0 : .pi,
            in: scene
        )
    }
    
    // MARK: - Movement
    
    func moveToward(_ targetPosition: CGPoint, deltaTime: TimeInterval) {
        state = .moving
        
        let dx = targetPosition.x - position.x
        let dy = targetPosition.y - position.y
        let distance = sqrt(dx * dx + dy * dy)
        
        if distance > 1 {
            let normalizedDx = dx / distance
            let normalizedDy = dy / distance
            
            position.x += normalizedDx * moveSpeed * CGFloat(deltaTime)
            position.y += normalizedDy * moveSpeed * CGFloat(deltaTime)
            
            // Поворот в сторону движения
            if abs(dx) > 1 {
                characterNode.xScale = dx > 0 ? abs(characterNode.xScale) : -abs(characterNode.xScale)
            }
        }
    }
    
    func distanceTo(_ node: SKNode) -> CGFloat {
        let dx = node.position.x - position.x
        let dy = node.position.y - position.y
        return sqrt(dx * dx + dy * dy)
    }
}
