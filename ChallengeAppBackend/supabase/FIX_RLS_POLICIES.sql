-- ============================================
-- КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: RLS политики для user_challenges
-- ============================================
-- Проблема: Нет политики для UPDATE, поэтому Edge Function не может обновлять данные
-- Решение: Создаем политики для UPDATE и INSERT

-- 1. Проверяем текущие политики (ДО исправления)
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
WHERE tablename = 'user_challenges'
ORDER BY cmd, policyname;

-- 2. Удаляем старые политики, если они существуют (для чистоты)
DROP POLICY IF EXISTS "Users can update own challenges" ON public.user_challenges;
DROP POLICY IF EXISTS "Users can insert own challenges" ON public.user_challenges;

-- 3. Создаем политику для INSERT
-- Пользователи могут создавать только свои челленджи
CREATE POLICY "Users can insert own challenges"
    ON public.user_challenges FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- 4. Создаем политику для UPDATE
-- Пользователи могут обновлять только свои челленджи
-- ВАЖНО: WITH CHECK позволяет обновлять поля, включая is_failed и is_active
CREATE POLICY "Users can update own challenges"
    ON public.user_challenges FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 5. Проверяем, что политики созданы (ПОСЛЕ исправления)
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
WHERE tablename = 'user_challenges'
ORDER BY cmd, policyname;

-- Ожидаемый результат: должно быть 3 политики:
-- 1. "Users can view own challenges" (SELECT)
-- 2. "Users can insert own challenges" (INSERT)
-- 3. "Users can update own challenges" (UPDATE)
