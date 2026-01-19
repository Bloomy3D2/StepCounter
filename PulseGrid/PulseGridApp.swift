//
//  PulseGridApp.swift
//  PulseGrid
//
//  Ритмический пазл: соединяй блоки в одной фазе пульса
//

import SwiftUI

@main
struct PulseGridApp: App {
    @StateObject private var gameManager = GameManager()
    @StateObject private var audioManager = AudioManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameManager)
                .environmentObject(audioManager)
        }
    }
}
