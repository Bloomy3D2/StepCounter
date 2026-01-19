//
//  TournamentManager.swift
//  StepCounter
//
//  Менеджер еженедельных турниров
//

import Foundation

/// Тип турнира
enum TournamentType: String, Codable {
    case weekly = "weekly"                    // Еженедельный
    case seasonal = "seasonal"                // Сезонный
    case special = "special"                  // Специальный (праздники)
    case corporate = "corporate"              // Корпоративный
    case city = "city"                        // Городской
    case regional = "regional"                // Региональный
    
    var displayName: String {
        switch self {
        case .weekly: return "Еженедельный"
        case .seasonal: return "Сезонный"
        case .special: return "Специальный"
        case .corporate: return "Корпоративный"
        case .city: return "Городской"
        case .regional: return "Региональный"
        }
    }
    
    var icon: String {
        switch self {
        case .weekly: return "calendar"
        case .seasonal: return "leaf.fill"
        case .special: return "star.fill"
        case .corporate: return "building.2.fill"
        case .city: return "building.fill"
        case .regional: return "map.fill"
        }
    }
}

/// Участник турнира
struct TournamentParticipant: Identifiable, Codable, Comparable {
    let id: String
    let name: String
    var steps: Int
    var rank: Int = 0
    
    static func < (lhs: TournamentParticipant, rhs: TournamentParticipant) -> Bool {
        return lhs.steps < rhs.steps
    }
}

/// Результат турнира
struct TournamentResult: Codable {
    var rank: Int
    var steps: Int
    var rewardXP: Int
    var rewardTitle: String
}

/// Турнир
struct Tournament: Codable, Identifiable {
    let id: String
    let type: TournamentType
    let name: String
    let startDate: Date
    let endDate: Date
    var participants: [TournamentParticipant]
    var userResult: TournamentResult?
    var isActive: Bool
    var description: String?
    
    // Для обратной совместимости
    var weekStartDate: Date { startDate }
    var weekEndDate: Date { endDate }
    
    var isCurrentWeek: Bool {
        let now = Date()
        return now >= weekStartDate && now <= weekEndDate
    }
    
    var daysRemaining: Int {
        guard isCurrentWeek else { return 0 }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: weekEndDate).day ?? 0
    }
    
    var progress: Double {
        guard isCurrentWeek else { return 0 }
        let total = weekEndDate.timeIntervalSince(weekStartDate)
        let passed = Date().timeIntervalSince(weekStartDate)
        return min(1.0, passed / total)
    }
}

// Обратная совместимость для существующего кода
typealias WeeklyTournament = Tournament

/// Менеджер турниров
@MainActor
final class TournamentManager: ObservableObject {
    
    @Published var currentTournament: Tournament?
    @Published var pastTournaments: [Tournament] = []
    @Published var userRank: Int = 0
    
    private let tournamentKey = "currentTournament"
    private let pastTournamentsKey = "pastTournaments"
    
    init() {
        // Быстрая загрузка критичных данных синхронно
        loadTournaments()
        
        // Проверяем, нужен ли новый турнир (синхронно для первого запуска)
        if currentTournament == nil {
            checkAndStartNewTournament()
        }
        
        // Тяжелые операции - асинхронно (обновление шагов и т.д.)
        Task { @MainActor in
            // Проверяем, что турнир актуален (не истек)
            if let tournament = currentTournament, !tournament.isCurrentWeek {
                checkAndStartNewTournament()
            }
        }
    }
    
    // MARK: - Tournament Management
    
    func checkAndStartNewTournament() {
        let calendar = Calendar.current
        let now = Date()
        
        // Определяем начало текущей недели (понедельник)
        let weekday = calendar.component(.weekday, from: now)
        let daysToMonday = weekday == 1 ? 6 : weekday - 2 // 1 = воскресенье
        guard let weekStart = calendar.date(byAdding: .day, value: -daysToMonday, to: now),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            Logger.shared.logWarning("Не удалось вычислить даты недели для турнира")
            return
        }
        
        // Проверяем, нужен ли новый турнир
        if let current = currentTournament {
            if !current.isCurrentWeek {
                // Завершаем старый турнир и начинаем новый
                finishTournament()
                startNewTournament(weekStart: weekStart, weekEnd: weekEnd)
            }
        } else {
            // Создаём первый турнир
            startNewTournament(weekStart: weekStart, weekEnd: weekEnd)
        }
        
        updateUserRank()
    }
    
    private func startNewTournament(weekStart: Date, weekEnd: Date) {
        let tournamentId = "tournament_\(Int(weekStart.timeIntervalSince1970))"
        
        // Генерируем случайных участников (для демонстрации)
        let participants = generateParticipants()
        
        currentTournament = Tournament(
            id: tournamentId,
            type: .weekly,
            name: "Еженедельный турнир",
            startDate: weekStart,
            endDate: weekEnd,
            participants: participants,
            userResult: nil,
            isActive: true,
            description: "Соревнуйтесь с другими пользователями всю неделю"
        )
        
        saveTournaments()
    }
    
    private func generateParticipants() -> [TournamentParticipant] {
        // Генерируем 10 случайных участников
        let names = ["Анна", "Михаил", "Елена", "Дмитрий", "Ольга", "Алексей", "Мария", "Сергей", "Татьяна", "Игорь"]
        var participants: [TournamentParticipant] = []
        
        // Пользователь всегда первый
        participants.append(TournamentParticipant(
            id: "user",
            name: "Вы",
            steps: 0
        ))
        
        // Генерируем остальных участников со случайными шагами
        for (index, name) in names.enumerated() {
            let randomSteps = Int.random(in: 5000...25000)
            participants.append(TournamentParticipant(
                id: "participant_\(index)",
                name: name,
                steps: randomSteps
            ))
        }
        
        // Сортируем по шагам
        participants.sort { $0.steps > $1.steps }
        
        // Устанавливаем ранги
        for (index, participant) in participants.enumerated() {
            var updated = participant
            updated.rank = index + 1
            participants[index] = updated
        }
        
        return participants
    }
    
    /// Обновляет шаги пользователя в турнире (сумма за всю неделю)
    func updateUserSteps(_ todaySteps: Int) {
        guard var tournament = currentTournament else { return }
        
        // Обновляем шаги пользователя
        if let userIndex = tournament.participants.firstIndex(where: { $0.id == "user" }) {
            // Для турнира нужна сумма шагов за всю неделю
            // Считаем сумму шагов за период турнира (от начала недели до сегодня)
            // Если это первый день недели, просто используем сегодняшние шаги
            // Иначе нужно суммировать шаги за все дни недели
            // Для упрощения: используем сегодняшние шаги + сохраняем накопленную сумму
            let currentUserSteps = tournament.participants[userIndex].steps
            
            // Если сегодняшние шаги больше текущих, значит это новый день - добавляем разницу
            // Иначе просто обновляем (если шаги уменьшились, значит это обновление за сегодня)
            let newTotalSteps: Int
            if todaySteps > currentUserSteps {
                // Новый день или увеличение шагов - добавляем разницу
                newTotalSteps = currentUserSteps + (todaySteps - currentUserSteps)
            } else {
                // Обновление за сегодня - используем максимум из сохраненных или сегодняшних
                // Для правильного подсчета нужно суммировать все дни недели
                // Пока используем простую логику: берем максимум
                newTotalSteps = max(currentUserSteps, todaySteps)
            }
            
            tournament.participants[userIndex].steps = newTotalSteps
            
            // Пересчитываем ранги
            tournament.participants.sort { $0.steps > $1.steps }
            for (index, participant) in tournament.participants.enumerated() {
                var updated = participant
                updated.rank = index + 1
                tournament.participants[index] = updated
            }
            
            currentTournament = tournament
            updateUserRank()
            saveTournaments()
        }
    }
    
    /// Обновляет шаги пользователя из weeklySteps (правильный способ)
    func updateUserStepsFromWeekly(_ weeklySteps: [DailyStepData], tournamentStartDate: Date) {
        guard var tournament = currentTournament else { return }
        
        // Фильтруем шаги за период турнира
        let filteredSteps = weeklySteps.filter { stepData in
            stepData.date >= tournamentStartDate && stepData.date <= Date()
        }
        
        // Суммируем шаги за неделю
        let totalWeeklySteps = filteredSteps.reduce(0) { $0 + $1.steps }
        
        // Обновляем шаги пользователя
        if let userIndex = tournament.participants.firstIndex(where: { $0.id == "user" }) {
            tournament.participants[userIndex].steps = totalWeeklySteps
            
            // Пересчитываем ранги
            tournament.participants.sort { $0.steps > $1.steps }
            for (index, participant) in tournament.participants.enumerated() {
                var updated = participant
                updated.rank = index + 1
                tournament.participants[index] = updated
            }
            
            currentTournament = tournament
            updateUserRank()
            saveTournaments()
        }
    }
    
    func finishTournament() {
        guard var tournament = currentTournament else { return }
        
        // Вычисляем награды для пользователя
        if let userIndex = tournament.participants.firstIndex(where: { $0.id == "user" }) {
            let user = tournament.participants[userIndex]
            let rewardXP = calculateReward(rank: user.rank)
            let rewardTitle = getRewardTitle(rank: user.rank)
            
            tournament.userResult = TournamentResult(
                rank: user.rank,
                steps: user.steps,
                rewardXP: rewardXP,
                rewardTitle: rewardTitle
            )
        }
        
        tournament.isActive = false
        pastTournaments.insert(tournament, at: 0)
        
        // Оставляем только последние 10 турниров
        if pastTournaments.count > 10 {
            pastTournaments = Array(pastTournaments.prefix(10))
        }
        
        currentTournament = nil
        saveTournaments()
    }
    
    private func calculateReward(rank: Int) -> Int {
        switch rank {
        case 1: return 5000
        case 2: return 3000
        case 3: return 2000
        case 4...5: return 1000
        case 6...10: return 500
        default: return 100
        }
    }
    
    private func getRewardTitle(rank: Int) -> String {
        switch rank {
        case 1: return "🥇 Чемпион недели"
        case 2: return "🥈 Второе место"
        case 3: return "🥉 Третье место"
        case 4...5: return "🏅 Топ-5"
        case 6...10: return "⭐ Топ-10"
        default: return "💪 Участник"
        }
    }
    
    private func updateUserRank() {
        if let tournament = currentTournament,
           let user = tournament.participants.first(where: { $0.id == "user" }) {
            userRank = user.rank
        } else {
            userRank = 0
        }
    }
    
    // MARK: - Persistence
    
    private func saveTournaments() {
        if let current = currentTournament,
           let data = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(data, forKey: tournamentKey)
        }
        
        if let data = try? JSONEncoder().encode(pastTournaments) {
            UserDefaults.standard.set(data, forKey: pastTournamentsKey)
        }
    }
    
    private func loadTournaments() {
        if let data = UserDefaults.standard.data(forKey: tournamentKey),
           let tournament = try? JSONDecoder().decode(Tournament.self, from: data) {
            currentTournament = tournament
        }
        
        if let data = UserDefaults.standard.data(forKey: pastTournamentsKey),
           let tournaments = try? JSONDecoder().decode([Tournament].self, from: data) {
            pastTournaments = tournaments
        }
        
        updateUserRank()
    }
    
    // MARK: - Top Participants
    
    var topParticipants: [TournamentParticipant] {
        guard let tournament = currentTournament else { return [] }
        return Array(tournament.participants.prefix(10))
    }
}
