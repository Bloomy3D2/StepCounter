//
//  UserModel.swift
//  StepCounter
//
//  Модели пользователя и данных шагов
//

import Foundation

/// Профиль пользователя
struct UserProfile: Codable, Identifiable {
    var id: String
    var email: String
    var displayName: String
    var avatarEmoji: String
    var stepGoal: Int
    var createdAt: Date
    var friendIds: [String]
    var pendingFriendRequests: [String]  // ID пользователей, которые хотят добавить в друзья
    
    static let placeholder = UserProfile(
        id: "",
        email: "",
        displayName: "Пользователь",
        avatarEmoji: "🚶",
        stepGoal: 10000,
        createdAt: Date(),
        friendIds: [],
        pendingFriendRequests: []
    )
}

/// Данные шагов за день
struct DailyStepRecord: Codable, Identifiable {
    var id: String { "\(userId)_\(dateString)" }
    let userId: String
    let dateString: String  // "2026-01-18"
    var steps: Int
    var distance: Double  // метры
    var calories: Double
    var updatedAt: Date
    
    var date: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString) ?? Date()
    }
}

/// Запись в лидерборде
struct LeaderboardEntry: Identifiable {
    let id: String
    let userId: String
    let displayName: String
    let avatarEmoji: String
    let steps: Int
    var rank: Int
    
    var isTopThree: Bool {
        rank <= 3
    }
}

/// Запрос в друзья
struct FriendRequest: Identifiable {
    let id: String
    let fromUserId: String
    let fromDisplayName: String
    let fromAvatarEmoji: String
    let sentAt: Date
}

/// Период для статистики
enum StatsPeriod: String, CaseIterable {
    case today = "Сегодня"
    case week = "Неделя"
    case month = "Месяц"
    
    var days: Int {
        switch self {
        case .today: return 1
        case .week: return 7
        case .month: return 30
        }
    }
}
