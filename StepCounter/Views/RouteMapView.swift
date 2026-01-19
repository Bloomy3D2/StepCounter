//
//  RouteMapView.swift
//  StepCounter
//
//  Карта маршрута с питомцем
//

import SwiftUI
import MapKit

struct RouteMapView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var petManager: PetManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var position: MapCameraPosition = .automatic
    @State private var petBounce = false
    @State private var showPawPrints = true
    @State private var currentDuration: TimeInterval = 0
    @State private var timerTask: Task<Void, Never>?
    
    @StateObject private var themeManager = ThemeManager.shared
    private var accentGreen: Color { themeManager.accentGreen }
    private var cardColor: Color { themeManager.cardColor }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Карта
                Map(position: $position) {
                    // Маршрут
                    if let route = locationManager.currentRoute, !route.points.isEmpty {
                        // Линия маршрута (рисуем только если есть минимум 2 точки)
                        if route.points.count > 1 {
                            MapPolyline(coordinates: route.points.map { $0.coordinate })
                                .stroke(accentGreen, lineWidth: 4)
                            
                            // Следы лапок вдоль маршрута
                            if showPawPrints {
                                ForEach(Array(pawPrintPositions(from: route.points).enumerated()), id: \.offset) { index, coord in
                                    Annotation("", coordinate: coord) {
                                        Text("🐾")
                                            .font(.system(size: 12))
                                            .opacity(0.6)
                                    }
                                }
                            }
                        }
                        
                        // Старт (показываем всегда, если есть хотя бы одна точка)
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
                    }
                    
                    // Питомец на текущей позиции
                    if let location = locationManager.currentLocation, let pet = petManager.pet {
                        Annotation("Питомец", coordinate: location.coordinate) {
                            PetMapMarker(pet: pet, isMoving: locationManager.isTracking)
                        }
                        
                        // Явно показываем маркер пользователя на той же координате, чтобы не было ощущения "рассинхрона"
                        Annotation("Вы", coordinate: location.coordinate) {
                            ZStack {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 18, height: 18)
                                Circle()
                                    .fill(.white)
                                    .frame(width: 7, height: 7)
                            }
                        }
                    }
                    
                    // Текущая позиция (если нет питомца)
                    if locationManager.currentRoute == nil, let location = locationManager.currentLocation, petManager.pet == nil {
                        Annotation("Вы здесь", coordinate: location.coordinate) {
                            ZStack {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 20, height: 20)
                                Circle()
                                    .fill(.white)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                
                // Overlay панель управления
                VStack {
                    Spacer()
                    
                    controlPanel
                }
            }
        .onAppear {
            updateCameraPosition()
            // Запрашиваем локацию, если её нет
            if locationManager.currentLocation == nil {
                locationManager.requestCurrentLocation()
            }
            // Если трекинг активен, убеждаемся, что обновление локации работает
            if locationManager.isTracking {
                locationManager.requestCurrentLocation()
                // Запускаем таймер для обновления статистики
                startUpdateTimer()
            }
        }
        .onDisappear {
            // Останавливаем таймер при закрытии экрана
            stopUpdateTimer()
        }
        .onChange(of: locationManager.isTracking) { _, isTracking in
            if isTracking {
                startUpdateTimer()
            } else {
                stopUpdateTimer()
            }
        }
        .onChange(of: locationManager.currentLocation) { _, newLocation in
            // Обновляем камеру при изменении локации
            if let location = newLocation {
                // Если трекинг активен, следим за движением
                if locationManager.isTracking {
                    position = .camera(MapCamera(
                        centerCoordinate: location.coordinate,
                        distance: 500,
                        heading: 0,
                        pitch: 45
                    ))
                } else {
                    // Если трекинг не активен, просто обновляем позицию
                    updateCameraPosition()
                }
            }
        }
        .onChange(of: locationManager.currentRoute) { _, newRoute in
            // Обновляем камеру при изменении маршрута
            if let route = newRoute {
                updateCameraPosition()
                // Инициализируем текущее время
                if locationManager.isTracking {
                    currentDuration = Date().timeIntervalSince(route.startDate)
                }
            } else {
                currentDuration = 0
            }
        }
        .navigationTitle("Прогулка")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        }
    }
    
    // MARK: - Control Panel
    
    private var controlPanel: some View {
        VStack(spacing: 12) {
            // Статистика маршрута
            if let route = locationManager.currentRoute {
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text(String(format: "%.2f", route.distanceKm))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("км")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Divider()
                        .frame(height: 40)
                        .background(Color.white.opacity(0.3))
                    
                    VStack(spacing: 4) {
                        Text(formatDuration(locationManager.isTracking ? currentDuration : route.duration))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("время")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Divider()
                        .frame(height: 40)
                        .background(Color.white.opacity(0.3))
                    
                    VStack(spacing: 4) {
                        Text("\(route.points.count)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("точек")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(cardColor.opacity(0.95))
                )
            }
            
            // Кнопки управления
            HStack(spacing: 16) {
                // Показать/скрыть лапки
                Button {
                    showPawPrints.toggle()
                } label: {
                    Image(systemName: showPawPrints ? "pawprint.fill" : "pawprint")
                        .font(.system(size: 20))
                        .foregroundColor(showPawPrints ? accentGreen : .white.opacity(0.6))
                        .frame(width: 50, height: 50)
                        .background(cardColor.opacity(0.95))
                        .clipShape(Circle())
                }
                
                // Кнопка старт/стоп
                Button {
                    if locationManager.isTracking {
                        locationManager.stopTracking()
                    } else {
                        locationManager.startTracking()
                    }
                } label: {
                    HStack {
                        Image(systemName: locationManager.isTracking ? "stop.fill" : "record.circle")
                        Text(locationManager.isTracking ? "Стоп" : "Старт")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(locationManager.isTracking ? Color.red : accentGreen)
                    .clipShape(Capsule())
                }
                
                // Центрировать карту
                Button {
                    updateCameraPosition()
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 50, height: 50)
                        .background(cardColor.opacity(0.95))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    // MARK: - Helpers
    
    private func updateCameraPosition() {
        if let location = locationManager.currentLocation {
            position = .camera(MapCamera(
                centerCoordinate: location.coordinate,
                distance: 500,
                heading: 0,
                pitch: 45
            ))
        }
    }
    
    private func pawPrintPositions(from points: [RoutePoint]) -> [CLLocationCoordinate2D] {
        // Показываем лапки каждые ~50 метров
        var result: [CLLocationCoordinate2D] = []
        var lastPoint: CLLocation?
        var accumulatedDistance: Double = 0
        
        for point in points {
            let location = CLLocation(latitude: point.latitude, longitude: point.longitude)
            
            if let last = lastPoint {
                accumulatedDistance += location.distance(from: last)
                
                if accumulatedDistance >= 50 {
                    result.append(point.coordinate)
                    accumulatedDistance = 0
                }
            }
            
            lastPoint = location
        }
        
        return result
    }
    
    private func startUpdateTimer() {
        stopUpdateTimer() // Останавливаем предыдущий таймер, если есть
        
        guard let route = locationManager.currentRoute else { return }
        let startTime = route.startDate
        
        // Инициализируем текущее время сразу
        currentDuration = Date().timeIntervalSince(startTime)
        
        timerTask = Task { @MainActor in
            while !Task.isCancelled && locationManager.isTracking {
                currentDuration = Date().timeIntervalSince(startTime)
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 секунда
            }
        }
    }
    
    private func stopUpdateTimer() {
        timerTask?.cancel()
        timerTask = nil
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

// MARK: - Pet Map Marker

struct PetMapMarker: View {
    let pet: Pet
    let isMoving: Bool
    
    @State private var bounce = false
    @State private var showDust = false
    
    var body: some View {
        ZStack {
            // Пыль при движении
            if isMoving && showDust {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .offset(x: CGFloat.random(in: -15...(-5)), y: CGFloat.random(in: -5...5))
                }
            }
            
            // Питомец
            VStack(spacing: 0) {
                Text(pet.type.emoji)
                    .font(.system(size: 36))
                    .scaleEffect(bounce ? 1.1 : 1.0)
                    .offset(y: bounce ? -3 : 0)
                
                // Тень
                Ellipse()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 24, height: 8)
                    .scaleEffect(bounce ? 0.9 : 1.0)
            }
        }
        .onAppear {
            if isMoving {
                startMovingAnimation()
            }
        }
        .onChange(of: isMoving) { _, moving in
            if moving {
                startMovingAnimation()
            } else {
                stopMovingAnimation()
            }
        }
    }
    
    private func startMovingAnimation() {
        showDust = true
        withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
            bounce = true
        }
    }
    
    private func stopMovingAnimation() {
        showDust = false
        withAnimation(.easeOut(duration: 0.2)) {
            bounce = false
        }
    }
}

// MARK: - Preview

#Preview {
    RouteMapView()
        .environmentObject(LocationManager())
        .environmentObject(PetManager())
}
