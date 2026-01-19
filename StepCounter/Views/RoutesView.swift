//
//  RoutesView.swift
//  StepCounter
//
//  Экран маршрутов (заменяет путешествия)
//

import SwiftUI
import MapKit

struct RoutesView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var petManager: PetManager
    
    @State private var selectedRoute: RecordedRoute?
    @State private var showMapView = false
    @State private var showDeleteAlert = false
    @State private var routeToDelete: RecordedRoute?
    @State private var showPrivacyConsentAlert = false
    
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var consentManager = PrivacyConsentManager.shared
    
    private var bgColor: Color { themeManager.backgroundColor }
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Кнопка начала нового маршрута
                    if !locationManager.isTracking {
                        startRouteButton
                    } else {
                        currentRouteCard
                    }
                    
                    // Список сохранённых маршрутов
                    if !locationManager.savedRoutes.isEmpty {
                        savedRoutesSection
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 80)
            }
            .background(
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .ignoresSafeArea()
            )
            .navigationTitle("Маршруты")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: $showMapView) {
                NavigationStack {
                    if let route = selectedRoute {
                        RouteDetailView(route: route)
                            .environmentObject(locationManager)
                            .environmentObject(petManager)
                    } else {
                        RouteMapView()
                            .environmentObject(locationManager)
                            .environmentObject(petManager)
                    }
                }
            }
            .alert("Удалить маршрут?", isPresented: $showDeleteAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Удалить", role: .destructive) {
                    if let route = routeToDelete {
                        locationManager.deleteRoute(route)
                    }
                }
            } message: {
                Text("Это действие нельзя отменить")
            }
            .alert("Требуется согласие", isPresented: $showPrivacyConsentAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Перейти в настройки") {
                    // Можно добавить навигацию к настройкам
                }
            } message: {
                Text("Для записи GPS-маршрутов необходимо дать согласие на обработку персональных данных. Вы можете сделать это в настройках приложения.")
            }
        }
    }
    
    // MARK: - Start Route Button
    
    private var startRouteButton: some View {
        VStack(spacing: 12) {
            // Предупреждение о необходимости согласия
            if !consentManager.hasConsent {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Требуется согласие на обработку данных")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Для записи маршрутов необходимо дать согласие в настройках")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                        )
                )
            }
            
            Button {
                if !consentManager.hasConsent {
                    showPrivacyConsentAlert = true
                    HapticManager.notification(.warning)
                } else {
                    locationManager.startTracking()
                    showMapView = true // Открываем карту сразу при старте
                }
            } label: {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 24))
                    Text("Начать новый маршрут")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(consentManager.hasConsent ? accentGreen : Color.gray.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(!consentManager.hasConsent)
            
            // Кнопка открытия карты (если есть сохранённые маршруты)
            if !locationManager.savedRoutes.isEmpty {
                Button {
                    showMapView = true
                } label: {
                    HStack {
                        Image(systemName: "map.fill")
                            .font(.system(size: 20))
                        Text("Открыть карту")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(cardColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(accentGreen.opacity(0.5), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
    
    // MARK: - Current Route Card
    
    private var currentRouteCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Текущий маршрут")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    locationManager.stopTracking()
                } label: {
                    Text("Завершить")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
            }
            
            if let route = locationManager.currentRoute {
                RouteStatsView(route: route, isActive: true)
                
                // Кнопка открытия карты
                Button {
                    showMapView = true
                } label: {
                    HStack {
                        Image(systemName: "map.fill")
                            .font(.system(size: 18))
                        Text("Открыть карту")
                            .font(.system(size: 15, weight: .medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(cardColor))
    }
    
    // MARK: - Saved Routes Section
    
    private var savedRoutesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Сохранённые маршруты")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            ForEach(locationManager.savedRoutes) { route in
                RouteCard(route: route) {
                    selectedRoute = route
                    showMapView = true
                } onDelete: {
                    routeToDelete = route
                    showDeleteAlert = true
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "map.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Нет сохранённых маршрутов")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Начните новый маршрут, чтобы отслеживать свои прогулки")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
}

// MARK: - Route Card

struct RouteCard: View {
    let route: RecordedRoute
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @StateObject private var themeManager = ThemeManager.shared
    
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Заголовок с датой
                HStack {
                    Text(route.dateString)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.red.opacity(0.7))
                    }
                }
                
                // Статистика
                RouteStatsView(route: route, isActive: false)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(cardColor))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Route Stats View

struct RouteStatsView: View {
    let route: RecordedRoute
    let isActive: Bool
    
    @StateObject private var themeManager = ThemeManager.shared
    @State private var currentTime: TimeInterval = 0
    @State private var updateTimer: Timer?
    
    private var accentGreen: Color { themeManager.accentGreen }
    
    var body: some View {
        HStack(spacing: 20) {
            // Дистанция
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "map")
                        .font(.system(size: 12))
                        .foregroundColor(accentGreen)
                    Text(String(format: "%.2f км", route.distanceKm))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                Text("Дистанция")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Время
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    Text(formatDuration(isActive ? currentTime : route.duration))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                Text("Время")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Скорость
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Text(formatPace())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                Text("Темп")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
        .onAppear {
            if isActive {
                startTimer()
            }
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        stopTimer()
        currentTime = route.currentDuration
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = route.currentDuration
        }
    }
    
    private func stopTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func calculateSpeed() -> Double {
        let durationToUse = isActive ? currentTime : route.duration
        guard durationToUse > 0 else { return 0 }
        return (route.distance / 1000) / (durationToUse / 3600) // км/ч
    }
    
    /// Темп в формате мм:сс / км (для пеших маршрутов воспринимается лучше, чем км/ч)
    private func formatPace() -> String {
        let durationToUse = isActive ? currentTime : route.duration
        guard durationToUse > 0 else { return "--:-- /км" }
        
        // Если дистанция очень маленькая (< 10м), показываем "--:-- /км"
        guard route.distance >= 10 else { return "--:-- /км" }
        
        let distanceKm = route.distance / 1000
        guard distanceKm > 0 else { return "--:-- /км" }
        
        let secondsPerKm = durationToUse / distanceKm
        guard secondsPerKm.isFinite, secondsPerKm > 0, secondsPerKm < 3600 else { return "--:-- /км" }
        
        let minutes = Int(secondsPerKm) / 60
        let seconds = Int(secondsPerKm) % 60
        return String(format: "%d:%02d /км", minutes, seconds)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Route Detail View

struct RouteDetailView: View {
    let route: RecordedRoute
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var petManager: PetManager
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var themeManager = ThemeManager.shared
    @State private var position: MapCameraPosition = .automatic
    @State private var showPawPrints = true
    @State private var petBounce = false
    
    private var accentGreen: Color { themeManager.accentGreen }
    private var cardColor: Color { themeManager.cardColor }
    
    var body: some View {
        ZStack {
            Map(position: $position) {
                // Маршрут
                if route.points.count > 1 {
                    MapPolyline(coordinates: route.points.map { $0.coordinate })
                        .stroke(accentGreen, lineWidth: 4)
                    
                    // Следы лапок
                    if showPawPrints {
                        ForEach(Array(pawPrintPositions(from: route.points).enumerated()), id: \.offset) { index, coord in
                            Annotation("", coordinate: coord) {
                                Text("🐾")
                                    .font(.system(size: 12))
                                    .opacity(0.6)
                            }
                        }
                    }
                    
                    // Старт
                    if let first = route.points.first {
                        Annotation("Старт", coordinate: first.coordinate) {
                            ZStack {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 24, height: 24)
                                Image(systemName: "flag.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    // Финиш
                    if let last = route.points.last {
                        // Финиш
                        Annotation("Финиш", coordinate: last.coordinate) {
                            ZStack {
                                Circle()
                                    .fill(.red.opacity(0.7))
                                    .frame(width: 20, height: 20)
                                Image(systemName: "flag.checkered")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    // Питомец на финише маршрута (отдельная аннотация для лучшей видимости)
                    if let last = route.points.last, let pet = petManager.pet {
                        Annotation("Питомец", coordinate: last.coordinate) {
                            PetMapMarker(pet: pet, isMoving: false)
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .onAppear {
                updateCameraPosition()
                // Анимация питомца
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    petBounce = true
                }
            }
            
            // Overlay панель
            VStack {
                Spacer()
                
                RouteStatsView(route: route, isActive: false)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(cardColor.opacity(0.95))
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
        }
        .navigationTitle(route.dateString)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showPawPrints.toggle()
                } label: {
                    Image(systemName: showPawPrints ? "pawprint.fill" : "pawprint")
                        .foregroundColor(showPawPrints ? accentGreen : .white.opacity(0.7))
                }
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
    
    private func updateCameraPosition() {
        guard !route.points.isEmpty else { return }
        
        let coordinates = route.points.map { $0.coordinate }
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
        
        // Вычисляем расстояние для показа всего маршрута
        let latSpan = maxLat - minLat
        let lonSpan = maxLon - minLon
        let maxSpan = max(latSpan, lonSpan)
        let distance = max(1000, maxSpan * 111000 * 1.5) // Конвертируем в метры с запасом
        
        position = .camera(MapCamera(
            centerCoordinate: center,
            distance: distance,
            heading: 0,
            pitch: 0
        ))
    }
    
    private func pawPrintPositions(from points: [RoutePoint]) -> [CLLocationCoordinate2D] {
        var positions: [CLLocationCoordinate2D] = []
        let step = max(1, points.count / 20) // Максимум 20 следов
        
        for i in stride(from: 0, to: points.count, by: step) {
            positions.append(points[i].coordinate)
        }
        
        return positions
    }
}

#Preview {
    RoutesView()
        .environmentObject(LocationManager())
        .environmentObject(PetManager())
}
