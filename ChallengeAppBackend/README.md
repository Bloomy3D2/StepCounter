# Challenge App Backend - Supabase Configuration

Этот каталог содержит конфигурацию и скрипты для Supabase backend, который используется iOS приложением.

## Структура

```
ChallengeAppBackend/
├── supabase/                    # Конфигурация Supabase
│   ├── schema.sql              # Схема базы данных
│   ├── edge-functions/          # Edge Functions (Deno/TypeScript)
│   │   ├── join-challenge/     # Вступление в челлендж
│   │   ├── complete-day/       # Завершение дня
│   │   ├── fail-challenge/     # Провал челленджа
│   │   ├── payment-webhook/    # Webhook для платежей YooKassa
│   │   └── create-payout/      # Создание выплаты
│   ├── *.sql                   # SQL скрипты для миграций и фиксов
│   └── *.md                    # Документация
└── README.md                    # Этот файл
```

## Что здесь находится

### SQL скрипты
- `schema.sql` - основная схема базы данных
- `fix-*.sql` - исправления и миграции
- `test-data.sql` - тестовые данные

### Edge Functions
Edge Functions написаны на TypeScript/Deno и выполняются на Supabase:
- **join-challenge** - обработка вступления в челлендж
- **complete-day** - обработка завершения дня
- **fail-challenge** - обработка провала челленджа
- **payment-webhook** - обработка webhook от YooKassa
- **create-payout** - создание выплат через YooKassa Payouts API

## Использование

### Развертывание Edge Functions

```bash
cd supabase/edge-functions
# Следуйте инструкциям в DEPLOY_EDGE_FUNCTIONS.md
```

### Применение SQL скриптов

1. Откройте [Supabase Dashboard](https://supabase.com/dashboard)
2. Перейдите в SQL Editor
3. Скопируйте содержимое нужного `.sql` файла
4. Выполните скрипт

## Важные файлы

- `schema.sql` - основная схема БД (выполнить первым)
- `fix-challenge-stats-calculation.sql` - исправление расчета статистики
- `fix-payout-calculation.sql` - исправление расчета выплат
- `get-challenge-stats.sql` - функции для получения статистики

## Примечание

⚠️ **Java код удален** - iOS приложение работает напрямую с Supabase через `SupabaseManager.swift`, без промежуточного Java backend.
