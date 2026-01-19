//
//  ShareManager.swift
//  StepCounter
//
//  Менеджер для sharing достижений и контента
//

import SwiftUI
import UIKit

// MARK: - Share Manager

@MainActor
final class ShareManager {
    static let shared = ShareManager()
    
    // Кэш для изображений достижений
    private var achievementImageCache: [String: UIImage] = [:]
    
    // Флаг для предотвращения множественных презентаций
    private var isPresenting = false
    // Счетчик попыток показа (для предотвращения бесконечных циклов)
    private var presentationAttempts = 0
    private let maxPresentationAttempts = 2
    
    private init() {}
    
    // MARK: - Share Achievement
    
    func shareAchievement(_ achievement: Achievement) {
        // Текст для sharing
        let shareText = """
        🏆 Я разблокировал достижение "\(achievement.type.title)"!
        
        \(achievement.type.description)
        
        Скачай StepCounter и начни свой путь к здоровью! 💪
        """
        
        // Deep link (замените на реальный URL схемы)
        let appStoreURL = "https://apps.apple.com/app/stepcounter" // Замените на реальную ссылку
        let fullText = "\(shareText)\n\n\(appStoreURL)"
        
        // ВСЕГДА показываем sharing СРАЗУ с текстом (без изображения)
        // Это гарантирует мгновенное открытие
        // Вызываем напрямую на главном потоке для максимальной скорости
        if Thread.isMainThread {
            presentActivityViewControllerImmediate(items: [fullText])
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.presentActivityViewControllerImmediate(items: [fullText])
            }
        }
        
        // Изображение создаём в фоне для следующего раза (не блокируя текущий sharing)
        let cacheKey = "\(achievement.id)_\(achievement.type.title)"
        
        // Создаём изображение в фоне для кэша (для следующего раза)
        Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }
            if let image = await self.createAchievementImageAsync(achievement) {
                await MainActor.run {
                    self.achievementImageCache[cacheKey] = image
                }
            }
        }
    }
    
    // MARK: - Create Achievement Image (Async)
    
    private func createAchievementImageAsync(_ achievement: Achievement) async -> UIImage? {
        return await Task.detached(priority: .userInitiated) {
            // Размер изображения для sharing (уменьшен для быстрого рендеринга)
            let size = CGSize(width: 800, height: 420) // Оптимизированный размер
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Фон с градиентом
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 1.0).cgColor,
                    UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0).cgColor
                ] as CFArray,
                locations: [0.0, 1.0]
            )!
            
            cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
            
            // Медаль в центре
            let medalSize: CGFloat = 200
            let medalRect = CGRect(
                x: (size.width - medalSize) / 2,
                y: 150,
                width: medalSize,
                height: medalSize
            )
            
            // Рамка медали
            cgContext.setFillColor(UIColor.systemGray.cgColor)
            cgContext.fillEllipse(in: medalRect)
            
            // Внутренний круг
            let innerRect = medalRect.insetBy(dx: 20, dy: 20)
            cgContext.setFillColor(UIColor.systemBlue.cgColor)
            cgContext.fillEllipse(in: innerRect)
            
            // Текст достижения
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            
            let title = achievement.type.title
            let titleSize = title.size(withAttributes: titleAttributes)
            let titleRect = CGRect(
                x: (size.width - titleSize.width) / 2,
                y: medalRect.maxY + 40,
                width: titleSize.width,
                height: titleSize.height
            )
            title.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Описание
            let descriptionAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
            
            let description = achievement.type.description
            let descriptionSize = description.size(withAttributes: descriptionAttributes)
            let descriptionRect = CGRect(
                x: (size.width - descriptionSize.width) / 2,
                y: titleRect.maxY + 20,
                width: min(descriptionSize.width, size.width - 100),
                height: descriptionSize.height
            )
            description.draw(in: descriptionRect, withAttributes: descriptionAttributes)
            
            // Логотип приложения внизу
            let logoText = "StepCounter"
            let logoAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.6)
            ]
            
            let logoSize = logoText.size(withAttributes: logoAttributes)
            let logoRect = CGRect(
                x: (size.width - logoSize.width) / 2,
                y: size.height - 80,
                width: logoSize.width,
                height: logoSize.height
            )
            logoText.draw(in: logoRect, withAttributes: logoAttributes)
            }
        }.value
    }
    
    // MARK: - Create Achievement Image (Legacy - для обратной совместимости)
    
    private func createAchievementImage(_ achievement: Achievement) -> UIImage? {
        // Размер изображения для sharing
        let size = CGSize(width: 800, height: 420) // Оптимизированный размер
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Фон с градиентом
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 1.0).cgColor,
                    UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0).cgColor
                ] as CFArray,
                locations: [0.0, 1.0]
            )!
            
            cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
            
            // Медаль в центре
            let medalSize: CGFloat = 140
            let medalRect = CGRect(
                x: (size.width - medalSize) / 2,
                y: 100,
                width: medalSize,
                height: medalSize
            )
            
            // Рамка медали
            cgContext.setFillColor(UIColor.systemGray.cgColor)
            cgContext.fillEllipse(in: medalRect)
            
            // Внутренний круг
            let innerRect = medalRect.insetBy(dx: 15, dy: 15)
            cgContext.setFillColor(UIColor.systemBlue.cgColor)
            cgContext.fillEllipse(in: innerRect)
            
            // Текст достижения
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            
            let title = achievement.type.title
            let titleSize = title.size(withAttributes: titleAttributes)
            let titleRect = CGRect(
                x: (size.width - titleSize.width) / 2,
                y: medalRect.maxY + 30,
                width: titleSize.width,
                height: titleSize.height
            )
            title.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Описание
            let descriptionAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
            
            let description = achievement.type.description
            let descriptionSize = description.size(withAttributes: descriptionAttributes)
            let descriptionRect = CGRect(
                x: (size.width - descriptionSize.width) / 2,
                y: titleRect.maxY + 15,
                width: min(descriptionSize.width, size.width - 80),
                height: descriptionSize.height
            )
            description.draw(in: descriptionRect, withAttributes: descriptionAttributes)
            
            // Логотип приложения внизу
            let logoText = "StepCounter"
            let logoAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.6)
            ]
            
            let logoSize = logoText.size(withAttributes: logoAttributes)
            let logoRect = CGRect(
                x: (size.width - logoSize.width) / 2,
                y: size.height - 60,
                width: logoSize.width,
                height: logoSize.height
            )
            logoText.draw(in: logoRect, withAttributes: logoAttributes)
        }
    }
    
    // MARK: - Share Content
    
    private func shareContent(
        text: String,
        image: UIImage? = nil,
        subject: String? = nil
    ) {
        var items: [Any] = [text]
        
        if let image = image {
            items.append(image)
        }
        
        // МАКСИМАЛЬНО БЫСТРЫЙ способ - показываем СРАЗУ без асинхронности
        // Если мы уже на главном потоке, показываем немедленно
        if Thread.isMainThread {
            presentActivityViewControllerImmediate(items: items)
        } else {
            // Если не на главном потоке - переключаемся
            DispatchQueue.main.async { [weak self] in
                self?.presentActivityViewControllerImmediate(items: items)
            }
        }
    }
    
    // Прямая презентация без лишних проверок - МАКСИМАЛЬНО БЫСТРО
    private func presentActivityViewControllerImmediate(items: [Any]) {
        // Проверяем, не идет ли уже презентация
        if isPresenting {
            // Не логируем, чтобы не было спама - просто тихо пропускаем
            return
        }
        
        // Проверяем количество попыток (предотвращаем бесконечные циклы)
        if presentationAttempts >= maxPresentationAttempts {
            // Не логируем, чтобы не было спама - просто тихо пропускаем
            presentationAttempts = 0 // Сбрасываем счетчик
            return
        }
        
        presentationAttempts += 1
        
        // Создаём activity view controller СРАЗУ
        let activityViewController = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // Исключаем некоторые типы sharing
        activityViewController.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList
        ]
        
        // Обработчик завершения (когда пользователь закрывает экран sharing)
        activityViewController.completionWithItemsHandler = { [weak self] _, _, _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.isPresenting = false
            }
        }
        
        // Получаем window scene максимально быстро (без лишних проверок)
        let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
            ?? UIApplication.shared.connectedScenes.first as? UIWindowScene
        
        guard let window = windowScene?.windows.first(where: { $0.isKeyWindow })
            ?? windowScene?.windows.first,
              let rootVC = window.rootViewController else {
            return
        }
        
        // Находим top-most view controller БЕЗ рекурсии (максимум 3 уровня)
        var topVC = rootVC
        
        // Уровень 1: presented
        if let presented = topVC.presentedViewController, presented.view.window != nil {
            topVC = presented
        }
        
        // Уровень 2: navigation или tab bar
        if let nav = topVC as? UINavigationController, let navTop = nav.topViewController {
            topVC = navTop
        } else if let tab = topVC as? UITabBarController, let tabSelected = tab.selectedViewController {
            topVC = tabSelected
        }
        
        // Уровень 3: если есть ещё presented
        if let presented = topVC.presentedViewController, presented.view.window != nil {
            topVC = presented
        }
        
        // Проверяем, не показывается ли уже какой-то view controller
        if topVC.presentedViewController != nil || topVC.isBeingPresented {
            // Не логируем и не пытаемся повторно - просто выходим
            // Это предотвращает спам в логах и бесконечные циклы
            presentationAttempts = 0
            return
        }
        
        // Для iPad нужен popover
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(
                x: topVC.view.bounds.midX,
                y: topVC.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        
        // Показываем с проверкой на главном потоке
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Проверяем, не показывается ли уже что-то
            if topVC.presentedViewController != nil || topVC.isBeingPresented {
                // Не логируем и не пытаемся повторно - просто выходим
                // Это предотвращает спам в логах и бесконечные циклы
                self.presentationAttempts = 0
                return
            }
            
            // Дополнительная проверка перед показом
            guard topVC.presentedViewController == nil, !topVC.isBeingPresented, !self.isPresenting else {
                // Не логируем - просто выходим
                self.presentationAttempts = 0
                return
            }
            
            // Устанавливаем флаг перед показом
            self.isPresenting = true
            
            // Показываем (флаг сбросится через completionWithItemsHandler)
            topVC.present(activityViewController, animated: true)
        }
    }
    
    // MARK: - Present Activity View Controller
    
    private func presentActivityViewController(
        items: [Any],
        from viewController: UIViewController?
    ) {
        guard let viewController = viewController else {
            print("❌ View controller is nil, cannot present UIActivityViewController")
            return
        }
        
        // Создаём activity view controller сразу
        let activityViewController = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // Для iPad нужен popover
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        
        // Исключаем некоторые типы sharing (опционально)
        activityViewController.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList
        ]
        
        // Обработчик завершения (когда пользователь закрывает экран sharing)
        activityViewController.completionWithItemsHandler = { [weak self] _, _, _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.isPresenting = false
                self?.presentationAttempts = 0 // Сбрасываем счетчик попыток
            }
        }
        
        // Показываем с проверкой на главном потоке
        DispatchQueue.main.async {
            // Проверяем, не показывается ли уже что-то
            if viewController.view.window != nil {
                if viewController.presentedViewController == nil && !viewController.isBeingPresented {
                    viewController.present(activityViewController, animated: true)
                } else {
                    // Если занят, пытаемся найти другой view controller
                    if let topVC = self.getTopViewController(),
                       topVC.presentedViewController == nil,
                       !topVC.isBeingPresented {
                        topVC.present(activityViewController, animated: true)
                    } else {
                        Logger.shared.logWarning("Не удалось показать sharing: все view controllers заняты")
                    }
                }
            } else {
                // Fallback: пытаемся найти другой view controller
                if let topVC = self.getTopViewController(),
                   topVC.presentedViewController == nil,
                   !topVC.isBeingPresented {
                    topVC.present(activityViewController, animated: true)
                } else {
                    Logger.shared.logWarning("Не удалось показать sharing: view controller не найден или занят")
                }
            }
        }
    }
    
    // MARK: - Get Top View Controller
    
    private func getTopViewController() -> UIViewController? {
        // Получаем активную window scene
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            // Fallback: берем первую доступную window из всех сцен
            guard let fallbackWindowScene = UIApplication.shared.connectedScenes
                .first(where: { $0 is UIWindowScene }) as? UIWindowScene,
                let window = fallbackWindowScene.windows.first else {
                return nil
            }
            return getTopViewController(from: window.rootViewController)
        }
        
        return getTopViewController(from: window.rootViewController)
    }
    
    private func getTopViewController(from viewController: UIViewController?) -> UIViewController? {
        guard let viewController = viewController else { return nil }
        
        // Проверяем, что view controller действительно в иерархии окон
        guard viewController.view.window != nil || viewController.presentedViewController != nil else {
            return nil
        }
        
        // Если есть presented view controller, идём по нему (это может быть sheet или другой модальный view)
        if let presented = viewController.presentedViewController {
            // Проверяем, что presented view controller тоже в иерархии
            if presented.view.window != nil {
                return getTopViewController(from: presented)
            }
        }
        
        // Если это navigation controller, берём top
        if let navController = viewController as? UINavigationController {
            return getTopViewController(from: navController.topViewController)
        }
        
        // Если это tab bar controller, берём selected
        if let tabController = viewController as? UITabBarController {
            return getTopViewController(from: tabController.selectedViewController)
        }
        
        // Если это UIHostingController (SwiftUI), возвращаем его
        // Проверяем через reflection, так как тип может быть разным
        let className = String(describing: type(of: viewController))
        if className.contains("UIHostingController") || className.contains("PresentationHostingController") {
            // Проверяем, что view действительно в иерархии
            if viewController.view.window != nil {
                return viewController
            }
        }
        
        // Иначе возвращаем сам view controller, если он в иерархии
        return viewController.view.window != nil ? viewController : nil
    }
    
    // MARK: - Share Text
    
    func shareText(_ text: String) {
        shareContent(text: text)
    }
    
    // MARK: - Share Progress
    
    func shareDailyProgress(steps: Int, goal: Int, distance: Double, calories: Int) {
        let progress = Double(steps) / Double(goal) * 100
        let emoji = progress >= 100 ? "🎉" : "💪"
        
        let shareText = """
        \(emoji) Мой прогресс сегодня в StepCounter:
        
        👣 \(steps) шагов (\(String(format: "%.0f", progress))%)
        🏃 \(String(format: "%.1f", distance)) км
        🔥 \(calories) калорий
        
        Скачай StepCounter и начни свой путь к здоровью!
        """
        
        shareContent(text: shareText)
    }
}

// MARK: - Share Button View

struct ShareButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.impact(style: .light)
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(.appCaption)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
    }
}
