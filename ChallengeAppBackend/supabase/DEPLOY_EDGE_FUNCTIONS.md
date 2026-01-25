# Развертывание Edge Functions

## Способ 1: Через Supabase CLI (рекомендуется)

### Шаг 1: Авторизация

Откройте терминал и выполните:

```bash
cd /Users/maratgaliev/Downloads/Project/MyProjectGame/ChallengeAppBackend/supabase
supabase login
```

Это откроет браузер для авторизации. Войдите в свой аккаунт Supabase.

### Шаг 2: Связывание проекта

```bash
supabase link --project-ref qvyxkbeafgarcjjppttd
```

### Шаг 3: Развертывание функций

```bash
cd edge-functions

# Развернуть join-challenge
supabase functions deploy join-challenge --no-verify-jwt

# Развернуть complete-day
supabase functions deploy complete-day --no-verify-jwt

# Развернуть fail-challenge
supabase functions deploy fail-challenge --no-verify-jwt
```

**Или используйте готовый скрипт:**

```bash
cd /Users/maratgaliev/Downloads/Project/MyProjectGame/ChallengeAppBackend/supabase
./deploy-functions.sh
```

---

## Способ 2: Через Supabase Dashboard (если CLI не работает)

### 1. Развертывание join-challenge

1. Откройте **Supabase Dashboard**: https://supabase.com/dashboard/project/qvyxkbeafgarcjjppttd
2. Перейдите в **Edge Functions** (в левом меню)
3. Нажмите **Create a new function**
4. **Function name**: `join-challenge`
5. Скопируйте весь код из файла `edge-functions/join-challenge/index.ts`
6. Вставьте в редактор
7. Нажмите **Deploy**

### 2. Развертывание complete-day

1. Нажмите **Create a new function**
2. **Function name**: `complete-day`
3. Скопируйте код из `edge-functions/complete-day/index.ts`
4. Нажмите **Deploy**

### 3. Развертывание fail-challenge

1. Нажмите **Create a new function**
2. **Function name**: `fail-challenge`
3. Скопируйте код из `edge-functions/fail-challenge/index.ts`
4. Нажмите **Deploy**

---

## Проверка развертывания

После развертывания проверьте:

1. **Edge Functions** → должны быть видны 3 функции:
   - ✅ join-challenge
   - ✅ complete-day
   - ✅ fail-challenge

2. **Edge Functions** → **Logs** → должны быть логи вызовов (после тестирования)

3. В приложении попробуйте вступить в челлендж - должно работать без ошибок

---

## Если возникли проблемы

### Ошибка: "Function not found"
- Убедитесь, что функции развернуты
- Проверьте названия функций (должны быть точно: `join-challenge`, `complete-day`, `fail-challenge`)

### Ошибка: "Unauthorized"
- Проверьте, что пользователь авторизован в приложении
- Проверьте, что RLS политики настроены правильно

### Ошибка: "RPC function not found"
- Убедитесь, что SQL схема применена (`schema.sql`)
- Проверьте, что функции `join_challenge`, `complete_day`, `fail_challenge` существуют в базе

---

## Готово! 🎉

После развертывания все Edge Functions будут работать, и приложение сможет:
- ✅ Вступать в челленджи через Supabase
- ✅ Отмечать выполнение дня
- ✅ Проваливать челленджи
- ✅ Синхронизировать данные между устройствами
