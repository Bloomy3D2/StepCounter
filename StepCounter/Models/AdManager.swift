//
//  AdManager.swift
//  StepCounter
//
//  Менеджер рекламы (Google AdMob)
//
//  ВАЖНО: Для работы необходимо:
//  1. Добавить Google Mobile Ads SDK через SPM:
//     https://github.com/googleads/swift-package-manager-google-mobile-ads
//  2. Добавить в Info.plist:
//     - GADApplicationIdentifier: ваш App ID из AdMob
//     - SKAdNetworkItems: список идентификаторов
//

import Foundation
import SwiftUI

// MARK: - Ad Types

/// Типы рекламных блоков
enum AdUnitType: String {
    case rewardedVideo = "rewarded_video"
    case interstitial = "interstitial"
    case banner = "banner"
    
    /// Тестовые ID от Google (для разработки)
    var testAdUnitID: String {
        switch self {
        case .rewardedVideo:
            return "ca-app-pub-3940256099942544/1712485313"
        case .interstitial:
            return "ca-app-pub-3940256099942544/4411468910"
        case .banner:
            return "ca-app-pub-3940256099942544/2435281174"
        }
    }
    
    /// Реальные ID (замените на свои из AdMob Console)
    var productionAdUnitID: String {
        switch self {
        case .rewardedVideo:
            return "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"  // Замените
        case .interstitial:
            return "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"  // Замените
        case .banner:
            return "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"  // Замените
        }
    }
}

// MARK: - Ad Placement

/// Места показа рекламы в приложении
enum AdPlacement: String, CaseIterable {
    case doubleStepsReward      // Удвоить шаги за сегодня
    case bonusXPForPet          // Бонус XP для питомца
    case unlockAchievement      // Разблокировать достижение быстрее
    case extraRouteSlot         // Дополнительный слот для маршрута
    case dailyBonus             // Увеличить ежедневный бонус
    case reviveStreak           // Восстановить серию
    case refreshQuest            // Обновить задание
    
    var title: String {
        switch self {
        case .doubleStepsReward: return "Удвоить шаги"
        case .bonusXPForPet: return "Бонус для питомца"
        case .unlockAchievement: return "Ускорить достижение"
        case .extraRouteSlot: return "Доп. маршрут"
        case .dailyBonus: return "Увеличить бонус"
        case .reviveStreak: return "Восстановить серию"
        case .refreshQuest: return "Обновить задание"
        }
    }
    
    var description: String {
        switch self {
        case .doubleStepsReward: return "Посмотри рекламу и получи x2 шаги!"
        case .bonusXPForPet: return "+500 XP для твоего питомца"
        case .unlockAchievement: return "Ускорь прогресс достижения"
        case .extraRouteSlot: return "Сохрани ещё один маршрут"
        case .dailyBonus: return "Получи x2 ежедневный бонус"
        case .reviveStreak: return "Не потеряй свою серию!"
        case .refreshQuest: return "Получи новое задание"
        }
    }
    
    var icon: String {
        switch self {
        case .doubleStepsReward: return "figure.walk.motion"
        case .bonusXPForPet: return "pawprint.fill"
        case .unlockAchievement: return "trophy.fill"
        case .extraRouteSlot: return "map.fill"
        case .dailyBonus: return "gift.fill"
        case .reviveStreak: return "flame.fill"
        case .refreshQuest: return "arrow.clockwise"
        }
    }
    
    var rewardAmount: Int {
        switch self {
        case .doubleStepsReward: return 2     // Множитель
        case .bonusXPForPet: return 500       // XP
        case .unlockAchievement: return 25    // % прогресса
        case .extraRouteSlot: return 1        // Слот
        case .dailyBonus: return 2            // Множитель
        case .reviveStreak: return 1          // Восстановление
        case .refreshQuest: return 1          // Обновление
        }
    }
}

// MARK: - Ad Reward

/// Результат просмотра рекламы
struct AdReward {
    let placement: AdPlacement
    let amount: Int
    let timestamp: Date
}

// MARK: - Ad Manager

/// Менеджер рекламы
/// ПРИМЕЧАНИЕ: Это заглушка. Для реальной интеграции раскомментируйте код с GoogleMobileAds
@MainActor
final class AdManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AdManager()
    
    // MARK: - Dependencies
    
    private let subscriptionManager = SubscriptionManager.shared
    
    // MARK: - Published
    
    /// Готова ли rewarded реклама к показу
    @Published private(set) var isRewardedAdReady: Bool = false
    
    /// Готова ли interstitial реклама
    @Published private(set) var isInterstitialReady: Bool = false
    
    /// Идёт ли загрузка рекламы
    @Published private(set) var isLoading: Bool = false
    
    /// Показывается ли реклама сейчас
    @Published private(set) var isShowingAd: Bool = false
    
    /// Последняя ошибка
    @Published var lastError: String?
    
    /// Количество просмотренных реклам сегодня
    @Published private(set) var adsWatchedToday: Int = 0
    
    // MARK: - Config
    
    /// Максимум рекламы в день (чтобы не раздражать)
    let maxAdsPerDay: Int = 10
    
    /// Использовать тестовые ID (для разработки)
    #if DEBUG
    private let useTestAds = true
    #else
    private let useTestAds = false
    #endif
    
    // MARK: - Private
    
    private let adsWatchedKey = "adsWatchedToday"
    private let lastAdDateKey = "lastAdDate"
    
    // Для реальной интеграции:
    // private var rewardedAd: GADRewardedAd?
    // private var interstitialAd: GADInterstitialAd?
    
    // MARK: - Init
    
    private init() {
        loadDailyStats()
        preloadAds()
    }
    
    // MARK: - Daily Stats
    
    private func loadDailyStats() {
        let today = Calendar.current.startOfDay(for: Date())
        
        let storage = StorageManager.shared
        if let lastDate = storage.loadDate(forKey: lastAdDateKey) {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            
            if today == lastDay {
                adsWatchedToday = storage.loadInt(forKey: adsWatchedKey)
            } else {
                // Новый день — сбрасываем счётчик
                adsWatchedToday = 0
                storage.saveInt(0, forKey: adsWatchedKey)
            }
        }
        
        storage.saveDate(today, forKey: lastAdDateKey)
    }
    
    private func incrementAdsWatched() {
        adsWatchedToday += 1
        StorageManager.shared.saveInt(adsWatchedToday, forKey: adsWatchedKey)
    }
    
    /// Можно ли показать ещё рекламу
    var canShowMoreAds: Bool {
        return adsWatchedToday < maxAdsPerDay
    }
    
    /// Сколько рекламы осталось
    var remainingAds: Int {
        return max(0, maxAdsPerDay - adsWatchedToday)
    }
    
    // MARK: - Preload
    
    /// Предзагрузка рекламы
    func preloadAds() {
        loadRewardedAd()
        loadInterstitialAd()
    }
    
    /// Загрузка rewarded рекламы
    func loadRewardedAd() {
        guard !isLoading else { return }
        
        isLoading = true
        
        // ЗАГЛУШКА: Симуляция загрузки
        // Для реальной интеграции используйте GADRewardedAd.load(...)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isLoading = false
            self?.isRewardedAdReady = true
            print("✅ Rewarded реклама загружена (симуляция)")
        }
        
        /*
        // РЕАЛЬНАЯ ИНТЕГРАЦИЯ (раскомментируйте):
        let adUnitID = useTestAds ? AdUnitType.rewardedVideo.testAdUnitID : AdUnitType.rewardedVideo.productionAdUnitID
        
        GADRewardedAd.load(withAdUnitID: adUnitID, request: GADRequest()) { [weak self] ad, error in
            self?.isLoading = false
            
            if let error = error {
                print("❌ Ошибка загрузки rewarded: \(error)")
                self?.lastError = error.localizedDescription
                return
            }
            
            self?.rewardedAd = ad
            self?.isRewardedAdReady = true
            print("✅ Rewarded реклама загружена")
        }
        */
    }
    
    /// Загрузка interstitial рекламы
    func loadInterstitialAd() {
        // Аналогично loadRewardedAd
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isInterstitialReady = true
        }
    }
    
    // MARK: - Show Ads
    
    /// Показать rewarded рекламу
    /// - Parameters:
    ///   - placement: Место показа
    ///   - completion: Callback с результатом (награда или nil при ошибке)
    func showRewardedAd(
        for placement: AdPlacement,
        completion: @escaping (AdReward?) -> Void
    ) {
        // Проверяем Premium - если Premium, то сразу даём награду без рекламы
        if subscriptionManager.hasAccess(to: .noAds) {
            let reward = AdReward(
                placement: placement,
                amount: placement.rewardAmount,
                timestamp: Date()
            )
            completion(reward)
            return
        }
        
        // Проверяем лимит
        guard canShowMoreAds else {
            lastError = "Достигнут лимит рекламы на сегодня"
            completion(nil)
            return
        }
        
        // Проверяем готовность
        guard isRewardedAdReady else {
            lastError = "Реклама ещё загружается"
            loadRewardedAd()
            completion(nil)
            return
        }
        
        isShowingAd = true
        isRewardedAdReady = false
        
        // ЗАГЛУШКА: Симуляция просмотра рекламы
        print("📺 Показ рекламы: \(placement.title)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isShowingAd = false
            self?.incrementAdsWatched()
            
            // Выдаём награду
            let reward = AdReward(
                placement: placement,
                amount: placement.rewardAmount,
                timestamp: Date()
            )
            
            print("🎁 Награда получена: \(placement.title) x\(placement.rewardAmount)")
            completion(reward)
            
            // Перезагружаем следующую рекламу
            self?.loadRewardedAd()
        }
        
        /*
        // РЕАЛЬНАЯ ИНТЕГРАЦИЯ:
        guard let ad = rewardedAd,
              let rootVC = UIApplication.shared.rootViewController else {
            completion(nil)
            return
        }
        
        ad.present(fromRootViewController: rootVC) { [weak self] in
            let rewardType = ad.adReward.type
            let amount = ad.adReward.amount.intValue
            
            self?.isShowingAd = false
            self?.incrementAdsWatched()
            
            let reward = AdReward(placement: placement, amount: amount, timestamp: Date())
            completion(reward)
            
            self?.loadRewardedAd()
        }
        */
    }
    
    /// Показать interstitial между экранами
    func showInterstitial(completion: @escaping () -> Void) {
        // Проверяем Premium - если Premium, пропускаем рекламу
        if subscriptionManager.hasAccess(to: .noAds) {
            completion()
            return
        }
        
        guard isInterstitialReady else {
            completion()
            return
        }
        
        isInterstitialReady = false
        
        // ЗАГЛУШКА
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.loadInterstitialAd()
            completion()
        }
    }
}

// MARK: - UIApplication Extension

extension UIApplication {
    /// Получить root view controller для показа рекламы
    var rootViewController: UIViewController? {
        guard let scene = connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
}

// MARK: - SwiftUI View для кнопки "Смотреть рекламу"

/// Кнопка для просмотра рекламы с наградой
struct WatchAdButton: View {
    let placement: AdPlacement
    let onReward: (AdReward) -> Void
    
    @StateObject private var adManager = AdManager.shared
    @State private var isLoading = false
    
    private let accentGreen = Color(red: 0.3, green: 0.85, blue: 0.5)
    
    var body: some View {
        Button {
            watchAd()
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "play.rectangle.fill")
                    Text(placement.title)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(
                    adManager.canShowMoreAds ? accentGreen : Color.gray
                )
            )
        }
        .disabled(!adManager.canShowMoreAds || isLoading)
    }
    
    private func watchAd() {
        isLoading = true
        
        adManager.showRewardedAd(for: placement) { reward in
            isLoading = false
            
            if let reward = reward {
                onReward(reward)
            }
        }
    }
}

/// Карточка с предложением посмотреть рекламу
struct AdOfferCard: View {
    let placement: AdPlacement
    let onReward: (AdReward) -> Void
    
    private let cardColor = Color(red: 0.08, green: 0.08, blue: 0.12)
    private let accentGreen = Color(red: 0.3, green: 0.85, blue: 0.5)
    
    var body: some View {
        HStack(spacing: 14) {
            // Иконка
            ZStack {
                Circle()
                    .fill(accentGreen.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: placement.icon)
                    .font(.system(size: 20))
                    .foregroundColor(accentGreen)
            }
            
            // Текст
            VStack(alignment: .leading, spacing: 4) {
                Text(placement.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(placement.description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Кнопка
            WatchAdButton(placement: placement, onReward: onReward)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(cardColor))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        AdOfferCard(placement: .bonusXPForPet) { reward in
            print("Получено: \(reward.amount)")
        }
        
        AdOfferCard(placement: .doubleStepsReward) { reward in
            print("Получено: \(reward.amount)")
        }
        
        AdOfferCard(placement: .reviveStreak) { reward in
            print("Получено: \(reward.amount)")
        }
    }
    .padding()
    .background(Color(red: 0.02, green: 0.02, blue: 0.05))
}
