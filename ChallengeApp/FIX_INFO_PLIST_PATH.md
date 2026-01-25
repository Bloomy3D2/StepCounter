# ✅ Исправлен путь к Info.plist

## ❌ Проблема

Ключи не читались из Info.plist, потому что Build Script использовал неправильный путь.

**Ошибка в логах:**
```
⚠️ AppConfig: YooKassa Shop ID not found, using default
⚠️ AppConfig: YooKassa Secret Key not found, using default
```

**Причина:** При `GENERATE_INFOPLIST_FILE = YES` нужно использовать `PROCESSED_INFOPLIST_PATH`, а не `${TARGET_BUILD_DIR}/${INFOPLIST_PATH}`.

---

## ✅ Исправление

Обновлен Build Script для использования правильного пути:

**Было:**
```bash
PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
```

**Стало:**
```bash
# Используем PROCESSED_INFOPLIST_PATH для GENERATE_INFOPLIST_FILE = YES
if [ -n "${PROCESSED_INFOPLIST_PATH}" ] && [ -f "${PROCESSED_INFOPLIST_PATH}" ]; then
    PLIST="${PROCESSED_INFOPLIST_PATH}"
else
    # Fallback на обычный путь
    PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
fi
```

---

## 🧪 Проверка

1. **Пересоберите проект:**
   ```bash
   ⌘ + B
   ```

2. **Проверьте логи сборки:**
   Должно быть:
   ```
   🔧 Configuration: Debug
   🔑 Copying YooKassa keys to Info.plist...
   Shop ID: 1256365
   ✅ YooKassa keys copied successfully to Info.plist
   ```

3. **Запустите приложение:**
   ```bash
   ⌘ + R
   ```

4. **Проверьте логи приложения:**
   Должно быть:
   ```
   🔑 AppConfig: YooKassa Shop ID from Info.plist: 1256365
   🔑 AppConfig: YooKassa Secret Key from Info.plist: test_3NzNw2knb5rTf-b...
   ```

---

## ✅ Итог

**Проблема решена:** Build Script теперь использует правильный путь к Info.plist.

**Пересоберите проект и проверьте логи!**
