//
//  ChallengeAppApp.swift
//  ChallengeApp
//
//  Приложение для челленджей с денежными ставками
//

import SwiftUI

@main
struct ChallengeAppApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    init() {
        // Инициализируем LanguageManager при старте приложения
        _ = LanguageManager.shared
        
        // Инициализируем NetworkMonitor для мониторинга сети
        _ = NetworkMonitor.shared
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(languageManager)
                .preferredColorScheme(.dark)
                .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
                    // Принудительно обновляем UI при смене языка
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Обновляем данные при возврате в приложение (как в Duolingo, Strava)
                    handleAppWillEnterForeground()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NetworkReconnected"))) { _ in
                    // Обновляем данные пользователя при восстановлении сети
                    Task { @MainActor in
                        await appState.refreshUser()
                    }
                }
                .onOpenURL { url in
                    // Обработка возврата из ЮKassa после оплаты
                    handlePaymentReturnURL(url)
                }
        }
    }
    
    private static var lastForegroundRefresh: Date?
    private static let foregroundRefreshMinInterval: TimeInterval = 5
    
    /// Обработка возврата приложения в foreground (с дебаунсом)
    private func handleAppWillEnterForeground() {
        let now = Date()
        if let last = Self.lastForegroundRefresh, now.timeIntervalSince(last) < Self.foregroundRefreshMinInterval {
            return
        }
        Self.lastForegroundRefresh = now
        Logger.shared.info("📱 ChallengeAppApp: App will enter foreground - refreshing data")
        
        Task { @MainActor in
            let cm = DIContainer.shared.challengeManager
            await cm.loadUserChallengesFromSupabase(forceRefresh: false)
            await cm.loadChallengesFromSupabase(forceRefresh: false)
            await appState.refreshUser()
            
            // Уведомляем о возврате в foreground - это может быть возврат из YooKassa
            // Даже если onOpenURL не сработал, мы проверим статус платежа
            NotificationCenter.default.post(
                name: NSNotification.Name("AppEnteredForeground"),
                object: nil
            )
            
            Logger.shared.info("✅ ChallengeAppApp: Data refreshed after entering foreground")
        }
    }
    
    /// Обработка возврата из платежной системы
    private func handlePaymentReturnURL(_ url: URL) {
        Logger.shared.info("🔗 Payment return URL received: \(url.absoluteString)")
        
        // Проверяем, что это наш URL scheme для платежей
        guard url.scheme == AppConfig.appURLScheme,
              url.host == "payment" else {
            Logger.shared.warning("🔗 Unknown URL scheme: \(url.absoluteString)")
            return
        }
        
        // Извлекаем payment_id из query параметров, если есть
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let paymentId = components.queryItems?.first(where: { $0.name == "payment_id" })?.value {
            Logger.shared.info("🔗 Payment ID from URL: \(paymentId)")
            
            // Уведомляем о возврате из платежной системы
            NotificationCenter.default.post(
                name: NSNotification.Name("PaymentReturned"),
                object: nil,
                userInfo: ["payment_id": paymentId]
            )
        } else {
            // Если payment_id нет в URL, просто уведомляем о возврате
            Logger.shared.info("🔗 Payment return detected (no payment_id in URL)")
            NotificationCenter.default.post(
                name: NSNotification.Name("PaymentReturned"),
                object: nil
            )
        }
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var isOnboardingCompleted = UserDefaults.standard.bool(forKey: "isOnboardingCompleted")
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    init() {
        // Проверяем, есть ли сохраненный пользователь
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    func completeOnboarding() {
        isOnboardingCompleted = true
        UserDefaults.standard.set(true, forKey: "isOnboardingCompleted")
    }
    
    func setUser(_ user: User) {
        currentUser = user
        isAuthenticated = true
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
    }
    
    @MainActor
    func refreshUser() async {
        do {
            if let user = try await DIContainer.shared.supabase.getCurrentUser() {
                self.setUser(user)
                Logger.shared.info("AppState: User refreshed from server, balance: \(user.balance)")
            }
        } catch {
            Logger.shared.warning("AppState: Failed to refresh user from server", error: error)
        }
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
}

// MARK: - Root View
struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var languageManager: LanguageManager
    @State private var showSplash = true
    
    /// Единый ChallengeManager из DIContainer — один экземпляр на всё приложение (табы, foreground, NetworkMonitor).
    private static let sharedChallengeManager: ChallengeManager = (DIContainer.shared.challengeManager as! ChallengeManager)
    
    var body: some View {
        Group {
            if showSplash {
                SplashView(onStart: {
                    Logger.shared.info("📱 RootView: onStart called - switching to AuthView")
                    withAnimation { showSplash = false }
                })
            } else if !appState.isAuthenticated {
                AuthView()
                    .onChange(of: appState.isAuthenticated) { _, newValue in
                        if newValue {
                            Logger.shared.info("📱 RootView: User authenticated")
                            Task { await AnalyticsManager.shared.trackSessionStartIfNeeded() }
                        }
                    }
            } else {
                MainTabView()
            }
        }
        .id(languageManager.currentLanguage.rawValue)
        .environmentObject(RootView.sharedChallengeManager)
    }
}
