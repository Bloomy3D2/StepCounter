//
//  AccountDetailView.swift
//  StepCounter
//
//  Детальная информация об аккаунте Apple
//

import SwiftUI

struct AccountDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appleSignInManager: AppleSignInManager
    @StateObject private var themeManager = ThemeManager.shared
    
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Статус авторизации
                    statusCard
                    
                    // Информация о пользователе (если авторизован)
                    if appleSignInManager.isAuthenticated {
                        userInfoCard
                    }
                    
                    // Кнопка входа/выхода
                    actionButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .ignoresSafeArea()
            )
            .navigationTitle("Аккаунт Apple")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Status Card
    
    private var statusCard: some View {
        GlassCard(cornerRadius: 20, padding: 24, glowColor: appleSignInManager.isAuthenticated ? accentGreen.opacity(0.3) : .orange.opacity(0.3)) {
            VStack(spacing: 16) {
                // Иконка статуса
                ZStack {
                    Circle()
                        .fill(appleSignInManager.isAuthenticated ? accentGreen.opacity(0.2) : Color.orange.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: appleSignInManager.isAuthenticated ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(appleSignInManager.isAuthenticated ? accentGreen : .orange)
                }
                
                // Статус
                Text(appleSignInManager.isAuthenticated ? "Авторизован" : "Не авторизован")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Описание
                Text(appleSignInManager.isAuthenticated 
                     ? "Вы вошли в аккаунт Apple" 
                     : "Войдите через Apple ID для синхронизации данных")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - User Info Card
    
    private var userInfoCard: some View {
        GlassCard(cornerRadius: 20, padding: 20, glowColor: accentGreen.opacity(0.2)) {
            VStack(spacing: 16) {
                Text("Информация об аккаунте")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Имя пользователя
                if let displayName = appleSignInManager.userDisplayName, !displayName.isEmpty {
                    InfoRow(
                        icon: "person.fill",
                        label: "Имя",
                        value: displayName,
                        color: accentGreen
                    )
                }
                
                // Email
                if let email = appleSignInManager.userEmail, !email.isEmpty {
                    InfoRow(
                        icon: "envelope.fill",
                        label: "Email",
                        value: email,
                        color: accentGreen
                    )
                }
                
                // User ID
                if let userID = appleSignInManager.userIdentifier {
                    InfoRow(
                        icon: "key.fill",
                        label: "ID пользователя",
                        value: String(userID.prefix(20)) + "...",
                        color: accentGreen
                    )
                }
            }
        }
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button {
            HapticManager.impact(style: .medium)
            if appleSignInManager.isAuthenticated {
                appleSignInManager.signOut()
                dismiss()
            } else {
                // Вход будет обработан через AppleSignInButton в SettingsView
                dismiss()
            }
        } label: {
            HStack {
                Image(systemName: appleSignInManager.isAuthenticated ? "arrow.right.square.fill" : "person.badge.plus")
                    .font(.system(size: 18, weight: .semibold))
                
                Text(appleSignInManager.isAuthenticated ? "Выйти из аккаунта" : "Войти через Apple")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: appleSignInManager.isAuthenticated 
                        ? [Color.red.opacity(0.8), Color.red.opacity(0.6)]
                        : [accentGreen, accentGreen.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
        }
        .shadow(color: (appleSignInManager.isAuthenticated ? Color.red : accentGreen).opacity(0.4), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.vertical, 8)
    }
}
