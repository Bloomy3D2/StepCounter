# 🔍 Проверка использования .xcconfig файлов

## ✅ Что проверено

### 1. `.xcconfig` файлы подключены правильно

В `project.pbxproj` видно:
- **Debug**: `baseConfigurationReferenceRelativePath = Config.xcconfig;` ✅
- **Release**: `baseConfigurationReferenceRelativePath = Config.Release.xcconfig;` ✅

### 2. Проблема: Как код читает значения

**Текущий код в `AppConfig.swift`:**
```swift
static let yooKassaShopId: String = {
    // 1. Проверяет переменные окружения
    if let shopId = ProcessInfo.processInfo.environment["YOOKASSA_SHOP_ID"] {
        return shopId
    }
    
    // 2. Проверяет Info.plist
    if let shopId = Bundle.main.object(forInfoDictionaryKey: "YOOKASSA_SHOP_ID") as? String {
        return shopId
    }
    
    return "YOUR_SHOP_ID"
}()
```

**Проблема:**
- `.xcconfig` файлы определяют Build Settings переменные
- Эти переменные **НЕ попадают автоматически** в `ProcessInfo.processInfo.environment`
- Эти переменные **НЕ попадают автоматически** в `Info.plist`

---

## 🔧 Решение: Добавить значения в Info.plist через Build Settings

### Вариант 1: Через INFOPLIST_KEY_* (рекомендуется)

Добавьте в `.xcconfig` файлы:

**Config.xcconfig:**
```
YOOKASSA_SHOP_ID = 1256365
YOOKASSA_SECRET_KEY = test_3NzNw2knb5rTf-bMwRMfdACZdtpAmgmRVgdfW9FYToo
YOOKASSA_TEST_MODE = YES

# Добавляем в Info.plist через Build Settings
INFOPLIST_KEY_YOOKASSA_SHOP_ID = $(YOOKASSA_SHOP_ID)
INFOPLIST_KEY_YOOKASSA_SECRET_KEY = $(YOOKASSA_SECRET_KEY)
INFOPLIST_KEY_YOOKASSA_TEST_MODE = $(YOOKASSA_TEST_MODE)
```

**Config.Release.xcconfig:**
```
YOOKASSA_SHOP_ID = 1254934
YOOKASSA_SECRET_KEY = live_qSdkVXs_uFx88lkZzzyX0DkK-iparwPb6Jm4lM7ArXM
YOOKASSA_TEST_MODE = NO

# Добавляем в Info.plist через Build Settings
INFOPLIST_KEY_YOOKASSA_SHOP_ID = $(YOOKASSA_SHOP_ID)
INFOPLIST_KEY_YOOKASSA_SECRET_KEY = $(YOOKASSA_SECRET_KEY)
INFOPLIST_KEY_YOOKASSA_TEST_MODE = $(YOOKASSA_TEST_MODE)
```

**Обновите код в `AppConfig.swift`:**
```swift
static let yooKassaShopId: String = {
    // INFOPLIST_KEY_* автоматически добавляются в Info.plist с префиксом
    if let shopId = Bundle.main.object(forInfoDictionaryKey: "YOOKASSA_SHOP_ID") as? String, !shopId.isEmpty {
        return shopId
    }
    return "YOUR_SHOP_ID"
}()
```

### Вариант 2: Создать Info.plist вручную

1. Создайте `Info.plist` в папке `ChallengeApp/ChallengeApp/`
2. Добавьте:
```xml
<key>YOOKASSA_SHOP_ID</key>
<string>$(YOOKASSA_SHOP_ID)</string>
<key>YOOKASSA_SECRET_KEY</key>
<string>$(YOOKASSA_SECRET_KEY)</string>
<key>YOOKASSA_TEST_MODE</key>
<$(YOOKASSA_TEST_MODE)/>
```
3. В Build Settings укажите: `INFOPLIST_FILE = ChallengeApp/Info.plist`
4. Отключите `GENERATE_INFOPLIST_FILE = NO`

---

## ✅ Рекомендуемое решение

**Использовать INFOPLIST_KEY_* в .xcconfig файлах** - это самый простой способ, который работает с `GENERATE_INFOPLIST_FILE = YES`.
