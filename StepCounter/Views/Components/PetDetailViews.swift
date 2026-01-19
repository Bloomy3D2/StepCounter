//
//  PetDetailViews.swift
//  StepCounter
//
//  Детальные экраны для статистики питомца
//

import SwiftUI

// MARK: - Pet XP Detail View

@MainActor
struct PetXPDetailView: View {
    let pet: Pet
    let accentGreen: Color
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    private var averageXPPerDay: Double {
        guard pet.daysOld > 0 else { return 0 }
        return Double(pet.totalXP) / Double(pet.daysOld)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Главная карточка с общим опытом
                    GlassCard(cornerRadius: 24, padding: 32, glowColor: accentGreen.opacity(0.4)) {
                        VStack(spacing: 20) {
                            // Иконка
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                accentGreen.opacity(0.3),
                                                accentGreen.opacity(0.1)
                                            ],
                                            center: .center,
                                            startRadius: 20,
                                            endRadius: 60
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "star.fill")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(accentGreen)
                            }
                            
                            // Общий опыт
                            VStack(spacing: 8) {
                                Text("\(pet.totalXP)")
                                    .font(.system(size: 56, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Всего опыта")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                    
                    // Статистика
                    VStack(spacing: 16) {
                        // Средний опыт в день
                        StatDetailRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Средний опыт в день",
                            value: String(format: "%.1f", averageXPPerDay),
                            color: accentGreen
                        )
                        
                        // Дней вместе
                        StatDetailRow(
                            icon: "calendar",
                            title: "Дней вместе",
                            value: "\(pet.daysOld)",
                            color: .blue
                        )
                        
                        // Дата создания
                        StatDetailRow(
                            icon: "clock.fill",
                            title: "Дата создания",
                            value: dateFormatter.string(from: pet.createdDate),
                            color: .purple
                        )
                        
                        // Текущая эволюция
                        StatDetailRow(
                            icon: "sparkles",
                            title: "Текущая эволюция",
                            value: pet.evolution.name,
                            color: .yellow
                        )
                        
                        // Опыт до следующей эволюции
                        if let xpNeeded = pet.xpToNextEvolution {
                            StatDetailRow(
                                icon: "arrow.up.circle.fill",
                                title: "До следующей эволюции",
                                value: "\(xpNeeded) XP",
                                color: .orange
                            )
                        } else {
                            StatDetailRow(
                                icon: "checkmark.seal.fill",
                                title: "Максимальная эволюция",
                                value: "Достигнута",
                                color: accentGreen
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 24)
            }
            .background(
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .ignoresSafeArea()
            )
            .navigationTitle("Опыт питомца")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.impact(style: .light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
    }
}

// MARK: - Pet Days Detail View

@MainActor
struct PetDaysDetailView: View {
    let pet: Pet
    let accentGreen: Color
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }
    
    private var dayMonthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }
    
    private var yearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }
    
    private var milestoneDays: [Int] {
        [1, 7, 30, 100, 365]
    }
    
    private func milestoneDate(for days: Int) -> Date? {
        Calendar.current.date(byAdding: .day, value: days, to: pet.createdDate)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Главная карточка с днями вместе
                    GlassCard(cornerRadius: 24, padding: 32, glowColor: accentGreen.opacity(0.4)) {
                        VStack(spacing: 20) {
                            // Иконка
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                accentGreen.opacity(0.3),
                                                accentGreen.opacity(0.1)
                                            ],
                                            center: .center,
                                            startRadius: 20,
                                            endRadius: 60
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "calendar")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(accentGreen)
                            }
                            
                            // Дни вместе
                            VStack(spacing: 8) {
                                Text("\(pet.daysOld)")
                                    .font(.system(size: 56, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Дней вместе")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                    
                    // Информация о дате создания
                    GlassCard(cornerRadius: 20, padding: 20, glowColor: .blue.opacity(0.3)) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.blue)
                                
                                Text("Дата создания")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.2))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(dateFormatter.string(from: pet.createdDate))
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                let dayMonth = dayMonthFormatter.string(from: pet.createdDate)
                                let year = yearFormatter.string(from: pet.createdDate)
                                Text("\(dayMonth) \(year) года")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Вехи
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Важные даты")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            ForEach(milestoneDays, id: \.self) { days in
                                if let milestoneDate = milestoneDate(for: days) {
                                    let isPast = milestoneDate <= Date()
                                    MilestoneRow(
                                        days: days,
                                        date: milestoneDate,
                                        isPast: isPast,
                                        accentGreen: accentGreen
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 24)
            }
            .background(
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .ignoresSafeArea()
            )
            .navigationTitle("Дни вместе")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.impact(style: .light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
    }
}

// MARK: - Stat Detail Row

struct StatDetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        GlassCard(cornerRadius: 16, padding: 16, glowColor: color.opacity(0.3)) {
            HStack(spacing: 16) {
                // Иконка
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                
                // Текст
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(value)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Milestone Row

struct MilestoneRow: View {
    let days: Int
    let date: Date
    let isPast: Bool
    let accentGreen: Color
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }
    
    var body: some View {
        GlassCard(cornerRadius: 16, padding: 16, glowColor: isPast ? accentGreen.opacity(0.3) : Color.gray.opacity(0.2)) {
            HStack(spacing: 16) {
                // Иконка
                ZStack {
                    Circle()
                        .fill(isPast ? accentGreen.opacity(0.2) : Color.gray.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: isPast ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isPast ? accentGreen : .gray)
                }
                
                // Текст
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(days) \(days == 1 ? "день" : days < 5 ? "дня" : "дней") вместе")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(dateFormatter.string(from: date))
                        .font(.system(size: 14))
                        .foregroundColor(isPast ? accentGreen.opacity(0.8) : .white.opacity(0.5))
                }
                
                Spacer()
                
                if isPast {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(accentGreen)
                }
            }
        }
    }
}
