//
//  ContentView.swift
//  PulseGrid
//
//  Главное меню
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var audioManager: AudioManager
    @State private var showGame = false
    @State private var selectedLevel: Int?
    @State private var pulseAnimation = false
    
    // Дизайн
    private let bgColor = Color(red: 0.03, green: 0.03, blue: 0.06)
    private let cardColor = Color(red: 0.08, green: 0.08, blue: 0.12)
    private let accentCyan = Color(red: 0.4, green: 0.8, blue: 0.95)
    private let accentPink = Color(red: 1.0, green: 0.45, blue: 0.5)
    private let accentPurple = Color(red: 0.7, green: 0.5, blue: 0.95)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Фон
                bgColor.ignoresSafeArea()
                
                // Анимированные круги на фоне
                backgroundPulses
                
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
                        .environmentObject(audioManager)
                        .onAppear {
                            gameManager.startLevel(level)
                        }
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Background Pulses
    
    private var backgroundPulses: some View {
        GeometryReader { geo in
            ZStack {
                // Пульсирующие круги
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    [accentCyan, accentPink, accentPurple][i].opacity(0.15),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                        .offset(
                            x: i == 0 ? -100 : (i == 1 ? geo.size.width - 100 : geo.size.width / 2 - 150),
                            y: i == 0 ? 100 : (i == 1 ? geo.size.height - 200 : geo.size.height / 2)
                        )
                        .animation(
                            .easeInOut(duration: 2 + Double(i) * 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.3),
                            value: pulseAnimation
                        )
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Лого с пульсацией
            ZStack {
                // Внешнее кольцо
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [accentCyan, accentPink, accentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 90, height: 90)
                    .scaleEffect(pulseAnimation ? 1.1 : 0.95)
                
                // Внутренние ячейки
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 4)
                            .fill([accentCyan, accentPink, accentPurple][i])
                            .frame(width: 20, height: 20)
                            .scaleEffect(pulseAnimation ? (i == 1 ? 1.2 : 1.0) : (i == 1 ? 1.0 : 1.2))
                    }
                }
            }
            .padding(.top, 40)
            
            // Название
            VStack(spacing: 4) {
                Text("PULSE")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentCyan, accentPink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("GRID")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // Подзаголовок
            Text("Поймай ритм • Собери комбо")
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
    
    @State private var isPressing = false
    
    var body: some View {
        Button(action: {
            if isUnlocked { action() }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isUnlocked
                            ? Color.white.opacity(isPressing ? 0.15 : 0.08)
                            : Color.white.opacity(0.03)
                    )
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
        .buttonStyle(PressableButtonStyle())
    }
}

struct PressableButtonStyle: ButtonStyle {
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
        .environmentObject(AudioManager())
}
