-- Исправление проблемы с complete_day
-- Проблема: entry_date может быть не установлен или NULL
-- Решение: обновляем функцию join_challenge и исправляем существующие записи

-- 1. Обновляем функцию join_challenge (уже сделано в schema.sql)
-- entry_date теперь устанавливается явно: entry_date = NOW()

-- 2. Исправляем существующие записи user_challenges, где entry_date NULL
UPDATE public.user_challenges
SET entry_date = COALESCE(entry_date, created_at, NOW())
WHERE entry_date IS NULL;

-- 3. Проверяем, что все записи имеют entry_date
-- Если есть записи без entry_date, они будут обновлены выше

-- 4. Улучшаем функцию complete_day для лучшей обработки ошибок
-- (уже сделано в schema.sql - entry_date устанавливается явно)
