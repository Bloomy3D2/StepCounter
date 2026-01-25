# Настройка Apple Sign In для продакшена

## ✅ Что уже реализовано

1. ✅ Код для Apple Sign In в `AuthManager.swift`
2. ✅ Интеграция с Supabase (`signInWithApple` в `SupabaseManager`)
3. ✅ UI кнопка в `AuthView.swift`

## ⚠️ Что нужно настроить

### 1. Capability в Xcode

1. Откройте проект в Xcode
2. Выберите target **ChallengeApp**
3. Перейдите в **Signing & Capabilities**
4. Нажмите **+ Capability**
5. Добавьте **Sign in with Apple**

**Или через Info.plist:**
- Добавьте в `Info.plist`:
```xml
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
```

### 2. Настройка в Apple Developer Portal

1. Войдите в [Apple Developer Portal](https://developer.apple.com/account)
2. Перейдите в **Certificates, Identifiers & Profiles**
3. Выберите **Identifiers** → ваш App ID
4. Включите **Sign in with Apple**
5. Сохраните изменения

### 3. Настройка в Supabase

1. Откройте Supabase Dashboard: https://supabase.com/dashboard/project/qvyxkbeafgarcjjppttd
2. Перейдите в **Authentication** → **Providers**
3. Найдите **Apple** и включите его
4. Настройте:
   - **Client ID (Service ID)**: создайте Service ID в Apple Developer Portal
   - **Client Secret**: сгенерируйте через Apple Developer Portal
   - **Redirect URL**: `https://qvyxkbeafgarcjjppttd.supabase.co/auth/v1/callback`

### 4. Создание Service ID в Apple Developer Portal

1. **Identifiers** → **+** → **Services IDs**
2. **Description**: ChallengeApp Apple Sign In
3. **Identifier**: `com.yourcompany.challengeapp.applesignin` (уникальный)
4. Включите **Sign in with Apple**
5. Нажмите **Configure**
6. **Primary App ID**: выберите ваш App ID
7. **Website URLs**:
   - **Domains**: `qvyxkbeafgarcjjppttd.supabase.co`
   - **Return URLs**: `https://qvyxkbeafgarcjjppttd.supabase.co/auth/v1/callback`
8. Сохраните

### 5. Создание Key для Client Secret

1. **Keys** → **+**
2. **Key Name**: ChallengeApp Apple Sign In Key
3. Включите **Sign in with Apple**
4. **Continue** → **Register**
5. **Download** ключ (`.p8` файл) - сохраните безопасно!
6. **Key ID** - скопируйте (нужен для Supabase)

### 6. Генерация Client Secret

Используйте онлайн-генератор или скрипт:

**Вариант 1: Онлайн**
- https://appleid.apple.com/signinwithapple/button/helper
- Или используйте Node.js скрипт

**Вариант 2: Node.js скрипт**
```javascript
const jwt = require('jsonwebtoken');
const fs = require('fs');

const teamId = 'YOUR_TEAM_ID'; // Из Apple Developer Portal
const clientId = 'com.yourcompany.challengeapp.applesignin'; // Service ID
const keyId = 'YOUR_KEY_ID'; // Из шага 5
const privateKey = fs.readFileSync('AuthKey_XXXXXXXXXX.p8'); // Скачанный ключ

const token = jwt.sign(
  {
    iss: teamId,
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 86400 * 180, // 6 месяцев
    aud: 'https://appleid.apple.com',
    sub: clientId,
  },
  privateKey,
  {
    algorithm: 'ES256',
    keyid: keyId,
  }
);

console.log(token);
```

### 7. Добавление Client Secret в Supabase

1. Supabase Dashboard → **Authentication** → **Providers** → **Apple**
2. Вставьте:
   - **Client ID (Service ID)**: ваш Service ID
   - **Client Secret**: сгенерированный токен
3. Сохраните

## 🧪 Тестирование

### На реальном устройстве:
1. Запустите приложение на iPhone/iPad
2. Нажмите "Войти через Apple"
3. Авторизуйтесь через Face ID/Touch ID
4. Проверьте, что вход прошел успешно

### На симуляторе:
- Apple Sign In работает только на реальных устройствах
- На симуляторе будет ошибка

## ✅ Чеклист

- [ ] Capability добавлена в Xcode
- [ ] Sign in with Apple включен в App ID
- [ ] Service ID создан
- [ ] Key создан и скачан
- [ ] Client Secret сгенерирован
- [ ] Apple provider настроен в Supabase
- [ ] Протестирован на реальном устройстве

## 🐛 Решение проблем

### Ошибка: "Sign in with Apple недоступен"
- Проверьте, что capability добавлена в Xcode
- Проверьте, что включена в Apple Developer Portal

### Ошибка: "Invalid client"
- Проверьте Service ID в Supabase
- Проверьте, что Service ID правильно настроен

### Ошибка: "Invalid client secret"
- Проверьте, что Client Secret сгенерирован правильно
- Проверьте срок действия (6 месяцев)

## 📚 Дополнительные ресурсы

- [Apple Documentation](https://developer.apple.com/sign-in-with-apple/)
- [Supabase Apple Provider](https://supabase.com/docs/guides/auth/social-login/auth-apple)

---

**Готово!** После выполнения всех шагов Apple Sign In будет работать. 🍎
