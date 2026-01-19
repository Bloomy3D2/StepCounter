//
//  ContentView.swift
//  TemperatureTiles
//
//  Главное меню
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var showGame = false
    @State private var selectedLevel: Int?
    @State private var thermometerAnimation = false
    
    // Дизайн
    private let bgColor = Color(red: 0.08, green: 0.06, blue: 0.1)
    private let cardColor = Color(red: 0.12, green: 0.1, blue: 0.15)
    private let hotColor = Color(red: 1.0, green: 0.3, blue: 0.2)
    private let coldColor = Color(red: 0.2, green: 0.5, blue: 1.0)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Фон с градиентом
                LinearGradient(
                    colors: [
                        coldColor.opacity(0.15),
                        bgColor,
                        hotColor.opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    statsView
                    levelGrid
                }
            }
            .navigationDestination(isPresented: $showGame) {
                if let level = selectedLevel {
                    GameView()
                        .environmentObject(gameManager)
                        .onAppear {
                            gameManager.loadLevel(level)
                        }
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    thermometerAnimation = true
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Термометр
            ZStack {
                // Шкала
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [coldColor, .white, hotColor],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 30, height: 100)
                
                // Индикатор
                Circle()
                    .fill(thermometerAnimation ? hotColor : coldColor)
                    .frame(width: 40, height: 40)
                    .offset(y: thermometerAnimation ? -35 : 35)
                    .shadow(color: thermometerAnimation ? hotColor : coldColor, radius: 10)
            }
            .padding(.top, 30)
            
            // Название
            VStack(spacing: 4) {
                Text("TEMPERATURE")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [coldColor, hotColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("TILES")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // Подзаголовок
            Text("Доведи всё до нейтральной температуры")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Stats
    
    private var statsView: some View {
        HStack(spacing: 16) {
            StatCard(
                icon: "star.fill",
                value: "\(gameManager.totalStars)",
                label: "Звёзды",
                color: .yellow
            )
            
            StatCard(
                icon: "checkmark.circle.fill",
                value: "\(gameManager.maxUnlockedLevel - 1)",
                label: "Пройдено",
                color: .green
            )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
    
    // MARK: - Level Grid
    
    private var levelGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(1...gameManager.totalLevels, id: \.self) { level in
                    LevelCard(
                        level: level,
                        stars: gameManager.levelStars[level] ?? 0,
                        isUnlocked: level <= gameManager.maxUnlockedLevel,
                        hotColor: hotColor,
                        coldColor: coldColor
                    ) {
                        selectedLevel = level
                        showGame = true
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
    }
}

// MARK: - Level Card

struct LevelCard: View {
    let level: Int
    let stars: Int
    let isUnlocked: Bool
    let hotColor: Color
    let coldColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if isUnlocked { action() }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isUnlocked
                            ? LinearGradient(
                                colors: [coldColor.opacity(0.2), hotColor.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.03), Color.white.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                stars > 0 ? Color.yellow.opacity(0.5) : Color.clear,
                                lineWidth: 2
                            )
                    )
                
                if isUnlocked {
                    VStack(spacing: 4) {
                        // Звёзды
                        if stars > 0 {
                            HStack(spacing: 2) {
                                ForEach(0..<3, id: \.self) { i in
                                    Image(systemName: i < stars ? "star.fill" : "star")
                                        .font(.system(size: 10))
                                        .foregroundColor(i < stars ? .yellow : .white.opacity(0.2))
                                }
                            }
                        }
                        
                        Text("\(level)")
                            .font(.system(size: stars > 0 ? 20 : 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.2))
                }
            }
            .frame(height: 75)
        }
        .disabled(!isUnlocked)
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(GameManager())
}
