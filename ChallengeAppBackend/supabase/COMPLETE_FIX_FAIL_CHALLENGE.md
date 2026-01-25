# 🔧 ПОЛНОЕ РЕШЕНИЕ: Проваленные челленджи исчезают

## ❌ Проблема

После провала челленджа:
1. ✅ Локально статус обновляется правильно (`isFailed=true, isActive=false`)
2. ✅ В истории отображается правильно
3. ❌ После обновления страницы проваленный челлендж снова показывается как активный
4. ❌ Сервер возвращает `isActive=true, isFailed=false` вместо `isActive=false, isFailed=true`

**Корневая причина:** SQL функция `fail_challenge` может не обновлять данные правильно, или RLS политики блокируют чтение обновленных данных.

## ✅ ПОЛНОЕ РЕШЕНИЕ

### Шаг 1: Проверить текущее состояние данных в БД

Выполните SQL из `DEBUG_FAIL_CHALLENGE.sql` в Supabase SQL Editor:

```sql
-- Проверяем все проваленные челленджи
SELECT 
    id,
    user_id,
    challenge_id,
    is_active,
    is_completed,
    is_failed,
    failed_at,
    updated_at
FROM public.user_challenges
WHERE is_failed = true
ORDER BY failed_at DESC;

-- Проверяем челленджи с противоречивыми статусами
SELECT 
    id,
    user_id,
    challenge_id,
    is_active,
    is_completed,
    is_failed,
    failed_at,
    updated_at
FROM public.user_challenges
WHERE is_active = false 
  AND is_completed = false 
  AND is_failed = false
ORDER BY updated_at DESC;
```

### Шаг 2: Обновить SQL функцию `fail_challenge`

Выполните в Supabase SQL Editor:

```sql
CREATE OR REPLACE FUNCTION fail_challenge(
    p_user_id UUID,
    p_challenge_id BIGINT
)
RETURNS JSON AS $$
DECLARE
    v_user_challenge RECORD;
    v_rows_updated INTEGER;
BEGIN
    -- Get user challenge (не проверяем is_active, чтобы можно было обновить даже если локально уже false)
    -- Но проверяем, что челлендж не завершен и не провален уже
    SELECT * INTO v_user_challenge
    FROM public.user_challenges
    WHERE user_id = p_user_id
    AND challenge_id = p_challenge_id
    AND is_completed = false
    AND is_failed = false;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Challenge not found or already completed/failed';
    END IF;
    
    -- Mark as failed (обновляем только если еще не провален)
    UPDATE public.user_challenges
    SET is_failed = true,
        is_active = false,
        failed_at = COALESCE(failed_at, NOW()),
        updated_at = NOW()
    WHERE id = v_user_challenge.id
    AND is_failed = false;
    
    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
    
    IF v_rows_updated = 0 THEN
        RAISE EXCEPTION 'Failed to update challenge status';
    END IF;
    
    -- Update challenge active participants (только если был активным)
    IF v_user_challenge.is_active = true THEN
        UPDATE public.challenges
        SET active_participants = GREATEST(0, active_participants - 1),
            updated_at = NOW()
        WHERE id = p_challenge_id;
    END IF;
    
    RETURN json_build_object('success', true, 'rows_updated', v_rows_updated);
END;
$$ LANGUAGE plpgsql;
```

### Шаг 3: Исправить существующие записи в БД

Выполните в Supabase SQL Editor:

```sql
-- Исправляем челленджи, которые должны быть проваленными
UPDATE public.user_challenges
SET is_failed = true,
    is_active = false,
    failed_at = COALESCE(failed_at, updated_at, NOW()),
    updated_at = NOW()
WHERE is_active = false 
  AND is_completed = false 
  AND is_failed = false;
```

### Шаг 4: Проверить RLS политики

Выполните в Supabase SQL Editor:

```sql
-- Проверяем RLS политики для user_challenges
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'user_challenges';
```

**Убедитесь, что есть политика для UPDATE:**
```sql
-- Если нет политики для UPDATE, создайте её:
CREATE POLICY "Users can update own challenges"
    ON public.user_challenges FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
```

### Шаг 5: Передеплоить Edge Function

Edge Function уже обновлена с fallback логикой. Передеплойте:

```bash
cd ChallengeAppBackend/supabase
supabase functions deploy fail-challenge
```

### Шаг 6: Проверить логи Edge Function

После провала челленджа в логах Edge Function должно быть:

**Успешный случай:**
```
📥 Fail challenge request: userId=..., challengeId=...
📋 User challenge BEFORE fail: { is_active: true, is_failed: false }
✅ fail_challenge RPC success: { success: true, rows_updated: 1 }
📋 User challenge AFTER fail: { is_active: false, is_failed: true }
✅ Verified: Challenge correctly marked as failed
```

**Если SQL функция не работает (fallback):**
```
❌ CRITICAL: fail_challenge RPC did not update correctly!
🔄 Attempting direct update via Supabase client as fallback...
✅ Direct update succeeded: [...]
✅ Verified: Direct update worked correctly
```

### Шаг 7: Проверить логи в приложении

После провала челленджа в логах приложения должно быть:

**Если данные с сервера правильные:**
```
🔍 SupabaseManager.getUserChallenges: Raw response - ... isFailed=true
🔍 SupabaseManager.getUserChallenges: Found FAILED challenge - ...
```

**Если данные с сервера неправильные:**
```
❌ CRITICAL: Server returned invalid state - ... isFailed=false
   This challenge should be marked as FAILED but server returned isFailed=false!
```

---

## 🔍 Диагностика

### Если проблема все еще есть:

1. **Проверьте логи Edge Function** в Supabase Dashboard:
   - Зайдите в Dashboard → Edge Functions → fail-challenge → Logs
   - Найдите последний вызов функции
   - Проверьте, что показывает "AFTER fail"

2. **Проверьте данные в БД напрямую:**
   - Выполните SQL из `DEBUG_FAIL_CHALLENGE.sql`
   - Убедитесь, что `is_failed = true` и `is_active = false` для проваленных челленджей

3. **Проверьте RLS политики:**
   - Убедитесь, что есть политика для UPDATE
   - Убедитесь, что политика позволяет обновлять `is_failed` и `is_active`

4. **Проверьте логи приложения:**
   - Найдите строки с "CRITICAL: Server returned invalid state"
   - Это покажет, что именно приходит с сервера

---

## 📝 Что изменилось

### В SQL функции:
- ✅ Убрано условие `is_active = true` из SELECT
- ✅ Добавлена проверка `GET DIAGNOSTICS` для подтверждения обновления
- ✅ Добавлена ошибка, если UPDATE не обновил строку

### В Edge Function:
- ✅ Добавлено логирование до и после вызова SQL функции
- ✅ Добавлена проверка, что данные действительно обновились
- ✅ **Добавлен FALLBACK: прямое обновление через Supabase client, если SQL функция не работает**

### В Swift коде:
- ✅ Добавлено логирование сырого JSON ответа от Supabase
- ✅ Добавлена критическая проверка неправильных данных с сервера
- ✅ Принудительное обновление данных с сервера после провала

---

## 🧪 Проверка

После применения всех исправлений:

1. **Провалите челлендж** - должно работать
2. **Проверьте логи Edge Function** - должно быть "✅ Verified: Challenge correctly marked as failed"
3. **Проверьте историю** - должен отображаться проваленный челлендж
4. **Обновите страницу** - проваленный челлендж должен остаться в истории
5. **Проверьте логи приложения** - не должно быть "CRITICAL: Server returned invalid state"

---

**Дата создания:** 2026-01-23  
**Статус:** ✅ Готово к применению  
**Приоритет:** 🔴 КРИТИЧЕСКИЙ
