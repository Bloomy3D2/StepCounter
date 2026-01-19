//
//  NegativeSpaceApp.swift
//  NegativeSpace
//
//  Пазл-игра: заполни пустоту правильными блоками
//

import SwiftUI

@main
struct NegativeSpaceApp: App {
    @StateObject private var gameManager = GameManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameManager)
        }
    }
}
