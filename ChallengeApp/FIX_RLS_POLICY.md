# Исправление ошибки RLS политики

## Проблема

При регистрации возникает ошибка:
```
new row violates row-level security policy for table users
```

Это происходит потому, что в таблице `users` включен Row Level Security (RLS), но нет политики, которая разрешает пользователям создавать свои профили.

## Решение

### Способ 1: Выполнить SQL скрипт (быстро)

1. Откройте **Supabase Dashboard**: https://supabase.com/dashboard/project/qvyxkbeafgarcjjppttd

2. Перейдите в **SQL Editor** (в левом меню)

3. Скопируйте и выполните следующий SQL:

```sql
-- Добавляем политику для создания профиля пользователя
CREATE POLICY "Users can insert own profile"
    ON public.users FOR INSERT
    WITH CHECK (auth.uid() = id);
```

4. Нажмите **Run** (или Cmd+Enter)

5. Готово! Теперь пользователи смогут создавать свои профили при регистрации.

---

### Способ 2: Через файл (если способ 1 не работает)

1. Откройте файл `ChallengeAppBackend/supabase/fix-rls-policy.sql`

2. Скопируйте содержимое

3. Вставьте в **Supabase SQL Editor**

4. Нажмите **Run**

---

## Что делает эта политика?

Политика `"Users can insert own profile"` разрешает пользователям создавать запись в таблице `users` **только если**:
- `auth.uid()` (ID текущего авторизованного пользователя) **равен** `id` (ID в создаваемой записи)

Это означает, что пользователь может создать только свой собственный профиль, что обеспечивает безопасность.

---

## Проверка

После выполнения SQL:

1. ✅ Политика создана
2. ✅ Пользователи могут регистрироваться
3. ✅ Профили создаются автоматически

Попробуйте зарегистрироваться снова - ошибка должна исчезнуть!

---

## Если ошибка все еще возникает

1. **Проверьте, что политика создана:**
   - Перейдите в **Authentication** → **Policies**
   - Найдите таблицу `users`
   - Убедитесь, что есть политика `"Users can insert own profile"`

2. **Проверьте, что RLS включен:**
   - В SQL Editor выполните:
   ```sql
   SELECT tablename, rowsecurity 
   FROM pg_tables 
   WHERE schemaname = 'public' AND tablename = 'users';
   ```
   - `rowsecurity` должен быть `true`

3. **Если политика уже существует:**
   - Удалите старую и создайте новую:
   ```sql
   DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
   CREATE POLICY "Users can insert own profile"
       ON public.users FOR INSERT
       WITH CHECK (auth.uid() = id);
   ```
