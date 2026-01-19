//
//  RanksView.swift
//  StepCounter
//
//  Экран всех званий (аналогично AchievementsView)
//

import SwiftUI

struct RanksView: View {
    @EnvironmentObject var levelManager: LevelManager
    @StateObject private var themeManager = ThemeManager.shared
    
    private var bgColor: Color { themeManager.backgroundColor }
    private var cardColor: Color { themeManager.cardColor }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Сводка
                    summaryCard
                    
                    // Сетка званий
                    ranksGrid
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
            .background(
                LinearGradient(
                    colors: themeManager.currentTheme.primaryGradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .id(themeManager.currentTheme.id)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: themeManager.currentTheme.id)
            )
            .navigationTitle("Звания")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Summary Card
    
    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Прогресс кольцо
                ZStack {
                    // Фон
                    Circle()
                        .stroke(cardColor, lineWidth: 10)
                        .frame(width: 90, height: 90)
                    
                    // Прогресс
                    Circle()
                        .trim(from: 0, to: Double(unlockedRanksCount) / Double(PlayerRank.allCases.count))
                        .stroke(
                            AngularGradient(
                                colors: [.green, .cyan, .blue, .purple, .green],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(unlockedRanksCount)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("из \(PlayerRank.allCases.count)")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    // Текущее звание
                    HStack(spacing: 6) {
                        Image(systemName: levelManager.player.rank.iconName)
                            .foregroundColor(levelManager.player.rank.color)
                        Text(levelManager.player.rank.name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    // Уровень
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Уровень \(levelManager.player.level)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // XP
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.cyan)
                        Text("\(levelManager.player.totalXP) XP")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.1), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - Ranks Grid
    
    private var ranksGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            spacing: 20
        ) {
            ForEach(Array(PlayerRank.allCases.enumerated()), id: \.element) { index, rank in
                RankView(
                    rank: rank,
                    isUnlocked: levelManager.player.level >= rank.minLevel,
                    isCurrent: levelManager.player.rank == rank
                )
                .cascadeAppear(delay: Double(index) * 0.05)
            }
        }
    }
    
    private var unlockedRanksCount: Int {
        PlayerRank.allCases.filter { levelManager.player.level >= $0.minLevel }.count
    }
}

#Preview {
    RanksView()
        .environmentObject(LevelManager())
}
