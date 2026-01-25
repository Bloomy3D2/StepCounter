-- Функция для пополнения баланса пользователя
-- Выполните этот SQL в Supabase SQL Editor

CREATE OR REPLACE FUNCTION update_user_balance(
    p_user_id UUID,
    p_amount DECIMAL(10, 2)
)
RETURNS JSON AS $$
DECLARE
    v_new_balance DECIMAL(10, 2);
BEGIN
    -- Проверяем, что пользователь существует
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = p_user_id) THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Обновляем баланс
    UPDATE public.users
    SET balance = balance + p_amount,
        updated_at = NOW()
    WHERE id = p_user_id
    RETURNING balance INTO v_new_balance;
    
    -- Создаем запись о пополнении
    INSERT INTO public.payments (
        user_id, type, status, amount, description
    ) VALUES (
        p_user_id, 'DEPOSIT', 'COMPLETED', p_amount, 'Пополнение баланса'
    );
    
    -- Возвращаем новый баланс
    RETURN json_build_object(
        'success', true,
        'new_balance', v_new_balance
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Альтернатива: Простое обновление баланса через SQL (для тестирования)
-- UPDATE public.users 
-- SET balance = balance + 100.00 
-- WHERE id = 'YOUR_USER_ID';
