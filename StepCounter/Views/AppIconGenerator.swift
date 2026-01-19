//
//  AppIconGenerator.swift
//  StepCounter
//
//  Генератор иконки приложения
//

import SwiftUI

struct AppIconView: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Фон с градиентом
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.5, blue: 1.0),  // Синий
                            Color(red: 0.3, green: 0.85, blue: 0.5), // Зелёный
                            Color(red: 0.4, green: 0.7, blue: 0.9)   // Голубой
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: size * 0.05, x: 0, y: size * 0.02)
            
            // Декоративные элементы фона
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: size * 0.6, height: size * 0.6)
                .offset(x: -size * 0.15, y: -size * 0.15)
            
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: size * 0.4, height: size * 0.4)
                .offset(x: size * 0.2, y: size * 0.2)
            
            // Основная фигура - идущий человек
            ZStack {
                // Тело
                Capsule()
                    .fill(Color.white)
                    .frame(width: size * 0.12, height: size * 0.35)
                    .offset(y: size * 0.05)
                
                // Голова
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.18, height: size * 0.18)
                    .offset(y: -size * 0.2)
                
                // Ноги (в движении)
                // Левая нога
                Capsule()
                    .fill(Color.white)
                    .frame(width: size * 0.08, height: size * 0.25)
                    .rotationEffect(.degrees(-25))
                    .offset(x: -size * 0.08, y: size * 0.25)
                
                // Правая нога
                Capsule()
                    .fill(Color.white)
                    .frame(width: size * 0.08, height: size * 0.25)
                    .rotationEffect(.degrees(25))
                    .offset(x: size * 0.08, y: size * 0.25)
                
                // Руки
                // Левая рука
                Capsule()
                    .fill(Color.white)
                    .frame(width: size * 0.08, height: size * 0.2)
                    .rotationEffect(.degrees(45))
                    .offset(x: -size * 0.12, y: size * 0.05)
                
                // Правая рука
                Capsule()
                    .fill(Color.white)
                    .frame(width: size * 0.08, height: size * 0.2)
                    .rotationEffect(.degrees(-45))
                    .offset(x: size * 0.12, y: size * 0.05)
            }
            
            // Следы под ногами (для динамики)
            HStack(spacing: size * 0.15) {
                // Левый след
                Image(systemName: "pawprint.fill")
                    .font(.system(size: size * 0.12))
                    .foregroundColor(Color.white.opacity(0.6))
                    .offset(x: -size * 0.15, y: size * 0.4)
                
                // Правый след
                Image(systemName: "pawprint.fill")
                    .font(.system(size: size * 0.12))
                    .foregroundColor(Color.white.opacity(0.4))
                    .offset(x: size * 0.15, y: size * 0.45)
            }
            
            // Акцент - шаги (цифры)
            Text("10K")
                .font(.system(size: size * 0.15, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .offset(y: size * 0.35)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview для генерации иконки

struct AppIconPreview: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("Иконка приложения StepCounter")
                .font(.title)
                .padding()
            
            HStack(spacing: 40) {
                // Размеры для разных устройств
                VStack {
                    AppIconView(size: 1024)
                        .frame(width: 200, height: 200)
                    Text("1024x1024")
                        .font(.caption)
                }
                
                VStack {
                    AppIconView(size: 180)
                        .frame(width: 90, height: 90)
                    Text("180x180")
                        .font(.caption)
                }
                
                VStack {
                    AppIconView(size: 120)
                        .frame(width: 60, height: 60)
                    Text("120x120")
                        .font(.caption)
                }
            }
            
            Text("Используйте этот preview для экспорта иконки")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        }
        .padding()
    }
}

#Preview {
    AppIconPreview()
}
