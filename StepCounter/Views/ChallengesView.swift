//
//  ChallengesView.swift
//  StepCounter
//
//  Экран челленджей
//

import SwiftUI

struct ChallengesView: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @EnvironmentObject var groupChallengeManager: GroupChallengeManager
    
    @State private var showingCreateSheet = false
    @State private var showingGroupCreateSheet = false
    @State private var showingLeaderboard = false
    @State private var showingSeason = false
    
    @StateObject private var themeManager = ThemeManager.shared
    
    private var bgColor: Color { themeManager.backgroundColor }
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                    VStack(spacing: 24) {
                        // Сезон (временно отключено для отладки)
                        // if SeasonManager.shared.currentSeason != nil {
                        //     seasonCard
                        // }
                        
                        // Групповые челленджи
                        if !groupChallengeManager.activeChallenges.isEmpty {
                            groupChallengesSection
                        }
                        
                        // Активные челленджи
                        if !challengeManager.activeChallenges.isEmpty {
                            activeChallengesSection
                        }
                        
                        // Пустое состояние
                        if challengeManager.activeChallenges.isEmpty && groupChallengeManager.activeChallenges.isEmpty {
                            emptyState
                        }
                        
                        // История
                        if !challengeManager.completedChallenges.isEmpty {
                            historySection
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
                .navigationTitle("Челленджи")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            showingLeaderboard = true
                        } label: {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.yellow)
                        }
                        
                        Menu {
                            Button {
                                showingCreateSheet = true
                            } label: {
                                Label("Личный челлендж", systemImage: "person.fill")
                            }
                            
                            Button {
                                showingGroupCreateSheet = true
                            } label: {
                                Label("Командный челлендж", systemImage: "person.3.fill")
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(accentGreen)
                        }
                    }
                }
                .sheet(isPresented: $showingCreateSheet) {
                    CreateChallengeSheet()
                }
                .sheet(isPresented: $showingGroupCreateSheet) {
                    CreateGroupChallengeSheet()
                }
                .sheet(isPresented: $showingLeaderboard) {
                    PublicLeaderboardView()
                }
                .sheet(isPresented: $showingSeason) {
                    SeasonView()
                }
        }
    }
    
    // MARK: - Season Card
    
    private var seasonCard: some View {
        Button {
            showingSeason = true
        } label: {
            HStack(spacing: 16) {
                if let season = SeasonManager.shared.currentSeason {
                    Text(season.theme.icon)
                        .font(.system(size: 48))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(season.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("\(season.daysRemaining) дней осталось")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardColor.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(accentGreen.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    private var groupChallengesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Командные челленджи")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            ForEach(groupChallengeManager.activeChallenges) { challenge in
                NavigationLink {
                    GroupChallengeDetailView(challenge: challenge)
                        .environmentObject(groupChallengeManager)
                } label: {
                    GroupChallengeCard(challenge: challenge)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var activeChallengesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Активные челленджи")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            ForEach(challengeManager.activeChallenges) { challenge in
                NavigationLink {
                    PersonalChallengeDetailView(challenge: challenge)
                        .environmentObject(challengeManager)
                } label: {
                    ChallengeCard(challenge: challenge)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "flag.fill")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Нет активных челленджей")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text("Создайте свой первый челлендж и бросьте себе вызов!")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            
            Text("Нажмите на плюс в правом верхнем углу, чтобы создать челлендж")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("История")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(challengeManager.totalCompleted) выполнено")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            ForEach(challengeManager.completedChallenges.prefix(5)) { challenge in
                HistoryChallengeRow(challenge: challenge)
            }
        }
    }
}

struct ChallengeCard: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @StateObject private var themeManager = ThemeManager.shared
    let challenge: Challenge
    
    private var cardColor: Color { themeManager.cardColor }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // Иконка
                ZStack {
                    Circle()
                        .fill(challenge.type.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: challenge.type.icon)
                        .font(.system(size: 20))
                        .foregroundColor(challenge.type.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.type.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(challenge.statusText)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Удалить
                Button {
                    challengeManager.deleteChallenge(challenge)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            
            // Прогресс
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(challenge.type.color)
                            .frame(width: geo.size.width * challenge.progressPercent, height: 8)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("\(challenge.currentProgress) \(challenge.type.unit)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Цель: \(challenge.target) \(challenge.type.unit)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(cardColor))
    }
}

struct HistoryChallengeRow: View {
    let challenge: Challenge
    
    @StateObject private var themeManager = ThemeManager.shared
    
    private var cardColor: Color { themeManager.cardColor }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: challenge.isCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(challenge.isCompleted ? .green : .red.opacity(0.6))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(challenge.type.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text("\(challenge.target) \(challenge.type.unit)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            if let date = challenge.completedDate ?? challenge.endDate as Date? {
                Text(formatDate(date))
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(cardColor))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}

struct CreateChallengeSheet: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: ChallengeType = .dailySteps
    @State private var selectedTarget: Int = 10000
    @State private var selectedDuration: Int = 7
    
    @StateObject private var themeManager = ThemeManager.shared
    
    private var bgColor: Color { themeManager.backgroundColor }
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Тип челленджа
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Тип челленджа")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ChallengeType.allCases, id: \.self) { type in
                                    ChallengeTypeButton(type: type, isSelected: selectedType == type) {
                                        selectedType = type
                                        selectedTarget = type.presets.first ?? 10000
                                    }
                                }
                            }
                        }
                    }
                    
                    // Цель
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Цель: \(selectedTarget) \(selectedType.unit)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(selectedType.presets, id: \.self) { preset in
                                    Button {
                                        selectedTarget = preset
                                    } label: {
                                        Text("\(preset)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(selectedTarget == preset ? .white : .white.opacity(0.6))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                Capsule().fill(selectedTarget == preset ? selectedType.color : cardColor)
                                            )
                                    }
                                }
                            }
                        }
                    }
                    
                    // Длительность
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Длительность: \(selectedDuration) дней")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 10) {
                            ForEach([1, 3, 7, 14, 30], id: \.self) { days in
                                Button {
                                    selectedDuration = days
                                } label: {
                                    Text("\(days) дн.")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedDuration == days ? .white : .white.opacity(0.6))
                                        .padding(.horizontal, days >= 14 ? 12 : 14)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: 50)
                                        .background(
                                            Capsule().fill(selectedDuration == days ? accentGreen : cardColor)
                                        )
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Кнопка создания
                    Button {
                        Task { @MainActor in
                            challengeManager.createChallenge(type: selectedType, target: selectedTarget, durationDays: selectedDuration)
                            dismiss()
                        }
                    } label: {
                        Text("Создать челлендж")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(accentGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(20)
            }
            .background(
                LinearGradient(
                    colors: themeManager.currentTheme.primaryGradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Новый челлендж")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(accentGreen)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct ChallengeTypeButton: View {
    let type: ChallengeType
    let isSelected: Bool
    let action: () -> Void
    
    @StateObject private var themeManager = ThemeManager.shared
    @State private var scale: CGFloat = 1.0
    
    private var cardColor: Color { themeManager.cardColor }
    
    var body: some View {
        Button(action: {
            HapticManager.impact(style: .light)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 0.9
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? type.color : .white.opacity(0.5))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                Text(type.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                    .lineLimit(1)
            }
            .frame(width: 80, height: 70)
            .scaleEffect(scale)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(cardColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? type.color : Color.clear, lineWidth: 2)
                            .shadow(color: isSelected ? type.color.opacity(0.5) : Color.clear, radius: 8)
                    )
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

// MARK: - Group Challenge Card

struct GroupChallengeCard: View {
    @EnvironmentObject var groupChallengeManager: GroupChallengeManager
    @StateObject private var themeManager = ThemeManager.shared
    let challenge: GroupChallenge
    
    @State private var showDeleteAlert = false
    
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(challenge.type.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 20))
                        .foregroundColor(challenge.type.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Text("\(challenge.participants.count) участников")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        
                        if challenge.daysRemaining > 0 {
                            Text("• \(challenge.daysRemaining) дн. осталось")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                Spacer()
                
                if let user = challenge.participants.first(where: { $0.id == "user" }) {
                    VStack(spacing: 4) {
                        Text("№\(user.rank)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(user.rank <= 3 ? .yellow : .white)
                        Text("Ваш")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                // Кнопка удаления
                Button {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [challenge.type.color, accentGreen],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * challenge.teamProgress, height: 8)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("\(challenge.totalProgress) / \(challenge.target) \(challenge.type.unit)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(challenge.teamProgress * 100))%")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(challenge.participants.prefix(5)) { participant in
                        HStack(spacing: 4) {
                            if participant.rank <= 3 {
                                Image(systemName: "medal.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor([.yellow, .gray, Color(red: 0.8, green: 0.5, blue: 0.2)][participant.rank - 1])
                            }
                            Text(participant.name)
                                .font(.system(size: 11, weight: participant.id == "user" ? .bold : .regular))
                                .foregroundColor(participant.id == "user" ? accentGreen : .white.opacity(0.7))
                            Text("\(participant.progress)")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(participant.id == "user" ? accentGreen.opacity(0.2) : cardColor)
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(cardColor))
        .alert("Удалить челлендж?", isPresented: $showDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                groupChallengeManager.deleteChallenge(challenge)
            }
        } message: {
            Text("Это действие нельзя отменить.")
        }
    }
}

// MARK: - Create Group Challenge Sheet

struct CreateGroupChallengeSheet: View {
    @EnvironmentObject var groupChallengeManager: GroupChallengeManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var challengeName: String = ""
    @State private var selectedType: ChallengeType = .dailySteps
    @State private var selectedTarget: Int = 100000
    @State private var selectedDuration: Int = 7
    @State private var selectedParticipants: [String] = []
    
    private var bgColor: Color { themeManager.backgroundColor }
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Название челленджа")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                        
                        TextField("Например: Неделя чемпионов", text: $challengeName)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.white)
                            .padding(16)
                            .background(cardColor)
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Тип челленджа")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ChallengeType.allCases, id: \.self) { type in
                                    ChallengeTypeButton(type: type, isSelected: selectedType == type) {
                                        selectedType = type
                                    }
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Общая цель команды: \(selectedTarget) \(selectedType.unit)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach([50000, 100000, 150000, 200000, 300000], id: \.self) { preset in
                                    Button {
                                        selectedTarget = preset
                                    } label: {
                                        Text("\(preset)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(selectedTarget == preset ? .white : .white.opacity(0.6))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                Capsule().fill(selectedTarget == preset ? selectedType.color : cardColor)
                                            )
                                    }
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Длительность: \(selectedDuration) дней")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 10) {
                            ForEach([3, 7, 14, 30], id: \.self) { days in
                                Button {
                                    selectedDuration = days
                                } label: {
                                    Text("\(days) дн.")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedDuration == days ? .white : .white.opacity(0.6))
                                        .padding(.horizontal, days >= 14 ? 12 : 14)
                                        .padding(.vertical, 10)
                                        .frame(minWidth: 50)
                                        .background(
                                            Capsule().fill(selectedDuration == days ? accentGreen : cardColor)
                                        )
                                }
                            }
                        }
                    }
                    
                    // Выбор участников
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Участники")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        ParticipantSelectionView(selectedParticipants: $selectedParticipants)
                    }
                    
                    Spacer(minLength: 40)
                    
                    Button {
                        Task { @MainActor in
                            // Добавляем текущего пользователя в список участников
                            var participants = selectedParticipants
                            if !participants.contains("user") {
                                participants.insert("user", at: 0)
                            }
                            
                            let success = groupChallengeManager.createChallenge(
                                name: challengeName.isEmpty ? "Командный челлендж" : challengeName,
                                type: selectedType,
                                target: selectedTarget,
                                durationDays: selectedDuration,
                                participants: participants
                            )
                            if success {
                                dismiss()
                            }
                        }
                    } label: {
                        Text("Создать командный челлендж")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(accentGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(selectedParticipants.isEmpty)
                }
                .padding(20)
            }
            .background(
                LinearGradient(
                    colors: themeManager.currentTheme.primaryGradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Новый командный челлендж")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(accentGreen)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Participant Selection View

struct ParticipantSelectionView: View {
    @Binding var selectedParticipants: [String]
    
    @StateObject private var themeManager = ThemeManager.shared
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    
    // Моковые данные друзей (в будущем можно загружать из CloudManager или UserModel)
    private let availableFriends: [(id: String, name: String, emoji: String)] = [
        ("friend1", "Алексей", "👨"),
        ("friend2", "Мария", "👩"),
        ("friend3", "Дмитрий", "🧑"),
        ("friend4", "Анна", "👱‍♀️"),
        ("friend5", "Иван", "👨‍💼"),
        ("friend6", "Елена", "👩‍💼"),
        ("friend7", "Сергей", "🧑‍🔧"),
        ("friend8", "Ольга", "👩‍🏫")
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(availableFriends, id: \.id) { friend in
                    Button {
                        if selectedParticipants.contains(friend.id) {
                            selectedParticipants.removeAll { $0 == friend.id }
                        } else {
                            selectedParticipants.append(friend.id)
                        }
                        HapticManager.impact(style: .light)
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(selectedParticipants.contains(friend.id) ? accentGreen : cardColor)
                                    .frame(width: 50, height: 50)
                                
                                Text(friend.emoji)
                                    .font(.system(size: 24))
                                
                                if selectedParticipants.contains(friend.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(accentGreen))
                                        .offset(x: 18, y: -18)
                                }
                            }
                            
                            Text(friend.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .frame(width: 70)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        
        if !selectedParticipants.isEmpty {
            HStack {
                Text("Выбрано: \(selectedParticipants.count)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Button {
                    selectedParticipants.removeAll()
                } label: {
                    Text("Очистить")
                        .font(.system(size: 12))
                        .foregroundColor(accentGreen)
                }
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Group Challenge Detail View

struct GroupChallengeDetailView: View {
    let challenge: GroupChallenge
    @EnvironmentObject var groupChallengeManager: GroupChallengeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteAlert = false
    
    @StateObject private var themeManager = ThemeManager.shared
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                groupChallengeDetail(challenge: challenge)
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: themeManager.currentTheme.primaryGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Детали челленджа")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.8))
                }
            }
        }
        .alert("Удалить челлендж?", isPresented: $showDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                groupChallengeManager.deleteChallenge(challenge)
                dismiss()
            }
        } message: {
            Text("Это действие нельзя отменить. Челлендж будет удалён без возможности восстановления.")
        }
    }
    
    @ViewBuilder
    private func groupChallengeDetail(challenge: GroupChallenge) -> some View {
        // Заголовок
        VStack(spacing: 16) {
            Text(challenge.name)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                Label("\(challenge.participants.count) участников", systemImage: "person.3.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                if challenge.daysRemaining > 0 {
                    Label("\(challenge.daysRemaining) дн. осталось", systemImage: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(cardColor))
        
        // Прогресс команды
        VStack(alignment: .leading, spacing: 12) {
            Text("Прогресс команды")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [challenge.type.color, accentGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * challenge.teamProgress, height: 12)
                }
            }
            .frame(height: 12)
            
            HStack {
                Text("\(challenge.totalProgress) / \(challenge.target) \(challenge.type.unit)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(challenge.teamProgress * 100))%")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(cardColor))
        
        // Рейтинг участников
        VStack(alignment: .leading, spacing: 16) {
            Text("Рейтинг участников")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            ForEach(Array(challenge.participants.enumerated()), id: \.element.id) { index, participant in
                ParticipantRow(
                    participant: participant,
                    rank: participant.rank,
                    challengeType: challenge.type,
                    target: challenge.target,
                    isCurrentUser: participant.id == "user"
                )
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(cardColor))
    }
}

// MARK: - Personal Challenge Detail View

struct PersonalChallengeDetailView: View {
    let challenge: Challenge
    @EnvironmentObject var challengeManager: ChallengeManager
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var themeManager = ThemeManager.shared
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                personalChallengeDetail(challenge: challenge)
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: themeManager.currentTheme.primaryGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Детали челленджа")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func personalChallengeDetail(challenge: Challenge) -> some View {
        // Заголовок
        VStack(spacing: 16) {
            Text(challenge.type.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                Label(challenge.statusText, systemImage: challenge.isCompleted ? "checkmark.circle.fill" : "clock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                if challenge.daysRemaining > 0 {
                    Label("\(challenge.daysRemaining) дн. осталось", systemImage: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(cardColor))
        
        // Прогресс
        VStack(alignment: .leading, spacing: 12) {
            Text("Ваш прогресс")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    Capsule()
                        .fill(challenge.type.color)
                        .frame(width: geo.size.width * challenge.progressPercent, height: 12)
                }
            }
            .frame(height: 12)
            
            HStack {
                Text("\(challenge.currentProgress) / \(challenge.target) \(challenge.type.unit)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(challenge.progressPercent * 100))%")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(cardColor))
        
        // Статистика
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Начало")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    Text(formatDate(challenge.startDate))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Конец")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    Text(formatDate(challenge.endDate))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(cardColor))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}

// MARK: - Participant Row

struct ParticipantRow: View {
    let participant: GroupChallengeParticipant
    let rank: Int
    let challengeType: ChallengeType
    let target: Int
    let isCurrentUser: Bool
    
    @StateObject private var themeManager = ThemeManager.shared
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    
    var body: some View {
        HStack(spacing: 12) {
            // Ранг
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                if rank <= 3 {
                    Image(systemName: "medal.fill")
                        .font(.system(size: 18))
                        .foregroundColor(rankColor)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(rankColor)
                }
            }
            
            // Имя и прогресс
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(participant.name)
                        .font(.system(size: 16, weight: isCurrentUser ? .bold : .medium))
                        .foregroundColor(isCurrentUser ? accentGreen : .white)
                    
                    if isCurrentUser {
                        Text("(Вы)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(challengeType.color)
                            .frame(width: geo.size.width * progressPercent, height: 6)
                    }
                }
                .frame(height: 6)
            }
            
            Spacer()
            
            // Прогресс
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(participant.progress)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text("\(challengeType.unit)")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentUser ? accentGreen.opacity(0.1) : cardColor.opacity(0.5))
        )
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .white.opacity(0.5)
        }
    }
    
    private var progressPercent: Double {
        guard target > 0 else { return 0 }
        return min(1.0, Double(participant.progress) / Double(target))
    }
}

#Preview {
    ChallengesView()
        .environmentObject(ChallengeManager())
        .environmentObject(GroupChallengeManager())
}
