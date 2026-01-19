//
//  LocationManager.swift
//  StepCounter
//
//  GPS-трекинг маршрутов
//

import Foundation
import CoreLocation
import MapKit

/// Точка маршрута
struct RoutePoint: Codable, Identifiable, Equatable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(location: CLLocation) {
        self.id = UUID()
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.timestamp = location.timestamp
    }
}

/// Записанный маршрут
struct RecordedRoute: Codable, Identifiable, Equatable {
    let id: UUID
    let startDate: Date
    var endDate: Date?
    var points: [RoutePoint]
    var distance: Double // метры
    var duration: TimeInterval // секунды
    
    init() {
        self.id = UUID()
        self.startDate = Date()
        self.endDate = nil
        self.points = []
        self.distance = 0
        self.duration = 0
    }
    
    var distanceKm: Double {
        distance / 1000
    }
    
    var averageSpeed: Double {
        guard duration > 0 else { return 0 }
        return (distance / 1000) / (duration / 3600) // км/ч
    }
    
    /// Текущая длительность (для активного маршрута вычисляется, для завершенного - из duration)
    var currentDuration: TimeInterval {
        if endDate == nil {
            // Маршрут активен, вычисляем длительность от начала до сейчас
            return Date().timeIntervalSince(startDate)
        } else {
            // Маршрут завершен, используем сохраненную длительность
            return duration
        }
    }
    
    var formattedDuration: String {
        let durationToFormat = endDate == nil ? currentDuration : duration
        let hours = Int(durationToFormat) / 3600
        let minutes = (Int(durationToFormat) % 3600) / 60
        let seconds = Int(durationToFormat) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var currentAverageSpeed: Double {
        let durationToUse = endDate == nil ? currentDuration : duration
        guard durationToUse > 0 else { return 0 }
        return (distance / 1000) / (durationToUse / 3600) // км/ч
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM, HH:mm"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: startDate)
    }
}

/// Менеджер GPS-трекинга
@MainActor
final class LocationManager: NSObject, ObservableObject {
    
    @Published var isTracking: Bool = false
    @Published var currentRoute: RecordedRoute?
    @Published var savedRoutes: [RecordedRoute] = []
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var trackingStartTime: Date?
    
    private let routesKey = "savedRoutes"
    
    override init() {
        super.init()
        locationManager.delegate = self
        // Максимальная точность для карты
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone // Обновление при любом движении
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.pausesLocationUpdatesAutomatically = false
        // Указываем, что это пешая прогулка для лучшей точности
        if #available(iOS 12.0, *) {
            locationManager.activityType = .fitness
        }
        
        Task { @MainActor in
            loadRoutes()
        }
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    // MARK: - Tracking
    
    @MainActor
    func startTracking() {
        // Проверяем согласие на обработку персональных данных
        guard PrivacyConsentManager.shared.hasConsent else {
            Logger.shared.logWarning("Попытка начать трекинг без согласия на обработку ПДн")
            return
        }
        
        guard isAuthorized else {
            requestAuthorization()
            return
        }
        
        // МАКСИМАЛЬНАЯ ТОЧНОСТЬ для точного трекинга по дорогам
        // kCLLocationAccuracyBestForNavigation - самая высокая точность (использует GPS + дополнительные датчики)
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        // kCLDistanceFilterNone - обновление при ЛЮБОМ движении (для максимальной детализации)
        locationManager.distanceFilter = kCLDistanceFilterNone
        
        // Указываем тип активности для оптимизации
        if #available(iOS 12.0, *) {
            locationManager.activityType = .fitness // Пешая прогулка
        }
        
        currentRoute = RecordedRoute()
        lastLocation = nil
        trackingStartTime = Date()
        isTracking = true
        
        Logger.shared.logInfo("Начало записи маршрута")
        
        // Запускаем обновление локации
        locationManager.startUpdatingLocation()
        
        // Также запрашиваем текущую локацию для немедленного обновления
        locationManager.requestLocation()
        
        // Дополнительно запрашиваем локацию через небольшую задержку для надежности
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 секунда
            if self.isTracking {
                self.locationManager.requestLocation()
            }
        }
    }
    
    @MainActor
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        isTracking = false
        
        // Возвращаем настройки для обычного режима (не трекинг)
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        
        if var route = currentRoute {
            route.endDate = Date()
            let actualDuration = Date().timeIntervalSince(trackingStartTime ?? route.startDate)
            route.duration = actualDuration
            
            Logger.shared.logInfo("Остановка маршрута: точек=\(route.points.count), дистанция=\(String(format: "%.2f", route.distance))м, время=\(String(format: "%.0f", actualDuration))с")
            
            // Сохраняем маршруты с более мягкими условиями:
            // - минимум 1 точка (даже если пользователь стоял на месте)
            // - или минимум 2 точки и любая дистанция (даже 0 метров, если GPS неточный)
            if route.points.count >= 1 {
                // Проверяем Premium для неограниченного количества маршрутов
                let subscriptionManager = SubscriptionManager.shared
                let hasUnlimitedRoutes = subscriptionManager.hasAccess(to: .unlimitedRoutes)
            
                // Для free пользователей: максимум 5 маршрутов
                let maxRoutesForFree = 5
                if !hasUnlimitedRoutes && savedRoutes.count >= maxRoutesForFree {
                    // Удаляем самый старый маршрут
                    if savedRoutes.count > 0 {
                        savedRoutes.removeLast()
                    }
                }
                
                savedRoutes.insert(route, at: 0)
                saveRoutes()
                Logger.shared.logInfo("Маршрут сохранен: \(route.points.count) точек, \(String(format: "%.2f", route.distance))м")
            } else {
                Logger.shared.logWarning("Маршрут не сохранен: недостаточно точек (\(route.points.count))")
            }
        }
        
        currentRoute = nil
        lastLocation = nil
    }
    
    func pauseTracking() {
        locationManager.stopUpdatingLocation()
    }
    
    func resumeTracking() {
        locationManager.startUpdatingLocation()
    }
    
    /// Запросить однократное обновление местоположения (для показа на карте)
    func requestCurrentLocation() {
        // Проверяем согласие на обработку персональных данных
        guard PrivacyConsentManager.shared.hasConsent else {
            Logger.shared.logWarning("Попытка получить геолокацию без согласия на обработку ПДн")
            return
        }
        
        guard isAuthorized else {
            requestAuthorization()
            return
        }
        
        // Запускаем однократное обновление
        locationManager.requestLocation()
        
        // Если трекинг не активен, запускаем периодическое обновление для карты
        if !isTracking {
            locationManager.startUpdatingLocation()
            // Останавливаем через 5 секунд, если трекинг не начался
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                if self?.isTracking == false {
                    self?.locationManager.stopUpdatingLocation()
                }
            }
        }
    }
    
    // MARK: - Route Management
    
    @MainActor
    func deleteRoute(_ route: RecordedRoute) {
        savedRoutes.removeAll { $0.id == route.id }
        saveRoutes()
    }
    
    @MainActor
    func deleteAllRoutes() {
        savedRoutes.removeAll()
        saveRoutes()
    }
    
    // MARK: - Persistence
    
    @MainActor
    private func loadRoutes() {
        if let data = UserDefaults.standard.data(forKey: routesKey),
           let routes = try? JSONDecoder().decode([RecordedRoute].self, from: data) {
            // Проверяем Premium для неограниченного количества маршрутов
            let subscriptionManager = SubscriptionManager.shared
            let hasUnlimitedRoutes = subscriptionManager.hasAccess(to: .unlimitedRoutes)
            
            if hasUnlimitedRoutes {
                savedRoutes = routes
            } else {
                // Для free пользователей: максимум 5 маршрутов
                savedRoutes = Array(routes.prefix(5))
            }
        }
    }
    
    @MainActor
    private func saveRoutes() {
        // Проверяем Premium для неограниченного количества маршрутов
        let subscriptionManager = SubscriptionManager.shared
        let hasUnlimitedRoutes = subscriptionManager.hasAccess(to: .unlimitedRoutes)
        
        let maxRoutes: Int
        if hasUnlimitedRoutes {
            maxRoutes = 1000 // Практически неограниченно
        } else {
            maxRoutes = 5 // Для free пользователей
            // Ограничиваем количество маршрутов для free
            if savedRoutes.count > maxRoutes {
                savedRoutes = Array(savedRoutes.prefix(maxRoutes))
            }
        }
        
        let routesToSave = Array(savedRoutes.prefix(maxRoutes))
        if let data = try? JSONEncoder().encode(routesToSave) {
            UserDefaults.standard.set(data, forKey: routesKey)
        }
    }
    
    // MARK: - Stats
    
    var totalDistance: Double {
        savedRoutes.reduce(0) { $0 + $1.distance }
    }
    
    var totalDuration: TimeInterval {
        savedRoutes.reduce(0) { $0 + $1.duration }
    }
    
    var routesThisWeek: [RecordedRoute] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return savedRoutes.filter { $0.startDate > weekAgo }
    }
    
    var routesThisMonth: [RecordedRoute] {
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return savedRoutes.filter { $0.startDate > monthAgo }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Обрабатываем ВСЕ полученные локации для максимальной точности
        guard !locations.isEmpty else { return }
        
        // Обновляем на главном потоке, так как это @Published свойства
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // Берем последнюю (самую свежую) локацию для отображения на карте
            guard let location = locations.last else { return }
            
            // Всегда обновляем текущее местоположение (для карты и питомца)
            self.currentLocation = location
            
            // Если идёт трекинг, обрабатываем точки для маршрута
            guard self.isTracking, var route = self.currentRoute else { return }
            
            // Для точности используем разумные фильтры:
            // - horizontalAccuracy должна быть положительной (валидная точка)
            // - Допускаем до 100м точности (для работы в помещении и на улице)
            let maxAccuracy: Double = 100.0 // метры
            
            // Обрабатываем ВСЕ полученные локации для максимальной детализации
            for loc in locations {
                // Проверяем каждую точку на валидность
                guard loc.horizontalAccuracy > 0, loc.horizontalAccuracy <= maxAccuracy else {
                    Logger.shared.logWarning("Пропущена точка с точностью: \(loc.horizontalAccuracy)м")
                    continue // Пропускаем неточные точки
                }
                
                // ВАЖНО: Первая точка всегда добавляется
                if self.lastLocation == nil {
                    // Это первая точка маршрута - добавляем обязательно
                    let point = RoutePoint(location: loc)
                    route.points.append(point)
                    self.lastLocation = loc
                    Logger.shared.logInfo("Добавлена первая точка маршрута: \(loc.coordinate.latitude), \(loc.coordinate.longitude)")
                } else {
                    // Для последующих точек считаем дистанцию
                    let last = self.lastLocation!
                    let delta = loc.distance(from: last)
                    let dt = max(0.01, loc.timestamp.timeIntervalSince(last.timestamp))
                    let speedMps = delta / dt
                    
                    // Принимаем перемещения от 1 метра (более мягкий фильтр)
                    // Отсекаем только невозможные скачки (> 15 м/с = 54 км/ч - слишком быстро для ходьбы/бега)
                    if delta >= 1.0 && speedMps <= 15.0 {
                        route.distance += delta
                        let point = RoutePoint(location: loc)
                        route.points.append(point)
                        self.lastLocation = loc
                        Logger.shared.logInfo("Добавлена точка маршрута: дистанция +\(String(format: "%.2f", delta))м, всего: \(String(format: "%.2f", route.distance))м, точек: \(route.points.count)")
                    } else {
                        Logger.shared.logWarning("Пропущена точка: delta=\(String(format: "%.2f", delta))м, speed=\(String(format: "%.2f", speedMps))м/с")
                    }
                }
            }
            
            // Обновляем маршрут
            self.currentRoute = route
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
