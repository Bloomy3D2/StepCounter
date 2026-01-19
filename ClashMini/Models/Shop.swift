//
//  Shop.swift
//  ClashMini
//
//  Система магазина и внутриигровых покупок
//

import Foundation
import SwiftUI

// MARK: - Валюта

/// Типы валюты в игре
enum CurrencyType {
    case gold       // Обычная валюта (зарабатывается в игре)
    case gems       // Премиум валюта (покупается за реальные деньги)
}

// MARK: - Товары магазина

/// Типы товаров
enum ShopItemType: String, CaseIterable {
    case gemPack        // Пакет гемов
    case goldPack       // Пакет золота
    case booster        // Бустер/усиление
    case chest          // Сундук с картами
    case specialOffer   // Специальное предложение
}

/// Бустеры (усиления)
enum BoosterType: String, CaseIterable, Identifiable {
    case doubleElixir       // Начать с двойным эликсиром
    case extraHealth        // +50% здоровья башен
    case strongUnits        // +25% урона юнитов
    case fastElixir         // +50% скорость регенерации эликсира
    case extraCard          // +1 карта в руке
    case shield             // Щит на главную башню (блокирует 100 урона)
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .doubleElixir: return "Двойной Эликсир"
        case .extraHealth: return "Крепкие Башни"
        case .strongUnits: return "Мощная Армия"
        case .fastElixir: return "Быстрый Эликсир"
        case .extraCard: return "Дополнительная Карта"
        case .shield: return "Королевский Щит"
        }
    }
    
    var description: String {
        switch self {
        case .doubleElixir: return "Начните битву с 10 эликсиром вместо 5"
        case .extraHealth: return "+50% здоровья всех ваших башен"
        case .strongUnits: return "+25% урона всех ваших юнитов"
        case .fastElixir: return "+50% скорость регенерации эликсира"
        case .extraCard: return "Видите 5 карт вместо 4 в руке"
        case .shield: return "Ваша главная башня блокирует первые 100 урона"
        }
    }
    
    var icon: String {
        switch self {
        case .doubleElixir: return "⚗️"
        case .extraHealth: return "🛡️"
        case .strongUnits: return "⚔️"
        case .fastElixir: return "⚡"
        case .extraCard: return "🃏"
        case .shield: return "🏰"
        }
    }
    
    var gemPrice: Int {
        switch self {
        case .doubleElixir: return 15
        case .extraHealth: return 25
        case .strongUnits: return 30
        case .fastElixir: return 20
        case .extraCard: return 10
        case .shield: return 35
        }
    }
    
    var goldPrice: Int {
        switch self {
        case .doubleElixir: return 150
        case .extraHealth: return 250
        case .strongUnits: return 300
        case .fastElixir: return 200
        case .extraCard: return 100
        case .shield: return 350
        }
    }
    
    var color: Color {
        switch self {
        case .doubleElixir: return .purple
        case .extraHealth: return .green
        case .strongUnits: return .red
        case .fastElixir: return .yellow
        case .extraCard: return .blue
        case .shield: return .cyan
        }
    }
}

/// Пакеты гемов для покупки
enum GemPack: String, CaseIterable, Identifiable {
    case tiny       // 80 гемов
    case small      // 500 гемов
    case medium     // 1200 гемов
    case large      // 2500 гемов
    case huge       // 6500 гемов
    case mega       // 14000 гемов
    
    var id: String { rawValue }
    
    var gems: Int {
        switch self {
        case .tiny: return 80
        case .small: return 500
        case .medium: return 1200
        case .large: return 2500
        case .huge: return 6500
        case .mega: return 14000
        }
    }
    
    var bonusGems: Int {
        switch self {
        case .tiny: return 0
        case .small: return 50
        case .medium: return 200
        case .large: return 500
        case .huge: return 1500
        case .mega: return 4000
        }
    }
    
    var totalGems: Int { gems + bonusGems }
    
    var priceUSD: Double {
        switch self {
        case .tiny: return 0.99
        case .small: return 4.99
        case .medium: return 9.99
        case .large: return 19.99
        case .huge: return 49.99
        case .mega: return 99.99
        }
    }
    
    var name: String {
        switch self {
        case .tiny: return "Горсть Гемов"
        case .small: return "Мешочек Гемов"
        case .medium: return "Сундук Гемов"
        case .large: return "Сокровище"
        case .huge: return "Королевская Казна"
        case .mega: return "Легендарное Богатство"
        }
    }
    
    var icon: String {
        switch self {
        case .tiny: return "💎"
        case .small: return "💎💎"
        case .medium: return "💰"
        case .large: return "👑"
        case .huge: return "🏆"
        case .mega: return "⭐"
        }
    }
}

/// Специальные предложения
struct SpecialOffer: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let gems: Int
    let gold: Int
    let boosters: [BoosterType]
    let originalPrice: Double
    let discountedPrice: Double
    let discountPercent: Int
    let expiresIn: TimeInterval
    let icon: String
    
    static let dailyDeal = SpecialOffer(
        name: "Ежедневная Сделка",
        description: "Отличный набор для начинающего!",
        gems: 100,
        gold: 1000,
        boosters: [.doubleElixir, .extraCard],
        originalPrice: 9.99,
        discountedPrice: 2.99,
        discountPercent: 70,
        expiresIn: 86400,
        icon: "🌟"
    )
    
    static let starterPack = SpecialOffer(
        name: "Стартовый Набор",
        description: "Идеальный старт для новых игроков!",
        gems: 500,
        gold: 5000,
        boosters: [.extraHealth, .strongUnits, .shield],
        originalPrice: 29.99,
        discountedPrice: 4.99,
        discountPercent: 83,
        expiresIn: 259200,
        icon: "🚀"
    )
    
    static let legendaryBundle = SpecialOffer(
        name: "Легендарный Бандл",
        description: "Максимум преимуществ!",
        gems: 2000,
        gold: 20000,
        boosters: BoosterType.allCases,
        originalPrice: 99.99,
        discountedPrice: 19.99,
        discountPercent: 80,
        expiresIn: 604800,
        icon: "👑"
    )
}

// MARK: - Менеджер магазина

/// Менеджер магазина и валюты
final class ShopManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = ShopManager()
    
    // MARK: - Published
    @Published var gems: Int = 50          // Начальные гемы
    @Published var gold: Int = 500         // Начальное золото
    @Published var ownedBoosters: [BoosterType: Int] = [:]
    @Published var activeBoosters: Set<BoosterType> = []
    
    // Специальные предложения
    @Published var specialOffers: [SpecialOffer] = [
        .dailyDeal,
        .starterPack,
        .legendaryBundle
    ]
    
    // История покупок
    @Published var purchaseHistory: [PurchaseRecord] = []
    
    // MARK: - Init
    private init() {
        loadData()
    }
    
    // MARK: - Валюта
    
    func addGems(_ amount: Int) {
        gems += amount
        saveData()
    }
    
    func addGold(_ amount: Int) {
        gold += amount
        saveData()
    }
    
    func spendGems(_ amount: Int) -> Bool {
        guard gems >= amount else { return false }
        gems -= amount
        saveData()
        return true
    }
    
    func spendGold(_ amount: Int) -> Bool {
        guard gold >= amount else { return false }
        gold -= amount
        saveData()
        return true
    }
    
    // MARK: - Бустеры
    
    func buyBooster(_ booster: BoosterType, withGems: Bool) -> Bool {
        let price = withGems ? booster.gemPrice : booster.goldPrice
        let success = withGems ? spendGems(price) : spendGold(price)
        
        if success {
            ownedBoosters[booster, default: 0] += 1
            
            let record = PurchaseRecord(
                itemName: booster.name,
                price: price,
                currency: withGems ? .gems : .gold,
                date: Date()
            )
            purchaseHistory.append(record)
            saveData()
            return true
        }
        return false
    }
    
    func useBooster(_ booster: BoosterType) -> Bool {
        guard let count = ownedBoosters[booster], count > 0 else { return false }
        
        ownedBoosters[booster] = count - 1
        if ownedBoosters[booster] == 0 {
            ownedBoosters.removeValue(forKey: booster)
        }
        
        activeBoosters.insert(booster)
        saveData()
        return true
    }
    
    func deactivateAllBoosters() {
        activeBoosters.removeAll()
    }
    
    func hasBooster(_ booster: BoosterType) -> Bool {
        return (ownedBoosters[booster] ?? 0) > 0
    }
    
    func boosterCount(_ booster: BoosterType) -> Int {
        return ownedBoosters[booster] ?? 0
    }
    
    func isBoosterActive(_ booster: BoosterType) -> Bool {
        return activeBoosters.contains(booster)
    }
    
    // MARK: - Покупка гемов (симуляция IAP)
    
    func purchaseGemPack(_ pack: GemPack, completion: @escaping (Bool) -> Void) {
        // Симуляция покупки (в реальном приложении тут будет StoreKit)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // Добавляем гемы
            self.gems += pack.totalGems
            
            let record = PurchaseRecord(
                itemName: pack.name,
                price: Int(pack.priceUSD * 100), // центы
                currency: .gems,
                date: Date(),
                isRealMoney: true
            )
            self.purchaseHistory.append(record)
            self.saveData()
            
            completion(true)
        }
    }
    
    // MARK: - Специальные предложения
    
    func purchaseSpecialOffer(_ offer: SpecialOffer, completion: @escaping (Bool) -> Void) {
        // Симуляция покупки
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            self.gems += offer.gems
            self.gold += offer.gold
            
            for booster in offer.boosters {
                self.ownedBoosters[booster, default: 0] += 1
            }
            
            // Удаляем предложение после покупки
            self.specialOffers.removeAll { $0.id == offer.id }
            
            let record = PurchaseRecord(
                itemName: offer.name,
                price: Int(offer.discountedPrice * 100),
                currency: .gems,
                date: Date(),
                isRealMoney: true
            )
            self.purchaseHistory.append(record)
            self.saveData()
            
            completion(true)
        }
    }
    
    // MARK: - Награды за победу
    
    func rewardForVictory(crowns: Int) {
        let goldReward = 50 + (crowns * 25)
        let gemChance = Double(crowns) * 0.1 // 10-30% шанс получить гем
        
        gold += goldReward
        
        if Double.random(in: 0...1) < gemChance {
            gems += 1
        }
        
        saveData()
    }
    
    // MARK: - Persistence
    
    private func saveData() {
        UserDefaults.standard.set(gems, forKey: "shop_gems")
        UserDefaults.standard.set(gold, forKey: "shop_gold")
        
        // Сохраняем бустеры
        let boosterData = ownedBoosters.mapKeys { $0.rawValue }
        UserDefaults.standard.set(boosterData, forKey: "shop_boosters")
    }
    
    private func loadData() {
        gems = UserDefaults.standard.integer(forKey: "shop_gems")
        gold = UserDefaults.standard.integer(forKey: "shop_gold")
        
        if gems == 0 && gold == 0 {
            // Первый запуск — даём начальные ресурсы
            gems = 50
            gold = 500
        }
        
        if let boosterData = UserDefaults.standard.dictionary(forKey: "shop_boosters") as? [String: Int] {
            ownedBoosters = boosterData.compactMapKeys { BoosterType(rawValue: $0) }
        }
    }
}

// MARK: - Запись о покупке

struct PurchaseRecord: Identifiable {
    let id = UUID()
    let itemName: String
    let price: Int
    let currency: CurrencyType
    let date: Date
    var isRealMoney: Bool = false
}

// MARK: - Dictionary Extensions

extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        var result = [T: Value]()
        for (key, value) in self {
            result[transform(key)] = value
        }
        return result
    }
    
    func compactMapKeys<T: Hashable>(_ transform: (Key) -> T?) -> [T: Value] {
        var result = [T: Value]()
        for (key, value) in self {
            if let newKey = transform(key) {
                result[newKey] = value
            }
        }
        return result
    }
}
