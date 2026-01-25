-- Тестовые данные для Challenge App
-- Выполните этот SQL в Supabase SQL Editor после применения schema.sql

-- Добавить тестовые челленджи
-- Создаём даты в 00:00 UTC для завтрашнего дня
INSERT INTO public.challenges (
    title, subtitle, icon, duration, entry_fee,
    start_date, end_date, description, is_active
) VALUES 
(
    'Быстрый старт',
    '1 день',
    'bolt.fill',
    1,
    499.0,
    (DATE_TRUNC('day', NOW() + INTERVAL '1 day') AT TIME ZONE 'UTC')::timestamptz,
    (DATE_TRUNC('day', NOW() + INTERVAL '2 days') AT TIME ZONE 'UTC')::timestamptz,
    'Попробуй себя в однодневном челлендже',
    true
),
(
    'Подъём до 7:00',
    '7 дней подряд',
    'sunrise.fill',
    7,
    999.0,
    (DATE_TRUNC('day', NOW() + INTERVAL '1 day') AT TIME ZONE 'UTC')::timestamptz,
    (DATE_TRUNC('day', NOW() + INTERVAL '8 days') AT TIME ZONE 'UTC')::timestamptz,
    'Просыпайся до 7:00 каждый день в течение недели',
    true
),
(
    '10,000 шагов',
    '14 дней подряд',
    'figure.walk',
    14,
    1499.0,
    (DATE_TRUNC('day', NOW() + INTERVAL '1 day') AT TIME ZONE 'UTC')::timestamptz,
    (DATE_TRUNC('day', NOW() + INTERVAL '15 days') AT TIME ZONE 'UTC')::timestamptz,
    'Проходи минимум 10,000 шагов каждый день',
    true
),
(
    'Без соцсетей',
    '30 дней',
    'hand.raised.fill',
    30,
    2999.0,
    (DATE_TRUNC('day', NOW() + INTERVAL '1 day') AT TIME ZONE 'UTC')::timestamptz,
    (DATE_TRUNC('day', NOW() + INTERVAL '31 days') AT TIME ZONE 'UTC')::timestamptz,
    'Полный отказ от социальных сетей на месяц',
    true
)
ON CONFLICT DO NOTHING;

-- Добавить правила для челленджей
INSERT INTO public.challenge_rules (challenge_id, rule, order_index)
SELECT id, 'Отметь выполнение сегодня', 1 FROM public.challenges WHERE title = 'Быстрый старт'
UNION ALL
SELECT id, 'Нет отметки = вылет', 2 FROM public.challenges WHERE title = 'Быстрый старт'
UNION ALL
SELECT id, 'Деньги не возвращаются', 3 FROM public.challenges WHERE title = 'Быстрый старт'
UNION ALL
SELECT id, 'Каждый день отмечай выполнение', 1 FROM public.challenges WHERE title = 'Подъём до 7:00'
UNION ALL
SELECT id, 'Нет отметки = вылет', 2 FROM public.challenges WHERE title = 'Подъём до 7:00'
UNION ALL
SELECT id, 'Деньги не возвращаются', 3 FROM public.challenges WHERE title = 'Подъём до 7:00'
UNION ALL
SELECT id, 'Каждый день отмечай выполнение', 1 FROM public.challenges WHERE title = '10,000 шагов'
UNION ALL
SELECT id, 'Нет отметки = вылет', 2 FROM public.challenges WHERE title = '10,000 шагов'
UNION ALL
SELECT id, 'Деньги не возвращаются', 3 FROM public.challenges WHERE title = '10,000 шагов'
UNION ALL
SELECT id, 'Каждый день отмечай выполнение', 1 FROM public.challenges WHERE title = 'Без соцсетей'
UNION ALL
SELECT id, 'Нет отметки = вылет', 2 FROM public.challenges WHERE title = 'Без соцсетей'
UNION ALL
SELECT id, 'Деньги не возвращаются', 3 FROM public.challenges WHERE title = 'Без соцсетей'
ON CONFLICT DO NOTHING;

-- Проверка: должно быть 4 челленджа
SELECT COUNT(*) as challenges_count FROM public.challenges WHERE is_active = true;

-- Проверка: должно быть 12 правил (4 челленджа × 3 правила)
SELECT COUNT(*) as rules_count FROM public.challenge_rules;
