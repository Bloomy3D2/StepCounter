//
//  PrivacyConsentView.swift
//  StepCounter
//
//  Экран согласия на обработку персональных данных (первый запуск)
//

import SwiftUI

struct PrivacyConsentView: View {
    @StateObject private var consentManager = PrivacyConsentManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var showPrivacyPolicy = false
    @Binding var hasConsent: Bool
    
    private let accentGreen = Color(red: 0.3, green: 0.85, blue: 0.5)
    
    var body: some View {
        ZStack {
            // Фон с темой
            AnimatedGradientBackground(theme: themeManager.currentTheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Иконка
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [accentGreen.opacity(0.5), .clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                        
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 50))
                            .foregroundColor(accentGreen)
                    }
                    .padding(.top, 60)
                    
                    // Заголовок
                    VStack(spacing: 12) {
                        Text("Добро пожаловать в StepCounter!")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Для работы приложения нам нужно ваше согласие на обработку персональных данных")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Информация о данных
                    VStack(alignment: .leading, spacing: 20) {
                        DataUsageRow(
                            icon: "heart.fill",
                            title: "Данные о здоровье",
                            description: "Шаги, дистанция, калории из Apple Health",
                            color: .red
                        )
                        
                        DataUsageRow(
                            icon: "location.fill",
                            title: "Геолокация",
                            description: "Только для записи маршрутов прогулок",
                            color: .blue
                        )
                        
                        DataUsageRow(
                            icon: "person.fill",
                            title: "Данные аккаунта",
                            description: "User ID, email (опционально) через Sign in with Apple",
                            color: .purple
                        )
                        
                        DataUsageRow(
                            icon: "lock.shield.fill",
                            title: "Безопасность",
                            description: "Все данные хранятся локально на вашем устройстве",
                            color: accentGreen
                        )
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.3), .white.opacity(0.1), .clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                    )
                    .padding(.horizontal, 20)
                    
                    // Важная информация
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 20))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Важно знать")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("• Все данные хранятся только на вашем устройстве\n• Мы не передаем данные третьим лицам\n• Вы можете отозвать согласие в любой момент в настройках")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    
                    // Политика конфиденциальности
                    Button {
                        showPrivacyPolicy = true
                    } label: {
                        HStack(spacing: 8) {
                            Text("Политика конфиденциальности")
                                .font(.system(size: 15, weight: .medium))
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(accentGreen)
                    }
                    .padding(.top, 8)
                    
                    // Кнопки действий
                    VStack(spacing: 16) {
                        // Согласие
                        Button {
                            consentManager.giveConsent()
                            consentManager.markOnboardingSeen()
                            hasConsent = true
                            HapticManager.notification(.success)
                        } label: {
                            Text("Согласен и продолжить")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [accentGreen, accentGreen.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 20)
                        
                        // Отказ
                        Button {
                            // При отказе показываем предупреждение
                            showDeclineAlert = true
                        } label: {
                            Text("Отказаться")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyWebView()
        }
        .alert("Отказ от согласия", isPresented: $showDeclineAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Понятно", role: .destructive) {
                // При отказе ограничиваем функциональность
                // Отзываем согласие и отмечаем, что onboarding был просмотрен
                consentManager.revokeConsent()
                consentManager.markOnboardingSeen()
                // Обновляем binding для закрытия экрана
                hasConsent = false
                HapticManager.notification(.warning)
                
                // Небольшая задержка для плавного перехода
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // Принудительно обновляем состояние для закрытия экрана
                    consentManager.objectWillChange.send()
                }
            }
        } message: {
            Text("Без согласия некоторые функции приложения будут недоступны:\n\n• Запись GPS-маршрутов\n• Доступ к данным Apple Health\n• Синхронизация данных\n\nВы сможете дать согласие позже в настройках.")
        }
    }
    
    @State private var showDeclineAlert = false
}

// MARK: - Data Usage Row

struct DataUsageRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
    }
}

// MARK: - Privacy Policy Web View

struct PrivacyPolicyWebView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            WebView(url: URL(string: AppConstants.URLs.privacyPolicy) ?? URL(string: "about:blank")!)
                .navigationTitle("Политика конфиденциальности")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Готово") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - Web View

import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if url.scheme == "file" {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            webView.load(URLRequest(url: url))
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            // Если файл не найден, показываем встроенный текст
            if let url = webView.url, url.scheme == "file" {
                let htmlContent = """
                <html>
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <style>
                        body { font-family: -apple-system; padding: 20px; line-height: 1.6; }
                        h1 { color: #2c3e50; }
                        h2 { color: #34495e; margin-top: 30px; }
                    </style>
                </head>
                <body>
                    <h1>Политика конфиденциальности</h1>
                    <p>Полная версия политики конфиденциальности доступна в файле PrivacyPolicy.html в проекте.</p>
                    <p>Для публикации приложения разместите этот файл на вашем сайте или GitHub Pages и укажите URL в App Store Connect.</p>
                </body>
                </html>
                """
                webView.loadHTMLString(htmlContent, baseURL: nil)
            }
        }
    }
}

#Preview {
    PrivacyConsentView(hasConsent: .constant(false))
}
