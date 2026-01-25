# Как пополнить баланс

## Способ 1: Через приложение (рекомендуется)

1. Откройте приложение
2. Перейдите в **Профиль** (иконка профиля внизу)
3. Нажмите кнопку **"Пополнить баланс"** под балансом
4. Выберите сумму из быстрого выбора или введите свою
5. Нажмите **"Пополнить"**

---

## Способ 2: Через SQL (для тестирования)

### Шаг 1: Найдите ID пользователя

В Supabase SQL Editor выполните:
```sql
SELECT id, email, name, balance 
FROM public.users 
ORDER BY created_at DESC 
LIMIT 10;
```

Скопируйте `id` нужного пользователя (это UUID, например: `123e4567-e89b-12d3-a456-426614174000`)

### Шаг 2: Пополните баланс

```sql
-- Пополнить на 100 €
UPDATE public.users 
SET balance = balance + 100.00,
    updated_at = NOW()
WHERE id = 'ВАШ_USER_ID';

-- Создать запись о пополнении
INSERT INTO public.payments (
    user_id, type, status, amount, description
) VALUES (
    'ВАШ_USER_ID', 'DEPOSIT', 'COMPLETED', 100.00, 'Пополнение баланса (тест)'
);
```

**Замените `ВАШ_USER_ID` на реальный ID пользователя!**

### Шаг 3: Проверьте баланс

```sql
SELECT id, email, name, balance 
FROM public.users 
WHERE id = 'ВАШ_USER_ID';
```

---

## Способ 3: Использовать RPC функцию (после настройки)

### Шаг 1: Создайте функцию

Выполните SQL из файла `ChallengeAppBackend/supabase/deposit-balance-function.sql` в Supabase SQL Editor.

### Шаг 2: Используйте функцию

```sql
SELECT update_user_balance(
    'ВАШ_USER_ID'::UUID,
    100.00
);
```

---

## Быстрое пополнение для тестирования

Если нужно быстро пополнить баланс для тестирования, выполните:

```sql
-- Пополнить баланс всех пользователей на 1000 € (ТОЛЬКО ДЛЯ ТЕСТИРОВАНИЯ!)
UPDATE public.users 
SET balance = balance + 1000.00,
    updated_at = NOW();
```

**⚠️ ВНИМАНИЕ:** Это пополнит баланс ВСЕХ пользователей! Используйте только для тестирования!

---

## Проверка баланса

Чтобы проверить баланс пользователя:

```sql
SELECT 
    id,
    email,
    name,
    balance,
    created_at
FROM public.users
WHERE email = 'test@example.com';  -- или WHERE id = 'USER_ID'
```

---

## История пополнений

Чтобы посмотреть историю пополнений:

```sql
SELECT 
    p.id,
    p.amount,
    p.status,
    p.description,
    p.created_at,
    u.email,
    u.name
FROM public.payments p
JOIN public.users u ON u.id = p.user_id
WHERE p.type = 'DEPOSIT'
ORDER BY p.created_at DESC
LIMIT 20;
```

---

## Важно

1. **Баланс хранится в таблице `users`** в поле `balance`
2. **Все операции записываются** в таблицу `payments`
3. **После пополнения через SQL** перезапустите приложение, чтобы увидеть обновленный баланс
4. **В продакшене** используйте только способ через приложение с реальной оплатой

---

## После пополнения

1. **Перезапустите приложение** (закройте и откройте снова)
2. **Проверьте баланс** в профиле
3. **Попробуйте вступить в челлендж** - ошибка "Insufficient balance" должна исчезнуть
