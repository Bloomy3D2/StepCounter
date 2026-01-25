-- Миграция: Добавление честной серии (honest_streak) в таблицу users
-- Выполнить в Supabase SQL Editor

-- Добавить поле честной серии в users
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS honest_streak INTEGER DEFAULT 0 NOT NULL;

-- Индекс для быстрого поиска по серии (для будущих запросов)
CREATE INDEX IF NOT EXISTS idx_users_honest_streak 
ON public.users(honest_streak DESC);

-- Функция для увеличения честной серии
CREATE OR REPLACE FUNCTION increment_honest_streak(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_new_streak INTEGER;
BEGIN
    UPDATE public.users
    SET honest_streak = honest_streak + 1,
        updated_at = NOW()
    WHERE id = p_user_id
    RETURNING honest_streak INTO v_new_streak;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    RETURN v_new_streak;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Функция для сброса честной серии (при нечестном действии)
CREATE OR REPLACE FUNCTION reset_honest_streak(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_new_streak INTEGER;
BEGIN
    UPDATE public.users
    SET honest_streak = 0,
        updated_at = NOW()
    WHERE id = p_user_id
    RETURNING honest_streak INTO v_new_streak;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    RETURN v_new_streak;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Комментарии для документации
COMMENT ON COLUMN public.users.honest_streak IS 'Честная серия - количество честных действий подряд (честные провалы и завершения)';
COMMENT ON FUNCTION increment_honest_streak IS 'Увеличивает честную серию пользователя на 1';
COMMENT ON FUNCTION reset_honest_streak IS 'Сбрасывает честную серию пользователя в 0';
