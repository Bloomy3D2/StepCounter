//
//  SplashView.swift
//  ChallengeApp
//
//  Экран загрузки / Splash
//

import SwiftUI

struct SplashView: View {
    var onStart: () -> Void
    
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Темный фон
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Логотип (анимация появления)
                Image(systemName: "target")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.5)
                
                // Слоган
                VStack(spacing: 16) {
                    Text("splash.title".localized)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("splash.subtitle".localized)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                // Кнопка "Начать"
                Button(action: {
                    Logger.shared.info("👆 SplashView: Button 'Начать' tapped - calling onStart")
                    onStart()
                }) {
                    Text("splash.start".localized)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
            }
        }
        .onAppear {
            Logger.shared.info("📱 SplashView appeared")
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
    }
}
