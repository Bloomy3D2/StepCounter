//
//  AppleSignInManager.swift
//  StepCounter
//
//  Менеджер авторизации через Sign in with Apple
//

import Foundation
import AuthenticationServices
import SwiftUI

@MainActor
final class AppleSignInManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    static let shared = AppleSignInManager()
    
    // MARK: - Published
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var userIdentifier: String?
    @Published var userEmail: String?
    @Published var userDisplayName: String?
    
    // MARK: - Private
    private let userIdentifierKey = "appleSignInUserIdentifier"
    private let userEmailKey = "appleSignInUserEmail"
    private let userDisplayNameKey = "appleSignInUserDisplayName"
    
    // MARK: - Init
    private override init() {
        super.init()
        loadSavedUser()
    }
    
    // MARK: - Public Methods
    
    /// Проверка, доступна ли Sign in with Apple
    var isAvailable: Bool {
        guard #available(iOS 13.0, *) else {
            return false
        }
        
        // Проверяем наличие capability в entitlements файле
        guard let entitlementsPath = Bundle.main.path(forResource: "StepCounter", ofType: "entitlements"),
              let entitlementsData = NSDictionary(contentsOfFile: entitlementsPath),
              let appleSignIn = entitlementsData["com.apple.developer.applesignin"] as? [String],
              !appleSignIn.isEmpty else {
            // Capability не настроена - это нормально для Personal Team
            return false
        }
        
        return true
    }
    
    /// Загрузка сохраненных данных пользователя
    private func loadSavedUser() {
        let storage = StorageManager.shared
        userIdentifier = storage.loadString(forKey: userIdentifierKey)
        userEmail = storage.loadString(forKey: userEmailKey)
        userDisplayName = storage.loadString(forKey: userDisplayNameKey)
        isAuthenticated = userIdentifier != nil
    }
    
    /// Сохранение данных пользователя
    private func saveUser(identifier: String, email: String?, displayName: String?) {
        let storage = StorageManager.shared
        storage.saveString(identifier, forKey: userIdentifierKey)
        
        if let email = email {
            storage.saveString(email, forKey: userEmailKey)
        }
        
        if let displayName = displayName {
            storage.saveString(displayName, forKey: userDisplayNameKey)
        }
        
        userIdentifier = identifier
        userEmail = email
        userDisplayName = displayName
        isAuthenticated = true
    }
    
    /// Выход из аккаунта
    func signOut() {
        let storage = StorageManager.shared
        storage.remove(forKey: userIdentifierKey)
        storage.remove(forKey: userEmailKey)
        storage.remove(forKey: userDisplayNameKey)
        
        userIdentifier = nil
        userEmail = nil
        userDisplayName = nil
        isAuthenticated = false
        errorMessage = nil
    }
    
    /// Обработка успешной авторизации
    func handleAuthorization(authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "Не удалось получить данные авторизации"
            return
        }
        
        let userIdentifier = appleIDCredential.user
        let email = appleIDCredential.email
        let fullName = appleIDCredential.fullName
        
        // Формируем имя пользователя
        var displayName: String?
        if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
            displayName = "\(givenName) \(familyName)"
        } else if let givenName = fullName?.givenName {
            displayName = givenName
        } else if let familyName = fullName?.familyName {
            displayName = familyName
        }
        
        // Сохраняем данные
        saveUser(identifier: userIdentifier, email: email, displayName: displayName)
        
        isLoading = false
        errorMessage = nil
        
        // Если email не был предоставлен (пользователь скрыл его), пытаемся загрузить из сохраненных данных
        if email == nil {
            self.userEmail = StorageManager.shared.loadString(forKey: userEmailKey)
        }
    }
    
    /// Обработка ошибки авторизации
    func handleError(_ error: Error) {
        isLoading = false
        
        // Логируем ошибку для отладки
        Logger.shared.logError(error, context: "Apple Sign In")
        
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                // Пользователь отменил - не показываем ошибку
                errorMessage = nil
            case .failed:
                errorMessage = "Не удалось выполнить вход. Проверьте настройки Apple ID."
            case .invalidResponse:
                errorMessage = "Неверный ответ от сервера. Попробуйте позже."
            case .notHandled:
                errorMessage = "Запрос не обработан. Попробуйте позже."
            case .unknown:
                errorMessage = "Произошла неизвестная ошибка. Попробуйте позже."
            @unknown default:
                errorMessage = "Произошла ошибка. Попробуйте позже."
            }
        } else {
            // Обработка других типов ошибок (например, AKAuthenticationError)
            let nsError = error as NSError
            if nsError.domain == "com.apple.AuthenticationServices.AuthorizationError" {
                switch nsError.code {
                case 1000:
                    errorMessage = "Не удалось выполнить запрос авторизации. Проверьте подключение к интернету."
                case 1001:
                    errorMessage = "Авторизация отменена"
                default:
                    errorMessage = "Ошибка авторизации: \(nsError.localizedDescription)"
                }
            } else if nsError.domain == "AKAuthenticationError" {
                switch nsError.code {
                case -7026:
                    errorMessage = "Проблема с конфигурацией Apple ID. Проверьте настройки устройства."
                default:
                    errorMessage = "Ошибка Apple ID: \(nsError.localizedDescription)"
                }
            } else {
                errorMessage = error.localizedDescription.isEmpty ? "Произошла ошибка. Попробуйте позже." : error.localizedDescription
            }
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInManager: ASAuthorizationControllerDelegate {
    
    @MainActor
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        // Обработка успешной авторизации
        handleAuthorization(authorization: authorization)
    }
    
    @MainActor
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Обработка ошибки
        handleError(error)
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleSignInManager: ASAuthorizationControllerPresentationContextProviding {
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Получаем активную window scene
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            // Fallback: берем первую доступную window из всех сцен
            guard let fallbackWindowScene = UIApplication.shared.connectedScenes
                .first(where: { $0 is UIWindowScene }) as? UIWindowScene,
                let window = fallbackWindowScene.windows.first else {
                // Последний fallback: создаем новое окно (не должно произойти)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    return windowScene.windows.first ?? UIWindow()
                }
                return UIWindow()
            }
            return window
        }
        return window
    }
}
