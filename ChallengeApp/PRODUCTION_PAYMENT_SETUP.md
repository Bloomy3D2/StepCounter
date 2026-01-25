# Настройка платежей для продакшена

## 🎯 Что нужно сделать для реальных платежей

### Текущее состояние (MVP):
- ✅ Симуляция платежей (всегда успешно)
- ✅ Базовая структура кода
- ✅ Обработка ошибок

### Для продакшена нужно:
- ⚠️ Интеграция с реальными платежными системами
- ⚠️ Webhook'и для подтверждения платежей
- ⚠️ Токенизация карт
- ⚠️ 3D Secure
- ⚠️ Возврат средств при ошибках
- ⚠️ Мониторинг и логирование

---

## 📋 План действий

### Этап 1: Регистрация в платежных системах

#### 1.1 ЮKassa (для карт)
1. Зарегистрироваться на [yookassa.ru](https://yookassa.ru)
2. Пройти верификацию (нужен ИП/ООО)
3. Получить:
   - `shopId` (ID магазина)
   - `secretKey` (секретный ключ)
   - `testKey` (для тестирования)

#### 1.2 СБП (через банк)
1. Открыть расчетный счет в банке с API СБП (Сбер, Тинькофф, Альфа)
2. Подключить API СБП
3. Получить:
   - API ключи
   - Webhook URL для callback'ов

---

### Этап 2: Интеграция ЮKassa для карт

#### 2.1 Установка SDK

Добавьте в `Package.swift` или через SPM:
```swift
dependencies: [
    .package(url: "https://github.com/yoomoney/yookassa-sdk-swift", from: "6.0.0")
]
```

Или используйте REST API напрямую (проще для начала).

#### 2.2 Создание платежа

**Текущий код (симуляция):**
```swift
case .card:
    result = try await simulatePayment()
```

**Для продакшена:**
```swift
case .card:
    result = try await processCardPaymentWithYooKassa(
        amount: amount,
        challenge: challenge,
        cardDetails: cardDetails
    )
```

#### 2.3 Реализация метода

```swift
private func processCardPaymentWithYooKassa(
    amount: Double,
    challenge: Challenge,
    cardDetails: CardDetails
) async throws -> Bool {
    // 1. Создаем платеж через ЮKassa API
    let paymentRequest = YooKassaPaymentRequest(
        amount: Amount(value: String(format: "%.2f", amount), currency: "RUB"),
        description: "Оплата челленджа: \(challenge.title)",
        confirmation: Confirmation(type: .redirect, returnUrl: "challengeapp://payment/success"),
        capture: true,
        metadata: [
            "challenge_id": challenge.id,
            "user_id": userId
        ]
    )
    
    // 2. Отправляем запрос в ЮKassa
    let payment = try await yooKassaClient.createPayment(paymentRequest)
    
    // 3. Если требуется 3D Secure, открываем URL
    if let confirmationUrl = payment.confirmation?.confirmationUrl {
        await MainActor.run {
            UIApplication.shared.open(confirmationUrl)
        }
        // Ждем callback через webhook
        return try await waitForPaymentConfirmation(paymentId: payment.id)
    }
    
    // 4. Если оплата сразу успешна
    return payment.status == .succeeded
}
```

#### 2.4 Токенизация карты

**Важно:** Не храните полные данные карты!

```swift
// Вместо отправки полных данных карты:
// ❌ НЕПРАВИЛЬНО: cardNumber, cvv, expiryDate

// Используйте токенизацию:
// ✅ ПРАВИЛЬНО: токен от ЮKassa
private func tokenizeCard(cardDetails: CardDetails) async throws -> String {
    let tokenRequest = TokenRequest(
        number: cardDetails.cardNumber.replacingOccurrences(of: " ", with: ""),
        cvc: cardDetails.cvv,
        expiryMonth: String(cardDetails.expiryDate.prefix(2)),
        expiryYear: "20" + String(cardDetails.expiryDate.suffix(2))
    )
    
    let token = try await yooKassaClient.createToken(tokenRequest)
    return token.value // Используйте этот токен для платежа
}
```

---

### Этап 3: Интеграция СБП

#### 3.1 Создание платежа СБП

**Текущий код (заглушка):**
```swift
let sbpURLString = "https://qr.nspk.ru/{amount}/{transactionId}"
```

**Для продакшена (через ЮKassa):**
```swift
private func processSBPPayment(amount: Double, challenge: Challenge) async throws -> Bool {
    // 1. Создаем платеж через ЮKassa с методом СБП
    let paymentRequest = YooKassaPaymentRequest(
        amount: Amount(value: String(format: "%.2f", amount), currency: "RUB"),
        description: "Оплата челленджа: \(challenge.title)",
        paymentMethodData: PaymentMethodData(type: .sbp),
        confirmation: Confirmation(type: .redirect, returnUrl: "challengeapp://payment/success"),
        capture: true
    )
    
    let payment = try await yooKassaClient.createPayment(paymentRequest)
    
    // 2. Получаем URL для редиректа на СБП
    guard let confirmationUrl = payment.confirmation?.confirmationUrl else {
        throw PaymentError.noConfirmationUrl
    }
    
    // 3. Открываем URL в Safari
    await MainActor.run {
        UIApplication.shared.open(confirmationUrl)
    }
    
    // 4. Ждем callback через webhook
    return try await waitForPaymentConfirmation(paymentId: payment.id)
}
```

#### 3.2 Альтернатива: Прямая интеграция с банком

Если используете прямой API банка (например, Сбер):

```swift
private func processSBPPaymentWithSber(amount: Double) async throws -> Bool {
    // 1. Создаем QR-код через Сбер API
    let qrRequest = SberQRRequest(
        amount: Int(amount * 100),
        currency: "RUB",
        orderId: UUID().uuidString
    )
    
    let qrResponse = try await sberAPI.createQR(qrRequest)
    
    // 2. Открываем URL СБП
    await MainActor.run {
        UIApplication.shared.open(qrResponse.qrUrl)
    }
    
    // 3. Ждем callback
    return try await waitForSberPaymentConfirmation(orderId: qrRequest.orderId)
}
```

---

### Этап 4: Webhook'и для подтверждения платежей

#### 4.1 Создание Edge Function для webhook'ов

**Файл:** `supabase/functions/payment-webhook/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const { payment_id, status, amount, metadata } = await req.json()
    
    // Проверяем подпись от ЮKassa (важно для безопасности!)
    const signature = req.headers.get('X-YooMoney-Signature')
    if (!verifySignature(req.body, signature)) {
      return new Response(JSON.stringify({ error: 'Invalid signature' }), { status: 401 })
    }
    
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )
    
    if (status === 'succeeded') {
      // Платеж успешен
      const challengeId = metadata?.challenge_id
      const userId = metadata?.user_id
      
      if (challengeId && userId) {
        // Вступаем в челлендж
        const { data, error } = await supabase.rpc('join_challenge', {
          p_user_id: userId,
          p_challenge_id: challengeId
        })
        
        if (error) {
          console.error('Error joining challenge:', error)
          // Инициируем возврат средств
          await initiateRefund(payment_id, amount)
        }
      }
      
      // Обновляем статус платежа в БД
      await supabase
        .from('payments')
        .update({ status: 'COMPLETED', processed_at: new Date().toISOString() })
        .eq('transaction_id', payment_id)
    } else if (status === 'canceled') {
      // Платеж отменен
      await supabase
        .from('payments')
        .update({ status: 'FAILED' })
        .eq('transaction_id', payment_id)
    }
    
    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})

function verifySignature(body: string, signature: string): boolean {
  // Проверка подписи от ЮKassa
  // Используйте секретный ключ для проверки HMAC
  // Это критично для безопасности!
  return true // Заглушка - реализуйте реальную проверку
}
```

#### 4.2 Настройка webhook URL в ЮKassa

1. Войдите в личный кабинет ЮKassa
2. Перейдите в "Настройки" → "HTTP-уведомления"
3. Укажите URL: `https://YOUR_PROJECT.supabase.co/functions/v1/payment-webhook`
4. Выберите события: `payment.succeeded`, `payment.canceled`

#### 4.3 Обработка возврата в приложение

**В `Info.plist` добавьте URL scheme:**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>challengeapp</string>
        </array>
    </dict>
</array>
```

**В `ChallengeAppApp.swift` обработайте URL:**
```swift
.onOpenURL { url in
    if url.scheme == "challengeapp" && url.host == "payment" {
        // Пользователь вернулся после оплаты
        // Проверяем статус платежа через API
        Task {
            await checkPaymentStatus()
        }
    }
}
```

---

### Этап 5: Возврат средств при ошибках

#### 5.1 Метод возврата в PaymentManager

```swift
func refundPayment(transactionId: String, amount: Double) async throws {
    // Вызов API ЮKassa для возврата
    let refundRequest = RefundRequest(
        paymentId: transactionId,
        amount: Amount(value: String(format: "%.2f", amount), currency: "RUB")
    )
    
    let refund = try await yooKassaClient.createRefund(refundRequest)
    
    // Обновляем статус в БД
    try await SupabaseManager.shared.updatePaymentStatus(
        transactionId: transactionId,
        status: "REFUNDED"
    )
}
```

#### 5.2 Использование при ошибке вступления

```swift
} catch {
    // КРИТИЧЕСКИЙ СЛУЧАЙ: Оплата прошла, но вступление не удалось
    do {
        // Инициируем возврат средств
        try await paymentManager.refundPayment(
            transactionId: transactionId,
            amount: challenge.entryFee
        )
        
        errorMessage = "Оплата прошла, но не удалось вступить в челлендж. Средства возвращены."
    } catch {
        errorMessage = "Оплата прошла, но не удалось вступить в челлендж. Средства будут возвращены автоматически. Если проблема сохраняется, обратитесь в поддержку."
    }
}
```

---

### Этап 6: Безопасность

#### 6.1 Хранение ключей

**❌ НЕПРАВИЛЬНО (в коде):**
```swift
let secretKey = "sk_live_1234567890" // НИКОГДА так не делайте!
```

**✅ ПРАВИЛЬНО (через переменные окружения или Supabase Secrets):**

1. **Вариант 1: Supabase Secrets**
```swift
// В Edge Function
const yooKassaSecretKey = Deno.env.get('YOOKASSA_SECRET_KEY')
```

2. **Вариант 2: iOS Keychain**
```swift
import Security

func getSecretKey() -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: "yookassa_secret_key",
        kSecReturnData as String: true
    ]
    
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    
    if status == errSecSuccess,
       let data = result as? Data,
       let key = String(data: data, encoding: .utf8) {
        return key
    }
    
    return nil
}
```

#### 6.2 Проверка подписи webhook'ов

```swift
func verifyWebhookSignature(body: Data, signature: String) -> Bool {
    let secretKey = getSecretKey() ?? ""
    let hmac = HMAC<SHA256>.authenticationCode(for: body, using: SymmetricKey(data: secretKey.data(using: .utf8)!))
    let expectedSignature = Data(hmac).base64EncodedString()
    return signature == expectedSignature
}
```

---

### Этап 7: Мониторинг и логирование

#### 7.1 Логирование платежей

```swift
func logPaymentEvent(event: PaymentEvent) {
    // Отправка в систему мониторинга (Sentry, Firebase, и т.д.)
    Logger.shared.log(
        level: event.isError ? .error : .info,
        message: "Payment event: \(event.type)",
        metadata: [
            "payment_id": event.paymentId,
            "amount": event.amount,
            "status": event.status,
            "error": event.error
        ]
    )
}
```

#### 7.2 Метрики для отслеживания

- Количество успешных платежей
- Количество неудачных платежей
- Среднее время обработки
- Количество возвратов
- Количество критических ошибок (оплата успешна, но вступление не удалось)

---

## 📝 Чеклист для продакшена

### Интеграция:
- [ ] Зарегистрироваться в ЮKassa
- [ ] Получить API ключи (shopId, secretKey)
- [ ] Интегрировать SDK или REST API
- [ ] Настроить токенизацию карт
- [ ] Реализовать 3D Secure
- [ ] Настроить СБП (через ЮKassa или банк)

### Webhook'и:
- [ ] Создать Edge Function для webhook'ов
- [ ] Настроить URL в ЮKassa
- [ ] Реализовать проверку подписи
- [ ] Обработать все статусы платежей
- [ ] Настроить возврат в приложение (URL scheme)

### Безопасность:
- [ ] Убрать секретные ключи из кода
- [ ] Использовать Supabase Secrets или Keychain
- [ ] Реализовать проверку подписи webhook'ов
- [ ] Не хранить полные данные карт
- [ ] Использовать токенизацию

### Обработка ошибок:
- [ ] Реализовать возврат средств
- [ ] Обработать все типы ошибок
- [ ] Добавить мониторинг критических ошибок
- [ ] Настроить уведомления администратора

### Тестирование:
- [ ] Протестировать карты (успешные и неудачные)
- [ ] Протестировать СБП
- [ ] Протестировать 3D Secure
- [ ] Протестировать возврат средств
- [ ] Протестировать webhook'и

---

## 🔧 Примеры кода

### Полная интеграция с ЮKassa (упрощенный вариант)

```swift
import Foundation

class YooKassaClient {
    private let shopId: String
    private let secretKey: String
    private let baseURL = "https://api.yookassa.ru/v3"
    
    init(shopId: String, secretKey: String) {
        self.shopId = shopId
        self.secretKey = secretKey
    }
    
    func createPayment(amount: Double, description: String, returnUrl: String) async throws -> Payment {
        let url = URL(string: "\(baseURL)/payments")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(shopId)", forHTTPHeaderField: "Idempotence-Key")
        
        let body: [String: Any] = [
            "amount": [
                "value": String(format: "%.2f", amount),
                "currency": "RUB"
            ],
            "description": description,
            "confirmation": [
                "type": "redirect",
                "return_url": returnUrl
            ],
            "capture": true
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Payment.self, from: data)
    }
    
    private var base64Auth: String {
        let credentials = "\(shopId):\(secretKey)"
        return Data(credentials.utf8).base64EncodedString()
    }
}
```

---

## ✅ Итог

**Для продакшена нужно:**

1. ✅ **Интегрировать реальные платежные системы** (ЮKassa, СБП API)
2. ✅ **Настроить webhook'и** для подтверждения платежей
3. ✅ **Реализовать токенизацию** карт (не хранить полные данные)
4. ✅ **Добавить 3D Secure** для карт
5. ✅ **Реализовать возврат средств** при ошибках
6. ✅ **Настроить безопасность** (ключи в Secrets, проверка подписей)
7. ✅ **Добавить мониторинг** и логирование

**Текущий код готов к интеграции** - нужно заменить симуляцию на реальные API вызовы.
