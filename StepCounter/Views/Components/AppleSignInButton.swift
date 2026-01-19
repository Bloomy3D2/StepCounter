//
//  AppleSignInButton.swift
//  StepCounter
//
//  Кнопка входа через Apple
//

import SwiftUI
import AuthenticationServices

struct AppleSignInButton: View {
    @ObservedObject var signInManager: AppleSignInManager
    let onSignIn: () -> Void
    
    var body: some View {
        if signInManager.isAuthenticated {
            // Показываем информацию о пользователе
            signedInView
        } else {
            // Показываем кнопку входа
            signInButton
        }
    }
    
    // MARK: - Sign In Button
    
    private var signInButton: some View {
        Button {
            performSignIn()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "applelogo")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Войти через Apple")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.black)
            .cornerRadius(12)
        }
        .disabled(signInManager.isLoading)
        .overlay {
            if signInManager.isLoading {
                ProgressView()
                    .tint(.white)
            }
        }
    }
    
    // MARK: - Sign In Action
    
    private func performSignIn() {
        // Проверяем доступность Sign in with Apple
        guard signInManager.isAvailable else {
            signInManager.errorMessage = "Sign in with Apple недоступен. Требуется настройка capability в Xcode."
            signInManager.isLoading = false
            Logger.shared.logWarning("Попытка входа через Apple без настроенной capability")
            return
        }
        
        // Сбрасываем предыдущие ошибки
        signInManager.errorMessage = nil
        signInManager.isLoading = true
        
        // Создаем запрос на главном потоке
        Task { @MainActor in
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = signInManager
            authorizationController.presentationContextProvider = signInManager
            
            // Выполняем запрос на главном потоке
            authorizationController.performRequests()
        }
    }
    
    // MARK: - Signed In View
    
    private var signedInView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Аватар
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    if let displayName = signInManager.userDisplayName, !displayName.isEmpty {
                        Text(String(displayName.prefix(1)).uppercased())
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    } else if let email = signInManager.userEmail, !email.isEmpty {
                        Text(String(email.prefix(1)).uppercased())
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
                
                // Информация о пользователе
                VStack(alignment: .leading, spacing: 4) {
                    if let displayName = signInManager.userDisplayName, !displayName.isEmpty {
                        Text(displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    } else if let email = signInManager.userEmail, !email.isEmpty {
                        Text(email)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    } else {
                        Text("Пользователь Apple")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    if let email = signInManager.userEmail, !email.isEmpty,
                       signInManager.userDisplayName != nil {
                        Text(email)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Кнопка выхода
                Button {
                    signInManager.signOut()
                } label: {
                    Image(systemName: "arrow.right.square")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    // MARK: - Helpers
    
    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            signInManager.handleAuthorization(authorization: authorization)
            onSignIn()
        case .failure(let error):
            signInManager.handleError(error)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        AppleSignInButton(signInManager: AppleSignInManager.shared) {
            print("Signed in")
        }
    }
    .padding()
    .background(Color.black)
}
