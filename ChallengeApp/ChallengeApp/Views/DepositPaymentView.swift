//
//  DepositPaymentView.swift
//  ChallengeApp
//
//  Экран оплаты для пополнения баланса
//

import SwiftUI
import UIKit

struct DepositPaymentView: View {
    let amount: Double
    var receiptEmail: String
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @StateObject private var paymentManager = PaymentManager(
        yooKassaClient: DIContainer.shared.yooKassaClient
    )
    @State private var agreedToTerms = true
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isPaymentInProgress = false
    @State private var currentPaymentId: String? = nil
    @State private var isFinalizingDeposit = false
    
    private let currentDepositPaymentIdKey = "currentDepositPaymentId"
    private let currentDepositPaymentAmountKey = "currentDepositPaymentAmount"
        
    private var payButtonText: String {
        String(format: "payment.pay_card".localized, String(format: "%.0f ₽", amount))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Информация о пополнении
                        VStack(spacing: 16) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                            
                            Text("profile.deposit_balance".localized)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        
                        // Сумма к оплате
                        VStack(spacing: 8) {
                            Text("payment.amount_to_pay".localized)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(String(format: "%.0f ₽", amount))
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        // Email для чека
                        VStack(alignment: .leading, spacing: 8) {
                            Text("payment.receipt_email".localized)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            TextField("example@mail.com", text: .constant(receiptEmail))
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                                .disabled(true)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 20)
                        
                        // Кнопка оплаты
                        Button(action: {
                            Task {
                                await processPayment()
                            }
                        }) {
                            if isPaymentInProgress {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(Color.white.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                Text(payButtonText)
                                    .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(agreedToTerms ? Color.white : Color.white.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .disabled(!agreedToTerms || isPaymentInProgress)
                        .padding(.horizontal, 20)
                        
                        Spacer()
                            .frame(height: 50)
                    }
                }
            }
            .navigationTitle("payment.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .disabled(isPaymentInProgress)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PaymentReturned"))) { notification in
                let paymentId = notification.userInfo?["payment_id"] as? String
                Task { await handlePaymentReturn(paymentIdFromURL: paymentId) }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AppEnteredForeground"))) { _ in
                Task { await handlePaymentReturn(paymentIdFromURL: nil) }
            }
            .task {
                // Восстанавливаем paymentId после возврата из Safari, если нужно
                if currentPaymentId == nil {
                    let saved = UserDefaults.standard.string(forKey: currentDepositPaymentIdKey)
                    if let saved, !saved.isEmpty {
                        currentPaymentId = saved
                        await handlePaymentReturn(paymentIdFromURL: saved)
                    }
                }
            }
            .alert("error.title".localized, isPresented: $showingError) {
                Button("common.ok".localized, role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("payment.excellent".localized, isPresented: $showingSuccess) {
                Button("common.ok".localized) {
                    dismiss()
                }
            } message: {
                Text(String(format: "profile.deposit_success_amount".localized, String(format: "%.0f", amount)))
            }
        }
    }
    
    private func processPayment() async {
        guard let userId = appState.currentUser?.id else {
            await MainActor.run {
                errorMessage = "error.auth_required".localized
                showingError = true
            }
            return
        }
        
        await AnalyticsManager.shared.track(
            "deposit_attempt",
            amount: amount,
            props: ["has_email": receiptEmail.isEmpty ? "0" : "1"]
        )
        
        guard receiptEmail.isValidEmail else {
            await MainActor.run {
                errorMessage = "payment.email_invalid".localized
                showingError = true
            }
            return
        }
        
        await MainActor.run {
            isPaymentInProgress = true
        }
        
        do {
            // Не зачисляем баланс на кнопку "Оплатить".
            // Баланс пополняется только после подтверждённого платежа (status=SUCCEEDED).
            let shopId = AppConfig.yooKassaShopId
            let secretKey = AppConfig.yooKassaSecretKey
            let isConfigured = !shopId.isEmpty && !secretKey.isEmpty && shopId != "YOUR_SHOP_ID" && secretKey != "YOUR_SECRET_KEY"
            guard isConfigured else {
                await MainActor.run {
                    isPaymentInProgress = false
                    errorMessage = "Оплата YooKassa не настроена. Проверь Shop ID / Secret Key."
                    showingError = true
                }
                return
            }
            
            let yooKassaClient = DIContainer.shared.yooKassaClient
            let returnUrl = AppConfig.paymentReturnURL
            let metadata = [
                "type": "deposit",
                "user_id": userId
            ]
            
            // Для пополнения делаем как при вступлении в челлендж: редирект в UI YooKassa.
            // paymentMethod не фиксируем — пользователь выберет способ оплаты в YooKassa UI.
            let payment = try await yooKassaClient.createPayment(
                amount: amount,
                description: "Пополнение баланса",
                returnUrl: returnUrl,
                metadata: metadata,
                paymentMethod: nil,
                receiptEmail: receiptEmail.isEmpty ? nil : receiptEmail
            )
            
            await AnalyticsManager.shared.track(
                "deposit_payment_created",
                amount: amount,
                props: ["payment_id": payment.id]
            )
            
            currentPaymentId = payment.id
            UserDefaults.standard.set(payment.id, forKey: currentDepositPaymentIdKey)
            UserDefaults.standard.set(amount, forKey: currentDepositPaymentAmountKey)
            
            if let confirmationUrlString = payment.confirmation?.confirmationUrl,
               let confirmationUrl = URL(string: confirmationUrlString) {
                await MainActor.run {
                    UIApplication.shared.open(confirmationUrl) { success in
                        if !success {
                            self.errorMessage = "Не удалось открыть страницу оплаты"
                            self.showingError = true
                            self.isPaymentInProgress = false
                        }
                    }
                }
            } else {
                await MainActor.run {
                    errorMessage = "Не удалось получить ссылку для оплаты"
                    showingError = true
                    isPaymentInProgress = false
                }
            }
        } catch {
            await AnalyticsManager.shared.track(
                "deposit_create_failed",
                amount: amount,
                props: ["error": error.localizedDescription]
            )
            await MainActor.run {
                isPaymentInProgress = false
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    /// Обработка возврата из YooKassa: проверяем статус платежа и, если он успешный,
    /// пополняем баланс через Supabase.
    private func handlePaymentReturn(paymentIdFromURL: String?) async {
        // Если payment_id пришел в URL — используем его
        if let paymentIdFromURL, !paymentIdFromURL.isEmpty {
            currentPaymentId = paymentIdFromURL
            UserDefaults.standard.set(paymentIdFromURL, forKey: currentDepositPaymentIdKey)
        }
        
        guard !isFinalizingDeposit else { return }
        
        let paymentId: String? = currentPaymentId ?? UserDefaults.standard.string(forKey: currentDepositPaymentIdKey)
        guard let paymentId, !paymentId.isEmpty else { return }
        
        do {
            let payment = try await DIContainer.shared.yooKassaClient.getPayment(paymentId: paymentId)
            
            if payment.status == .succeeded || payment.paid {
                isFinalizingDeposit = true
                do {
                    // Безопасно берём сумму и тип из YooKassa, чтобы:
                    // - не зачислить "любую" сумму из UI
                    // - не зачислить повторно старый paymentId с другим экраном
                    let paymentType = payment.metadata?["type"]
                    let paymentUserId = payment.metadata?["user_id"]
                    if paymentType != "deposit" {
                        throw AppError.invalidData("Неверный тип платежа")
                    }
                    if let paymentUserId, let currentUserId = appState.currentUser?.id, paymentUserId != currentUserId {
                        throw AppError.invalidData("Платёж принадлежит другому пользователю")
                    }
                    
                    let ykAmount = Double(payment.amount.value) ?? UserDefaults.standard.double(forKey: currentDepositPaymentAmountKey)
                    guard ykAmount > 0 else {
                        throw AppError.invalidData("Не удалось определить сумму платежа")
                    }
                    
                    try await SupabaseManager.shared.depositBalance(amount: ykAmount)
                    await appState.refreshUser()
                    
                    await AnalyticsManager.shared.track(
                        "deposit_success",
                        amount: ykAmount,
                        props: ["payment_id": paymentId]
                    )
                    
                    await MainActor.run {
                        isPaymentInProgress = false
                        showingSuccess = true
                    }
                } catch {
                    await AnalyticsManager.shared.track(
                        "deposit_finalize_failed",
                        amount: amount,
                        props: ["payment_id": paymentId, "error": error.localizedDescription]
                    )
                    await MainActor.run {
                        isPaymentInProgress = false
                        errorMessage = "Оплата прошла успешно, но не удалось пополнить баланс. Попробуйте обновить профиль или обратитесь в поддержку."
                        showingError = true
                    }
                }
                
                UserDefaults.standard.removeObject(forKey: currentDepositPaymentIdKey)
                UserDefaults.standard.removeObject(forKey: currentDepositPaymentAmountKey)
                currentPaymentId = nil
            } else if payment.status == .canceled {
                await AnalyticsManager.shared.track(
                    "deposit_canceled",
                    amount: amount,
                    props: ["payment_id": paymentId]
                )
                await MainActor.run {
                    isPaymentInProgress = false
                    errorMessage = "Платёж был отменён."
                    showingError = true
                }
                UserDefaults.standard.removeObject(forKey: currentDepositPaymentIdKey)
                UserDefaults.standard.removeObject(forKey: currentDepositPaymentAmountKey)
                currentPaymentId = nil
            } else {
                // pending / waiting_for_capture — остаёмся в ожидании, повторно проверим при следующем возврате/foreground
            }
        } catch {
            // Не роняем UX: статус мог не успеть обновиться — попробуем позже
            Logger.shared.warning("DepositPaymentView: Failed to check payment status", error: error)
        }
    }
}
