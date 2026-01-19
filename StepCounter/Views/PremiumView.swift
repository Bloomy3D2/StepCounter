//
//  PremiumView.swift
//  StepCounter
//
//  Экран подписки Premium (Paywall)
//

import SwiftUI
import StoreKit

struct PremiumView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProduct: Product?
    @State private var showSuccess = false
    
    // Цвета из темы
    private var bgColor: Color { themeManager.backgroundColor }
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    private let accentGold = Color(red: 1.0, green: 0.84, blue: 0.0) // Золотой всегда одинаковый
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if subscriptionManager.isPremium {
                    // Если есть подписка - показываем информацию о ней
                    subscriptionInfoSection
                } else {
                    // Если нет подписки - показываем предложение
                    VStack(spacing: 24) {
                        // Заголовок
                        headerSection
                        
                        // Преимущества
                        featuresSection
                        
                        // Варианты подписки
                        productsSection
                        
                        // Кнопка покупки
                        purchaseButton
                        
                        // Восстановить покупки
                        restoreButton
                        
                        // Правовая информация
                        legalText
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .background(
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .ignoresSafeArea()
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
            .alert("Подписка оформлена! 🎉", isPresented: $showSuccess) {
                Button("Отлично!") { dismiss() }
            } message: {
                Text("Добро пожаловать в Premium! Все функции разблокированы.")
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Иконка
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accentGold, accentGold.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            
            Text("StepCounter Premium")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Разблокируйте все возможности приложения")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Features
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Все Premium функции")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(PremiumFeature.allCases, id: \.title) { feature in
                    FeatureCard(
                        icon: feature.icon,
                        title: feature.title,
                        accentColor: accentGreen,
                        cardColor: cardColor
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardColor)
                .shadow(color: accentGreen.opacity(0.3), radius: 20, x: 0, y: 10)
        )
    }
    
    // MARK: - Products
    
    private var productsSection: some View {
        VStack(spacing: 12) {
            if subscriptionManager.isLoading {
                ProgressView()
                    .tint(.white)
                    .padding()
            } else if subscriptionManager.products.isEmpty {
                Text("Не удалось загрузить варианты подписки")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .padding()
            } else {
                ForEach(subscriptionManager.products, id: \.id) { product in
                    ProductCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        badge: badgeFor(product),
                        accentColor: accentGreen,
                        accentGold: accentGold,
                        cardColor: cardColor
                    ) {
                        selectedProduct = product
                    }
                }
            }
        }
        .onAppear {
            // Выбираем годовую подписку по умолчанию
            if selectedProduct == nil {
                if let yearlyProduct = subscriptionManager.products.first(where: { $0.id == SubscriptionProductID.yearly.rawValue }) {
                    selectedProduct = yearlyProduct
                } else {
                    selectedProduct = subscriptionManager.products.first
                }
            }
        }
    }
    
    private func badgeFor(_ product: Product) -> String? {
        if product.id == SubscriptionProductID.yearly.rawValue {
            return "🔥 Популярный"
        } else if product.id == SubscriptionProductID.lifetime.rawValue {
            return "💎 Лучшая цена"
        }
        return nil
    }
    
    // MARK: - Purchase Button
    
    private var purchaseButton: some View {
        Button {
            Task {
                if let product = selectedProduct {
                    let success = await subscriptionManager.purchase(product)
                    if success {
                        showSuccess = true
                    }
                }
            }
        } label: {
            HStack {
                if subscriptionManager.isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Оформить подписку")
                        .font(.system(size: 18, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [accentGreen, accentGreen.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
        }
        .disabled(selectedProduct == nil || subscriptionManager.isPurchasing)
        .opacity(selectedProduct == nil ? 0.5 : 1.0)
    }
    
    // MARK: - Restore
    
    private var restoreButton: some View {
        Button {
            Task {
                await subscriptionManager.restorePurchases()
                if subscriptionManager.isPremium {
                    showSuccess = true
                }
            }
        } label: {
            Text("Восстановить покупки")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    // MARK: - Subscription Info
    
    private var subscriptionInfoSection: some View {
        VStack(spacing: 24) {
            // Заголовок
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accentGold, accentGold.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
                
                Text("Premium активна")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.top, 40)
            
            // Информация о подписке
            GlassCard(cornerRadius: 20, padding: 24, glowColor: accentGold.opacity(0.3)) {
                VStack(spacing: 20) {
                    // Тип подписки
                    HStack {
                        Text("Тип подписки:")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text(subscriptionTypeDisplay)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // Дата окончания или статус
                    if isLifetimeSubscription {
                        // Для lifetime подписки
                        HStack {
                            Text("Статус:")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                            
                            Text("Навсегда")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(accentGold)
                        }
                    } else if let expirationDate = subscriptionManager.expirationDate {
                        // Для месячной и годовой подписки
                        let dateInfo = formatExpirationDate(expirationDate)
                        HStack {
                            Text("Действует до:")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(dateInfo.day) \(dateInfo.month)")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                
                                let year = Calendar.current.component(.year, from: expirationDate)
                                Text("\(year) год")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    } else {
                        // Если дата не определена
                        HStack {
                            Text("Статус:")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                            
                            Text("Активна")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(accentGreen)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Преимущества Premium
            VStack(alignment: .leading, spacing: 16) {
                Text("Доступные функции")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(PremiumFeature.allCases, id: \.title) { feature in
                        FeatureCard(
                            icon: feature.icon,
                            title: feature.title,
                            accentColor: accentGreen,
                            cardColor: cardColor
                        )
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardColor)
                    .shadow(color: accentGreen.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 40)
    }
    
    private var subscriptionTypeDisplay: String {
        if let subscription = subscriptionManager.activeSubscription {
            return subscription.displayName
        }
        return "Premium"
    }
    
    private var isLifetimeSubscription: Bool {
        subscriptionManager.activeSubscription == SubscriptionProductID.lifetime
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }
    
    private var dayMonthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }
    
    private func formatExpirationDate(_ date: Date) -> (day: String, month: String) {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        monthFormatter.locale = Locale(identifier: "ru_RU")
        let month = monthFormatter.string(from: date)
        return ("\(day)", month)
    }
    
    // MARK: - Legal
    
    private var legalText: some View {
        VStack(spacing: 8) {
            Text("Подписка автоматически продлевается. Отмена возможна в настройках App Store минимум за 24 часа до окончания периода.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("Условия использования") { }
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                
                Button("Политика конфиденциальности") { }
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(accentColor)
        }
    }
}

// MARK: - Product Card

struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let badge: String?
    let accentColor: Color
    let accentGold: Color
    let cardColor: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule().fill(
                                        product.id.contains("yearly") ? accentColor : accentGold
                                    )
                                )
                        }
                    }
                    
                    Text(product.description)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    if product.id.contains("yearly") {
                        Text("~\(monthlyPrice(from: product))/мес")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
    
    private func monthlyPrice(from product: Product) -> String {
        let yearly = product.price
        let monthly = yearly / 12
        let currencyCode = product.priceFormatStyle.currencyCode
        return monthly.formatted(.currency(code: currencyCode ?? "USD"))
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let icon: String
    let title: String
    let accentColor: Color
    let cardColor: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(accentColor)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(accentColor.opacity(0.15))
                )
            
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardColor.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    PremiumView()
}
