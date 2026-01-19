//
//  AdManager.swift
//  NegativeSpace
//
//  Менеджер рекламы (Google AdMob)
//
//  ИНСТРУКЦИЯ ПО ИНТЕГРАЦИИ AdMob:
//  1. Добавь Google Mobile Ads SDK через Swift Package Manager:
//     File → Add Package Dependencies → https://github.com/googleads/swift-package-manager-google-mobile-ads
//
//  2. Создай аккаунт AdMob: https://admob.google.com
//
//  3. Создай приложение в AdMob и получи:
//     - App ID (ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY)
//     - Ad Unit IDs для каждого типа рекламы
//
//  4. Добавь в Info.plist:
//     <key>GADApplicationIdentifier</key>
//     <string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
//
//  5. Замени тестовые ID на реальные перед публикацией
//

import SwiftUI

// MARK: - Ad Configuration

/// Конфигурация рекламы
struct AdConfig {
    // ⚠️ ТЕСТОВЫЕ ID - замени на реальные перед публикацией!
    
    /// ID приложения AdMob
    static let appID = "ca-app-pub-3940256099942544~1458002511" // Тестовый
    
    /// ID для Rewarded Video (за подсказки)
    static let rewardedAdID = "ca-app-pub-3940256099942544/1712485313" // Тестовый
    
    /// ID для Interstitial (между уровнями)
    static let interstitialAdID = "ca-app-pub-3940256099942544/4411468910" // Тестовый
    
    /// Показывать interstitial каждые N уровней
    static let interstitialFrequency = 3
    
    /// Награда за просмотр rewarded video
    static let hintsReward = 2
}

// MARK: - Ad Manager

/// Менеджер рекламы
/// 
/// После интеграции SDK раскомментируй код и импорты
final class AdManager: ObservableObject {
    
    static let shared = AdManager()
    
    // MARK: - Published Properties
    
    /// Rewarded реклама загружена
    @Published var isRewardedAdReady = false
    
    /// Interstitial реклама загружена
    @Published var isInterstitialReady = false
    
    /// Счётчик пройденных уровней (для показа interstitial)
    @Published var levelsSinceLastAd = 0
    
    // MARK: - Private Properties
    
    // После интеграции SDK:
    // private var rewardedAd: GADRewardedAd?
    // private var interstitialAd: GADInterstitialAd?
    
    private init() {
        // Инициализация SDK
        // После интеграции:
        // GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        loadAds()
    }
    
    // MARK: - Public Methods
    
    /// Загрузить рекламу
    func loadAds() {
        loadRewardedAd()
        loadInterstitialAd()
    }
    
    /// Показать rewarded рекламу за подсказки
    func showRewardedAd(onReward: @escaping (Int) -> Void) {
        // После интеграции SDK:
        /*
        guard let rewardedAd = rewardedAd,
              let rootVC = getRootViewController() else {
            print("Rewarded ad not ready")
            return
        }
        
        rewardedAd.present(fromRootViewController: rootVC) {
            let reward = rewardedAd.adReward
            print("User earned reward: \(reward.amount) \(reward.type)")
            onReward(AdConfig.hintsReward)
        }
        
        // Загружаем следующую рекламу
        loadRewardedAd()
        */
        
        // Заглушка для тестирования (убрать после интеграции SDK)
        print("📺 [AdManager] Showing rewarded ad (mock)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            onReward(AdConfig.hintsReward)
        }
    }
    
    /// Показать interstitial рекламу
    func showInterstitialIfNeeded() {
        levelsSinceLastAd += 1
        
        guard levelsSinceLastAd >= AdConfig.interstitialFrequency else {
            return
        }
        
        // После интеграции SDK:
        /*
        guard let interstitialAd = interstitialAd,
              let rootVC = getRootViewController() else {
            print("Interstitial ad not ready")
            return
        }
        
        interstitialAd.present(fromRootViewController: rootVC)
        levelsSinceLastAd = 0
        loadInterstitialAd()
        */
        
        // Заглушка для тестирования
        print("📺 [AdManager] Showing interstitial ad (mock)")
        levelsSinceLastAd = 0
    }
    
    // MARK: - Private Methods
    
    private func loadRewardedAd() {
        // После интеграции SDK:
        /*
        let request = GADRequest()
        GADRewardedAd.load(withAdUnitID: AdConfig.rewardedAdID, request: request) { [weak self] ad, error in
            if let error = error {
                print("Failed to load rewarded ad: \(error)")
                self?.isRewardedAdReady = false
                return
            }
            self?.rewardedAd = ad
            self?.isRewardedAdReady = true
            print("Rewarded ad loaded successfully")
        }
        */
        
        // Заглушка
        isRewardedAdReady = true
    }
    
    private func loadInterstitialAd() {
        // После интеграции SDK:
        /*
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: AdConfig.interstitialAdID, request: request) { [weak self] ad, error in
            if let error = error {
                print("Failed to load interstitial: \(error)")
                self?.isInterstitialReady = false
                return
            }
            self?.interstitialAd = ad
            self?.isInterstitialReady = true
            print("Interstitial loaded successfully")
        }
        */
        
        // Заглушка
        isInterstitialReady = true
    }
    
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return nil
        }
        return rootVC
    }
}

// MARK: - SwiftUI View Extension

extension View {
    /// Показать кнопку "Получить подсказки за рекламу"
    func rewardedAdButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "play.rectangle.fill")
                Text("Смотреть рекламу")
                Text("+\(AdConfig.hintsReward)")
                    .fontWeight(.bold)
                Image(systemName: "lightbulb.fill")
            }
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.orange, Color.red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
        }
    }
}
