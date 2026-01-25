# Отладка ошибки Edge Function (400)

## Проблема

При попытке вступить в челлендж возникает ошибка:
```
⚠️ Error calling join-challenge Edge Function: httpError(code: 400, data: 41 bytes)
```

## Возможные причины

### 1. Недостаточный баланс
Функция `join_challenge` проверяет, что у пользователя достаточно средств:
```sql
IF v_user.balance < v_challenge.entry_fee THEN
    RAISE EXCEPTION 'Insufficient balance';
END IF;
```

**Решение:** Убедитесь, что у пользователя есть достаточный баланс.

### 2. Пользователь уже участвует
```sql
IF EXISTS (
    SELECT 1 FROM public.user_challenges
    WHERE user_id = p_user_id AND challenge_id = p_challenge_id
) THEN
    RAISE EXCEPTION 'User already joined this challenge';
END IF;
```

**Решение:** Проверьте, не участвует ли пользователь уже в этом челлендже.

### 3. Челендж еще не начался
```sql
IF v_challenge.start_date > NOW() THEN
    RAISE EXCEPTION 'Challenge has not started yet';
END IF;
```

**Решение:** Дождитесь старта челленджа.

## Как проверить

### 1. Проверьте баланс пользователя

В Supabase SQL Editor выполните:
```sql
SELECT id, email, name, balance 
FROM public.users 
WHERE id = 'YOUR_USER_ID';
```

### 2. Проверьте, участвует ли пользователь

```sql
SELECT * 
FROM public.user_challenges 
WHERE user_id = 'YOUR_USER_ID' 
AND challenge_id = YOUR_CHALLENGE_ID;
```

### 3. Проверьте статус челленджа

```sql
SELECT id, title, start_date, end_date, is_active, entry_fee
FROM public.challenges 
WHERE id = YOUR_CHALLENGE_ID;
```

## Временное решение для тестирования

Если нужно протестировать без проверки баланса, можно временно изменить функцию:

```sql
-- Временно отключить проверку баланса (ТОЛЬКО ДЛЯ ТЕСТИРОВАНИЯ!)
CREATE OR REPLACE FUNCTION join_challenge(
    p_user_id UUID,
    p_challenge_id BIGINT
)
RETURNS JSON AS $$
-- ... остальной код ...
    -- Временно закомментировать проверку баланса
    -- IF v_user.balance < v_challenge.entry_fee THEN
    --     RAISE EXCEPTION 'Insufficient balance';
    -- END IF;
-- ... остальной код ...
```

**⚠️ ВНИМАНИЕ:** Не используйте это в продакшене! Это только для тестирования.

## Улучшенная обработка ошибок

Код теперь показывает понятные сообщения об ошибках:
- "Недостаточно средств на балансе" - если баланс недостаточен
- "Вы уже участвуете в этом челлендже" - если уже участвуете
- "Челлендж еще не начался" - если челендж не начался
- "Челлендж не найден или неактивен" - если челендж не найден

## Проверка логов

После улучшения обработки ошибок в логах будет видно:
- Детали ошибки
- Тип ошибки
- Сообщение от Edge Function

Попробуйте снова вступить в челлендж и проверьте логи - там будет точное сообщение об ошибке.
