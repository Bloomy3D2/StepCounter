//
//  VictoryView.swift
//  ChallengeApp
//
//  Экран победы
//

import SwiftUI

struct VictoryView: View {
    let challenge: Challenge
    let payout: Double
    let winnersCount: Int
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Анимация
                Text("🎉")
                    .font(.system(size: 100))
                
                Text("victory.made_it".localized)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    Text("victory.you_earned".localized)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(String(format: "%.0f ₽", payout))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    
                    Text(String(format: "victory.winners_count".localized, winnersCount))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        // Вывод денег
                        if var user = appState.currentUser {
                            user.balance += payout
                            appState.setUser(user)
                        }
                        dismiss()
                    }) {
                        Text("victory.withdraw_money".localized)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("victory.next_challenge".localized)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }
}
