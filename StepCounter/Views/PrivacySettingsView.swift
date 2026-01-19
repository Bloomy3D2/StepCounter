//
//  PrivacySettingsView.swift
//  StepCounter
//
//  Настройки приватности профиля
//

import SwiftUI

struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var profileVisibility: ProfileVisibility = .public
    @State private var statsVisibility: VisibilityLevel = .friends
    @State private var achievementsVisibility: VisibilityLevel = .public
    @State private var routesVisibility: VisibilityLevel = .private
    
    enum ProfileVisibility: String, CaseIterable {
        case `public` = "Публичный"
        case friends = "Только друзья"
        case `private` = "Приватный"
    }
    
    enum VisibilityLevel: String, CaseIterable {
        case `public` = "Публичный"
        case friends = "Только друзья"
        case `private` = "Приватный"
    }
    
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Профиль
                    visibilitySection(
                        title: "Профиль",
                        icon: "person.fill",
                        selection: Binding(
                            get: { profileVisibility.rawValue },
                            set: { profileVisibility = ProfileVisibility(rawValue: $0) ?? .public }
                        ),
                        options: ProfileVisibility.allCases.map { $0.rawValue }
                    )
                    
                    // Статистика
                    visibilitySection(
                        title: "Статистика",
                        icon: "chart.bar.fill",
                        selection: Binding(
                            get: { statsVisibility.rawValue },
                            set: { statsVisibility = VisibilityLevel(rawValue: $0) ?? .public }
                        ),
                        options: VisibilityLevel.allCases.map { $0.rawValue }
                    )
                    
                    // Достижения
                    visibilitySection(
                        title: "Достижения",
                        icon: "trophy.fill",
                        selection: Binding(
                            get: { achievementsVisibility.rawValue },
                            set: { achievementsVisibility = VisibilityLevel(rawValue: $0) ?? .public }
                        ),
                        options: VisibilityLevel.allCases.map { $0.rawValue }
                    )
                    
                    // Маршруты
                    visibilitySection(
                        title: "Маршруты",
                        icon: "map.fill",
                        selection: Binding(
                            get: { routesVisibility.rawValue },
                            set: { routesVisibility = VisibilityLevel(rawValue: $0) ?? .private }
                        ),
                        options: VisibilityLevel.allCases.map { $0.rawValue }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .ignoresSafeArea()
            )
            .navigationTitle("Настройки приватности")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func visibilitySection(title: String, icon: String, selection: Binding<String>, options: [String]) -> some View {
        GlassCard(cornerRadius: 20, padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(accentGreen)
                    
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Picker("", selection: selection) {
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .tint(accentGreen)
            }
        }
    }
}
