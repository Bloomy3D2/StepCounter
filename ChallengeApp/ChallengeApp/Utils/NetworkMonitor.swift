//
//  NetworkMonitor.swift
//  ChallengeApp
//
//  Мониторинг состояния сети и автоматическая синхронизация при восстановлении
//

import Foundation
import Network
import Combine

/// Монитор состояния сети для автоматической синхронизации данных
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType?
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var wasDisconnected = false
    
    private init() {
        startMonitoring()
    }
    
    /// Начать мониторинг сети
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self = self else { return }
                
                let wasConnected = self.isConnected
                self.isConnected = path.status == .satisfied
                self.connectionType = path.availableInterfaces.first?.type
                
                Logger.shared.info("🌐 NetworkMonitor: Connection status changed - isConnected=\(self.isConnected), type=\(self.connectionType?.description ?? "unknown")")
                
                // Если сеть восстановилась после отключения, синхронизируем данные
                if !wasConnected && self.isConnected {
                    Logger.shared.info("🌐 NetworkMonitor: Network restored - triggering sync")
                    self.wasDisconnected = true
                    await self.syncOnReconnect()
                } else if !self.isConnected {
                    self.wasDisconnected = true
                    Logger.shared.warning("🌐 NetworkMonitor: Network disconnected")
                }
            }
        }
        
        monitor.start(queue: queue)
        Logger.shared.info("🌐 NetworkMonitor: Started monitoring network status")
    }
    
    /// Синхронизация данных при восстановлении сети
    private func syncOnReconnect() async {
        guard isConnected else { return }
        
        Logger.shared.info("🔄 NetworkMonitor: Syncing data after network reconnect")
        
        // Небольшая задержка, чтобы сеть стабилизировалась
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 секунда
        
        // Обновляем критичные данные
        let challengeManager = DIContainer.shared.challengeManager
        await challengeManager.loadUserChallengesFromSupabase(forceRefresh: true)
        await challengeManager.loadChallengesFromSupabase(forceRefresh: false)
        
        // Уведомляем о необходимости обновить данные пользователя
        // AppState будет обновлен через RootView при получении уведомления
        NotificationCenter.default.post(
            name: NSNotification.Name("NetworkReconnected"),
            object: nil
        )
        
        Logger.shared.info("✅ NetworkMonitor: Data sync completed after reconnect")
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Extensions

extension NWInterface.InterfaceType {
    var description: String {
        switch self {
        case .wifi: return "WiFi"
        case .cellular: return "Cellular"
        case .wiredEthernet: return "Ethernet"
        case .loopback: return "Loopback"
        case .other: return "Other"
        @unknown default: return "Unknown"
        }
    }
}
