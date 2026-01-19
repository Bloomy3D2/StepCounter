//
//  ParticleEffects.swift
//  ClashMini
//
//  Продвинутые эффекты частиц
//

import SpriteKit

/// Фабрика эффектов частиц
final class ParticleEffects {
    
    // MARK: - Spawn Effects
    
    /// Эффект появления юнита
    static func createSpawnEffect(at position: CGPoint, color: SKColor, in scene: SKScene) {
        // Кольцевая волна
        let ring = SKShapeNode(circleOfRadius: 5)
        ring.fillColor = .clear
        ring.strokeColor = color.withAlphaComponent(0.9)
        ring.lineWidth = 4
        ring.glowWidth = 8
        ring.position = position
        ring.zPosition = 100
        scene.addChild(ring)
        
        let expandRing = SKAction.scale(to: 6, duration: 0.4)
        let fadeRing = SKAction.fadeOut(withDuration: 0.4)
        ring.run(SKAction.group([expandRing, fadeRing])) {
            ring.removeFromParent()
        }
        
        // Искры
        for i in 0..<12 {
            let spark = SKShapeNode(circleOfRadius: 4)
            spark.fillColor = color
            spark.strokeColor = .white
            spark.lineWidth = 1
            spark.position = position
            spark.zPosition = 99
            scene.addChild(spark)
            
            let angle = CGFloat(i) * (.pi * 2 / 12)
            let distance: CGFloat = 50
            let endPos = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )
            
            let move = SKAction.move(to: endPos, duration: 0.3)
            move.timingMode = .easeOut
            let shrink = SKAction.scale(to: 0, duration: 0.3)
            
            spark.run(SKAction.group([move, shrink])) {
                spark.removeFromParent()
            }
        }
        
        // Вспышка в центре
        let flash = SKShapeNode(circleOfRadius: 15)
        flash.fillColor = .white
        flash.strokeColor = .clear
        flash.alpha = 0.8
        flash.position = position
        flash.zPosition = 101
        scene.addChild(flash)
        
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.5, duration: 0.15),
                SKAction.fadeOut(withDuration: 0.15)
            ]),
            SKAction.removeFromParent()
        ]))
    }
    
    // MARK: - Attack Effects
    
    /// Эффект удара мечом
    static func createSlashEffect(at position: CGPoint, direction: CGFloat, in scene: SKScene) {
        let slashPath = CGMutablePath()
        slashPath.addArc(center: .zero, radius: 25, startAngle: -0.5, endAngle: 0.5, clockwise: false)
        
        let slash = SKShapeNode(path: slashPath)
        slash.strokeColor = .white
        slash.lineWidth = 6
        slash.glowWidth = 8
        slash.alpha = 0.9
        slash.position = position
        slash.zRotation = direction
        slash.zPosition = 110
        scene.addChild(slash)
        
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.15)
        let fadeOut = SKAction.fadeOut(withDuration: 0.15)
        
        slash.run(SKAction.group([scaleUp, fadeOut])) {
            slash.removeFromParent()
        }
    }
    
    /// Эффект магического удара
    static func createMagicImpact(at position: CGPoint, color: SKColor, in scene: SKScene) {
        // Центральная вспышка
        let core = SKShapeNode(circleOfRadius: 20)
        core.fillColor = color
        core.strokeColor = .white
        core.lineWidth = 3
        core.glowWidth = 15
        core.position = position
        core.zPosition = 105
        scene.addChild(core)
        
        // Расширяющиеся кольца
        for i in 0..<3 {
            let ring = SKShapeNode(circleOfRadius: 10)
            ring.fillColor = .clear
            ring.strokeColor = color.withAlphaComponent(0.8 - CGFloat(i) * 0.2)
            ring.lineWidth = 3
            ring.position = position
            ring.zPosition = 104
            scene.addChild(ring)
            
            let delay = Double(i) * 0.1
            ring.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.scale(to: 5 + CGFloat(i), duration: 0.4),
                    SKAction.fadeOut(withDuration: 0.4)
                ]),
                SKAction.removeFromParent()
            ]))
        }
        
        // Частицы
        for _ in 0..<15 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...6))
            particle.fillColor = color
            particle.strokeColor = .white.withAlphaComponent(0.5)
            particle.lineWidth = 1
            particle.position = position
            particle.zPosition = 106
            scene.addChild(particle)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 40...80)
            let endPos = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )
            
            let move = SKAction.move(to: endPos, duration: 0.4)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.4)
            let shrink = SKAction.scale(to: 0, duration: 0.4)
            
            particle.run(SKAction.group([move, fade, shrink])) {
                particle.removeFromParent()
            }
        }
        
        core.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.2)
            ]),
            SKAction.removeFromParent()
        ]))
    }
    
    /// Эффект огненного дыхания
    static func createFireEffect(from start: CGPoint, to end: CGPoint, in scene: SKScene) {
        let particleCount = 20
        
        for i in 0..<particleCount {
            let t = CGFloat(i) / CGFloat(particleCount)
            let pos = CGPoint(
                x: start.x + (end.x - start.x) * t + CGFloat.random(in: -10...10),
                y: start.y + (end.y - start.y) * t + CGFloat.random(in: -10...10)
            )
            
            let flame = SKShapeNode(circleOfRadius: CGFloat.random(in: 8...15))
            let colors: [SKColor] = [
                SKColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1),
                SKColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1),
                SKColor(red: 1.0, green: 0.3, blue: 0.1, alpha: 1)
            ]
            flame.fillColor = colors.randomElement()!
            flame.strokeColor = .clear
            flame.alpha = 0.8
            flame.position = pos
            flame.zPosition = 108
            scene.addChild(flame)
            
            let delay = Double(i) * 0.02
            flame.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.moveBy(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: 10...30), duration: 0.3),
                    SKAction.scale(to: 0, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.3)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }
    
    // MARK: - Death Effects
    
    /// Эффект смерти юнита
    static func createDeathEffect(at position: CGPoint, color: SKColor, in scene: SKScene) {
        // Взрыв частиц
        for i in 0..<16 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 5...10))
            particle.fillColor = color
            particle.strokeColor = .white
            particle.lineWidth = 1
            particle.position = position
            particle.zPosition = 95
            scene.addChild(particle)
            
            let angle = CGFloat(i) * (.pi * 2 / 16)
            let distance = CGFloat.random(in: 50...90)
            let endPos = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )
            
            let move = SKAction.move(to: endPos, duration: 0.4)
            move.timingMode = .easeOut
            let shrink = SKAction.scale(to: 0, duration: 0.5)
            let fade = SKAction.fadeOut(withDuration: 0.5)
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -3...3), duration: 0.5)
            
            particle.run(SKAction.group([move, shrink, fade, rotate])) {
                particle.removeFromParent()
            }
        }
        
        // Дымок
        for _ in 0..<6 {
            let smoke = SKShapeNode(circleOfRadius: CGFloat.random(in: 15...25))
            smoke.fillColor = SKColor(white: 0.4, alpha: 0.5)
            smoke.strokeColor = .clear
            smoke.position = CGPoint(
                x: position.x + CGFloat.random(in: -15...15),
                y: position.y + CGFloat.random(in: -10...10)
            )
            smoke.zPosition = 94
            scene.addChild(smoke)
            
            smoke.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: 30...60), duration: 0.8),
                    SKAction.scale(to: 2, duration: 0.8),
                    SKAction.fadeOut(withDuration: 0.8)
                ]),
                SKAction.removeFromParent()
            ]))
        }
        
        // Вспышка
        let flash = SKShapeNode(circleOfRadius: 25)
        flash.fillColor = .white
        flash.strokeColor = .clear
        flash.alpha = 0.9
        flash.position = position
        flash.zPosition = 96
        scene.addChild(flash)
        
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.5, duration: 0.15),
                SKAction.fadeOut(withDuration: 0.15)
            ]),
            SKAction.removeFromParent()
        ]))
    }
    
    // MARK: - Tower Effects
    
    /// Эффект разрушения башни
    static func createTowerDestructionEffect(at position: CGPoint, color: SKColor, in scene: SKScene) {
        // Большой взрыв
        for wave in 0..<3 {
            let explosion = SKShapeNode(circleOfRadius: 30)
            explosion.fillColor = wave == 0 ? SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 1) : color.withAlphaComponent(0.7)
            explosion.strokeColor = .white
            explosion.lineWidth = wave == 0 ? 5 : 3
            explosion.glowWidth = 20
            explosion.position = position
            explosion.zPosition = 150
            scene.addChild(explosion)
            
            let delay = Double(wave) * 0.1
            explosion.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.scale(to: CGFloat(5 + wave * 2), duration: 0.4),
                    SKAction.fadeOut(withDuration: 0.4)
                ]),
                SKAction.removeFromParent()
            ]))
        }
        
        // Много обломков
        for _ in 0..<25 {
            let size = CGFloat.random(in: 8...20)
            let debris = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: 2)
            debris.fillColor = color
            debris.strokeColor = .black.withAlphaComponent(0.3)
            debris.lineWidth = 1
            debris.position = CGPoint(
                x: position.x + CGFloat.random(in: -30...30),
                y: position.y + CGFloat.random(in: -20...40)
            )
            debris.zPosition = 149
            scene.addChild(debris)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 80...150)
            let endPos = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance * 0.8
            )
            
            let fly = SKAction.move(to: endPos, duration: 0.5)
            fly.timingMode = .easeOut
            let fall = SKAction.moveBy(x: 0, y: -80, duration: 0.4)
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -6...6), duration: 0.9)
            let fade = SKAction.fadeOut(withDuration: 0.9)
            
            debris.run(SKAction.group([
                SKAction.sequence([fly, fall]),
                rotate,
                fade
            ])) {
                debris.removeFromParent()
            }
        }
        
        // Много дыма
        for _ in 0..<12 {
            let smoke = SKShapeNode(circleOfRadius: CGFloat.random(in: 20...40))
            smoke.fillColor = SKColor(white: 0.35, alpha: 0.6)
            smoke.strokeColor = .clear
            smoke.position = CGPoint(
                x: position.x + CGFloat.random(in: -40...40),
                y: position.y + CGFloat.random(in: -20...30)
            )
            smoke.zPosition = 148
            scene.addChild(smoke)
            
            smoke.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: CGFloat.random(in: -50...50), y: CGFloat.random(in: 60...120), duration: 1.5),
                    SKAction.scale(to: 3, duration: 1.5),
                    SKAction.fadeOut(withDuration: 1.5)
                ]),
                SKAction.removeFromParent()
            ]))
        }
        
        // Огонь
        for _ in 0..<8 {
            let flame = SKShapeNode(circleOfRadius: CGFloat.random(in: 15...25))
            let colors: [SKColor] = [
                SKColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1),
                SKColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 1),
                SKColor(red: 1.0, green: 0.3, blue: 0.1, alpha: 1)
            ]
            flame.fillColor = colors.randomElement()!
            flame.strokeColor = .clear
            flame.position = CGPoint(
                x: position.x + CGFloat.random(in: -30...30),
                y: position.y + CGFloat.random(in: -10...30)
            )
            flame.zPosition = 147
            scene.addChild(flame)
            
            flame.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: 40...80), duration: 0.6),
                    SKAction.scale(to: 0, duration: 0.6),
                    SKAction.fadeOut(withDuration: 0.6)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }
    
    // MARK: - Elixir Effect
    
    /// Эффект полного эликсира
    static func createElixirFullEffect(in scene: SKScene) {
        let screenWidth = scene.size.width
        
        // Вспышка внизу экрана
        let flash = SKShapeNode(rectOf: CGSize(width: screenWidth, height: 50))
        flash.fillColor = SKColor(red: 0.7, green: 0.3, blue: 0.9, alpha: 0.5)
        flash.strokeColor = .clear
        flash.position = CGPoint(x: screenWidth / 2, y: 80)
        flash.zPosition = 200
        scene.addChild(flash)
        
        flash.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.8, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }
    
    // MARK: - Crown Effect
    
    /// Эффект получения короны
    static func createCrownEffect(at position: CGPoint, in scene: SKScene) {
        // Летящая корона
        let crown = SKLabelNode(text: "👑")
        crown.fontSize = 40
        crown.position = position
        crown.zPosition = 200
        scene.addChild(crown)
        
        // Анимация
        let moveUp = SKAction.moveBy(x: 0, y: 100, duration: 0.8)
        moveUp.timingMode = .easeOut
        let scale = SKAction.sequence([
            SKAction.scale(to: 1.5, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2),
            SKAction.scale(to: 1.3, duration: 0.4)
        ])
        let fade = SKAction.fadeOut(withDuration: 0.8)
        
        crown.run(SKAction.group([moveUp, scale, fade])) {
            crown.removeFromParent()
        }
        
        // Золотые искры
        for _ in 0..<12 {
            let spark = SKShapeNode(circleOfRadius: 4)
            spark.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1)
            spark.strokeColor = .white
            spark.lineWidth = 1
            spark.position = position
            spark.zPosition = 199
            scene.addChild(spark)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 40...80)
            let endPos = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )
            
            spark.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: endPos, duration: 0.5),
                    SKAction.fadeOut(withDuration: 0.5)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }
}
