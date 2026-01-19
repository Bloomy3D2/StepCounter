//
//  OrbitMatchApp.swift
//  OrbitMatch
//
//  Орбитальный пазл: лови момент, когда блоки выстраиваются
//

import SwiftUI

@main
struct OrbitMatchApp: App {
    @StateObject private var gameManager = GameManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameManager)
        }
    }
}
