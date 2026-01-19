//
//  SubscriptionManager.swift
//  StepCounter
//
//  Менеджер подписок Premium
//

import Foundation
import StoreKit

// MARK: - Subscription Products

/// Идентификаторы продуктов подписки
enum SubscriptionProductID: String, CaseIterable {
    case monthly = "com.stepcounter.premium.monthly"    // $2.99/месяц
    case yearly = "com.stepcounter.premium.yearly"      // $19.99/год (экономия 44%)
    case lifetime = "com.stepcounter.premium.lifetime"  // $49.99 навсегда
    
    var displayName: String {
        switch self {
        case .monthly: return "Ежемесячная"
        case .yearly: return "Годовая"
        case .lifetime: return "Навсегда"
        }
    }
    
    var description: String {
        switch self {
        case .monthly: return "$2.99/месяц"
        case .yearly: return "$19.99/год (экономия 44%)"
        case .lifetime: return "$49.99 один раз"
        }
    }
    
    var badge: String? {
        switch self {
        case .yearly: return "Популярный"
        case .lifetime: return "Лучшая цена"
        default: return nil
        }
    }
}

// MARK: - Premium Features

/// Функции Premium подписки
enum PremiumFeature: CaseIterable {
    case unlimitedPets        // Все питомцы разблокированы
    case customThemes         // Кастомные темы оформления
    case detailedStats        // Детальная статистика
    case exportData           // Экспорт данных
    case noAds                // Без рекламы
    case prioritySupport      // Приоритетная поддержка
    case exclusiveAccessories // Эксклюзивные аксессуары для питомца
    case advancedChallenges   // Продвинутые челленджи
    case unlimitedRoutes      // Безлимитное сохранение маршрутов
    case animatedThemes       // Анимированные темы
    case advancedAnalytics    // Продвинутая аналитика
    case exclusiveAchievements // Эксклюзивные достижения
    case unlimitedFriends     // Неограниченные друзья
    case unlimitedHistory     // История без ограничений
    
    var title: String {
        switch self {
        case .unlimitedPets: return "Все питомцы"
        case .customThemes: return "Темы оформления"
        case .detailedStats: return "Детальная статистика"
        case .exportData: return "Экспорт данных"
        case .noAds: return "Без рекламы"
        case .prioritySupport: return "Приоритетная поддержка"
        case .exclusiveAccessories: return "Эксклюзивные аксессуары"
        case .advancedChallenges: return "Продвинутые челленджи"
        case .unlimitedRoutes: return "Безлимит маршрутов"
        case .animatedThemes: return "Анимированные темы"
        case .advancedAnalytics: return "Продвинутая аналитика"
        case .exclusiveAchievements: return "Эксклюзивные достижения"
        case .unlimitedFriends: return "Неограниченные друзья"
        case .unlimitedHistory: return "История без ограничений"
        }
    }
    
    var icon: String {
        switch self {
        case .unlimitedPets: return "pawprint.fill"
        case .customThemes: return "paintpalette.fill"
        case .detailedStats: return "chart.bar.fill"
        case .exportData: return "square.and.arrow.up.fill"
        case .noAds: return "xmark.circle.fill"
        case .prioritySupport: return "star.fill"
        case .exclusiveAccessories: return "crown.fill"
        case .advancedChallenges: return "flag.checkered"
        case .unlimitedRoutes: return "map.fill"
        case .animatedThemes: return "sparkles.tv.fill"
        case .advancedAnalytics: return "chart.line.uptrend.xyaxis"
        case .exclusiveAchievements: return "trophy.fill"
        case .unlimitedFriends: return "person.3.fill"
        case .unlimitedHistory: return "clock.arrow.circlepath"
        }
    }
    
    var description: String {
        switch self {
        case .unlimitedPets: return "Разблокируйте всех питомцев: лисичку, пингвина и других"
        case .customThemes: return "Тёмная, светлая, природа, космос и другие темы"
        case .detailedStats: return "Графики за неделю, месяц, год. Средние показатели"
        case .exportData: return "Экспорт в CSV, PDF, интеграция с другими приложениями"
        case .noAds: return "Полностью без рекламы"
        case .prioritySupport: return "Быстрые ответы на вопросы"
        case .exclusiveAccessories: return "Шляпки, очки, костюмы для питомца"
        case .advancedChallenges: return "Марафоны, групповые челленджи"
        case .unlimitedRoutes: return "Сохраняйте неограниченное количество маршрутов"
        case .animatedThemes: return "Живые, анимированные темы с эффектами"
        case .advancedAnalytics: return "Прогнозы, сравнения, тренды"
        case .exclusiveAchievements: return "Эксклюзивные медали только для Premium"
        case .unlimitedFriends: return "Добавляйте неограниченное количество друзей"
        case .unlimitedHistory: return "Храните историю шагов без ограничений"
        }
    }
}

// MARK: - Subscription Manager

@MainActor
final class SubscriptionManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = SubscriptionManager()
    
    // MARK: - Published
    
    /// Активна ли премиум подписка
    @Published private(set) var isPremium: Bool = false
    
    /// Временный ручной переключатель Premium (для личного теста). Потом удалим.
    func togglePremiumManually() {
        setPremiumManually(!isPremium)
    }
    
    /// Временная ручная установка Premium (для личного теста). Потом удалим.
    func setPremiumManually(_ enabled: Bool) {
        let wasPremium = isPremium
        isPremium = enabled
        activeSubscription = nil
        expirationDate = nil
        StorageManager.shared.saveBool(enabled, forKey: premiumKey)
        // Чтобы статус не "перезатирался" сохранённой датой истечения
        try? StorageManager.shared.save(Data(), forKey: "premiumExpirationDate")
        
        // Если Premium отключен, отключаем автопереключение темы и сбрасываем Premium тему
        if !enabled {
            ThemeManager.shared.setupAutoSwitch()
            if wasPremium {
                ThemeManager.shared.checkAndResetPremiumThemeIfNeeded()
            }
        }
    }
    
    /// Тип активной подписки
    @Published private(set) var activeSubscription: SubscriptionProductID?
    
    /// Дата окончания подписки
    @Published private(set) var expirationDate: Date?
    
    /// Загруженные продукты
    @Published private(set) var products: [Product] = []
    
    /// Статус загрузки
    @Published private(set) var isLoading: Bool = false
    
    /// Статус покупки
    @Published private(set) var isPurchasing: Bool = false
    
    /// Ошибка
    @Published var error: String?
    
    // MARK: - Private
    
    private var updateListenerTask: Task<Void, Error>?
    private let premiumKey = "isPremiumUser"
    
    // MARK: - Init
    
    private init() {
        // Загружаем дату окончания Premium (если была добавлена через addPremiumDays)
        if let expirationData = try? StorageManager.shared.load(Data.self, forKey: "premiumExpirationDate"),
           let expiration = try? JSONDecoder().decode(Date.self, from: expirationData) {
            expirationDate = expiration
            // Проверяем, не истекла ли подписка
            let isStillValid = expiration > Date()
            isPremium = isStillValid
            StorageManager.shared.saveBool(isStillValid, forKey: premiumKey)
            
            if !isStillValid {
                // Подписка истекла, удаляем сохраненную дату
                try? StorageManager.shared.save(Data(), forKey: "premiumExpirationDate")
            }
        } else {
            // Проверяем сохранённый статус (для оффлайн)
            isPremium = StorageManager.shared.loadBool(forKey: premiumKey)
        }
        
        // Запускаем слушатель транзакций
        updateListenerTask = listenForTransactions()
        
        // Загружаем продукты и проверяем подписку
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Загрузка продуктов из App Store
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let productIDs = SubscriptionProductID.allCases.map { $0.rawValue }
            let storeProducts = try await Product.products(for: productIDs)
            
            // Сортируем: месячная, годовая, пожизненная
            products = storeProducts.sorted { p1, p2 in
                let order: [String: Int] = [
                    SubscriptionProductID.monthly.rawValue: 0,
                    SubscriptionProductID.yearly.rawValue: 1,
                    SubscriptionProductID.lifetime.rawValue: 2
                ]
                return (order[p1.id] ?? 99) < (order[p2.id] ?? 99)
            }
            
            print("✅ Загружено \(products.count) продуктов подписки")
        } catch {
            print("❌ Ошибка загрузки продуктов: \(error)")
            self.error = "Не удалось загрузить варианты подписки"
        }
    }
    
    /// Покупка подписки
    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateSubscriptionStatus()
                await transaction.finish()
                print("✅ Подписка оформлена: \(product.id)")
                return true
                
            case .userCancelled:
                print("ℹ️ Пользователь отменил покупку")
                return false
                
            case .pending:
                print("⏳ Покупка ожидает подтверждения")
                error = "Покупка ожидает подтверждения"
                return false
                
            @unknown default:
                return false
            }
        } catch {
            print("❌ Ошибка покупки: \(error)")
            self.error = "Ошибка оформления подписки"
            return false
        }
    }
    
    /// Покупка по ID
    func purchase(productId: SubscriptionProductID) async -> Bool {
        guard let product = products.first(where: { $0.id == productId.rawValue }) else {
            error = "Продукт не найден"
            return false
        }
        return await purchase(product)
    }
    
    /// Восстановление покупок
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            print("✅ Покупки восстановлены")
        } catch {
            print("❌ Ошибка восстановления: \(error)")
            self.error = "Не удалось восстановить покупки"
        }
    }
    
    // MARK: - Private Methods
    
    /// Проверка верификации
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    /// Обновление статуса подписки
    func updateSubscriptionStatus() async {
        var foundPremium = false
        var foundExpirationDate: Date?
        var foundSubscription: SubscriptionProductID?
        
        // Проверяем транзакции StoreKit
        // Собираем все активные транзакции
        var activeTransactions: [(transaction: Transaction, productId: SubscriptionProductID, expirationDate: Date?)] = []
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            
            // Проверяем, не отменена ли подписка
            if transaction.revocationDate == nil {
                if let productId = SubscriptionProductID(rawValue: transaction.productID) {
                    let expiration = transaction.expirationDate
                    activeTransactions.append((transaction, productId, expiration))
                }
            }
        }
        
        // Выбираем транзакцию с самой поздней датой окончания (самая актуальная подписка)
        if let latestTransaction = activeTransactions.max(by: { t1, t2 in
            let date1 = t1.expirationDate ?? Date.distantFuture
            let date2 = t2.expirationDate ?? Date.distantFuture
            return date1 < date2
        }) {
            foundPremium = true
            foundSubscription = latestTransaction.productId
            foundExpirationDate = latestTransaction.expirationDate
            
            print("✅ Найдена активная подписка: \(latestTransaction.productId.displayName)")
            if let expiration = latestTransaction.expirationDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "d MMMM yyyy"
                formatter.locale = Locale(identifier: "ru_RU")
                print("   Дата окончания: \(formatter.string(from: expiration))")
            }
        }
        
        // Если нет активной подписки из StoreKit, проверяем сохраненную дату (из addPremiumDays)
        if !foundPremium, let savedExpirationData = try? StorageManager.shared.load(Data.self, forKey: "premiumExpirationDate"),
           let savedExpiration = try? JSONDecoder().decode(Date.self, from: savedExpirationData) {
            // Проверяем, не истекла ли подписка
            if savedExpiration > Date() {
                foundPremium = true
                foundExpirationDate = savedExpiration
            } else {
                // Подписка истекла, удаляем сохраненную дату
                try? StorageManager.shared.save(Data(), forKey: "premiumExpirationDate")
            }
        }
        
        // Сохраняем предыдущее состояние для проверки изменений
        let wasPremium = isPremium
        
        // Обновляем состояние
        isPremium = foundPremium
        activeSubscription = foundSubscription
        expirationDate = foundExpirationDate
        StorageManager.shared.saveBool(isPremium, forKey: premiumKey)
        
        // Если Premium статус изменился с true на false, проверяем и сбрасываем Premium тему
        if wasPremium && !isPremium {
            Task { @MainActor in
                ThemeManager.shared.checkAndResetPremiumThemeIfNeeded()
            }
        }
        
        // Если Premium отключен, отключаем автопереключение темы
        if !isPremium {
            ThemeManager.shared.setupAutoSwitch()
        }
    }
    
    /// Слушатель транзакций
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    print("❌ Ошибка обработки транзакции: \(error)")
                }
            }
        }
    }
    
    // MARK: - Premium Management
    
    /// Добавить дни Premium (для наград из сезонов и т.д.)
    func addPremiumDays(_ days: Int) {
        let calendar = Calendar.current
        let newExpirationDate: Date
        
        if let currentExpiration = expirationDate, currentExpiration > Date() {
            // Если уже есть активная подписка, продлеваем её
            newExpirationDate = calendar.date(byAdding: .day, value: days, to: currentExpiration) ?? Date()
        } else {
            // Если подписки нет, добавляем с сегодняшнего дня
            newExpirationDate = calendar.date(byAdding: .day, value: days, to: Date()) ?? Date()
        }
        
        expirationDate = newExpirationDate
        isPremium = true
        StorageManager.shared.saveBool(true, forKey: premiumKey)
        
        // Сохраняем дату окончания для проверки
        if let expirationData = try? JSONEncoder().encode(newExpirationDate) {
            try? StorageManager.shared.save(expirationData, forKey: "premiumExpirationDate")
        }
        
        print("✅ Добавлено \(days) дней Premium. Истекает: \(newExpirationDate)")
    }
    
    // MARK: - Feature Access
    
    /// Проверка доступа к премиум-функции
    func hasAccess(to feature: PremiumFeature) -> Bool {
        // Проверяем как статус, так и дату окончания
        if !isPremium { return false }
        
        // Если есть дата окончания, проверяем, не истекла ли она
        if let expiration = expirationDate, expiration < Date() {
            isPremium = false
            StorageManager.shared.saveBool(false, forKey: premiumKey)
            return false
        }
        
        return true
    }
    
    /// Бесплатные функции (ограниченные)
    var freeFeatures: [String] {
        return [
            "Подсчёт шагов",
            "1 питомец (собачка)",
            "3 достижения",
            "Базовая статистика",
            "5 сохранённых маршрутов"
        ]
    }
}

// MARK: - Store Error (если нет в других файлах)

enum StoreError: LocalizedError {
    case productNotFound
    case purchaseFailed
    case verificationFailed
    case userCancelled
    case pending
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotFound: return "Продукт не найден"
        case .purchaseFailed: return "Ошибка покупки"
        case .verificationFailed: return "Ошибка верификации"
        case .userCancelled: return "Отменено"
        case .pending: return "Ожидает подтверждения"
        case .unknown: return "Неизвестная ошибка"
        }
    }
}
