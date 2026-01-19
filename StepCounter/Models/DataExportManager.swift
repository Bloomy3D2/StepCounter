//
//  DataExportManager.swift
//  StepCounter
//
//  Менеджер экспорта данных (CSV, PDF) - Premium функция
//

import Foundation
import SwiftUI

/// Ошибки экспорта данных
enum DataExportError: LocalizedError {
    case premiumRequired
    case dateCalculationFailed
    case csvGenerationFailed
    case fileCreationFailed
    case dataGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .premiumRequired:
            return "Экспорт данных доступен только для Premium пользователей"
        case .dateCalculationFailed:
            return "Ошибка вычисления дат для экспорта"
        case .csvGenerationFailed:
            return "Ошибка генерации CSV файла"
        case .fileCreationFailed:
            return "Не удалось создать файл для экспорта"
        case .dataGenerationFailed:
            return "Не удалось сгенерировать данные для экспорта"
        }
    }
}

/// Менеджер экспорта данных
@MainActor
final class DataExportManager: ObservableObject {
    static let shared = DataExportManager()
    
    private let subscriptionManager = SubscriptionManager.shared
    
    private init() {}
    
    /// Экспорт с использованием HealthManager
    func exportToCSV(healthManager: HealthManager, completion: @escaping (Result<URL, Error>) -> Void) {
        // Проверка Premium
        guard subscriptionManager.hasAccess(to: .exportData) else {
            completion(.failure(DataExportError.premiumRequired))
            return
        }
        
        Task {
            do {
                let csvContent = try generateCSVContent(healthManager: healthManager)
                let url = try saveToFile(content: csvContent, extension: "csv")
                completion(.success(url))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Экспорт в PDF с использованием HealthManager
    func exportToPDF(healthManager: HealthManager, completion: @escaping (Result<URL, Error>) -> Void) {
        // Проверка Premium
        guard subscriptionManager.hasAccess(to: .exportData) else {
            completion(.failure(DataExportError.premiumRequired))
            return
        }
        
        Task {
            do {
                let pdfData = try generatePDFContent(healthManager: healthManager)
                let url = try saveToFile(data: pdfData, extension: "pdf")
                completion(.success(url))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - CSV Generation
    
    private func generateCSVContent(healthManager: HealthManager) throws -> String {
        var csv = "Дата,Шаги,Дистанция (м),Калории,Активность (мин)\n"
        
        // Экспортируем данные за последние 365 дней
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -365, to: endDate) else {
            throw DataExportError.dateCalculationFailed
        }
        
        // Формируем CSV из weeklySteps и monthlySteps
        var date = startDate
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        while date <= endDate {
            let dayData = healthManager.weeklySteps.first { calendar.isDate($0.date, inSameDayAs: date) }
            
            let steps = dayData?.steps ?? 0
            let distance = Double(steps) * 0.75 // Примерный расчет (1 шаг ≈ 0.75 метра)
            let calories = Double(steps) * 0.04 // Примерный расчет
            let activeMinutes = max(0, steps / 100) // Примерный расчет
            
            csv += "\(formatter.string(from: date)),\(steps),\(Int(distance)),\(Int(calories)),\(activeMinutes)\n"
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = nextDate
        }
        
        return csv
    }
    
    // MARK: - PDF Generation
    
    private func generatePDFContent(healthManager: HealthManager) throws -> Data {
        // Простой PDF через UIGraphics
        let pdfMetaData = [
            kCGPDFContextCreator: "StepCounter App",
            kCGPDFContextAuthor: "StepCounter",
            kCGPDFContextTitle: "Отчет по шагам"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 72.0
            
            // Заголовок
            let title = "Отчет по шагам"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            let titleSize = title.size(withAttributes: titleAttributes)
            title.draw(at: CGPoint(x: (pageWidth - titleSize.width) / 2, y: yPosition), withAttributes: titleAttributes)
            yPosition += titleSize.height + 40
            
            // Статистика
            let totalSteps = healthManager.weeklySteps.reduce(0) { $0 + $1.steps }
            let avgSteps = healthManager.weeklySteps.isEmpty ? 0 : totalSteps / healthManager.weeklySteps.count
            
            let stats = [
                "Всего шагов: \(totalSteps)",
                "Среднее за день: \(avgSteps)",
                "Цель: \(healthManager.stepGoal) шагов"
            ]
            
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            
            for stat in stats {
                stat.draw(at: CGPoint(x: 72, y: yPosition), withAttributes: textAttributes)
                yPosition += 24
            }
        }
        
        return data
    }
    
    // MARK: - File Saving
    
    private func saveToFile(content: String, extension ext: String) throws -> URL {
        let fileName = "stepcounter_export_\(Date().timeIntervalSince1970).\(ext)"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    private func saveToFile(data: Data, extension ext: String) throws -> URL {
        let fileName = "stepcounter_export_\(Date().timeIntervalSince1970).\(ext)"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try data.write(to: fileURL)
        return fileURL
    }
}
