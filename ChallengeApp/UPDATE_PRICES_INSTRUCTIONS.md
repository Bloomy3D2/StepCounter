# Инструкция по обновлению цен челленджей

## Проблема
Цены на странице не обновились, потому что данные загружаются из Supabase, а не из локальных тестовых данных.

## Решение

### 1. Обновить цены в Supabase

Выполните SQL скрипт в Supabase SQL Editor:

```sql
-- Обновление цен челленджей
UPDATE public.challenges 
SET entry_fee = 499.0,
    updated_at = NOW()
WHERE title = 'Быстрый старт' AND entry_fee != 499.0;

UPDATE public.challenges 
SET entry_fee = 999.0,
    updated_at = NOW()
WHERE title = 'Подъём до 7:00' AND entry_fee != 999.0;

UPDATE public.challenges 
SET entry_fee = 1499.0,
    updated_at = NOW()
WHERE title = '10,000 шагов' AND entry_fee != 1499.0;

UPDATE public.challenges 
SET entry_fee = 2999.0,
    updated_at = NOW()
WHERE title = 'Без соцсетей' AND entry_fee != 2999.0;

-- Проверка обновленных цен
SELECT title, entry_fee, duration, updated_at 
FROM public.challenges 
WHERE is_active = true
ORDER BY duration;
```

### 2. Очистить кэш в приложении

После обновления цен в Supabase:

1. **Перезапустите приложение** - это очистит кэш в памяти
2. Или используйте функцию "Сбросить локальные данные" в настройках профиля
3. Или потяните вниз на экране челленджей для обновления (pull-to-refresh)

### 3. Проверка

После выполнения SQL и очистки кэша, цены должны обновиться:
- Быстрый старт: **499 ₽**
- Подъём до 7:00: **999 ₽**
- 10,000 шагов: **1499 ₽**
- Без соцсетей: **2999 ₽**
