-- Исправление RLS политик для таблицы users
-- Выполните этот SQL в Supabase SQL Editor

-- Добавляем политику для создания профиля пользователя
CREATE POLICY "Users can insert own profile"
    ON public.users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Если политика уже существует, используйте вместо этого:
-- DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
-- CREATE POLICY "Users can insert own profile"
--     ON public.users FOR INSERT
--     WITH CHECK (auth.uid() = id);
