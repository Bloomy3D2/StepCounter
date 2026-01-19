//
//  NotificationManager.swift
//  StepCounter
//
//  Умные уведомления
//

import Foundation
import UserNotifications

/// Менеджер уведомлений
@MainActor
final class NotificationManager: ObservableObject {
    
    static let shared = NotificationManager()
    
    @Published var isAuthorized: Bool = false
    @Published var notificationsEnabled: Bool {
        didSet {
            StorageManager.shared.saveBool(notificationsEnabled, forKey: "notificationsEnabled")
            if notificationsEnabled {
                requestAuthorization()
            } else {
                removeAllNotifications()
            }
        }
    }
    
    @Published var goalReminderEnabled: Bool {
        didSet {
            StorageManager.shared.saveBool(goalReminderEnabled, forKey: "goalReminderEnabled")
            scheduleGoalReminder()
        }
    }
    
    @Published var inactivityReminderEnabled: Bool {
        didSet {
            StorageManager.shared.saveBool(inactivityReminderEnabled, forKey: "inactivityReminderEnabled")
        }
    }
    
    private init() {
        let storage = StorageManager.shared
        notificationsEnabled = storage.loadBool(forKey: "notificationsEnabled")
        goalReminderEnabled = storage.loadBool(forKey: "goalReminderEnabled")
        inactivityReminderEnabled = storage.loadBool(forKey: "inactivityReminderEnabled")
        checkAuthorization()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if granted {
                    self?.scheduleGoalReminder()
                }
            }
        }
    }
    
    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Schedule Notifications
    
    /// Напоминание о цели вечером
    func scheduleGoalReminder() {
        guard goalReminderEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Как дела с шагами? 🚶"
        content.body = "Проверьте, сколько осталось до цели сегодня!"
        content.sound = .default
        
        // Каждый день в 20:00
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "goalReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Уведомление о достижении цели
    func sendGoalReachedNotification() {
        guard notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🎉 Цель достигнута!"
        content.body = "Отличная работа! Вы выполнили свою цель по шагам сегодня!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "goalReached-\(Date())", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Уведомление о почти достигнутой цели
    func sendAlmostThereNotification(remaining: Int) {
        guard notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Почти у цели! 💪"
        content.body = "Осталось всего \(remaining) шагов. Вы справитесь!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "almostThere-\(Date())", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Уведомление о новом достижении
    func sendAchievementNotification(title: String) {
        guard notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🏆 Новое достижение!"
        content.body = "Вы разблокировали: \(title)"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "achievement-\(Date())", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Мотивационное уведомление
    func sendMotivationalNotification() {
        guard notificationsEnabled else { return }
        
        let messages = [
            ("Время прогуляться! 🚶", "Небольшая прогулка поднимет настроение и добавит шагов."),
            ("Как насчёт прогулки? 🌤️", "Свежий воздух и движение — залог здоровья!"),
            ("Вы сегодня двигались? 💪", "Даже 10 минут ходьбы приносят пользу."),
            ("Пора размяться! 🏃", "Встаньте и пройдитесь — ваше тело скажет спасибо.")
        ]
        
        let message = messages.randomElement()!
        
        let content = UNMutableNotificationContent()
        content.title = message.0
        content.body = message.1
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "motivational-\(Date())", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Remove Notifications
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
