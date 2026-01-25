-- Supabase Database Schema for Challenge App
-- Запустите этот SQL в Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLES
-- ============================================

-- Users table (расширяет auth.users)
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    balance DECIMAL(10, 2) DEFAULT 0.0 NOT NULL,
    auth_provider TEXT NOT NULL DEFAULT 'EMAIL',
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    last_login_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Challenges table
CREATE TABLE public.challenges (
    id BIGSERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    subtitle TEXT NOT NULL,
    icon TEXT NOT NULL,
    duration INTEGER NOT NULL,
    entry_fee DECIMAL(10, 2) NOT NULL,
    service_fee_percent DECIMAL(5, 2) DEFAULT 15.0 NOT NULL,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    participants INTEGER DEFAULT 0 NOT NULL,
    prize_pool DECIMAL(10, 2) DEFAULT 0.0 NOT NULL,
    active_participants INTEGER DEFAULT 0 NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Challenge rules (many-to-many через JSONB или отдельную таблицу)
CREATE TABLE public.challenge_rules (
    id BIGSERIAL PRIMARY KEY,
    challenge_id BIGINT REFERENCES public.challenges(id) ON DELETE CASCADE NOT NULL,
    rule TEXT NOT NULL,
    order_index INTEGER NOT NULL
);

-- User challenges (participation)
CREATE TABLE public.user_challenges (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    challenge_id BIGINT REFERENCES public.challenges(id) ON DELETE CASCADE NOT NULL,
    entry_date TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    is_completed BOOLEAN DEFAULT false NOT NULL,
    is_failed BOOLEAN DEFAULT false NOT NULL,
    payout DECIMAL(10, 2),
    completed_at TIMESTAMPTZ,
    failed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE(user_id, challenge_id)
);

-- Completed days (many-to-many)
CREATE TABLE public.completed_days (
    id BIGSERIAL PRIMARY KEY,
    user_challenge_id BIGINT REFERENCES public.user_challenges(id) ON DELETE CASCADE NOT NULL,
    completed_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE(user_challenge_id, completed_date)
);

-- Payments table
CREATE TABLE public.payments (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    challenge_id BIGINT REFERENCES public.challenges(id) ON DELETE SET NULL,
    type TEXT NOT NULL, -- ENTRY_FEE, WITHDRAWAL, PAYOUT
    status TEXT NOT NULL DEFAULT 'PENDING', -- PENDING, COMPLETED, FAILED, REFUNDED
    amount DECIMAL(10, 2) NOT NULL,
    transaction_id TEXT UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    processed_at TIMESTAMPTZ
);

-- Analytics events (internal analytics, minimal)
CREATE TABLE public.analytics_events (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    session_id UUID NOT NULL,
    event_name TEXT NOT NULL,
    challenge_id BIGINT REFERENCES public.challenges(id) ON DELETE SET NULL,
    amount DECIMAL(10, 2),
    props JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- ============================================
-- INDEXES (оптимизированы для масштабирования)
-- Все индексы добавлены сразу для лучшей производительности
-- ============================================

-- Users indexes
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_created_at ON public.users(created_at DESC);

-- Challenges indexes
CREATE INDEX idx_challenges_active ON public.challenges(is_active) WHERE is_active = true;
CREATE INDEX idx_challenges_start_end_date ON public.challenges(start_date, end_date) WHERE is_active = true;
CREATE INDEX idx_challenges_created_at ON public.challenges(created_at DESC);

-- User challenges indexes (критично для производительности)
CREATE INDEX idx_user_challenges_user_id ON public.user_challenges(user_id);
CREATE INDEX idx_user_challenges_challenge_id ON public.user_challenges(challenge_id);
CREATE INDEX idx_user_challenges_active ON public.user_challenges(user_id, is_active) WHERE is_active = true;
-- Составной индекс для частого запроса активных челленджей пользователя
CREATE INDEX idx_user_challenges_user_active_completed 
    ON public.user_challenges(user_id, is_active, is_completed) 
    WHERE is_active = true;
-- Индекс для статистики пользователя
CREATE INDEX idx_user_challenges_stats 
    ON public.user_challenges(user_id, is_completed, is_failed);
-- Индекс для поиска активных участников челленджа
CREATE INDEX idx_user_challenges_challenge_active 
    ON public.user_challenges(challenge_id, is_active) 
    WHERE is_active = true;
-- Индекс для сортировки по дате вступления
CREATE INDEX idx_user_challenges_entry_date 
    ON public.user_challenges(entry_date DESC);

-- Completed days indexes
CREATE INDEX idx_completed_days_user_challenge ON public.completed_days(user_challenge_id);
CREATE INDEX idx_completed_days_date ON public.completed_days(completed_date);
-- Составной индекс для проверки выполнения дня (критично для производительности)
CREATE INDEX idx_completed_days_challenge_date 
    ON public.completed_days(user_challenge_id, completed_date);

-- Payments indexes
CREATE INDEX idx_payments_user_id ON public.payments(user_id);
CREATE INDEX idx_payments_status ON public.payments(status);
CREATE INDEX idx_payments_created_at ON public.payments(created_at DESC);
-- Индекс для истории платежей пользователя (часто используется)
CREATE INDEX idx_payments_user_created 
    ON public.payments(user_id, created_at DESC);
-- Индекс для поиска платежей по типу
CREATE INDEX idx_payments_type ON public.payments(type);
-- Индекс для поиска платежей по челленджу
CREATE INDEX idx_payments_challenge_id ON public.payments(challenge_id) WHERE challenge_id IS NOT NULL;

-- Analytics indexes
CREATE INDEX idx_analytics_events_created_at ON public.analytics_events(created_at DESC);
CREATE INDEX idx_analytics_events_user_created_at ON public.analytics_events(user_id, created_at DESC);
CREATE INDEX idx_analytics_events_event_created_at ON public.analytics_events(event_name, created_at DESC);
CREATE INDEX idx_analytics_events_challenge_created_at
    ON public.analytics_events(challenge_id, created_at DESC)
    WHERE challenge_id IS NOT NULL;

-- Challenge rules indexes
CREATE INDEX idx_challenge_rules_challenge_id ON public.challenge_rules(challenge_id);
CREATE INDEX idx_challenge_rules_order ON public.challenge_rules(challenge_id, order_index);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to get current day of challenge
CREATE OR REPLACE FUNCTION get_current_day(p_user_challenge_id BIGINT)
RETURNS INTEGER AS $$
DECLARE
    v_entry_date DATE;
    v_today DATE;
BEGIN
    SELECT entry_date::DATE INTO v_entry_date
    FROM public.user_challenges
    WHERE id = p_user_challenge_id;
    
    v_today := CURRENT_DATE;
    
    RETURN (v_today - v_entry_date) + 1;
END;
$$ LANGUAGE plpgsql;

-- Function to check if day is completed
CREATE OR REPLACE FUNCTION has_completed_today(p_user_challenge_id BIGINT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.completed_days
        WHERE user_challenge_id = p_user_challenge_id
        AND completed_date = CURRENT_DATE
    );
END;
$$ LANGUAGE plpgsql;

-- Function to join challenge (with transaction)
CREATE OR REPLACE FUNCTION join_challenge(
    p_user_id UUID,
    p_challenge_id BIGINT
)
RETURNS JSON AS $$
DECLARE
    v_challenge RECORD;
    v_user RECORD;
    v_user_challenge_id BIGINT;
    v_service_fee DECIMAL(10, 2);
BEGIN
    -- Get challenge
    SELECT * INTO v_challenge
    FROM public.challenges
    WHERE id = p_challenge_id AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Challenge not found or inactive';
    END IF;
    
    -- УБРАЛИ ПРОВЕРКУ НАЧАЛА - разрешаем предварительную регистрацию
    -- Пользователь может оплатить через YooKassa и вступить ДО начала челленджа
    -- IF v_challenge.start_date > NOW() THEN
    --     RAISE EXCEPTION 'Challenge has not started yet';
    -- END IF;
    
    -- Проверяем только, что челлендж не закончился
    IF v_challenge.end_date < NOW() THEN
        RAISE EXCEPTION 'Challenge has already ended';
    END IF;
    
    -- Get user
    SELECT * INTO v_user
    FROM public.users
    WHERE id = p_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if already joined
    IF EXISTS (
        SELECT 1 FROM public.user_challenges
        WHERE user_id = p_user_id AND challenge_id = p_challenge_id
    ) THEN
        RAISE EXCEPTION 'User already joined this challenge';
    END IF;
    
    -- УБРАЛИ ПРОВЕРКУ БАЛАНСА - оплата уже прошла через YooKassa
    -- IF v_user.balance < v_challenge.entry_fee THEN
    --     RAISE EXCEPTION 'Insufficient balance';
    -- END IF;
    
    -- Calculate service fee
    v_service_fee := v_challenge.entry_fee * (v_challenge.service_fee_percent / 100.0);
    
    -- Start transaction
    BEGIN
        -- Create user challenge
        -- entry_date устанавливается автоматически через DEFAULT NOW(), но явно указываем для надежности
        INSERT INTO public.user_challenges (user_id, challenge_id, is_active, entry_date)
        VALUES (p_user_id, p_challenge_id, true, NOW())
        RETURNING id INTO v_user_challenge_id;
        
        -- Update challenge stats
        UPDATE public.challenges
        SET participants = participants + 1,
            prize_pool = prize_pool + (v_challenge.entry_fee - v_service_fee),
            active_participants = active_participants + 1,
            updated_at = NOW()
        WHERE id = p_challenge_id;
        
        -- УБРАЛИ СПИСАНИЕ С БАЛАНСА - оплата уже прошла через YooKassa
        -- Баланс пользователя НЕ должен списываться, так как оплата была через внешний платежный шлюз
        -- UPDATE public.users
        -- SET balance = balance - v_challenge.entry_fee,
        --     updated_at = NOW()
        -- WHERE id = p_user_id;
        
        -- Create payment record (платеж уже обработан через YooKassa, просто записываем факт)
        -- transaction_id будет обновлен webhook'ом с реальным ID платежа от YooKassa
        INSERT INTO public.payments (
            user_id, challenge_id, type, status, amount,
            transaction_id, description
        ) VALUES (
            p_user_id, p_challenge_id, 'ENTRY_FEE', 'COMPLETED',
            v_challenge.entry_fee, gen_random_uuid()::TEXT,
            'Entry fee for challenge: ' || v_challenge.title || ' (paid via YooKassa)'
        );
        
        -- Return result
        RETURN json_build_object(
            'success', true,
            'user_challenge_id', v_user_challenge_id
        );
        
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to join challenge: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Function to complete day
CREATE OR REPLACE FUNCTION complete_day(
    p_user_id UUID,
    p_challenge_id BIGINT
)
RETURNS JSON AS $$
DECLARE
    v_user_challenge RECORD;
    v_challenge RECORD;
    v_completed_count INTEGER;
    v_payout DECIMAL(10, 2);
BEGIN
    -- Get user challenge with challenge details
    SELECT uc.*, c.duration, c.prize_pool, c.entry_fee, c.service_fee_percent
    INTO v_user_challenge
    FROM public.user_challenges uc
    JOIN public.challenges c ON c.id = uc.challenge_id
    WHERE uc.user_id = p_user_id
    AND uc.challenge_id = p_challenge_id
    AND uc.is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active challenge not found';
    END IF;
    
    -- Check if already completed today
    IF has_completed_today(v_user_challenge.id) THEN
        RAISE EXCEPTION 'Day already completed';
    END IF;
    
    -- Add today to completed days
    INSERT INTO public.completed_days (user_challenge_id, completed_date)
    VALUES (v_user_challenge.id, CURRENT_DATE)
    ON CONFLICT (user_challenge_id, completed_date) DO NOTHING;
    
    -- Count completed days
    SELECT COUNT(*) INTO v_completed_count
    FROM public.completed_days
    WHERE user_challenge_id = v_user_challenge.id;
    
    -- Check if challenge is completed
    IF v_completed_count >= v_user_challenge.duration THEN
        -- Mark as completed
        UPDATE public.user_challenges
        SET is_completed = true,
            is_active = false,
            completed_at = NOW(),
            updated_at = NOW()
        WHERE id = v_user_challenge.id;
        
        -- Уменьшаем active_participants, так как пользователь завершил челлендж
        UPDATE public.challenges
        SET active_participants = GREATEST(0, active_participants - 1),
            updated_at = NOW()
        WHERE id = p_challenge_id;
        
        -- Calculate payout: каждый победитель получает 85% от СВОЕГО входа
        -- payout = entry_fee * 0.85 (85% от входной платы)
        -- НЕ зависит от количества победителей - каждый получает свою долю
        v_payout := v_user_challenge.entry_fee * 0.85;
        
        -- Update payout
        UPDATE public.user_challenges
        SET payout = v_payout
        WHERE id = v_user_challenge.id;
        
        -- Add to user balance
        UPDATE public.users
        SET balance = balance + v_payout,
            updated_at = NOW()
        WHERE id = p_user_id;
        
        -- Create payout payment
        INSERT INTO public.payments (
            user_id, challenge_id, type, status, amount,
            transaction_id, description, processed_at
        ) VALUES (
            p_user_id, p_challenge_id, 'PAYOUT', 'COMPLETED',
            v_payout, gen_random_uuid()::TEXT,
            'Payout for completing challenge (85% of entry fee)',
            NOW()
        );
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'completed_days', v_completed_count,
        'is_completed', v_completed_count >= v_user_challenge.duration,
        'payout', v_payout
    );
END;
$$ LANGUAGE plpgsql;

-- Function to fail challenge
CREATE OR REPLACE FUNCTION fail_challenge(
    p_user_id UUID,
    p_challenge_id BIGINT
)
RETURNS JSON AS $$
DECLARE
    v_user_challenge RECORD;
    v_rows_updated INTEGER;
BEGIN
    -- Get user challenge (не проверяем is_active, чтобы можно было обновить даже если локально уже false)
    -- Но проверяем, что челлендж не завершен и не провален уже
    SELECT * INTO v_user_challenge
    FROM public.user_challenges
    WHERE user_id = p_user_id
    AND challenge_id = p_challenge_id
    AND is_completed = false
    AND is_failed = false;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Challenge not found or already completed/failed';
    END IF;
    
    -- Mark as failed (обновляем только если еще не провален)
    UPDATE public.user_challenges
    SET is_failed = true,
        is_active = false,
        failed_at = COALESCE(failed_at, NOW()),
        updated_at = NOW()
    WHERE id = v_user_challenge.id
    AND is_failed = false;
    
    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
    
    IF v_rows_updated = 0 THEN
        RAISE EXCEPTION 'Failed to update challenge status';
    END IF;
    
    -- Update challenge active participants (только если был активным)
    IF v_user_challenge.is_active = true THEN
        UPDATE public.challenges
        SET active_participants = GREATEST(0, active_participants - 1),
            updated_at = NOW()
        WHERE id = p_challenge_id;
    END IF;
    
    RETURN json_build_object('success', true, 'rows_updated', v_rows_updated);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.completed_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;

-- Users: can read own data, can update own data
CREATE POLICY "Users can insert own profile"
    ON public.users FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view own data"
    ON public.users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own data"
    ON public.users FOR UPDATE
    USING (auth.uid() = id);

-- Challenges: everyone can read active challenges
CREATE POLICY "Anyone can view active challenges"
    ON public.challenges FOR SELECT
    USING (is_active = true);

-- User challenges: users can view their own
CREATE POLICY "Users can view own challenges"
    ON public.user_challenges FOR SELECT
    USING (auth.uid() = user_id);

-- User challenges: users can insert their own
CREATE POLICY "Users can insert own challenges"
    ON public.user_challenges FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- User challenges: users can update their own
CREATE POLICY "Users can update own challenges"
    ON public.user_challenges FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Completed days: users can view their own
CREATE POLICY "Users can view own completed days"
    ON public.completed_days FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.user_challenges
            WHERE id = completed_days.user_challenge_id
            AND user_id = auth.uid()
        )
    );

-- Completed days: users can insert their own (required for complete_day RPC via anon key)
CREATE POLICY "Users can insert own completed days"
    ON public.completed_days FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.user_challenges
            WHERE id = completed_days.user_challenge_id
            AND user_id = auth.uid()
        )
    );

-- Payments: users can view their own
CREATE POLICY "Users can view own payments"
    ON public.payments FOR SELECT
    USING (auth.uid() = user_id);

-- Analytics: users can view/insert only their own
CREATE POLICY "Users can view own analytics events"
    ON public.analytics_events FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own analytics events"
    ON public.analytics_events FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_challenges_updated_at
    BEFORE UPDATE ON public.challenges
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_challenges_updated_at
    BEFORE UPDATE ON public.user_challenges
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SAMPLE DATA (для тестирования)
-- ============================================

-- Вставьте тестовые данные после создания пользователя через auth
-- INSERT INTO public.challenges (title, subtitle, icon, duration, entry_fee, start_date, end_date, description, is_active)
-- VALUES 
-- ('Подъём до 7:00', '7 дней подряд', 'sunrise.fill', 7, 10.0, NOW() + INTERVAL '1 day', NOW() + INTERVAL '8 days', 'Просыпайся до 7:00 каждый день', true),
-- ('10,000 шагов', '14 дней подряд', 'figure.walk', 14, 20.0, NOW() + INTERVAL '1 day', NOW() + INTERVAL '15 days', 'Проходи минимум 10,000 шагов каждый день', true);
