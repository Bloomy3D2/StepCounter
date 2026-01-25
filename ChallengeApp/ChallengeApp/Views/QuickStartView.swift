//
//  QuickStartView.swift
//  ChallengeApp
//
//  Quick Start экран - первый челлендж для новых пользователей
//

import SwiftUI

struct QuickStartView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var challengeManager: ChallengeManager
    @Binding var showQuickStart: Bool // Для управления навигацией из RootView
    @State private var isCreating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var navigateToPayment = false
    @State private var selectedChallenge: Challenge?
    
    // Параметры Quick Start челленджа
    private let quickStartDuration = 1
    private let quickStartEntryFee = 499.0
    private let quickStartCategory = "Привычки"
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Заголовок
                    VStack(spacing: 16) {
                        Text("quickstart.ready".localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("quickstart.try_first".localized)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 40)
                    
                    // Карточка челленджа
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.yellow)
                            
                            Text("quickstart.first_challenge".localized)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("quickstart.duration_label".localized)
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text("\(quickStartDuration) \(quickStartDuration == 1 ? "quickstart.day".localized : "quickstart.days".localized)")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Text("quickstart.stake".localized)
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text("\(Int(quickStartEntryFee)) ₽")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Text("quickstart.category".localized)
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text(quickStartCategory)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }
                        .font(.system(size: 16))
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Кнопка "Начать за 499 ₽"
                    Button(action: {
                        handleStartChallenge()
                    }) {
                        if isCreating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        } else {
                            Text(String(format: "quickstart.start_for".localized, Int(quickStartEntryFee)))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(16)
                    .disabled(isCreating)
                    
                    // Кнопка "Выбрать другой"
                    Button(action: {
                        Logger.shared.info("👆 QuickStartView: User tapped 'Выбрать другой'")
                        // Переход к MainTabView
                        withAnimation {
                            showQuickStart = false
                        }
                    }) {
                        Text("quickstart.choose_other".localized)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .alert("error.title".localized, isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            Logger.shared.info("📱 QuickStartView appeared")
        }
        .sheet(isPresented: $navigateToPayment) {
            if let challenge = selectedChallenge {
                PaymentView(challenge: challenge)
                    .environmentObject(appState)
                    .environmentObject(challengeManager)
                    .onAppear {
                        Logger.shared.info("💳 QuickStartView: Opening PaymentView for challengeId=\(challenge.id), entryFee=\(challenge.entryFee)")
                    }
                    .onDisappear {
                        Logger.shared.info("💳 QuickStartView: PaymentView dismissed")
                        // После закрытия PaymentView проверяем, появился ли активный челлендж
                        let activeCount = challengeManager.userChallenges.filter { $0.isActive }.count
                        Logger.shared.info("💳 QuickStartView: After payment, activeChallenges=\(activeCount)")
                        if challengeManager.userChallenges.contains(where: { $0.isActive }) {
                            Logger.shared.info("💳 QuickStartView: Active challenge found, navigating to MainTabView")
                            withAnimation {
                                showQuickStart = false
                            }
                        }
                    }
            }
        }
        .onChange(of: navigateToPayment) { _, isPresented in
            if isPresented, let challenge = selectedChallenge {
                Logger.shared.info("💳 QuickStartView: Payment sheet will appear for challengeId=\(challenge.id), entryFee=\(challenge.entryFee)")
            }
        }
    }
    
    private func handleStartChallenge() {
        guard !isCreating else {
            Logger.shared.warning("👆 QuickStartView.handleStartChallenge: Already creating, ignoring")
            return
        }
        
        Logger.shared.info("👆 QuickStartView.handleStartChallenge: User tapped 'Начать', searching for Quick Start challenge (duration=\(quickStartDuration), entryFee=\(quickStartEntryFee))")
        isCreating = true
        
        Task {
            // Загружаем челленджи, если их еще нет
            if challengeManager.availableChallenges.isEmpty {
                Logger.shared.info("📋 QuickStartView: Loading challenges from Supabase")
                await challengeManager.loadChallengesFromSupabase(forceRefresh: true)
            }
            
            await MainActor.run {
                let availableCount = challengeManager.availableChallenges.count
                Logger.shared.info("📋 QuickStartView: Available challenges count=\(availableCount)")
                
                // Ищем подходящий Quick Start челлендж (1 день, 499₽)
                if let quickStartChallenge = challengeManager.availableChallenges.first(where: { 
                    $0.duration == quickStartDuration && 
                    abs($0.entryFee - quickStartEntryFee) < 1.0 
                }) {
                    Logger.shared.info("✅ QuickStartView: Found Quick Start challenge, challengeId=\(quickStartChallenge.id), title=\(quickStartChallenge.title)")
                    selectedChallenge = quickStartChallenge
                    navigateToPayment = true
                    isCreating = false
                } else {
                    // Если нет подходящего челленджа, переходим к выбору
                    Logger.shared.warning("⚠️ QuickStartView: Quick Start challenge not found, navigating to challenge list")
                    isCreating = false
                    withAnimation {
                        showQuickStart = false
                    }
                }
            }
        }
    }
}
