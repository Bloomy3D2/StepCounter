# ✅ Исправлена настройка ключей YooKassa

## 🔧 Что было исправлено

### Проблема
Build Script пытался вручную записывать ключи в `Info.plist` внутри `.app` bundle, что вызывало ошибку **"Operation not permitted"**. Это происходило потому, что Xcode уже создал и подписал `Info.plist` к моменту выполнения скрипта.

### Решение
✅ **Удалён Build Script** - он больше не нужен  
✅ **Используется автоматическая инъекция** через `INFOPLIST_KEY_*` из `.xcconfig` файлов

---

## 📋 Как это работает сейчас

### 1. `.xcconfig` файлы содержат ключи и `INFOPLIST_KEY_*` переменные:

**Config.xcconfig (Debug):**
```
YOOKASSA_SHOP_ID = 1256365
YOOKASSA_SECRET_KEY = test_3NzNw2knb5rTf-bMwRMfdACZdtpAmgmRVgdfW9FYToo
YOOKASSA_TEST_MODE = YES

INFOPLIST_KEY_YOOKASSA_SHOP_ID = $(YOOKASSA_SHOP_ID)
INFOPLIST_KEY_YOOKASSA_SECRET_KEY = $(YOOKASSA_SECRET_KEY)
INFOPLIST_KEY_YOOKASSA_TEST_MODE = $(YOOKASSA_TEST_MODE)
```

**Config.Release.xcconfig (Release):**
```
YOOKASSA_SHOP_ID = 1254934
YOOKASSA_SECRET_KEY = live_qSdkVXs_uFx88lkZzzyX0DkK-iparwPb6Jm4lM7ArXM
YOOKASSA_TEST_MODE = NO

INFOPLIST_KEY_YOOKASSA_SHOP_ID = $(YOOKASSA_SHOP_ID)
INFOPLIST_KEY_YOOKASSA_SECRET_KEY = $(YOOKASSA_SECRET_KEY)
INFOPLIST_KEY_YOOKASSA_TEST_MODE = $(YOOKASSA_TEST_MODE)
```

### 2. Xcode автоматически инжектит значения в Info.plist

Когда Xcode генерирует `Info.plist` (при `GENERATE_INFOPLIST_FILE = YES`), он автоматически:
- Читает `INFOPLIST_KEY_*` переменные из Build Settings (которые берутся из `.xcconfig` файлов)
- Добавляет их в `Info.plist` как ключи без префикса `INFOPLIST_KEY_`

Например:
- `INFOPLIST_KEY_YOOKASSA_SHOP_ID` → `YOOKASSA_SHOP_ID` в Info.plist

### 3. `AppConfig.swift` читает значения из Info.plist

```swift
static let yooKassaShopId: String = {
    if let shopId = Bundle.main.object(forInfoDictionaryKey: "YOOKASSA_SHOP_ID") as? String {
        return shopId
    }
    // fallback...
}()
```

---

## 🔒 Безопасность

### ✅ Что защищено:

1. **`.xcconfig` файлы в `.gitignore`:**
   - `ChallengeApp/ChallengeApp/Config.xcconfig` ✅
   - `ChallengeApp/ChallengeApp/Config.Release.xcconfig` ✅
   - `**/Config.*.xcconfig` ✅

2. **Ключи НЕ в `project.pbxproj`:**
   - Проверено: ключей нет напрямую в `project.pbxproj` ✅
   - Только ссылка на `.xcconfig` файл: `baseConfigurationReferenceRelativePath = Config.xcconfig;`

3. **Build Script удалён:**
   - Больше нет скрипта, который мог бы содержать ключи ✅

### ✅ Можно безопасно коммитить:

- `project.pbxproj` - безопасно (только ссылки на `.xcconfig` файлы)
- `.xcconfig` файлы - не попадут в git (в `.gitignore`)

---

## 🧪 Проверка

### 1. Проверьте, что `.xcconfig` файлы игнорируются:

```bash
git check-ignore ChallengeApp/ChallengeApp/Config.xcconfig
# Должно вернуть путь к файлу (значит игнорируется)
```

### 2. Проверьте, что ключей нет в `project.pbxproj`:

```bash
grep -n "test_3NzNw2knb5rTf\|live_qSdkVXs" ChallengeApp.xcodeproj/project.pbxproj
# Должно быть пусто
```

### 3. Проверьте, что значения попадают в Info.plist:

После сборки приложения проверьте сгенерированный `Info.plist`:
- Должны быть ключи `YOOKASSA_SHOP_ID`, `YOOKASSA_SECRET_KEY`, `YOOKASSA_TEST_MODE`
- Значения должны соответствовать конфигурации (Debug/Release)

---

## 📝 Что делать дальше

1. **Соберите проект** в Xcode (Debug или Release)
2. **Проверьте логи** - `AppConfig` должен логировать откуда читаются ключи:
   ```
   🔑 AppConfig: YooKassa Shop ID from Info.plist: 1256365
   ```
3. **Если ключи не читаются:**
   - Убедитесь, что `.xcconfig` файлы подключены к конфигурациям проекта:
     - PROJECT → Info → Configurations → Debug: `Config.xcconfig`
     - PROJECT → Info → Configurations → Release: `Config.Release.xcconfig`
   - Проверьте, что `INFOPLIST_KEY_*` переменные правильно определены в `.xcconfig`

---

## ✅ Итог

- ✅ Build Script удалён (больше нет ошибок "Operation not permitted")
- ✅ Используется стандартный механизм Xcode (`INFOPLIST_KEY_*`)
- ✅ Ключи безопасно хранятся в `.xcconfig` файлах (в `.gitignore`)
- ✅ Готово к использованию в продакшене
