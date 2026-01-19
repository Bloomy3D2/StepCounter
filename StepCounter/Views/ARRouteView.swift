//
//  ARRouteView.swift
//  StepCounter
//
//  AR-визуализация маршрутов (базовая структура)
//

import SwiftUI
import ARKit
import CoreLocation

/// AR-визуализация маршрута для локационного вызова
struct ARRouteView: View {
    let challenge: LocationChallenge
    @ObservedObject var locationManager: LocationManager
    @State private var userLocation: CLLocation?
    @State private var distanceToChallenge: Double?
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Карта с маршрутом (пока используем MapKit, AR требует отдельной настройки)
            MapView(
                challenge: challenge,
                userLocation: userLocation,
                locationManager: locationManager
            )
            .ignoresSafeArea()
            
            // Информационная панель сверху
            VStack {
                challengeInfoCard
                    .padding()
                
                Spacer()
                
                // Кнопка закрытия
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            userLocation = locationManager.currentLocation
            updateDistance()
        }
        .onChange(of: locationManager.currentLocation) { _, newLocation in
            userLocation = newLocation
            updateDistance()
        }
    }
    
    private var challengeInfoCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: challenge.type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(challenge.type.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(challenge.location.name)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Прогресс
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Прогресс")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(Int(challenge.progressPercent * 100))%")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
                
                ProgressView(value: challenge.progressPercent)
                    .tint(challenge.type.color)
            }
            
            // Расстояние до локации
            if let distance = distanceToChallenge {
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Text(distance < 1000 
                        ? "В \(Int(distance)) метрах от локации"
                        : "В \(String(format: "%.1f", distance / 1000)) км от локации")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func updateDistance() {
        guard let userLoc = userLocation else { return }
        let challengeLoc = challenge.location.clLocation
        distanceToChallenge = userLoc.distance(from: challengeLoc)
    }
}

// MARK: - Map View (временная реализация, AR требует ARKit)

struct MapView: View {
    let challenge: LocationChallenge
    let userLocation: CLLocation?
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        // Используем MapKit для показа карты
        // В будущем можно заменить на ARKit для AR-визуализации
        Map {
            // Маркер локации вызова
            Annotation(
                challenge.location.name,
                coordinate: challenge.location.coordinate
            ) {
                VStack {
                    Image(systemName: challenge.type.icon)
                        .font(.system(size: 24))
                        .foregroundColor(challenge.type.color)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(challenge.type.color, lineWidth: 3)
                        )
                }
            }
            
            // Маркер пользователя
            if let userLoc = userLocation {
                Annotation(
                    "Вы здесь",
                    coordinate: userLoc.coordinate
                ) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
            
            // Круг радиуса вызова
            MapCircle(
                center: challenge.location.coordinate,
                radius: challenge.radius
            )
            .foregroundStyle(challenge.type.color.opacity(0.2))
            .stroke(challenge.type.color, lineWidth: 2)
        }
        .mapStyle(.standard)
        .onAppear {
            locationManager.requestCurrentLocation()
        }
    }
}

#Preview {
    let challenge = LocationChallenge(
        type: .stepsAtLocation,
        title: "10,000 шагов в парке",
        description: "Пройдите 10,000 шагов в Центральном парке",
        location: ChallengeLocation(
            name: "Центральный парк",
            latitude: 55.7558,
            longitude: 37.6173
        ),
        targetSteps: 10000
    )
    
    ARRouteView(
        challenge: challenge,
        locationManager: LocationManager()
    )
}
