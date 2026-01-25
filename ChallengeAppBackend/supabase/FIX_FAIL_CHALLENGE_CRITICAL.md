# 🔧 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Проваленные челленджи исчезают

## ❌ Проблема

После провала челленджа:
1. ✅ Локально статус обновляется правильно (`isFailed=true, isActive=false`)
2. ✅ В истории отображается правильно
3. ❌ После обновления страницы проваленный челлендж снова показывается как активный
4. ❌ Сервер возвращает `isActive=true, isFailed=false` вместо `isActive=false, isFailed=true`

**Причина:** SQL функция `fail_challenge` искала запись с `is_active = true`, что могло вызывать проблемы при обновлении. Также функция не проверяла, что UPDATE действительно обновил строку.

## ✅ Решение

### Шаг 1: Обновить SQL функцию `fail_challenge`

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

### Шаг 2: Исправить существующие записи в БД

Выполните в Supabase SQL Editor:

```sql
-- Исправляем челленджи, которые должны быть проваленными
-- (если is_active=false и is_completed=false, но is_failed=false - это ошибка)
UPDATE public.user_challenges
SET is_failed = true,
    is_active = false,
    failed_at = COALESCE(failed_at, updated_at, NOW()),
    updated_at = NOW()
WHERE is_active = false 
  AND is_completed = false 
  AND is_failed = false;
```

### Шаг 3: Передеплоить Edge Function

```bash
cd ChallengeAppBackend/supabase
supabase functions deploy fail-challenge
```

### Шаг 4: Проверить логи Edge Function

После провала челленджа в логах Edge Function должно быть:
```
📥 Fail challenge request: userId=..., challengeId=...
📋 User challenge BEFORE fail: { is_active: true, is_failed: false }
✅ fail_challenge RPC success: { success: true, rows_updated: 1 }
📋 User challenge AFTER fail: { is_active: false, is_failed: true }
✅ Verified: Challenge correctly marked as failed
```

Если `AFTER fail` показывает неправильные значения или есть ошибка "CRITICAL: fail_challenge did not update correctly!", значит проблема в SQL функции или RLS политиках.

---

## 🔍 Что изменилось

### В SQL функции:
- ✅ Убрано условие `is_active = true` из SELECT (теперь ищем по `is_completed = false AND is_failed = false`)
- ✅ Добавлена проверка `GET DIAGNOSTICS v_rows_updated = ROW_COUNT` для подтверждения обновления
- ✅ Добавлена проверка `IF v_rows_updated = 0 THEN RAISE EXCEPTION` для ошибки, если UPDATE не обновил строку
- ✅ Обновление `active_participants` только если челлендж был активным

### В Edge Function:
- ✅ Добавлено логирование `failed_at` и `updated_at` после обновления
- ✅ Добавлена проверка, что данные действительно обновились (`is_failed === true && is_active === false`)
- ✅ Добавлено критическое логирование ошибки, если обновление не сработало

---

## 🧪 Проверка

После исправления:

1. **Провалите челлендж** - должно работать
2. **Проверьте историю** - должен отображаться проваленный челлендж
3. **Обновите страницу** - проваленный челлендж должен остаться в истории
4. **Перейдите на другую вкладку и обратно** - история должна сохраниться

В логах должно быть:
- `📋 User challenge AFTER fail: { is_active: false, is_failed: true }` - правильный статус
- `✅ Verified: Challenge correctly marked as failed` - подтверждение
- `🔍 SupabaseManager.getUserChallenges: Raw response - ... isFailed=true` - правильные данные с сервера

Если проблема повторится, в логах будет видно:
- Точные значения `isActive`, `isFailed` до и после вызова SQL функции
- Что именно приходит с сервера при загрузке данных
- Критическая ошибка, если SQL функция не обновила данные

---

## 📝 Примечания

1. **RLS политики:** Убедитесь, что RLS политики позволяют обновлять `user_challenges` для текущего пользователя
2. **Транзакции:** SQL функция выполняется в транзакции, поэтому все обновления атомарны
3. **Кэш:** После провала кэш очищается и данные загружаются заново с сервера
4. **Логирование:** Все операции логируются для диагностики

---

**Дата создания:** 2026-01-23  
**Статус:** ✅ Готово к применению  
**Приоритет:** 🔴 КРИТИЧЕСКИЙ
