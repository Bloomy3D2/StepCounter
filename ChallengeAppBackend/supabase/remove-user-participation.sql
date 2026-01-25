-- SQL скрипт для удаления участия пользователя в челленджах
-- Используйте этот скрипт в Supabase SQL Editor

-- ============================================
-- ВАРИАНТ 1: Удалить участие во ВСЕХ челленджах для конкретного пользователя
-- ============================================
-- Замените 'USER_ID_HERE' на UUID вашего пользователя
-- UUID можно найти в таблице auth.users или public.users

-- Удаляем связанные записи о выполненных днях (CASCADE удалит их автоматически, но лучше явно)
DELETE FROM public.completed_days
WHERE user_challenge_id IN (
    SELECT id FROM public.user_challenges
    WHERE user_id = 'USER_ID_HERE'::uuid
);

-- Удаляем записи об участии в челленджах
DELETE FROM public.user_challenges
WHERE user_id = 'USER_ID_HERE'::uuid;

-- ============================================
-- ВАРИАНТ 2: Удалить участие в КОНКРЕТНОМ челлендже
-- ============================================
-- Замените 'USER_ID_HERE' на UUID пользователя
-- Замените CHALLENGE_ID на ID челленджа (например, 1, 2, 3...)

-- Удаляем связанные записи о выполненных днях
DELETE FROM public.completed_days
WHERE user_challenge_id IN (
    SELECT id FROM public.user_challenges
    WHERE user_id = 'USER_ID_HERE'::uuid
    AND challenge_id = CHALLENGE_ID
);

-- Удаляем запись об участии
DELETE FROM public.user_challenges
WHERE user_id = 'USER_ID_HERE'::uuid
AND challenge_id = CHALLENGE_ID;

-- ============================================
-- ВАРИАНТ 3: Найти UUID пользователя по email
-- ============================================
-- Если вы не знаете UUID, используйте этот запрос для поиска:

SELECT 
    u.id as user_id,
    u.email,
    COUNT(uc.id) as active_challenges_count
FROM public.users u
LEFT JOIN public.user_challenges uc ON uc.user_id = u.id AND uc.is_active = true
WHERE u.email = 'your-email@example.com'  -- Замените на ваш email
GROUP BY u.id, u.email;

-- После того как найдете user_id, используйте его в ВАРИАНТЕ 1 или 2

-- ============================================
-- ВАРИАНТ 4: Просмотреть все активные участия пользователя
-- ============================================
-- Полезно для проверки перед удалением:

SELECT 
    uc.id,
    uc.user_id,
    uc.challenge_id,
    c.title as challenge_title,
    uc.is_active,
    uc.is_completed,
    uc.is_failed,
    uc.entry_date,
    uc.payout
FROM public.user_challenges uc
JOIN public.challenges c ON c.id = uc.challenge_id
WHERE uc.user_id = 'USER_ID_HERE'::uuid
ORDER BY uc.entry_date DESC;

-- ============================================
-- ВАРИАНТ 5: Удалить участие для текущего авторизованного пользователя (через Edge Function)
-- ============================================
-- Этот вариант можно использовать, если вы авторизованы в Supabase Dashboard
-- Но проще использовать ВАРИАНТ 1 или 2

-- ============================================
-- ВАЖНО: После выполнения SQL скрипта
-- ============================================
-- 1. Данные в БД будут удалены
-- 2. НО в приложении останутся кэшированные данные
-- 3. Нужно обновить данные в приложении (см. инструкцию ниже)
