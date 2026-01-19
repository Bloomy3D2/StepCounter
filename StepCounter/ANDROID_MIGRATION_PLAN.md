# План миграции StepCounter на Android

## 📱 Варианты портирования

### ✅ Рекомендуемый: Kotlin Multiplatform Mobile (KMM)

**Архитектура:**
```
StepCounter/
├── shared/                    # Общий код (Kotlin)
│   ├── commonMain/           # Общая бизнес-логика
│   │   ├── models/           # Модели данных
│   │   ├── managers/         # Менеджеры (логика)
│   │   └── utils/            # Утилиты
│   ├── androidMain/          # Android-специфичный код
│   │   └── platform/         # Android реализации
│   └── iosMain/              # iOS-специфичный код
│       └── platform/         # iOS реализации
├── androidApp/                # Android UI (Jetpack Compose)
│   └── ui/                   # Compose экраны
└── iosApp/                    # iOS UI (SwiftUI) - существующий
    └── Views/                # SwiftUI экраны
```

**Преимущества:**
- ✅ Общая бизнес-логика (28 моделей + менеджеры)
- ✅ Нативный UI на каждой платформе
- ✅ Переиспользование кода ~70-80%
- ✅ Один код для сетей, БД, логики

**Что нужно переписать:**
- ❌ UI слой (SwiftUI → Jetpack Compose)
- ❌ Платформенные интеграции (HealthKit → Google Fit, StoreKit → Google Play Billing)

---

## 🔄 Маппинг iOS → Android API

### HealthKit → Google Fit
```kotlin
// iOS: HealthKit
import HealthKit

// Android: Google Fit
implementation("com.google.android.gms:play-services-fitness:21.0.1")
```

### StoreKit → Google Play Billing
```kotlin
// iOS: StoreKit
import StoreKit

// Android: Google Play Billing
implementation("com.android.billingclient:billing-ktx:6.0.1")
```

### CoreLocation → Android Location Services
```kotlin
// iOS: CoreLocation
import CoreLocation

// Android: Location Services
implementation("com.google.android.gms:play-services-location:21.0.1")
```

### MapKit → Google Maps
```kotlin
// iOS: MapKit
import MapKit

// Android: Google Maps
implementation("com.google.android.gms:play-services-maps:18.2.0")
```

### ARKit → ARCore
```kotlin
// iOS: ARKit
import ARKit

// Android: ARCore
implementation("com.google.ar:core:1.40.0")
```

### UserNotifications → Android Notifications
```kotlin
// iOS: UserNotifications
import UserNotifications

// Android: NotificationManager (встроенный)
```

---

## 📋 План миграции по этапам

### Этап 1: Настройка KMM проекта (1-2 дня)
1. Создать структуру KMM проекта
2. Настроить Gradle для iOS и Android
3. Настроить общие зависимости

### Этап 2: Миграция моделей (3-5 дней)
- [ ] UserModel
- [ ] Achievement
- [ ] Challenge
- [ ] Pet
- [ ] Level
- [ ] Tournament
- [ ] Season
- [ ] LocationChallenge
- И другие модели...

**Пример миграции:**
```kotlin
// shared/commonMain/kotlin/models/UserModel.kt
data class UserModel(
    val id: String,
    val name: String,
    val email: String,
    val level: Int,
    val xp: Int,
    val rank: PlayerRank
)
```

### Этап 3: Платформенные интерфейсы (5-7 дней)
Создать expect/actual для платформенных функций:

```kotlin
// shared/commonMain/kotlin/platform/HealthPlatform.kt
expect class HealthPlatform {
    suspend fun requestAuthorization(): Boolean
    suspend fun getTodaySteps(): Int
    suspend fun getTodayDistance(): Double
    suspend fun getTodayCalories(): Double
}

// shared/androidMain/kotlin/platform/HealthPlatform.android.kt
actual class HealthPlatform {
    // Реализация через Google Fit
}

// shared/iosMain/kotlin/platform/HealthPlatform.ios.kt
actual class HealthPlatform {
    // Реализация через HealthKit
}
```

### Этап 4: Миграция менеджеров (10-15 дней)
- [ ] AchievementManager
- [ ] ChallengeManager
- [ ] PetManager
- [ ] LevelManager
- [ ] TournamentManager
- [ ] SeasonManager
- [ ] ThemeManager
- [ ] StorageManager
- И другие...

**Пример:**
```kotlin
// shared/commonMain/kotlin/managers/AchievementManager.kt
class AchievementManager(
    private val healthPlatform: HealthPlatform,
    private val storage: StorageManager
) {
    fun checkAchievements(steps: Int) {
        // Общая логика проверки достижений
    }
}
```

### Этап 5: Android UI (15-20 дней)
Переписать все экраны на Jetpack Compose:

- [ ] HomeView → HomeScreen.kt
- [ ] StatsView → StatsScreen.kt
- [ ] PetView → PetScreen.kt
- [ ] RoutesView → RoutesScreen.kt
- [ ] ChallengesView → ChallengesScreen.kt
- [ ] AchievementsView → AchievementsScreen.kt
- [ ] ProfileView → ProfileScreen.kt
- [ ] SettingsView → SettingsScreen.kt
- И другие...

**Пример:**
```kotlin
// androidApp/ui/screens/HomeScreen.kt
@Composable
fun HomeScreen(
    viewModel: HomeViewModel,
    onNavigate: (Screen) -> Unit
) {
    // Compose UI
}
```

### Этап 6: Интеграция платформенных сервисов (7-10 дней)
- [ ] Google Fit интеграция
- [ ] Google Play Billing
- [ ] Google Maps
- [ ] ARCore (опционально)
- [ ] Push уведомления

### Этап 7: Тестирование и оптимизация (5-7 дней)
- [ ] Unit тесты для общей логики
- [ ] UI тесты для Android
- [ ] Интеграционное тестирование
- [ ] Оптимизация производительности

---

## 📊 Оценка времени

| Этап | Время | Сложность |
|------|-------|-----------|
| Настройка KMM | 1-2 дня | Средняя |
| Миграция моделей | 3-5 дней | Низкая |
| Платформенные интерфейсы | 5-7 дней | Высокая |
| Миграция менеджеров | 10-15 дней | Средняя |
| Android UI | 15-20 дней | Средняя |
| Интеграция сервисов | 7-10 дней | Высокая |
| Тестирование | 5-7 дней | Средняя |
| **ИТОГО** | **46-66 дней** | - |

---

## 🛠️ Необходимые инструменты

1. **Android Studio** (последняя версия)
2. **Kotlin Multiplatform Mobile Plugin**
3. **Xcode** (для iOS части)
4. **Google Fit API** ключ
5. **Google Maps API** ключ
6. **Google Play Console** аккаунт

---

## 📚 Полезные ресурсы

- [Kotlin Multiplatform Mobile документация](https://kotlinlang.org/docs/multiplatform-mobile-getting-started.html)
- [Jetpack Compose документация](https://developer.android.com/jetpack/compose)
- [Google Fit API](https://developers.google.com/fit)
- [Google Play Billing](https://developer.android.com/google/play/billing)

---

## ⚠️ Важные замечания

1. **HealthKit vs Google Fit**: Разные API, нужна адаптация
2. **StoreKit vs Play Billing**: Разные модели подписок
3. **UI различия**: Material Design vs iOS Human Interface Guidelines
4. **Разрешения**: Android требует runtime разрешения
5. **Фоновые задачи**: Разные подходы к background work

---

## 🚀 Быстрый старт

Если хотите начать миграцию, я могу:
1. Создать структуру KMM проекта
2. Настроить Gradle конфигурацию
3. Начать миграцию моделей
4. Создать платформенные интерфейсы

Скажите, с чего начать?
