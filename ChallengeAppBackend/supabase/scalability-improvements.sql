-- ============================================
-- МАСШТАБИРУЕМОСТЬ И ОПТИМИЗАЦИЯ БД
-- ============================================
-- Эти улучшения нужно применять по мере роста приложения

-- ============================================
-- 1. ДОПОЛНИТЕЛЬНЫЕ ИНДЕКСЫ (для больших объемов)
-- ============================================

-- Составные индексы для частых запросов
CREATE INDEX IF NOT EXISTS idx_user_challenges_user_active 
    ON public.user_challenges(user_id, is_active, is_completed) 
    WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_user_challenges_challenge_active 
    ON public.user_challenges(challenge_id, is_active) 
    WHERE is_active = true;

-- Индекс для поиска по датам
CREATE INDEX IF NOT EXISTS idx_user_challenges_entry_date 
    ON public.user_challenges(entry_date DESC);

CREATE INDEX IF NOT EXISTS idx_payments_created_at 
    ON public.payments(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_challenges_start_end_date 
    ON public.challenges(start_date, end_date) 
    WHERE is_active = true;

-- Индекс для статистики
CREATE INDEX IF NOT EXISTS idx_user_challenges_stats 
    ON public.user_challenges(user_id, is_completed, is_failed);

-- ============================================
-- 2. ПАРТИЦИОНИРОВАНИЕ (для очень больших таблиц)
-- ============================================
-- Применять когда таблица > 10 млн записей

-- Партиционирование payments по месяцам
-- CREATE TABLE public.payments_2024_01 PARTITION OF public.payments
--     FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

-- Партиционирование completed_days по годам
-- CREATE TABLE public.completed_days_2024 PARTITION OF public.completed_days
--     FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

-- ============================================
-- 3. МАТЕРИАЛИЗОВАННЫЕ ВИДЫ (для аналитики)
-- ============================================

-- Статистика по челленджам (обновляется раз в час)
CREATE MATERIALIZED VIEW IF NOT EXISTS challenge_stats AS
SELECT 
    c.id,
    c.title,
    c.participants,
    c.active_participants,
    c.prize_pool,
    COUNT(uc.id) FILTER (WHERE uc.is_completed = true) as winners_count,
    COUNT(uc.id) FILTER (WHERE uc.is_failed = true) as failed_count,
    AVG(EXTRACT(EPOCH FROM (uc.completed_at - uc.entry_date))) as avg_completion_time
FROM public.challenges c
LEFT JOIN public.user_challenges uc ON uc.challenge_id = c.id
WHERE c.is_active = true
GROUP BY c.id, c.title, c.participants, c.active_participants, c.prize_pool;

CREATE UNIQUE INDEX ON challenge_stats(id);

-- Статистика пользователей
CREATE MATERIALIZED VIEW IF NOT EXISTS user_stats AS
SELECT 
    u.id,
    u.email,
    u.name,
    COUNT(uc.id) as total_challenges,
    COUNT(uc.id) FILTER (WHERE uc.is_completed = true) as completed_challenges,
    COUNT(uc.id) FILTER (WHERE uc.is_failed = true) as failed_challenges,
    COALESCE(SUM(uc.payout), 0) as total_earned,
    COALESCE(SUM(c.entry_fee) FILTER (WHERE uc.is_failed = true), 0) as total_lost
FROM public.users u
LEFT JOIN public.user_challenges uc ON uc.user_id = u.id
LEFT JOIN public.challenges c ON c.id = uc.challenge_id
GROUP BY u.id, u.email, u.name;

CREATE UNIQUE INDEX ON user_stats(id);

-- Функция для обновления материализованных видов
CREATE OR REPLACE FUNCTION refresh_stats()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY challenge_stats;
    REFRESH MATERIALIZED VIEW CONCURRENTLY user_stats;
END;
$$ LANGUAGE plpgsql;

-- Автоматическое обновление каждый час
-- SELECT cron.schedule('refresh-stats', '0 * * * *', $$SELECT refresh_stats()$$);

-- ============================================
-- 4. ОПТИМИЗАЦИЯ ЗАПРОСОВ (функции с кэшированием)
-- ============================================

-- Оптимизированная функция получения статистики пользователя
CREATE OR REPLACE FUNCTION get_user_stats_optimized(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    v_stats RECORD;
BEGIN
    -- Используем материализованный вид если доступен
    SELECT * INTO v_stats
    FROM user_stats
    WHERE id = p_user_id;
    
    IF FOUND THEN
        RETURN json_build_object(
            'total_challenges', v_stats.total_challenges,
            'completed_challenges', v_stats.completed_challenges,
            'failed_challenges', v_stats.failed_challenges,
            'total_earned', v_stats.total_earned,
            'total_lost', v_stats.total_lost,
            'win_rate', CASE 
                WHEN v_stats.total_challenges > 0 
                THEN (v_stats.completed_challenges::DECIMAL / v_stats.total_challenges * 100)
                ELSE 0 
            END
        );
    ELSE
        -- Fallback на обычный запрос
        RETURN get_user_stats(p_user_id);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5. АРХИВАЦИЯ СТАРЫХ ДАННЫХ
-- ============================================

-- Таблица для архивированных платежей
CREATE TABLE IF NOT EXISTS public.payments_archive (
    LIKE public.payments INCLUDING ALL
);

-- Функция для архивации платежей старше 1 года
CREATE OR REPLACE FUNCTION archive_old_payments()
RETURNS void AS $$
BEGIN
    INSERT INTO public.payments_archive
    SELECT * FROM public.payments
    WHERE created_at < NOW() - INTERVAL '1 year'
    AND status = 'COMPLETED';
    
    DELETE FROM public.payments
    WHERE created_at < NOW() - INTERVAL '1 year'
    AND status = 'COMPLETED';
END;
$$ LANGUAGE plpgsql;

-- Запуск архивации раз в месяц
-- SELECT cron.schedule('archive-payments', '0 0 1 * *', $$SELECT archive_old_payments()$$);

-- ============================================
-- 6. МОНИТОРИНГ ПРОИЗВОДИТЕЛЬНОСТИ
-- ============================================

-- Таблица для логирования медленных запросов
CREATE TABLE IF NOT EXISTS public.slow_queries_log (
    id BIGSERIAL PRIMARY KEY,
    query_text TEXT,
    execution_time_ms INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Функция для логирования медленных операций
CREATE OR REPLACE FUNCTION log_slow_query(p_query_text TEXT, p_execution_time_ms INTEGER)
RETURNS void AS $$
BEGIN
    IF p_execution_time_ms > 1000 THEN -- Логируем запросы > 1 секунды
        INSERT INTO public.slow_queries_log (query_text, execution_time_ms)
        VALUES (p_query_text, p_execution_time_ms);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 7. ОПТИМИЗАЦИЯ ДЛЯ ЧАСТЫХ ЗАПРОСОВ
-- ============================================

-- Кэширование активных челленджей (обновляется каждые 5 минут)
CREATE TABLE IF NOT EXISTS public.challenges_cache (
    id BIGINT PRIMARY KEY,
    data JSONB NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION refresh_challenges_cache()
RETURNS void AS $$
BEGIN
    TRUNCATE public.challenges_cache;
    
    INSERT INTO public.challenges_cache (id, data)
    SELECT 
        c.id,
        jsonb_build_object(
            'id', c.id,
            'title', c.title,
            'subtitle', c.subtitle,
            'icon', c.icon,
            'duration', c.duration,
            'entry_fee', c.entry_fee,
            'participants', c.participants,
            'prize_pool', c.prize_pool,
            'active_participants', c.active_participants,
            'time_until_start', EXTRACT(EPOCH FROM (c.start_date - NOW())) * 1000
        )
    FROM public.challenges c
    WHERE c.is_active = true;
END;
$$ LANGUAGE plpgsql;

-- Автоматическое обновление кэша
-- SELECT cron.schedule('refresh-cache', '*/5 * * * *', $$SELECT refresh_challenges_cache()$$);

-- ============================================
-- 8. ОПТИМИЗАЦИЯ ДЛЯ МАСШТАБИРОВАНИЯ
-- ============================================

-- Connection pooling (настраивается в Supabase Dashboard)
-- Рекомендуется использовать pgBouncer для connection pooling

-- Read replicas (для чтения)
-- В Supabase Pro можно настроить read replicas для распределения нагрузки

-- ============================================
-- 9. ОПТИМИЗАЦИЯ ХРАНЕНИЯ
-- ============================================

-- Сжатие старых данных
-- ALTER TABLE public.completed_days SET (
--     toast_tuple_target = 128
-- );

-- ============================================
-- 10. МЕТРИКИ И АНАЛИТИКА
-- ============================================

-- Таблица для метрик производительности
CREATE TABLE IF NOT EXISTS public.performance_metrics (
    id BIGSERIAL PRIMARY KEY,
    metric_name TEXT NOT NULL,
    metric_value NUMERIC,
    tags JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_performance_metrics_name_date 
    ON public.performance_metrics(metric_name, created_at DESC);

-- Функция для записи метрик
CREATE OR REPLACE FUNCTION record_metric(
    p_metric_name TEXT,
    p_metric_value NUMERIC,
    p_tags JSONB DEFAULT '{}'::JSONB
)
RETURNS void AS $$
BEGIN
    INSERT INTO public.performance_metrics (metric_name, metric_value, tags)
    VALUES (p_metric_name, p_metric_value, p_tags);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 11. ОПТИМИЗАЦИЯ ДЛЯ ВЫСОКИХ НАГРУЗОК
-- ============================================

-- Batch processing для массовых операций
CREATE OR REPLACE FUNCTION batch_update_challenge_stats()
RETURNS void AS $$
DECLARE
    v_challenge RECORD;
BEGIN
    FOR v_challenge IN 
        SELECT id FROM public.challenges WHERE is_active = true
    LOOP
        -- Обновляем статистику для каждого челленджа
        UPDATE public.challenges
        SET active_participants = (
            SELECT COUNT(*) 
            FROM public.user_challenges 
            WHERE challenge_id = v_challenge.id AND is_active = true
        ),
        prize_pool = (
            SELECT COALESCE(SUM(entry_fee * (1 - service_fee_percent / 100.0)), 0)
            FROM public.user_challenges uc
            JOIN public.challenges c ON c.id = uc.challenge_id
            WHERE uc.challenge_id = v_challenge.id
        )
        WHERE id = v_challenge.id;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 12. РЕКОМЕНДАЦИИ ПО ПРИМЕНЕНИЮ
-- ============================================

/*
ПРИМЕНЯЙТЕ ПО ЭТАПАМ:

ЭТАП 1 (0-10K пользователей):
- ✅ Базовые индексы (уже есть в schema.sql)
- ✅ Материализованные виды для статистики

ЭТАП 2 (10K-100K пользователей):
- ✅ Дополнительные индексы (этот файл)
- ✅ Кэширование активных челленджей
- ✅ Мониторинг производительности

ЭТАП 3 (100K+ пользователей):
- ✅ Партиционирование больших таблиц
- ✅ Архивация старых данных
- ✅ Read replicas (Supabase Pro)
- ✅ Connection pooling

ЭТАП 4 (1M+ пользователей):
- ✅ Горизонтальное масштабирование
- ✅ Шардирование данных
- ✅ CDN для статических данных
*/
