//
//  ContentView.swift
//  NegativeSpace
//
//  Главный экран с навигацией
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var showGame = false
    @State private var selectedLevel: Int?
    
    // Дизайн
    private let bgColor = Color(red: 0.05, green: 0.05, blue: 0.08)
    private let cardColor = Color(red: 0.1, green: 0.1, blue: 0.14)
    private let accentColor = Color(red: 0.4, green: 0.8, blue: 0.95)
    private let secondaryAccent = Color(red: 1.0, green: 0.45, blue: 0.5)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Фон
                bgColor.ignoresSafeArea()
                
                // Декоративные элементы
                GeometryReader { geo in
                    // Левый верхний блюр
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 300)
                        .blur(radius: 80)
                        .offset(x: -100, y: -100)
                    
                    // Правый нижний блюр
                    Circle()
                        .fill(secondaryAccent.opacity(0.1))
                        .frame(width: 250)
                        .blur(radius: 70)
                        .offset(x: geo.size.width - 100, y: geo.size.height - 150)
                }
                
                VStack(spacing: 0) {
                    // Заголовок
                    headerView
                    
                    // Выбор уровней
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
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Логотип
            ZStack {
                // Контур фигуры
                RoundedRectangle(cornerRadius: 16)
                    .stroke(accentColor.opacity(0.5), lineWidth: 3)
                    .frame(width: 80, height: 80)
                
                // Внутренний блок
                RoundedRectangle(cornerRadius: 8)
                    .fill(accentColor)
                    .frame(width: 30, height: 30)
                    .offset(x: -12, y: -12)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(secondaryAccent)
                    .frame(width: 30, height: 30)
                    .offset(x: 12, y: 12)
            }
            .padding(.top, 40)
            
            // Название
            VStack(spacing: 4) {
                Text("NEGATIVE")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text("SPACE")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentColor, secondaryAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            // Подзаголовок
            Text("Заполни пустоту")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
            
            // Статистика
            HStack(spacing: 24) {
                StatBadge(
                    icon: "star.fill",
                    value: "\(gameManager.maxUnlockedLevel - 1)",
                    label: "Пройдено",
                    color: .yellow
                )
                
                StatBadge(
                    icon: "lightbulb.fill",
                    value: "\(gameManager.hints)",
                    label: "Подсказки",
                    color: accentColor
                )
            }
            .padding(.top, 8)
        }
        .padding(.bottom, 24)
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
                ForEach(1...50, id: \.self) { level in
                    LevelButton(
                        level: level,
                        isUnlocked: level <= gameManager.maxUnlockedLevel,
                        isCompleted: level < gameManager.maxUnlockedLevel,
                        accentColor: accentColor,
                        cardColor: cardColor
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

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

// MARK: - Level Button

struct LevelButton: View {
    let level: Int
    let isUnlocked: Bool
    let isCompleted: Bool
    let accentColor: Color
    let cardColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if isUnlocked {
                action()
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(isUnlocked ? cardColor : cardColor.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isCompleted ? accentColor.opacity(0.5) : Color.clear,
                                lineWidth: 2
                            )
                    )
                
                if isUnlocked {
                    VStack(spacing: 4) {
                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(accentColor)
                                .font(.system(size: 18))
                        }
                        
                        Text("\(level)")
                            .font(.system(size: isCompleted ? 16 : 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.system(size: 18))
                }
            }
            .frame(height: 70)
        }
        .disabled(!isUnlocked)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(GameManager())
}
