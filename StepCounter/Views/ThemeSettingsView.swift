//
//  ThemeSettingsView.swift
//  StepCounter
//
//  Экран выбора темы оформления
//

import SwiftUI

struct ThemeSettingsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showPremium = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Заголовок
                    headerSection
                    
                    // Автопереключение
                    autoSwitchSection
                    
                    // Доступные темы
                    themesSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .id(themeManager.currentTheme.id)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.5), value: themeManager.currentTheme.id)
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .sheet(isPresented: $showPremium) {
                PremiumView()
            }
            .onChange(of: subscriptionManager.isPremium) { oldValue, newValue in
                // Если Premium закончился, проверяем и сбрасываем Premium тему
                if oldValue && !newValue {
                    themeManager.checkAndResetPremiumThemeIfNeeded()
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "paintbrush.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Темы оформления")
                    .font(.appScreenTitle)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text("Персонализируйте внешний вид приложения")
                .font(.appCaption)
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Auto Switch
    
    private var autoSwitchSection: some View {
        GlassCard(cornerRadius: 20, padding: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "sun.horizon.fill")
                            .foregroundColor(.orange)
                        Text("Автопереключение")
                            .font(.appTitle)
                            .foregroundColor(.white)
                        
                        if !subscriptionManager.isPremium {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text(subscriptionManager.isPremium 
                         ? "Тема меняется автоматически в зависимости от времени суток"
                         : "Требуется Premium для автопереключения темы")
                        .font(.appCaption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { 
                        // Если нет Premium, всегда false
                        subscriptionManager.isPremium ? themeManager.autoSwitchEnabled : false
                    },
                    set: { newValue in
                        if !subscriptionManager.isPremium {
                            // Если нет Premium, показываем экран Premium
                            HapticManager.notification(.warning)
                            showPremium = true
                        } else {
                            // Если есть Premium, переключаем
                            HapticManager.impact(style: .light)
                            themeManager.toggleAutoSwitch()
                        }
                    }
                ))
                .tint(themeManager.currentTheme.accentColors.primaryColor)
                .disabled(!subscriptionManager.isPremium)
            }
            .opacity(subscriptionManager.isPremium ? 1.0 : 0.7)
        }
    }
    
    // MARK: - Themes
    
    private var themesSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Базовые темы
            let basicThemes = themeManager.availableThemes().filter { !$0.isPremium }
            if !basicThemes.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.6))
                        Text("Базовые темы")
                            .font(.appSectionTitle)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 4)
                    
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ],
                        spacing: 16
                    ) {
                        ForEach(basicThemes) { theme in
                            ThemeCard(
                                theme: theme,
                                isSelected: themeManager.currentTheme.id == theme.id,
                                isLocked: false
                            ) {
                                HapticManager.impact(style: .medium)
                                withAnimation(.appSpring) {
                                    themeManager.setTheme(theme)
                                }
                            }
                        }
                    }
                }
            }
            
            // Premium темы
            let premiumThemes = themeManager.availableThemes().filter { $0.isPremium }
            if !premiumThemes.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                        Text("Premium темы")
                            .font(.appSectionTitle)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 4)
                    
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ],
                        spacing: 16
                    ) {
                        ForEach(premiumThemes) { theme in
                            ThemeCard(
                                theme: theme,
                                isSelected: themeManager.currentTheme.id == theme.id,
                                isLocked: !subscriptionManager.isPremium
                            ) {
                                if !subscriptionManager.isPremium {
                                    HapticManager.notification(.warning)
                                    showPremium = true
                                } else {
                                    HapticManager.impact(style: .medium)
                                    withAnimation(.appSpring) {
                                        themeManager.setTheme(theme)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Theme Card

struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Превью темы
                ZStack {
                    // Градиент фона
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: theme.primaryGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 140)
                        .overlay(
                            // Затемнение для заблокированных тем
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(isLocked ? 0.6 : 0))
                        )
                    
                    // Иконка темы
                    Image(systemName: theme.icon)
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(.white.opacity(isLocked ? 0.4 : 0.95))
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    // Premium badge / Lock icon
                    VStack {
                        HStack {
                            Spacer()
                            if isLocked {
                                // Иконка замка для заблокированных тем
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            } else if theme.isPremium {
                                // Корона для Premium тем (если разблокирована)
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.yellow)
                                    .padding(10)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                        }
                        Spacer()
                    }
                    .padding(10)
                    
                    // Выбранная тема
                    if isSelected && !isLocked {
                        VStack {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                Spacer()
                            }
                            Spacer()
                        }
                        .padding(10)
                    }
                }
                
                // Информация о теме
                VStack(alignment: .leading, spacing: 8) {
                    // Название
                    HStack(spacing: 6) {
                        Text(theme.displayName)
                            .font(.appTitle)
                            .foregroundColor(isLocked ? .white.opacity(0.5) : .white)
                        
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        } else if theme.isPremium {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    // Бейджи (Анимация)
                    if theme.isAnimated && !isLocked {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 9))
                                .foregroundColor(.cyan)
                            Text("Анимация")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.cyan.opacity(0.9))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(.cyan.opacity(0.15))
                        )
                    }
                    
                    // Описание
                    Text(theme.description)
                        .font(.appSmallCaption)
                        .foregroundColor(isLocked ? .white.opacity(0.3) : .white.opacity(0.6))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 12)
                .padding(.horizontal, 4)
            }
        }
        .buttonStyle(ThemeCardButtonStyle(isSelected: isSelected && !isLocked, isLocked: isLocked))
        .disabled(isLocked && !isSelected)
    }
}

// MARK: - Theme Card Button Style

struct ThemeCardButtonStyle: ButtonStyle {
    let isSelected: Bool
    let isLocked: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(16)
            .background(
                GlassCard(
                    cornerRadius: 20,
                    padding: 0,
                    glowColor: isSelected ? Color.yellow.opacity(0.3) : nil
                ) {
                    Color.clear
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.yellow : (isLocked ? Color.white.opacity(0.2) : Color.clear),
                        lineWidth: isSelected ? 2 : (isLocked ? 1 : 0)
                    )
            )
            .scaleEffect(configuration.isPressed && !isLocked ? 0.95 : 1.0)
            .animation(.appSpring, value: configuration.isPressed)
            .opacity(isLocked ? 0.7 : 1.0)
    }
}

#Preview {
    ThemeSettingsView()
}
