# 🚨 БЫСТРОЕ ИСПРАВЛЕНИЕ: 401 ошибка

## ❌ ПРОБЛЕМА

Edge Function возвращает **401**, поэтому данные не обновляются в БД.

**По логам видно:**
- Edge Function возвращает 401 (Unauthorized)
- Fallback (прямое обновление через Supabase client) также не работает
- После обновления с сервера данные показывают `isActive=true, isFailed=false` (не обновились)

**Причина:** Отсутствуют RLS (Row Level Security) политики для `UPDATE` и `INSERT` на таблице `user_challenges`.

## ✅ РЕШЕНИЕ (2 шага)

### Шаг 1: Создать RLS политики (ОБЯЗАТЕЛЬНО!)

**⚠️ КРИТИЧНО: Без этих политик провал челленджа НЕ БУДЕТ РАБОТАТЬ!**

**Выполните этот SQL в Supabase SQL Editor:**

```sql
-- Удаляем старые политики, если они существуют (для чистоты)
DROP POLICY IF EXISTS "Users can update own challenges" ON public.user_challenges;
DROP POLICY IF EXISTS "Users can insert own challenges" ON public.user_challenges;

-- Создаем политику для INSERT
CREATE POLICY "Users can insert own challenges"
    ON public.user_challenges FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Создаем политику для UPDATE
CREATE POLICY "Users can update own challenges"
    ON public.user_challenges FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
```

**Проверьте, что политики созданы:**
```sql
SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'user_challenges'
ORDER BY cmd;
```

**Должно быть 3 политики:**
- `Users can view own challenges` (SELECT)
- `Users can insert own challenges` (INSERT) ← **НОВАЯ**
- `Users can update own challenges` (UPDATE) ← **НОВАЯ**

**Если политик нет или их меньше 3:**
1. Убедитесь, что RLS включен для таблицы:
   ```sql
   ALTER TABLE public.user_challenges ENABLE ROW LEVEL SECURITY;
   ```
2. Выполните SQL выше еще раз
3. Проверьте, что нет ошибок в SQL Editor

### Шаг 2: Протестировать

1. Провалите челлендж в приложении
2. Проверьте логи приложения:
   - Если видно "Direct update via Supabase client SUCCESS" - значит fallback сработал
   - Если видно "Direct update also FAILED" - значит RLS политики не созданы или не работают

3. Проверьте данные в БД:
   ```sql
   SELECT id, challenge_id, is_active, is_completed, is_failed, failed_at
   FROM public.user_challenges
   WHERE id = 24;  -- Замените на реальный id
   ```

**Должно быть:**
- `is_failed = true`
- `is_active = false`
- `failed_at` не NULL

---

## 🔍 ЕСЛИ НЕ ПОМОГЛО

### Проверьте логи Edge Function в Supabase Dashboard:

1. Зайдите в **Dashboard → Edge Functions → fail-challenge → Logs**
2. Найдите последний вызов
3. Проверьте, что показывает:
   - `📋 Request headers: ...`
   - `🔑 Authorization header: ...`
   - `✅ User authenticated: ...` или `❌ Unauthorized`

### Если Authorization header MISSING:

Проблема в передаче токена из приложения. Проверьте:
- Сессия не истекла (в логах должно быть "Session isExpired: false")
- Пользователь авторизован

### Если Authorization header есть, но все еще 401:

Проблема в RLS политиках или в токене:
1. Убедитесь, что политики созданы (Шаг 1)
2. Проверьте, что токен валидный (в логах должно быть "Session accessToken prefix: eyJ...")

---

**Дата:** 2026-01-23  
**Приоритет:** 🔴 КРИТИЧЕСКИЙ
