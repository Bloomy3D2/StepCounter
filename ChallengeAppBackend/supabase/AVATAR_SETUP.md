# Настройка загрузки аватарки пользователя

## 📋 Что нужно сделать

### 1. Добавить поле `avatar_url` в таблицу `users`

Выполните SQL из файла `add-avatar-url.sql` в Supabase SQL Editor:

```sql
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS avatar_url TEXT;
```

### 2. Создать bucket "avatars" в Supabase Storage

1. Откройте **Supabase Dashboard** → **Storage**
2. Нажмите **Create a new bucket**
3. Название: `avatars`
4. **Public bucket**: ✅ (чтобы аватарки были доступны публично)
5. Нажмите **Create bucket**

### 3. Настроить RLS политики для bucket "avatars"

В Supabase SQL Editor выполните:

```sql
-- Политика для загрузки (пользователь может загружать только свои аватарки)
CREATE POLICY "Users can upload their own avatars"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Политика для чтения (все могут читать аватарки, так как bucket публичный)
CREATE POLICY "Anyone can read avatars"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- Политика для обновления (пользователь может обновлять только свои аватарки)
CREATE POLICY "Users can update their own avatars"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Политика для удаления (пользователь может удалять только свои аватарки)
CREATE POLICY "Users can delete their own avatars"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
);
```

### 4. Проверка

После настройки:
- Пользователь может выбрать фото из галереи
- Фото загружается в `avatars/{userId}/avatar.jpg`
- URL сохраняется в `users.avatar_url`
- Аватарка отображается в профиле

## ⚠️ Важно

- Bucket должен быть **публичным** для отображения аватарки
- Путь к файлу: `{userId}/avatar.jpg` (например, `123e4567-e89b-12d3-a456-426614174000/avatar.jpg`)
- Файлы автоматически перезаписываются при новой загрузке (upsert: true)
