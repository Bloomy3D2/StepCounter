//
//  TemperatureTilesApp.swift
//  TemperatureTiles
//
//  Пазл с температурой: горячее и холодное взаимодействуют
//

import SwiftUI

@main
struct TemperatureTilesApp: App {
    @StateObject private var gameManager = GameManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameManager)
        }
    }
}
