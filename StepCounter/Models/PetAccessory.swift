//
//  PetAccessory.swift
//  StepCounter
//
//  Аксессуары для питомца
//

import Foundation
import SwiftUI

/// Тип аксессуара
enum AccessoryType: String, Codable, CaseIterable {
    // Головные уборы (от простых к премиум)
    case cap = "cap"                    // Базовый
    case beanie = "beanie"               // Зимний стиль
    case sunglasses = "sunglasses"      // Крутой вид
    case bandana = "bandana"            // Бунтарский стиль
    case partyHat = "party_hat"         // Праздничный
    case crown = "crown"                // Королевский (Premium)
    case wizardHat = "wizard_hat"       // Магический (Premium)
    
    // Шейные аксессуары
    case bowtie = "bowtie"              // Элегантный
    case scarf = "scarf"                // Уютный
    case tie = "tie"                    // Деловой
    case necklace = "necklace"          // Украшение (Premium)
    
    // Нагрудные аксессуары
    case medal = "medal"                // Награда (Premium)
    case badge = "badge"                // Значок (Premium)
    case heartPin = "heart_pin"         // Сердечко (Premium)
    
    var name: String {
        switch self {
        // Головные уборы
        case .cap: return "Бейсболка"
        case .beanie: return "Бини"
        case .sunglasses: return "Солнечные очки"
        case .bandana: return "Бандана"
        case .partyHat: return "Праздничная шляпа"
        case .crown: return "Золотая корона"
        case .wizardHat: return "Шляпа мага"
        
        // Шейные аксессуары
        case .bowtie: return "Бабочка"
        case .scarf: return "Шарф"
        case .tie: return "Галстук"
        case .necklace: return "Ожерелье"
        
        // Нагрудные аксессуары
        case .medal: return "Золотая медаль"
        case .badge: return "Боевой значок"
        case .heartPin: return "Брошь-сердечко"
        }
    }
    
    var emoji: String {
        switch self {
        // Головные уборы
        case .cap: return "🧢"
        case .beanie: return "🎩"
        case .sunglasses: return "🕶️"
        case .bandana: return "🤠"
        case .partyHat: return "🎉"
        case .crown: return "👑"
        case .wizardHat: return "🧙‍♂️"
        
        // Шейные аксессуары
        case .bowtie: return "🎀"
        case .scarf: return "🧣"
        case .tie: return "👔"
        case .necklace: return "💎"
        
        // Нагрудные аксессуары
        case .medal: return "🏅"
        case .badge: return "🎖️"
        case .heartPin: return "💖"
        }
    }
    
    var description: String {
        switch self {
        // Головные уборы
        case .cap: return "Спортивный стиль"
        case .beanie: return "Уютная шапочка"
        case .sunglasses: return "Крутой вид"
        case .bandana: return "Бунтарский стиль"
        case .partyHat: return "Готов к вечеринке!"
        case .crown: return "Королевское достоинство"
        case .wizardHat: return "Магическая сила"
        
        // Шейные аксессуары
        case .bowtie: return "Элегантность"
        case .scarf: return "Уют и тепло"
        case .tie: return "Деловой стиль"
        case .necklace: return "Роскошь и блеск"
        
        // Нагрудные аксессуары
        case .medal: return "За достижения"
        case .badge: return "Боевая слава"
        case .heartPin: return "Любовь и нежность"
        }
    }
    
    var category: AccessoryCategory {
        switch self {
        // Головные уборы
        case .cap, .crown, .beanie, .sunglasses, .bandana, .partyHat, .wizardHat:
            return .head
        // Шейные аксессуары
        case .scarf, .bowtie, .tie, .necklace:
            return .neck
        // Нагрудные аксессуары
        case .medal, .badge, .heartPin:
            return .chest
        }
    }
    
    var unlockRequirement: Int {
        switch self {
        // Головные уборы (прогрессия)
        case .cap: return 10000          // Первый аксессуар
        case .beanie: return 25000        // Зимний стиль
        case .sunglasses: return 50000    // Крутой вид
        case .bandana: return 75000       // Бунтарский
        case .partyHat: return 100000     // Праздничный
        case .crown: return 500000        // Королевский (Premium)
        case .wizardHat: return 400000     // Магический (Premium)
        
        // Шейные аксессуары
        case .bowtie: return 120000       // Элегантный
        case .scarf: return 150000        // Уютный
        case .tie: return 200000          // Деловой
        case .necklace: return 350000      // Роскошный (Premium)
        
        // Нагрудные аксессуары
        case .medal: return 300000         // Награда (Premium)
        case .badge: return 450000         // Боевой (Premium)
        case .heartPin: return 250000      // Любовь (Premium)
        }
    }
    
    /// Является ли аксессуар Premium (доступен только для Premium)
    var isPremium: Bool {
        switch self {
        case .crown, .wizardHat, .necklace, .medal, .badge, .heartPin:
            return true // Эксклюзивные премиум аксессуары
        default:
            return false
        }
    }
    
    var color: Color {
        switch self {
        // Головные уборы
        case .cap: return .blue
        case .beanie: return .red
        case .sunglasses: return .black
        case .bandana: return .purple
        case .partyHat: return .pink
        case .crown: return .yellow
        case .wizardHat: return .purple
        
        // Шейные аксессуары
        case .bowtie: return .pink
        case .scarf: return .orange
        case .tie: return .gray
        case .necklace: return .cyan
        
        // Нагрудные аксессуары
        case .medal: return .yellow
        case .badge: return .blue
        case .heartPin: return .pink
        }
    }
    
    /// Редкость аксессуара (для визуального отображения)
    var rarity: AccessoryRarity {
        switch self {
        case .cap, .beanie:
            return .common
        case .sunglasses, .bandana, .bowtie, .scarf:
            return .uncommon
        case .partyHat, .tie:
            return .rare
        case .wizardHat, .necklace, .heartPin:
            return .epic
        case .crown, .medal, .badge:
            return .legendary
        }
    }
}

enum AccessoryCategory: String, Codable {
    case head
    case neck
    case chest
}

/// Редкость аксессуара
enum AccessoryRarity: String, Codable {
    case common = "common"           // Обычный
    case uncommon = "uncommon"       // Необычный
    case rare = "rare"               // Редкий
    case epic = "epic"               // Эпический
    case legendary = "legendary"     // Легендарный
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .yellow
        }
    }
    
    var name: String {
        switch self {
        case .common: return "Обычный"
        case .uncommon: return "Необычный"
        case .rare: return "Редкий"
        case .epic: return "Эпический"
        case .legendary: return "Легендарный"
        }
    }
}

/// Аксессуар
struct PetAccessory: Identifiable, Codable {
    let id: String
    let type: AccessoryType
    var isUnlocked: Bool
    var unlockedDate: Date?
    
    init(type: AccessoryType) {
        self.id = type.rawValue
        self.type = type
        self.isUnlocked = false
        self.unlockedDate = nil
    }
}
