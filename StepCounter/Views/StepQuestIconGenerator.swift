//
//  StepQuestIconGenerator.swift
//  StepQuest
//
//  Генератор уникальной иконки для StepQuest: Шагомер
//  Дизайн: комбинация шагов и квеста (геймификация)
//

import SwiftUI

struct StepQuestIconView: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Фон с динамичным градиентом (энергия движения)
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.3, blue: 0.9),   // Яркий синий
                            Color(red: 0.4, green: 0.7, blue: 1.0),    // Светло-голубой
                            Color(red: 0.3, green: 0.85, blue: 0.5),   // Зелёный (успех)
                            Color(red: 0.9, green: 0.5, blue: 0.2)    // Оранжевый (энергия)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.25), radius: size * 0.06, x: 0, y: size * 0.03)
            
            // Декоративные световые эффекты (глубина)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size * 0.4
                    )
                )
                .frame(width: size * 0.7, height: size * 0.7)
                .offset(x: -size * 0.2, y: -size * 0.2)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        center: .bottomTrailing,
                        startRadius: 0,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size * 0.6, height: size * 0.6)
                .offset(x: size * 0.25, y: size * 0.25)
            
            // Основная композиция: идущий человек + значок квеста
            ZStack {
                // Идущий человек (стилизованный)
                ZStack {
                    // Голова
                    Circle()
                        .fill(Color.white)
                        .frame(width: size * 0.2, height: size * 0.2)
                        .shadow(color: .black.opacity(0.2), radius: size * 0.02, x: 0, y: size * 0.01)
                        .offset(y: -size * 0.22)
                    
                    // Тело
                    Capsule()
                        .fill(Color.white)
                        .frame(width: size * 0.14, height: size * 0.32)
                        .shadow(color: .black.opacity(0.15), radius: size * 0.02, x: 0, y: size * 0.01)
                        .offset(y: size * 0.05)
                    
                    // Ноги в движении (динамика)
                    // Левая нога (впереди)
                    Capsule()
                        .fill(Color.white)
                        .frame(width: size * 0.09, height: size * 0.24)
                        .rotationEffect(.degrees(-20))
                        .offset(x: -size * 0.09, y: size * 0.28)
                        .shadow(color: .black.opacity(0.15), radius: size * 0.015)
                    
                    // Правая нога (сзади)
                    Capsule()
                        .fill(Color.white)
                        .frame(width: size * 0.09, height: size * 0.22)
                        .rotationEffect(.degrees(15))
                        .offset(x: size * 0.09, y: size * 0.3)
                        .shadow(color: .black.opacity(0.15), radius: size * 0.015)
                    
                    // Руки в движении
                    // Левая рука (назад)
                    Capsule()
                        .fill(Color.white)
                        .frame(width: size * 0.09, height: size * 0.22)
                        .rotationEffect(.degrees(50))
                        .offset(x: -size * 0.13, y: size * 0.08)
                        .shadow(color: .black.opacity(0.1), radius: size * 0.01)
                    
                    // Правая рука (вперёд)
                    Capsule()
                        .fill(Color.white)
                        .frame(width: size * 0.09, height: size * 0.22)
                        .rotationEffect(.degrees(-50))
                        .offset(x: size * 0.13, y: size * 0.08)
                        .shadow(color: .black.opacity(0.1), radius: size * 0.01)
                }
                
                // Значок квеста (звезда/медаль) - геймификация
                ZStack {
                    // Внешнее свечение
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.yellow.opacity(0.4),
                                    Color.orange.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: size * 0.25
                            )
                        )
                        .frame(width: size * 0.5, height: size * 0.5)
                        .offset(x: size * 0.25, y: -size * 0.15)
                    
                    // Звезда квеста
                    Image(systemName: "star.fill")
                        .font(.system(size: size * 0.18, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.yellow,
                                    Color.orange
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .orange.opacity(0.5), radius: size * 0.03, x: 0, y: 0)
                        .offset(x: size * 0.25, y: -size * 0.15)
                    
                    // Маленькая звёздочка рядом (деталь)
                    Image(systemName: "sparkle")
                        .font(.system(size: size * 0.08))
                        .foregroundColor(.yellow.opacity(0.9))
                        .offset(x: size * 0.35, y: -size * 0.25)
                }
            }
            
            // Следы под ногами (динамика движения)
            HStack(spacing: size * 0.18) {
                // Левый след
                Image(systemName: "pawprint.fill")
                    .font(.system(size: size * 0.1))
                    .foregroundColor(Color.white.opacity(0.5))
                    .offset(x: -size * 0.18, y: size * 0.42)
                
                // Правый след (более прозрачный - дальше)
                Image(systemName: "pawprint.fill")
                    .font(.system(size: size * 0.08))
                    .foregroundColor(Color.white.opacity(0.3))
                    .offset(x: size * 0.18, y: size * 0.45)
            }
            
            // Акцентный элемент: число шагов (опционально, можно убрать для чистоты)
            // Оставляем минималистично - только визуальные элементы
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
    }
}

// MARK: - Preview для генерации иконки

struct StepQuestIconPreview: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("StepQuest: Шагомер")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .padding()
            
            Text("Уникальная иконка приложения")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 40) {
                // Размеры для разных устройств
                VStack(spacing: 12) {
                    StepQuestIconView(size: 1024)
                        .frame(width: 200, height: 200)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    Text("1024×1024")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("App Store")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 12) {
                    StepQuestIconView(size: 180)
                        .frame(width: 90, height: 90)
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                    Text("180×180")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("iPhone")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 12) {
                    StepQuestIconView(size: 120)
                        .frame(width: 60, height: 60)
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                    Text("120×120")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("iPhone")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            VStack(spacing: 8) {
                Text("💡 Инструкция по экспорту:")
                    .font(.headline)
                Text("1. Запустите этот preview в Xcode")
                    .font(.caption)
                Text("2. Сделайте скриншот каждого размера")
                    .font(.caption)
                Text("3. Или используйте инструменты для экспорта PNG")
                    .font(.caption)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
    }
}

#Preview {
    StepQuestIconPreview()
}
