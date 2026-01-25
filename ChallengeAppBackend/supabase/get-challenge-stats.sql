-- Функции для получения статистики челленджа (выполнило сегодня, выбыло сегодня)
-- Используется в запросах для получения челленджей

-- Функция для получения количества участников, выполнивших день сегодня
CREATE OR REPLACE FUNCTION get_completed_today_count(p_challenge_id BIGINT)
RETURNS BIGINT AS $$
DECLARE
    v_count BIGINT;
BEGIN
    -- Количество уникальных участников, которые выполнили день СЕГОДНЯ
    SELECT COUNT(DISTINCT cd.user_challenge_id) INTO v_count
    FROM public.completed_days cd
    JOIN public.user_challenges uc ON uc.id = cd.user_challenge_id
    WHERE uc.challenge_id = p_challenge_id
    AND cd.completed_date = CURRENT_DATE;
    
    RETURN COALESCE(v_count, 0);
END;
$$ LANGUAGE plpgsql;

-- Функция для получения количества участников, выбывших сегодня
CREATE OR REPLACE FUNCTION get_failed_today_count(p_challenge_id BIGINT)
RETURNS BIGINT AS $$
DECLARE
    v_count BIGINT;
BEGIN
    -- Количество участников, которые провалились СЕГОДНЯ
    SELECT COUNT(*) INTO v_count
    FROM public.user_challenges
    WHERE challenge_id = p_challenge_id
    AND is_failed = true
    AND DATE(failed_at) = CURRENT_DATE;
    
    RETURN COALESCE(v_count, 0);
END;
$$ LANGUAGE plpgsql;
