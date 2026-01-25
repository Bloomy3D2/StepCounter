-- Добавить 3 однодневных челленджа: старт вчера/сегодня/завтра
-- Выполните в Supabase SQL Editor.
--
-- Заметка:
-- - start_date/end_date создаём в 00:00 UTC (как в test-data.sql), чтобы даты были стабильными.
-- - "Вчерашний" челлендж может уже быть завершён по времени — он нужен для демонстрации.

DO $$
DECLARE
  cid_yesterday BIGINT;
  cid_today BIGINT;
  cid_tomorrow BIGINT;
BEGIN
  -- Вчерашний
  IF NOT EXISTS (SELECT 1 FROM public.challenges WHERE title = 'Вчерашний вызов') THEN
    INSERT INTO public.challenges (
      title, subtitle, icon, duration, entry_fee,
      start_date, end_date, description, is_active
    ) VALUES (
      'Вчерашний вызов',
      '1 день (начался вчера)',
      'clock.fill',
      1,
      299.0,
      (DATE_TRUNC('day', NOW() - INTERVAL '1 day') AT TIME ZONE 'UTC')::timestamptz,
      (DATE_TRUNC('day', NOW()) AT TIME ZONE 'UTC')::timestamptz,
      'Однодневный челлендж, который начался вчера',
      true
    )
    RETURNING id INTO cid_yesterday;

    INSERT INTO public.challenge_rules (challenge_id, rule, order_index)
    VALUES
      (cid_yesterday, 'Отметь выполнение сегодня', 1),
      (cid_yesterday, 'Нет отметки = вылет', 2),
      (cid_yesterday, 'Деньги не возвращаются', 3);
  END IF;

  -- Сегодняшний
  IF NOT EXISTS (SELECT 1 FROM public.challenges WHERE title = 'Сегодняшний вызов') THEN
    INSERT INTO public.challenges (
      title, subtitle, icon, duration, entry_fee,
      start_date, end_date, description, is_active
    ) VALUES (
      'Сегодняшний вызов',
      '1 день (начался сегодня)',
      'sun.max.fill',
      1,
      399.0,
      (DATE_TRUNC('day', NOW()) AT TIME ZONE 'UTC')::timestamptz,
      (DATE_TRUNC('day', NOW() + INTERVAL '1 day') AT TIME ZONE 'UTC')::timestamptz,
      'Однодневный челлендж, который начался сегодня',
      true
    )
    RETURNING id INTO cid_today;

    INSERT INTO public.challenge_rules (challenge_id, rule, order_index)
    VALUES
      (cid_today, 'Отметь выполнение сегодня', 1),
      (cid_today, 'Нет отметки = вылет', 2),
      (cid_today, 'Деньги не возвращаются', 3);
  END IF;

  -- Завтрашний
  IF NOT EXISTS (SELECT 1 FROM public.challenges WHERE title = 'Завтрашний вызов') THEN
    INSERT INTO public.challenges (
      title, subtitle, icon, duration, entry_fee,
      start_date, end_date, description, is_active
    ) VALUES (
      'Завтрашний вызов',
      '1 день (начнется завтра)',
      'calendar.badge.clock',
      1,
      499.0,
      (DATE_TRUNC('day', NOW() + INTERVAL '1 day') AT TIME ZONE 'UTC')::timestamptz,
      (DATE_TRUNC('day', NOW() + INTERVAL '2 days') AT TIME ZONE 'UTC')::timestamptz,
      'Однодневный челлендж, который начнется завтра',
      true
    )
    RETURNING id INTO cid_tomorrow;

    INSERT INTO public.challenge_rules (challenge_id, rule, order_index)
    VALUES
      (cid_tomorrow, 'Отметь выполнение в день старта', 1),
      (cid_tomorrow, 'Нет отметки = вылет', 2),
      (cid_tomorrow, 'Деньги не возвращаются', 3);
  END IF;
END $$;

-- Проверка
SELECT id, title, start_date, end_date, is_active
FROM public.challenges
WHERE title IN ('Вчерашний вызов', 'Сегодняшний вызов', 'Завтрашний вызов')
ORDER BY start_date;

