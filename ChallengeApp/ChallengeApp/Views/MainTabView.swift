//
//  MainTabView.swift
//  ChallengeApp
//
//  Главный TabView с навигацией
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var challengeManager: ChallengeManager
    @State private var selectedTab = 0
    
    // Для свайпов между табами
    private func handleSwipe(_ direction: SwipeDirection) {
        switch direction {
        case .left:
            if selectedTab < 3 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTab += 1
                }
            }
        case .right:
            if selectedTab > 0 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTab -= 1
                }
            }
        }
    }
    
    enum SwipeDirection {
        case left, right
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChallengesListView()
                .environmentObject(appState)
                .environmentObject(challengeManager)
                .tabItem {
                    Label("nav.challenges".localized, systemImage: "flame.fill")
                }
                .tag(0)
            
            // Мой прогресс = текущий челлендж (выполнить/провалить). По бизнес-плану: «Активный челлендж — основной экран для отслеживания прогресса».
            NavigationView {
                ActiveChallengeView()
            }
            .environmentObject(challengeManager)
            .environmentObject(appState)
            .tabItem {
                Label("nav.my_progress".localized, systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(1)
            
            // Создать (disabled)
            ZStack {
                Color.black
                    .ignoresSafeArea(.container, edges: [.top])
                Text("common.coming_soon".localized)
                    .foregroundColor(.white)
            }
            .tabItem {
                Label("nav.create".localized, systemImage: "plus.circle")
            }
            .tag(2)
            
            // История = статистика и список всех челленджей. По README: «Мой прогресс — статистика и история челленджей» — это история участий.
            MyProgressView()
                .environmentObject(appState)
                .environmentObject(challengeManager)
                .tabItem {
                    Label("nav.history".localized, systemImage: "clock.fill")
                }
                .tag(3)
        }
        .accentColor(.white)
        .task {
            await AnalyticsManager.shared.trackSessionStartIfNeeded()
            await AnalyticsManager.shared.track("main_tab_open", props: ["tab": "\(selectedTab)"])
        }
        .onChange(of: selectedTab) { _, newValue in
            Task {
                await AnalyticsManager.shared.track("tab_changed", props: ["tab": "\(newValue)"])
            }
        }
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = abs(value.translation.height)
                    
                    // Проверяем, что свайп горизонтальный и достаточно сильный
                    if abs(horizontalAmount) > verticalAmount && abs(horizontalAmount) > 50 {
                        if horizontalAmount > 0 {
                            // Свайп вправо - предыдущий таб
                            handleSwipe(.right)
                        } else {
                            // Свайп влево - следующий таб
                            handleSwipe(.left)
                        }
                    }
                }
        )
    }
}
