-- Добавление поля avatar_url в таблицу users
-- Выполните этот SQL в Supabase SQL Editor

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Создание индекса для быстрого поиска (опционально)
CREATE INDEX IF NOT EXISTS idx_users_avatar_url ON public.users(avatar_url) WHERE avatar_url IS NOT NULL;

-- Комментарий к полю
COMMENT ON COLUMN public.users.avatar_url IS 'URL аватарки пользователя в Supabase Storage';
