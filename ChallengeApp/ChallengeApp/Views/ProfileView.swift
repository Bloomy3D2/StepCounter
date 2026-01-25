//
//  ProfileView.swift
//  ChallengeApp
//
//  Профиль / Настройки
//

import SwiftUI
import Combine
import PhotosUI
import UIKit
import Supabase

@MainActor
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var challengeManager: ChallengeManager
    @Environment(\.dismiss) var dismiss
    @State private var showingDeposit = false
    @State private var showingWithdraw = false
    @State private var showingRules = false
    @State private var showingSupport = false
    @State private var showingDeleteAccount = false
    @State private var showingClearData = false
    @State private var showingLanguageSelection = false
    @State private var balanceStatus: BalanceStatus?
    @State private var currentTime = Date()
    @State private var pendingDepositCreatedAt: Date?
    @State private var transactions: [PaymentTransaction] = []
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var avatarImage: UIImage? = nil
    @State private var isUploadingAvatar = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        profileHeaderView
                        transactionHistorySection
                        profileActionsView
                    }
                }
            }
        .navigationTitle("nav.profile".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadBalanceStatus()
            await loadTransactions()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            // Обновляем только время для таймера (не загружаем статусы заново)
            currentTime = Date()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDataUpdated"))) { _ in
            // Обновляем данные пользователя при изменении честной серии
            Task {
                await appState.refreshUser()
            }
        }
        .onChange(of: appState.currentUser?.balance) { _, _ in
            Task {
                await loadBalanceStatus()
                await loadTransactions()
            }
        }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showingDeposit) {
                DepositView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showingWithdraw) {
                WithdrawView()
                    .environmentObject(appState)
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    await loadPhoto(from: newItem)
                }
            }
            .sheet(isPresented: $showingRules) {
                RulesView()
            }
            .sheet(isPresented: $showingSupport) {
                SupportView()
            }
            .sheet(isPresented: $showingLanguageSelection) {
                LanguageSelectionView()
            }
            .alert("alert.delete_account.title".localized, isPresented: $showingDeleteAccount) {
                Button("common.cancel".localized, role: .cancel) {}
                Button("common.delete".localized, role: .destructive) {
                    appState.logout()
                    dismiss()
                }
            } message: {
                Text("alert.delete_account.message".localized)
            }
            .alert("alert.clear_data.title".localized, isPresented: $showingClearData) {
                Button("common.cancel".localized, role: .cancel) {}
                Button("common.delete".localized, role: .destructive) {
                    Task {
                        await challengeManager.clearLocalData()
                        await MainActor.run {
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("alert.clear_data.message".localized)
            }
        }
    }
    
    // MARK: - Profile Header
    
    @ViewBuilder
    private var profileHeaderView: some View {
        // Снимаем значения на MainActor, чтобы не захватывать actor-isolated
        // свойства внутри не-изолированных SwiftUI builder closure’ов (Swift 6 warnings)
        let currentAvatarImage = avatarImage
        let currentAvatarUrl = appState.currentUser?.avatarUrl
        
        VStack(spacing: 16) {
            // Аватарка с возможностью изменения
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Group {
                    if let avatarImage = currentAvatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if let avatarUrl = currentAvatarUrl, !avatarUrl.isEmpty {
                        MainActor.assumeIsolated {
                            CachedRemoteImage(url: URL(string: avatarUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.white)
                            }
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
                .overlay(
                    // Иконка редактирования
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .offset(x: 5, y: 5)
                        }
                    }
                )
            }
            .disabled(isUploadingAvatar)
            .overlay {
                if isUploadingAvatar {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            
            Text(appState.currentUser?.name ?? "common.user".localized)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            if let status = balanceStatus {
                balanceStatusView(status: status)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.05)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.orange)
                
                Text("profile.honest_streak_label".localized)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("\(appState.currentUser?.honestStreak ?? 0) \("profile.days".localized)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.2))
            )
            
            Button(action: { showingDeposit = true }) {
                Text("profile.deposit_balance".localized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.top, 40)
    }
    
    @ViewBuilder
    private var transactionHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("profile.transaction_history_title".localized)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            if transactions.isEmpty {
                Text("profile.no_transactions_yet".localized)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            } else {
                VStack(spacing: 8) {
                    ForEach(transactions) { tx in
                        transactionRow(tx)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func transactionRow(_ tx: PaymentTransaction) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transactionTypeLabel(tx.type))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(formatTransactionDate(tx.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            Text(formatTransactionAmount(tx))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(transactionAmountColor(tx))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func transactionTypeLabel(_ type: String) -> String {
        switch type {
        case "DEPOSIT": return "profile.tx_deposit".localized
        case "ENTRY_FEE": return "profile.tx_entry_fee".localized
        case "WITHDRAWAL": return "profile.tx_withdrawal".localized
        case "PAYOUT": return "profile.tx_payout".localized
        default: return type
        }
    }
    
    private func formatTransactionDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        f.locale = Locale.current
        return f.string(from: date)
    }
    
    private func formatTransactionAmount(_ tx: PaymentTransaction) -> String {
        let sign: String
        switch tx.type {
        case "DEPOSIT", "PAYOUT": sign = "+"
        case "ENTRY_FEE", "WITHDRAWAL": sign = "−"
        default: sign = ""
        }
        return "\(sign)\(String(format: "%.0f", tx.amount)) ₽"
    }
    
    private func transactionAmountColor(_ tx: PaymentTransaction) -> Color {
        switch tx.type {
        case "DEPOSIT", "PAYOUT": return .green
        case "ENTRY_FEE", "WITHDRAWAL": return .red.opacity(0.9)
        default: return .white
        }
    }
    
    @ViewBuilder
    private var profileActionsView: some View {
        VStack(spacing: 12) {
            profileActionButton(title: "profile.withdraw".localized, icon: "chevron.right") { showingWithdraw = true }
            profileActionButton(title: "profile.rules".localized, icon: "chevron.right") { showingRules = true }
            profileActionButton(title: "profile.support".localized, icon: "chevron.right") { showingSupport = true }
            profileActionButton(title: "language.title".localized, icon: "chevron.right") { showingLanguageSelection = true }
            
            Button(action: { showingClearData = true }) {
                HStack {
                    Text("profile.clear_data".localized)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.orange)
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.orange.opacity(0.5))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                )
            }
            
            Button(action: { showingDeleteAccount = true }) {
                HStack {
                    Text("profile.delete_account".localized)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.red)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.red.opacity(0.5))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                )
            }
            
            Button(action: {
                appState.logout()
                dismiss()
            }) {
                Text("profile.logout".localized)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }
    
    @ViewBuilder
    private func profileActionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: icon)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
        }
    }
    
    // MARK: - Balance Status View
    
    @ViewBuilder
    private func balanceStatusView(status: BalanceStatus) -> some View {
        VStack(spacing: 16) {
            // Доступно
            VStack(spacing: 8) {
                Text("profile.available".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(String(format: "%.2f ₽", status.available))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
            }
            
            // На проверке
            if status.onVerification > 0 {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                        
                        Text("profile.on_verification".localized)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Text(String(format: "%.2f ₽", status.onVerification))
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.blue)
                    
                    // Таймер ожидания
                    if let createdAt = pendingDepositCreatedAt {
                        let verificationDuration: TimeInterval = 24 * 60 * 60 // 24 часа
                        let elapsed = currentTime.timeIntervalSince(createdAt)
                        let remaining = max(0, verificationDuration - elapsed)
                        
                        if remaining > 0 {
                            let hours = Int(remaining) / 3600
                            let minutes = (Int(remaining) % 3600) / 60
                            let timeString = String(format: "%02d:%02d", hours, minutes)
                            
                            Text(String(format: "profile.time_remaining".localized, timeString))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.blue.opacity(0.8))
                        }
                    } else if let timeRemaining = status.formattedVerificationTime {
                        Text(String(format: "profile.time_remaining".localized, timeRemaining))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.blue.opacity(0.8))
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.2))
                )
            }
            
            // Ожидает вывода
            if status.pendingWithdrawal > 0 {
                VStack(spacing: 8) {
                    Text("profile.pending_withdrawal_label".localized)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(String(format: "%.2f ₽", status.pendingWithdrawal))
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.orange)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.2))
                )
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Load Balance Status
    
    private func loadBalanceStatus() async {
        do {
            let status = try await SupabaseManager.shared.getBalanceStatus()
            
            // Получаем дату создания депозита на проверке для таймера
            var depositCreatedAt: Date? = nil
            if status.onVerification > 0 {
                depositCreatedAt = try await SupabaseManager.shared.getPendingDepositCreatedAt()
            }
            
            await MainActor.run {
                balanceStatus = status
                pendingDepositCreatedAt = depositCreatedAt
            }
        } catch {
            Logger.shared.error("Error loading balance status", error: error)
            // Fallback: чтобы UI не "висел" со спиннером, показываем хотя бы текущий баланс.
            // (если запрос статусов недоступен)
            let fallback = BalanceStatus(
                available: appState.currentUser?.balance ?? 0,
                onVerification: 0,
                pendingWithdrawal: 0,
                verificationTimeRemaining: nil
            )
            await MainActor.run {
                balanceStatus = fallback
                pendingDepositCreatedAt = nil
            }
        }
    }
    
    private func loadTransactions() async {
        do {
            let list = try await SupabaseManager.shared.getUserPayments(limit: 50)
            await MainActor.run {
                transactions = list
            }
        } catch {
            Logger.shared.error("Error loading transactions", error: error)
        }
    }
    
    // MARK: - Avatar Upload
    
    @MainActor
    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                avatarImage = image
                isUploadingAvatar = true
                
                // Загружаем в Supabase Storage
                try await uploadAvatar(image: image)
                
                isUploadingAvatar = false
            }
        } catch {
            Logger.shared.error("Failed to load photo", error: error)
            isUploadingAvatar = false
        }
    }
    
    @MainActor
    private func uploadAvatar(image: UIImage) async throws {
        // Получаем userId (уже на MainActor)
        guard let userId = appState.currentUser?.id,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw AppError.invalidData("Не удалось обработать изображение")
        }
        
        // Загружаем в Supabase Storage
        let fileName = "\(userId)/avatar.jpg"
        
        // Используем правильный API Supabase Storage
        // Supabase Swift SDK принимает опции через .init(upsert: true)
        _ = try await SupabaseManager.shared.supabase.storage
            .from("avatars")
            .upload(fileName, data: imageData, options: .init(upsert: true))
        
        // Получаем публичный URL
        let url = try SupabaseManager.shared.supabase.storage
            .from("avatars")
            .getPublicURL(path: fileName)
        
        // Обновляем in-memory кэш, чтобы аватарка показывалась мгновенно
        // (и чтобы не ждать CDN/декодирования после аплоада)
        RemoteImageCache.shared.insert(image, for: url)
        
        // Обновляем URL аватарки в профиле пользователя
        try await SupabaseManager.shared.updateUserAvatar(avatarUrl: url.absoluteString)
        
        // Обновляем локальный профиль
        await appState.refreshUser()
        
        Logger.shared.info("✅ Avatar uploaded successfully: \(url.absoluteString)")
    }
}

struct WithdrawView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @StateObject private var paymentManager = PaymentManager(
        yooKassaClient: DIContainer.shared.yooKassaClient
    )
    
    @State private var amount: String = ""
    @State private var withdrawMethod: WithdrawMethodType = .card // Всегда карта
    @State private var cardNumber: String = ""
    @State private var isProcessing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var balanceStatus: BalanceStatus?
    
    private let presetAmounts: [Double] = [499, 599, 699, 799, 999, 1199, 1499]
    private let minWithdrawAmount: Double = 499.0 // Минимальная сумма вывода
    
    var currentBalance: Double {
        // В UI "available_for_withdrawal" должен быть именно доступный баланс.
        balanceStatus?.available ?? (appState.currentUser?.balance ?? 0.0)
    }
    
    var isValid: Bool {
        guard let amountValue = Double(amount), amountValue >= minWithdrawAmount, amountValue <= currentBalance else {
            return false
        }
        // Всегда используем карту, проверяем только номер карты
        return cardNumber.count >= 16
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        balanceHeaderView
                        amountInputView
                        accountDetailsInputView
                        withdrawButtonView
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("profile.withdraw".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert("error.title".localized, isPresented: $showingError) {
                Button("common.ok".localized, role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("profile.withdrawal_created_title".localized, isPresented: $showingSuccess) {
                Button("common.ok".localized) {
                    dismiss()
                }
            } message: {
                Text(String(format: "profile.withdrawal_request_created".localized, amount))
            }
            .task {
                await loadBalanceStatus()
            }
        }
    }
    
    private func loadBalanceStatus() async {
        do {
            let status = try await SupabaseManager.shared.getBalanceStatus()
            await MainActor.run {
                balanceStatus = status
            }
        } catch {
            Logger.shared.error("WithdrawView: Error loading balance status", error: error)
            let fallback = BalanceStatus(
                available: appState.currentUser?.balance ?? 0,
                onVerification: 0,
                pendingWithdrawal: 0,
                verificationTimeRemaining: nil
            )
            await MainActor.run {
                balanceStatus = fallback
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var balanceHeaderView: some View {
        VStack(spacing: 8) {
            Text("profile.available_for_withdrawal".localized)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text(String(format: "%.2f ₽", currentBalance))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            if currentBalance < minWithdrawAmount {
                Text(String(format: "profile.min_withdrawal_amount".localized, Int(minWithdrawAmount)))
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
                    .padding(.top, 4)
            }
        }
        .padding(.top, 40)
    }
    
    @ViewBuilder
    private var quickAmountSelectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("profile.quick_selection".localized)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(presetAmounts.filter { $0 <= currentBalance }, id: \.self) { presetAmount in
                    quickAmountButton(amount: presetAmount)
                }
                
                if currentBalance >= minWithdrawAmount {
                    allAmountButton
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func quickAmountButton(amount: Double) -> some View {
        Button(action: {
            self.amount = String(format: "%.0f", amount)
        }) {
            Text("\(Int(amount)) ₽")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(self.amount == String(format: "%.0f", amount) ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    self.amount == String(format: "%.0f", amount)
                    ? Color.white
                    : Color.white.opacity(0.1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    @ViewBuilder
    private var allAmountButton: some View {
        Button(action: {
            amount = String(format: "%.2f", currentBalance)
        }) {
            Text("profile.all".localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(amount == String(format: "%.2f", currentBalance) ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    amount == String(format: "%.2f", currentBalance)
                    ? Color.white
                    : Color.white.opacity(0.1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    @ViewBuilder
    private var amountInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("profile.or_enter_amount".localized)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            TextField("0", text: $amount)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .keyboardType(.decimalPad)
                .padding(.vertical, 14)
                .padding(.leading, 16)
                .padding(.trailing, 52) // место под "₽" справа
            .background(Color.white.opacity(0.1))
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    
                    HStack {
                        Spacer()
                        Text("₽")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.trailing, 16)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            amountValidationMessage
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var amountValidationMessage: some View {
        Group {
            if let amountValue = Double(amount), amountValue > currentBalance {
                Text("profile.insufficient_funds".localized)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .padding(.top, 4)
            } else if let amountValue = Double(amount), amountValue < minWithdrawAmount && amountValue > 0 {
                Text(String(format: "profile.min_amount_label".localized, Int(minWithdrawAmount)))
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
                    .padding(.top, 4)
            }
        }
    }
    
    @ViewBuilder
    private var accountDetailsInputView: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardNumberInput
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var cardNumberInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("profile.card_number".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            TextField("0000 0000 0000 0000", text: $cardNumber)
                .keyboardType(.numberPad)
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: cardNumber) { _, newValue in
                    let filtered = newValue.filter { $0.isNumber || $0 == " " }
                    if filtered != newValue {
                        cardNumber = filtered
                    }
                    let cleaned = cardNumber.replacingOccurrences(of: " ", with: "")
                    var formatted = ""
                    for (index, char) in cleaned.enumerated() {
                        if index > 0 && index % 4 == 0 {
                            formatted += " "
                        }
                        formatted.append(char)
                    }
                    cardNumber = String(formatted.prefix(19))
                }
        }
    }
    
    @ViewBuilder
    private var withdrawButtonView: some View {
        Button(action: {
            Task {
                await processWithdraw()
            }
        }) {
            if isProcessing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Text("profile.withdraw_button".localized)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(isValid ? Color.white : Color.white.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .disabled(!isValid || isProcessing)
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }
    
    private func processWithdraw() async {
        guard appState.currentUser?.id != nil else {
            await MainActor.run {
                errorMessage = "error.auth_required".localized
                showingError = true
            }
            return
        }
        
        guard let amountValue = Double(amount), amountValue >= minWithdrawAmount, amountValue <= currentBalance else {
            await MainActor.run {
                errorMessage = "error.invalid_amount".localized
                showingError = true
            }
            return
        }
        
        await MainActor.run {
            isProcessing = true
        }
        
        // Всегда используем карту
        let accountDetails = String(format: "profile.card_format".localized, cardNumber)
        
        do {
            await AnalyticsManager.shared.track(
                "withdraw_attempt",
                amount: amountValue,
                props: ["method": "card"]
            )
            
            try await SupabaseManager.shared.withdrawBalance(
                amount: amountValue,
                accountDetails: accountDetails,
                method: withdrawMethod,
                challengeId: nil
            )
            
            // Обновляем баланс пользователя с сервера (Edge Function уже обновил баланс)
            await appState.refreshUser()
            Logger.shared.info("💳 WithdrawView: User balance refreshed from server")
            
            await AnalyticsManager.shared.track(
                "withdraw_success",
                amount: amountValue,
                props: ["method": "card"]
            )
            
            await MainActor.run {
                isProcessing = false
                showingSuccess = true
            }
        } catch {
            await AnalyticsManager.shared.track(
                "withdraw_failed",
                amount: amountValue,
                props: ["method": "card", "error": error.localizedDescription]
            )
            await MainActor.run {
                isProcessing = false
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}


struct RulesView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("profile.rules_title".localized)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("profile.rule_1".localized)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("profile.rule_2".localized)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("profile.rule_3".localized)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("profile.rule_4".localized)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }
            }
            .navigationTitle("profile.rules_title".localized)
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

struct DepositView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var amount: String = ""
    @State private var isProcessing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var showingEmailInput = false
    @State private var receiptEmail = ""
    @State private var showingPayment = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Текущий баланс
                        VStack(spacing: 8) {
                            Text("profile.current_balance".localized)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(String(format: "%.2f ₽", appState.currentUser?.balance ?? 0.0))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 40)
                        
                        // Поле ввода суммы
                        VStack(alignment: .leading, spacing: 8) {
                            Text("profile.or_enter_amount".localized)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            TextField("0", text: $amount)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .keyboardType(.decimalPad)
                                .padding(.vertical, 14)
                                .padding(.leading, 16)
                                .padding(.trailing, 52) // место под "₽" справа
                            .background(Color.white.opacity(0.1))
                            .overlay(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    
                                    HStack {
                                        Spacer()
                                        Text("₽")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.white.opacity(0.7))
                                            .padding(.trailing, 16)
                                    }
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 20)
                        
                        // Кнопка пополнения
                        Button(action: {
                            // Показываем модальное окно для ввода email
                            receiptEmail = appState.currentUser?.email ?? ""
                            showingEmailInput = true
                        }) {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(Color.white.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                Text("profile.deposit".localized)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(
                                        (Double(amount) ?? 0) > 0 
                                        ? Color.white 
                                        : Color.white.opacity(0.3)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .disabled(isProcessing || (Double(amount) ?? 0) <= 0)
                        .padding(.horizontal, 20)
                        
                        Spacer()
                            .frame(height: 50)
                    }
                }
            }
            .navigationTitle("profile.deposit_balance".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert("alert.error".localized, isPresented: $showingError) {
                Button("common.ok".localized, role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("payment.excellent".localized, isPresented: $showingSuccess) {
                Button("common.ok".localized) {
                    dismiss()
                }
            } message: {
                Text(String(format: "profile.deposit_success_amount".localized, amount))
            }
            .sheet(isPresented: $showingEmailInput) {
                EmailInputSheet(
                    email: $receiptEmail,
                    onConfirm: {
                        // Валидация email
                        if receiptEmail.isValidEmail {
                            showingEmailInput = false
                            // Открываем PaymentView для пополнения баланса
                            Task {
                                await openDepositPayment()
                            }
                        } else {
                            errorMessage = "payment.email_invalid".localized
                            showingError = true
                        }
                    },
                    onCancel: {
                        showingEmailInput = false
                    }
                )
            }
            .sheet(isPresented: $showingPayment) {
                DepositPaymentView(amount: Double(amount) ?? 0, receiptEmail: receiptEmail)
                    .environmentObject(appState)
            }
        }
    }
    
    private func openDepositPayment() async {
        guard let amountValue = Double(amount), amountValue > 0 else {
            await MainActor.run {
                errorMessage = "error.enter_valid_amount".localized
                showingError = true
            }
            return
        }
        
        await MainActor.run {
            showingPayment = true
        }
    }
    
    private func processDeposit() async {
        guard let amountValue = Double(amount), amountValue > 0 else {
            await MainActor.run {
                errorMessage = "error.enter_valid_amount".localized
                showingError = true
            }
            return
        }
        
        await MainActor.run {
            isProcessing = true
        }
        
        do {
            try await SupabaseManager.shared.depositBalance(amount: amountValue)
            
            // Обновляем локальный баланс
            if var user = appState.currentUser {
                user.balance += amountValue
                appState.setUser(user)
                Logger.shared.info("💳 DepositView: Local balance updated, newBalance=\(user.balance)")
            }
            
            // Обновляем баланс пользователя с сервера
            await appState.refreshUser()
            Logger.shared.info("💳 DepositView: User balance refreshed from server")
            
            await MainActor.run {
                isProcessing = false
                showingSuccess = true
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                
                // Обрабатываем ошибку через ErrorHandler для понятного сообщения
                let appError = ErrorHandler.handle(error)
                
                // Всегда показываем понятное сообщение пользователю
                // Не показываем технические детали
                var userMessage = appError.errorDescription ?? "Не удалось пополнить баланс."
                
                // Убираем технические детали из сообщения
                if userMessage.contains("couldn't be read") || 
                   userMessage.contains("missing") ||
                   userMessage.contains("decoding") ||
                   userMessage.contains("DecodingError") {
                    userMessage = "Не удалось обработать данные. Попробуйте ещё раз."
                }
                
                // Если есть предложение по исправлению, добавляем его
                if let suggestion = appError.recoverySuggestion {
                    errorMessage = "\(userMessage)\n\n\(suggestion)"
                } else {
                    errorMessage = String(format: "error.try_again_support".localized, userMessage)
                }
                
                // Логируем полную ошибку для разработчиков
                Logger.shared.error("DepositView: Error processing deposit", error: error)
                
                showingError = true
            }
        }
    }
}

struct SupportView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    Text("profile.support".localized)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                }
            }
            .navigationTitle("profile.support".localized)
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
