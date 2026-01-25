# Экраны и табы по бизнес-плану

## Идея (README, PRODUCT_ANALYSIS)

1. **Челленджи** — лента доступных челленджей, вход по кнопке.
2. **Активный челлендж** — «основной экран для отслеживания прогресса»: выполнить/провалить, таймер до конца дня.
3. **Мой прогресс** — «статистика и история челленджей»: общая статистика + список всех участий (активные, завершённые, проваленные).

---

## Табы (как сейчас)

| Таб | Экран | Назначение |
|-----|--------|------------|
| **Челленджи** | `ChallengesListView` | Список челленджей, вход, статусы |
| **Мой прогресс** | `ActiveChallengeView` | Текущий челлендж: выполнить/провалить, таймер |
| **Создать** | Заглушка «Скоро» | Пока отключено |
| **История** | `MyProgressView` | Статистика + список всех челленджей (история участий) |

---

## Что исправлено

- **Раньше:** таб «Мой прогресс» вёл на «статистика + история» (`MyProgressView`), таб «История» — на «текущий челлендж» (`ActiveChallengeView`). По смыслу было наоборот.
- **Сейчас:**
  - **Мой прогресс** = текущий челлендж (perform/fail) — то, что в плане называется «активный челлендж».
  - **История** = статистика и список всех челленджей — то, что в плане «история челленджей».

---

## Улучшения (внесены)

### 1. Единый ChallengeManager
- **Было:** `MainTabView` создавал свой `@StateObject` `ChallengeManager`, а `handleAppWillEnterForeground` и `NetworkMonitor` использовали `DIContainer.shared.challengeManager` — два инстанса, расхождения по данным и дубли логов.
- **Стало:** один инстанс из `DIContainer`. `RootView` передаёт его через `.environmentObject(RootView.sharedChallengeManager)`, `MainTabView` получает `@EnvironmentObject var challengeManager` и пробрасывает в табы. Foreground и реконнект используют тот же менеджер.

### 2. Нормализация userId
- В `ChallengeManager.getStats(for:)` и в `ChallengesListView.activeUserChallenges` сравнение `userId` идёт через `.lowercased()`, чтобы не зависеть от регистра (Supabase vs `currentUser.id`).

### 3. getUserChallenges при отсутствии пользователя
- **Было:** при `getCurrentUser() == nil` возвращался `[]`, кэш перезаписывался пустым списком — участие пропадало.
- **Стало:** в этом случае бросается `AppError.dataNotFound`. В `loadUserChallengesFromSupabase` при ошибке сохраняются существующие данные (fallback на UserDefaults), пустой список не записывается.

### 4. Дебаунс handleAppWillEnterForeground
- Обновление при возврате в приложение выполняется не чаще одного раза в 5 секунд (`lastForegroundRefresh` + `foregroundRefreshMinInterval`), чтобы снизить лишние запросы и дубли логов.

### 5. Устранение дубликатов файлов
- **Проблема:** в проекте были дубликаты `ChallengeManager.swift` и `ManagerProtocols.swift` в вложенной структуре `ChallengeApp/ChallengeApp/ChallengeApp/`, что вызывало ошибку компиляции `'ChallengeManager' is ambiguous for type lookup`.
- **Решение:** удалён дубликат `ChallengeManager.swift`, `ManagerProtocols.swift` перемещён в правильную папку `ChallengeApp/Protocols/`, вложенная структура очищена. Теперь каждый файл существует в единственном экземпляре.
