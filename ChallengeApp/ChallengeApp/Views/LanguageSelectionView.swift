//
//  LanguageSelectionView.swift
//  ChallengeApp
//
//  Экран выбора языка приложения
//

import SwiftUI

struct LanguageSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Заголовок
                        VStack(spacing: 8) {
                            Text("language.select".localized)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("language.select_interface".localized)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 20)
                        
                        // Список языков
                        VStack(spacing: 12) {
                            ForEach(AppLanguage.allCases) { language in
                                LanguageRow(
                                    language: language,
                                    isSelected: languageManager.currentLanguage == language
                                ) {
                                    languageManager.setLanguage(language)
                                    dismiss()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("language.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Language Row

struct LanguageRow: View {
    let language: AppLanguage
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Флаг/Иконка языка
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.green.opacity(0.2) : Color.white.opacity(0.05))
                        .frame(width: 50, height: 50)
                    
                    Text(languageFlag(language))
                        .font(.system(size: 24))
                }
                
                // Название языка
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.nativeDisplayName)
                        .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(.white)
                    
                    Text(language.displayName)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Индикатор выбора
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func languageFlag(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "🇷🇺"
        case .english:
            return "🇺🇸"
        case .chinese:
            return "🇨🇳"
        }
    }
}
