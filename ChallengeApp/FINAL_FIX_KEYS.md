# 🔧 Финальное исправление чтения ключей

## ❌ Проблема

Значения из `.xcconfig` и User-Defined Settings не читаются в runtime. Код получает `YOUR_SHOP_ID` вместо реальных значений.

**Причина:** Build Settings переменные не попадают автоматически в `Bundle.main.object(forInfoDictionaryKey:)` при `GENERATE_INFOPLIST_FILE = YES`.

---

## ✅ Решение: Добавить Build Script

Создать Build Script, который будет копировать значения из Build Settings в Info.plist во время сборки.

### Шаг 1: Создать скрипт

Создайте файл `scripts/copy-yookassa-keys.sh`:

```bash
#!/bin/bash

# Копируем значения из Build Settings в Info.plist
PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

if [ -f "$PLIST" ]; then
    /usr/libexec/PlistBuddy -c "Set :YOOKASSA_SHOP_ID ${YOOKASSA_SHOP_ID}" "$PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :YOOKASSA_SHOP_ID string ${YOOKASSA_SHOP_ID}" "$PLIST"
    
    /usr/libexec/PlistBuddy -c "Set :YOOKASSA_SECRET_KEY ${YOOKASSA_SECRET_KEY}" "$PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :YOOKASSA_SECRET_KEY string ${YOOKASSA_SECRET_KEY}" "$PLIST"
    
    /usr/libexec/PlistBuddy -c "Set :YOOKASSA_TEST_MODE ${YOOKASSA_TEST_MODE}" "$PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :YOOKASSA_TEST_MODE bool ${YOOKASSA_TEST_MODE}" "$PLIST"
fi
```

### Шаг 2: Добавить Build Phase

1. В Xcode: Target "ChallengeApp" → Build Phases
2. Нажмите "+" → "New Run Script Phase"
3. Добавьте скрипт выше
4. Переместите его **ПОСЛЕ** "Copy Bundle Resources"

---

## 🔄 Альтернатива: Использовать User-Defined Settings напрямую

Если Build Script не работает, можно использовать User-Defined Settings, которые мы добавили в `project.pbxproj`. Они уже там есть и должны работать через `INFOPLIST_KEY_*`.

**Проверка:** После пересборки проверьте логи - должно быть:
```
🔑 AppConfig: YooKassa Shop ID from Info.plist: 1256365
```

Если этого нет - значит значения не попадают в Info.plist, и нужен Build Script.

---

## 🧪 Тестирование

1. Пересоберите проект (⌘ + B)
2. Запустите приложение
3. Проверьте логи - должны быть значения из Info.plist
4. Попробуйте создать платеж - должно работать
