# Быстрое развертывание Edge Functions

## ⚡ Самый быстрый способ

### Вариант А: Через терминал (1 команда)

```bash
cd /Users/maratgaliev/Downloads/Project/MyProjectGame/ChallengeAppBackend/supabase && ./deploy-functions.sh
```

**Если скрипт просит авторизацию:**
```bash
supabase login
# (откроется браузер, войдите в Supabase)
# Затем снова запустите скрипт
```

---

### Вариант Б: Через Dashboard (без терминала)

1. Откройте: https://supabase.com/dashboard/project/qvyxkbeafgarcjjppttd/functions

2. Для каждой функции:
   - Нажмите **Create a new function**
   - Название: `join-challenge` (затем `complete-day`, затем `fail-challenge`)
   - Скопируйте код из файла:
     - `ChallengeAppBackend/supabase/edge-functions/join-challenge/index.ts`
     - `ChallengeAppBackend/supabase/edge-functions/complete-day/index.ts`
     - `ChallengeAppBackend/supabase/edge-functions/fail-challenge/index.ts`
   - Нажмите **Deploy**

---

## ✅ Проверка

После развертывания в Dashboard должно быть 3 функции:
- join-challenge
- complete-day  
- fail-challenge

**Готово!** Теперь приложение может вступать в челленджи через Supabase.
