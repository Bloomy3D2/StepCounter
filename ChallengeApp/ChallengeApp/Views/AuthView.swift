//
//  AuthView.swift
//  ChallengeApp
//
//  Экран авторизации
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var authManager = AuthManager(
        supabaseManager: DIContainer.shared.supabase
    )
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Проверка доступности Sign In with Apple capability
    // Personal Team не поддерживает эту capability
    // Для включения нужен платный Apple Developer Program ($99/год)
    private var isAppleSignInAvailable: Bool {
        // Проверяем наличие entitlement через Info.plist или entitlements
        // Если capability не настроена (Personal Team), возвращаем false
        if let entitlementsPath = Bundle.main.path(forResource: "ChallengeApp", ofType: "entitlements"),
           let entitlementsData = NSDictionary(contentsOfFile: entitlementsPath),
           let appleSignIn = entitlementsData["com.apple.developer.applesignin"] as? [String],
           !appleSignIn.isEmpty {
            return true
        }
        return false
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 60)
                    
                    // Логотип
                    Image(systemName: "flame.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text("auth.tagline".localized)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    // Форма авторизации
                    VStack(spacing: 20) {
                        if isSignUp {
                            // Поле имени (только при регистрации)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("auth.name".localized)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                TextField("", text: $name)
                                    .textFieldStyle(AuthTextFieldStyle())
                                    .autocapitalization(.words)
                            }
                        }
                        
                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("auth.email".localized)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            TextField("", text: $email)
                                .textFieldStyle(AuthTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }
                        
                        // Пароль
                        VStack(alignment: .leading, spacing: 8) {
                            Text("auth.password".localized)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            SecureField("", text: $password)
                                .textFieldStyle(AuthTextFieldStyle())
                        }
                        
                        // Кнопка входа/регистрации
                        Button(action: {
                            Task {
                                await handleAuth()
                            }
                        }) {
                            if authManager.isAuthenticating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                Text(isSignUp ? "auth.sign_up".localized : "auth.sign_in".localized)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .disabled(authManager.isAuthenticating || email.isEmpty || password.isEmpty || (isSignUp && name.isEmpty))
                        
                        // Переключение между входом и регистрацией
                        Button(action: {
                            withAnimation {
                                isSignUp.toggle()
                                errorMessage = ""
                            }
                        }) {
                            HStack {
                                Text(isSignUp ? "auth.already_have_account".localized : "auth.no_account".localized)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text(isSignUp ? "auth.sign_in".localized : "auth.sign_up".localized)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(authManager.isAuthenticating)
                    }
                    .padding(.horizontal, 32)
                    
                    // Разделитель
                    HStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                        
                        Text("auth.or".localized)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 16)
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 32)
                    
                    // Apple Sign In (только если capability доступна)
                    // Примечание: Sign In with Apple требует платный Apple Developer Program ($99/год)
                    // Personal Team не поддерживает эту capability
                    if isAppleSignInAvailable {
                        Button(action: {
                            Task {
                                await signInWithApple()
                            }
                        }) {
                            HStack {
                                Image(systemName: "applelogo")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("auth.sign_in_apple".localized)
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(authManager.isAuthenticating)
                        .padding(.horizontal, 32)
                    }
                    
                    Spacer()
                        .frame(height: 50)
                }
            }
        }
        .alert("error.title".localized, isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleAuth() async {
        await MainActor.run {
            authManager.lastError = nil
        }
        
        do {
            let user: User?
            
            if isSignUp {
                user = try await authManager.signUp(email: email, password: password, name: name)
            } else {
                user = try await authManager.signIn(email: email, password: password)
            }
            
            if let user = user {
                await MainActor.run {
                    appState.setUser(user)
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = ErrorHandler.userFriendlyMessage(for: error)
                showingError = true
            }
        }
    }
    
    private func signInWithApple() async {
        if let user = await authManager.signInWithApple() {
            await MainActor.run {
                appState.setUser(user)
            }
        } else if let error = authManager.lastError {
            await MainActor.run {
                errorMessage = error
                showingError = true
            }
        }
    }
}

// Стиль для текстовых полей
struct AuthTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .foregroundColor(.white)
            .padding()
            .background(Color.white.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
