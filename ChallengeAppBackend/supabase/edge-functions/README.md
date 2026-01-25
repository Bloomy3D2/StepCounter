# Edge Functions для Challenge App

## Файлы функций

- `join-challenge/index.ts` - Вступление в челлендж
- `complete-day/index.ts` - Отметка выполнения дня
- `fail-challenge/index.ts` - Провал челленджа

## Развертывание

### Через CLI:

```bash
# 1. Авторизация (если еще не авторизованы)
supabase login

# 2. Связывание проекта
cd /Users/maratgaliev/Downloads/Project/MyProjectGame/ChallengeAppBackend/supabase
supabase link --project-ref qvyxkbeafgarcjjppttd

# 3. Развертывание
cd edge-functions
supabase functions deploy join-challenge --no-verify-jwt
supabase functions deploy complete-day --no-verify-jwt
supabase functions deploy fail-challenge --no-verify-jwt
```

### Или используйте скрипт:

```bash
cd /Users/maratgaliev/Downloads/Project/MyProjectGame/ChallengeAppBackend/supabase
./deploy-functions.sh
```

### Через Dashboard:

1. Откройте: https://supabase.com/dashboard/project/qvyxkbeafgarcjjppttd/functions
2. Для каждой функции:
   - Create a new function
   - Скопируйте код из соответствующего `index.ts`
   - Deploy

## Проверка

После развертывания функции должны быть видны в Dashboard → Edge Functions.
