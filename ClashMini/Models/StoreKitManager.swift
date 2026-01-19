//
//  StoreKitManager.swift
//  ClashMini
//
//  Менеджер внутриигровых покупок через StoreKit 2
//

import Foundation
import StoreKit

// MARK: - Product IDs

/// Идентификаторы продуктов в App Store Connect
/// ВАЖНО: Замените на реальные ID из вашего App Store Connect
enum StoreProductID: String, CaseIterable {
    // Пакеты гемов
    case gemsTiny = "com.game.clashmini.gems.tiny"           // 80 гемов - $0.99
    case gemsSmall = "com.game.clashmini.gems.small"         // 500 гемов - $4.99
    case gemsMedium = "com.game.clashmini.gems.medium"       // 1200 гемов - $9.99
    case gemsLarge = "com.game.clashmini.gems.large"         // 2500 гемов - $19.99
    case gemsHuge = "com.game.clashmini.gems.huge"           // 6500 гемов - $49.99
    case gemsMega = "com.game.clashmini.gems.mega"           // 14000 гемов - $99.99
    
    // Специальные предложения
    case offerDaily = "com.game.clashmini.offer.daily"       // Ежедневная сделка
    case offerStarter = "com.game.clashmini.offer.starter"   // Стартовый набор
    case offerLegendary = "com.game.clashmini.offer.legendary" // Легендарный бандл
    
    // Подписки (опционально)
    case vipMonthly = "com.game.clashmini.vip.monthly"       // VIP подписка
    case vipYearly = "com.game.clashmini.vip.yearly"         // VIP годовая
    
    /// Количество гемов для пакета
    var gemAmount: Int {
        switch self {
        case .gemsTiny: return 80
        case .gemsSmall: return 550      // 500 + 50 бонус
        case .gemsMedium: return 1400    // 1200 + 200 бонус
        case .gemsLarge: return 3000     // 2500 + 500 бонус
        case .gemsHuge: return 8000      // 6500 + 1500 бонус
        case .gemsMega: return 18000     // 14000 + 4000 бонус
        default: return 0
        }
    }
}

// MARK: - Store Error

enum StoreError: LocalizedError {
    case productNotFound
    case purchaseFailed
    case verificationFailed
    case userCancelled
    case pending
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Продукт не найден в App Store"
        case .purchaseFailed:
            return "Ошибка покупки"
        case .verificationFailed:
            return "Ошибка верификации покупки"
        case .userCancelled:
            return "Покупка отменена"
        case .pending:
            return "Покупка ожидает подтверждения"
        case .unknown:
            return "Неизвестная ошибка"
        }
    }
}

// MARK: - Purchase Result

struct PurchaseResult {
    let success: Bool
    let productId: String?
    let error: StoreError?
    let gemsAwarded: Int
}

// MARK: - StoreKit Manager

@MainActor
final class StoreKitManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = StoreKitManager()
    
    // MARK: - Published Properties
    
    /// Загруженные продукты из App Store
    @Published private(set) var products: [Product] = []
    
    /// Продукты по категориям
    @Published private(set) var gemProducts: [Product] = []
    @Published private(set) var offerProducts: [Product] = []
    @Published private(set) var subscriptionProducts: [Product] = []
    
    /// Купленные продукты (для подписок и non-consumable)
    @Published private(set) var purchasedProductIDs: Set<String> = []
    
    /// Статус загрузки
    @Published private(set) var isLoading = false
    
    /// Статус покупки
    @Published private(set) var isPurchasing = false
    
    /// Последняя ошибка
    @Published var lastError: StoreError?
    
    // MARK: - Private
    
    private var updateListenerTask: Task<Void, Error>?
    
    // MARK: - Init
    
    private init() {
        // Запускаем слушатель транзакций
        updateListenerTask = listenForTransactions()
        
        // Загружаем продукты
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    
    /// Загрузка продуктов из App Store
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let productIDs = StoreProductID.allCases.map { $0.rawValue }
            let storeProducts = try await Product.products(for: productIDs)
            
            // Сортируем по цене
            products = storeProducts.sorted { $0.price < $1.price }
            
            // Разделяем по категориям
            gemProducts = products.filter { product in
                product.id.contains("gems")
            }
            
            offerProducts = products.filter { product in
                product.id.contains("offer")
            }
            
            subscriptionProducts = products.filter { product in
                product.id.contains("vip")
            }
            
            print("✅ Загружено \(products.count) продуктов из App Store")
            
        } catch {
            print("❌ Ошибка загрузки продуктов: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    /// Покупка продукта
    func purchase(_ product: Product) async -> PurchaseResult {
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Верифицируем покупку
                let transaction = try checkVerified(verification)
                
                // Обрабатываем покупку
                let gemsAwarded = await handleSuccessfulPurchase(transaction)
                
                // Завершаем транзакцию
                await transaction.finish()
                
                print("✅ Покупка успешна: \(product.id)")
                
                return PurchaseResult(
                    success: true,
                    productId: product.id,
                    error: nil,
                    gemsAwarded: gemsAwarded
                )
                
            case .userCancelled:
                print("ℹ️ Пользователь отменил покупку")
                lastError = .userCancelled
                return PurchaseResult(success: false, productId: nil, error: .userCancelled, gemsAwarded: 0)
                
            case .pending:
                print("⏳ Покупка ожидает подтверждения")
                lastError = .pending
                return PurchaseResult(success: false, productId: nil, error: .pending, gemsAwarded: 0)
                
            @unknown default:
                lastError = .unknown
                return PurchaseResult(success: false, productId: nil, error: .unknown, gemsAwarded: 0)
            }
            
        } catch {
            print("❌ Ошибка покупки: \(error)")
            lastError = .purchaseFailed
            return PurchaseResult(success: false, productId: nil, error: .purchaseFailed, gemsAwarded: 0)
        }
    }
    
    /// Покупка по ID продукта
    func purchase(productId: String) async -> PurchaseResult {
        guard let product = products.first(where: { $0.id == productId }) else {
            lastError = .productNotFound
            return PurchaseResult(success: false, productId: nil, error: .productNotFound, gemsAwarded: 0)
        }
        
        return await purchase(product)
    }
    
    /// Покупка пакета гемов
    func purchaseGemPack(_ pack: GemPack) async -> PurchaseResult {
        let productId = pack.storeProductId
        return await purchase(productId: productId)
    }
    
    // MARK: - Restore Purchases
    
    /// Восстановление покупок
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            print("✅ Покупки восстановлены")
        } catch {
            print("❌ Ошибка восстановления: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    /// Проверка верификации транзакции
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    /// Обработка успешной покупки
    private func handleSuccessfulPurchase(_ transaction: Transaction) async -> Int {
        // Определяем количество гемов по ID продукта
        guard let storeProduct = StoreProductID(rawValue: transaction.productID) else {
            return 0
        }
        
        let gemsToAward = storeProduct.gemAmount
        
        if gemsToAward > 0 {
            // Начисляем гемы через ShopManager
            await MainActor.run {
                ShopManager.shared.addGems(gemsToAward)
            }
        }
        
        // Для non-consumable и подписок сохраняем статус
        if transaction.productType != .consumable {
            purchasedProductIDs.insert(transaction.productID)
        }
        
        return gemsToAward
    }
    
    /// Слушатель транзакций (для обновлений вне приложения)
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    _ = await self.handleSuccessfulPurchase(transaction)
                    await transaction.finish()
                } catch {
                    print("❌ Ошибка обработки транзакции: \(error)")
                }
            }
        }
    }
    
    /// Обновление списка купленных продуктов
    private func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            
            if transaction.revocationDate == nil {
                purchasedProductIDs.insert(transaction.productID)
            } else {
                purchasedProductIDs.remove(transaction.productID)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Получить продукт по ID
    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }
    
    /// Проверить, куплен ли продукт
    func isPurchased(_ productId: String) -> Bool {
        purchasedProductIDs.contains(productId)
    }
    
    /// Отформатированная цена продукта
    func formattedPrice(for productId: String) -> String {
        guard let product = product(for: productId) else {
            return "—"
        }
        return product.displayPrice
    }
}

// MARK: - GemPack Extension

extension GemPack {
    /// ID продукта в App Store
    var storeProductId: String {
        switch self {
        case .tiny: return StoreProductID.gemsTiny.rawValue
        case .small: return StoreProductID.gemsSmall.rawValue
        case .medium: return StoreProductID.gemsMedium.rawValue
        case .large: return StoreProductID.gemsLarge.rawValue
        case .huge: return StoreProductID.gemsHuge.rawValue
        case .mega: return StoreProductID.gemsMega.rawValue
        }
    }
}
