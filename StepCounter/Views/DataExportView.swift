//
//  DataExportView.swift
//  StepCounter
//
//  Экспорт данных пользователя
//

import SwiftUI

struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var healthManager: HealthManager
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    @State private var showExportSuccess = false
    @State private var showExportError = false
    @State private var errorMessage = ""
    
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Информация
                    infoCard
                    
                    // Форматы экспорта
                    exportFormatsCard
                    
                    // Прогресс (если экспортируется)
                    if isExporting {
                        progressCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .ignoresSafeArea()
            )
            .navigationTitle("Экспорт данных")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert("Экспорт завершён", isPresented: $showExportSuccess) {
                Button("ОК") {}
            } message: {
                Text("Данные успешно экспортированы")
            }
            .alert("Ошибка экспорта", isPresented: $showExportError) {
                Button("ОК") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var infoCard: some View {
        GlassCard(cornerRadius: 20, padding: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                    
                    Text("Информация")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("Вы можете экспортировать все свои данные в различных форматах. Данные будут сохранены локально на вашем устройстве.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private var exportFormatsCard: some View {
        GlassCard(cornerRadius: 20, padding: 0) {
            VStack(spacing: 0) {
                // CSV
                exportFormatRow(
                    icon: "doc.text.fill",
                    title: "CSV",
                    subtitle: "Табличный формат для Excel",
                    color: .green
                ) {
                    exportData(format: .csv)
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // PDF
                exportFormatRow(
                    icon: "doc.fill",
                    title: "PDF",
                    subtitle: "Документ для печати",
                    color: .red
                ) {
                    exportData(format: .pdf)
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // JSON
                exportFormatRow(
                    icon: "curlybraces",
                    title: "JSON",
                    subtitle: "Структурированные данные",
                    color: .blue
                ) {
                    exportData(format: .json)
                }
            }
        }
    }
    
    private func exportFormatRow(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.impact(style: .light)
            action()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(accentGreen)
            }
            .padding(20)
        }
        .disabled(isExporting)
    }
    
    private var progressCard: some View {
        GlassCard(cornerRadius: 20, padding: 20) {
            VStack(spacing: 16) {
                Text("Экспорт данных...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                ProgressView(value: exportProgress)
                    .tint(accentGreen)
                    .progressViewStyle(.linear)
                
                Text("\(Int(exportProgress * 100))%")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private func exportData(format: ExportFormat) {
        isExporting = true
        exportProgress = 0
        
        Task {
            do {
                // Симуляция прогресса
                for i in 1...10 {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 секунды
                    await MainActor.run {
                        exportProgress = Double(i) / 10.0
                    }
                }
                
                // Здесь будет реальный экспорт через DataExportManager
                // Пока заглушка - нужно реализовать методы экспорта
                let dataExportManager = DataExportManager.shared
                // let url = try await dataExportManager.exportToCSV(...)
                
                await MainActor.run {
                    isExporting = false
                    exportProgress = 0
                    showExportSuccess = true
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportProgress = 0
                    errorMessage = error.localizedDescription
                    showExportError = true
                }
            }
        }
    }
    
    enum ExportFormat {
        case csv
        case pdf
        case json
    }
}
