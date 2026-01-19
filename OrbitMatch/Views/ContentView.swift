//
//  ContentView.swift
//  OrbitMatch
//
//  Главное меню
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var showGame = false
    @State private var selectedLevel: Int?
    @State private var orbitAnimation = false
    
    // Дизайн
    private let bgColor = Color(red: 0.02, green: 0.02, blue: 0.05)
    private let cardColor = Color(red: 0.07, green: 0.07, blue: 0.11)
    private let accentCyan = Color(red: 0.4, green: 0.85, blue: 0.95)
    private let accentPink = Color(red: 1.0, green: 0.45, blue: 0.55)
    private let accentPurple = Color(red: 0.7, green: 0.5, blue: 0.95)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Фон
                bgColor.ignoresSafeArea()
                
                // Звёзды на фоне
                starsBackground
                
                VStack(spacing: 0) {
                    // Заголовок
                    headerView
                    
                    // Статистика
                    statsView
                    
                    // Уровни
                    levelGrid
                }
            }
            .navigationDestination(isPresented: $showGame) {
                if let level = selectedLevel {
                    GameView()
                        .environmentObject(gameManager)
                        .onAppear {
                            gameManager.startLevel(level)
                        }
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                    orbitAnimation = true
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Stars Background
    
    private var starsBackground: some View {
        GeometryReader { geo in
            ForEach(0..<30, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.2...0.6)))
                    .frame(width: CGFloat.random(in: 1...3))
                    .position(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: CGFloat.random(in: 0...geo.size.height)
                    )
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Анимированные орбиты
            ZStack {
                // Орбиты
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(
                            [accentCyan, accentPink, accentPurple][i].opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: CGFloat(50 + i * 30), height: CGFloat(50 + i * 30))
                    
                    // Шарик на орбите
                    Circle()
                        .fill([accentCyan, accentPink, accentPurple][i])
                        .frame(width: 12, height: 12)
                        .offset(y: CGFloat(-25 - i * 15))
                        .rotationEffect(.degrees(orbitAnimation ? 360 : 0) * (i % 2 == 0 ? 1 : -1))
                }
            }
            .frame(height: 120)
            .padding(.top, 30)
            
            // Название
            VStack(spacing: 4) {
                Text("ORBIT")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentCyan, accentPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("MATCH")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // Подзаголовок
            Text("Поймай момент • Собери линию")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Stats
    
    private var statsView: some View {
        HStack(spacing: 16) {
            StatCard(
                icon: "trophy.fill",
                value: "\(gameManager.highScore)",
                label: "Рекорд",
                color: .yellow
            )
            
            StatCard(
                icon: "star.fill",
                value: "\(gameManager.maxUnlockedLevel - 1)",
                label: "Пройдено",
                color: accentCyan
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
                ForEach(1...30, id: \.self) { level in
                    LevelCard(
                        level: level,
                        isUnlocked: level <= gameManager.maxUnlockedLevel,
                        isCompleted: level < gameManager.maxUnlockedLevel,
                        accentColor: accentForLevel(level)
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
    
    private func accentForLevel(_ level: Int) -> Color {
        switch (level - 1) % 3 {
        case 0: return accentCyan
        case 1: return accentPink
        default: return accentPurple
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
                .fill(Color.white.opacity(0.06))
        )
    }
}

// MARK: - Level Card

struct LevelCard: View {
    let level: Int
    let isUnlocked: Bool
    let isCompleted: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if isUnlocked { action() }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isUnlocked ? 0.08 : 0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isCompleted ? accentColor.opacity(0.6) : Color.clear,
                                lineWidth: 2
                            )
                    )
                
                if isUnlocked {
                    VStack(spacing: 6) {
                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(accentColor)
                        }
                        
                        Text("\(level)")
                            .font(.system(size: isCompleted ? 18 : 24, weight: .bold, design: .rounded))
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
