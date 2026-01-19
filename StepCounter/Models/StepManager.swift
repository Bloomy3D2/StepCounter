//
//  StepManager.swift
//  StepCounter
//
//  Real-time подсчёт шагов через CoreMotion
//

import Foundation
import CoreMotion
import Combine

/// Менеджер CoreMotion для real-time подсчёта
final class StepManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Шаги с начала сессии
    @Published var sessionSteps: Int = 0
    
    /// Активен ли подсчёт
    @Published var isTracking: Bool = false
    
    /// Темп (шагов в минуту)
    @Published var currentPace: Int = 0
    
    /// Каденс (шагов в минуту при ходьбе)
    @Published var cadence: Double = 0
    
    /// Floors climbed
    @Published var floorsClimbed: Int = 0
    
    // MARK: - Private Properties
    
    private let pedometer = CMPedometer()
    private let activityManager = CMMotionActivityManager()
    private var sessionStartDate: Date?
    
    // MARK: - Public Methods
    
    /// Начать отслеживание
    func startTracking() {
        guard CMPedometer.isStepCountingAvailable() else {
            print("Подсчёт шагов недоступен")
            return
        }
        
        sessionStartDate = Date()
        sessionSteps = 0
        isTracking = true
        
        // Начинаем обновления педометра
        pedometer.startUpdates(from: sessionStartDate!) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            
            DispatchQueue.main.async {
                self?.sessionSteps = data.numberOfSteps.intValue
                
                if let pace = data.currentPace?.doubleValue {
                    // pace в секундах на метр, конвертируем в шаги/мин
                    self?.currentPace = Int(60 / pace * 0.7) // примерная конверсия
                }
                
                if let cadence = data.currentCadence?.doubleValue {
                    self?.cadence = cadence * 60 // steps per second → per minute
                }
                
                if let floors = data.floorsAscended?.intValue {
                    self?.floorsClimbed = floors
                }
            }
        }
    }
    
    /// Остановить отслеживание
    func stopTracking() {
        pedometer.stopUpdates()
        isTracking = false
    }
    
    /// Проверить доступность
    static var isAvailable: Bool {
        CMPedometer.isStepCountingAvailable()
    }
    
    /// Проверить доступность каденса
    static var isCadenceAvailable: Bool {
        CMPedometer.isCadenceAvailable()
    }
    
    /// Проверить доступность этажей
    static var isFloorCountingAvailable: Bool {
        CMPedometer.isFloorCountingAvailable()
    }
}
