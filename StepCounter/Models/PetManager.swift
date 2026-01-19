//
//  PetManager.swift
//  StepCounter
//
//  Виртуальный питомец (Тамагочи)
//

import Foundation
import SwiftUI

/// Тип питомца
enum PetType: String, Codable, CaseIterable {
    case poodle = "dog"  // Используем старый rawValue для совместимости
    case cat = "cat"
    case rabbit = "rabbit"
    case fox = "fox"
    case penguin = "penguin"

    /// Требуется ли Premium для выбора этого питомца.
    /// Базовый питомец (free) — котик.
    var requiresPremium: Bool { self != .cat }
    
    var name: String {
        switch self {
        case .poodle: return "Пудель"
        case .cat: return "Котик"
        case .rabbit: return "Зайчик"
        case .fox: return "Лисичка"
        case .penguin: return "Пингвинчик"
        }
    }
    
    var emoji: String {
        switch self {
        case .poodle: return "🐩"
        case .cat: return "🐱"
        case .rabbit: return "🐰"
        case .fox: return "🦊"
        case .penguin: return "🐧"
        }
    }
    
    var evolutions: [PetEvolution] {
        switch self {
        case .poodle: return [.baby, .teen, .adult, .champion, .legend]
        case .cat: return [.baby, .teen, .adult, .champion, .legend]
        case .rabbit: return [.baby, .teen, .adult, .champion, .legend]
        case .fox: return [.baby, .teen, .adult, .champion, .legend]
        case .penguin: return [.baby, .teen, .adult, .champion, .legend]
        }
    }
    
    var color: Color {
        switch self {
        case .poodle: return .brown
        case .cat: return .orange
        case .rabbit: return .white
        case .fox: return .orange
        case .penguin: return .black
        }
    }
}

/// Стадия эволюции
enum PetEvolution: String, Codable, CaseIterable {
    case baby = "baby"
    case teen = "teen"
    case adult = "adult"
    case champion = "champion"
    case legend = "legend"
    
    var name: String {
        switch self {
        case .baby: return "Малыш"
        case .teen: return "Подросток"
        case .adult: return "Взрослый"
        case .champion: return "Чемпион"
        case .legend: return "Легенда"
        }
    }
    
    var requiredXP: Int {
        switch self {
        case .baby: return 0
        case .teen: return 10000
        case .adult: return 50000
        case .champion: return 150000
        case .legend: return 500000
        }
    }
    
    var size: CGFloat {
        switch self {
        case .baby: return 60
        case .teen: return 80
        case .adult: return 100
        case .champion: return 120
        case .legend: return 140
        }
    }
}

/// Настроение питомца
enum PetMood: String, Codable {
    case ecstatic = "ecstatic"
    case happy = "happy"
    case content = "content"
    case sad = "sad"
    case tired = "tired"
    
    var emoji: String {
        switch self {
        case .ecstatic: return "🤩"
        case .happy: return "😊"
        case .content: return "😐"
        case .sad: return "😢"
        case .tired: return "😴"
        }
    }
    
    var message: String {
        switch self {
        case .ecstatic: return "Невероятно! Я так счастлив!"
        case .happy: return "Отличная прогулка!"
        case .content: return "Неплохо, но хочу гулять!"
        case .sad: return "Мне скучно... Пойдём гулять?"
        case .tired: return "Давно не гуляли... Zzz"
        }
    }
    
    var color: Color {
        switch self {
        case .ecstatic: return .yellow
        case .happy: return .green
        case .content: return .blue
        case .sad: return .orange
        case .tired: return .gray
        }
    }
}

/// Питомец
struct Pet: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: PetType
    var evolution: PetEvolution
    var totalXP: Int
    var todaySteps: Int
    var lastFedDate: Date
    var createdDate: Date
    var accessories: [String]
    
    init(name: String, type: PetType) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.evolution = .baby
        self.totalXP = 0
        self.todaySteps = 0
        self.lastFedDate = Date()
        self.createdDate = Date()
        self.accessories = []
    }
    
    var mood: PetMood {
        let hoursSinceLastFed = Date().timeIntervalSince(lastFedDate) / 3600
        
        if todaySteps >= 15000 { return .ecstatic }
        if todaySteps >= 10000 { return .happy }
        if todaySteps >= 5000 { return .content }
        if hoursSinceLastFed > 24 { return .tired }
        return .sad
    }
    
    var nextEvolution: PetEvolution? {
        let evolutions = PetEvolution.allCases
        guard let currentIndex = evolutions.firstIndex(of: evolution),
              currentIndex + 1 < evolutions.count else { return nil }
        return evolutions[currentIndex + 1]
    }
    
    var xpToNextEvolution: Int? {
        guard let next = nextEvolution else { return nil }
        return next.requiredXP - totalXP
    }
    
    var evolutionProgress: Double {
        guard let next = nextEvolution else { return 1.0 }
        let currentRequired = evolution.requiredXP
        let nextRequired = next.requiredXP
        let range = nextRequired - currentRequired
        let progress = totalXP - currentRequired
        return min(1.0, Double(progress) / Double(range))
    }
    
    var daysOld: Int {
        let calendar = Calendar.current
        // Нормализуем обе даты до начала дня для правильного подсчета дней
        let startOfCreationDay = calendar.startOfDay(for: createdDate)
        let startOfToday = calendar.startOfDay(for: Date())
        
        // Подсчитываем разницу в днях
        let days = calendar.dateComponents([.day], from: startOfCreationDay, to: startOfToday).day ?? 0
        
        // Минимум 0 дней (если создан сегодня)
        return max(0, days)
    }
    
    mutating func feed(steps: Int) {
        todaySteps = steps
        let xpGained = steps / 100 // 1 XP за 100 шагов (соответствует новой системе)
        totalXP += xpGained
        lastFedDate = Date()
        
        // Проверяем эволюцию
        checkEvolution()
    }
    
    mutating func checkEvolution() {
        for evo in PetEvolution.allCases.reversed() {
            if totalXP >= evo.requiredXP {
                if evolution != evo {
                    evolution = evo
                }
                break
            }
        }
    }
}

/// Менеджер питомца
@MainActor
final class PetManager: ObservableObject {
    
    @Published var pets: [Pet] = []
    @Published var selectedPetId: UUID? // Активный питомец
    @Published var showEvolutionAnimation: Bool = false
    @Published var newEvolution: PetEvolution?
    
    private let petsKey = "virtualPets"
    private let selectedPetKey = "selectedPetId"
    
    // Обратная совместимость
    var pet: Pet? {
        get {
            if let id = selectedPetId,
               let found = pets.first(where: { $0.id.uuidString == id.uuidString }) {
                return found
            }
            return pets.first
        }
        set {
            if let newPet = newValue {
                if let index = pets.firstIndex(where: { $0.id == newPet.id }) {
                    pets[index] = newPet
                } else {
                    pets.append(newPet)
                }
                selectedPetId = newPet.id
                savePets()
            }
        }
    }
    
    init() {
        // Быстрая загрузка критичных данных синхронно
        loadPetsSync()
        
        // Тяжелые операции - асинхронно
        Task { @MainActor in
            migrateOldFormat()
            setMaxPetXPIfNeeded()
        }

        // Следим за изменением Premium и применяем ограничения к питомцам
        NotificationCenter.default.addObserver(
            forName: .premiumStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            Task { @MainActor in
                let isPremium = (notification.userInfo?["isPremium"] as? Bool) ?? SubscriptionManager.shared.isPremium
                self.enforcePremiumRestrictions(isPremium: isPremium)
            }
        }

        // Применяем ограничения сразу при старте (если Premium уже выключен/истёк)
        Task { @MainActor in
            enforcePremiumRestrictions(isPremium: SubscriptionManager.shared.isPremium)
        }
    }
    
    // MARK: - Persistence
    
    /// Быстрая синхронная загрузка только критичных данных
    private func loadPetsSync() {
        let storage = StorageManager.shared
        if let saved: [Pet] = storage.loadSafe([Pet].self, forKey: petsKey) {
            pets = saved
        }
        
        if let idString = storage.loadString(forKey: selectedPetKey),
           let id = UUID(uuidString: idString) {
            selectedPetId = id
        }
    }
    
    /// Полная загрузка питомцев (для совместимости)
    private func loadPets() {
        loadPetsSync()
    }
    
    func savePets() {
        // UserDefaults должен вызываться на главной очереди, но синхронно
        assert(Thread.isMainThread, "savePets must be called on main thread")
        
        let storage = StorageManager.shared
        do {
            try storage.save(pets, forKey: petsKey)
        } catch {
            Logger.shared.logStorageError(error, key: petsKey)
        }
        
        if let id = selectedPetId {
            storage.saveString(id.uuidString, forKey: selectedPetKey)
        }
        
        // Сохраняем данные питомца в App Group для виджета
        if let pet = self.pet, let sharedDefaults = UserDefaults(suiteName: "group.stepcounter.shared") {
            sharedDefaults.set(pet.type.emoji, forKey: "petEmoji")
            sharedDefaults.set(pet.name, forKey: "petName")
            
            // Вычисляем уровень питомца на основе XP
            let level = calculatePetLevel(xp: pet.totalXP)
            sharedDefaults.set(level, forKey: "petLevel")
            sharedDefaults.set(pet.totalXP, forKey: "petXP")
            
            // Вычисляем XP до следующего уровня
            let nextLevelXP = calculateNextLevelXP(currentLevel: level)
            sharedDefaults.set(nextLevelXP, forKey: "petNextLevelXP")
        }
    }
    
    /// Вычисляет уровень питомца на основе XP
    private func calculatePetLevel(xp: Int) -> Int {
        // Упрощенная формула: каждые 1000 XP = 1 уровень
        return max(1, min(100, (xp / 1000) + 1))
    }
    
    /// Вычисляет XP до следующего уровня
    private func calculateNextLevelXP(currentLevel: Int) -> Int {
        // Следующий уровень требует (currentLevel + 1) * 1000 XP
        return (currentLevel + 1) * 1000
    }
    
    // Миграция старого формата (одного питомца)
    private func migrateOldFormat() {
        if pets.isEmpty {
            let storage = StorageManager.shared
            if let oldPet: Pet = storage.loadSafe(Pet.self, forKey: "virtualPet") {
                pets = [oldPet]
                selectedPetId = oldPet.id
                savePets()
                storage.remove(forKey: "virtualPet")
            }
        }
    }
    
    /// Установить максимальный XP для питомца, если пользователь на максимальном уровне
    private func setMaxPetXPIfNeeded() {
        // Проверяем, установлен ли максимальный уровень игрока
        let maxLevelSetKey = "maxLevelSetOnce"
        let storage = StorageManager.shared
        if storage.loadBool(forKey: maxLevelSetKey) {
            // Если уровень максимальный, даём питомцу достаточно XP для всех аксессуаров
            let maxAccessoryXP = 500000 // Максимум для короны
            for i in pets.indices {
                if pets[i].totalXP < maxAccessoryXP {
                    pets[i].totalXP = maxAccessoryXP
                    pets[i].checkEvolution()
                }
            }
            savePets()
        }
    }
    
    func savePet() {
        savePets()
    }
    
    // MARK: - Pet Management
    
    var hasPet: Bool {
        !pets.isEmpty
    }
    
    @MainActor
    func createPet(name: String, type: PetType) -> Bool {
        // Premium требуется для всех питомцев, кроме базового котика
        let subscriptionManager = SubscriptionManager.shared
        if type.requiresPremium && !subscriptionManager.isPremium {
            return false
        }
        
        // Premium даёт возможность создавать несколько питомцев
        let hasUnlimitedPets = subscriptionManager.isPremium
        
        // Для free пользователей: максимум 1 питомец
        if !hasUnlimitedPets && pets.count >= 1 {
            return false
        }
        
        let newPet = Pet(name: name, type: type)
        pets.append(newPet)
        selectedPetId = newPet.id
        savePets()
        return true
    }

    // MARK: - Premium Restrictions
    
    /// Если Premium выключен/истёк — блокируем Premium питомцев и гарантируем базового котика.
    @MainActor
    func enforcePremiumRestrictions(isPremium: Bool) {
        guard !isPremium else { return }
        
        // Если питомцев нет — создаём базового котика
        if pets.isEmpty {
            let basePet = Pet(name: PetType.cat.name, type: .cat)
            pets = [basePet]
            selectedPetId = basePet.id
            savePets()
            return
        }
        
        // Если активный питомец — Premium, переключаем на первого доступного (котика),
        // а если его нет — создаём.
        if let current = pet, current.type.requiresPremium {
            if let freePet = pets.first(where: { !$0.type.requiresPremium }) {
                selectedPetId = freePet.id
                savePets()
            } else {
                let basePet = Pet(name: PetType.cat.name, type: .cat)
                pets.insert(basePet, at: 0)
                selectedPetId = basePet.id
                savePets()
            }
        }
    }
    
    func feedPet(steps: Int) {
        guard let petId = selectedPetId,
              let index = pets.firstIndex(where: { $0.id == petId }) else { return }
        
        var currentPet = pets[index]
        let oldEvolution = currentPet.evolution
        currentPet.feed(steps: steps)
        
        // Проверяем эволюцию
        if currentPet.evolution != oldEvolution {
            newEvolution = currentPet.evolution
            showEvolutionAnimation = true
            
            // Haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        
        pets[index] = currentPet
        savePets()
    }
    
    func resetDaily() {
        guard let petId = selectedPetId,
              let index = pets.firstIndex(where: { $0.id == petId }) else { return }
        
        pets[index].todaySteps = 0
        savePets()
    }
    
    func deletePet(_ pet: Pet) {
        pets.removeAll { $0.id == pet.id }
        if selectedPetId == pet.id {
            selectedPetId = pets.first?.id
        }
        savePets()
    }
    
    func updatePetName(_ pet: Pet, newName: String) {
        guard let index = pets.firstIndex(where: { $0.id == pet.id }) else { return }
        pets[index].name = newName
        savePets()
    }
    
    func selectPet(_ pet: Pet) {
        // Проверяем, не требует ли питомец премиум
        let subscriptionManager = SubscriptionManager.shared
        if pet.type.requiresPremium && !subscriptionManager.isPremium {
            // Нельзя выбрать премиум питомца без премиума
            // Автоматически переключаем на бесплатного питомца
            if let freePet = pets.first(where: { !$0.type.requiresPremium }) {
                selectedPetId = freePet.id
            } else {
                // Если нет бесплатного питомца, создаём котика
                let basePet = Pet(name: PetType.cat.name, type: .cat)
                pets.insert(basePet, at: 0)
                selectedPetId = basePet.id
            }
            savePets()
            return
        }
        
        selectedPetId = pet.id
        savePets()
    }
    
    func addAccessory(_ accessory: String) {
        guard let petId = selectedPetId,
              let index = pets.firstIndex(where: { $0.id == petId }) else { return }
        
        if !pets[index].accessories.contains(accessory) {
            pets[index].accessories.append(accessory)
            savePets()
        }
    }
}
