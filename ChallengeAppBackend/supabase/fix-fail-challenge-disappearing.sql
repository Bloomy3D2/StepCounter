-- Исправление проблемы с исчезающими проваленными челленджами
-- Проблема: После обновления страницы проваленные челленджи показываются как активные

-- 1. Проверяем текущее состояние проваленных челленджей
SELECT id, user_id, challenge_id, is_active, is_completed, is_failed, failed_at, updated_at
FROM public.user_challenges
WHERE is_failed = true OR (is_active = false AND is_completed = false)
ORDER BY updated_at DESC;

-- 2. Исправляем челленджи, которые должны быть проваленными
-- (если is_active=false и is_completed=false, но is_failed=false - это ошибка)
UPDATE public.user_challenges
SET is_failed = true,
    is_active = false,
    failed_at = COALESCE(failed_at, updated_at, NOW()),
    updated_at = NOW()
WHERE is_active = false 
  AND is_completed = false 
  AND is_failed = false;

-- 3. Улучшаем функцию fail_challenge для более надежной работы
-- Выполните следующую функцию из schema.sql:
-- CREATE OR REPLACE FUNCTION fail_challenge(...) (см. schema.sql)

-- 4. Проверяем, что все проваленные челленджи имеют правильный статус
SELECT id, user_id, challenge_id, is_active, is_completed, is_failed, failed_at
FROM public.user_challenges
WHERE is_failed = true
ORDER BY failed_at DESC;

-- 5. Проверяем, нет ли челленджей с противоречивыми статусами
SELECT id, user_id, challenge_id, is_active, is_completed, is_failed
FROM public.user_challenges
WHERE (is_active = true AND is_failed = true)
   OR (is_active = true AND is_completed = true)
   OR (is_failed = true AND is_completed = true);
