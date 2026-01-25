# Пример: Как Supabase заменит Java Backend

## Архитектура с Supabase:

```
iOS App
   ↓
Supabase Client SDK
   ↓
┌─────────────────────────────────────┐
│         Supabase                    │
│  ┌──────────────────────────────┐      │
│  │  PostgreSQL Database      │      │
│  │  (таблицы как в Java)     │      │
│  └──────────────────────────────┘      │
│  ┌──────────────────────────────┐      │
│  │  Supabase Auth              │      │
│  │  (замена JWT)               │      │
│  └──────────────────────────────┘      │
│  ┌──────────────────────────────┐      │
│  │  Edge Functions              │      │
│  │  (замена Java сервисов)      │      │
│  └──────────────────────────────┘      │
│  ┌──────────────────────────────┐      │
│  │  Realtime                    │      │
│  │  (обновления в реальном      │      │
│  │   времени)                   │      │
│  └──────────────────────────────┘      │
└─────────────────────────────────────┘
```

## Что нужно переписать:

### 1. База данных (автоматически)

**Java:**
```java
@Entity
public class User {
    @Id
    @GeneratedValue
    private Long id;
    private String email;
    private Double balance;
}
```

**Supabase:**
```sql
-- Та же структура!
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    balance DECIMAL DEFAULT 0.0
);
```

✅ **Почти идентично!**

---

### 2. Аутентификация (проще!)

**Java:**
```java
@PostMapping("/api/auth/login")
public AuthResponse login(@RequestBody LoginRequest request) {
    // Проверка пароля
    // Генерация JWT
    // Возврат токена
}
```

**Supabase:**
```swift
// iOS код
let response = try await supabase.auth.signIn(
    email: email,
    password: password
)
// Готово! Токен автоматически
```

✅ **Намного проще!**

---

### 3. Бизнес-логика (нужно переписать)

**Java:**
```java
@PostMapping("/api/challenges/{id}/join")
public UserChallengeDto joinChallenge(...) {
    // Вся логика в Java
}
```

**Supabase:**
```typescript
// Edge Function (Deno/TypeScript)
Deno.serve(async (req) => {
    const { userId, challengeId } = await req.json();
    
    // Та же логика, но на TypeScript
    const user = await supabase
        .from('users')
        .select('*')
        .eq('id', userId)
        .single();
    
    // Проверка баланса
    if (user.balance < challenge.entryFee) {
        return new Response('Insufficient balance', { status: 400 });
    }
    
    // Транзакция
    await supabase.rpc('join_challenge', {
        user_id: userId,
        challenge_id: challengeId
    });
    
    return new Response(JSON.stringify(result));
});
```

⚠️ **Нужно переписать на TypeScript, но логика та же**

---

### 4. Автоматические задачи

**Java:**
```java
@Scheduled(cron = "0 0 0 * * *")
public void checkFailedChallenges() { ... }
```

**Supabase:**
```sql
-- PostgreSQL функция
CREATE OR REPLACE FUNCTION check_failed_challenges()
RETURNS void AS $$
BEGIN
    -- Та же логика
END;
$$ LANGUAGE plpgsql;

-- pg_cron
SELECT cron.schedule(
    'check-failed-daily',
    '0 0 * * *',
    $$SELECT check_failed_challenges()$$
);
```

✅ **Работает аналогично**

---

## Код для iOS (Supabase):

```swift
import Supabase

class ChallengeService {
    let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://your-project.supabase.co")!,
        supabaseKey: "your-anon-key"
    )
    
    // Присоединиться к челленджу
    func joinChallenge(challengeId: Int) async throws {
        // Вызов Edge Function
        let response = try await supabase.functions
            .invoke("join-challenge", body: [
                "challengeId": challengeId
            ])
    }
    
    // Получить челленджи
    func getChallenges() async throws -> [Challenge] {
        let response = try await supabase
            .from("challenges")
            .select("*")
            .execute()
        
        return try JSONDecoder().decode([Challenge].self, from: response.data)
    }
}
```

---

## ИТОГ:

### ✅ Supabase ЗАМЕНЯЕТ:
- ✅ Базу данных (100%)
- ✅ Аутентификацию (100%, даже проще)
- ✅ API endpoints (через Edge Functions)
- ✅ Автоматические задачи (через pg_cron)

### ⚠️ НУЖНО ПЕРЕПИСАТЬ:
- ⚠️ Бизнес-логику с Java на TypeScript (Edge Functions)
- ⚠️ Но логика остается той же!

### 💰 СТОИМОСТЬ:
- Бесплатно: 500MB БД, 2GB bandwidth
- Pro: $25/мес - 8GB БД, 50GB bandwidth

---

## ВЫВОД:

**Да, Supabase может заменить Java Backend!**

Но нужно:
1. Переписать сервисы на TypeScript (Edge Functions)
2. Настроить PostgreSQL функции для сложной логики
3. Использовать Supabase Client SDK в iOS

**Преимущества:**
- Меньше кода
- Проще развертывание
- Бесплатно для старта
- Автоматическое масштабирование

**Недостатки:**
- Меньше контроля
- Нужно знать TypeScript
- Vendor lock-in
