-- Обновление цен челленджей
-- Выполните этот SQL в Supabase SQL Editor для обновления существующих челленджей

-- Обновляем цены челленджей
UPDATE public.challenges 
SET entry_fee = 499.0,
    updated_at = NOW()
WHERE title = 'Быстрый старт' AND entry_fee != 499.0;

UPDATE public.challenges 
SET entry_fee = 999.0,
    updated_at = NOW()
WHERE title = 'Подъём до 7:00' AND entry_fee != 999.0;

UPDATE public.challenges 
SET entry_fee = 1499.0,
    updated_at = NOW()
WHERE title = '10,000 шагов' AND entry_fee != 1499.0;

UPDATE public.challenges 
SET entry_fee = 2999.0,
    updated_at = NOW()
WHERE title = 'Без соцсетей' AND entry_fee != 2999.0;

-- Проверка обновленных цен
SELECT title, entry_fee, duration, updated_at 
FROM public.challenges 
WHERE is_active = true
ORDER BY duration;
