//
//  Card.swift
//  ClashMini
//
//  Модель карты юнита
//

import Foundation
import SpriteKit

/// Тип карты
enum CardType: String, CaseIterable {
    case knight = "Рыцарь"
    case archer = "Лучница"
    case giant = "Великан"
    case goblin = "Гоблин"
    case wizard = "Маг"
    case dragon = "Дракон"
    
    /// Стоимость эликсира
    var elixirCost: Int {
        switch self {
        case .knight: return 3
        case .archer: return 3
        case .giant: return 5
        case .goblin: return 2
        case .wizard: return 5
        case .dragon: return 4
        }
    }
    
    /// Здоровье юнита
    var health: Int {
        switch self {
        case .knight: return 100
        case .archer: return 50
        case .giant: return 200
        case .goblin: return 30
        case .wizard: return 60
        case .dragon: return 80
        }
    }
    
    /// Урон юнита
    var damage: Int {
        switch self {
        case .knight: return 15
        case .archer: return 12
        case .giant: return 20
        case .goblin: return 8
        case .wizard: return 25
        case .dragon: return 18
        }
    }
    
    /// Скорость атаки (секунды между атаками)
    var attackSpeed: TimeInterval {
        switch self {
        case .knight: return 1.2
        case .archer: return 1.0
        case .giant: return 1.5
        case .goblin: return 0.8
        case .wizard: return 1.8
        case .dragon: return 1.3
        }
    }
    
    /// Скорость движения
    var moveSpeed: CGFloat {
        switch self {
        case .knight: return 60
        case .archer: return 50
        case .giant: return 35
        case .goblin: return 80
        case .wizard: return 45
        case .dragon: return 70
        }
    }
    
    /// Дальность атаки
    var attackRange: CGFloat {
        switch self {
        case .knight: return 30
        case .archer: return 120
        case .giant: return 30
        case .goblin: return 25
        case .wizard: return 100
        case .dragon: return 90
        }
    }
    
    /// Эмодзи для отображения
    var emoji: String {
        switch self {
        case .knight: return "⚔️"
        case .archer: return "🏹"
        case .giant: return "👊"
        case .goblin: return "👺"
        case .wizard: return "🧙"
        case .dragon: return "🐉"
        }
    }
    
    /// Цвет карты
    var color: SKColor {
        switch self {
        case .knight: return SKColor(red: 0.7, green: 0.7, blue: 0.8, alpha: 1)
        case .archer: return SKColor(red: 0.6, green: 0.8, blue: 0.6, alpha: 1)
        case .giant: return SKColor(red: 0.8, green: 0.6, blue: 0.5, alpha: 1)
        case .goblin: return SKColor(red: 0.5, green: 0.8, blue: 0.5, alpha: 1)
        case .wizard: return SKColor(red: 0.7, green: 0.5, blue: 0.9, alpha: 1)
        case .dragon: return SKColor(red: 0.9, green: 0.5, blue: 0.4, alpha: 1)
        }
    }
    
    /// Описание карты
    var description: String {
        switch self {
        case .knight: return "Универсальный боец ближнего боя"
        case .archer: return "Стреляет издалека, но хрупкая"
        case .giant: return "Много здоровья, атакует башни"
        case .goblin: return "Быстрый, но слабый"
        case .wizard: return "Мощные заклинания по площади"
        case .dragon: return "Летает и дышит огнём"
        }
    }
}

/// Модель карты в колоде
struct Card: Identifiable, Equatable {
    let id = UUID()
    let type: CardType
    
    var name: String { type.rawValue }
    var elixirCost: Int { type.elixirCost }
    var emoji: String { type.emoji }
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        lhs.id == rhs.id
    }
}

/// Колода игрока
struct Deck {
    var cards: [Card]
    var handCards: [Card] = []
    var nextCard: Card?
    
    init(cardTypes: [CardType]) {
        self.cards = cardTypes.map { Card(type: $0) }
        shuffleAndDraw()
    }
    
    mutating func shuffleAndDraw() {
        cards.shuffle()
        handCards = Array(cards.prefix(4))
        nextCard = cards.count > 4 ? cards[4] : nil
    }
    
    mutating func playCard(_ card: Card) -> Card? {
        guard let index = handCards.firstIndex(of: card) else { return nil }
        handCards.remove(at: index)
        
        if let next = nextCard {
            handCards.append(next)
        }
        
        // Получаем новую карту из колоды
        let usedCards = handCards + [card]
        let availableCards = cards.filter { cardInDeck in
            !usedCards.contains { $0.type == cardInDeck.type }
        }
        
        if let randomCard = availableCards.randomElement() {
            nextCard = randomCard
        } else {
            nextCard = cards.randomElement()
        }
        
        return card
    }
}
