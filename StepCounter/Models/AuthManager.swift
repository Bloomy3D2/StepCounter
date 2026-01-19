//
//  AuthManager.swift
//  StepCounter
//
//  Менеджер аутентификации (использует Sign in with Apple)
//

import Foundation
import Combine

/// Менеджер аутентификации
@MainActor
final class AuthManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AuthManager()
    
    // MARK: - Published
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private
    private let appleSignInManager = AppleSignInManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    private init() {
        // Синхронизируем начальное состояние
        updateState()
        
        // Подписываемся на изменения через Combine
        appleSignInManager.$isAuthenticated
            .sink { [weak self] newValue in
                Task { @MainActor in
                    self?.isAuthenticated = newValue
                }
            }
            .store(in: &cancellables)
        
        appleSignInManager.$isLoading
            .sink { [weak self] newValue in
                Task { @MainActor in
                    self?.isLoading = newValue
                }
            }
            .store(in: &cancellables)
        
        appleSignInManager.$errorMessage
            .sink { [weak self] newValue in
                Task { @MainActor in
                    self?.errorMessage = newValue
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    private func updateState() {
        isAuthenticated = appleSignInManager.isAuthenticated
        isLoading = appleSignInManager.isLoading
        errorMessage = appleSignInManager.errorMessage
    }
    
    // MARK: - Public Methods
    
    /// Получить идентификатор пользователя
    var userIdentifier: String? {
        appleSignInManager.userIdentifier
    }
    
    /// Получить email пользователя
    var userEmail: String? {
        appleSignInManager.userEmail
    }
    
    /// Получить имя пользователя
    var userDisplayName: String? {
        appleSignInManager.userDisplayName
    }
    
    /// Выход из аккаунта
    func signOut() {
        appleSignInManager.signOut()
    }
}
