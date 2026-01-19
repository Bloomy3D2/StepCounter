//
//  LocationChallenge.swift
//  StepCounter
//
//  Локационные вызовы - гео-вызовы с AR-визуализацией
//

import Foundation
import SwiftUI
import CoreLocation
import MapKit

// MARK: - Тип локационного вызова

enum LocationChallengeType: String, Codable, CaseIterable {
    case stepsAtLocation      // "Пройдите 10,000 шагов в Центральном парке"
    case distanceAtLocation   // "Пройдите 5 км в парке Горького"
    case visitLocation        // "Посетите 10 скрытых локаций в вашем городе"
    case speedRecord          // "Установите рекорд скорости на набережной"
    case routeChallenge       // "Пройдите маршрут по историческим местам"
    
    var title: String {
        switch self {
        case .stepsAtLocation: return "Шаги в локации"
        case .distanceAtLocation: return "Дистанция в локации"
        case .visitLocation: return "Посещение локаций"
        case .speedRecord: return "Рекорд скорости"
        case .routeChallenge: return "Маршрутный вызов"
        }
    }
    
    var icon: String {
        switch self {
        case .stepsAtLocation: return "figure.walk"
        case .distanceAtLocation: return "map.fill"
        case .visitLocation: return "location.fill"
        case .speedRecord: return "speedometer"
        case .routeChallenge: return "route"
        }
    }
    
    var color: Color {
        switch self {
        case .stepsAtLocation: return .green
        case .distanceAtLocation: return .blue
        case .visitLocation: return .purple
        case .speedRecord: return .orange
        case .routeChallenge: return .cyan
        }
    }
}

// MARK: - Локационный вызов

struct LocationChallenge: Identifiable, Codable {
    let id: UUID
    let type: LocationChallengeType
    let title: String
    let description: String
    
    // Геолокация
    let location: ChallengeLocation
    let radius: Double // радиус в метрах
    
    // Цели
    let targetSteps: Int?
    let targetDistance: Double? // в метрах
    let targetSpeed: Double? // в км/ч
    let targetVisits: Int?
    
    // Временные рамки
    let startDate: Date
    let endDate: Date?
    
    // Прогресс
    var currentProgress: LocationChallengeProgress
    var isCompleted: Bool
    var completedDate: Date?
    
    // Достижение за выполнение
    var rewardAchievement: AchievementType?
    
    init(
        type: LocationChallengeType,
        title: String,
        description: String,
        location: ChallengeLocation,
        radius: Double = 500, // 500 метров по умолчанию
        targetSteps: Int? = nil,
        targetDistance: Double? = nil,
        targetSpeed: Double? = nil,
        targetVisits: Int? = nil,
        durationDays: Int? = nil,
        rewardAchievement: AchievementType? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.description = description
        self.location = location
        self.radius = radius
        self.targetSteps = targetSteps
        self.targetDistance = targetDistance
        self.targetSpeed = targetSpeed
        self.targetVisits = targetVisits
        
        self.startDate = Date()
        if let days = durationDays {
            self.endDate = Calendar.current.date(byAdding: .day, value: days, to: Date())
        } else {
            self.endDate = nil // Без ограничения по времени
        }
        
        self.currentProgress = LocationChallengeProgress()
        self.isCompleted = false
        self.completedDate = nil
        self.rewardAchievement = rewardAchievement
    }
    
    var progressPercent: Double {
        switch type {
        case .stepsAtLocation:
            guard let target = targetSteps, target > 0 else { return 0 }
            return min(1.0, Double(currentProgress.steps) / Double(target))
            
        case .distanceAtLocation:
            guard let target = targetDistance, target > 0 else { return 0 }
            return min(1.0, currentProgress.distance / target)
            
        case .visitLocation:
            guard let target = targetVisits, target > 0 else { return 0 }
            return min(1.0, Double(currentProgress.visits) / Double(target))
            
        case .speedRecord:
            guard let target = targetSpeed, target > 0 else { return 0 }
            return min(1.0, currentProgress.maxSpeed / target)
            
        case .routeChallenge:
            // Для маршрутного вызова прогресс = процент посещенных точек
            guard let target = targetVisits, target > 0 else { return 0 }
            return min(1.0, Double(currentProgress.visits) / Double(target))
        }
    }
    
    var daysRemaining: Int? {
        guard let endDate = endDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, days)
    }
    
    var isExpired: Bool {
        guard let endDate = endDate else { return false }
        return Date() > endDate && !isCompleted
    }
    
    var isActive: Bool {
        !isCompleted && !isExpired
    }
    
    var statusText: String {
        if isCompleted {
            return "✅ Выполнено"
        } else if isExpired {
            return "❌ Не выполнено"
        } else if let days = daysRemaining, days == 0 {
            return "⏰ Последний день"
        } else if let days = daysRemaining {
            return "📅 Осталось \(days) дн."
        } else {
            return "🎯 Активно"
        }
    }
    
    /// Проверяет, находится ли пользователь в радиусе локации
    func isUserInLocation(_ userLocation: CLLocation) -> Bool {
        let challengeLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let distance = userLocation.distance(from: challengeLocation)
        return distance <= radius
    }
}

// MARK: - Локация вызова

struct ChallengeLocation: Codable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let address: String?
    let city: String?
    let description: String?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var clLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    init(
        id: String = UUID().uuidString,
        name: String,
        latitude: Double,
        longitude: Double,
        address: String? = nil,
        city: String? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.city = city
        self.description = description
    }
}

// MARK: - Прогресс локационного вызова

struct LocationChallengeProgress: Codable {
    var steps: Int = 0
    var distance: Double = 0 // в метрах
    var maxSpeed: Double = 0 // в км/ч
    var visits: Int = 0
    var lastVisitDate: Date?
    var routePoints: [ChallengeRoutePoint] = []
    
    init() {}
}

// MARK: - Точка маршрута для вызова

struct ChallengeRoutePoint: Codable, Identifiable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let visited: Bool
    
    init(location: CLLocation, visited: Bool = false) {
        self.id = UUID()
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.timestamp = location.timestamp
        self.visited = visited
    }
}

// MARK: - Расширение Color для hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
