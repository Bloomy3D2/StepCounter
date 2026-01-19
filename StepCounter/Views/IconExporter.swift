//
//  IconExporter.swift
//  StepQuest
//
//  Вспомогательный view для экспорта иконки
//

import SwiftUI

struct IconExporterView: View {
    @State private var showingExportAlert = false
    @State private var exportMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Text("StepQuest Icon Exporter")
                .font(.title.bold())
            
            Text("Используйте этот инструмент для экспорта иконки")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Превью всех размеров
            ScrollView {
                VStack(spacing: 30) {
                    ForEach([1024, 180, 167, 152, 120, 76], id: \.self) { size in
                        VStack(spacing: 12) {
                            StepQuestIconView(size: CGFloat(size))
                                .frame(width: min(200, CGFloat(size) * 0.2), 
                                       height: min(200, CGFloat(size) * 0.2))
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                            
                            Text("\(size)×\(size)")
                                .font(.headline)
                            
                            Text(getSizeDescription(size))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                exportIcon(size: size)
                            }) {
                                Label("Экспортировать", systemImage: "square.and.arrow.down")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                    }
                }
                .padding()
            }
            
            Text("💡 Совет: Используйте скриншот или инструменты экспорта для сохранения PNG")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        }
        .padding()
        .alert("Экспорт", isPresented: $showingExportAlert) {
            Button("OK") { }
        } message: {
            Text(exportMessage)
        }
    }
    
    private func getSizeDescription(_ size: Int) -> String {
        switch size {
        case 1024: return "App Store"
        case 180: return "iPhone (3x)"
        case 167: return "iPad Pro (2x)"
        case 152: return "iPad (2x)"
        case 120: return "iPhone (2x)"
        case 76: return "iPad (1x)"
        default: return ""
        }
    }
    
    private func exportIcon(size: Int) {
        // В реальном приложении здесь был бы код экспорта
        // Для экспорта используйте скриншот или сторонние инструменты
        exportMessage = "Для экспорта \(size)×\(size) используйте:\n1. Скриншот этого preview\n2. Онлайн инструменты (icon.kitchen)\n3. Или экспорт через Xcode"
        showingExportAlert = true
    }
}

#Preview {
    IconExporterView()
}
