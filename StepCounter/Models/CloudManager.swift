//
//  CloudManager.swift
//  StepCounter
//
//  Заглушка для CloudManager (Firebase отключен)
//

import Foundation

/// Менеджер облачной синхронизации (заглушка)
final class CloudManager: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var friends: [UserProfile] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var friendsSteps: [String: DailyStepRecord] = [:]
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Пустая реализация - Firebase не подключен
    func syncSteps(steps: Int, distance: Double, calories: Double) async {}
    func fetchFriendsStepsToday() async {}
}
