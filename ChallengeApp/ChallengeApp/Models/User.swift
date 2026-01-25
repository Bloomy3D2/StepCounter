//
//  User.swift
//  ChallengeApp
//
//  Модель пользователя
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    var name: String
    var email: String?
    var balance: Double
    var authProvider: AuthProvider
    var createdAt: Date
    var honestStreak: Int // Честная серия (количество честных действий подряд)
    var avatarUrl: String? // URL аватарки пользователя
    
    enum AuthProvider: String, Codable {
        case apple
        case google
        case anonymous
        case email
    }
    
    init(id: String = UUID().uuidString, 
         name: String, 
         email: String? = nil, 
         balance: Double = 0.0,
         authProvider: AuthProvider = .anonymous,
         createdAt: Date = Date(),
         honestStreak: Int = 0,
         avatarUrl: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.balance = balance
        self.authProvider = authProvider
        self.createdAt = createdAt
        self.honestStreak = honestStreak
        self.avatarUrl = avatarUrl
    }
}
