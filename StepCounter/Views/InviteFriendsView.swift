//
//  InviteFriendsView.swift
//  StepCounter
//
//  Экран приглашения друзей (реферальная система)
//

import SwiftUI

struct InviteFriendsView: View {
    @StateObject private var referralManager = ReferralManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var showShareSheet = false
    @State private var referralCodeInput = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var showPremiumView = false
    @State private var showFriendsLimitAlert = false
    
    private var accentGreen: Color { themeManager.accentGreen }
    private var accentGold: Color { Color(hex: "FFD700") }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Заголовок
                        headerSection
                        
                        // Реферальный код
                        referralCodeSection
                        
                        // Награды
                        rewardsSection
                        
                        // Статистика
                        statsSection
                        
                        // Кнопка поделиться
                        shareButton
                        
                        // Регистрация по коду
                        enterCodeSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Пригласить друзей")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .alert("Ошибка", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .alert("Успех! 🎉", isPresented: $showSuccess) {
                Button("Отлично!") {}
            } message: {
                Text("Код применён! Вы получили награды.")
            }
            .alert("Лимит друзей", isPresented: $showFriendsLimitAlert) {
                Button("OK") {}
                Button("Оформить Premium") {
                    showPremiumView = true
                }
            } message: {
                Text("Вы достигли лимита приглашений (10 друзей). Оформите Premium, чтобы приглашать неограниченное количество друзей!")
            }
            .sheet(isPresented: $showPremiumView) {
                PremiumView()
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accentGold, Color(hex: "FFA500")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: accentGold.opacity(0.5), radius: 20, x: 0, y: 10)
                
                Image(systemName: "person.2.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            Text("Пригласи друзей")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Получи награды за каждого друга!")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Referral Code
    
    private var referralCodeSection: some View {
        GlassCard(cornerRadius: 20, padding: 24, glowColor: accentGold.opacity(0.3)) {
            VStack(spacing: 16) {
                Text("Ваш код")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(referralManager.referralInfo.referralCode)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                
                Button {
                    UIPasteboard.general.string = referralManager.referralInfo.referralCode
                    HapticManager.notification(.success)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.on.doc")
                        Text("Копировать")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(accentGreen)
                    )
                }
            }
        }
    }
    
    // MARK: - Rewards
    
    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Награды для вас и друзей")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                // Награда для нового пользователя
                rewardCard(
                    title: "Для друга",
                    icon: "gift.fill",
                    color: accentGreen,
                    rewards: [
                        "7 дней Premium",
                        "1000 XP"
                    ]
                )
                
                // Награда для вас
                rewardCard(
                    title: "Для вас",
                    icon: "star.fill",
                    color: accentGold,
                    rewards: [
                        "7 дней Premium",
                        "2000 XP"
                    ]
                )
            }
        }
    }
    
    private func rewardCard(title: String, icon: String, color: Color, rewards: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(rewards, id: \.self) { reward in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(color)
                        
                        Text(reward)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Stats
    
    private var statsSection: some View {
        GlassCard(cornerRadius: 20, padding: 20) {
            VStack(spacing: 16) {
                HStack {
                    Text("Статистика")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                HStack(spacing: 24) {
                    statItem(
                        value: "\(referralManager.referralInfo.completedCount)",
                        label: "Приглашено",
                        icon: "person.2.fill"
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .frame(height: 40)
                    
                    statItem(
                        value: "\(referralManager.referralInfo.totalRewardsEarned)",
                        label: "XP заработано",
                        icon: "star.fill"
                    )
                }
            }
        }
    }
    
    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(accentGreen)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Share Button
    
    private var shareButton: some View {
        Button {
            shareInvite()
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20))
                
                Text("Поделиться кодом")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [accentGold, Color(hex: "FFA500")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: accentGold.opacity(0.4), radius: 12, x: 0, y: 6)
        }
    }
    
    // MARK: - Enter Code
    
    private var enterCodeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("У вас есть код друга?")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                TextField("Введите код", text: $referralCodeInput)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                
                Button {
                    applyReferralCode()
                } label: {
                    Text("Применить")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(accentGreen)
                        )
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func shareInvite() {
        // Проверяем лимит друзей
        guard referralManager.canInviteFriend() else {
            showFriendsLimitAlert = true
            HapticManager.notification(.warning)
            return
        }
        
        let inviteText = referralManager.generateInviteText()
        
        // Показываем sharing без закрытия sheet - ShareManager сам найдёт правильный view controller
        // Используем небольшую задержку для гарантии, что UI готов
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            ShareManager.shared.shareText(inviteText)
            HapticManager.impact(style: .medium)
            
            // Обновляем статистику
            self.referralManager.referralInfo = ReferralInfo(
                referralCode: self.referralManager.referralInfo.referralCode,
                invitedCount: self.referralManager.referralInfo.invitedCount + 1,
                completedCount: self.referralManager.referralInfo.completedCount,
                totalRewardsEarned: self.referralManager.referralInfo.totalRewardsEarned,
                lastRewardDate: self.referralManager.referralInfo.lastRewardDate
            )
        }
    }
    
    private func applyReferralCode() {
        let code = referralCodeInput.uppercased().trimmingCharacters(in: .whitespaces)
        
        guard !code.isEmpty else {
            errorMessage = "Введите код"
            showError = true
            return
        }
        
        if referralManager.registerWithReferralCode(code) {
            referralCodeInput = ""
            showSuccess = true
            HapticManager.notification(.success)
        } else {
            errorMessage = "Неверный код или он уже использован"
            showError = true
        }
    }
}

#Preview {
    InviteFriendsView()
}
