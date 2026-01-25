# Настройка Supabase для Challenge App

## Шаг 1: Создание проекта Supabase

1. Перейдите на [supabase.com](https://supabase.com)
2. Нажмите "Start your project"
3. Войдите через GitHub (или создайте аккаунт)
4. Нажмите "New Project"
5. Заполните:
   - **Name**: `challenge-app`
   - **Database Password**: (сохраните пароль!)
   - **Region**: выберите ближайший
6. Нажмите "Create new project"
7. Подождите 2-3 минуты пока проект создается

---

## Шаг 2: Настройка базы данных

1. В левом меню выберите **SQL Editor**
2. Откройте файл `supabase/schema.sql`
3. Скопируйте весь SQL код
4. Вставьте в SQL Editor
5. Нажмите **Run** (или Cmd+Enter)
6. Должно появиться сообщение "Success. No rows returned"

---

## Шаг 3: Получение API ключей

1. В левом меню выберите **Settings** → **API**
2. Скопируйте:
   - **Project URL** (например: `https://xxxxx.supabase.co`)
   - **anon public** key (длинная строка)
3. Сохраните эти значения - они понадобятся для iOS приложения

---

## Шаг 4: Настройка аутентификации

1. В левом меню выберите **Authentication** → **Providers**
2. Включите нужные провайдеры:
   - ✅ **Email** (уже включен)
   - ✅ **Apple** (если нужен Sign in with Apple)
   - ✅ **Google** (если нужен Google Sign-In)

### Для Apple Sign-In:
1. Перейдите в [Apple Developer](https://developer.apple.com)
2. Создайте Service ID
3. Настройте callback URL: `https://YOUR_PROJECT.supabase.co/auth/v1/callback`
4. Скопируйте Client ID и Secret в Supabase

---

## Шаг 5: Установка Supabase CLI (для Edge Functions)

```bash
# macOS
brew install supabase/tap/supabase

# Или через npm
npm install -g supabase
```

---

## Шаг 6: Деплой Edge Functions

```bash
# Войдите в Supabase
supabase login

# Свяжите проект
supabase link --project-ref YOUR_PROJECT_REF

# Деплой функций
cd supabase/edge-functions

supabase functions deploy join-challenge
supabase functions deploy complete-day
supabase functions deploy fail-challenge
```

**Или через Dashboard:**
1. В левом меню выберите **Edge Functions**
2. Нажмите **Create a new function**
3. Скопируйте код из `edge-functions/join-challenge/index.ts`
4. Повторите для остальных функций

---

## Шаг 7: Настройка iOS приложения

1. Откройте `ChallengeApp/Managers/SupabaseManager.swift`
2. Замените:
   ```swift
   guard let url = URL(string: "YOUR_SUPABASE_URL"),
         let key = "YOUR_SUPABASE_ANON_KEY" as String? else {
   ```
   На ваши реальные значения:
   ```swift
   guard let url = URL(string: "https://xxxxx.supabase.co"),
         let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." as String? else {
   ```

---

## Шаг 8: Установка Supabase Swift SDK

### Через Swift Package Manager:

1. В Xcode: **File** → **Add Packages...**
2. Вставьте URL: `https://github.com/supabase/supabase-swift`
3. Выберите версию: `2.0.0` или последнюю
4. Добавьте в target: **ChallengeApp**

### Или через Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
]
```

---

## Шаг 9: Обновление менеджеров

Замените локальные менеджеры на Supabase версии:

### AuthManager:
```swift
// Вместо симуляции используйте:
let user = try await SupabaseManager.shared.signIn(email: email, password: password)
```

### ChallengeManager:
```swift
// Вместо UserDefaults используйте:
let challenges = try await SupabaseManager.shared.getChallenges()
```

---

## Шаг 10: Тестирование

1. Запустите приложение
2. Попробуйте зарегистрироваться
3. Проверьте, что пользователь создался в Supabase:
   - **Authentication** → **Users**
4. Попробуйте получить челленджи
5. Проверьте в **Table Editor** → **challenges**

---

## Шаг 11: Добавление тестовых данных

В SQL Editor выполните:

```sql
-- Добавьте тестовые челленджи
INSERT INTO public.challenges (
    title, subtitle, icon, duration, entry_fee,
    start_date, end_date, description, is_active
) VALUES 
(
    'Подъём до 7:00',
    '7 дней подряд',
    'sunrise.fill',
    7,
    10.0,
    NOW() + INTERVAL '1 day',
    NOW() + INTERVAL '8 days',
    'Просыпайся до 7:00 каждый день в течение недели',
    true
),
(
    '10,000 шагов',
    '14 дней подряд',
    'figure.walk',
    14,
    20.0,
    NOW() + INTERVAL '1 day',
    NOW() + INTERVAL '15 days',
    'Проходи минимум 10,000 шагов каждый день',
    true
),
(
    'Без соцсетей',
    '30 дней',
    'hand.raised.fill',
    30,
    50.0,
    NOW() + INTERVAL '1 day',
    NOW() + INTERVAL '31 days',
    'Полный отказ от социальных сетей на месяц',
    true
);

-- Добавьте правила для первого челленджа
INSERT INTO public.challenge_rules (challenge_id, rule, order_index)
SELECT id, 'Каждый день отмечай выполнение', 1 FROM public.challenges WHERE title = 'Подъём до 7:00'
UNION ALL
SELECT id, 'Нет отметки = вылет', 2 FROM public.challenges WHERE title = 'Подъём до 7:00'
UNION ALL
SELECT id, 'Деньги не возвращаются', 3 FROM public.challenges WHERE title = 'Подъём до 7:00';
```

---

## Шаг 12: Настройка автоматических задач

Для проверки провалов каждый день:

1. В SQL Editor создайте функцию:
```sql
-- Функция уже есть в schema.sql
-- Нужно только настроить cron

-- Установите pg_cron extension (если еще не установлен)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Настройте задачу (выполняется каждый день в полночь UTC)
SELECT cron.schedule(
    'check-failed-challenges',
    '0 0 * * *', -- каждый день в 00:00
    $$SELECT check_failed_challenges()$$
);
```

---

## Проверка работы

### В Supabase Dashboard:

1. **Table Editor** → проверьте таблицы:
   - `users` - должны быть пользователи
   - `challenges` - должны быть челленджи
   - `user_challenges` - при присоединении

2. **Authentication** → **Users** - проверьте зарегистрированных пользователей

3. **Edge Functions** → проверьте логи функций

4. **Database** → **Functions** - проверьте созданные функции

---

## Troubleshooting

### Ошибка: "relation does not exist"
- Убедитесь, что выполнили `schema.sql`
- Проверьте, что таблицы созданы в **Table Editor**

### Ошибка: "permission denied"
- Проверьте RLS policies
- Убедитесь, что пользователь авторизован

### Ошибка: "function does not exist"
- Проверьте, что функции созданы в **Database** → **Functions**

### Edge Functions не работают
- Проверьте логи в **Edge Functions** → выберите функцию → **Logs**
- Убедитесь, что функция задеплоена

---

## Следующие шаги

1. ✅ Настроить push-уведомления (через Supabase или FCM)
2. ✅ Интегрировать реальные платежи (Stripe)
3. ✅ Настроить мониторинг и аналитику
4. ✅ Добавить бэкапы (автоматически в Pro плане)

---

## Полезные ссылки

- [Supabase Docs](https://supabase.com/docs)
- [Supabase Swift SDK](https://github.com/supabase/supabase-swift)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Edge Functions Docs](https://supabase.com/docs/guides/functions)

---

## Готово! 🎉

Теперь ваше приложение использует Supabase вместо локального хранения!
