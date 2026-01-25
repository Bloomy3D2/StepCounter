//
//  ChallengeDetailView.swift
//  ChallengeApp
//
//  Детали челленджа (decision screen)
//

import SwiftUI
import Combine

struct ChallengeDetailView: View {
    let challenge: Challenge
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var challengeManager: ChallengeManager
    @Environment(\.dismiss) var dismiss
    @State private var showingPayment = false
    @State private var showingEmailInput = false
    @State private var receiptEmail = ""
    @State private var currentTime = Date()
    @State private var loadedChallenge: Challenge?
    @State private var isJoining = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isProcessingPayment = false // Обработка возврата из YooKassa
    @State private var currentPaymentId: String? = nil {
        didSet {
            // Сохраняем paymentId в UserDefaults для восстановления после возврата
            if let paymentId = currentPaymentId {
                UserDefaults.standard.set(paymentId, forKey: "currentPaymentId_\(challenge.id)")
                Logger.shared.info("💾 ChallengeDetailView: Saved paymentId to UserDefaults - \(paymentId)")
            } else {
                UserDefaults.standard.removeObject(forKey: "currentPaymentId_\(challenge.id)")
            }
        }
    }
    
    // Используем загруженный челлендж или исходный
    private var displayChallenge: Challenge {
        loadedChallenge ?? challenge
    }
    
    // Проверяем участие пользователя в этом челлендже (тот же lookup, что и на карточке)
    private var userChallenge: UserChallenge? {
        challengeManager.participatingUserChallenge(challengeId: challenge.id, userId: appState.currentUser?.id)
    }
    
    // Проверяем, завершился ли челлендж
    private var isChallengeEnded: Bool {
        displayChallenge.endDate < currentTime
    }
    
    private var participationStatus: ParticipationStatus {
        guard let uc = userChallenge else { return .notParticipating }
        if uc.isActive { return .active }
        if uc.isCompleted { return .completed }
        if uc.isFailed { return .failed }
        return .notParticipating
    }
    
    enum ParticipationStatus {
        case notParticipating
        case active
        case completed
        case failed
        case ended // Челлендж завершился
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Название + иконка
                    HStack {
                        Image(systemName: displayChallenge.icon)
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(displayChallenge.title)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text(displayChallenge.subtitle)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    // Таймер старта
                    if timeUntilStart > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("detail.start_in".localized)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    Text(formattedTimeUntilStart)
                                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("detail.start_date".localized)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.5))
                                    
                                    Text(displayChallenge.formattedStartDay)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(String(format: "detail.start_time".localized, displayChallenge.formattedStartTime))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                    
                    // Условия
                    VStack(alignment: .leading, spacing: 20) {
                        Text("detail.conditions".localized)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Правила челленджа
                        if !displayChallenge.rules.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(displayChallenge.rules, id: \.self) { rule in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 6))
                                            .foregroundColor(.white.opacity(0.6))
                                            .padding(.top, 6)
                                        
                                        Text(rule)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white.opacity(0.9))
                                            .fixedSize(horizontal: false, vertical: true)
                                        
                                        Spacer()
                                    }
                                }
                            }
                        } else {
                            Text("detail.rules_loading".localized)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                    
                    // Деньги
                    VStack(alignment: .leading, spacing: 16) {
                        Text("detail.money".localized)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("detail.entry".localized)
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text(displayChallenge.formattedEntryFee)
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("detail.service_fee".localized)
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text("\(Int(displayChallenge.serviceFee))%")
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                    
                    // Кнопка вступления или статус участия
                    Group {
                        // Если челлендж завершился, показываем сообщение
                        if isChallengeEnded {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.orange)
                                
                                Text("detail.challenge_ended".localized)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.orange.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            switch participationStatus {
                            case .notParticipating:
                            Button(action: {
                                // Защита от двойного нажатия
                                guard !isJoining else {
                                    Logger.shared.warning("⚠️ ChallengeDetailView: Join button tapped while already joining - ignoring")
                                    return
                                }
                                // Показываем модальное окно для ввода email
                                receiptEmail = appState.currentUser?.email ?? ""
                                showingEmailInput = true
                            }) {
                                if isJoining {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 18)
                                        .background(Color.white.opacity(0.7))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    Text(String(format: "detail.join_for".localized, displayChallenge.formattedEntryFee))
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 18)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .disabled(isJoining)
                            
                        case .active:
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.green)
                                    
                                    Text("detail.you_participate".localized)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(Color.green.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                if let uc = userChallenge {
                                    NavigationLink(destination: ActiveChallengeView(userChallengeId: uc.id)) {
                                        Text("detail.go_to_challenge".localized)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Button(action: { }) {
                                        Text("detail.go_to_challenge".localized)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white.opacity(0.35))
                                    }
                                    .disabled(true)
                                }
                            }
                            
                        case .completed:
                            HStack(spacing: 12) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.yellow)
                                
                                Text("detail.you_won".localized)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.yellow.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                        case .failed:
                            VStack(spacing: 16) {
                                HStack(spacing: 12) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.red)
                                    
                                    Text("detail.you_dropped".localized)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(Color.red.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                Text("detail.wait_next_round".localized)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                                    .multilineTextAlignment(.center)
                            }
                            
                        case .ended:
                            // Этот case не должен достигаться, так как проверка isChallengeEnded выше
                            // Но добавляем для полноты switch
                            HStack(spacing: 12) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.orange)
                                
                                Text("detail.challenge_ended".localized)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.orange.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        }
                    }
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEmailInput) {
            EmailInputSheet(
                email: $receiptEmail,
                onConfirm: {
                    // Валидация email
                    if receiptEmail.isValidEmail {
                        showingEmailInput = false
                        // Проверяем баланс: если достаточно - вступаем сразу, иначе показываем оплату
                        Task {
                            await handleJoinChallengeWithEmail()
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
            PaymentView(challenge: displayChallenge, initialEmail: receiptEmail)
                .environmentObject(appState)
                .environmentObject(challengeManager)
        }
        .alert("error.title".localized, isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .overlay {
            // Экран ожидания обработки платежа
            if isProcessingPayment {
                PaymentProcessingOverlay()
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            currentTime = Date()
        }
        .onChange(of: challengeManager.userChallenges) { oldValue, newValue in
            // Обновляем UI при изменении userChallenges (например, после успешного вступления)
            Logger.shared.debug("🔄 ChallengeDetailView: userChallenges changed - oldCount=\(oldValue.count), newCount=\(newValue.count)")
            // SwiftUI автоматически перерисует view, так как participationStatus зависит от userChallenge
        }
        .onChange(of: participationStatus) { oldValue, newValue in
            Logger.shared.info("🔄 ChallengeDetailView: participationStatus changed - \(oldValue) -> \(newValue)")
        }
        .task {
            await AnalyticsManager.shared.track(
                "view_challenge_detail",
                challengeId: Int64(challenge.id),
                props: ["challenge_id": challenge.id]
            )
            
            // Загружаем полные данные челленджа из Supabase, если правила пустые
            if challenge.rules.isEmpty, let challengeId = Int64(challenge.id) {
                do {
                    let fullChallenge = try await SupabaseManager.shared.getChallenge(id: challengeId)
                    loadedChallenge = fullChallenge
                } catch {
                    Logger.shared.error("Error loading challenge details", error: error)
                }
            } else {
                loadedChallenge = challenge
            }
        }
        .onChange(of: showingPayment) { oldValue, newValue in
            // Когда PaymentView закрывается, обновляем данные
            if oldValue == true && newValue == false {
                Logger.shared.info("🔄 ChallengeDetailView: PaymentView closed - reloading user challenges")
                Task {
                    await challengeManager.loadUserChallengesFromSupabase(forceRefresh: true)
                    // Обновляем баланс пользователя после оплаты
                    await appState.refreshUser()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PaymentReturned"))) { notification in
            // Обработка возврата из ЮKassa после оплаты
            Logger.shared.info("🔄 ChallengeDetailView: PaymentReturned notification received")
            
            // Получаем payment_id из уведомления, если есть
            if let paymentId = notification.userInfo?["payment_id"] as? String {
                currentPaymentId = paymentId
                Logger.shared.info("💳 ChallengeDetailView: Payment ID from notification - \(paymentId)")
            }
            
            Task {
                await handlePaymentReturn()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AppEnteredForeground"))) { _ in
            // Обработка возврата в приложение - проверяем статус платежа, если есть
            // Восстанавливаем paymentId из UserDefaults, если он был сохранен
            let savedPaymentId = UserDefaults.standard.string(forKey: "currentPaymentId_\(challenge.id)")
            if let paymentId = savedPaymentId {
                Logger.shared.info("🔄 ChallengeDetailView: App entered foreground - restored paymentId from UserDefaults: \(paymentId)")
                currentPaymentId = paymentId
                Task {
                    await handlePaymentReturn()
                }
            } else if currentPaymentId != nil {
                Logger.shared.info("🔄 ChallengeDetailView: App entered foreground with pending payment - checking status")
                Task {
                    await handlePaymentReturn()
                }
            }
        }
        .task {
            // При появлении view проверяем, есть ли сохраненный paymentId
            let savedPaymentId = UserDefaults.standard.string(forKey: "currentPaymentId_\(challenge.id)")
            if let paymentId = savedPaymentId {
                Logger.shared.info("💾 ChallengeDetailView: Restored paymentId from UserDefaults on appear: \(paymentId)")
                currentPaymentId = paymentId
                // Проверяем статус платежа
                await handlePaymentReturn()
            }
        }
    }
    
    // Вычисляемые свойства для таймера
    private var timeUntilStart: TimeInterval {
        max(0, displayChallenge.startDate.timeIntervalSince(currentTime))
    }
    
    private var formattedTimeUntilStart: String {
        let hours = Int(timeUntilStart) / 3600
        let minutes = (Int(timeUntilStart) % 3600) / 60
        let seconds = Int(timeUntilStart) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // MARK: - Join Challenge Logic
    
    /// Обработка вступления в челлендж после подтверждения email
    private func handleJoinChallengeWithEmail() async {
        Logger.shared.info("🎯 ChallengeDetailView.handleJoinChallengeWithEmail: START - challengeId=\(displayChallenge.id), email=\(receiptEmail)")
        
        guard let userId = appState.currentUser?.id else {
            Logger.shared.error("❌ ChallengeDetailView.handleJoinChallengeWithEmail: No user ID")
            await MainActor.run {
                errorMessage = "error.login_required".localized
                showingError = true
            }
            return
        }
        
        await MainActor.run {
            isJoining = true
        }
        
        // Проверяем баланс
        let userBalance = appState.currentUser?.balance ?? 0.0
        let entryFee = displayChallenge.entryFee
        
        // Проверяем участие
        let isAlreadyParticipating = challengeManager.participatingUserChallenge(challengeId: challenge.id, userId: userId) != nil
        
        if isAlreadyParticipating {
            await MainActor.run {
                isJoining = false
                errorMessage = "error.already_participating".localized
                showingError = true
            }
            return
        }
        
        if userBalance >= entryFee {
            // Баланс достаточен - списываем и вступаем
            await handleJoinChallengeWithBalance()
        } else {
            // Баланс недостаточен - сразу создаем платеж и открываем UI ЮKassa
            await MainActor.run {
                isJoining = false
            }
            await createPaymentAndOpenYooKassa()
        }
    }
    
    /// Создание платежа и открытие UI ЮKassa
    private func createPaymentAndOpenYooKassa() async {
        Logger.shared.info("💳 ChallengeDetailView.createPaymentAndOpenYooKassa: START - challengeId=\(displayChallenge.id), email=\(receiptEmail)")
        
        guard let userId = appState.currentUser?.id else {
            Logger.shared.error("❌ ChallengeDetailView.createPaymentAndOpenYooKassa: No user ID")
            await MainActor.run {
                errorMessage = "error.login_required".localized
                showingError = true
            }
            return
        }
        
        do {
            let yooKassaClient = DIContainer.shared.yooKassaClient
            let returnUrl = AppConfig.paymentReturnURL
            let metadata = [
                "challenge_id": String(displayChallenge.id),
                "user_id": userId
            ]
            
            Logger.shared.info("💳 ChallengeDetailView.createPaymentAndOpenYooKassa: Creating payment - amount=\(displayChallenge.entryFee), email=\(receiptEmail)")
            
            // Создаем платеж через ЮKassa
            let payment = try await yooKassaClient.createPayment(
                amount: displayChallenge.entryFee,
                description: "Оплата челленджа: \(displayChallenge.title)",
                returnUrl: returnUrl,
                metadata: metadata,
                paymentMethod: nil, // Не указываем метод - пользователь выберет в UI ЮKassa
                receiptEmail: receiptEmail.isEmpty ? nil : receiptEmail
            )
            
            currentPaymentId = payment.id
            
            Logger.shared.info("✅ ChallengeDetailView.createPaymentAndOpenYooKassa: Payment created - paymentId=\(payment.id)")
            
            // Уведомляем о создании платежа
            NotificationCenter.default.post(
                name: NSNotification.Name("PaymentCreated"),
                object: nil,
                userInfo: ["payment_id": payment.id, "challenge_id": displayChallenge.id]
            )
            
            // Открываем UI ЮKassa
            if let confirmationUrlString = payment.confirmation?.confirmationUrl,
               let confirmationUrl = URL(string: confirmationUrlString) {
                Logger.shared.info("🌐 ChallengeDetailView.createPaymentAndOpenYooKassa: Opening YooKassa UI - url=\(confirmationUrlString)")
                
                await MainActor.run {
                    UIApplication.shared.open(confirmationUrl) { success in
                        if success {
                            Logger.shared.info("✅ ChallengeDetailView.createPaymentAndOpenYooKassa: YooKassa UI opened successfully")
                        } else {
                            Logger.shared.error("❌ ChallengeDetailView.createPaymentAndOpenYooKassa: Failed to open YooKassa UI")
                            Task { @MainActor in
                                self.errorMessage = "Не удалось открыть страницу оплаты"
                                self.showingError = true
                            }
                        }
                    }
                }
            } else {
                Logger.shared.error("❌ ChallengeDetailView.createPaymentAndOpenYooKassa: No confirmation URL in payment response")
                await MainActor.run {
                    errorMessage = "Не удалось получить ссылку для оплаты"
                    showingError = true
                }
            }
        } catch {
            Logger.shared.error("❌ ChallengeDetailView.createPaymentAndOpenYooKassa: Error creating payment", error: error)
            await MainActor.run {
                let appError = ErrorHandler.handle(error)
                errorMessage = appError.errorDescription ?? "Не удалось создать платеж"
                showingError = true
            }
        }
    }
    
    /// Обработка возврата из ЮKassa после оплаты
    private func handlePaymentReturn() async {
        Logger.shared.info("🔄 ChallengeDetailView.handlePaymentReturn: START")
        
        // Показываем экран ожидания
        await MainActor.run {
            isProcessingPayment = true
        }
        
        defer {
            // Скрываем экран ожидания после завершения
            Task { @MainActor in
                isProcessingPayment = false
            }
        }
        
        guard let userId = appState.currentUser?.id else {
            Logger.shared.error("❌ ChallengeDetailView.handlePaymentReturn: No user ID")
            return
        }
        
        guard let paymentId = currentPaymentId else {
            Logger.shared.warning("⚠️ ChallengeDetailView.handlePaymentReturn: No payment ID stored")
            // Пробуем проверить участие - возможно платеж уже обработан через webhook
            await checkAndJoinIfNeeded(userId: userId)
            return
        }
        
        Logger.shared.info("💳 ChallengeDetailView.handlePaymentReturn: Checking payment status - paymentId=\(paymentId)")
        
        do {
            let yooKassaClient = DIContainer.shared.yooKassaClient
            let payment = try await yooKassaClient.getPayment(paymentId: paymentId)
            
            Logger.shared.info("💳 ChallengeDetailView.handlePaymentReturn: Payment status - status=\(payment.status), paid=\(payment.paid)")
            
            if payment.status == .succeeded || payment.paid {
                // Платеж успешен - вступаем в челлендж
                Logger.shared.info("✅ ChallengeDetailView.handlePaymentReturn: Payment succeeded - joining challenge")
                // Очищаем сохраненный paymentId
                UserDefaults.standard.removeObject(forKey: "currentPaymentId_\(challenge.id)")
                await joinChallengeAfterPayment(userId: userId)
            } else if payment.status == .canceled {
                Logger.shared.info("❌ ChallengeDetailView.handlePaymentReturn: Payment canceled")
                await MainActor.run {
                    errorMessage = "Платеж отменен"
                    showingError = true
                }
            } else {
                Logger.shared.info("⏳ ChallengeDetailView.handlePaymentReturn: Payment pending - status=\(payment.status)")
                // Платеж еще обрабатывается - ждем немного и проверяем снова
                // YooKassa может обработать платеж асинхронно
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 секунды
                
                // Проверяем статус еще раз
                do {
                    let updatedPayment = try await yooKassaClient.getPayment(paymentId: paymentId)
                    Logger.shared.info("💳 ChallengeDetailView.handlePaymentReturn: Re-checked payment status - status=\(updatedPayment.status), paid=\(updatedPayment.paid)")
                    
                    if updatedPayment.status == .succeeded || updatedPayment.paid {
                        Logger.shared.info("✅ ChallengeDetailView.handlePaymentReturn: Payment succeeded on re-check - joining challenge")
                        await joinChallengeAfterPayment(userId: userId)
                    } else {
                        // Все еще pending - проверяем участие (возможно webhook уже обработал)
                        await checkAndJoinIfNeeded(userId: userId)
                    }
                } catch {
                    Logger.shared.error("❌ ChallengeDetailView.handlePaymentReturn: Error re-checking payment", error: error)
                    // В случае ошибки проверяем участие - возможно webhook уже обработал
                    await checkAndJoinIfNeeded(userId: userId)
                }
            }
        } catch {
            Logger.shared.error("❌ ChallengeDetailView.handlePaymentReturn: Error checking payment", error: error)
            // В случае ошибки проверяем участие - возможно платеж обработан через webhook
            await checkAndJoinIfNeeded(userId: userId)
        }
        
        // Скрываем экран ожидания после завершения (включая ошибки)
        await MainActor.run {
            isProcessingPayment = false
        }
    }
    
    /// Проверка участия и вступление, если нужно
    private func checkAndJoinIfNeeded(userId: String) async {
        Logger.shared.info("🔍 ChallengeDetailView.checkAndJoinIfNeeded: Checking participation")
        
        // Обновляем данные с сервера
        await challengeManager.loadUserChallengesFromSupabase(forceRefresh: true)
        await appState.refreshUser()
        
        // Проверяем, не вступили ли уже
        let isParticipating = challengeManager.participatingUserChallenge(challengeId: challenge.id, userId: userId) != nil
        
        if !isParticipating {
            Logger.shared.info("🔄 ChallengeDetailView.checkAndJoinIfNeeded: Not participating yet - will check again")
            // Если еще не участвуем, возможно платеж еще обрабатывается
            // Webhook обработает автоматически
        } else {
            Logger.shared.info("✅ ChallengeDetailView.checkAndJoinIfNeeded: Already participating - payment processed")
        }
    }
    
    /// Вступление в челлендж после успешной оплаты
    private func joinChallengeAfterPayment(userId: String) async {
        Logger.shared.info("🚀 ChallengeDetailView.joinChallengeAfterPayment: Starting")
        
        do {
            let userChallenge = try await challengeManager.joinChallenge(displayChallenge, userId: userId)
            
            Logger.shared.info("✅ ChallengeDetailView.joinChallengeAfterPayment: Successfully joined - userChallengeId=\(userChallenge.id)")
            
            // Очищаем сохраненный paymentId после успешного вступления
            UserDefaults.standard.removeObject(forKey: "currentPaymentId_\(challenge.id)")
            currentPaymentId = nil
            
            // Обновляем данные
            await challengeManager.loadUserChallengesFromSupabase(forceRefresh: true)
            await appState.refreshUser()
            
            Logger.shared.info("✅ ChallengeDetailView.joinChallengeAfterPayment: COMPLETE")
        } catch {
            Logger.shared.error("❌ ChallengeDetailView.joinChallengeAfterPayment: Error joining challenge", error: error)
            
            // КРИТИЧЕСКАЯ ОШИБКА: Оплата прошла, но вступление не удалось
            // Нужно инициировать возврат средств
            if let paymentId = currentPaymentId {
                Logger.shared.critical("🚨 ChallengeDetailView.joinChallengeAfterPayment: Payment succeeded but join failed - initiating refund")
                do {
                    let yooKassaClient = DIContainer.shared.yooKassaClient
                    _ = try await yooKassaClient.createRefund(paymentId: paymentId, amount: displayChallenge.entryFee)
                    Logger.shared.info("✅ ChallengeDetailView.joinChallengeAfterPayment: Refund initiated")
                } catch {
                    Logger.shared.critical("🚨 ChallengeDetailView.joinChallengeAfterPayment: Failed to initiate refund", error: error)
                }
            }
            
            await MainActor.run {
                errorMessage = "Оплата прошла, но не удалось вступить в челлендж. Средства будут возвращены автоматически."
                showingError = true
            }
        }
    }
    
    /// Вступление в челлендж с баланса (без оплаты через ЮKassa)
    private func handleJoinChallengeWithBalance() async {
        Logger.shared.info("✅ ChallengeDetailView.handleJoinChallengeWithBalance: Starting")
        
        guard let userId = appState.currentUser?.id else { return }
        
        do {
            let serverChallengeId = Int64(displayChallenge.id)
            
            await AnalyticsManager.shared.track(
                "join_attempt",
                challengeId: serverChallengeId,
                amount: displayChallenge.entryFee,
                props: [
                    "flow": "balance",
                    "challenge_id": displayChallenge.id
                ]
            )
            
            if serverChallengeId == nil, AppConfig.isConfigured {
                // Supabase настроен — не даём вступать в локальные (UUID) демо-челленджи,
                // иначе деньги "не списываются" (сервер не знает про этот челлендж).
                throw AppError.invalidData("Этот челлендж локальный (demo) и не поддерживает оплату. Запусти SQL сид в Supabase или выбери серверный челлендж.")
            }
            if let serverChallengeId {
                // Делаем server refresh перед списанием, чтобы не словить двойное списание
                // при повторной попытке (например, если прошлый запрос упал на декодинге).
                await challengeManager.loadUserChallengesFromSupabase(forceRefresh: true)
                if challengeManager.participatingUserChallenge(challengeId: displayChallenge.id, userId: userId) != nil {
                    await MainActor.run {
                        isJoining = false
                        errorMessage = "Вы уже участвуете в этом челлендже."
                        showingError = true
                    }
                    return
                }
                
                try await SupabaseManager.shared.withdrawBalance(
                    amount: displayChallenge.entryFee,
                    accountDetails: "Entry fee for challenge: \(displayChallenge.title)",
                    method: .`internal`,
                    challengeId: serverChallengeId
                )
            }
            
            _ = try await challengeManager.joinChallenge(displayChallenge, userId: userId)
            
            // С сервера обновляем только если это серверный челлендж (есть числовой id)
            if serverChallengeId != nil {
                await challengeManager.loadUserChallengesFromSupabase(forceRefresh: true)
                await appState.refreshUser()
            }
            
            await AnalyticsManager.shared.track(
                "join_success",
                challengeId: serverChallengeId,
                amount: displayChallenge.entryFee,
                props: [
                    "flow": "balance",
                    "challenge_id": displayChallenge.id
                ]
            )
            
            await MainActor.run {
                isJoining = false
            }
        } catch {
            Logger.shared.error("❌ Error joining with balance", error: error)
            let appError = ErrorHandler.handle(error)
            await AnalyticsManager.shared.track(
                "join_failed",
                challengeId: Int64(displayChallenge.id),
                amount: displayChallenge.entryFee,
                props: [
                    "flow": "balance",
                    "challenge_id": displayChallenge.id,
                    "error": appError.errorDescription ?? "unknown"
                ]
            )
            await MainActor.run {
                isJoining = false
                errorMessage = appError.errorDescription ?? "Не удалось вступить в челлендж"
                showingError = true
            }
        }
    }
    
    private func handleJoinChallenge() async {
        Logger.shared.info("🎯 ChallengeDetailView.handleJoinChallenge: START - challengeId=\(displayChallenge.id), title=\(displayChallenge.title), entryFee=\(displayChallenge.entryFee)")
        
        guard let userId = appState.currentUser?.id else {
            Logger.shared.error("❌ ChallengeDetailView.handleJoinChallenge: No user ID - user not authenticated")
            await MainActor.run {
                errorMessage = "error.login_required".localized
                showingError = true
            }
            return
        }
        
        Logger.shared.info("✅ ChallengeDetailView.handleJoinChallenge: User authenticated - userId=\(userId)")
        
        await MainActor.run {
            isJoining = true
        }
        
        // Проверяем баланс пользователя
        let userBalance = appState.currentUser?.balance ?? 0.0
        let entryFee = displayChallenge.entryFee
        
        Logger.shared.info("💰 ChallengeDetailView.handleJoinChallenge: Balance check - userId=\(userId), userBalance=\(userBalance), entryFee=\(entryFee), sufficient=\(userBalance >= entryFee)")
        
        // Проверяем, не участвует ли уже пользователь (тот же lookup, что на карточке и в userChallenge)
        let isAlreadyParticipating = challengeManager.participatingUserChallenge(challengeId: challenge.id, userId: userId) != nil
        
        Logger.shared.info("🔍 ChallengeDetailView.handleJoinChallenge: Participation check - isAlreadyParticipating=\(isAlreadyParticipating)")
        
        if isAlreadyParticipating {
            Logger.shared.warning("⚠️ ChallengeDetailView.handleJoinChallenge: User already participating - aborting join")
            await MainActor.run {
                isJoining = false
                errorMessage = "error.already_participating".localized
                showingError = true
            }
            return
        }
        
        if userBalance >= entryFee {
            // Баланс достаточен - списываем с баланса и вступаем
            Logger.shared.info("✅ ChallengeDetailView.handleJoinChallenge: Sufficient balance - proceeding with balance payment")
            
            do {
                await AnalyticsManager.shared.track(
                    "join_attempt",
                    challengeId: Int64(displayChallenge.id),
                    amount: entryFee,
                    props: [
                        "flow": "balance",
                        "challenge_id": displayChallenge.id
                    ]
                )
                
                // Списываем с баланса (создаем запись о платеже)
                let serverChallengeId = Int64(displayChallenge.id)
                if let serverChallengeId {
                    Logger.shared.info("💳 ChallengeDetailView.handleJoinChallenge: Withdrawing balance - challengeId=\(serverChallengeId), amount=\(entryFee)")
                    
                    try await SupabaseManager.shared.withdrawBalance(
                        amount: entryFee,
                        accountDetails: "Entry fee for challenge: \(displayChallenge.title)",
                        method: .`internal`,
                        challengeId: serverChallengeId
                    )
                    
                    Logger.shared.info("✅ ChallengeDetailView.handleJoinChallenge: Balance withdrawn successfully")
                } else {
                    // Локальный (demo/offline) челлендж: не трогаем серверные платежи.
                    Logger.shared.warning("⚠️ ChallengeDetailView.handleJoinChallenge: Non-numeric challengeId=\(displayChallenge.id). Using local join without server withdrawal.")
                }
                
                // Обновляем локальный баланс (оптимистичное обновление)
                // Баланс обновляем только после refreshUser(), чтобы избежать двойных списаний в UI
                // при ретраях/ошибках декодинга.
                
                // Вступаем в челлендж
                Logger.shared.info("🚀 ChallengeDetailView.handleJoinChallenge: Joining challenge - challengeId=\(displayChallenge.id), userId=\(userId)")
                let userChallenge = try await challengeManager.joinChallenge(displayChallenge, userId: userId)
                
                Logger.shared.info("✅ ChallengeDetailView.handleJoinChallenge: Successfully joined challenge - userChallengeId=\(userChallenge.id), isActive=\(userChallenge.isActive)")
                
                // Принудительно обновляем данные для отображения статуса
                Logger.shared.info("🔄 ChallengeDetailView.handleJoinChallenge: Reloading user challenges to update UI")
                if serverChallengeId != nil {
                    await challengeManager.loadUserChallengesFromSupabase(forceRefresh: true)
                }
                
                // Обновляем баланс пользователя с сервера для синхронизации
                Logger.shared.info("🔄 ChallengeDetailView.handleJoinChallenge: Refreshing user data from server")
                if serverChallengeId != nil {
                    await appState.refreshUser()
                }
                
                await AnalyticsManager.shared.track(
                    "join_success",
                    challengeId: Int64(displayChallenge.id),
                    amount: entryFee,
                    props: [
                        "flow": "balance",
                        "challenge_id": displayChallenge.id
                    ]
                )
                
                await MainActor.run {
                    isJoining = false
                    Logger.shared.info("✅ ChallengeDetailView.handleJoinChallenge: COMPLETE - join successful, UI will update automatically")
                }
            } catch {
                Logger.shared.error("❌ ChallengeDetailView.handleJoinChallenge: Error joining challenge with balance", error: error)
                Logger.shared.error("❌ ChallengeDetailView.handleJoinChallenge: Error details - challengeId=\(displayChallenge.id), userId=\(userId), entryFee=\(entryFee), userBalance=\(userBalance)")
                
                let appError = ErrorHandler.handle(error)
                await AnalyticsManager.shared.track(
                    "join_failed",
                    challengeId: Int64(displayChallenge.id),
                    amount: entryFee,
                    props: [
                        "flow": "balance",
                        "challenge_id": displayChallenge.id,
                        "error": appError.errorDescription ?? "unknown"
                    ]
                )
                
                await MainActor.run {
                    isJoining = false
                    errorMessage = appError.errorDescription ?? "Не удалось вступить в челлендж. Попробуйте ещё раз."
                    if let suggestion = appError.recoverySuggestion {
                        errorMessage += "\n\n\(suggestion)"
                    }
                    showingError = true
                    Logger.shared.error("❌ ChallengeDetailView.handleJoinChallenge: Error shown to user - message=\(errorMessage)")
                }
            }
        } else {
            // Баланс недостаточен - показываем модальное окно для ввода email
            Logger.shared.info("💳 ChallengeDetailView.handleJoinChallenge: Insufficient balance - showing email input - balance=\(userBalance), required=\(entryFee), deficit=\(entryFee - userBalance)")
            await MainActor.run {
                isJoining = false
                receiptEmail = appState.currentUser?.email ?? ""
                showingEmailInput = true
                Logger.shared.info("📱 ChallengeDetailView.handleJoinChallenge: Email input sheet shown")
            }
        }
    }
    
}

// MARK: - Email Input Sheet

struct EmailInputSheet: View {
    @Binding var email: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @FocusState private var isEmailFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Иконка
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .padding(.top, 40)
                    
                    // Заголовок
                    Text("payment.email_required_title".localized)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // Описание
                    Text("payment.email_required_description".localized)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // Поле ввода email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("payment.receipt_email".localized)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        TextField("example@mail.com", text: $email)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .textContentType(.emailAddress)
                            .focused($isEmailFocused)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isEmailFocused ? Color.white.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Кнопка подтверждения
                    Button(action: {
                        onConfirm()
                    }) {
                        Text("payment.confirm".localized)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(email.isEmpty ? Color.white.opacity(0.3) : Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(email.isEmpty)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        onCancel()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Payment Processing Overlay

struct PaymentProcessingOverlay: View {
    var body: some View {
        ZStack {
            // Полупрозрачный фон
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Индикатор загрузки
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                // Текст
                VStack(spacing: 8) {
                    Text("payment.processing".localized)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("payment.processing_wait".localized)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                    )
            )
            .padding(40)
        }
    }
}
