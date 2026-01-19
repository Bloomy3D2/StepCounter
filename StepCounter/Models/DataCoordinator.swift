//
//  DataCoordinator.swift
//  StepCounter
//
//  Координатор для оптимизации обновлений данных при изменении шагов
//

import Foundation
import Combine

// Импортируем протоколы
// Протоколы определены в ManagerProtocols.swift

/// Координирует обновления всех менеджеров при изменении данных о шагах
@MainActor
class DataCoordinator: ObservableObject {
    
    // MARK: - Singleton
    static let shared = DataCoordinator()
    
    // MARK: - Dependencies
    private weak var achievementManager: AchievementManagerProtocol?
    private weak var challengeManager: ChallengeManagerProtocol?
    private weak var petManager: PetManagerProtocol?
    private weak var levelManager: LevelManagerProtocol?
    private weak var tournamentManager: TournamentManagerProtocol?
    private weak var groupChallengeManager: GroupChallengeManagerProtocol?
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Setup
    
    func setup(
        achievementManager: AchievementManagerProtocol,
        challengeManager: ChallengeManagerProtocol,
        petManager: PetManagerProtocol,
        levelManager: LevelManagerProtocol,
        tournamentManager: TournamentManagerProtocol,
        groupChallengeManager: GroupChallengeManagerProtocol
    ) {
        self.achievementManager = achievementManager
        self.challengeManager = challengeManager
        self.petManager = petManager
        self.levelManager = levelManager
        self.tournamentManager = tournamentManager
        self.groupChallengeManager = groupChallengeManager
    }
    
    // MARK: - Steps Changed
    
    /// Вызывается при изменении количества шагов
    /// Координирует все обновления в правильном порядке
    func onStepsChanged(
        steps: Int,
        distance: Double,
        calories: Double,
        goalReached: Bool,
        stepGoal: Int,
        streak: Int
    ) {
        // Проверяем наличие менеджеров перед использованием
        guard let achievementManager = achievementManager else {
            Logger.shared.logWarning("AchievementManager is nil in DataCoordinator")
            return
        }
        
        // 1. Обновляем достижения (первым, т.к. может повлиять на streak)
        achievementManager.checkAchievements(
            steps: steps,
            distance: distance,
            calories: calories,
            goalReached: goalReached,
            stepGoal: stepGoal
        )
        
        // 2. Обновляем челленджи (использует streak из достижений)
        let currentStreak = achievementManager.currentStreak
        if let challengeManager = challengeManager {
            challengeManager.updateProgress(
                steps: steps,
                distance: distance,
                calories: calories,
                streak: currentStreak
            )
        } else {
            Logger.shared.logWarning("ChallengeManager is nil in DataCoordinator")
        }
        
        // 3. Кормим питомца
        if let petManager = petManager {
            petManager.feedPet(steps: steps)
        } else {
            Logger.shared.logWarning("PetManager is nil in DataCoordinator")
        }
        
        // 4. Обновляем уровень игрока
        if let levelManager = levelManager {
            levelManager.addSteps(
                steps,
                distance: distance,
                calories: calories
            )
        } else {
            Logger.shared.logWarning("LevelManager is nil in DataCoordinator")
        }
        
        // 5. Турнир обновляется автоматически через onChange в StepCounterApp
        // (использует weeklySteps для правильного подсчета суммы за неделю)
        
        // 6. Обновляем групповые челленджи
        if let groupChallengeManager = groupChallengeManager {
            groupChallengeManager.updateUserProgress(
                type: .dailySteps,
                steps: steps,
                distance: distance,
                calories: calories
            )
        } else {
            Logger.shared.logWarning("GroupChallengeManager is nil in DataCoordinator")
        }
    }
    
    // MARK: - Goal Reached
    
    func onGoalReached() {
        NotificationManager.shared.sendGoalReachedNotification()
    }
    
    // MARK: - Almost There
    
    func onAlmostThere(remaining: Int) {
        NotificationManager.shared.sendAlmostThereNotification(remaining: remaining)
    }
    
    // MARK: - Achievement Unlocked
    
    func onAchievementUnlocked(title: String) {
        NotificationManager.shared.sendAchievementNotification(title: title)
    }
    
    // MARK: - Validation
    
    /// Проверяет, что все менеджеры настроены
    var isSetupComplete: Bool {
        achievementManager != nil &&
        challengeManager != nil &&
        petManager != nil &&
        levelManager != nil &&
        tournamentManager != nil &&
        groupChallengeManager != nil
    }
    
    /// Логирует статус настройки всех менеджеров
    func logSetupStatus() {
        Logger.shared.logInfo("DataCoordinator setup status:")
        Logger.shared.logInfo("  AchievementManager: \(achievementManager != nil ? "✓" : "✗")")
        Logger.shared.logInfo("  ChallengeManager: \(challengeManager != nil ? "✓" : "✗")")
        Logger.shared.logInfo("  PetManager: \(petManager != nil ? "✓" : "✗")")
        Logger.shared.logInfo("  LevelManager: \(levelManager != nil ? "✓" : "✗")")
        Logger.shared.logInfo("  TournamentManager: \(tournamentManager != nil ? "✓" : "✗")")
        Logger.shared.logInfo("  GroupChallengeManager: \(groupChallengeManager != nil ? "✓" : "✗")")
    }
}
