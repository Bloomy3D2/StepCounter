# План реализации изменений "Ставка на себя"

## 🎯 Архитектура: CORE → GROWTH → MOAT

> **Принцип:** Сначала ядро (жесткость, реальные деньги), потом рост (мягкость earned, AI), потом защита (wearables, privacy).

---

## 📋 СОДЕРЖАНИЕ

1. [LAYER 1 — CORE (MVP)](#layer-1--core-mvp)
2. [LAYER 2 — GROWTH](#layer-2--growth)
3. [LAYER 3 — MOAT](#layer-3--moat)
4. [База данных — изменения](#база-данных--изменения)
5. [Код — структура и паттерны](#код--структура-и-паттерны)
6. [UI/UX — дизайн и анимации](#uiux--дизайн-и-анимации)
7. [Проверки и тестирование](#проверки-и-тестирование)
8. [Масштабируемость](#масштабируемость)

---

## 🔴 LAYER 1 — CORE (MVP)

### Цель: Работающий MVP с жесткими правилами

### 1.1. Обновление Splash/Entry экрана

**Файлы:**
- `Views/SplashView.swift` — полная переработка
- `ChallengeAppApp.swift` — логика навигации

**Изменения:**

#### SplashView.swift
```swift
struct SplashView: View {
    @EnvironmentObject var appState: AppState
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Темный фон
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Логотип (анимация появления)
                Image(systemName: "target")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.5)
                
                // Слоган
                VStack(spacing: 16) {
                    Text("Ставка на себя")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Сорвался — платишь.\nВыдержал — забираешь деньги.")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                // Кнопка "Начать"
                Button(action: {
                    handleStart()
                }) {
                    Text("Начать")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
    }
    
    private func handleStart() {
        Task {
            // Автоматический анонимный вход
            await appState.autoSignIn()
        }
    }
}
```

**Требования:**
- ✅ Анимация появления элементов
- ✅ Темная тема
- ✅ Крупный, читаемый текст
- ✅ Кнопка "Начать" — белая, заметная
- ✅ Автоматический анонимный вход при нажатии

#### ChallengeAppApp.swift
```swift
// Убрать проверку isOnboardingCompleted
// Убрать OnboardingView из навигации
// После Splash → сразу Quick Start или MainTabView
```

---

### 1.2. Quick Start экран

**Файлы:**
- `Views/QuickStartView.swift` — новый файл
- `Managers/ChallengeManager.swift` — метод `createQuickStartChallenge()`

**Изменения:**

#### QuickStartView.swift
```swift
struct QuickStartView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var challengeManager: ChallengeManager
    @State private var isCreating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Заголовок
                VStack(spacing: 16) {
                    Text("Готовы начать?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Попробуйте первый челлендж")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Карточка челленджа
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.yellow)
                        
                        Text("Первый челлендж")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Длительность:")
                            Spacer()
                            Text("1 день")
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Ставка:")
                            Spacer()
                            Text("299 ₽")
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Категория:")
                            Spacer()
                            Text("Привычки")
                                .fontWeight(.semibold)
                        }
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                }
                .padding(24)
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                
                // Кнопка "Начать за 299 ₽"
                Button(action: {
                    handleStartChallenge()
                }) {
                    if isCreating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    } else {
                        Text("Начать за 299 ₽")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.white)
                .cornerRadius(16)
                .disabled(isCreating)
                
                // Кнопка "Выбрать другой"
                Button(action: {
                    // Переход к выбору челленджей
                }) {
                    Text("Выбрать другой")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(24)
        }
        .alert("Ошибка", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleStartChallenge() {
        isCreating = true
        
        Task {
            do {
                // Создать Quick Start челлендж
                let challenge = try await challengeManager.createQuickStartChallenge()
                
                // Перейти к оплате или сразу в активный челлендж
                await MainActor.run {
                    // Навигация
                }
            } catch {
                await MainActor.run {
                    errorMessage = ErrorHandler.handle(error).errorDescription ?? "Не удалось создать челлендж"
                    showingError = true
                    isCreating = false
                }
            }
        }
    }
}
```

**Требования:**
- ✅ Простой, понятный UI
- ✅ Крупная кнопка "Начать"
- ✅ Показ параметров челленджа
- ✅ Обработка ошибок
- ✅ Loading state

---

### 1.3. Честная серия (базовая версия)

**Файлы:**
- `Models/User.swift` — добавить поле `honestStreak`
- `Backend/supabase/schema.sql` — добавить поле в таблицу `users`
- `Managers/ChallengeManager.swift` — логика обновления серии

**Изменения БД:**

```sql
-- Добавить поле честной серии в users
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS honest_streak INTEGER DEFAULT 0 NOT NULL;

-- Индекс для быстрого поиска по серии (для будущих запросов)
CREATE INDEX IF NOT EXISTS idx_users_honest_streak 
ON public.users(honest_streak DESC);
```

**Изменения User.swift:**

```swift
struct User: Codable, Identifiable {
    let id: String
    var name: String
    var email: String?
    var balance: Double
    var authProvider: AuthProvider
    var createdAt: Date
    var honestStreak: Int // НОВОЕ
    
    // ... остальное
}
```

**Изменения ChallengeManager.swift:**

```swift
// После успешного failChallenge (честный провал)
private func updateHonestStreak(userId: String, isHonest: Bool) async {
    guard isHonest else { return }
    
    do {
        // Увеличить честную серию
        try await supabaseManager.incrementHonestStreak(userId: userId)
        
        // Обновить локальный пользователь
        await MainActor.run {
            if var user = appState.currentUser {
                user.honestStreak += 1
                appState.currentUser = user
            }
        }
    } catch {
        Logger.shared.error("Failed to update honest streak", error: error)
    }
}
```

**Требования:**
- ✅ Отслеживание честных провалов
- ✅ Отслеживание честных завершений
- ✅ Отображение в профиле
- ✅ Без влияния на правила (пока)

---

### 1.4. Обновление ActiveChallengeView

**Файлы:**
- `Views/ActiveChallengeView.swift` — добавить таймер до конца дня

**Изменения:**

```swift
struct ActiveChallengeView: View {
    // ... существующий код
    
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        // ... существующий код
        
        // Таймер до конца дня (крупный, заметный)
        VStack(spacing: 8) {
            Text("До конца дня")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            
            Text(formatTimeRemaining(timeRemaining))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
        }
        .padding(24)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
        
        // Кнопки "Выполнил" и "Провалился" (большие, по центру)
        VStack(spacing: 16) {
            Button(action: {
                handleCompleteDay()
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Выполнил")
                }
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(Color.green)
                .cornerRadius(16)
            }
            
            Button(action: {
                handleFailChallenge()
            }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("Провалился")
                }
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(Color.red.opacity(0.3))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red, lineWidth: 2)
                )
            }
        }
        .padding(.horizontal, 24)
        
        // ... остальной код
    }
    
    private func formatTimeRemaining(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func updateTimer() {
        let calendar = Calendar.current
        let now = Date()
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)
        timeRemaining = tomorrow.timeIntervalSince(now)
    }
    
    private func startTimer() {
        updateTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateTimer()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // ... остальные методы
}
```

**Требования:**
- ✅ Таймер до конца дня (крупный, заметный)
- ✅ Кнопки "Выполнил" и "Провалился" — большие, по центру
- ✅ Обновление каждую секунду
- ✅ Остановка таймера при завершении/провале

---

## 🟡 LAYER 2 — GROWTH

### Цель: Удержание и рост (после 100-300 пользователей)

### 2.1. Мягкая дисциплина (earned)

**Файлы:**
- `Backend/supabase/schema.sql` — добавить поля для мягкой дисциплины
- `Models/Challenge.swift` — добавить поля `isSoft`, `restDays`
- `Managers/ChallengeManager.swift` — логика проверки доступа

**Изменения БД:**

```sql
-- Добавить поля для мягкой дисциплины в challenges
ALTER TABLE public.challenges 
ADD COLUMN IF NOT EXISTS is_soft BOOLEAN DEFAULT false NOT NULL,
ADD COLUMN IF NOT EXISTS rest_days INTEGER DEFAULT 0 NOT NULL,
ADD COLUMN IF NOT EXISTS soft_failure_refund_percent DECIMAL(5, 2) DEFAULT 0.0 NOT NULL,
ADD COLUMN IF NOT EXISTS required_honest_streak INTEGER DEFAULT 0 NOT NULL;

-- Индекс для поиска доступных мягких челленджей
CREATE INDEX IF NOT EXISTS idx_challenges_soft_required_streak 
ON public.challenges(is_soft, required_honest_streak) 
WHERE is_soft = true;
```

**Изменения Challenge.swift:**

```swift
struct Challenge: Identifiable, Codable {
    // ... существующие поля
    
    var isSoft: Bool // НОВОЕ
    var restDays: Int // НОВОЕ
    var softFailureRefundPercent: Double // НОВОЕ (0-50%)
    var requiredHonestStreak: Int // НОВОЕ (0, 5, 10, 20)
    
    // Проверка доступности для пользователя
    func isAvailableForUser(honestStreak: Int) -> Bool {
        if !isSoft {
            return true // Обычные челленджи доступны всем
        }
        return honestStreak >= requiredHonestStreak
    }
}
```

**Логика доступа:**

```swift
// В ChallengeManager
func canCreateSoftChallenge(userHonestStreak: Int, requiredStreak: Int) -> Bool {
    return userHonestStreak >= requiredStreak
}

// Градация:
// 0-3: жесткие правила (requiredStreak = 0)
// 5+: восстановительный день (requiredStreak = 5)
// 10+: мягкий провал 30% (requiredStreak = 10)
// 20+: кастомные условия (requiredStreak = 20)
```

**Требования:**
- ✅ Мягкость = заработанная награда
- ✅ Проверка доступа на основе честной серии
- ✅ UI показывает "Доступно с честной серией X"
- ✅ Новичок не может выбрать мягкий режим

---

### 2.2. AI-рекомендации (до/после, не во время)

**Файлы:**
- `Managers/AIRecommendationManager.swift` — новый файл
- `Backend/supabase/schema.sql` — таблица для истории и паттернов
- `Views/ChallengeRecommendationView.swift` — новый файл

**Изменения БД:**

```sql
-- Таблица для хранения паттернов пользователя
CREATE TABLE IF NOT EXISTS public.user_patterns (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    pattern_type TEXT NOT NULL, -- 'FAILURE_DAY', 'SUCCESS_DURATION', 'PREFERRED_CATEGORY'
    pattern_value TEXT NOT NULL, -- JSON с данными паттерна
    confidence DECIMAL(5, 2) DEFAULT 0.0 NOT NULL, -- 0-100%
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE(user_id, pattern_type)
);

-- Индексы
CREATE INDEX IF NOT EXISTS idx_user_patterns_user_id 
ON public.user_patterns(user_id);

-- Функция для анализа паттернов
CREATE OR REPLACE FUNCTION analyze_user_patterns(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    v_patterns JSON;
BEGIN
    -- Анализ: на какой день чаще всего проваливается
    -- Анализ: какая длительность успешнее
    -- Анализ: какая категория успешнее
    -- Возврат JSON с паттернами
    RETURN v_patterns;
END;
$$ LANGUAGE plpgsql;
```

**AIRecommendationManager.swift:**

```swift
@MainActor
class AIRecommendationManager: ObservableObject {
    private let supabaseManager: SupabaseManagerProtocol
    
    init(supabaseManager: SupabaseManagerProtocol) {
        self.supabaseManager = supabaseManager
    }
    
    // Рекомендации ДО старта
    func getRecommendations(userId: String) async throws -> ChallengeRecommendations {
        // 1. Получить паттерны пользователя
        let patterns = try await supabaseManager.getUserPatterns(userId: userId)
        
        // 2. Проанализировать историю
        let history = try await supabaseManager.getUserChallengeHistory(userId: userId)
        
        // 3. Сгенерировать рекомендации
        return generateRecommendations(patterns: patterns, history: history)
    }
    
    // Инсайты ПОСЛЕ завершения
    func getInsights(userChallengeId: Int64) async throws -> ChallengeInsights {
        // Анализ: что помогло, что мешало
        // Паттерны: когда был риск провала
        // Рекомендации: что попробовать дальше
    }
    
    // НИКОГДА не вмешивается во время активного челленджа
}
```

**Требования:**
- ✅ AI только до/после, не во время
- ✅ Показ паттернов ("На 3-й день риск выше")
- ✅ Рекомендации на основе истории
- ✅ Без советов "снизь ставку" или "отдохни"

---

### 2.3. Умные напоминания

**Файлы:**
- `Managers/NotificationManager.swift` — улучшить логику
- `Backend/supabase/schema.sql` — таблица для паттернов активности

**Изменения:**

```swift
// В NotificationManager
func scheduleSmartReminder(userId: String, challengeId: Int64) async {
    // 1. Получить паттерн активности пользователя
    let activityPattern = try await supabaseManager.getUserActivityPattern(userId: userId)
    
    // 2. Определить оптимальное время напоминания
    let reminderTime = calculateOptimalReminderTime(pattern: activityPattern)
    
    // 3. Запланировать напоминание
    scheduleReminder(at: reminderTime, message: "Не забудь подтвердить выполнение")
}

// Напоминания:
// - "Обычно ты подтверждаешь в 22:00, напомнить?"
// - "До конца дня осталось 2 часа"
// - "Ранее в это время ты срывался, будь внимателен"
```

**Требования:**
- ✅ На основе паттернов пользователя
- ✅ Снижают фрустрацию (не забыл)
- ✅ Не снижают ответственность (все равно нужно подтвердить)

---

## 🟢 LAYER 3 — MOAT

### Цель: Защита от конкурентов (после 1000 пользователей)

### 3.1. Wearables (Apple Health)

**Файлы:**
- `Managers/HealthKitManager.swift` — новый файл
- `Models/Challenge.swift` — добавить поле `healthKitType`
- `Views/HealthPermissionView.swift` — новый файл

**Изменения:**

```swift
import HealthKit

@MainActor
class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    // Типы данных для автоматического подтверждения
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
    ]
    
    // Запрос разрешения
    func requestAuthorization() async throws {
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }
    
    // Автоматическое подтверждение на основе данных
    func canAutoConfirm(challenge: Challenge, date: Date) async -> Bool {
        switch challenge.healthKitType {
        case .stepCount(let target):
            let steps = try await getSteps(for: date)
            return steps >= target
        case .sleepAnalysis(let targetHour):
            let wakeTime = try await getWakeTime(for: date)
            return wakeTime <= targetHour
        case .none:
            return false
        }
    }
}
```

**Требования:**
- ✅ Опционально (не обязательно)
- ✅ Только для подтверждения, не для штрафов
- ✅ Всегда можно отключить
- ✅ Прозрачность: "Мы не следим, ты можешь разрешить автоматическое подтверждение"

---

## 📊 БАЗА ДАННЫХ — ИЗМЕНЕНИЯ

### Масштабируемость

**Индексы (уже есть базовые, добавить):**

```sql
-- Для честной серии
CREATE INDEX IF NOT EXISTS idx_users_honest_streak 
ON public.users(honest_streak DESC);

-- Для мягкой дисциплины
CREATE INDEX IF NOT EXISTS idx_challenges_soft_required_streak 
ON public.challenges(is_soft, required_honest_streak) 
WHERE is_soft = true;

-- Для паттернов пользователя
CREATE INDEX IF NOT EXISTS idx_user_patterns_user_id 
ON public.user_patterns(user_id);

-- Для быстрого поиска активных челленджей пользователя
CREATE INDEX IF NOT EXISTS idx_user_challenges_user_active_updated 
ON public.user_challenges(user_id, is_active, updated_at DESC) 
WHERE is_active = true;
```

**Партиционирование (для будущего масштабирования):**

```sql
-- Партиционирование completed_days по дате (если > 1M записей)
-- Пока не нужно, но структура готова
```

**Материализованные виды (для статистики):**

```sql
-- Материализованный вид для статистики пользователя
CREATE MATERIALIZED VIEW IF NOT EXISTS user_statistics AS
SELECT 
    user_id,
    COUNT(*) FILTER (WHERE is_completed = true) as completed_count,
    COUNT(*) FILTER (WHERE is_failed = true) as failed_count,
    SUM(payout) FILTER (WHERE payout IS NOT NULL) as total_earned,
    AVG(EXTRACT(EPOCH FROM (completed_at - entry_date))) as avg_duration
FROM public.user_challenges
GROUP BY user_id;

-- Индекс для быстрого доступа
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_statistics_user_id 
ON user_statistics(user_id);

-- Обновление (можно через триггер или cron)
REFRESH MATERIALIZED VIEW CONCURRENTLY user_statistics;
```

---

## 💻 КОД — СТРУКТУРА И ПАТТЕРНЫ

### Архитектура

**Структура папок:**
```
ChallengeApp/
├── Models/
│   ├── Challenge.swift
│   ├── User.swift
│   ├── UserChallenge.swift
│   └── ChallengeRecommendations.swift (новый)
├── Managers/
│   ├── ChallengeManager.swift
│   ├── SupabaseManager.swift
│   ├── AIRecommendationManager.swift (новый)
│   ├── HealthKitManager.swift (новый)
│   └── NotificationManager.swift
├── Views/
│   ├── SplashView.swift
│   ├── QuickStartView.swift (новый)
│   ├── ActiveChallengeView.swift
│   └── ChallengeRecommendationView.swift (новый)
├── Utils/
│   ├── ErrorHandler.swift
│   ├── Logger.swift
│   └── NetworkRetry.swift
└── Protocols/
    └── ManagerProtocols.swift
```

### Паттерны

**1. Dependency Injection:**
```swift
// Использовать DIContainer для всех зависимостей
let challengeManager = ChallengeManager(
    supabaseManager: DIContainer.shared.supabase,
    cacheManager: DIContainer.shared.cacheManager
)
```

**2. Error Handling:**
```swift
// Всегда использовать ErrorHandler
do {
    try await someOperation()
} catch {
    let appError = ErrorHandler.handle(error)
    Logger.shared.error("Operation failed", error: error)
    // Показать пользователю appError.errorDescription
}
```

**3. Async/Await:**
```swift
// Всегда использовать async/await, не completion handlers
func loadData() async throws -> [Challenge] {
    return try await supabaseManager.getChallenges()
}
```

**4. MainActor:**
```swift
// Все UI-операции на MainActor
@MainActor
class ChallengeManager: ObservableObject {
    @Published var challenges: [Challenge] = []
}
```

### Проверки на ошибки

**1. Валидация входных данных:**
```swift
func createChallenge(duration: Int, entryFee: Double) throws {
    guard duration > 0 && duration <= 30 else {
        throw AppError.invalidData("Длительность должна быть от 1 до 30 дней")
    }
    
    guard entryFee >= 200 && entryFee <= 10000 else {
        throw AppError.invalidData("Ставка должна быть от 200 до 10000 ₽")
    }
}
```

**2. Проверка сетевых ошибок:**
```swift
// Использовать NetworkRetry для автоматических повторов
let result = try await NetworkRetry.execute(maxAttempts: 3) {
    try await supabaseManager.getChallenges()
}
```

**3. Проверка состояния:**
```swift
// Всегда проверять состояние перед операциями
guard let user = appState.currentUser else {
    throw AppError.authenticationRequired
}

guard user.balance >= entryFee else {
    throw AppError.insufficientBalance
}
```

---

## 🎨 UI/UX — ДИЗАЙН И АНИМАЦИИ

### Принципы дизайна

**1. Темная тема:**
- Фон: `Color.black`
- Текст: `Color.white` с opacity для иерархии
- Акценты: `Color.white` для кнопок

**2. Типографика:**
- Заголовки: `.system(size: 28-32, weight: .bold)`
- Подзаголовки: `.system(size: 18-20, weight: .semibold)`
- Текст: `.system(size: 16, weight: .regular)`
- Мелкий текст: `.system(size: 14, weight: .regular)` с opacity 0.7

**3. Отступы:**
- Стандартный: 16-24pt
- Большой: 32-40pt
- Маленький: 8-12pt

**4. Скругления:**
- Карточки: 20pt
- Кнопки: 16pt
- Маленькие элементы: 8-12pt

### Анимации

**1. Появление элементов:**
```swift
.opacity(showContent ? 1 : 0)
.offset(y: showContent ? 0 : 20)
.animation(.easeOut(duration: 0.8), value: showContent)
```

**2. Нажатия кнопок:**
```swift
.scaleEffect(isPressed ? 0.95 : 1.0)
.animation(.spring(response: 0.3), value: isPressed)
```

**3. Загрузка:**
```swift
ProgressView()
    .progressViewStyle(CircularProgressViewStyle(tint: .white))
    .scaleEffect(1.2)
```

### Доступность

**1. Динамический тип:**
```swift
.font(.system(size: 18, weight: .semibold))
.dynamicTypeSize(...dynamicTypeSize)
```

**2. VoiceOver:**
```swift
.accessibilityLabel("Начать челлендж")
.accessibilityHint("Нажмите для начала челленджа на 1 день за 299 рублей")
```

**3. Контрастность:**
- Минимум 4.5:1 для текста
- Минимум 3:1 для UI элементов

---

## ✅ ПРОВЕРКИ И ТЕСТИРОВАНИЕ

### Unit тесты

**Файлы:**
- `ChallengeManagerTests.swift`
- `AIRecommendationManagerTests.swift`
- `HealthKitManagerTests.swift`

**Пример:**
```swift
func testHonestStreakIncrement() async {
    let manager = ChallengeManager(...)
    let initialStreak = user.honestStreak
    
    await manager.failChallenge(userChallenge, isHonest: true)
    
    XCTAssertEqual(user.honestStreak, initialStreak + 1)
}
```

### Integration тесты

**Файлы:**
- `ChallengeFlowTests.swift`
- `PaymentFlowTests.swift`

### UI тесты

**Файлы:**
- `QuickStartUITests.swift`
- `ActiveChallengeUITests.swift`

---

## 📈 МАСШТАБИРУЕМОСТЬ

### Производительность

**1. Кэширование:**
```swift
// Использовать CacheManager для всех данных
cacheManager.cacheChallenges(challenges)
cacheManager.cacheUserChallenges(userChallenges)
```

**2. Ленивая загрузка:**
```swift
// Загружать данные по мере необходимости
LazyVStack {
    ForEach(challenges) { challenge in
        ChallengeCard(challenge: challenge)
            .onAppear {
                if challenge == challenges.last {
                    loadMore()
                }
            }
    }
}
```

**3. Оптимизация запросов:**
```swift
// Использовать пагинацию
func getChallenges(page: Int, limit: Int = 20) async throws -> [Challenge] {
    // Запрос с LIMIT и OFFSET
}
```

### Мониторинг

**1. Логирование:**
```swift
Logger.shared.info("Challenge created", metadata: ["challengeId": challenge.id])
Logger.shared.error("Failed to create challenge", error: error)
```

**2. Метрики:**
- Время загрузки экранов
- Количество ошибок
- Retention rate
- Conversion rate

---

## 📋 ЧЕКЛИСТ РЕАЛИЗАЦИИ

### LAYER 1 — CORE (MVP)

- [ ] Обновить SplashView.swift
- [ ] Создать QuickStartView.swift
- [ ] Добавить честную серию в БД и модель
- [ ] Обновить ActiveChallengeView с таймером
- [ ] Обновить ChallengeAppApp.swift (навигация)
- [ ] Тестирование core flow

### LAYER 2 — GROWTH

- [ ] Добавить мягкую дисциплину в БД
- [ ] Создать AIRecommendationManager
- [ ] Улучшить NotificationManager
- [ ] Добавить статистику
- [ ] Тестирование growth features

### LAYER 3 — MOAT

- [ ] Создать HealthKitManager
- [ ] Добавить Privacy dashboard
- [ ] Улучшить персонализацию
- [ ] Тестирование moat features

---

**Готов приступить к реализации. С чего начинаем?**
