//
//  TimingConstants.swift
//  ChallengeApp
//
//  Константы для таймингов и задержек
//

import Foundation

/// Константы для таймингов операций
enum TimingConstants {
    /// Короткая задержка (0.5 секунды)
    /// Используется для небольших пауз между операциями
    static let shortDelay: TimeInterval = 0.5
    
    /// Стандартная задержка (2 секунды)
    /// Используется для симуляции операций и polling
    static let defaultDelay: TimeInterval = 2.0
    
    /// Максимальное количество попыток для polling платежей
    static let paymentPollingMaxAttempts = 30
    
    /// Задержка для симуляции платежа (2 секунды)
    static let paymentSimulationDelay: TimeInterval = 2.0
    
    /// Задержка для симуляции СБП платежа (5 секунд)
    static let sbpPaymentSimulationDelay: TimeInterval = 5.0
    
    /// Задержка для вывода средств (1 секунда)
    static let withdrawalSimulationDelay: TimeInterval = 1.0
}
