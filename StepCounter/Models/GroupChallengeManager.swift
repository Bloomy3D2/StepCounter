//
//  GroupChallengeManager.swift
//  StepCounter
//
//  Групповые челленджи (команды друзей)
//

import Foundation

/// Участник группового челленджа
struct GroupChallengeParticipant: Identifiable, Codable {
    let id: String
    let name: String
    var progress: Int
    var isCompleted: Bool = false
    
    var rank: Int = 0
}

/// Групповой челлендж
struct GroupChallenge: Identifiable, Codable {
    let id: UUID
    let name: String
    let type: ChallengeType
    let target: Int
    let startDate: Date
    let endDate: Date
    var participants: [GroupChallengeParticipant]
    let creatorId: String
    
    var isActive: Bool {
        Date() >= startDate && Date() <= endDate
    }
    
    var daysRemaining: Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, days)
    }
    
    var totalProgress: Int {
        participants.reduce(0) { $0 + $1.progress }
    }
    
    var teamProgress: Double {
        guard target > 0 else { return 0 }
        return min(1.0, Double(totalProgress) / Double(target))
    }
    
    var completedCount: Int {
        participants.filter { $0.isCompleted }.count
    }
    
    mutating func updateRanks() {
        // Сортируем участников по прогрессу (по убыванию), затем по имени для стабильности
        participants.sort { participant1, participant2 in
            if participant1.progress != participant2.progress {
                return participant1.progress > participant2.progress
            }
            return participant1.name < participant2.name
        }
        
        // Устанавливаем ранги с учетом одинакового прогресса
        var currentRank = 1
        var previousProgress: Int? = nil
        
        for index in participants.indices {
            let currentProgress = participants[index].progress
            
            // Если прогресс отличается от предыдущего, обновляем ранг
            if let prev = previousProgress, currentProgress < prev {
                currentRank = index + 1
            } else if previousProgress == nil {
                // Первый участник всегда имеет ранг 1
                currentRank = 1
            }
            
            participants[index].rank = currentRank
            previousProgress = currentProgress
        }
    }
}

/// Менеджер групповых челленджей
@MainActor
final class GroupChallengeManager: ObservableObject {
    
    @Published var activeChallenges: [GroupChallenge] = []
    @Published var completedChallenges: [GroupChallenge] = []
    
    private let activeKey = "activeGroupChallenges"
    private let completedKey = "completedGroupChallenges"
    
    private var hasLoaded = false
    
    init() {
        // Загружаем данные сразу при инициализации
        // Все операции на главном потоке благодаря @MainActor
        let storage = StorageManager.shared
        if let active: [GroupChallenge] = storage.loadSafe([GroupChallenge].self, forKey: activeKey) {
            // Обновляем ранги для всех загруженных челленджей
            activeChallenges = active.map { challenge in
                var updated = challenge
                updated.updateRanks()
                return updated
            }
        }
        if let completed: [GroupChallenge] = storage.loadSafe([GroupChallenge].self, forKey: completedKey) {
            // Обновляем ранги для всех загруженных завершенных челленджей
            completedChallenges = completed.map { challenge in
                var updated = challenge
                updated.updateRanks()
                return updated
            }
        }
        hasLoaded = true
    }
    
    // MARK: - Challenge Management
    
    @MainActor
    func createChallenge(name: String, type: ChallengeType, target: Int, durationDays: Int, participants: [String]) -> Bool {
        // Проверяем Premium для продвинутых челленджей
        let subscriptionManager = SubscriptionManager.shared
        
        // Групповые челленджи требуют Premium
        if !subscriptionManager.isPremium {
            return false
        }
        var challenge = GroupChallenge(
            id: UUID(),
            name: name,
            type: type,
            target: target,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: durationDays, to: Date()) ?? Date(),
            participants: participants.map { userId in
                GroupChallengeParticipant(
                    id: userId,
                    name: getParticipantName(userId: userId),
                    progress: 0
                )
            },
            creatorId: "user"
        )
        
        // Устанавливаем начальные ранги
        challenge.updateRanks()
        
        activeChallenges.append(challenge)
        // Копируем данные и сохраняем асинхронно
        let active = activeChallenges
        let completed = completedChallenges
        let activeKey = self.activeKey
        let completedKey = self.completedKey
        Task.detached {
            let storage = StorageManager.shared
            do {
                try await MainActor.run {
                    try storage.save(active, forKey: activeKey)
                    try storage.save(completed, forKey: completedKey)
                }
            } catch {
                Task { @MainActor in
                    Logger.shared.logStorageError(error, key: activeKey)
                }
            }
        }
        return true
    }
    
    @MainActor
    func updateParticipantProgress(challengeId: UUID, participantId: String, progress: Int) {
        if let challengeIndex = activeChallenges.firstIndex(where: { $0.id == challengeId }),
           let participantIndex = activeChallenges[challengeIndex].participants.firstIndex(where: { $0.id == participantId }) {
            
            activeChallenges[challengeIndex].participants[participantIndex].progress = progress
            
            // Проверяем выполнение цели
            if progress >= activeChallenges[challengeIndex].target {
                activeChallenges[challengeIndex].participants[participantIndex].isCompleted = true
            }
            
            // Обновляем ранги
            activeChallenges[challengeIndex].updateRanks()
            
            // Проверяем, завершён ли челлендж (все участники выполнили)
            if activeChallenges[challengeIndex].totalProgress >= activeChallenges[challengeIndex].target {
                completeChallenge(challengeId: challengeId)
            } else {
                saveChallenges()
            }
        }
    }
    
    @MainActor
    func updateUserProgress(type: ChallengeType, steps: Int, distance: Double, calories: Double) {
        for challengeIndex in activeChallenges.indices where activeChallenges[challengeIndex].type == type {
            let progress: Int
            switch type {
            case .dailySteps, .weeklySteps:
                progress = steps
            case .weeklyDistance:
                progress = Int(distance / 1000) // км
            case .dailyCalories:
                progress = Int(calories)
            case .streakDays:
                // Для стриков используем текущий прогресс
                progress = steps / 1000 // упрощённо
            }
            
            if let userIndex = activeChallenges[challengeIndex].participants.firstIndex(where: { $0.id == "user" }) {
                activeChallenges[challengeIndex].participants[userIndex].progress = progress
                
                if progress >= activeChallenges[challengeIndex].target {
                    activeChallenges[challengeIndex].participants[userIndex].isCompleted = true
                }
                
                activeChallenges[challengeIndex].updateRanks()
                
                if activeChallenges[challengeIndex].totalProgress >= activeChallenges[challengeIndex].target {
                    completeChallenge(challengeId: activeChallenges[challengeIndex].id)
                }
            }
        }
        
        saveChallenges()
    }
    
    @MainActor
    private func completeChallenge(challengeId: UUID) {
        if let index = activeChallenges.firstIndex(where: { $0.id == challengeId }) {
            let challenge = activeChallenges[index]
            completedChallenges.append(challenge)
            activeChallenges.remove(at: index)
            saveChallenges()
        }
    }
    
    @MainActor
    func deleteChallenge(_ challenge: GroupChallenge) {
        activeChallenges.removeAll { $0.id == challenge.id }
        saveChallenges()
    }
    
    @MainActor
    private func checkExpiredChallenges() {
        let now = Date()
        let expired = activeChallenges.filter { $0.endDate < now }
        completedChallenges.append(contentsOf: expired)
        activeChallenges.removeAll { $0.endDate < now }
        saveChallenges()
    }
    
    // MARK: - Persistence
    
    @MainActor
    private func saveChallenges() {
        let storage = StorageManager.shared
        do {
            try storage.save(activeChallenges, forKey: activeKey)
            try storage.save(completedChallenges, forKey: completedKey)
        } catch {
            Logger.shared.logStorageError(error, key: activeKey)
        }
    }
    
    @MainActor
    func ensureLoaded() async {
        // Данные уже загружены в init(), просто проверяем истекшие
        guard !hasLoaded else { return }
        hasLoaded = true
        
        // Проверку истекших откладываем
        Task { @MainActor [weak self] in
            self?.checkExpiredChallenges()
        }
    }
    
    // MARK: - Helper
    
    func userRank(in challenge: GroupChallenge) -> Int {
        if let user = challenge.participants.first(where: { $0.id == "user" }) {
            return user.rank
        }
        return 0
    }
    
    private func getParticipantName(userId: String) -> String {
        if userId == "user" {
            return "Вы"
        }
        
        // Маппинг ID на имена (в будущем можно загружать из CloudManager)
        let nameMap: [String: String] = [
            "friend1": "Алексей",
            "friend2": "Мария",
            "friend3": "Дмитрий",
            "friend4": "Анна",
            "friend5": "Иван",
            "friend6": "Елена",
            "friend7": "Сергей",
            "friend8": "Ольга"
        ]
        
        return nameMap[userId] ?? "Участник \(userId)"
    }
}
