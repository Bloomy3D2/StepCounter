//
//  DIContainer.swift
//  ChallengeApp
//
//  Dependency Injection Container
//

import Foundation
import Supabase

/// Dependency Injection Container для управления зависимостями
class DIContainer {
    nonisolated(unsafe) static let shared = DIContainer()
    
    // MARK: - Managers
    
    private(set) lazy var supabaseManager: any SupabaseManagerProtocol = {
        return SupabaseManager.shared
    }()
    
    private(set) lazy var authManager: any AuthManagerProtocol = {
        return AuthManager()
    }()
    
    private(set) lazy var challengeManager: any ChallengeManagerProtocol = {
        // ChallengeManager помечен как @MainActor, поэтому инициализируем на главном потоке
        return MainActor.assumeIsolated {
            ChallengeManager()
        }
    }()
    
    private(set) lazy var paymentManager: any PaymentManagerProtocol = {
        return PaymentManager()
    }()
    
    private(set) lazy var yooKassaClient: any YooKassaClientProtocol = {
        return YooKassaClient.shared
    }()
    
    // MARK: - Cache Manager
    
    private(set) lazy var cacheManager: any CacheManagerProtocol = {
        return CacheManager.shared
    }()
    
    // MARK: - Network Retry
    
    private(set) lazy var networkRetry: any NetworkRetryProtocol = {
        return NetworkRetry.shared
    }()
    
    // MARK: - Initialization
    
    private init() {
        Logger.shared.info("DIContainer initialized")
    }
    
    // MARK: - Testing Support
    
    #if DEBUG
    /// Для тестирования: возможность заменить менеджеры на моки
    func setSupabaseManager(_ manager: any SupabaseManagerProtocol) {
        // В тестах можно использовать это для инжекции моков
        // В продакшене это не используется
    }
    #endif
}

// MARK: - Convenience Access

extension DIContainer {
    /// Получить менеджер авторизации
    var auth: any AuthManagerProtocol {
        return authManager
    }
    
    /// Получить менеджер челленджей
    var challenges: any ChallengeManagerProtocol {
        return challengeManager
    }
    
    /// Получить менеджер платежей
    var payments: any PaymentManagerProtocol {
        return paymentManager
    }
    
    /// Получить Supabase менеджер
    var supabase: any SupabaseManagerProtocol {
        return supabaseManager
    }
}
