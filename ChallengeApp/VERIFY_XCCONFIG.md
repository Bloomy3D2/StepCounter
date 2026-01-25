# ✅ Проверка настройки .xcconfig файлов

## 🔍 Проблема

Ключи YooKassa не попадают в `Info.plist` при runtime, хотя они настроены в `.xcconfig` файлах.

## ✅ Что было исправлено

1. ✅ Удалены дублирующие `INFOPLIST_KEY_*` из `project.pbxproj`
2. ✅ Теперь значения берутся ТОЛЬКО из `.xcconfig` файлов
3. ✅ `.xcconfig` файлы правильно подключены через `baseConfigurationReferenceRelativePath`

## 📋 Шаги для проверки

### Шаг 1: Очистка проекта

1. В Xcode: **Product** → **Clean Build Folder** (⇧⌘K)
2. Закройте Xcode полностью
3. Откройте Xcode снова

### Шаг 2: Проверка Build Settings в Xcode

1. Откройте проект в Xcode
2. Выберите **Target "ChallengeApp"**
3. Перейдите на вкладку **"Build Settings"**
4. В поиске введите: `INFOPLIST_KEY_YOOKASSA`
5. **Проверьте**, что видны значения:
   - `INFOPLIST_KEY_YOOKASSA_SHOP_ID` = `1256365` (для Debug)
   - `INFOPLIST_KEY_YOOKASSA_SECRET_KEY` = `test_3NzNw2knb5rTf-bMwRMfdACZdtpAmgmRVgdfW9FYToo` (для Debug)
   - `INFOPLIST_KEY_YOOKASSA_TEST_MODE` = `YES` (для Debug)

**Если значений НЕТ:**
- Проверьте, что `.xcconfig` файлы подключены:
  - Debug → `Config.xcconfig`
  - Release → `Config.Release.xcconfig`
- Проверьте путь к файлам в `project.pbxproj`:
  - `baseConfigurationReferenceRelativePath = Config.xcconfig`

### Шаг 3: Проверка переменных YOOKASSA_*

1. В **Build Settings** введите в поиск: `YOOKASSA_SHOP_ID`
2. **Проверьте**, что видны значения:
   - `YOOKASSA_SHOP_ID` = `1256365` (для Debug)
   - `YOOKASSA_SECRET_KEY` = `test_3NzNw2knb5rTf-bMwRMfdACZdtpAmgmRVgdfW9FYToo` (для Debug)
   - `YOOKASSA_TEST_MODE` = `YES` (для Debug)

**Если значений НЕТ:**
- `.xcconfig` файлы не загружаются правильно
- Проверьте синтаксис в `.xcconfig` файлах (нет ли опечаток)

### Шаг 4: Пересборка и проверка

1. **Product** → **Build** (⌘B)
2. Запустите приложение
3. Проверьте логи - должно быть:
   ```
   🔍 AppConfig: Found YOOKASSA_SHOP_ID in Info.plist: 1256365
   🔑 AppConfig: YooKassa Shop ID from Info.plist: 1256365
   ```

## 🔧 Если все еще не работает

### Альтернативное решение: Build Script

Если `.xcconfig` файлы все еще не работают, можно использовать Build Script для явного копирования значений в `Info.plist`.

1. Создайте файл `ChallengeApp/scripts/inject-yookassa-keys.sh`:
   ```bash
   #!/bin/bash
   
   # Получаем путь к сгенерированному Info.plist
   PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
   
   # Проверяем, что файл существует
   if [ ! -f "$PLIST" ]; then
       echo "⚠️ Info.plist not found at: $PLIST"
       exit 0
   fi
   
   # Вставляем значения из Build Settings
   /usr/libexec/PlistBuddy -c "Set :YOOKASSA_SHOP_ID ${YOOKASSA_SHOP_ID}" "$PLIST" 2>/dev/null || \
   /usr/libexec/PlistBuddy -c "Add :YOOKASSA_SHOP_ID string ${YOOKASSA_SHOP_ID}" "$PLIST"
   
   /usr/libexec/PlistBuddy -c "Set :YOOKASSA_SECRET_KEY ${YOOKASSA_SECRET_KEY}" "$PLIST" 2>/dev/null || \
   /usr/libexec/PlistBuddy -c "Add :YOOKASSA_SECRET_KEY string ${YOOKASSA_SECRET_KEY}" "$PLIST"
   
   /usr/libexec/PlistBuddy -c "Set :YOOKASSA_TEST_MODE ${YOOKASSA_TEST_MODE}" "$PLIST" 2>/dev/null || \
   /usr/libexec/PlistBuddy -c "Add :YOOKASSA_TEST_MODE string ${YOOKASSA_TEST_MODE}" "$PLIST"
   
   echo "✅ YooKassa keys injected into Info.plist"
   ```

2. В Xcode:
   - Target "ChallengeApp" → **Build Phases**
   - Нажмите **"+"** → **"New Run Script Phase"**
   - Переместите его **ПОСЛЕ** "Copy Bundle Resources"
   - Вставьте: `"${SRCROOT}/ChallengeApp/scripts/inject-yookassa-keys.sh"`
   - Убедитесь, что **"Run script only when installing"** = **НЕ ВКЛЮЧЕНА**

3. Сделайте скрипт исполняемым:
   ```bash
   chmod +x ChallengeApp/scripts/inject-yookassa-keys.sh
   ```

## 📝 Примечания

- `.xcconfig` файлы должны быть в `.gitignore` (уже добавлены)
- После изменений в `.xcconfig` всегда делайте **Clean Build Folder**
- Проверяйте значения в Build Settings перед сборкой
