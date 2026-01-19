//
//  DIContainer.swift
//  StepCounter
//
//  Dependency Injection Container для управления зависимостями
//

import Foundation
import Combine

/// Контейнер зависимостей для управления всеми менеджерами
@MainActor
class DIContainer: ObservableObject {
    
    // MARK: - Singleton (для обратной совместимости)
    static let shared = DIContainer()
    
    // MARK: - Core Managers
    
    /// Менеджер HealthKit
    lazy var healthManager: HealthManagerProtocol = {
        HealthManager()
    }()
    
    /// Менеджер достижений
    lazy var achievementManager: AchievementManagerProtocol = {
        AchievementManager()
    }()
    
    /// Менеджер челленджей
    lazy var challengeManager: ChallengeManagerProtocol = {
        ChallengeManager()
    }()
    
    /// Менеджер локаций
    lazy var locationManager: LocationManager = {
        LocationManager()
    }()
    
    /// Менеджер питомца
    lazy var petManager: PetManagerProtocol = {
        PetManager()
    }()
    
    /// Менеджер уровней
    lazy var levelManager: LevelManagerProtocol = {
        LevelManager()
    }()
    
    /// Менеджер турниров
    lazy var tournamentManager: TournamentManagerProtocol = {
        TournamentManager()
    }()
    
    /// Менеджер групповых челленджей
    lazy var groupChallengeManager: GroupChallengeManagerProtocol = {
        GroupChallengeManager()
    }()
    
    /// Менеджер сезонов
    lazy var seasonManager: SeasonManager = {
        SeasonManager.shared
    }()
    
    /// Менеджер согласия на обработку данных
    lazy var consentManager: PrivacyConsentManager = {
        PrivacyConsentManager.shared
    }()
    
    // MARK: - Service Managers (Singletons)
    
    /// Менеджер хранения данных
    var storageManager: StorageManagerProtocol {
        StorageManager.shared
    }
    
    /// Менеджер тем
    var themeManager: ThemeManager {
        ThemeManager.shared
    }
    
    /// Менеджер подписок
    var subscriptionManager: SubscriptionManager {
        SubscriptionManager.shared
    }
    
    /// Менеджер рекламы
    var adManager: AdManager {
        AdManager.shared
    }
    
    /// Менеджер уведомлений
    var notificationManager: NotificationManager {
        NotificationManager.shared
    }
    
    /// Менеджер авторизации
    var authManager: AuthManager {
        AuthManager.shared
    }
    
    /// Менеджер Apple Sign In
    var appleSignInManager: AppleSignInManager {
        AppleSignInManager.shared
    }
    
    /// Менеджер рефералов
    var referralManager: ReferralManager {
        ReferralManager.shared
    }
    
    /// Менеджер отзывов
    var reviewManager: ReviewManager {
        ReviewManager.shared
    }
    
    /// Менеджер экспорта данных
    var dataExportManager: DataExportManager {
        DataExportManager.shared
    }
    
    // MARK: - Initialization
    
    init() {
        // Инициализатор для singleton и подклассов (для тестирования)
    }
    
    // MARK: - Setup
    
    /// Настройка DataCoordinator со всеми зависимостями
    func setupDataCoordinator() {
        DataCoordinator.shared.setup(
            achievementManager: achievementManager,
            challengeManager: challengeManager,
            petManager: petManager,
            levelManager: levelManager,
            tournamentManager: tournamentManager,
            groupChallengeManager: groupChallengeManager
        )
        
        // Логируем статус настройки
        DataCoordinator.shared.logSetupStatus()
    }
    
    // MARK: - Reset (для тестирования)
    
    /// Сброс всех зависимостей (используется в тестах)
    func reset() {
        // В production не используется
        // Для тестов можно создать отдельный TestDIContainer
    }
}

// MARK: - Test DIContainer (для unit-тестов)

#if DEBUG
/// Тестовый контейнер для unit-тестов
@MainActor
final class TestDIContainer: DIContainer {
    
    // Переопределяем менеджеры для использования моков
    
    override var healthManager: HealthManagerProtocol {
        get { _healthManager ?? super.healthManager }
        set { _healthManager = newValue }
    }
    
    override var achievementManager: AchievementManagerProtocol {
        get { _achievementManager ?? super.achievementManager }
        set { _achievementManager = newValue }
    }
    
    override var challengeManager: ChallengeManagerProtocol {
        get { _challengeManager ?? super.challengeManager }
        set { _challengeManager = newValue }
    }
    
    override var petManager: PetManagerProtocol {
        get { _petManager ?? super.petManager }
        set { _petManager = newValue }
    }
    
    override var levelManager: LevelManagerProtocol {
        get { _levelManager ?? super.levelManager }
        set { _levelManager = newValue }
    }
    
    override var tournamentManager: TournamentManagerProtocol {
        get { _tournamentManager ?? super.tournamentManager }
        set { _tournamentManager = newValue }
    }
    
    override var groupChallengeManager: GroupChallengeManagerProtocol {
        get { _groupChallengeManager ?? super.groupChallengeManager }
        set { _groupChallengeManager = newValue }
    }
    
    // MARK: - Private Properties
    
    private var _healthManager: HealthManagerProtocol?
    private var _achievementManager: AchievementManagerProtocol?
    private var _challengeManager: ChallengeManagerProtocol?
    private var _petManager: PetManagerProtocol?
    private var _levelManager: LevelManagerProtocol?
    private var _tournamentManager: TournamentManagerProtocol?
    private var _groupChallengeManager: GroupChallengeManagerProtocol?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
}
#endif
