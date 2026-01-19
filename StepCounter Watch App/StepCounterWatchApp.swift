//
//  StepCounterWatchApp.swift
//  StepCounter Watch App
//
//  Приложение шагомер для Apple Watch
//

import SwiftUI
import HealthKit

@main
struct StepCounterWatchApp: App {
    @StateObject private var watchHealthManager = WatchHealthManager()
    
    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(watchHealthManager)
                .onAppear {
                    watchHealthManager.requestAuthorization()
                }
        }
    }
}
