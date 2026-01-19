//
//  LevelManager.swift
//  StepCounter
//
//  Система уровней и XP
//

import Foundation
import SwiftUI

/// Звание игрока
enum PlayerRank: String, Codable, CaseIterable {
    case beginner = "beginner"
    case walker = "walker"
    case hiker = "hiker"
    case explorer = "explorer"
    case adventurer = "adventurer"
    case athlete = "athlete"
    case champion = "champion"
    case legend = "legend"
    case master = "master"
    case grandmaster = "grandmaster"
    
    var name: String {
        switch self {
        case .beginner: return "Новичок"
        case .walker: return "Ходок"
        case .hiker: return "Путешественник"
        case .explorer: return "Исследователь"
        case .adventurer: return "Искатель"
        case .athlete: return "Атлет"
        case .champion: return "Чемпион"
        case .legend: return "Легенда"
        case .master: return "Мастер"
        case .grandmaster: return "Грандмастер"
        }
    }
    
    var iconName: String {
        switch self {
        case .beginner: return "star.fill"
        case .walker: return "figure.walk"
        case .hiker: return "mountain.2.fill"
        case .explorer: return "map.fill"
        case .adventurer: return "bolt.fill"
        case .athlete: return "figure.run"
        case .champion: return "trophy.fill"
        case .legend: return "crown.fill"
        case .master: return "sparkles"
        case .grandmaster: return "diamond.fill"
        }
    }
    
    var minLevel: Int {
        switch self {
        case .beginner: return 1
        case .walker: return 5
        case .hiker: return 10
        case .explorer: return 20
        case .adventurer: return 30
        case .athlete: return 40
        case .champion: return 50
        case .legend: return 65
        case .master: return 80
        case .grandmaster: return 100
        }
    }
    
    var color: Color {
        switch self {
        case .beginner: return .gray
        case .walker: return .green
        case .hiker: return .blue
        case .explorer: return .cyan
        case .adventurer: return .purple
        case .athlete: return .orange
        case .champion: return .yellow
        case .legend: return .pink
        case .master: return .red
        case .grandmaster: return Color(red: 1, green: 0.84, blue: 0) // Gold
        }
    }
    
    static func forLevel(_ level: Int) -> PlayerRank {
        for rank in PlayerRank.allCases.reversed() {
            if level >= rank.minLevel {
                return rank
            }
        }
        return .beginner
    }
}

/// Данные игрока
struct PlayerData: Codable {
    var totalXP: Int
    var level: Int
    var rank: PlayerRank
    var totalStepsAllTime: Int
    var totalDistanceAllTime: Double
    var totalCaloriesAllTime: Double
    var daysActive: Int
    var longestStreak: Int
    var currentStreak: Int
    var lastActiveDate: Date?
    var joinDate: Date
    
    init() {
        self.totalXP = 0
        self.level = 1
        self.rank = .beginner
        self.totalStepsAllTime = 0
        self.totalDistanceAllTime = 0
        self.totalCaloriesAllTime = 0
        self.daysActive = 0
        self.longestStreak = 0
        self.currentStreak = 0
        self.lastActiveDate = nil
        self.joinDate = Date()
    }
}

/// Ежедневный квест
struct DailyQuest: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let requirement: Int
    let xpReward: Int
    let type: QuestType
    var progress: Int
    var isCompleted: Bool
    var isPremium: Bool
    
    // Для обратной совместимости со старыми сохранениями
    init(id: String, title: String, description: String, requirement: Int, xpReward: Int, type: QuestType, progress: Int, isCompleted: Bool, isPremium: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.requirement = requirement
        self.xpReward = xpReward
        self.type = type
        self.progress = progress
        self.isCompleted = isCompleted
        self.isPremium = isPremium
    }
    
    var progressPercent: Double {
        guard requirement > 0 else { return 0 }
        return min(1.0, Double(progress) / Double(requirement))
    }
}

enum QuestType: String, Codable {
    case steps = "steps"
    case distance = "distance"
    case calories = "calories"
    case earlyWalk = "early_walk"
    case streak = "streak"
}

/// Менеджер уровней
@MainActor
final class LevelManager: ObservableObject {
    
    @Published var player: PlayerData
    @Published var dailyQuests: [DailyQuest] = []
    @Published var showLevelUp: Bool = false
    @Published var newLevel: Int = 0
    @Published var showRankUp: Bool = false
    @Published var newRank: PlayerRank?
    @Published var showStreakBonus: Bool = false
    @Published var streakBonusAmount: Int = 0
    @Published var streakBonusTitle: String = ""
    
    private let playerKey = "playerData"
    private let questsKey = "dailyQuests"
    private let lastQuestDate = "lastQuestDate"
    private let claimedStreakBonusesKey = "claimedStreakBonuses"
    
    init() {
        let storage = StorageManager.shared
        // Быстрая загрузка критичных данных синхронно
        if let saved: PlayerData = storage.loadSafe(PlayerData.self, forKey: playerKey) {
            player = saved
        } else {
            player = PlayerData()
        }
        
        // Тяжелые операции - асинхронно
        Task { @MainActor in
            // ВРЕМЕННО: Установить максимальный уровень для тестирования
            let maxLevelSetKey = "maxLevelSetOnce"
            if !storage.loadBool(forKey: maxLevelSetKey) {
                setMaxLevel()
                storage.saveBool(true, forKey: maxLevelSetKey)
            }
            
            loadQuests()
            generateDailyQuestsIfNeeded()
        }
    }
    
    // MARK: - XP System
    
    /// XP, необходимый для следующего уровня (экспоненциальная прогрессия)
    func xpForLevel(_ level: Int) -> Int {
        // Формула: базовый XP * (level ^ 1.8)
        // Уровень 1 → 0 XP
        // Уровень 2 → 200 XP
        // Уровень 10 → ~6,000 XP
        // Уровень 50 → ~200,000 XP
        // Уровень 100 → ~800,000 XP
        if level <= 1 {
            return 0
        }
        let base = 50.0
        let levelPower = pow(Double(level), 1.8)
        return Int(base * levelPower)
    }
    
    /// Текущий прогресс к следующему уровню (0-1)
    var levelProgress: Double {
        let currentLevelXP = xpForLevel(player.level - 1)
        let nextLevelXP = xpForLevel(player.level)
        let range = nextLevelXP - currentLevelXP
        let progress = player.totalXP - currentLevelXP
        return min(1.0, Double(progress) / Double(range))
    }
    
    /// XP до следующего уровня
    var xpToNextLevel: Int {
        let nextLevelXP = xpForLevel(player.level)
        return max(0, nextLevelXP - player.totalXP)
    }
    
    // MARK: - Add XP
    
    func addXP(_ amount: Int) {
        player.totalXP += amount
        
        // Проверяем повышение уровня
        while player.totalXP >= xpForLevel(player.level) {
            player.level += 1
            newLevel = player.level
            showLevelUp = true
            
            // Haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        
        // Проверяем повышение звания
        let newPlayerRank = PlayerRank.forLevel(player.level)
        if newPlayerRank != player.rank {
            player.rank = newPlayerRank
            newRank = newPlayerRank
            showRankUp = true
        }
        
        savePlayer()
    }
    
    @MainActor
    func addSteps(_ steps: Int, distance: Double, calories: Double) {
        // XP за шаги (1 XP за 100 шагов)
        let xpFromSteps = steps / 100
        
        // Бонус за достижение целей
        var bonusXP = 0
        if steps >= AppConstants.QuestMilestones.steps10k {
            bonusXP += AppConstants.XP.bonusFor10kSteps
        }
        if steps >= AppConstants.QuestMilestones.steps15k {
            bonusXP += AppConstants.XP.bonusFor15kSteps
        }
        if steps >= AppConstants.QuestMilestones.steps20k {
            bonusXP += AppConstants.XP.bonusFor20kSteps
        }
        
        // Бонус только раз в день за достижение цели
        let storage = StorageManager.shared
        let key = "bonusGiven_\(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)"
        if !storage.loadBool(forKey: key) && steps >= AppConstants.QuestMilestones.steps10k {
            bonusXP += AppConstants.XP.dailyGoalBonus
            storage.saveBool(true, forKey: key)
        }
        
        addXP(xpFromSteps + bonusXP)
        
        // Обновляем статистику
        player.totalStepsAllTime += steps
        player.totalDistanceAllTime += distance
        player.totalCaloriesAllTime += calories
        
        // Обновляем активность
        let today = Calendar.current.startOfDay(for: Date())
        if let lastActive = player.lastActiveDate {
            let lastDay = Calendar.current.startOfDay(for: lastActive)
            let daysDiff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if daysDiff == 1 {
                player.currentStreak += 1
                if player.currentStreak > player.longestStreak {
                    player.longestStreak = player.currentStreak
                }
            } else if daysDiff > 1 {
                player.currentStreak = 1
            }
        } else {
            player.currentStreak = 1
            player.daysActive = 1
        }
        
        if player.lastActiveDate == nil || !Calendar.current.isDate(player.lastActiveDate!, inSameDayAs: today) {
            player.daysActive += 1
        }
        
        player.lastActiveDate = Date()
        
        // Проверяем бонусы за стрики
        checkStreakBonuses()
        
        // Обновляем квесты
        updateQuests(steps: steps, distance: distance, calories: calories)
        
        savePlayer()
    }
    
    // MARK: - Streak Bonuses
    
    func checkStreakBonuses() {
        let streakBonuses: [(Int, Int, String)] = [
            (7, AppConstants.XP.streak7Days, "🔥 Неделя силы! Бонус +\(AppConstants.XP.streak7Days) XP"),
            (30, AppConstants.XP.streak30Days, "🌟 Месяц чемпиона! Бонус +\(AppConstants.XP.streak30Days) XP"),
            (100, AppConstants.XP.streak100Days, "💎 Легенда 100 дней! Бонус +\(AppConstants.XP.streak100Days) XP")
        ]
        
        let storage = StorageManager.shared
        var claimedBonuses = storage.loadArraySafe(Int.self, forKey: claimedStreakBonusesKey)
        
        for (streak, bonus, title) in streakBonuses {
            if player.currentStreak >= streak && !claimedBonuses.contains(streak) {
                addXP(bonus)
                claimedBonuses.append(streak)
                streakBonusAmount = bonus
                streakBonusTitle = title
                showStreakBonus = true
                storage.saveArraySafe(claimedBonuses, forKey: claimedStreakBonusesKey)
            }
        }
    }
    
    // MARK: - Daily Quests
    
    private func generateDailyQuestsIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        
        let storage = StorageManager.shared
        if let lastDate = storage.loadDate(forKey: lastQuestDate),
           Calendar.current.isDate(lastDate, inSameDayAs: today),
           !dailyQuests.isEmpty {
            // Квесты уже сгенерированы и успешно загружены
            // Но проверяем, что их ровно 3 (исправление для старых сохранений)
            if dailyQuests.count < 3 {
                Logger.shared.logWarning("Обнаружено меньше 3 квестов (\(dailyQuests.count)), перегенерируем...")
                generateDailyQuests()
                storage.saveDate(today, forKey: lastQuestDate)
            }
            return
        }
        
        // Если квестов нет или дата изменилась — генерируем новые
        generateDailyQuests()
        storage.saveDate(today, forKey: lastQuestDate)
    }
    
    private var questGenerationAttempts = 0
    private let maxQuestGenerationAttempts = 5
    
    private func generateDailyQuests() {
        questGenerationAttempts += 1
        guard questGenerationAttempts <= maxQuestGenerationAttempts else {
            Logger.shared.logWarning("Не удалось сгенерировать уникальные квесты после \(maxQuestGenerationAttempts) попыток")
            questGenerationAttempts = 0
            return
        }
        
        let possibleQuests: [(String, String, Int, Int, QuestType)] = [
            ("steps_5k", "Пройти 5,000 шагов", AppConstants.QuestMilestones.steps5k, 50, .steps),
            ("steps_8k", "Пройти 8,000 шагов", AppConstants.QuestMilestones.steps8k, 80, .steps),
            ("steps_10k", "Пройти 10,000 шагов", AppConstants.QuestMilestones.steps10k, 100, .steps),
            ("steps_12k", "Пройти 12,000 шагов", AppConstants.QuestMilestones.steps12k, 120, .steps),
            ("distance_3km", "Пройти 3 км", AppConstants.QuestMilestones.distance3km, 60, .distance),
            ("distance_5km", "Пройти 5 км", AppConstants.QuestMilestones.distance5km, 100, .distance),
            ("calories_200", "Сжечь 200 калорий", AppConstants.QuestMilestones.calories200, 50, .calories),
            ("calories_400", "Сжечь 400 калорий", AppConstants.QuestMilestones.calories400, 100, .calories),
        ]
        
        // Премиум квесты (более сложные и с большей наградой)
        let premiumQuests: [(String, String, Int, Int, QuestType)] = [
            ("steps_15k", "Пройти 15,000 шагов", AppConstants.QuestMilestones.steps15k, 200, .steps),
            ("steps_20k", "Пройти 20,000 шагов", AppConstants.QuestMilestones.steps20k, 300, .steps),
            ("distance_10km", "Пройти 10 км", AppConstants.QuestMilestones.distance10km, 250, .distance),
            ("calories_600", "Сжечь 600 калорий", AppConstants.QuestMilestones.calories600, 200, .calories),
        ]
        
        // Выбираем квесты с гарантией уникальности ID
        var selectedQuests: [(String, String, Int, Int, QuestType)] = []
        var usedIds = Set<String>()
        var premiumQuestAdded = false
        
        // Создаем множества ID для быстрой проверки
        let regularQuestIds = Set(possibleQuests.map { $0.0 })
        let premiumQuestIds = Set(premiumQuests.map { $0.0 })
        
        // Выбираем 2 обычных квеста с уникальными ID
        let shuffledRegular = possibleQuests.shuffled()
        for quest in shuffledRegular {
            if selectedQuests.count >= 2 { break }
            if !usedIds.contains(quest.0) {
                selectedQuests.append(quest)
                usedIds.insert(quest.0)
            }
        }
        
        // Гарантируем, что выбрано 2 обычных квеста
        guard selectedQuests.count == 2 else {
            Logger.shared.logWarning("Не удалось выбрать 2 обычных квеста. Выбрано: \(selectedQuests.count)")
            if questGenerationAttempts < maxQuestGenerationAttempts {
                generateDailyQuests() // Повторная попытка
            }
            return
        }
        
        // Выбираем 1 премиум квест с уникальным ID
        let shuffledPremium = premiumQuests.shuffled()
        for quest in shuffledPremium {
            if !usedIds.contains(quest.0) {
                selectedQuests.append(quest)
                usedIds.insert(quest.0)
                premiumQuestAdded = true
                break
            }
        }
        
        // Если премиум квест не найден, выбираем дополнительный обычный квест
        if !premiumQuestAdded {
            Logger.shared.logInfo("Премиум квест не выбран, добавляем дополнительный обычный квест")
            // Ищем в оставшихся обычных квестах
            for quest in shuffledRegular {
                if selectedQuests.count >= 3 { break }
                if !usedIds.contains(quest.0) {
                    selectedQuests.append(quest)
                    usedIds.insert(quest.0)
                    break
                }
            }
        }
        
        // Гарантируем, что выбрано ровно 3 квеста
        if selectedQuests.count < 3 {
            Logger.shared.logWarning("Не удалось выбрать 3 квеста. Выбрано: \(selectedQuests.count). Пытаемся добавить любые доступные.")
            // Если не удалось выбрать 3, используем все доступные уникальные квесты
            let allAvailableQuests = possibleQuests + premiumQuests
            let shuffledAll = allAvailableQuests.shuffled()
            
            for quest in shuffledAll {
                if selectedQuests.count >= 3 { break }
                if !usedIds.contains(quest.0) {
                    selectedQuests.append(quest)
                    usedIds.insert(quest.0)
                    // Если это премиум квест, отмечаем
                    if premiumQuestIds.contains(quest.0) {
                        premiumQuestAdded = true
                    }
                }
            }
            
            // Если все еще меньше 3, это критическая ошибка
            if selectedQuests.count < 3 {
                Logger.shared.logWarning("КРИТИЧЕСКАЯ ОШИБКА: Не удалось сгенерировать 3 квеста. Доступно только \(selectedQuests.count)")
                if questGenerationAttempts < maxQuestGenerationAttempts {
                    generateDailyQuests() // Повторная попытка
                }
                return
            }
        }
        
        // Создаём квесты
        var quests: [DailyQuest] = []
        for (index, quest) in selectedQuests.enumerated() {
            // Первые 2 - обычные, третий - премиум (если был выбран из premiumQuests)
            // Если третий был выбран из обычных, он тоже будет обычным
            let isPremium = index == 2 && premiumQuestAdded
            quests.append(
                DailyQuest(
                    id: quest.0,
                    title: quest.1,
                    description: "Выполните до конца дня",
                    requirement: quest.2,
                    xpReward: quest.3,
                    type: quest.4,
                    progress: 0,
                    isCompleted: false,
                    isPremium: isPremium
                )
            )
        }
        
        // Финальная проверка на уникальность всех ID
        let allIds = quests.map { $0.id }
        let uniqueIds = Set(allIds)
        if allIds.count != uniqueIds.count {
            // Если есть дубликаты, перегенерируем с уникальными ID
            Logger.shared.logWarning("Обнаружены дублирующиеся ID квестов: \(allIds.joined(separator: ", ")), перегенерируем...")
            if questGenerationAttempts < maxQuestGenerationAttempts {
                generateDailyQuests() // Рекурсивный вызов (с защитой от бесконечной рекурсии)
            }
            return
        }
        
        // Сбрасываем счетчик попыток при успешной генерации
        questGenerationAttempts = 0
        
        // Финальная проверка: должно быть ровно 3 квеста
        guard quests.count == 3 else {
            Logger.shared.logWarning("КРИТИЧЕСКАЯ ОШИБКА: После создания квестов их количество не равно 3. Количество: \(quests.count)")
            if questGenerationAttempts < maxQuestGenerationAttempts {
                generateDailyQuests() // Повторная попытка
            }
            return
        }
        
        Logger.shared.logInfo("✅ Успешно сгенерировано \(quests.count) ежедневных квестов: \(quests.map { $0.title }.joined(separator: ", "))")
        
        dailyQuests = quests
        saveQuests()
    }
    
    @MainActor
    private func updateQuests(steps: Int, distance: Double, calories: Double) {
        let subscriptionManager = SubscriptionManager.shared
        
        for i in dailyQuests.indices {
            if dailyQuests[i].isCompleted { continue }
            
            // Проверяем доступ к премиум квесту
            if dailyQuests[i].isPremium && !subscriptionManager.isPremium {
                // Премиум квест недоступен - не обновляем прогресс
                continue
            }
            
            switch dailyQuests[i].type {
            case .steps:
                dailyQuests[i].progress = steps
            case .distance:
                dailyQuests[i].progress = Int(distance)
            case .calories:
                dailyQuests[i].progress = Int(calories)
            case .earlyWalk, .streak:
                break
            }
            
            if dailyQuests[i].progress >= dailyQuests[i].requirement && !dailyQuests[i].isCompleted {
                dailyQuests[i].isCompleted = true
                addXP(dailyQuests[i].xpReward)
            }
        }
        
        saveQuests()
    }
    
    // MARK: - Persistence
    
    private func savePlayer() {
        let storage = StorageManager.shared
        if let data = try? JSONEncoder().encode(player) {
            storage.saveData(data, forKey: playerKey)
        }
    }
    
    // MARK: - Debug/Dev Methods
    
    /// Установить максимальный уровень (для разработки/тестирования)
    func setMaxLevel() {
        // Максимальный уровень - 100 (соответствует grandmaster)
        let maxLevel = 100
        let maxXP = xpForLevel(maxLevel) + 100000 // Немного больше максимального для уверенности
        
        player.level = maxLevel
        player.totalXP = maxXP
        player.rank = PlayerRank.grandmaster
        
        savePlayer()
        
        // Обновляем звание если нужно
        let newPlayerRank = PlayerRank.forLevel(player.level)
        if newPlayerRank != player.rank {
            player.rank = newPlayerRank
            savePlayer()
        }
    }
    
    private func loadQuests() {
        let storage = StorageManager.shared
        if let saved: [DailyQuest] = storage.loadSafe([DailyQuest].self, forKey: questsKey) {
            // Проверяем на дубликаты ID при загрузке
            var uniqueQuests: [DailyQuest] = []
            var seenIds = Set<String>()
            
            for quest in saved {
                if !seenIds.contains(quest.id) {
                    uniqueQuests.append(quest)
                    seenIds.insert(quest.id)
                } else {
                    Logger.shared.logWarning("Обнаружен дублирующийся ID квеста при загрузке: \(quest.id), пропускаем")
                }
            }
            
            dailyQuests = uniqueQuests
            
            // Если были дубликаты, сохраняем очищенный список
            if uniqueQuests.count != saved.count {
                saveQuests()
            }
        }
    }
    
    private func saveQuests() {
        let storage = StorageManager.shared
        do {
            try storage.save(dailyQuests, forKey: questsKey)
        } catch {
            Logger.shared.logStorageError(error, key: questsKey)
        }
    }
    
    // MARK: - Quest Refresh
    
    /// Обновить квест через просмотр рекламы
    @MainActor
    func refreshQuest(_ questId: String, completion: @escaping (Bool) -> Void) {
        guard let index = dailyQuests.firstIndex(where: { $0.id == questId }) else {
            completion(false)
            return
        }
        
        // Нельзя обновлять уже выполненный квест
        guard !dailyQuests[index].isCompleted else {
            completion(false)
            return
        }
        
        let adManager = AdManager.shared
        let placement = AdPlacement.refreshQuest
        
        adManager.showRewardedAd(for: placement) { [weak self] (reward: AdReward?) in
            guard let self = self, reward != nil else {
                completion(false)
                return
            }
            
            // Определяем, является ли текущий квест премиумным
            let isPremiumQuest = self.dailyQuests[index].isPremium
            
            // Выбираем квесты в зависимости от типа (бесплатные или премиум)
            let availableQuests: [(String, String, Int, Int, QuestType)]
            
            if isPremiumQuest {
                // Премиум квесты (более сложные и с большей наградой)
                availableQuests = [
                    ("steps_15k", "Пройти 15,000 шагов", AppConstants.QuestMilestones.steps15k, 200, .steps),
                    ("steps_20k", "Пройти 20,000 шагов", AppConstants.QuestMilestones.steps20k, 300, .steps),
                    ("distance_10km", "Пройти 10 км", AppConstants.QuestMilestones.distance10km, 250, .distance),
                    ("calories_600", "Сжечь 600 калорий", AppConstants.QuestMilestones.calories600, 200, .calories),
                ]
            } else {
                // Бесплатные квесты
                availableQuests = [
                    ("steps_5k", "Пройти 5,000 шагов", AppConstants.QuestMilestones.steps5k, 50, .steps),
                    ("steps_8k", "Пройти 8,000 шагов", AppConstants.QuestMilestones.steps8k, 80, .steps),
                    ("steps_10k", "Пройти 10,000 шагов", AppConstants.QuestMilestones.steps10k, 100, .steps),
                    ("steps_12k", "Пройти 12,000 шагов", AppConstants.QuestMilestones.steps12k, 120, .steps),
                    ("distance_3km", "Пройти 3 км", AppConstants.QuestMilestones.distance3km, 60, .distance),
                    ("distance_5km", "Пройти 5 км", AppConstants.QuestMilestones.distance5km, 100, .distance),
                    ("calories_200", "Сжечь 200 калорий", AppConstants.QuestMilestones.calories200, 50, .calories),
                    ("calories_400", "Сжечь 400 калорий", AppConstants.QuestMilestones.calories400, 100, .calories),
                ]
            }
            
            // Исключаем текущий квест и все существующие ID из списка доступных
            let existingIds = Set(self.dailyQuests.map { $0.id })
            let filteredQuests = availableQuests.filter { quest in
                quest.0 != questId && !existingIds.contains(quest.0)
            }
            
            guard let newQuest = filteredQuests.randomElement() else {
                Logger.shared.logWarning("Не удалось найти уникальный квест для обновления. Текущие ID: \(existingIds)")
                completion(false)
                return
            }
            
            // Обновляем квест с сохранением премиум статуса
            self.dailyQuests[index] = DailyQuest(
                id: newQuest.0,
                title: newQuest.1,
                description: "Выполните до конца дня",
                requirement: newQuest.2,
                xpReward: newQuest.3,
                type: newQuest.4,
                progress: 0,
                isCompleted: false,
                isPremium: isPremiumQuest // Сохраняем премиум статус
            )
            
            // Финальная проверка на уникальность
            let allIds = self.dailyQuests.map { $0.id }
            let uniqueIds = Set(allIds)
            if allIds.count != uniqueIds.count {
                Logger.shared.logWarning("Обнаружены дублирующиеся ID после обновления квеста: \(allIds.joined(separator: ", "))")
                completion(false)
                return
            }
            
            self.saveQuests()
            completion(true)
        }
    }
    
    // MARK: - Stats
    
    var completedQuestsToday: Int {
        dailyQuests.filter { $0.isCompleted }.count
    }
    
    var totalQuestsToday: Int {
        dailyQuests.count
    }
}
