//
//  GoalSettingsView.swift
//  StepCounter
//
//  Экран управления целью шагов
//

import SwiftUI

struct GoalSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var healthManager: HealthManager
    
    @StateObject private var themeManager = ThemeManager.shared
    
    private var accentGreen: Color { themeManager.accentGreen }
    private var accentBlue: Color { themeManager.accentBlue }
    private var cardColor: Color { themeManager.cardColor }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Заголовок
                        VStack(spacing: 8) {
                            Text("Изменить цели")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Установите дневную цель по шагам")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 20)
                        
                        // Текущая цель
                        GlassCard(cornerRadius: 20, padding: 32, glowColor: accentGreen.opacity(0.3)) {
                            VStack(spacing: 20) {
                                Text("\(healthManager.stepGoal)")
                                    .font(.system(size: 64, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("шагов в день")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        // Кнопки изменения
                        GlassCard(cornerRadius: 20, padding: 20, glowColor: accentBlue.opacity(0.3)) {
                            HStack(spacing: 20) {
                                Button {
                                    if healthManager.stepGoal > 1000 {
                                        healthManager.stepGoal -= 1000
                                        HapticManager.impact(style: .light)
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 44))
                                        .foregroundColor(accentBlue)
                                }
                                
                                Spacer()
                                
                                Button {
                                    healthManager.stepGoal += 1000
                                    HapticManager.impact(style: .light)
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 44))
                                        .foregroundColor(accentGreen)
                                }
                            }
                        }
                        
                        // Быстрые значения
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Быстрый выбор")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach([5000, 8000, 10000, 12000, 15000, 20000], id: \.self) { goal in
                                    Button {
                                        healthManager.stepGoal = goal
                                        HapticManager.impact(style: .light)
                                    } label: {
                                        Text("\(goal / 1000)k")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(healthManager.stepGoal == goal ? .white : .white.opacity(0.7))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(healthManager.stepGoal == goal ? accentGreen : cardColor.opacity(0.5))
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        }
    }
}

#Preview {
    GoalSettingsView()
        .environmentObject(HealthManager())
}
