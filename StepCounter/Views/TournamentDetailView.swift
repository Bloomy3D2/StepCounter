//
//  TournamentDetailView.swift
//  StepCounter
//
//  Детальный просмотр турнира
//

import SwiftUI

struct TournamentDetailView: View {
    let tournament: Tournament
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var tournamentManager: TournamentManager
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var levelManager: LevelManager
    
    @StateObject private var themeManager = ThemeManager.shared
    
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.currentTheme.accentColors.primaryColor }
    
    private var userParticipant: TournamentParticipant? {
        tournament.participants.first(where: { $0.id == "user" })
    }
    
    private var userRank: Int {
        userParticipant?.rank ?? 0
    }
    
    private var userSteps: Int {
        userParticipant?.steps ?? 0
    }
    
    private var topParticipants: [TournamentParticipant] {
        Array(tournament.participants.prefix(10))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Заголовок и прогресс
                    headerSection
                    
                    // Место пользователя
                    userRankCard
                    
                    // Награды
                    rewardsSection
                    
                    // Топ участников
                    leaderboardSection
                    
                    // Правила
                    rulesSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .ignoresSafeArea()
            )
            .navigationTitle("Турнир")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Иконка и название
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.yellow.opacity(0.3), .orange.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.yellow)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tournament.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(formatDateRange(tournament.startDate, tournament.endDate))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
            }
            
            // Прогресс недели
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Прогресс недели")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text("\(tournament.daysRemaining) дн. осталось")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 10)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [accentGreen, Color.cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * tournament.progress, height: 10)
                    }
                }
                .frame(height: 10)
                
                Text("\(Int(tournament.progress * 100))% завершено")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(20)
        .background(
            GlassCard(cornerRadius: 20, padding: 0) {
                Color.clear
            }
        )
    }
    
    // MARK: - User Rank Card
    
    private var userRankCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Ваше место")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Место с медалью
                HStack(spacing: 8) {
                    if userRank <= 3 {
                        Image(systemName: "medal.fill")
                            .font(.system(size: 24))
                            .foregroundColor(rankMedalColor(userRank))
                    }
                    
                    Text("№\(userRank)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(userRank <= 3 ? rankMedalColor(userRank) : .white)
                }
            }
            
            // Шаги пользователя
            HStack(spacing: 12) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 20))
                    .foregroundColor(accentGreen)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(formatNumber(userSteps)) шагов")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("За эту неделю")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .padding(20)
        .background(
            GlassCard(cornerRadius: 20, padding: 0) {
                Color.clear
            }
        )
    }
    
    // MARK: - Rewards Section
    
    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Награды")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                RewardRow(rank: 1, xp: 5000, title: "🥇 Чемпион недели", isUserRank: userRank == 1)
                RewardRow(rank: 2, xp: 3000, title: "🥈 Второе место", isUserRank: userRank == 2)
                RewardRow(rank: 3, xp: 2000, title: "🥉 Третье место", isUserRank: userRank == 3)
                RewardRow(rank: 4, xp: 1000, title: "🏅 Топ-5", isUserRank: userRank >= 4 && userRank <= 5)
                RewardRow(rank: 6, xp: 500, title: "⭐ Топ-10", isUserRank: userRank >= 6 && userRank <= 10)
                RewardRow(rank: 11, xp: 100, title: "💪 Участник", isUserRank: userRank > 10)
            }
        }
        .padding(20)
        .background(
            GlassCard(cornerRadius: 20, padding: 0) {
                Color.clear
            }
        )
    }
    
    // MARK: - Leaderboard Section
    
    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Таблица лидеров")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Топ-10")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            VStack(spacing: 8) {
                ForEach(Array(topParticipants.enumerated()), id: \.element.id) { index, participant in
                    TournamentLeaderboardRow(
                        participant: participant,
                        rank: index + 1,
                        isUser: participant.id == "user"
                    )
                }
            }
        }
        .padding(20)
        .background(
            GlassCard(cornerRadius: 20, padding: 0) {
                Color.clear
            }
        )
    }
    
    // MARK: - Rules Section
    
    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.cyan)
                
                Text("Как это работает")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                RuleItem(icon: "calendar", text: "Турнир длится всю неделю (понедельник - воскресенье)")
                RuleItem(icon: "figure.walk", text: "Ваши шаги автоматически добавляются в турнир")
                RuleItem(icon: "trophy.fill", text: "В конце недели вы получите награду в зависимости от места")
                RuleItem(icon: "arrow.triangle.2.circlepath", text: "Каждый понедельник начинается новый турнир")
            }
        }
        .padding(20)
        .background(
            GlassCard(cornerRadius: 20, padding: 0) {
                Color.clear
            }
        )
    }
    
    // MARK: - Helpers
    
    private func rankMedalColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Бронза
        default: return .white
        }
    }
    
    private func formatDateRange(_ start: Date, _ end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "ru_RU")
        
        let startStr = formatter.string(from: start)
        let endStr = formatter.string(from: end)
        
        return "\(startStr) - \(endStr)"
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000000 {
            return String(format: "%.1fМ", Double(number) / 1000000.0)
        } else if number >= 1000 {
            return String(format: "%.1fК", Double(number) / 1000.0)
        }
        return "\(number)"
    }
}

// MARK: - Reward Row

struct RewardRow: View {
    let rank: Int
    let xp: Int
    let title: String
    let isUserRank: Bool
    
    @StateObject private var themeManager = ThemeManager.shared
    private var accentGreen: Color { themeManager.currentTheme.accentColors.primaryColor }
    
    var body: some View {
        HStack(spacing: 12) {
            // Ранг
            ZStack {
                Circle()
                    .fill(isUserRank ? accentGreen.opacity(0.2) : Color.white.opacity(0.05))
                    .frame(width: 40, height: 40)
                
                Text("\(rank)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isUserRank ? accentGreen : .white.opacity(0.6))
            }
            
            // Название
            Text(title)
                .font(.system(size: 14, weight: isUserRank ? .bold : .medium))
                .foregroundColor(isUserRank ? .white : .white.opacity(0.7))
            
            Spacer()
            
            // XP награда
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                
                Text("\(xp) XP")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.yellow)
            }
            
            // Индикатор текущего места
            if isUserRank {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(accentGreen)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isUserRank ? accentGreen.opacity(0.1) : Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUserRank ? accentGreen.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Tournament Leaderboard Row

struct TournamentLeaderboardRow: View {
    let participant: TournamentParticipant
    let rank: Int
    let isUser: Bool
    
    @StateObject private var themeManager = ThemeManager.shared
    private var accentGreen: Color { themeManager.currentTheme.accentColors.primaryColor }
    
    var body: some View {
        HStack(spacing: 12) {
            // Место
            ZStack {
                if rank <= 3 {
                    Image(systemName: "medal.fill")
                        .font(.system(size: 20))
                        .foregroundColor(medalColor(rank))
                } else {
                    Text("\(rank)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 24)
                }
            }
            .frame(width: 30)
            
            // Имя
            Text(participant.name)
                .font(.system(size: 15, weight: isUser ? .bold : .medium))
                .foregroundColor(isUser ? accentGreen : .white)
            
            Spacer()
            
            // Шаги
            Text(formatSteps(participant.steps))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isUser ? accentGreen.opacity(0.1) : Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isUser ? accentGreen.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    private func medalColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .white
        }
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000000 {
            return String(format: "%.1fМ", Double(steps) / 1000000.0)
        } else if steps >= 1000 {
            return String(format: "%.1fК", Double(steps) / 1000.0)
        }
        return "\(steps)"
    }
}

// MARK: - Rule Item

struct RuleItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.cyan)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    TournamentDetailView(tournament: Tournament(
        id: "test",
        type: .weekly,
        name: "Еженедельный турнир",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date().addingTimeInterval(7 * 24 * 60 * 60),
        participants: [
            TournamentParticipant(id: "user", name: "Вы", steps: 15000, rank: 3),
            TournamentParticipant(id: "1", name: "Анна", steps: 25000, rank: 1),
            TournamentParticipant(id: "2", name: "Михаил", steps: 20000, rank: 2)
        ],
        userResult: nil,
        isActive: true,
        description: nil
    ))
    .environmentObject(TournamentManager())
    .environmentObject(HealthManager())
    .environmentObject(LevelManager())
}
