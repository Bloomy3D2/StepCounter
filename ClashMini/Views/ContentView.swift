//
//  ContentView.swift
//  ClashMini
//
//  Корневой View приложения
//

import SwiftUI

struct ContentView: View {
    @StateObject private var gameModel = GameModel()
    
    var body: some View {
        ZStack {
            switch gameModel.phase {
            case .menu:
                MainMenuView(gameModel: gameModel)
                    .transition(.opacity)
                
            case .playing, .paused, .victory, .defeat:
                GameView(gameModel: gameModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: gameModel.phase == .menu)
    }
}

#Preview {
    ContentView()
}
