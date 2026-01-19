//
//  LocationChallengesView.swift
//  StepCounter
//
//  Экран локационных вызовов
//

import SwiftUI
import MapKit

struct LocationChallengesView: View {
    @StateObject private var locationChallengeManager = LocationChallengeManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var selectedChallenge: LocationChallenge?
    @State private var showARView = false
    
    private var bgColor: Color { themeManager.backgroundColor }
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.currentTheme.accentColors.primaryColor }
    private var accentBlue: Color { themeManager.currentTheme.accentColors.secondaryColor }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Активные вызовы
                    if !locationChallengeManager.activeChallenges.isEmpty {
                        activeChallengesSection
                    }
                    
                    // Доступные вызовы
                    if !locationChallengeManager.availableChallenges.isEmpty {
                        availableChallengesSection
                    }
                    
                    // История
                    if !locationChallengeManager.completedChallenges.isEmpty {
                        completedChallengesSection
                    }
                    
                    // Пустое состояние
                    if locationChallengeManager.activeChallenges.isEmpty && 
                       locationChallengeManager.availableChallenges.isEmpty {
                        emptyState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .ignoresSafeArea()
            )
            .navigationTitle("Локационные вызовы")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                locationManager.requestAuthorization()
                updateProgress()
            }
            .onChange(of: locationManager.currentLocation) { _, _ in
                updateProgress()
            }
            .sheet(item: $selectedChallenge) { challenge in
                if showARView {
                    ARRouteView(challenge: challenge, locationManager: locationManager)
                } else {
                    LocationChallengeDetailView(challenge: challenge, locationManager: locationManager)
                }
            }
        }
    }
    
    // MARK: - Active Challenges Section
    
    private var activeChallengesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Активные вызовы")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            ForEach(locationChallengeManager.activeChallenges) { challenge in
                LocationChallengeCard(
                    challenge: challenge,
                    locationManager: locationManager,
                    onTap: {
                        selectedChallenge = challenge
                        showARView = false
                    },
                    onARTap: {
                        selectedChallenge = challenge
                        showARView = true
                    }
                )
            }
        }
    }
    
    // MARK: - Available Challenges Section
    
    private var availableChallengesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Доступные вызовы")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            ForEach(locationChallengeManager.availableChallenges) { challenge in
                LocationChallengeCard(
                    challenge: challenge,
                    locationManager: locationManager,
                    isAvailable: true,
                    onTap: {
                        locationChallengeManager.startChallenge(challenge)
                    }
                )
            }
        }
    }
    
    // MARK: - Completed Challenges Section
    
    private var completedChallengesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Выполненные")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(locationChallengeManager.completedChallenges.filter { $0.isCompleted }) { challenge in
                    CompletedChallengeCard(challenge: challenge)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.fill")
                .font(.system(size: 60))
                .foregroundColor(accentBlue.opacity(0.6))
            
            Text("Нет доступных вызовов")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("Новые локационные вызовы появятся здесь")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    // MARK: - Helper Methods
    
    private func updateProgress() {
        guard let location = locationManager.currentLocation else { return }
        guard let healthManager = try? getHealthManager() else { return }
        
        locationChallengeManager.updateProgress(
            userLocation: location,
            steps: healthManager.todaySteps,
            distance: healthManager.todayDistance,
            speed: calculateSpeed(healthManager: healthManager)
        )
    }
    
    private func getHealthManager() throws -> HealthManager {
        // В реальном приложении нужно получить из EnvironmentObject
        return HealthManager()
    }
    
    private func calculateSpeed(healthManager: HealthManager) -> Double {
        // Упрощенный расчет скорости на основе дистанции и времени
        let distanceKm = healthManager.todayDistance / 1000
        let hours = 1.0 // Предполагаем 1 час активности
        return distanceKm / hours
    }
}

// MARK: - Location Challenge Card

struct LocationChallengeCard: View {
    let challenge: LocationChallenge
    @ObservedObject var locationManager: LocationManager
    var isAvailable: Bool = false
    let onTap: () -> Void
    var onARTap: (() -> Void)? = nil
    
    @StateObject private var themeManager = ThemeManager.shared
    
    private var accentColor: Color {
        themeManager.currentTheme.accentColors.primaryColor
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: challenge.type.icon)
                        .font(.title2)
                        .foregroundColor(challenge.type.color)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(challenge.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(challenge.location.name)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    if isAvailable {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(accentColor)
                    } else {
                        Text(challenge.statusText)
                            .font(.caption.bold())
                            .foregroundColor(challenge.isCompleted ? .green : .orange)
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Прогресс
                if !isAvailable {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Прогресс")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("\(Int(challenge.progressPercent * 100))%")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        }
                        
                        ProgressView(value: challenge.progressPercent)
                            .tint(challenge.type.color)
                    }
                }
                
                // Цели
                HStack(spacing: 16) {
                    if let steps = challenge.targetSteps {
                        Label("\(formatNumber(steps))", systemImage: "figure.walk")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    if let distance = challenge.targetDistance {
                        Label("\(String(format: "%.1f", distance / 1000)) км", systemImage: "map")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    if let visits = challenge.targetVisits {
                        Label("\(visits)", systemImage: "location.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // Кнопка AR (только для активных)
                if !isAvailable, let onARTap = onARTap {
                    Button(action: onARTap) {
                        HStack {
                            Image(systemName: "arkit")
                            Text("AR-визуализация")
                        }
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(challenge.type.color.opacity(0.3))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Completed Challenge Card

struct CompletedChallengeCard: View {
    let challenge: LocationChallenge
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: challenge.type.icon)
                .font(.title)
                .foregroundColor(challenge.type.color)
            
            Text(challenge.title)
                .font(.caption.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if let completedDate = challenge.completedDate {
                Text(completedDate, style: .date)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Location Challenge Detail View

struct LocationChallengeDetailView: View {
    let challenge: LocationChallenge
    @ObservedObject var locationManager: LocationManager
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Карта
                    MapView(challenge: challenge, userLocation: locationManager.currentLocation, locationManager: locationManager)
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Информация
                    VStack(alignment: .leading, spacing: 16) {
                        Text(challenge.description)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                        
                        // Прогресс
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Прогресс: \(Int(challenge.progressPercent * 100))%")
                                .font(.headline)
                            
                            ProgressView(value: challenge.progressPercent)
                                .tint(challenge.type.color)
                        }
                        
                        // Детали
                        VStack(alignment: .leading, spacing: 8) {
                            if let steps = challenge.targetSteps {
                                Label("Цель: \(formatNumber(steps)) шагов", systemImage: "figure.walk")
                            }
                            if let distance = challenge.targetDistance {
                                Label("Цель: \(String(format: "%.1f", distance / 1000)) км", systemImage: "map")
                            }
                            if let radius = challenge.daysRemaining {
                                Label("Осталось дней: \(radius)", systemImage: "calendar")
                            }
                        }
                        .font(.body)
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle(challenge.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}
