//
//  ProfileHeaderCard.swift
//  StepCounter
//
//  Карточка профиля вверху экрана настроек
//

import SwiftUI

struct ProfileHeaderCard: View {
    @ObservedObject var appleSignInManager: AppleSignInManager
    @ObservedObject var subscriptionManager: SubscriptionManager
    @ObservedObject var themeManager: ThemeManager
    
    let onAccountTap: () -> Void
    let onPremiumTap: () -> Void
    
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    private var accentGold: Color { Color(red: 1.0, green: 0.84, blue: 0.0) }
    
    var body: some View {
        GlassCard(cornerRadius: 24, padding: 24, glowColor: accentGreen.opacity(0.2)) {
            VStack(spacing: 20) {
                // Аватар и информация
                HStack(spacing: 16) {
                    // Аватар
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        themeManager.currentTheme.accentColors.primaryColor,
                                        themeManager.currentTheme.accentColors.secondaryColor
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: accentGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        if appleSignInManager.isAuthenticated {
                            if let displayName = appleSignInManager.userDisplayName, !displayName.isEmpty {
                                Text(String(displayName.prefix(1)).uppercased())
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            } else if let email = appleSignInManager.userEmail, !email.isEmpty {
                                Text(String(email.prefix(1)).uppercased())
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        // Имя пользователя
                        if appleSignInManager.isAuthenticated {
                            if let displayName = appleSignInManager.userDisplayName, !displayName.isEmpty {
                                Text(displayName)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            } else if let email = appleSignInManager.userEmail, !email.isEmpty {
                                Text(email)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            } else {
                                Text("Пользователь")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        } else {
                            Text("Гость")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        // Статус аккаунта
                        HStack(spacing: 6) {
                            Circle()
                                .fill(appleSignInManager.isAuthenticated ? accentGreen : Color.orange)
                                .frame(width: 8, height: 8)
                            
                            Text(appleSignInManager.isAuthenticated ? "Авторизован через Apple ID" : "Не авторизован")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                }
                
                // Premium статус (если Premium)
                if subscriptionManager.isPremium {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 16))
                                .foregroundColor(accentGold)
                            
                            if subscriptionManager.activeSubscription == .lifetime {
                                Text("Premium: Навсегда")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                            } else if let expirationDate = subscriptionManager.expirationDate {
                                let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
                                Text("Premium активен до \(formatDate(expirationDate))")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                // Прогресс-бар до окончания
                                if daysRemaining > 0 && daysRemaining <= 30 {
                                    let progress = Double(daysRemaining) / 30.0
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.white.opacity(0.2))
                                                .frame(height: 6)
                                            
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [accentGold, accentGold.opacity(0.7)],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .frame(width: geometry.size.width * progress, height: 6)
                                        }
                                    }
                                    .frame(height: 6)
                                    
                                    Text("\(daysRemaining) дней до окончания")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            } else {
                                Text("Premium активен")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                
                // Кнопки действий
                HStack(spacing: 12) {
                    Button {
                        HapticManager.impact(style: .light)
                        onAccountTap()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 16))
                            Text("Аккаунт")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(accentGreen.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(accentGreen.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }
                    
                    Button {
                        HapticManager.impact(style: .light)
                        onPremiumTap()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: subscriptionManager.isPremium ? "crown.fill" : "crown")
                                .font(.system(size: 16))
                            Text(subscriptionManager.isPremium ? "Premium" : "Получить")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(subscriptionManager.isPremium ? accentGold.opacity(0.2) : accentGold.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(accentGold.opacity(0.6), lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}
