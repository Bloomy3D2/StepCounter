//
//  LocationChallengeManager.swift
//  StepCounter
//
//  Менеджер локационных вызовов
//

import Foundation
import CoreLocation
import Combine
import SwiftUI

/// Менеджер локационных вызовов
final class LocationChallengeManager: ObservableObject {
    
    @Published var activeChallenges: [LocationChallenge] = []
    @Published var completedChallenges: [LocationChallenge] = []
    @Published var availableChallenges: [LocationChallenge] = []
    @Published var newlyCompleted: LocationChallenge?
    
    private let storage = StorageManager.shared
    private let activeKey = "activeLocationChallenges"
    private let completedKey = "completedLocationChallenges"
    private let availableKey = "availableLocationChallenges"
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadChallenges()
        generateDefaultChallenges()
    }
    
    // MARK: - Persistence
    
    private func loadChallenges() {
        if let saved: [LocationChallenge] = storage.loadSafe([LocationChallenge].self, forKey: activeKey) {
            activeChallenges = saved
        }
        
        if let saved: [LocationChallenge] = storage.loadSafe([LocationChallenge].self, forKey: completedKey) {
            completedChallenges = saved
        }
        
        if let saved: [LocationChallenge] = storage.loadSafe([LocationChallenge].self, forKey: availableKey) {
            availableChallenges = saved
        }
        
        checkExpiredChallenges()
    }
    
    private func saveChallenges() {
        do {
            try storage.save(activeChallenges, forKey: activeKey)
            try storage.save(completedChallenges, forKey: completedKey)
            try storage.save(availableChallenges, forKey: availableKey)
        } catch {
            Logger.shared.logStorageError(error, key: activeKey)
        }
    }
    
    // MARK: - Challenge Management
    
    /// Создать новый локационный вызов
    func createChallenge(_ challenge: LocationChallenge) {
        activeChallenges.append(challenge)
        saveChallenges()
    }
    
    /// Удалить вызов
    func deleteChallenge(_ challenge: LocationChallenge) {
        activeChallenges.removeAll { $0.id == challenge.id }
        saveChallenges()
    }
    
    /// Начать вызов из доступных
    func startChallenge(_ challenge: LocationChallenge) {
        guard !activeChallenges.contains(where: { $0.id == challenge.id }) else { return }
        activeChallenges.append(challenge)
        availableChallenges.removeAll { $0.id == challenge.id }
        saveChallenges()
    }
    
    // MARK: - Progress Update
    
    /// Обновить прогресс вызова на основе локации и данных
    func updateProgress(
        userLocation: CLLocation,
        steps: Int,
        distance: Double,
        speed: Double
    ) {
        for i in activeChallenges.indices {
            var challenge = activeChallenges[i]
            
            // Проверяем, находится ли пользователь в радиусе локации
            let isInLocation = challenge.isUserInLocation(userLocation)
            
            // Обновляем прогресс только если пользователь в локации
            if isInLocation {
                var progress = challenge.currentProgress
                
                switch challenge.type {
                case .stepsAtLocation:
                    progress.steps = max(progress.steps, steps)
                    
                case .distanceAtLocation:
                    progress.distance = max(progress.distance, distance)
                    
                case .speedRecord:
                    progress.maxSpeed = max(progress.maxSpeed, speed)
                    
                case .visitLocation:
                    // Засчитываем визит, если прошло больше часа с последнего
                    if let lastVisit = progress.lastVisitDate {
                        let hoursSinceLastVisit = Date().timeIntervalSince(lastVisit) / 3600
                        if hoursSinceLastVisit >= 1 {
                            progress.visits += 1
                            progress.lastVisitDate = Date()
                        }
                    } else {
                        progress.visits = 1
                        progress.lastVisitDate = Date()
                    }
                    
                case .routeChallenge:
                    // Для маршрутных вызовов нужна отдельная логика проверки точек
                    break
                }
                
                challenge.currentProgress = progress
                
                // Проверяем выполнение
                if checkCompletion(challenge) && !challenge.isCompleted {
                    challenge.isCompleted = true
                    challenge.completedDate = Date()
                    newlyCompleted = challenge
                    
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
            
            activeChallenges[i] = challenge
        }
        
        // Перемещаем выполненные
        let completed = activeChallenges.filter { $0.isCompleted }
        completedChallenges.append(contentsOf: completed)
        activeChallenges.removeAll { $0.isCompleted }
        
        saveChallenges()
    }
    
    /// Проверка выполнения вызова
    private func checkCompletion(_ challenge: LocationChallenge) -> Bool {
        let progress = challenge.currentProgress
        
        switch challenge.type {
        case .stepsAtLocation:
            if let target = challenge.targetSteps {
                return progress.steps >= target
            }
            
        case .distanceAtLocation:
            if let target = challenge.targetDistance {
                return progress.distance >= target
            }
            
        case .visitLocation:
            if let target = challenge.targetVisits {
                return progress.visits >= target
            }
            
        case .speedRecord:
            if let target = challenge.targetSpeed {
                return progress.maxSpeed >= target
            }
            
        case .routeChallenge:
            if let target = challenge.targetVisits {
                return progress.visits >= target
            }
        }
        
        return false
    }
    
    private func checkExpiredChallenges() {
        let expired = activeChallenges.filter { $0.isExpired }
        completedChallenges.append(contentsOf: expired)
        activeChallenges.removeAll { $0.isExpired }
        saveChallenges()
    }
    
    // MARK: - Default Challenges
    
    /// Генерация дефолтных локационных вызовов
    private func generateDefaultChallenges() {
        guard availableChallenges.isEmpty else { return }
        
        // Примеры локаций (можно получить из текущей локации пользователя)
        // Для демонстрации используем примеры координат Москвы
        let moscowLocation = ChallengeLocation(
            name: "Центральный парк",
            latitude: 55.7558,
            longitude: 37.6173,
            address: "Центральный парк",
            city: "Москва",
            description: "Пройдите вызов в центральном парке города"
        )
        
        let challenge1 = LocationChallenge(
            type: .stepsAtLocation,
            title: "10,000 шагов в парке",
            description: "Пройдите 10,000 шагов в Центральном парке",
            location: moscowLocation,
            radius: 1000, // 1 км
            targetSteps: 10000,
            durationDays: 7,
            rewardAchievement: .first10KSteps
        )
        
        let challenge2 = LocationChallenge(
            type: .distanceAtLocation,
            title: "5 км по набережной",
            description: "Пройдите 5 километров вдоль набережной",
            location: moscowLocation,
            radius: 500,
            targetDistance: 5000,
            durationDays: 14
        )
        
        let challenge3 = LocationChallenge(
            type: .visitLocation,
            title: "Исследователь",
            description: "Посетите 10 различных локаций в вашем городе",
            location: moscowLocation,
            radius: 10000, // 10 км
            targetVisits: 10,
            durationDays: 30
        )
        
        availableChallenges = [challenge1, challenge2, challenge3]
        saveChallenges()
    }
    
    // MARK: - Stats
    
    var totalCompleted: Int {
        completedChallenges.filter { $0.isCompleted }.count
    }
    
    var activeCount: Int {
        activeChallenges.count
    }
    
    var completionRate: Double {
        let total = completedChallenges.count + activeChallenges.count
        guard total > 0 else { return 0 }
        return Double(totalCompleted) / Double(total)
    }
    
    /// Получить ближайший активный вызов
    func nearestActiveChallenge(from location: CLLocation) -> LocationChallenge? {
        let sorted = activeChallenges.sorted { challenge1, challenge2 in
            let loc1 = challenge1.location.clLocation
            let loc2 = challenge2.location.clLocation
            return location.distance(from: loc1) < location.distance(from: loc2)
        }
        return sorted.first
    }
    
    /// Расстояние до ближайшего вызова
    func distanceToNearestChallenge(from location: CLLocation) -> Double? {
        guard let nearest = nearestActiveChallenge(from: location) else { return nil }
        return location.distance(from: nearest.location.clLocation)
    }
}
