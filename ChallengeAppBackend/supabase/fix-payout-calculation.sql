-- Исправление расчета выигрыша
-- Каждый победитель получает 85% от СВОЕГО входа, независимо от количества победителей
-- Выполните этот SQL в Supabase SQL Editor

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
    -- Get user challenge with challenge details (включая entry_fee)
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
