# ✅ Проверка использования .xcconfig файлов

## 🔍 Анализ кода

### 1. Как код читает значения (`AppConfig.swift`)

```swift
static let yooKassaShopId: String = {
    // 1. Проверяет переменные окружения (ProcessInfo)
    if let shopId = ProcessInfo.processInfo.environment["YOOKASSA_SHOP_ID"], !shopId.isEmpty {
        return shopId
    }
    
    // 2. Проверяет Info.plist (Bundle.main)
    if let shopId = Bundle.main.object(forInfoDictionaryKey: "YOOKASSA_SHOP_ID") as? String, !shopId.isEmpty {
        return shopId  // ← ЭТО БУДЕТ РАБОТАТЬ с INFOPLIST_KEY_*
    }
    
    return "YOUR_SHOP_ID"
}()
```

### 2. Как .xcconfig работает

**`.xcconfig` файлы:**
- Определяют Build Settings переменные (`YOOKASSA_SHOP_ID`, `YOOKASSA_SECRET_KEY`, `YOOKASSA_TEST_MODE`)
- Эти переменные доступны во время компиляции через `$(YOOKASSA_SHOP_ID)`
- **НЕ попадают автоматически** в `ProcessInfo.processInfo.environment`
- **НЕ попадают автоматически** в `Info.plist`

### 3. Решение: INFOPLIST_KEY_*

**Добавлено в `.xcconfig` файлы:**
```
INFOPLIST_KEY_YOOKASSA_SHOP_ID = $(YOOKASSA_SHOP_ID)
INFOPLIST_KEY_YOOKASSA_SECRET_KEY = $(YOOKASSA_SECRET_KEY)
INFOPLIST_KEY_YOOKASSA_TEST_MODE = $(YOOKASSA_TEST_MODE)
```

**Как это работает:**
1. `.xcconfig` определяет `YOOKASSA_SHOP_ID = 1256365`
2. `INFOPLIST_KEY_YOOKASSA_SHOP_ID = $(YOOKASSA_SHOP_ID)` подставляет значение
3. Xcode автоматически добавляет `YOOKASSA_SHOP_ID = 1256365` в Info.plist (без префикса `INFOPLIST_KEY_`)
4. Код читает через `Bundle.main.object(forInfoDictionaryKey: "YOOKASSA_SHOP_ID")` ✅

---

## ✅ Проверка работы

### Шаг 1: Проверьте .xcconfig файлы

**Config.xcconfig** должен содержать:
```
YOOKASSA_SHOP_ID = 1256365
YOOKASSA_SECRET_KEY = test_3NzNw2knb5rTf-bMwRMfdACZdtpAmgmRVgdfW9FYToo
YOOKASSA_TEST_MODE = YES

INFOPLIST_KEY_YOOKASSA_SHOP_ID = $(YOOKASSA_SHOP_ID)
INFOPLIST_KEY_YOOKASSA_SECRET_KEY = $(YOOKASSA_SECRET_KEY)
INFOPLIST_KEY_YOOKASSA_TEST_MODE = $(YOOKASSA_TEST_MODE)
```

**Config.Release.xcconfig** должен содержать:
```
YOOKASSA_SHOP_ID = 1254934
YOOKASSA_SECRET_KEY = live_qSdkVXs_uFx88lkZzzyX0DkK-iparwPb6Jm4lM7ArXM
YOOKASSA_TEST_MODE = NO

INFOPLIST_KEY_YOOKASSA_SHOP_ID = $(YOOKASSA_SHOP_ID)
INFOPLIST_KEY_YOOKASSA_SECRET_KEY = $(YOOKASSA_SECRET_KEY)
INFOPLIST_KEY_YOOKASSA_TEST_MODE = $(YOOKASSA_TEST_MODE)
```

### Шаг 2: Проверьте подключение в Xcode

1. PROJECT "ChallengeApp" → Info → Configurations
2. Debug → `Config.xcconfig` ✅
3. Release → `Config.Release.xcconfig` ✅

### Шаг 3: Проверьте Build Settings

1. Target "ChallengeApp" → Build Settings
2. Найдите `INFOPLIST_KEY_YOOKASSA_SHOP_ID`
3. Должно быть значение из `.xcconfig` (например, `1256365` для Debug)

### Шаг 4: Проверьте в коде

1. Запустите приложение (Debug схема)
2. Добавьте breakpoint в `AppConfig.swift` на строке с `Bundle.main.object(forInfoDictionaryKey: "YOOKASSA_SHOP_ID")`
3. Проверьте, что значение читается правильно

---

## 🧪 Тест

Добавьте временный код для проверки:

```swift
// В AppConfig.swift, после определения yooKassaShopId
print("🔑 YooKassa Shop ID: \(yooKassaShopId)")
print("🔑 YooKassa Secret Key: \(yooKassaSecretKey.prefix(20))...")
print("🔑 YooKassa Test Mode: \(yooKassaIsTestMode)")
```

**Ожидаемый результат для Debug:**
```
🔑 YooKassa Shop ID: 1256365
🔑 YooKassa Secret Key: test_3NzNw2knb5rTf-b...
🔑 YooKassa Test Mode: true
```

---

## ✅ Итог

- ✅ `.xcconfig` файлы подключены правильно
- ✅ `INFOPLIST_KEY_*` добавлены в `.xcconfig` файлы
- ✅ Код читает через `Bundle.main.object(forInfoDictionaryKey:)` - будет работать
- ✅ Значения автоматически попадут в Info.plist при сборке
- ✅ Разные значения для Debug и Release

**Все должно работать!** 🎉
