-- Диагностика проблемы с проваленными челленджами
-- Выполните этот SQL в Supabase SQL Editor для проверки данных

-- 1. Проверяем все проваленные челленджи
SELECT 
    id,
    user_id,
    challenge_id,
    is_active,
    is_completed,
    is_failed,
    failed_at,
    updated_at,
    created_at
FROM public.user_challenges
WHERE is_failed = true
ORDER BY failed_at DESC
LIMIT 10;

-- 2. Проверяем челленджи с противоречивыми статусами
-- (должны быть проваленными, но is_failed = false)
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
ORDER BY updated_at DESC
LIMIT 10;

-- 3. Проверяем конкретный челлендж по challenge_id (замените на нужный ID)
-- SELECT 
--     id,
--     user_id,
--     challenge_id,
--     is_active,
--     is_completed,
--     is_failed,
--     failed_at,
--     updated_at
-- FROM public.user_challenges
-- WHERE challenge_id = 2  -- Замените на нужный challenge_id
-- ORDER BY updated_at DESC;

-- 4. Проверяем, что SQL функция fail_challenge существует и правильная
SELECT 
    p.proname AS function_name,
    pg_get_functiondef(p.oid) AS function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
  AND p.proname = 'fail_challenge';

-- 5. Тестируем функцию fail_challenge вручную (замените на реальные значения)
-- SELECT public.fail_challenge(
--     'USER_ID_HERE'::UUID,  -- Замените на реальный user_id
--     2::BIGINT              -- Замените на реальный challenge_id
-- );

-- 6. Проверяем RLS политики для user_challenges
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
