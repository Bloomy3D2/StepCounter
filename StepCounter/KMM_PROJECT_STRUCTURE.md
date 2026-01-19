# Структура Kotlin Multiplatform Mobile проекта

## 📁 Структура директорий

```
StepCounterKMM/
├── build.gradle.kts                    # Корневой Gradle файл
├── settings.gradle.kts                 # Настройки проекта
├── gradle.properties                   # Свойства Gradle
│
├── shared/                             # Общий модуль (Kotlin)
│   ├── build.gradle.kts
│   ├── src/
│   │   ├── commonMain/                 # Общий код для всех платформ
│   │   │   ├── kotlin/
│   │   │   │   ├── models/             # Модели данных
│   │   │   │   │   ├── UserModel.kt
│   │   │   │   │   ├── Achievement.kt
│   │   │   │   │   ├── Challenge.kt
│   │   │   │   │   ├── Pet.kt
│   │   │   │   │   ├── Level.kt
│   │   │   │   │   └── ...
│   │   │   │   ├── managers/           # Бизнес-логика
│   │   │   │   │   ├── AchievementManager.kt
│   │   │   │   │   ├── ChallengeManager.kt
│   │   │   │   │   ├── PetManager.kt
│   │   │   │   │   ├── LevelManager.kt
│   │   │   │   │   └── ...
│   │   │   │   ├── platform/           # Платформенные интерфейсы
│   │   │   │   │   ├── HealthPlatform.kt
│   │   │   │   │   ├── LocationPlatform.kt
│   │   │   │   │   ├── BillingPlatform.kt
│   │   │   │   │   ├── StoragePlatform.kt
│   │   │   │   │   └── NotificationPlatform.kt
│   │   │   │   └── utils/              # Утилиты
│   │   │   │       ├── Constants.kt
│   │   │   │       └── Extensions.kt
│   │   │   │
│   │   ├── androidMain/                # Android-специфичный код
│   │   │   ├── kotlin/
│   │   │   │   └── platform/
│   │   │   │       ├── HealthPlatform.android.kt    # Google Fit
│   │   │   │       ├── LocationPlatform.android.kt  # Android Location
│   │   │   │       ├── BillingPlatform.android.kt   # Play Billing
│   │   │   │       ├── StoragePlatform.android.kt    # SharedPreferences
│   │   │   │       └── NotificationPlatform.android.kt
│   │   │   └── res/                    # Android ресурсы
│   │   │
│   │   └── iosMain/                    # iOS-специфичный код
│   │       └── kotlin/
│   │           └── platform/
│   │               ├── HealthPlatform.ios.kt        # HealthKit
│   │               ├── LocationPlatform.ios.kt      # CoreLocation
│   │               ├── BillingPlatform.ios.kt       # StoreKit
│   │               ├── StoragePlatform.ios.kt       # UserDefaults
│   │               └── NotificationPlatform.ios.kt   # UserNotifications
│   │
│   └── commonTest/                     # Общие тесты
│       └── kotlin/
│
├── androidApp/                          # Android приложение
│   ├── build.gradle.kts
│   ├── src/
│   │   └── main/
│   │       ├── AndroidManifest.xml
│   │       ├── java/com/stepcounter/
│   │       │   ├── MainActivity.kt
│   │       │   └── StepCounterApplication.kt
│   │       └── res/                     # Android ресурсы
│   │           ├── layout/
│   │           ├── values/
│   │           └── drawable/
│   │
│   └── ui/                              # Jetpack Compose UI
│       ├── screens/
│       │   ├── HomeScreen.kt
│       │   ├── StatsScreen.kt
│       │   ├── PetScreen.kt
│       │   ├── RoutesScreen.kt
│       │   ├── ChallengesScreen.kt
│       │   ├── AchievementsScreen.kt
│       │   ├── ProfileScreen.kt
│       │   └── SettingsScreen.kt
│       ├── components/
│       │   ├── StatCard.kt
│       │   ├── AchievementPopup.kt
│       │   └── ...
│       └── theme/
│           ├── Color.kt
│           ├── Typography.kt
│           └── Theme.kt
│
└── iosApp/                              # iOS приложение (существующий)
    ├── StepCounterApp.swift
    ├── Views/                           # SwiftUI (остается как есть)
    └── Models/                          # Использует shared модуль
```

---

## 🔧 Примеры кода

### 1. Платформенный интерфейс (expect)

```kotlin
// shared/commonMain/kotlin/platform/HealthPlatform.kt
expect class HealthPlatform {
    suspend fun requestAuthorization(): Boolean
    suspend fun getTodaySteps(): Int
    suspend fun getTodayDistance(): Double
    suspend fun getTodayCalories(): Double
    suspend fun getHourlySteps(): List<HourlyStepData>
    fun observeSteps(callback: (Int) -> Unit)
}
```

### 2. Android реализация (actual)

```kotlin
// shared/androidMain/kotlin/platform/HealthPlatform.android.kt
import com.google.android.gms.fitness.Fitness
import com.google.android.gms.fitness.data.DataType

actual class HealthPlatform {
    private val fitnessOptions = FitnessOptions.builder()
        .addDataType(DataType.TYPE_STEP_COUNT_DELTA, FitnessOptions.ACCESS_READ)
        .addDataType(DataType.TYPE_DISTANCE_DELTA, FitnessOptions.ACCESS_READ)
        .addDataType(DataType.TYPE_CALORIES_EXPENDED, FitnessOptions.ACCESS_READ)
        .build()
    
    actual suspend fun requestAuthorization(): Boolean {
        // Запрос разрешений Google Fit
        return try {
            Fitness.getConfigClient(context)
                .requestAuthorization(fitnessOptions)
                .await()
            true
        } catch (e: Exception) {
            false
        }
    }
    
    actual suspend fun getTodaySteps(): Int {
        // Получение шагов через Google Fit
        val dataSource = DataSource.Builder()
            .setDataType(DataType.TYPE_STEP_COUNT_DELTA)
            .setType(DataSource.TYPE_RAW)
            .build()
        
        // ... реализация получения данных
        return steps
    }
    
    // ... остальные методы
}
```

### 3. iOS реализация (actual)

```kotlin
// shared/iosMain/kotlin/platform/HealthPlatform.ios.kt
import platform.HealthKit.*

actual class HealthPlatform {
    private val healthStore = HKHealthStore()
    
    actual suspend fun requestAuthorization(): Boolean {
        // Запрос разрешений HealthKit
        val stepType = HKQuantityType.quantityTypeForIdentifier(
            HKQuantityTypeIdentifierStepCount
        ) ?: return false
        
        return suspendCoroutine { continuation ->
            healthStore.requestAuthorizationToShareTypes(
                null,
                setOf(stepType)
            ) { success, error ->
                continuation.resume(success)
            }
        }
    }
    
    actual suspend fun getTodaySteps(): Int {
        // Получение шагов через HealthKit
        // ... реализация
        return steps
    }
    
    // ... остальные методы
}
```

### 4. Общий менеджер (использует платформенный интерфейс)

```kotlin
// shared/commonMain/kotlin/managers/HealthManager.kt
class HealthManager(
    private val healthPlatform: HealthPlatform
) {
    private var _todaySteps = MutableStateFlow(0)
    val todaySteps: StateFlow<Int> = _todaySteps.asStateFlow()
    
    suspend fun requestAuthorization() {
        val authorized = healthPlatform.requestAuthorization()
        if (authorized) {
            loadTodaySteps()
        }
    }
    
    private suspend fun loadTodaySteps() {
        val steps = healthPlatform.getTodaySteps()
        _todaySteps.value = steps
    }
    
    fun startObserving() {
        healthPlatform.observeSteps { steps ->
            _todaySteps.value = steps
        }
    }
}
```

### 5. Android UI (Jetpack Compose)

```kotlin
// androidApp/ui/screens/HomeScreen.kt
@Composable
fun HomeScreen(
    viewModel: HomeViewModel = viewModel()
) {
    val steps by viewModel.todaySteps.collectAsState()
    val goal by viewModel.stepGoal.collectAsState()
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        Color(0xFF1A1A2E),
                        Color(0xFF16213E)
                    )
                )
            )
    ) {
        // Заголовок
        Text(
            text = "Сегодня",
            style = MaterialTheme.typography.h4,
            modifier = Modifier.padding(16.dp)
        )
        
        // Круг прогресса
        CircularProgressIndicator(
            progress = (steps.toFloat() / goal),
            modifier = Modifier.size(200.dp)
        )
        
        // Статистика
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            StatCard(
                icon = Icons.Default.DirectionsWalk,
                value = "$steps",
                label = "Шаги"
            )
            StatCard(
                icon = Icons.Default.Straighten,
                value = "${viewModel.distance}м",
                label = "Дистанция"
            )
        }
    }
}
```

---

## 📦 Зависимости

### shared/build.gradle.kts
```kotlin
kotlin {
    android()
    ios()
    
    sourceSets {
        val commonMain by getting {
            dependencies {
                implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
                implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.0")
            }
        }
        
        val androidMain by getting {
            dependencies {
                implementation("com.google.android.gms:play-services-fitness:21.0.1")
                implementation("com.google.android.gms:play-services-location:21.0.1")
                implementation("com.android.billingclient:billing-ktx:6.0.1")
            }
        }
        
        val iosMain by getting {
            // iOS зависимости через CocoaPods или SPM
        }
    }
}
```

### androidApp/build.gradle.kts
```kotlin
dependencies {
    implementation(project(":shared"))
    implementation("androidx.compose.ui:ui:1.5.4")
    implementation("androidx.compose.material3:material3:1.1.2")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.6.2")
}
```

---

## 🎯 Преимущества такой структуры

1. **Общая бизнес-логика** - все менеджеры в одном месте
2. **Платформенная абстракция** - легко менять реализации
3. **Нативный UI** - лучший UX на каждой платформе
4. **Легкое тестирование** - общую логику можно тестировать отдельно
5. **Масштабируемость** - легко добавлять новые платформы (Desktop, Web)

---

Готов начать создание этой структуры, если нужно!
