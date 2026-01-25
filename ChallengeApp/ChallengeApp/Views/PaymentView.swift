//
//  PaymentView.swift
//  ChallengeApp
//
//  Экран прямой оплаты при вступлении в челлендж
//

import SwiftUI
import PassKit

struct PaymentView: View {
    let challenge: Challenge
    var initialEmail: String = ""
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var challengeManager: ChallengeManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var paymentManager = PaymentManager(
        yooKassaClient: DIContainer.shared.yooKassaClient
    )
    @State private var agreedToTerms = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var errorTitle = "payment.error".localized
    @State private var errorIcon = "xmark.circle.fill"
    @State private var errorColor = Color.red
    @State private var paymentMethod: PaymentMethodType = .applePay
    @State private var isPaymentInProgress = false // Защита от двойного нажатия
    @State private var paymentTask: Task<Void, Never>? // Для возможности отмены
    @State private var cardDetails = CardDetails() // Данные карты
    @State private var showingCardForm = false // Показывать ли форму карты
    @State private var receiptEmail = "" // Email для отправки чека
    @State private var emailError: String? = nil // Ошибка валидации email
    @State private var currentPaymentId: String? = nil // ID текущего платежа для проверки статуса
    
    var paymentButtonText: String {
        switch paymentMethod {
        case .applePay: return "payment.pay_apple".localized
        case .card: return String(format: "payment.pay_card".localized, challenge.formattedEntryFee)
        case .sbp: return "payment.pay_sbp".localized
        }
    }
    
    @ViewBuilder
    private var paymentButtonContent: some View {
        HStack {
            if paymentMethod == .applePay && PKPaymentAuthorizationController.canMakePayments() {
                Image(systemName: "applelogo")
                    .font(.system(size: 18, weight: .semibold))
            }
            Text(paymentButtonText)
                .font(.system(size: 18, weight: .bold))
        }
        .foregroundColor(.black)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(agreedToTerms ? Color.white : Color.white.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Информация о челлендже
                        VStack(spacing: 16) {
                            Image(systemName: challenge.icon)
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                            
                            Text(challenge.title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(String(format: "payment.duration_days".localized, challenge.duration))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 40)
                        
                        // Сумма к оплате
                        VStack(spacing: 8) {
                            Text("payment.amount_to_pay".localized)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(challenge.formattedEntryFee)
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        // Правила
                        VStack(alignment: .leading, spacing: 12) {
                            Text("payment.rules".localized)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            ForEach(challenge.rules.isEmpty ? [
                                "• Каждый день отмечай выполнение",
                                "• Нет отметки = вылет",
                                "• Деньги не возвращаются"
                            ] : challenge.rules, id: \.self) { rule in
                                Text(rule.hasPrefix("•") ? rule : "• \(rule)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                        )
                        .padding(.horizontal, 20)
                        
                        // Способ оплаты
                        paymentMethodSelectionView
                        
                        // Форма ввода данных карты (показывается только для карты)
                        if paymentMethod == .card && showingCardForm {
                            cardInputFormView
                        }
                        
                        // Информация о СБП
                        if paymentMethod == .sbp {
                            sbpInfoView
                        }
                        
                        // Поле для ввода email для чека
                        receiptEmailView
                        
                        // Чекбокс согласия
                        termsAgreementView
                        
                        // Кнопка оплаты
                        paymentButtonView
                    }
                }
            }
            .navigationTitle("payment.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        // Отменяем платеж, если он в процессе
                        if isPaymentInProgress {
                            paymentTask?.cancel()
                            paymentManager.isProcessing = false
                        }
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .disabled(paymentManager.isProcessing && !isPaymentInProgress)
                }
            }
            .onAppear {
                // Подписываемся на уведомление о возврате из платежной системы
                NotificationCenter.default.addObserver(
                    forName: NSNotification.Name("PaymentReturned"),
                    object: nil,
                    queue: .main
                ) { notification in
                    let paymentId = notification.userInfo?["payment_id"] as? String
                    Task { @MainActor in
                        handlePaymentReturn(paymentId: paymentId)
                    }
                }
            }
            .onDisappear {
                // Отписываемся от уведомлений
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name("PaymentReturned"), object: nil)
            }
            .onAppear {
                // Инициализируем email: сначала из параметра, потом из данных пользователя
                if !initialEmail.isEmpty {
                    receiptEmail = initialEmail
                } else if receiptEmail.isEmpty, let userEmail = appState.currentUser?.email {
                    receiptEmail = userEmail
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PaymentCreated"))) { notification in
                // Сохраняем paymentId при создании платежа
                if let paymentId = notification.userInfo?["payment_id"] as? String {
                    currentPaymentId = paymentId
                    Logger.shared.info("💳 PaymentView: Payment created with ID: \(paymentId)")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PaymentReturned"))) { notification in
                // Обработка возврата из платежной системы
                let paymentId = notification.userInfo?["payment_id"] as? String
                handlePaymentReturn(paymentId: paymentId)
            }
            .onDisappear {
                // Отменяем задачу при закрытии экрана
                paymentTask?.cancel()
                // Отписываемся от уведомлений
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name("PaymentReturned"), object: nil)
            }
            .sheet(isPresented: $showingError) {
                ErrorSheetView(
                    title: errorTitle,
                    message: errorMessage,
                    icon: errorIcon,
                    iconColor: errorColor,
                    onDismiss: {
                        showingError = false
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingSuccess) {
                SuccessSheetView(
                    title: "Успешно!",
                    message: "Оплата прошла успешно!\nВы вступили в челлендж \"\(challenge.title)\"",
                    onDismiss: {
                        Logger.shared.info("✅ PaymentView: Success sheet dismissed - closing payment view")
                        showingSuccess = false
                        dismiss()
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var paymentMethodSelectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("payment.method".localized)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            // Apple Pay
            if PKPaymentAuthorizationController.canMakePayments() {
                applePayButton
            }
            
            // Карта
            cardPaymentButton
            
            // СБП
            sbpPaymentButton
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var applePayButton: some View {
        Button(action: {
            paymentMethod = .applePay
        }) {
            HStack {
                Image(systemName: paymentMethod == .applePay ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(paymentMethod == .applePay ? .white : .white.opacity(0.5))
                
                Image(systemName: "applelogo")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Apple Pay")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(paymentMethod == .applePay ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
            )
        }
    }
    
    @ViewBuilder
    private var cardPaymentButton: some View {
        Button(action: {
            paymentMethod = .card
            showingCardForm = true
        }) {
            HStack {
                Image(systemName: paymentMethod == .card ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(paymentMethod == .card ? .white : .white.opacity(0.5))
                
                Image(systemName: "creditcard")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                
                Text("payment.card".localized)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(paymentMethod == .card ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
            )
        }
    }
    
    @ViewBuilder
    private var sbpPaymentButton: some View {
        Button(action: {
            paymentMethod = .sbp
            showingCardForm = false
        }) {
            HStack {
                Image(systemName: paymentMethod == .sbp ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(paymentMethod == .sbp ? .white : .white.opacity(0.5))
                
                Image(systemName: "qrcode")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                
                Text("payment.sbp".localized)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(paymentMethod == .sbp ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
            )
        }
    }
    
    @ViewBuilder
    private var cardInputFormView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("payment.card_details".localized)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            // Номер карты
            VStack(alignment: .leading, spacing: 8) {
                Text("payment.card_number".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                TextField("0000 0000 0000 0000", text: $cardDetails.cardNumber)
                    .keyboardType(.numberPad)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: cardDetails.cardNumber) { _, newValue in
                        // Ограничиваем только цифрами
                        let filtered = newValue.filter { $0.isNumber || $0 == " " }
                        if filtered != newValue {
                            cardDetails.cardNumber = filtered
                        }
                        cardDetails.formatCardNumber()
                    }
            }
            
            // Срок действия и CVV
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("payment.expiry".localized)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    TextField("MM/YY", text: $cardDetails.expiryDate)
                        .keyboardType(.numberPad)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: cardDetails.expiryDate) { _, newValue in
                            let filtered = newValue.filter { $0.isNumber || $0 == "/" }
                            if filtered != newValue {
                                cardDetails.expiryDate = filtered
                            }
                            cardDetails.formatExpiryDate()
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("CVV")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    SecureField("000", text: $cardDetails.cvv)
                        .keyboardType(.numberPad)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: cardDetails.cvv) { _, newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            cardDetails.cvv = String(filtered.prefix(3))
                        }
                }
            }
            
            // Имя держателя
            VStack(alignment: .leading, spacing: 8) {
                Text("payment.cardholder".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                TextField("IVAN IVANOV", text: $cardDetails.cardholderName)
                    .autocapitalization(.allCharacters)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var receiptEmailView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("payment.receipt_email".localized)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                TextField("example@mail.com", text: $receiptEmail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                emailError != nil ? Color.red : (isEmailValid ? Color.green.opacity(0.5) : Color.white.opacity(0.3)),
                                lineWidth: 1
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: receiptEmail) { _, newValue in
                        validateEmail(newValue)
                    }
                
                if let error = emailError {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                } else if !receiptEmail.isEmpty && isEmailValid {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("payment.email_valid".localized)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.green)
                }
            }
            
            Text("payment.email_receipt_info".localized)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .padding(.horizontal, 20)
    }
    
    private var isEmailValid: Bool {
        !receiptEmail.isEmpty && emailError == nil && receiptEmail.isValidEmail
    }
    
    private func validateEmail(_ email: String) {
        if email.isEmpty {
            emailError = nil
        } else if !email.isValidEmail {
            emailError = "Неверный формат email"
        } else {
            emailError = nil
        }
    }
    
    @ViewBuilder
    private var sbpInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("payment.sbp_payment".localized)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("payment.sbp_info".localized)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.2))
        )
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var termsAgreementView: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: {
                agreedToTerms.toggle()
            }) {
                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                    .font(.system(size: 24))
                    .foregroundColor(agreedToTerms ? .white : .white.opacity(0.5))
            }
            
            Text("payment.terms_agree".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var paymentButtonView: some View {
        Button(action: {
            // Защита от двойного нажатия
            guard !isPaymentInProgress && !paymentManager.isProcessing else { return }
            
            paymentTask = Task {
                await processPayment()
            }
        }) {
            if paymentManager.isProcessing || isPaymentInProgress {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                paymentButtonContent
            }
        }
        .disabled(!agreedToTerms || paymentManager.isProcessing || isPaymentInProgress || (paymentMethod == .card && !cardDetails.isValid) || !isEmailValid)
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }
    
    // MARK: - Payment Processing
    
    private func processPayment() async {
        Logger.shared.payment("💳 PaymentView.processPayment: START - challengeId=\(challenge.id), title=\(challenge.title), entryFee=\(challenge.entryFee), paymentMethod=\(paymentMethod), receiptEmail=\(receiptEmail.isEmpty ? "empty" : receiptEmail)")
        
        // Проверка на отмену задачи
        guard !Task.isCancelled else {
            Logger.shared.warning("⚠️ PaymentView.processPayment: Task cancelled before processing")
            await MainActor.run {
                isPaymentInProgress = false
            }
            return
        }
        
        guard let userId = appState.currentUser?.id else {
            Logger.shared.error("❌ PaymentView.processPayment: No user ID - user not authenticated")
            await MainActor.run {
                isPaymentInProgress = false
                showError(
                    "Для оплаты необходимо войти в приложение.\nПожалуйста, авторизуйтесь и попробуйте снова.",
                    title: "Требуется вход",
                    icon: "person.crop.circle.badge.exclamationmark",
                    color: .orange
                )
            }
            return
        }
        
        Logger.shared.info("✅ PaymentView.processPayment: User authenticated - userId=\(userId)")
        
        // Проверяем валидность email
        if !isEmailValid {
            Logger.shared.error("❌ PaymentView.processPayment: Invalid email - receiptEmail=\(receiptEmail), emailError=\(emailError ?? "nil")")
            await MainActor.run {
                isPaymentInProgress = false
                showError(
                    "Пожалуйста, введите корректный email для получения чека",
                    title: "Неверный email",
                    icon: "envelope.badge.fill",
                    color: .orange
                )
            }
            return
        }
        
        Logger.shared.info("✅ PaymentView.processPayment: Email validated - receiptEmail=\(receiptEmail)")
        
        // Проверяем, не участвует ли уже пользователь
        // ВАЖНО: Используем forceRefresh для получения актуальных данных с сервера
        Logger.shared.info("🔍 PaymentView.processPayment: Checking participation - challengeId=\(challenge.id), userId=\(userId)")
        await challengeManager.loadUserChallengesFromSupabase(forceRefresh: true)
        
        // Проверяем как активные, так и завершенные/проваленные челленджи
        let isAlreadyParticipating = challengeManager.userChallenges.contains { uc in
            uc.challengeId == challenge.id && uc.userId == userId
        }
        
        Logger.shared.info("🔍 PaymentView.processPayment: Participation check result - isAlreadyParticipating=\(isAlreadyParticipating), totalUserChallenges=\(challengeManager.userChallenges.count)")
        if isAlreadyParticipating {
            let existingChallenge = challengeManager.userChallenges.first { 
                $0.challengeId == challenge.id && $0.userId == userId 
            }
            let statusText = existingChallenge?.isActive == true ? "активном" : 
                           existingChallenge?.isCompleted == true ? "завершенном" : 
                           existingChallenge?.isFailed == true ? "проваленном" : "этом"
            
            Logger.shared.warning("⚠️ PaymentView.processPayment: User already participating - userChallengeId=\(existingChallenge?.id ?? "nil"), isActive=\(existingChallenge?.isActive ?? false), isCompleted=\(existingChallenge?.isCompleted ?? false), isFailed=\(existingChallenge?.isFailed ?? false)")
            
            await MainActor.run {
                isPaymentInProgress = false
                showInfo(
                    "Вы уже участвуете в этом челлендже.\n\nПроверьте раздел «Мои челленджи» для просмотра вашего прогресса.",
                    title: "Уже участвуете"
                )
            }
            return
        }
        
        // Проверяем, не закончился ли челлендж
        // Пользователь может оплатить ДО начала (предварительная регистрация)
        let now = Date()
        if challenge.endDate < now {
            Logger.shared.warning("⚠️ PaymentView.processPayment: Challenge already ended - endDate=\(challenge.endDate), now=\(now)")
            await MainActor.run {
                isPaymentInProgress = false
                showWarning(
                    "К сожалению, этот челлендж уже завершён.\nВыберите другой челлендж.",
                    title: "Челлендж завершён"
                )
            }
            return
        }
        
        Logger.shared.info("✅ PaymentView.processPayment: Pre-checks passed - starting payment processing")
        
        await MainActor.run {
            isPaymentInProgress = true
        }
        
        // Обрабатываем оплату с таймаутом
        Logger.shared.payment("💳 PaymentView.processPayment: Calling paymentManager.processPayment - amount=\(challenge.entryFee), method=\(paymentMethod)")
        let paymentResult = await withTimeout(seconds: 30) {
            await paymentManager.processPayment(
                amount: challenge.entryFee,
                challenge: challenge,
                userId: userId,
                paymentMethod: paymentMethod,
                cardDetails: paymentMethod == .card ? cardDetails : nil,
                receiptEmail: receiptEmail
            )
        }
        
        Logger.shared.payment("💳 PaymentView.processPayment: Payment result received - success=\(paymentResult ?? false)")
        
        // Проверка на отмену после оплаты
        guard !Task.isCancelled else {
            await MainActor.run {
                isPaymentInProgress = false
                showInfo(
                    "Платёж был отменён.\nВы можете попробовать снова.",
                    title: "Отменено"
                )
            }
            return
        }
        
        guard let success = paymentResult else {
            await MainActor.run {
                isPaymentInProgress = false
                showWarning(
                    "Превышено время ожидания ответа от платёжной системы.\nПожалуйста, попробуйте ещё раз.",
                    title: "Таймаут"
                )
            }
            return
        }
        
        if success {
            Logger.shared.payment("✅ PaymentView.processPayment: Payment succeeded - proceeding to join challenge")
            
            // Для СБП: если оплата прошла, но пользователь еще не вернулся из браузера,
            // не пытаемся вступить сразу - дождемся возврата в приложение
            if paymentMethod == .sbp {
                Logger.shared.info("⏳ PaymentView.processPayment: SBP payment - waiting 2 seconds for user return from browser")
                // СБП открывает браузер, поэтому вступление произойдет после возврата
                // В реальности здесь нужно использовать webhook или polling для проверки статуса
                // Для MVP: даем пользователю время вернуться из браузера
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 секунды
            }
            
            // После успешной оплаты вступаем в челлендж
            Logger.shared.info("🚀 PaymentView.processPayment: Joining challenge after successful payment - challengeId=\(challenge.id), userId=\(userId)")
            do {
                let userChallenge = try await challengeManager.joinChallenge(challenge, userId: userId)
                Logger.shared.info("✅ PaymentView.processPayment: Successfully joined challenge - userChallengeId=\(userChallenge.id), isActive=\(userChallenge.isActive)")
                
                // Принудительно обновляем userChallenges после успешного вступления
                Logger.shared.info("🔄 PaymentView.processPayment: Reloading user challenges to update UI")
                await challengeManager.loadUserChallengesFromSupabase(forceRefresh: true)
                
                Logger.shared.payment("✅ PaymentView.processPayment: COMPLETE - payment and join successful")
                
                await MainActor.run {
                    isPaymentInProgress = false
                    showingSuccess = true
                }
            } catch {
                Logger.shared.critical("🚨 PaymentView.processPayment: CRITICAL ERROR - Payment succeeded but join failed", error: error)
                Logger.shared.critical("🚨 PaymentView.processPayment: Error details - challengeId=\(challenge.id), userId=\(userId), entryFee=\(challenge.entryFee), paymentMethod=\(paymentMethod)")
                // КРИТИЧЕСКИЙ СЛУЧАЙ: Оплата прошла, но вступление не удалось
                await MainActor.run {
                    isPaymentInProgress = false
                    
                    let appError = ErrorHandler.handle(error)
                    Logger.shared.critical("Payment succeeded but failed to join challenge", error: error, file: #file, function: #function, line: #line)
                    Logger.shared.critical("User: \(userId), Challenge: \(challenge.id)")
                    
                    // Определяем сообщение и тип ошибки на основе AppError
                    switch appError {
                    case .alreadyJoined:
                        // Пользователь уже участвует - это не критическая ошибка
                        // Скорее всего, оплата не прошла или была отменена
                        Logger.shared.warning("User already joined - payment may have been cancelled or not processed")
                        showInfo(
                            "Вы уже участвуете в этом челлендже.\n\nЕсли вы видите это сообщение после оплаты, проверьте раздел «Мои челленджи». Если средства были списаны, но вы не видите челлендж в списке, обратитесь в поддержку.",
                            title: "Уже участвуете"
                        )
                    case .challengeNotFound:
                        showError(
                            "Челлендж не найден или был деактивирован.\n\nСредства будут возвращены автоматически в течение 24 часов.",
                            title: "Челлендж недоступен",
                            icon: "magnifyingglass.circle.fill",
                            color: .orange
                        )
                    case .serverError(let message):
                        let fullMessage: String
                        if message.contains("уже участвуете") || message.contains("already joined") {
                            fullMessage = "Вы уже участвуете в этом челлендже.\n\nЕсли средства были списаны повторно, они будут автоматически возвращены на ваш баланс в течение 24 часов.\n\nЕсли возврат не произошёл, обратитесь в поддержку."
                        } else {
                            fullMessage = "\(message)\n\nЕсли средства были списаны, они будут автоматически возвращены на ваш баланс в течение 24 часов.\n\nЕсли возврат не произошёл, обратитесь в поддержку."
                        }
                        showError(
                            fullMessage,
                            title: "Ошибка сервера",
                            icon: "exclamationmark.icloud.fill",
                            color: .red
                        )
                    case .networkError, .networkTimeout, .networkUnavailable:
                        showError(
                            "Нет соединения с сервером.\n\nПроверьте подключение к интернету и попробуйте снова.",
                            title: "Нет соединения",
                            icon: "wifi.slash",
                            color: .orange
                        )
                    case .authenticationRequired:
                        showError(
                            "Сессия истекла. Пожалуйста, войдите снова.",
                            title: "Требуется вход",
                            icon: "person.crop.circle.badge.exclamationmark",
                            color: .orange
                        )
                    default:
                        // Для остальных ошибок инициируем возврат
                        if appError.isCritical {
                            Task {
                                do {
                                    try await paymentManager.refundPayment(amount: challenge.entryFee)
                                    Logger.shared.payment("Возврат средств инициирован")
                                } catch {
                                    Logger.shared.error("Не удалось инициировать возврат", error: error)
                                }
                            }
                        }
                        
                        let friendlyMessage = appError.errorDescription ?? "Не удалось вступить в челлендж"
                        showError(
                            "\(friendlyMessage)\n\nЕсли средства были списаны, они будут автоматически возвращены на ваш баланс в течение 24 часов.\n\nЕсли возврат не произошёл, обратитесь в поддержку.",
                            title: "error.title".localized,
                            icon: "xmark.circle.fill",
                            color: .red
                        )
                    }
                }
            }
        } else {
            await MainActor.run {
                isPaymentInProgress = false
                let paymentError = paymentManager.lastError ?? "Платёж не был обработан"
                showError(
                    "\(paymentError)\n\nПроверьте данные и попробуйте ещё раз.",
                    title: "Ошибка оплаты",
                    icon: "creditcard.trianglebadge.exclamationmark",
                    color: .red
                )
            }
        }
    }
    
    // Вспомогательная функция для таймаута
    private func withTimeout<T: Sendable>(seconds: TimeInterval, operation: @escaping @Sendable () async -> T) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask { @Sendable in
                await operation()
            }
            
            group.addTask { @Sendable in
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return nil
            }
            
            let result = await group.next()
            group.cancelAll()
            return result ?? nil
        }
    }
    
    // MARK: - Error Helpers
    
    private func showError(_ message: String, title: String = "error.title".localized, icon: String = "xmark.circle.fill", color: Color = .red) {
        errorTitle = title
        errorMessage = message
        errorIcon = icon
        errorColor = color
        showingError = true
    }
    
    private func showWarning(_ message: String, title: String = "Внимание") {
        showError(message, title: title, icon: "exclamationmark.triangle.fill", color: .orange)
    }
    
    /// Обработка возврата из платежной системы
    private func handlePaymentReturn(paymentId: String?) {
        Logger.shared.info("🔗 PaymentView: Payment return detected")
        
        // Сохраняем payment_id, если есть
        if let paymentId = paymentId {
            Logger.shared.info("🔗 PaymentView: Payment ID from notification: \(paymentId)")
            currentPaymentId = paymentId
        }
        
        // Проверяем статус платежа и обновляем UI
        Task {
            await checkPaymentStatusAndUpdateUI()
        }
    }
    
    /// Проверка статуса платежа и обновление UI
    private func checkPaymentStatusAndUpdateUI() async {
        guard let userId = appState.currentUser?.id else {
            Logger.shared.warning("🔗 PaymentView: No user ID for payment status check")
            return
        }
        
        // Если есть paymentId, проверяем статус через API
        if let paymentId = currentPaymentId {
            Logger.shared.info("🔗 PaymentView: Checking payment status for ID: \(paymentId)")
            
            do {
                let payment = try await DIContainer.shared.yooKassaClient.getPayment(paymentId: paymentId)
                
                if payment.status == .succeeded {
                    Logger.shared.info("🔗 PaymentView: Payment succeeded, joining challenge")
                    
                    // Пытаемся вступить в челлендж
                    do {
                        _ = try await challengeManager.joinChallenge(challenge, userId: userId)
                        await challengeManager.loadUserChallengesFromSupabase(forceRefresh: true)
                        
                        await MainActor.run {
                            isPaymentInProgress = false
                            showingSuccess = true
                        }
                    } catch {
                        Logger.shared.error("🔗 PaymentView: Failed to join challenge after payment return", error: error)
                        await MainActor.run {
                            isPaymentInProgress = false
                            let appError = ErrorHandler.handle(error)
                            if case .alreadyJoined = appError {
                                showInfo(
                                    "Вы уже участвуете в этом челлендже.\n\nПроверьте раздел «Мои челленджи».",
                                    title: "Уже участвуете"
                                )
                            } else {
                                showError(
                                    "Платеж успешен, но не удалось вступить в челлендж.\n\nОбратитесь в поддержку.",
                                    title: "Ошибка"
                                )
                            }
                        }
                    }
                } else if payment.status == .canceled {
                    Logger.shared.warning("🔗 PaymentView: Payment was canceled")
                    await MainActor.run {
                        isPaymentInProgress = false
                        showInfo(
                            "Платеж был отменен.\n\nВы можете попробовать снова.",
                            title: "Платеж отменен"
                        )
                    }
                } else {
                    Logger.shared.info("🔗 PaymentView: Payment status: \(payment.status.rawValue), waiting...")
                    // Платеж еще обрабатывается, продолжаем ждать
                }
            } catch {
                Logger.shared.error("🔗 PaymentView: Error checking payment status", error: error)
                // Если не удалось проверить статус, просто обновляем данные пользователя
                await challengeManager.loadUserChallengesFromSupabase(forceRefresh: true)
            }
        } else {
            // Если paymentId нет, просто обновляем данные
            Logger.shared.info("🔗 PaymentView: No payment ID, refreshing user challenges")
            await challengeManager.loadUserChallengesFromSupabase(forceRefresh: true)
            
            // Проверяем, появился ли активный челлендж
            let isParticipating = challengeManager.userChallenges.contains { uc in
                uc.challengeId == challenge.id && uc.userId == userId && uc.isActive
            }
            
            if isParticipating {
                await MainActor.run {
                    isPaymentInProgress = false
                    showingSuccess = true
                }
            }
        }
    }
    
    private func showInfo(_ message: String, title: String = "Информация") {
        showError(message, title: title, icon: "info.circle.fill", color: .blue)
    }
}

// MARK: - Error Sheet View

struct ErrorSheetView: View {
    let title: String
    let message: String
    let icon: String
    let iconColor: Color
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Иконка
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(iconColor)
                .padding(.bottom, 8)
            
            // Заголовок
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            // Сообщение с ScrollView для длинных текстов
            ScrollView {
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxHeight: 200)
            
            Spacer()
            
            // Кнопка
            Button(action: onDismiss) {
                Text("payment.got_it".localized)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(iconColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Success Sheet View

struct SuccessSheetView: View {
    let title: String
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Анимированная галочка
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
            }
            .padding(.bottom, 8)
            
            // Заголовок
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            // Сообщение
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            
            // Кнопка
            Button(action: onDismiss) {
                Text("payment.excellent".localized)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - String Extension for Email Validation

extension String {
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
}
