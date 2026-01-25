-- Исправление функции join_challenge для работы с оплатой через YooKassa
-- Проблема: функция проверяет баланс и начало челленджа, хотя оплата уже прошла
-- Решение: убираем проверку баланса и разрешаем вступление до начала челленджа
-- Выполните этот SQL в Supabase SQL Editor

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
        INSERT INTO public.user_challenges (user_id, challenge_id, is_active)
        VALUES (p_user_id, p_challenge_id, true)
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
