//
//  SettingsView.swift
//  StepCounter
//
//  Настройки и дополнительные функции
//

import SwiftUI
import MapKit
import Combine
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var petManager: PetManager
    
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var appleSignInManager = AppleSignInManager.shared
    @StateObject private var consentManager = PrivacyConsentManager.shared
    @State private var showPremium = false
    @State private var showThemeSettings = false
    @State private var themeUpdateTrigger = UUID()
    
    @State private var showAppleError = false
    @State private var showPrivacyPolicy = false
    @State private var showDeleteDataAlert = false
    @State private var showRevokeConsentAlert = false
    @State private var showGiveConsentAlert = false
    @State private var showAccountDetail = false
    @State private var showDeleteAccountAlert = false
    @State private var showPrivacySettings = false
    @State private var showDataExport = false
    
    private var bgColor: Color { themeManager.backgroundColor }
    private var cardColor: Color { themeManager.cardColor }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Фон с темой
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .id("\(themeManager.currentTheme.id)-\(themeUpdateTrigger)")
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.5), value: themeManager.currentTheme.id)
                
                ScrollView {
                    settingsContent
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAccountDetail) {
                AccountDetailView(appleSignInManager: appleSignInManager)
            }
            .sheet(isPresented: $showThemeSettings) {
                ThemeSettingsView()
                    .onDisappear {
                        // Принудительное обновление при закрытии экрана выбора темы
                        themeUpdateTrigger = UUID()
                    }
            }
            .alert("Ошибка входа через Apple", isPresented: $showAppleError) {
                Button("Понятно") {
                    appleSignInManager.errorMessage = nil
                }
            } message: {
                Text(appleSignInManager.errorMessage ?? "Не удалось выполнить вход. Попробуйте позже.")
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyWebView()
            }
            .alert("Удалить все данные", isPresented: $showDeleteDataAlert) {
                Button("Отмена", role: .cancel) {}
                Button("Удалить", role: .destructive) {
                    deleteAllUserData()
                }
            } message: {
                Text("Все ваши данные будут удалены с устройства. Это действие нельзя отменить.")
            }
            .alert("Отозвать согласие", isPresented: $showRevokeConsentAlert) {
                Button("Отмена", role: .cancel) {}
                Button("Отозвать", role: .destructive) {
                    consentManager.revokeConsent()
                    HapticManager.notification(.warning)
                }
            } message: {
                Text("После отзыва согласия некоторые функции приложения будут ограничены. Вы сможете дать согласие снова в любой момент.")
            }
            .alert("Дать согласие на обработку данных", isPresented: $showGiveConsentAlert) {
                Button("Отмена", role: .cancel) {}
                Button("Согласен", role: .none) {
                    consentManager.giveConsent()
                    HapticManager.notification(.success)
                }
            } message: {
                Text("Приложение будет иметь доступ к:\n\n• Данным о здоровье (шаги, дистанция, калории)\n• Геолокации (для записи маршрутов)\n• Данным аккаунта (при использовании Sign in with Apple)\n\nВсе данные хранятся локально на вашем устройстве.")
            }
            .onChange(of: themeManager.currentTheme.id) { oldValue, newValue in
                // Принудительное обновление при изменении темы
                if oldValue != newValue {
                    themeUpdateTrigger = UUID()
                }
            }
        }
    }
    
    // MARK: - Settings Content
    
    private var settingsContent: some View {
        VStack(spacing: 24) {
            // Профиль вверху (новый дизайн)
            ProfileHeaderCard(
                appleSignInManager: appleSignInManager,
                subscriptionManager: subscriptionManager,
                themeManager: themeManager,
                onAccountTap: {
                    showAccountDetail = true
                },
                onPremiumTap: {
                    showPremium = true
                }
            )
            
            // Временная кнопка: включить/выключить Premium (потом удалим)
            premiumToggleSection
            
            // Аккаунт
            accountSection
            
            // Premium секция
            premiumStatusSection
            
            // Настройки
            settingsSection
            
            // Конфиденциальность
            privacySection
            
            // О приложении
            aboutSection
        }
        .padding(.horizontal, 20)
        .sheet(isPresented: $showPremium) {
            PremiumView()
        }
        .sheet(isPresented: $showPrivacySettings) {
            PrivacySettingsView()
        }
        .sheet(isPresented: $showDataExport) {
            DataExportView()
        }
        .alert("Удалить аккаунт", isPresented: $showDeleteAccountAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("Все данные аккаунта будут удалены безвозвратно. Это действие нельзя отменить.\n\nБудут удалены:\n• Профиль и статистика\n• Достижения\n• Маршруты\n• Данные питомца\n• Все настройки")
        }
    }
    
    // MARK: - Privacy Section
    
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🛡️ Конфиденциальность")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            GlassCard(cornerRadius: 20, padding: 0) {
                VStack(spacing: 0) {
                    // Согласие на обработку данных
                    HStack(spacing: 12) {
                        Image(systemName: consentManager.hasConsent ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                            .foregroundColor(consentManager.hasConsent ? .green : .orange)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Согласие на обработку данных")
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                            
                            if consentManager.hasConsent {
                                if let date = consentManager.consentInfo.formattedDate {
                                    Text("Дано: \(date)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            } else {
                                Text("Не дано")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Spacer()
                        
                        if consentManager.hasConsent {
                            Button {
                                showRevokeConsentAlert = true
                            } label: {
                                Text("Отозвать")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.orange.opacity(0.2))
                                    )
                            }
                        } else {
                            Button {
                                showGiveConsentAlert = true
                            } label: {
                                Text("Дать")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.green.opacity(0.2))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // Политика конфиденциальности
                    Button {
                        showPrivacyPolicy = true
                    } label: {
                        SettingsRow(
                            icon: "doc.text.fill",
                            iconColor: .blue,
                            title: "Политика конфиденциальности",
                            subtitle: "Версия 1.0",
                            showChevron: true
                        )
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // Настройки приватности
                    Button {
                        HapticManager.impact(style: .light)
                        showPrivacySettings = true
                    } label: {
                        SettingsRow(
                            icon: "lock.fill",
                            iconColor: .purple,
                            title: "Настройки приватности",
                            subtitle: "Профиль, статистика, достижения",
                            showChevron: true
                        )
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // Разрешения
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            Image(systemName: "key.fill")
                                .foregroundColor(.cyan)
                                .frame(width: 24)
                            
                            Text("Разрешения")
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        
                        // HealthKit
                        PermissionRow(
                            icon: "heart.fill",
                            title: "HealthKit",
                            isGranted: healthManager.isAuthorized,
                            onTap: {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        )
                        
                        // Локация
                        PermissionRow(
                            icon: "location.fill",
                            title: "Локация",
                            isGranted: locationManager.isAuthorized,
                            onTap: {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        )
                        
                        // Уведомления
                        PermissionRow(
                            icon: "bell.fill",
                            title: "Уведомления",
                            isGranted: NotificationManager.shared.notificationsEnabled,
                            onTap: {
                                NotificationManager.shared.requestAuthorization()
                            }
                        )
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // Экспорт данных
                    Button {
                        HapticManager.impact(style: .light)
                        showDataExport = true
                    } label: {
                        SettingsRow(
                            icon: "square.and.arrow.up.fill",
                            iconColor: .green,
                            title: "Экспорт данных",
                            subtitle: "CSV, PDF, JSON",
                            showChevron: true
                        )
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // Удалить все данные
                    Button {
                        HapticManager.impact(style: .medium)
                        showDeleteDataAlert = true
                    } label: {
                        SettingsRow(
                            icon: "trash.fill",
                            iconColor: .red,
                            title: "Удалить все данные",
                            showChevron: false
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Permission Row
    
    struct PermissionRow: View {
        let icon: String
        let title: String
        let isGranted: Bool
        let onTap: () -> Void
        
        var body: some View {
            Button {
                onTap()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .foregroundColor(isGranted ? .green : .orange)
                        .frame(width: 24)
                    
                    Text(title)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isGranted ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        
                        Text(isGranted ? "Разрешено" : "Не разрешено")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
    }
    
    // MARK: - Delete Data
    
    private func deleteAllUserData() {
        // Удаляем все данные из UserDefaults
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        // Удаляем данные из App Group (для виджета)
        if let sharedDefaults = UserDefaults(suiteName: "group.stepcounter.shared") {
            if let domain = sharedDefaults.persistentDomain(forName: "group.stepcounter.shared") {
                for key in domain.keys {
                    sharedDefaults.removeObject(forKey: key)
                }
                sharedDefaults.synchronize()
            }
        }
        
        // Отзываем согласие
        consentManager.revokeConsent()
        
        // Выходим из аккаунта
        appleSignInManager.signOut()
        
        HapticManager.notification(.success)
        Logger.shared.logInfo("Все данные пользователя удалены")
    }
    
    // MARK: - Account Section
    
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🔐 Аккаунт")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            GlassCard(cornerRadius: 20, padding: 0) {
                VStack(spacing: 0) {
                    // Информация об аккаунте
                    Button {
                        HapticManager.impact(style: .light)
                        showAccountDetail = true
                    } label: {
                        SettingsRow(
                            icon: "person.fill",
                            iconColor: .blue,
                            title: "Информация об аккаунте",
                            subtitle: appleSignInManager.isAuthenticated ? (appleSignInManager.userDisplayName ?? appleSignInManager.userEmail ?? "Вход выполнен") : "Не авторизован",
                            showChevron: true
                        )
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // Синхронизация данных
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Синхронизация данных")
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                            
                            Text("Локальное хранение")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 20))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    if appleSignInManager.isAuthenticated {
                        Divider().background(Color.white.opacity(0.1))
                        
                        // Выйти из аккаунта
                        Button {
                            HapticManager.impact(style: .medium)
                            appleSignInManager.signOut()
                            HapticManager.notification(.success)
                        } label: {
                            SettingsRow(
                                icon: "arrow.right.square.fill",
                                iconColor: .orange,
                                title: "Выйти из аккаунта",
                                showChevron: false
                            )
                        }
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        // Удалить аккаунт
                        Button {
                            HapticManager.impact(style: .medium)
                            showDeleteAccountAlert = true
                        } label: {
                            SettingsRow(
                                icon: "trash.fill",
                                iconColor: .red,
                                title: "Удалить аккаунт",
                                showChevron: false
                            )
                        }
                    } else {
                        Divider().background(Color.white.opacity(0.1))
                        
                        // Кнопка входа через Apple
                        if appleSignInManager.isAvailable {
                            AppleSignInButton(signInManager: appleSignInManager) {
                                HapticManager.notification(.success)
                            }
                            .onChange(of: appleSignInManager.errorMessage) { _, newValue in
                                if newValue != nil {
                                    showAppleError = true
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        } else {
                            HStack(spacing: 12) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.orange)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Sign in with Apple недоступен")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                    
                                    Text("Требуется настройка capability в Xcode")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Delete Account
    
    private func deleteAccount() {
        // Удаляем все данные аккаунта
        deleteAllUserData()
        
        // Выходим из аккаунта
        appleSignInManager.signOut()
        
        HapticManager.notification(.success)
        Logger.shared.logInfo("Аккаунт удалён")
    }
    
    // MARK: - Premium Status Section
    
    private var premiumStatusSection: some View {
        let accentGold = Color(red: 1.0, green: 0.84, blue: 0.0)
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("💎 Premium")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            GlassCard(cornerRadius: 20, padding: 0, glowColor: accentGold.opacity(0.3)) {
                if subscriptionManager.isPremium {
                    VStack(spacing: 0) {
                        // Статус подписки
                        HStack(spacing: 16) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 24))
                                .foregroundColor(accentGold)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                if subscriptionManager.activeSubscription == .lifetime {
                                    Text("Premium: Навсегда")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                } else if let expirationDate = subscriptionManager.expirationDate {
                                    Text("\(subscriptionManager.activeSubscription?.displayName ?? "Premium")")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("Действует до: \(formatDate(expirationDate))")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    // Прогресс-бар
                                    let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
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
                                        .padding(.top, 4)
                                        
                                        Text("\(daysRemaining) дней до окончания")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                } else {
                                    Text("Premium активен")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(20)
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        // Управление подпиской
                        Button {
                            HapticManager.impact(style: .light)
                            showPremium = true
                        } label: {
                            SettingsRow(
                                icon: "gearshape.fill",
                                iconColor: accentGold,
                                title: "Управление подпиской",
                                showChevron: true
                            )
                        }
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        // Восстановить покупки
                        Button {
                            HapticManager.impact(style: .light)
                            Task {
                                try? await AppStore.sync()
                                await subscriptionManager.updateSubscriptionStatus()
                            }
                        } label: {
                            SettingsRow(
                                icon: "arrow.clockwise.circle.fill",
                                iconColor: .blue,
                                title: "Восстановить покупки",
                                showChevron: false
                            )
                        }
                    }
                } else {
                    Button {
                        showPremium = true
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 24))
                                .foregroundColor(accentGold)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("StepCounter Premium")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Разблокируйте все функции")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text("От $2.99/мес")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(accentGold)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(20)
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
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("⚙️ Настройки")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            GlassCard(cornerRadius: 20, padding: 0) {
                VStack(spacing: 0) {
                    // Цель шагов
                    Button {
                        HapticManager.impact(style: .light)
                        // Можно открыть GoalSettingsView если нужно
                    } label: {
                        SettingsRow(
                            icon: "target",
                            iconColor: .green,
                            title: "Цель шагов",
                            subtitle: "\(healthManager.stepGoal) шагов",
                            showChevron: true
                        )
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // Тема оформления
                    Button {
                        HapticManager.impact(style: .light)
                        showThemeSettings = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "paintpalette.fill")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Тема оформления")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                
                                Text(themeManager.currentTheme.displayName)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            
                            Spacer()
                            
                            // Превью темы
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: Array(themeManager.currentTheme.primaryGradientColors.prefix(2)),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // Уведомления
                    SettingsToggleRow(
                        icon: "bell.fill",
                        title: "Уведомления",
                        subtitle: NotificationManager.shared.goalReminderEnabled ? "Вечернее напоминание: 20:00" : nil,
                        isOn: Binding(
                            get: { NotificationManager.shared.notificationsEnabled },
                            set: { NotificationManager.shared.notificationsEnabled = $0 }
                        ),
                        color: .orange
                    )
                }
            }
        }
    }
    
    // MARK: - Premium Section (старая версия, оставляем для совместимости)
    
    private var premiumSection: some View {
        let cardColor = themeManager.cardColor
        let accentGold = Color(red: 1.0, green: 0.84, blue: 0.0) // Золотой для Premium остается специфичным
        
        return Button {
            showPremium = true
        } label: {
            HStack(spacing: 16) {
                // Иконка короны
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accentGold, accentGold.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: accentGold.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("StepCounter Premium")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Разблокируйте все функции")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack(spacing: 4) {
                        Text("От")
                            .font(.system(size: 12))
                        Text("$2.99/мес")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(accentGold)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(20)
        }
        .background(
            ZStack {
            RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [accentGold.opacity(0.5), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
            }
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
    }
    
    // MARK: - Theme Section
    
    private var themeSection: some View {
        Button {
            HapticManager.impact(style: .light)
            showThemeSettings = true
        } label: {
            HStack(spacing: 16) {
                // Превью текущей темы
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: Array(themeManager.currentTheme.primaryGradientColors.prefix(2)),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .id(themeManager.currentTheme.id) // Принудительное обновление при смене темы
                    
                    Image(systemName: themeManager.currentTheme.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Тема оформления")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(themeManager.currentTheme.displayName)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .id(themeManager.currentTheme.id) // Обновление текста при смене темы
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
        }
        .animation(.easeInOut(duration: 0.3), value: themeManager.currentTheme.id)
    }
    
    private var goalSection: some View {
        let cardColor = themeManager.cardColor
        let accentGreen = themeManager.accentGreen
        let accentBlue = themeManager.accentBlue
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Цель шагов")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            HStack {
                Button {
                    if healthManager.stepGoal > 1000 {
                        healthManager.stepGoal -= 1000
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(accentBlue)
                }
                
                Spacer()
                
                Text("\(healthManager.stepGoal)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    healthManager.stepGoal += 1000
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(accentGreen)
                }
            }
            
            HStack(spacing: 8) {
                ForEach([5000, 8000, 10000, 12000, 15000], id: \.self) { goal in
                    Button {
                        healthManager.stepGoal = goal
                    } label: {
                        Text("\(goal / 1000)k")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(healthManager.stepGoal == goal ? .white : .white.opacity(0.6))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(healthManager.stepGoal == goal ? accentGreen : cardColor.opacity(0.5))
                            )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
    }
    
    private var notificationsSection: some View {
        let cardColor = themeManager.cardColor
        let manager = NotificationManager.shared
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Уведомления")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 0) {
                SettingsToggleRow(
                    icon: "bell.fill",
                    title: "Уведомления",
                    isOn: Binding(
                        get: { manager.notificationsEnabled },
                        set: { manager.notificationsEnabled = $0 }
                    ),
                    color: .blue
                )
                
                Divider().background(Color.white.opacity(0.1))
                
                SettingsToggleRow(
                    icon: "clock.fill",
                    title: "Вечернее напоминание",
                    subtitle: "В 20:00",
                    isOn: Binding(
                        get: { manager.goalReminderEnabled },
                        set: { manager.goalReminderEnabled = $0 }
                    ),
                    color: .orange
                )
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
    }
    
    // MARK: - Premium Toggle (временное)
    
    private var premiumToggleSection: some View {
        Button {
            subscriptionManager.togglePremiumManually()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: subscriptionManager.isPremium ? "crown.fill" : "crown")
                    .foregroundColor(subscriptionManager.isPremium ? .yellow : .white.opacity(0.7))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Premium: \(subscriptionManager.isPremium ? "ВКЛ" : "ВЫКЛ")")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Временная кнопка для теста (потом удалим)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Text(subscriptionManager.isPremium ? "Выключить" : "Включить")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.accentGreen)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardColor.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(themeManager.accentGreen.opacity(0.4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var aboutSection: some View {
        // Получаем версию приложения
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("О приложении")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                SettingsInfoRow(icon: "heart.fill", text: "Данные из Apple Health", color: .red)
                SettingsInfoRow(icon: "applewatch", text: "Синхронизация с Apple Watch", color: themeManager.accentGreen)
                SettingsInfoRow(icon: "trophy.fill", text: "Система достижений", color: .yellow)
                SettingsInfoRow(icon: "flag.fill", text: "Личные челленджи", color: .purple)
                SettingsInfoRow(icon: "map.fill", text: "GPS-трекинг маршрутов", color: themeManager.accentBlue)
                SettingsInfoRow(icon: "lock.shield.fill", text: "Данные на устройстве", color: .cyan)
                
                Divider().background(Color.white.opacity(0.1))
                
                // Версия приложения
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Версия приложения")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                        
                        Text("\(appVersion) (\(buildNumber))")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // Поддержка
                Button {
                    // Правильная URL-кодировка для заголовка письма
                    let subject = "Вопрос о приложении StepCounter"
                    if let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                       let url = URL(string: "mailto:support@stepcounter.app?subject=\(encodedSubject)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.cyan)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Поддержка")
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                            
                            Text("support@stepcounter.app")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
    }
}

// MARK: - Helper Views

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    var showChevron: Bool = true
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(ThemeManager.shared.accentGreen)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
        }
    }
}

struct RouteRow: View {
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var themeManager = ThemeManager.shared
    let route: RecordedRoute
    
    private var cardColor: Color { themeManager.cardColor }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "map.fill")
                .foregroundColor(.cyan)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(route.dateString)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text(String(format: "%.2f км", route.distanceKm))
                    Text("•")
                    Text(route.formattedDuration)
                }
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            Button {
                locationManager.deleteRoute(route)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.red.opacity(0.6))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

#Preview {
    SettingsView()
        .environmentObject(HealthManager())
        .environmentObject(LocationManager())
        .environmentObject(PetManager())
}
