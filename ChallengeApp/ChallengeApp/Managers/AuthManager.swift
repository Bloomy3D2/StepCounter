//
//  AuthManager.swift
//  ChallengeApp
//
//  Менеджер для авторизации
//

import Foundation
import AuthenticationServices
import Combine
import UIKit

final class AuthManager: NSObject, AuthManagerProtocol, @unchecked Sendable {
    @Published var isAuthenticating = false
    @Published var lastError: String?
    
    private var currentAppleSignInContinuation: CheckedContinuation<User?, Never>?
    private let supabaseManager: SupabaseManagerProtocol
    
    init(supabaseManager: SupabaseManagerProtocol = DIContainer.shared.supabase) {
        self.supabaseManager = supabaseManager
        super.init()
    }
    
    func signUp(email: String, password: String, name: String) async throws -> User {
        await MainActor.run {
            isAuthenticating = true
            lastError = nil
        }
        
        do {
            let user = try await supabaseManager.signUp(email: email, password: password, name: name)
            
            await MainActor.run {
                isAuthenticating = false
            }
            
            Task { await AnalyticsManager.shared.track("sign_up_success", props: ["provider": "email"]) }
            
            return user
        } catch {
            await MainActor.run {
                isAuthenticating = false
                lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws -> User {
        await MainActor.run {
            isAuthenticating = true
            lastError = nil
        }
        
        do {
            let user = try await supabaseManager.signIn(email: email, password: password)
            
            await MainActor.run {
                isAuthenticating = false
            }
            
            Task { await AnalyticsManager.shared.track("sign_in_success", props: ["provider": "email"]) }
            
            return user
        } catch {
            await MainActor.run {
                isAuthenticating = false
                lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    func signInWithApple() async -> User? {
        Task { @MainActor in
            isAuthenticating = true
            lastError = nil
        }
        
        return await withCheckedContinuation { (continuation: CheckedContinuation<User?, Never>) in
            // Сохраняем continuation с гарантией очистки
            self.currentAppleSignInContinuation = continuation
            
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            
            authorizationController.performRequests()
            
            // Устанавливаем таймаут для предотвращения утечки памяти
            Task {
                try? await Task.sleep(nanoseconds: 60_000_000_000) // 60 секунд
                // Проверяем, что continuation все еще активен (не был использован)
                if self.currentAppleSignInContinuation != nil {
                    Logger.shared.warning("AuthManager: Apple Sign In timeout, cleaning up continuation")
                    self.currentAppleSignInContinuation?.resume(returning: nil)
                    self.currentAppleSignInContinuation = nil
                }
            }
        }
    }
    
    func signInWithGoogle() async -> User? {
        Task { @MainActor in
            isAuthenticating = true
            lastError = nil
        }
        
        // Google Sign In требует дополнительной настройки
        // Пока возвращаем ошибку, чтобы пользователь использовал Email/Password
        Task { @MainActor in
            isAuthenticating = false
            lastError = "Google Sign In пока не настроен. Используйте Email/Password для входа."
        }
        
        return nil
    }
    
    func signOut() async {
        do {
            try await supabaseManager.signOut()
        } catch {
            Task { @MainActor in
                lastError = error.localizedDescription
            }
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task {
            // Гарантируем очистку continuation в любом случае
            defer {
                currentAppleSignInContinuation = nil
            }
            
            guard let continuation = currentAppleSignInContinuation else {
                Logger.shared.warning("AuthManager: No continuation found for Apple Sign In")
                return
            }
            
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                await MainActor.run {
                    isAuthenticating = false
                    lastError = "Неверный тип авторизации"
                }
                continuation.resume(returning: nil)
                return
            }
            
            // Получаем identity token
            guard let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                await MainActor.run {
                    isAuthenticating = false
                    lastError = "Не удалось получить токен от Apple"
                }
                continuation.resume(returning: nil)
                return
            }
            
            // Входим через Supabase
            do {
                let user = try await supabaseManager.signInWithApple(token: identityToken)
                
                await MainActor.run {
                    isAuthenticating = false
                }
                
                continuation.resume(returning: user)
            } catch {
                await MainActor.run {
                    isAuthenticating = false
                    lastError = error.localizedDescription
                }
                continuation.resume(returning: nil)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            // Гарантируем очистку continuation в любом случае
            defer {
                currentAppleSignInContinuation = nil
            }
            
            isAuthenticating = false
            
            let nsError = error as NSError
            if nsError.domain == "com.apple.AuthenticationServices.AuthorizationError" {
                switch nsError.code {
                case 1001:
                    lastError = "Авторизация отменена"
                case 1000:
                    lastError = "Не удалось выполнить запрос. Проверьте подключение к интернету."
                default:
                    lastError = "Ошибка авторизации: \(error.localizedDescription)"
                }
            } else {
                lastError = error.localizedDescription.isEmpty ? "Произошла ошибка. Попробуйте позже." : error.localizedDescription
            }
            
            currentAppleSignInContinuation?.resume(returning: nil)
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            // Fallback
            guard let fallbackWindowScene = UIApplication.shared.connectedScenes
                .first(where: { $0 is UIWindowScene }) as? UIWindowScene,
                let window = fallbackWindowScene.windows.first else {
                return UIWindow()
            }
            return window
        }
        return window
    }
}
