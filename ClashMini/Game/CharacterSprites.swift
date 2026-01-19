//
//  CharacterSprites.swift
//  ClashMini
//
//  Красивые уникальные персонажи в мультяшном стиле
//

import SpriteKit

/// Фабрика для создания красивых спрайтов персонажей
final class CharacterSprites {
    
    // MARK: - Knight (Рыцарь Стального Ордена)
    
    static func createKnight(teamColor: SKColor) -> SKNode {
        let character = SKNode()
        let scale: CGFloat = 1.0
        
        // === ТЕЛО (Броня) ===
        let bodyPath = CGMutablePath()
        bodyPath.move(to: CGPoint(x: -12, y: -18))
        bodyPath.addQuadCurve(to: CGPoint(x: 0, y: -22), control: CGPoint(x: -6, y: -22))
        bodyPath.addQuadCurve(to: CGPoint(x: 12, y: -18), control: CGPoint(x: 6, y: -22))
        bodyPath.addLine(to: CGPoint(x: 14, y: 5))
        bodyPath.addQuadCurve(to: CGPoint(x: 0, y: 12), control: CGPoint(x: 10, y: 12))
        bodyPath.addQuadCurve(to: CGPoint(x: -14, y: 5), control: CGPoint(x: -10, y: 12))
        bodyPath.closeSubpath()
        
        let body = SKShapeNode(path: bodyPath)
        body.fillColor = SKColor(red: 0.45, green: 0.48, blue: 0.55, alpha: 1) // Стальной
        body.strokeColor = SKColor(red: 0.3, green: 0.32, blue: 0.38, alpha: 1)
        body.lineWidth = 2
        body.zPosition = 1
        character.addChild(body)
        
        // Блик на броне
        let shineBody = SKShapeNode(ellipseOf: CGSize(width: 8, height: 16))
        shineBody.fillColor = SKColor.white.withAlphaComponent(0.25)
        shineBody.strokeColor = .clear
        shineBody.position = CGPoint(x: -4, y: -2)
        shineBody.zPosition = 2
        character.addChild(shineBody)
        
        // Нагрудник с эмблемой
        let chestPlate = SKShapeNode(rectOf: CGSize(width: 14, height: 12), cornerRadius: 3)
        chestPlate.fillColor = teamColor
        chestPlate.strokeColor = teamColor.darker(by: 0.3)
        chestPlate.lineWidth = 1.5
        chestPlate.position = CGPoint(x: 0, y: -4)
        chestPlate.zPosition = 3
        character.addChild(chestPlate)
        
        // Звезда на нагруднике
        let star = createStar(radius: 4, color: .white)
        star.position = CGPoint(x: 0, y: -4)
        star.zPosition = 4
        character.addChild(star)
        
        // === ГОЛОВА (Шлем) ===
        let helmet = SKShapeNode(circleOfRadius: 13)
        helmet.fillColor = SKColor(red: 0.5, green: 0.52, blue: 0.58, alpha: 1)
        helmet.strokeColor = SKColor(red: 0.35, green: 0.37, blue: 0.42, alpha: 1)
        helmet.lineWidth = 2
        helmet.position = CGPoint(x: 0, y: 18)
        helmet.zPosition = 5
        character.addChild(helmet)
        
        // Гребень шлема
        let crestPath = CGMutablePath()
        crestPath.move(to: CGPoint(x: -3, y: 28))
        crestPath.addQuadCurve(to: CGPoint(x: 0, y: 38), control: CGPoint(x: -2, y: 35))
        crestPath.addQuadCurve(to: CGPoint(x: 3, y: 28), control: CGPoint(x: 2, y: 35))
        crestPath.closeSubpath()
        
        let crest = SKShapeNode(path: crestPath)
        crest.fillColor = SKColor(red: 0.85, green: 0.2, blue: 0.2, alpha: 1) // Красный гребень
        crest.strokeColor = SKColor(red: 0.6, green: 0.15, blue: 0.15, alpha: 1)
        crest.lineWidth = 1
        crest.zPosition = 6
        character.addChild(crest)
        
        // Визор (прорезь для глаз)
        let visor = SKShapeNode(rectOf: CGSize(width: 18, height: 5), cornerRadius: 2)
        visor.fillColor = SKColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1)
        visor.strokeColor = .clear
        visor.position = CGPoint(x: 0, y: 17)
        visor.zPosition = 7
        character.addChild(visor)
        
        // Глаза (светящиеся в визоре)
        for xOff in [-4, 4] {
            let eye = SKShapeNode(circleOfRadius: 2)
            eye.fillColor = SKColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1)
            eye.strokeColor = .clear
            eye.glowWidth = 3
            eye.position = CGPoint(x: CGFloat(xOff), y: 17)
            eye.zPosition = 8
            character.addChild(eye)
        }
        
        // === МЕЧ ===
        let sword = createSword(length: 35)
        sword.position = CGPoint(x: 20, y: 0)
        sword.zRotation = -0.4
        sword.zPosition = 10
        character.addChild(sword)
        
        // === ЩИТ ===
        let shield = createShield(color: teamColor)
        shield.position = CGPoint(x: -18, y: -2)
        shield.zPosition = 10
        character.addChild(shield)
        
        character.setScale(scale)
        return character
    }
    
    // MARK: - Archer (Лесная Охотница)
    
    static func createArcher(teamColor: SKColor) -> SKNode {
        let character = SKNode()
        
        // === ПЛАЩ ===
        let cloakPath = CGMutablePath()
        cloakPath.move(to: CGPoint(x: -10, y: 8))
        cloakPath.addQuadCurve(to: CGPoint(x: -14, y: -20), control: CGPoint(x: -16, y: -5))
        cloakPath.addQuadCurve(to: CGPoint(x: 14, y: -20), control: CGPoint(x: 0, y: -25))
        cloakPath.addQuadCurve(to: CGPoint(x: 10, y: 8), control: CGPoint(x: 16, y: -5))
        cloakPath.closeSubpath()
        
        let cloak = SKShapeNode(path: cloakPath)
        cloak.fillColor = SKColor(red: 0.25, green: 0.5, blue: 0.3, alpha: 1) // Лесной зелёный
        cloak.strokeColor = SKColor(red: 0.18, green: 0.38, blue: 0.22, alpha: 1)
        cloak.lineWidth = 2
        cloak.zPosition = 0
        character.addChild(cloak)
        
        // === ТЕЛО ===
        let body = SKShapeNode(rectOf: CGSize(width: 16, height: 22), cornerRadius: 4)
        body.fillColor = SKColor(red: 0.55, green: 0.4, blue: 0.28, alpha: 1) // Кожаная куртка
        body.strokeColor = SKColor(red: 0.4, green: 0.28, blue: 0.18, alpha: 1)
        body.lineWidth = 2
        body.position = CGPoint(x: 0, y: -4)
        body.zPosition = 1
        character.addChild(body)
        
        // Ремень
        let belt = SKShapeNode(rectOf: CGSize(width: 18, height: 4), cornerRadius: 1)
        belt.fillColor = SKColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1)
        belt.strokeColor = .clear
        belt.position = CGPoint(x: 0, y: -10)
        belt.zPosition = 2
        character.addChild(belt)
        
        // Пряжка
        let buckle = SKShapeNode(circleOfRadius: 3)
        buckle.fillColor = SKColor(red: 0.85, green: 0.75, blue: 0.4, alpha: 1)
        buckle.strokeColor = SKColor(red: 0.65, green: 0.55, blue: 0.25, alpha: 1)
        buckle.lineWidth = 1
        buckle.position = CGPoint(x: 0, y: -10)
        buckle.zPosition = 3
        character.addChild(buckle)
        
        // === ГОЛОВА ===
        let head = SKShapeNode(circleOfRadius: 11)
        head.fillColor = SKColor(red: 0.95, green: 0.82, blue: 0.72, alpha: 1) // Кожа
        head.strokeColor = SKColor(red: 0.75, green: 0.62, blue: 0.52, alpha: 1)
        head.lineWidth = 1
        head.position = CGPoint(x: 0, y: 18)
        head.zPosition = 5
        character.addChild(head)
        
        // Волосы (длинные, рыжие)
        let hairPath = CGMutablePath()
        hairPath.move(to: CGPoint(x: -12, y: 22))
        hairPath.addQuadCurve(to: CGPoint(x: 0, y: 32), control: CGPoint(x: -8, y: 32))
        hairPath.addQuadCurve(to: CGPoint(x: 12, y: 22), control: CGPoint(x: 8, y: 32))
        hairPath.addLine(to: CGPoint(x: 10, y: 10))
        hairPath.addQuadCurve(to: CGPoint(x: 12, y: -5), control: CGPoint(x: 14, y: 2))
        hairPath.addQuadCurve(to: CGPoint(x: -12, y: -5), control: CGPoint(x: 0, y: -8))
        hairPath.addQuadCurve(to: CGPoint(x: -10, y: 10), control: CGPoint(x: -14, y: 2))
        hairPath.closeSubpath()
        
        let hair = SKShapeNode(path: hairPath)
        hair.fillColor = SKColor(red: 0.85, green: 0.45, blue: 0.2, alpha: 1) // Рыжие волосы
        hair.strokeColor = SKColor(red: 0.65, green: 0.3, blue: 0.12, alpha: 1)
        hair.lineWidth = 1
        hair.position = CGPoint(x: 0, y: 8)
        hair.zPosition = 4
        character.addChild(hair)
        
        // Глаза
        for xOff in [-4, 4] {
            let eyeWhite = SKShapeNode(ellipseOf: CGSize(width: 5, height: 6))
            eyeWhite.fillColor = .white
            eyeWhite.strokeColor = .clear
            eyeWhite.position = CGPoint(x: CGFloat(xOff), y: 19)
            eyeWhite.zPosition = 6
            character.addChild(eyeWhite)
            
            let pupil = SKShapeNode(circleOfRadius: 2)
            pupil.fillColor = SKColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1) // Зелёные глаза
            pupil.strokeColor = .clear
            pupil.position = CGPoint(x: CGFloat(xOff), y: 18)
            pupil.zPosition = 7
            character.addChild(pupil)
        }
        
        // Лёгкая улыбка
        let smilePath = CGMutablePath()
        smilePath.addArc(center: CGPoint(x: 0, y: 14), radius: 4, startAngle: .pi * 0.15, endAngle: .pi * 0.85, clockwise: true)
        let smile = SKShapeNode(path: smilePath)
        smile.strokeColor = SKColor(red: 0.6, green: 0.4, blue: 0.35, alpha: 1)
        smile.lineWidth = 1.5
        smile.lineCap = .round
        smile.zPosition = 7
        character.addChild(smile)
        
        // === ЛУК ===
        let bow = createBow(size: 40)
        bow.position = CGPoint(x: 18, y: 5)
        bow.zPosition = 8
        character.addChild(bow)
        
        // === КОЛЧАН ===
        let quiver = createQuiver()
        quiver.position = CGPoint(x: -12, y: 0)
        quiver.zRotation = 0.2
        quiver.zPosition = -1
        character.addChild(quiver)
        
        return character
    }
    
    // MARK: - Giant (Горный Титан)
    
    static func createGiant(teamColor: SKColor) -> SKNode {
        let character = SKNode()
        
        // === ТЕЛО (Огромное) ===
        let bodyPath = CGMutablePath()
        bodyPath.move(to: CGPoint(x: -22, y: -25))
        bodyPath.addQuadCurve(to: CGPoint(x: 0, y: -30), control: CGPoint(x: -12, y: -32))
        bodyPath.addQuadCurve(to: CGPoint(x: 22, y: -25), control: CGPoint(x: 12, y: -32))
        bodyPath.addLine(to: CGPoint(x: 24, y: 15))
        bodyPath.addQuadCurve(to: CGPoint(x: 0, y: 22), control: CGPoint(x: 16, y: 22))
        bodyPath.addQuadCurve(to: CGPoint(x: -24, y: 15), control: CGPoint(x: -16, y: 22))
        bodyPath.closeSubpath()
        
        let body = SKShapeNode(path: bodyPath)
        body.fillColor = SKColor(red: 0.72, green: 0.55, blue: 0.42, alpha: 1) // Загорелая кожа
        body.strokeColor = SKColor(red: 0.55, green: 0.4, blue: 0.3, alpha: 1)
        body.lineWidth = 3
        body.zPosition = 1
        character.addChild(body)
        
        // Пояс варвара
        let beltPath = CGMutablePath()
        beltPath.addRect(CGRect(x: -24, y: -20, width: 48, height: 8))
        let belt = SKShapeNode(path: beltPath)
        belt.fillColor = SKColor(red: 0.45, green: 0.32, blue: 0.2, alpha: 1)
        belt.strokeColor = SKColor(red: 0.3, green: 0.2, blue: 0.12, alpha: 1)
        belt.lineWidth = 2
        belt.zPosition = 2
        character.addChild(belt)
        
        // Большая пряжка черепа
        let skullBuckle = createSkullBuckle()
        skullBuckle.position = CGPoint(x: 0, y: -16)
        skullBuckle.zPosition = 3
        character.addChild(skullBuckle)
        
        // === ГОЛОВА (Маленькая относительно тела) ===
        let head = SKShapeNode(circleOfRadius: 14)
        head.fillColor = SKColor(red: 0.72, green: 0.55, blue: 0.42, alpha: 1)
        head.strokeColor = SKColor(red: 0.55, green: 0.4, blue: 0.3, alpha: 1)
        head.lineWidth = 2
        head.position = CGPoint(x: 0, y: 32)
        head.zPosition = 5
        character.addChild(head)
        
        // Лысина
        let baldSpot = SKShapeNode(ellipseOf: CGSize(width: 20, height: 12))
        baldSpot.fillColor = SKColor(red: 0.75, green: 0.58, blue: 0.45, alpha: 1)
        baldSpot.strokeColor = .clear
        baldSpot.position = CGPoint(x: 0, y: 38)
        baldSpot.zPosition = 6
        character.addChild(baldSpot)
        
        // Брови (густые, нахмуренные)
        for (xOff, rot) in [(-6, CGFloat(0.3)), (6, CGFloat(-0.3))] {
            let brow = SKShapeNode(rectOf: CGSize(width: 8, height: 3), cornerRadius: 1)
            brow.fillColor = SKColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1)
            brow.strokeColor = .clear
            brow.position = CGPoint(x: CGFloat(xOff), y: 36)
            brow.zRotation = rot
            brow.zPosition = 7
            character.addChild(brow)
        }
        
        // Маленькие глаза
        for xOff in [-5, 5] {
            let eye = SKShapeNode(circleOfRadius: 3)
            eye.fillColor = .black
            eye.strokeColor = .clear
            eye.position = CGPoint(x: CGFloat(xOff), y: 32)
            eye.zPosition = 7
            character.addChild(eye)
        }
        
        // Рот (злой)
        let mouth = SKShapeNode(rectOf: CGSize(width: 12, height: 5), cornerRadius: 2)
        mouth.fillColor = SKColor(red: 0.25, green: 0.15, blue: 0.1, alpha: 1)
        mouth.strokeColor = .clear
        mouth.position = CGPoint(x: 0, y: 24)
        mouth.zPosition = 7
        character.addChild(mouth)
        
        // Клыки
        for xOff in [-4, 4] {
            let fang = SKShapeNode(rectOf: CGSize(width: 3, height: 5), cornerRadius: 1)
            fang.fillColor = .white
            fang.strokeColor = .clear
            fang.position = CGPoint(x: CGFloat(xOff), y: 22)
            fang.zPosition = 8
            character.addChild(fang)
        }
        
        // === КУЛАКИ ===
        for xOff in [-28, 28] {
            let fist = SKShapeNode(circleOfRadius: 12)
            fist.fillColor = SKColor(red: 0.72, green: 0.55, blue: 0.42, alpha: 1)
            fist.strokeColor = SKColor(red: 0.55, green: 0.4, blue: 0.3, alpha: 1)
            fist.lineWidth = 2
            fist.position = CGPoint(x: CGFloat(xOff), y: -5)
            fist.zPosition = 4
            character.addChild(fist)
            
            // Шипованые наручи
            let bracer = SKShapeNode(rectOf: CGSize(width: 16, height: 8), cornerRadius: 2)
            bracer.fillColor = SKColor(red: 0.4, green: 0.35, blue: 0.3, alpha: 1)
            bracer.strokeColor = SKColor(red: 0.3, green: 0.25, blue: 0.2, alpha: 1)
            bracer.lineWidth = 1
            bracer.position = CGPoint(x: CGFloat(xOff), y: 5)
            bracer.zPosition = 5
            character.addChild(bracer)
        }
        
        return character
    }
    
    // MARK: - Goblin (Хитрый Пройдоха)
    
    static func createGoblin(teamColor: SKColor) -> SKNode {
        let character = SKNode()
        
        // === ТЕЛО (Маленькое, худое) ===
        let body = SKShapeNode(rectOf: CGSize(width: 14, height: 18), cornerRadius: 4)
        body.fillColor = SKColor(red: 0.5, green: 0.75, blue: 0.4, alpha: 1) // Зелёная кожа
        body.strokeColor = SKColor(red: 0.35, green: 0.55, blue: 0.28, alpha: 1)
        body.lineWidth = 2
        body.position = CGPoint(x: 0, y: -8)
        body.zPosition = 1
        character.addChild(body)
        
        // Жилетка
        let vest = SKShapeNode(rectOf: CGSize(width: 12, height: 14), cornerRadius: 3)
        vest.fillColor = SKColor(red: 0.5, green: 0.35, blue: 0.25, alpha: 1)
        vest.strokeColor = SKColor(red: 0.35, green: 0.22, blue: 0.15, alpha: 1)
        vest.lineWidth = 1
        vest.position = CGPoint(x: 0, y: -6)
        vest.zPosition = 2
        character.addChild(vest)
        
        // === ГОЛОВА (Большая) ===
        let headPath = CGMutablePath()
        headPath.addEllipse(in: CGRect(x: -14, y: 2, width: 28, height: 24))
        
        let head = SKShapeNode(path: headPath)
        head.fillColor = SKColor(red: 0.5, green: 0.75, blue: 0.4, alpha: 1)
        head.strokeColor = SKColor(red: 0.35, green: 0.55, blue: 0.28, alpha: 1)
        head.lineWidth = 2
        head.zPosition = 3
        character.addChild(head)
        
        // Огромные острые уши
        for (xOff, rot) in [(-16, CGFloat(0.4)), (16, CGFloat(-0.4))] {
            let earPath = CGMutablePath()
            earPath.move(to: CGPoint(x: 0, y: -8))
            earPath.addQuadCurve(to: CGPoint(x: 0, y: 18), control: CGPoint(x: xOff > 0 ? 12 : -12, y: 8))
            earPath.addQuadCurve(to: CGPoint(x: 0, y: -8), control: CGPoint(x: xOff > 0 ? 4 : -4, y: 5))
            
            let ear = SKShapeNode(path: earPath)
            ear.fillColor = SKColor(red: 0.5, green: 0.75, blue: 0.4, alpha: 1)
            ear.strokeColor = SKColor(red: 0.35, green: 0.55, blue: 0.28, alpha: 1)
            ear.lineWidth = 2
            ear.position = CGPoint(x: CGFloat(xOff), y: 12)
            ear.zRotation = rot
            ear.zPosition = 2
            character.addChild(ear)
        }
        
        // Огромные жёлтые глаза
        for xOff in [-6, 6] {
            let eyeWhite = SKShapeNode(ellipseOf: CGSize(width: 10, height: 12))
            eyeWhite.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 1)
            eyeWhite.strokeColor = .clear
            eyeWhite.position = CGPoint(x: CGFloat(xOff), y: 16)
            eyeWhite.zPosition = 4
            character.addChild(eyeWhite)
            
            let pupil = SKShapeNode(ellipseOf: CGSize(width: 4, height: 8))
            pupil.fillColor = SKColor(red: 0.8, green: 0.2, blue: 0.1, alpha: 1) // Красные зрачки
            pupil.strokeColor = .clear
            pupil.position = CGPoint(x: CGFloat(xOff), y: 15)
            pupil.zPosition = 5
            character.addChild(pupil)
        }
        
        // Хитрая ухмылка
        let grinPath = CGMutablePath()
        grinPath.move(to: CGPoint(x: -8, y: 6))
        grinPath.addQuadCurve(to: CGPoint(x: 8, y: 6), control: CGPoint(x: 0, y: -2))
        
        let grin = SKShapeNode(path: grinPath)
        grin.strokeColor = SKColor(red: 0.25, green: 0.15, blue: 0.1, alpha: 1)
        grin.lineWidth = 2
        grin.lineCap = .round
        grin.zPosition = 5
        character.addChild(grin)
        
        // Острые зубы
        for x in stride(from: -6, through: 6, by: 3) {
            let tooth = SKShapeNode(rectOf: CGSize(width: 2, height: 4), cornerRadius: 0.5)
            tooth.fillColor = .white
            tooth.strokeColor = .clear
            tooth.position = CGPoint(x: CGFloat(x), y: 4)
            tooth.zPosition = 6
            character.addChild(tooth)
        }
        
        // === КИНЖАЛЫ (два) ===
        for (xOff, rot) in [(14, CGFloat(-0.5)), (-14, CGFloat(0.5))] {
            let dagger = createDagger()
            dagger.position = CGPoint(x: CGFloat(xOff), y: -5)
            dagger.zRotation = rot
            dagger.zPosition = 7
            character.addChild(dagger)
        }
        
        return character
    }
    
    // MARK: - Wizard (Древний Чародей)
    
    static func createWizard(teamColor: SKColor) -> SKNode {
        let character = SKNode()
        
        // === МАНТИЯ ===
        let robePath = CGMutablePath()
        robePath.move(to: CGPoint(x: -16, y: 10))
        robePath.addLine(to: CGPoint(x: -20, y: -22))
        robePath.addQuadCurve(to: CGPoint(x: 20, y: -22), control: CGPoint(x: 0, y: -28))
        robePath.addLine(to: CGPoint(x: 16, y: 10))
        robePath.closeSubpath()
        
        let robe = SKShapeNode(path: robePath)
        robe.fillColor = SKColor(red: 0.35, green: 0.2, blue: 0.55, alpha: 1) // Фиолетовая мантия
        robe.strokeColor = SKColor(red: 0.25, green: 0.12, blue: 0.4, alpha: 1)
        robe.lineWidth = 2
        robe.zPosition = 1
        character.addChild(robe)
        
        // Узоры на мантии
        for y in stride(from: -18, through: 2, by: 8) {
            let pattern = SKShapeNode(rectOf: CGSize(width: 24, height: 3), cornerRadius: 1)
            pattern.fillColor = SKColor(red: 0.7, green: 0.5, blue: 0.9, alpha: 0.4)
            pattern.strokeColor = .clear
            pattern.position = CGPoint(x: 0, y: CGFloat(y))
            pattern.zPosition = 2
            character.addChild(pattern)
        }
        
        // === ГОЛОВА ===
        let head = SKShapeNode(circleOfRadius: 10)
        head.fillColor = SKColor(red: 0.92, green: 0.82, blue: 0.75, alpha: 1)
        head.strokeColor = SKColor(red: 0.72, green: 0.62, blue: 0.55, alpha: 1)
        head.lineWidth = 1
        head.position = CGPoint(x: 0, y: 20)
        head.zPosition = 5
        character.addChild(head)
        
        // Длинная белая борода
        let beardPath = CGMutablePath()
        beardPath.move(to: CGPoint(x: -8, y: 15))
        beardPath.addQuadCurve(to: CGPoint(x: 0, y: -8), control: CGPoint(x: -10, y: 0))
        beardPath.addQuadCurve(to: CGPoint(x: 8, y: 15), control: CGPoint(x: 10, y: 0))
        beardPath.closeSubpath()
        
        let beard = SKShapeNode(path: beardPath)
        beard.fillColor = SKColor(red: 0.92, green: 0.9, blue: 0.88, alpha: 1)
        beard.strokeColor = SKColor(red: 0.75, green: 0.72, blue: 0.7, alpha: 1)
        beard.lineWidth = 1
        beard.zPosition = 4
        character.addChild(beard)
        
        // Глаза (мудрые, светящиеся)
        for xOff in [-4, 4] {
            let eyeGlow = SKShapeNode(circleOfRadius: 5)
            eyeGlow.fillColor = SKColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 0.4)
            eyeGlow.strokeColor = .clear
            eyeGlow.position = CGPoint(x: CGFloat(xOff), y: 21)
            eyeGlow.zPosition = 6
            character.addChild(eyeGlow)
            
            let eye = SKShapeNode(circleOfRadius: 2.5)
            eye.fillColor = SKColor(red: 0.4, green: 0.75, blue: 1.0, alpha: 1)
            eye.strokeColor = .white
            eye.lineWidth = 0.5
            eye.glowWidth = 4
            eye.position = CGPoint(x: CGFloat(xOff), y: 21)
            eye.zPosition = 7
            character.addChild(eye)
        }
        
        // === ШЛЯПА МАГА ===
        let hat = createWizardHat()
        hat.position = CGPoint(x: 0, y: 32)
        hat.zPosition = 8
        character.addChild(hat)
        
        // === ПОСОХ ===
        let staff = createMagicStaff()
        staff.position = CGPoint(x: 20, y: 0)
        staff.zPosition = 9
        character.addChild(staff)
        
        // Магические частицы вокруг
        for i in 0..<4 {
            let particle = SKShapeNode(circleOfRadius: 3)
            particle.fillColor = SKColor(red: 0.6, green: 0.4, blue: 1.0, alpha: 0.7)
            particle.strokeColor = .clear
            particle.glowWidth = 5
            
            let angle = CGFloat(i) * (.pi / 2)
            particle.position = CGPoint(x: cos(angle) * 25, y: sin(angle) * 25)
            particle.zPosition = 10
            character.addChild(particle)
            
            // Орбитальная анимация
            let orbit = SKAction.customAction(withDuration: 3.0) { node, time in
                let newAngle = angle + (time / 3.0) * .pi * 2
                node.position = CGPoint(x: cos(newAngle) * 25, y: sin(newAngle) * 25 + 5)
                node.alpha = 0.5 + 0.5 * sin(time * 4)
            }
            particle.run(SKAction.repeatForever(orbit))
        }
        
        return character
    }
    
    // MARK: - Dragon (Огненный Змей)
    
    static func createDragon(teamColor: SKColor) -> SKNode {
        let character = SKNode()
        
        // === КРЫЛЬЯ (задний план) ===
        for xOff in [-1, 1] {
            let wing = createDragonWing()
            wing.position = CGPoint(x: CGFloat(xOff) * 20, y: 8)
            wing.xScale = CGFloat(xOff)
            wing.zPosition = 0
            character.addChild(wing)
            
            // Анимация крыльев
            let flapUp = SKAction.rotate(byAngle: CGFloat(xOff) * 0.25, duration: 0.3)
            let flapDown = SKAction.rotate(byAngle: CGFloat(xOff) * -0.25, duration: 0.3)
            wing.run(SKAction.repeatForever(SKAction.sequence([flapUp, flapDown])))
        }
        
        // === ТЕЛО ===
        let bodyPath = CGMutablePath()
        bodyPath.addEllipse(in: CGRect(x: -18, y: -12, width: 36, height: 28))
        
        let body = SKShapeNode(path: bodyPath)
        body.fillColor = SKColor(red: 0.85, green: 0.28, blue: 0.18, alpha: 1) // Красная чешуя
        body.strokeColor = SKColor(red: 0.65, green: 0.18, blue: 0.1, alpha: 1)
        body.lineWidth = 2
        body.zPosition = 1
        character.addChild(body)
        
        // Живот (светлее)
        let belly = SKShapeNode(ellipseOf: CGSize(width: 22, height: 18))
        belly.fillColor = SKColor(red: 0.95, green: 0.75, blue: 0.5, alpha: 1)
        belly.strokeColor = .clear
        belly.position = CGPoint(x: 0, y: -2)
        belly.zPosition = 2
        character.addChild(belly)
        
        // Чешуя (текстура)
        for y in stride(from: -6, through: 8, by: 6) {
            for x in stride(from: -10, through: 10, by: 8) {
                let scale1 = SKShapeNode(ellipseOf: CGSize(width: 6, height: 4))
                scale1.fillColor = SKColor(red: 0.75, green: 0.22, blue: 0.12, alpha: 0.5)
                scale1.strokeColor = .clear
                scale1.position = CGPoint(x: CGFloat(x), y: CGFloat(y))
                scale1.zPosition = 3
                character.addChild(scale1)
            }
        }
        
        // === ГОЛОВА ===
        let headPath = CGMutablePath()
        headPath.addEllipse(in: CGRect(x: -12, y: 12, width: 24, height: 20))
        
        let head = SKShapeNode(path: headPath)
        head.fillColor = SKColor(red: 0.85, green: 0.28, blue: 0.18, alpha: 1)
        head.strokeColor = SKColor(red: 0.65, green: 0.18, blue: 0.1, alpha: 1)
        head.lineWidth = 2
        head.zPosition = 4
        character.addChild(head)
        
        // Рога
        for (xOff, rot) in [(-8, CGFloat(0.4)), (8, CGFloat(-0.4))] {
            let hornPath = CGMutablePath()
            hornPath.move(to: CGPoint(x: 0, y: 0))
            hornPath.addQuadCurve(to: CGPoint(x: 0, y: 18), control: CGPoint(x: xOff > 0 ? 8 : -8, y: 12))
            hornPath.addLine(to: CGPoint(x: xOff > 0 ? -3 : 3, y: 0))
            hornPath.closeSubpath()
            
            let horn = SKShapeNode(path: hornPath)
            horn.fillColor = SKColor(red: 0.25, green: 0.2, blue: 0.18, alpha: 1)
            horn.strokeColor = SKColor(red: 0.15, green: 0.12, blue: 0.1, alpha: 1)
            horn.lineWidth = 1
            horn.position = CGPoint(x: CGFloat(xOff), y: 28)
            horn.zRotation = rot
            horn.zPosition = 5
            character.addChild(horn)
        }
        
        // Глаза (злые, светящиеся)
        for xOff in [-5, 5] {
            let eyeGlow = SKShapeNode(ellipseOf: CGSize(width: 10, height: 6))
            eyeGlow.fillColor = SKColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.5)
            eyeGlow.strokeColor = .clear
            eyeGlow.position = CGPoint(x: CGFloat(xOff), y: 24)
            eyeGlow.zPosition = 5
            character.addChild(eyeGlow)
            
            let eye = SKShapeNode(ellipseOf: CGSize(width: 7, height: 5))
            eye.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1)
            eye.strokeColor = .clear
            eye.position = CGPoint(x: CGFloat(xOff), y: 24)
            eye.zPosition = 6
            character.addChild(eye)
            
            let pupil = SKShapeNode(ellipseOf: CGSize(width: 2, height: 5))
            pupil.fillColor = .black
            pupil.strokeColor = .clear
            pupil.position = CGPoint(x: CGFloat(xOff), y: 24)
            pupil.zPosition = 7
            character.addChild(pupil)
        }
        
        // Ноздри с дымом
        for xOff in [-3, 3] {
            let nostril = SKShapeNode(circleOfRadius: 2)
            nostril.fillColor = SKColor(red: 0.15, green: 0.1, blue: 0.08, alpha: 1)
            nostril.strokeColor = .clear
            nostril.position = CGPoint(x: CGFloat(xOff), y: 16)
            nostril.zPosition = 6
            character.addChild(nostril)
        }
        
        // === ХВОСТ ===
        let tail = createDragonTail()
        tail.position = CGPoint(x: -22, y: -5)
        tail.zPosition = -1
        character.addChild(tail)
        
        // Анимация парения
        let float = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 4, duration: 0.6),
            SKAction.moveBy(x: 0, y: -4, duration: 0.6)
        ])
        character.run(SKAction.repeatForever(float))
        
        return character
    }
    
    // MARK: - Helper Methods
    
    private static func createStar(radius: CGFloat, color: SKColor) -> SKShapeNode {
        let path = CGMutablePath()
        for i in 0..<5 {
            let angle = CGFloat(i) * (4 * .pi / 5) - .pi / 2
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        
        let star = SKShapeNode(path: path)
        star.fillColor = color
        star.strokeColor = .clear
        return star
    }
    
    private static func createSword(length: CGFloat) -> SKNode {
        let sword = SKNode()
        
        // Лезвие
        let bladePath = CGMutablePath()
        bladePath.move(to: CGPoint(x: 0, y: 0))
        bladePath.addLine(to: CGPoint(x: 3, y: length * 0.85))
        bladePath.addLine(to: CGPoint(x: 0, y: length))
        bladePath.addLine(to: CGPoint(x: -3, y: length * 0.85))
        bladePath.closeSubpath()
        
        let blade = SKShapeNode(path: bladePath)
        blade.fillColor = SKColor(red: 0.85, green: 0.88, blue: 0.92, alpha: 1)
        blade.strokeColor = SKColor(red: 0.6, green: 0.62, blue: 0.65, alpha: 1)
        blade.lineWidth = 1
        sword.addChild(blade)
        
        // Блик
        let shine = SKShapeNode(rectOf: CGSize(width: 1.5, height: length * 0.7), cornerRadius: 0.5)
        shine.fillColor = SKColor.white.withAlphaComponent(0.6)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: -1, y: length * 0.45)
        sword.addChild(shine)
        
        // Гарда
        let guard1 = SKShapeNode(rectOf: CGSize(width: 14, height: 4), cornerRadius: 2)
        guard1.fillColor = SKColor(red: 0.75, green: 0.6, blue: 0.25, alpha: 1)
        guard1.strokeColor = SKColor(red: 0.55, green: 0.42, blue: 0.15, alpha: 1)
        guard1.lineWidth = 1
        sword.addChild(guard1)
        
        // Рукоять
        let handle = SKShapeNode(rectOf: CGSize(width: 4, height: 12), cornerRadius: 1)
        handle.fillColor = SKColor(red: 0.4, green: 0.28, blue: 0.15, alpha: 1)
        handle.strokeColor = .clear
        handle.position = CGPoint(x: 0, y: -8)
        sword.addChild(handle)
        
        // Навершие
        let pommel = SKShapeNode(circleOfRadius: 3)
        pommel.fillColor = SKColor(red: 0.75, green: 0.6, blue: 0.25, alpha: 1)
        pommel.strokeColor = .clear
        pommel.position = CGPoint(x: 0, y: -14)
        sword.addChild(pommel)
        
        return sword
    }
    
    private static func createShield(color: SKColor) -> SKNode {
        let shield = SKNode()
        
        let shieldPath = CGMutablePath()
        shieldPath.move(to: CGPoint(x: 0, y: 15))
        shieldPath.addQuadCurve(to: CGPoint(x: 12, y: 5), control: CGPoint(x: 10, y: 14))
        shieldPath.addQuadCurve(to: CGPoint(x: 0, y: -18), control: CGPoint(x: 12, y: -8))
        shieldPath.addQuadCurve(to: CGPoint(x: -12, y: 5), control: CGPoint(x: -12, y: -8))
        shieldPath.addQuadCurve(to: CGPoint(x: 0, y: 15), control: CGPoint(x: -10, y: 14))
        shieldPath.closeSubpath()
        
        let shieldShape = SKShapeNode(path: shieldPath)
        shieldShape.fillColor = color
        shieldShape.strokeColor = color.darker(by: 0.3)
        shieldShape.lineWidth = 2
        shield.addChild(shieldShape)
        
        // Металлический край
        let rim = SKShapeNode(path: shieldPath)
        rim.fillColor = .clear
        rim.strokeColor = SKColor(red: 0.75, green: 0.72, blue: 0.68, alpha: 1)
        rim.lineWidth = 3
        shield.addChild(rim)
        
        // Эмблема
        let emblem = createStar(radius: 6, color: .white)
        emblem.position = CGPoint(x: 0, y: 0)
        shield.addChild(emblem)
        
        return shield
    }
    
    private static func createBow(size: CGFloat) -> SKNode {
        let bow = SKNode()
        
        // Дуга лука
        let bowPath = CGMutablePath()
        bowPath.addArc(center: CGPoint(x: 0, y: 0), radius: size / 2, startAngle: .pi * 0.25, endAngle: .pi * 1.75, clockwise: false)
        
        let bowShape = SKShapeNode(path: bowPath)
        bowShape.strokeColor = SKColor(red: 0.55, green: 0.38, blue: 0.22, alpha: 1)
        bowShape.lineWidth = 5
        bowShape.lineCap = .round
        bow.addChild(bowShape)
        
        // Тетива
        let stringPath = CGMutablePath()
        let startPoint = CGPoint(x: cos(.pi * 0.25) * size / 2, y: sin(.pi * 0.25) * size / 2)
        let endPoint = CGPoint(x: cos(.pi * 1.75) * size / 2, y: sin(.pi * 1.75) * size / 2)
        stringPath.move(to: startPoint)
        stringPath.addLine(to: endPoint)
        
        let string = SKShapeNode(path: stringPath)
        string.strokeColor = SKColor(red: 0.9, green: 0.85, blue: 0.75, alpha: 1)
        string.lineWidth = 1.5
        bow.addChild(string)
        
        // Стрела
        let arrow = SKShapeNode(rectOf: CGSize(width: 2, height: size * 0.8), cornerRadius: 0.5)
        arrow.fillColor = SKColor(red: 0.5, green: 0.38, blue: 0.25, alpha: 1)
        arrow.strokeColor = .clear
        arrow.position = CGPoint(x: size / 4, y: 0)
        bow.addChild(arrow)
        
        // Наконечник стрелы
        let tipPath = CGMutablePath()
        tipPath.move(to: CGPoint(x: 0, y: 8))
        tipPath.addLine(to: CGPoint(x: 4, y: 0))
        tipPath.addLine(to: CGPoint(x: -4, y: 0))
        tipPath.closeSubpath()
        
        let tip = SKShapeNode(path: tipPath)
        tip.fillColor = SKColor(red: 0.7, green: 0.7, blue: 0.75, alpha: 1)
        tip.strokeColor = .clear
        tip.position = CGPoint(x: size / 4, y: size * 0.4)
        bow.addChild(tip)
        
        return bow
    }
    
    private static func createQuiver() -> SKNode {
        let quiver = SKNode()
        
        let quiverShape = SKShapeNode(rectOf: CGSize(width: 8, height: 22), cornerRadius: 3)
        quiverShape.fillColor = SKColor(red: 0.5, green: 0.35, blue: 0.22, alpha: 1)
        quiverShape.strokeColor = SKColor(red: 0.38, green: 0.25, blue: 0.15, alpha: 1)
        quiverShape.lineWidth = 1
        quiver.addChild(quiverShape)
        
        // Стрелы в колчане
        for x in [-2, 0, 2] {
            let arrowFeather = SKShapeNode(rectOf: CGSize(width: 2, height: 6), cornerRadius: 0.5)
            arrowFeather.fillColor = SKColor(red: 0.8, green: 0.25, blue: 0.2, alpha: 1)
            arrowFeather.strokeColor = .clear
            arrowFeather.position = CGPoint(x: CGFloat(x), y: 14)
            quiver.addChild(arrowFeather)
        }
        
        return quiver
    }
    
    private static func createDagger() -> SKNode {
        let dagger = SKNode()
        
        let bladePath = CGMutablePath()
        bladePath.move(to: CGPoint(x: 0, y: 18))
        bladePath.addLine(to: CGPoint(x: 4, y: 0))
        bladePath.addLine(to: CGPoint(x: -4, y: 0))
        bladePath.closeSubpath()
        
        let blade = SKShapeNode(path: bladePath)
        blade.fillColor = SKColor(red: 0.78, green: 0.8, blue: 0.82, alpha: 1)
        blade.strokeColor = SKColor(red: 0.55, green: 0.58, blue: 0.6, alpha: 1)
        blade.lineWidth = 1
        dagger.addChild(blade)
        
        let handle = SKShapeNode(rectOf: CGSize(width: 4, height: 8), cornerRadius: 1)
        handle.fillColor = SKColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1)
        handle.strokeColor = .clear
        handle.position = CGPoint(x: 0, y: -4)
        dagger.addChild(handle)
        
        return dagger
    }
    
    private static func createSkullBuckle() -> SKNode {
        let buckle = SKNode()
        
        // Череп
        let skull = SKShapeNode(circleOfRadius: 6)
        skull.fillColor = SKColor(red: 0.9, green: 0.88, blue: 0.82, alpha: 1)
        skull.strokeColor = SKColor(red: 0.65, green: 0.6, blue: 0.55, alpha: 1)
        skull.lineWidth = 1
        buckle.addChild(skull)
        
        // Глазницы
        for xOff in [-2, 2] {
            let eyeSocket = SKShapeNode(circleOfRadius: 2)
            eyeSocket.fillColor = .black
            eyeSocket.strokeColor = .clear
            eyeSocket.position = CGPoint(x: CGFloat(xOff), y: 1)
            buckle.addChild(eyeSocket)
        }
        
        // Нос
        let nose = SKShapeNode(rectOf: CGSize(width: 2, height: 3), cornerRadius: 0.5)
        nose.fillColor = SKColor(red: 0.3, green: 0.28, blue: 0.25, alpha: 1)
        nose.strokeColor = .clear
        nose.position = CGPoint(x: 0, y: -1)
        buckle.addChild(nose)
        
        return buckle
    }
    
    private static func createWizardHat() -> SKNode {
        let hat = SKNode()
        
        // Конус
        let conePath = CGMutablePath()
        conePath.move(to: CGPoint(x: 0, y: 35))
        conePath.addQuadCurve(to: CGPoint(x: -18, y: 0), control: CGPoint(x: -8, y: 15))
        conePath.addLine(to: CGPoint(x: 18, y: 0))
        conePath.addQuadCurve(to: CGPoint(x: 0, y: 35), control: CGPoint(x: 8, y: 15))
        conePath.closeSubpath()
        
        let cone = SKShapeNode(path: conePath)
        cone.fillColor = SKColor(red: 0.3, green: 0.15, blue: 0.5, alpha: 1)
        cone.strokeColor = SKColor(red: 0.2, green: 0.1, blue: 0.35, alpha: 1)
        cone.lineWidth = 2
        hat.addChild(cone)
        
        // Поля шляпы
        let brim = SKShapeNode(ellipseOf: CGSize(width: 45, height: 12))
        brim.fillColor = SKColor(red: 0.3, green: 0.15, blue: 0.5, alpha: 1)
        brim.strokeColor = SKColor(red: 0.2, green: 0.1, blue: 0.35, alpha: 1)
        brim.lineWidth = 2
        brim.position = CGPoint(x: 0, y: -2)
        hat.addChild(brim)
        
        // Звёзды на шляпе
        let starPositions = [(x: -5, y: 12), (x: 4, y: 22), (x: -2, y: 28)]
        for pos in starPositions {
            let star = createStar(radius: 3, color: SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 1))
            star.position = CGPoint(x: CGFloat(pos.x), y: CGFloat(pos.y))
            star.glowWidth = 3
            hat.addChild(star)
        }
        
        // Лента
        let ribbon = SKShapeNode(rectOf: CGSize(width: 20, height: 5), cornerRadius: 1)
        ribbon.fillColor = SKColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 1)
        ribbon.strokeColor = .clear
        ribbon.position = CGPoint(x: 0, y: 4)
        hat.addChild(ribbon)
        
        return hat
    }
    
    private static func createMagicStaff() -> SKNode {
        let staff = SKNode()
        
        // Древко
        let shaft = SKShapeNode(rectOf: CGSize(width: 5, height: 55), cornerRadius: 2)
        shaft.fillColor = SKColor(red: 0.45, green: 0.32, blue: 0.2, alpha: 1)
        shaft.strokeColor = SKColor(red: 0.32, green: 0.22, blue: 0.12, alpha: 1)
        shaft.lineWidth = 1
        staff.addChild(shaft)
        
        // Кристалл
        let crystalPath = CGMutablePath()
        crystalPath.move(to: CGPoint(x: 0, y: 15))
        crystalPath.addLine(to: CGPoint(x: 8, y: 0))
        crystalPath.addLine(to: CGPoint(x: 0, y: -15))
        crystalPath.addLine(to: CGPoint(x: -8, y: 0))
        crystalPath.closeSubpath()
        
        let crystal = SKShapeNode(path: crystalPath)
        crystal.fillColor = SKColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 1)
        crystal.strokeColor = SKColor(red: 0.35, green: 0.6, blue: 0.85, alpha: 1)
        crystal.lineWidth = 2
        crystal.glowWidth = 10
        crystal.position = CGPoint(x: 0, y: 38)
        staff.addChild(crystal)
        
        // Свечение
        let glow = SKShapeNode(circleOfRadius: 15)
        glow.fillColor = SKColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 0.3)
        glow.strokeColor = .clear
        glow.position = CGPoint(x: 0, y: 38)
        glow.zPosition = -1
        staff.addChild(glow)
        
        // Анимация пульсации
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.8),
            SKAction.scale(to: 1.0, duration: 0.8)
        ])
        glow.run(SKAction.repeatForever(pulse))
        
        return staff
    }
    
    private static func createDragonWing() -> SKNode {
        let wing = SKNode()
        
        let wingPath = CGMutablePath()
        wingPath.move(to: CGPoint(x: 0, y: 0))
        wingPath.addQuadCurve(to: CGPoint(x: -30, y: 20), control: CGPoint(x: -20, y: 25))
        wingPath.addQuadCurve(to: CGPoint(x: -25, y: 5), control: CGPoint(x: -30, y: 12))
        wingPath.addQuadCurve(to: CGPoint(x: -18, y: -8), control: CGPoint(x: -25, y: -2))
        wingPath.addQuadCurve(to: CGPoint(x: 0, y: 0), control: CGPoint(x: -10, y: -5))
        wingPath.closeSubpath()
        
        let wingShape = SKShapeNode(path: wingPath)
        wingShape.fillColor = SKColor(red: 0.78, green: 0.25, blue: 0.15, alpha: 0.9)
        wingShape.strokeColor = SKColor(red: 0.58, green: 0.18, blue: 0.1, alpha: 1)
        wingShape.lineWidth = 2
        wing.addChild(wingShape)
        
        // Перепонки
        let membrane = SKShapeNode(path: wingPath)
        membrane.fillColor = SKColor(red: 0.92, green: 0.6, blue: 0.45, alpha: 0.5)
        membrane.strokeColor = .clear
        wing.addChild(membrane)
        
        return wing
    }
    
    private static func createDragonTail() -> SKNode {
        let tail = SKNode()
        
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: 0, y: 5))
        tailPath.addQuadCurve(to: CGPoint(x: -25, y: 3), control: CGPoint(x: -12, y: 10))
        tailPath.addQuadCurve(to: CGPoint(x: -35, y: 8), control: CGPoint(x: -30, y: 5))
        tailPath.addLine(to: CGPoint(x: -32, y: 3)) // Шип
        tailPath.addQuadCurve(to: CGPoint(x: -25, y: -3), control: CGPoint(x: -28, y: 0))
        tailPath.addQuadCurve(to: CGPoint(x: 0, y: -5), control: CGPoint(x: -12, y: -10))
        tailPath.closeSubpath()
        
        let tailShape = SKShapeNode(path: tailPath)
        tailShape.fillColor = SKColor(red: 0.85, green: 0.28, blue: 0.18, alpha: 1)
        tailShape.strokeColor = SKColor(red: 0.65, green: 0.18, blue: 0.1, alpha: 1)
        tailShape.lineWidth = 2
        tail.addChild(tailShape)
        
        // Анимация хвоста
        let sway = SKAction.sequence([
            SKAction.rotate(byAngle: 0.15, duration: 0.5),
            SKAction.rotate(byAngle: -0.15, duration: 0.5)
        ])
        tail.run(SKAction.repeatForever(sway))
        
        return tail
    }
}

// MARK: - SKColor Extension

extension SKColor {
    func darker(by percentage: CGFloat) -> SKColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return SKColor(red: max(r - percentage, 0),
                       green: max(g - percentage, 0),
                       blue: max(b - percentage, 0),
                       alpha: a)
    }
}
