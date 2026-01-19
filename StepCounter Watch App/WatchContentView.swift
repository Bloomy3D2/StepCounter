//
//  WatchContentView.swift
//  StepCounter Watch App
//
//  Главный экран шагомера на часах
//

import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject var healthManager: WatchHealthManager
    
    private let accentGreen = Color(red: 0.3, green: 0.85, blue: 0.5)
    private let accentBlue = Color(red: 0.3, green: 0.6, blue: 1.0)
    private let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    
    var body: some View {
        TabView {
            // Основной экран
            mainScreen
            
            // Детальная статистика
            detailScreen
        }
        .tabViewStyle(.carousel)
        .onAppear {
            healthManager.fetchAllData()
        }
    }
    
    // MARK: - Main Screen
    
    private var mainScreen: some View {
        VStack(spacing: 8) {
            // Прогресс
            ZStack {
                // Фоновый круг
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                
                // Прогресс
                Circle()
                    .trim(from: 0, to: healthManager.goalProgress)
                    .stroke(
                        LinearGradient(
                            colors: [accentGreen, accentBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: healthManager.goalProgress)
                
                // Центр
                VStack(spacing: 2) {
                    if healthManager.isGoalReached {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(accentGreen)
                    }
                    
                    Text("\(healthManager.todaySteps)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("шагов")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 110, height: 110)
            
            // Цель
            HStack {
                Image(systemName: "flag.fill")
                    .font(.system(size: 10))
                    .foregroundColor(accentOrange)
                
                Text("\(healthManager.stepGoal)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Detail Screen
    
    private var detailScreen: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Дистанция
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(accentBlue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "%.2f км", healthManager.todayDistance / 1000))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Дистанция")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                // Калории
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(accentOrange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(healthManager.todayCalories))")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Калории")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                // Пульс
                if healthManager.heartRate > 0 {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(healthManager.heartRate)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Пульс")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Preview

#Preview {
    WatchContentView()
        .environmentObject(WatchHealthManager())
}
