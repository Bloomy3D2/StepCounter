//
//  ShopView.swift
//  ClashMini
//
//  Красивый интерфейс магазина с реальными покупками
//

import SwiftUI
import StoreKit

struct ShopView: View {
    @ObservedObject var shopManager = ShopManager.shared
    @StateObject var storeManager = StoreKitManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTab: ShopTab = .boosters
    @State private var showPurchaseAlert = false
    @State private var purchaseMessage = ""
    @State private var isPurchasing = false
    @State private var showRestoreAlert = false
    
    enum ShopTab: String, CaseIterable {
        case boosters = "Бустеры"
        case gems = "Гемы"
        case offers = "Акции"
    }
    
    var body: some View {
        ZStack {
            // Фон
            backgroundGradient
            
            VStack(spacing: 0) {
                // Хедер
                shopHeader
                
                // Валюта
                currencyBar
                
                // Табы
                tabBar
                
                // Контент
                ScrollView(showsIndicators: false) {
                    switch selectedTab {
                    case .boosters:
                        boostersGrid
                    case .gems:
                        gemsGrid
                    case .offers:
                        offersSection
                    }
                }
                .padding(.horizontal)
            }
        }
        .alert("Покупка", isPresented: $showPurchaseAlert) {
            Button("OK") { }
        } message: {
            Text(purchaseMessage)
        }
        .alert("Восстановление", isPresented: $showRestoreAlert) {
            Button("OK") { }
        } message: {
            Text("Покупки успешно восстановлены!")
        }
        .overlay {
            if isPurchasing || storeManager.isPurchasing {
                purchasingOverlay
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.05, blue: 0.2),
                Color(red: 0.15, green: 0.1, blue: 0.25),
                Color(red: 0.1, green: 0.15, blue: 0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(
            // Звёзды/частицы
            GeometryReader { geo in
                ForEach(0..<20, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.1...0.3)))
                        .frame(width: CGFloat.random(in: 2...4))
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height)
                        )
                }
            }
        )
    }
    
    // MARK: - Header
    
    private var shopHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text("МАГАЗИН")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .orange.opacity(0.5), radius: 10)
            
            Spacer()
            
            // Кнопка восстановления покупок
            Button {
                Task {
                    await storeManager.restorePurchases()
                    showRestoreAlert = true
                }
            } label: {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding()
    }
    
    // MARK: - Currency Bar
    
    private var currencyBar: some View {
        HStack(spacing: 20) {
            // Золото
            currencyPill(
                icon: "🪙",
                value: shopManager.gold,
                color: .yellow
            )
            
            // Гемы
            currencyPill(
                icon: "💎",
                value: shopManager.gems,
                color: .cyan
            )
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
    
    private func currencyPill(icon: String, value: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(icon)
                .font(.title3)
            
            Text("\(value)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            Capsule()
                .stroke(color.opacity(0.5), lineWidth: 1)
        )
    }
    
    // MARK: - Tab Bar
    
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(ShopTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(tab.rawValue)
                            .font(.system(size: 16, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.5))
                        
                        Rectangle()
                            .fill(selectedTab == tab ? Color.orange : Color.clear)
                            .frame(height: 3)
                            .cornerRadius(2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
    
    // MARK: - Boosters Grid
    
    private var boostersGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(BoosterType.allCases) { booster in
                BoosterCard(
                    booster: booster,
                    owned: shopManager.boosterCount(booster),
                    onBuyWithGems: {
                        buyBooster(booster, withGems: true)
                    },
                    onBuyWithGold: {
                        buyBooster(booster, withGems: false)
                    }
                )
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Gems Grid
    
    private var gemsGrid: some View {
        VStack(spacing: 16) {
            // Информация о загрузке
            if storeManager.isLoading {
                HStack {
                    ProgressView()
                        .tint(.white)
                    Text("Загрузка продуктов...")
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
            }
            
            // Сетка пакетов
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(GemPack.allCases) { pack in
                    // Получаем реальную цену из StoreKit если доступна
                    let storePrice = storeManager.formattedPrice(for: pack.storeProductId)
                    
                    GemPackCardWithStore(
                        pack: pack,
                        storePrice: storePrice,
                        isLoading: storeManager.isPurchasing
                    ) {
                        purchaseGemPack(pack)
                    }
                }
            }
            
            // Примечание о реальных покупках
            VStack(spacing: 4) {
                Text("💳 Реальные покупки через App Store")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                
                Text("Деньги списываются с вашего Apple ID")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.top, 10)
        }
        .padding(.vertical)
    }
    
    // MARK: - Offers Section
    
    private var offersSection: some View {
        VStack(spacing: 16) {
            ForEach(shopManager.specialOffers) { offer in
                SpecialOfferCard(offer: offer) {
                    purchaseOffer(offer)
                }
            }
            
            if shopManager.specialOffers.isEmpty {
                VStack(spacing: 12) {
                    Text("🎁")
                        .font(.system(size: 60))
                    
                    Text("Нет активных акций")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Заходите позже!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.vertical, 60)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Purchasing Overlay
    
    private var purchasingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Обработка покупки...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(white: 0.2))
            )
        }
    }
    
    // MARK: - Actions
    
    private func buyBooster(_ booster: BoosterType, withGems: Bool) {
        let price = withGems ? booster.gemPrice : booster.goldPrice
        let currency = withGems ? shopManager.gems : shopManager.gold
        let currencyName = withGems ? "гемов" : "золота"
        
        if currency < price {
            purchaseMessage = "Недостаточно \(currencyName)!"
            showPurchaseAlert = true
            return
        }
        
        if shopManager.buyBooster(booster, withGems: withGems) {
            purchaseMessage = "Вы купили \(booster.name)! 🎉"
            showPurchaseAlert = true
        }
    }
    
    private func purchaseGemPack(_ pack: GemPack) {
        Task {
            // Пробуем реальную покупку через StoreKit
            let result = await storeManager.purchaseGemPack(pack)
            
            await MainActor.run {
                if result.success {
                    purchaseMessage = "Вы получили \(result.gemsAwarded) гемов! 💎\nСпасибо за покупку!"
                    showPurchaseAlert = true
                } else if let error = result.error {
                    switch error {
                    case .userCancelled:
                        // Пользователь отменил — не показываем ошибку
                        break
                    case .pending:
                        purchaseMessage = "Покупка ожидает подтверждения. Проверьте позже."
                        showPurchaseAlert = true
                    case .productNotFound:
                        // Fallback на симуляцию для тестирования
                        fallbackPurchase(pack)
                    default:
                        purchaseMessage = "Ошибка покупки: \(error.localizedDescription)"
                        showPurchaseAlert = true
                    }
                }
            }
        }
    }
    
    /// Fallback покупка для тестирования (когда StoreKit недоступен)
    private func fallbackPurchase(_ pack: GemPack) {
        isPurchasing = true
        
        shopManager.purchaseGemPack(pack) { success in
            isPurchasing = false
            if success {
                purchaseMessage = "🧪 Тестовый режим\nВы получили \(pack.totalGems) гемов! 💎"
                showPurchaseAlert = true
            }
        }
    }
    
    private func purchaseOffer(_ offer: SpecialOffer) {
        isPurchasing = true
        
        shopManager.purchaseSpecialOffer(offer) { success in
            isPurchasing = false
            if success {
                purchaseMessage = "Отличная покупка! Вы получили все бонусы! 🎁"
                showPurchaseAlert = true
            }
        }
    }
}

// MARK: - Booster Card

struct BoosterCard: View {
    let booster: BoosterType
    let owned: Int
    let onBuyWithGems: () -> Void
    let onBuyWithGold: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Иконка
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [booster.color.opacity(0.5), booster.color.opacity(0.2)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Text(booster.icon)
                    .font(.system(size: 30))
            }
            
            // Название
            Text(booster.name)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            
            // Описание
            Text(booster.description)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // В наличии
            if owned > 0 {
                Text("В наличии: \(owned)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            // Кнопки покупки
            HStack(spacing: 8) {
                // За гемы
                Button(action: onBuyWithGems) {
                    HStack(spacing: 2) {
                        Text("💎")
                            .font(.caption)
                        Text("\(booster.gemPrice)")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.cyan.opacity(0.3))
                    )
                }
                
                // За золото
                Button(action: onBuyWithGold) {
                    HStack(spacing: 2) {
                        Text("🪙")
                            .font(.caption)
                        Text("\(booster.goldPrice)")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.yellow.opacity(0.3))
                    )
                }
            }
        }
        .padding()
        .frame(height: 220)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            booster.color.opacity(0.2),
                            Color(white: 0.1).opacity(0.9)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(booster.color.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Gem Pack Card

struct GemPackCard: View {
    let pack: GemPack
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Иконка
            Text(pack.icon)
                .font(.system(size: 40))
            
            // Название
            Text(pack.name)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            // Количество гемов
            VStack(spacing: 2) {
                Text("\(pack.gems)")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                if pack.bonusGems > 0 {
                    Text("+\(pack.bonusGems) бонус!")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            // Кнопка покупки
            Button(action: onPurchase) {
                Text("$\(String(format: "%.2f", pack.priceUSD))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .shadow(color: .green.opacity(0.5), radius: 5)
            }
        }
        .padding()
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.2),
                            Color(white: 0.1).opacity(0.9)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Gem Pack Card With StoreKit

struct GemPackCardWithStore: View {
    let pack: GemPack
    let storePrice: String
    let isLoading: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Популярность бейдж для больших пакетов
            if pack == .large || pack == .huge {
                Text("ПОПУЛЯРНЫЙ")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.orange)
                    )
            }
            
            // Иконка
            Text(pack.icon)
                .font(.system(size: 36))
            
            // Название
            Text(pack.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            // Количество гемов
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Text("💎")
                        .font(.system(size: 16))
                    Text("\(pack.gems)")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                
                if pack.bonusGems > 0 {
                    Text("+\(pack.bonusGems) бонус!")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            // Кнопка покупки с реальной ценой
            Button(action: onPurchase) {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        // Показываем цену из StoreKit или fallback
                        Text(storePrice != "—" ? storePrice : "$\(String(format: "%.2f", pack.priceUSD))")
                            .font(.system(size: 15, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(width: 90, height: 36)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .shadow(color: .green.opacity(0.5), radius: 5)
            }
            .disabled(isLoading)
        }
        .padding()
        .frame(height: 210)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.2),
                            Color(white: 0.1).opacity(0.9)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    pack == .large || pack == .huge
                        ? Color.orange.opacity(0.6)
                        : Color.cyan.opacity(0.4),
                    lineWidth: pack == .large || pack == .huge ? 2 : 1
                )
        )
    }
}

// MARK: - Special Offer Card

struct SpecialOfferCard: View {
    let offer: SpecialOffer
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Хедер
            HStack {
                Text(offer.icon)
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(offer.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(offer.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Скидка
                Text("-\(offer.discountPercent)%")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.red)
                    )
            }
            
            // Содержимое
            HStack(spacing: 16) {
                // Гемы
                VStack {
                    Text("💎")
                        .font(.title2)
                    Text("\(offer.gems)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.cyan)
                }
                
                // Золото
                VStack {
                    Text("🪙")
                        .font(.title2)
                    Text("\(offer.gold)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.yellow)
                }
                
                // Бустеры
                VStack {
                    Text("⚡")
                        .font(.title2)
                    Text("\(offer.boosters.count) бустеров")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.purple)
                }
            }
            
            // Кнопка покупки
            Button(action: onPurchase) {
                HStack {
                    Text("$\(String(format: "%.2f", offer.originalPrice))")
                        .strikethrough()
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("$\(String(format: "%.2f", offer.discountedPrice))")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: .orange.opacity(0.5), radius: 10)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.2),
                            Color.purple.opacity(0.1),
                            Color(white: 0.1).opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [.orange.opacity(0.6), .purple.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
    }
}

#Preview {
    ShopView()
}
