# Руководство по логированию

## 📋 Обзор

В приложении реализовано структурированное логирование для отладки. Все логи используют единый `Logger.shared` и содержат эмодзи-префиксы для быстрой идентификации типа события.

---

## 🔍 Типы логов

### Эмодзи-префиксы:
- 📱 - UI события (появление экранов, навигация)
- 👆 - Действия пользователя (нажатия кнопок)
- 🔐 - Аутентификация
- 💳 - Платежи
- ✅ - Успешные операции
- ❌ - Ошибки и провалы
- ⚠️ - Предупреждения
- 🔄 - Обновления состояния (честная серия, баланс)
- ⏱️ - Таймеры
- 🔍 - Поиск и проверки
- 📋 - Загрузка данных

---

## 📍 Ключевые места логирования

### 1. SplashView
- Появление экрана
- Нажатие кнопки "Начать"
- Результат autoSignIn

**Пример логов:**
```
📱 SplashView appeared
👆 SplashView: User tapped 'Начать' button
🔐 AppState.autoSignIn: Starting
🔐 AppState.autoSignIn: Success - Using existing session, userId=xxx, balance=0.0
```

---

### 2. RootView
- Переходы между экранами
- Проверка активных челленджей
- Изменения состояния аутентификации

**Пример логов:**
```
🔍 RootView.checkActiveChallenges: Starting
🔍 RootView.checkActiveChallenges: User loaded, userId=xxx, loading challenges
🔍 RootView.checkActiveChallenges: Loaded 2 challenges, 1 active
🔍 RootView.checkActiveChallenges: Navigation - showSplash=false, showQuickStart=false
📱 RootView: QuickStartView appeared
```

---

### 3. QuickStartView
- Появление экрана
- Поиск Quick Start челленджа
- Переход к оплате
- Навигация

**Пример логов:**
```
📱 QuickStartView appeared
👆 QuickStartView.handleStartChallenge: User tapped 'Начать', searching for Quick Start challenge (duration=1, entryFee=299.0)
📋 QuickStartView: Loading challenges from Supabase
📋 QuickStartView: Available challenges count=5
✅ QuickStartView: Found Quick Start challenge, challengeId=123, title=Первый челлендж
💳 QuickStartView: Opening PaymentView for challengeId=123, entryFee=299.0
```

---

### 4. ActiveChallengeView
- Появление экрана
- Завершение дня
- Провал челленджа
- Работа таймера

**Пример логов:**
```
📱 ActiveChallengeView appeared, userChallengeId=xxx
⏱️ ActiveChallengeView: Starting timer, timeRemaining=23:45:12
✅ ActiveChallengeView: User tapped 'Выполнил', userChallengeId=xxx, currentDay=1
✅ ChallengeManager.completeDay: User balance updated, userId=xxx, balance=299.0, honestStreak=1
✅ ActiveChallengeView: Day completed successfully
⏱️ ActiveChallengeView.stopTimer: Timer stopped
```

---

### 5. ChallengeManager
- Завершение дня
- Провал челленджа
- Обновление честной серии

**Пример логов:**
```
✅ ChallengeManager.completeDay: Starting, userChallengeId=xxx
✅ ChallengeManager.completeDay: User balance updated, userId=xxx, balance=299.0, honestStreak=1
🔄 ChallengeManager.updateHonestStreak: Incrementing streak (honest action), userId=xxx
✅ ChallengeManager.updateHonestStreak: Streak incremented, userId=xxx, newStreak=1
```

---

## 🐛 Как использовать логи для отладки

### 1. Поиск проблемы
Используйте эмодзи-префиксы для быстрого поиска:
- Проблема с оплатой → ищите 💳
- Проблема с аутентификацией → ищите 🔐
- Проблема с завершением дня → ищите ✅
- Ошибки → ищите ❌

### 2. Трассировка потока
Следуйте по логам от начала до конца:
```
📱 SplashView appeared
👆 SplashView: User tapped 'Начать' button
🔐 AppState.autoSignIn: Starting
🔐 AppState.autoSignIn: Success
🔍 RootView.checkActiveChallenges: Starting
...
```

### 3. Контекст
Все логи содержат контекст:
- `userId` - ID пользователя
- `challengeId` - ID челленджа
- `userChallengeId` - ID участия пользователя
- `balance` - Баланс пользователя
- `honestStreak` - Честная серия
- `currentDay` - Текущий день челленджа

---

## 📝 Формат логов

### Структура:
```
[Эмодзи] [Компонент].[Метод]: [Действие], [Контекст]
```

### Примеры:
```
✅ ChallengeManager.completeDay: User balance updated, userId=abc123, balance=299.0, honestStreak=1
❌ ActiveChallengeView.handleFailChallenge: Failed to fail challenge, userChallengeId=xyz789
🔍 RootView.checkActiveChallenges: Loaded 2 challenges, 1 active
```

---

## ⚠️ Важные моменты

1. **Не избыточное логирование**: Логируются только ключевые события, не каждое обновление UI
2. **Контекст всегда**: Каждый лог содержит необходимый контекст для отладки
3. **Уровни логирования**: 
   - `info` - обычные события
   - `warning` - предупреждения
   - `error` - ошибки
   - `debug` - детальная отладка (таймеры)

---

## 🔧 Как получить логи

### В Xcode:
1. Откройте консоль (View → Debug Area → Activate Console)
2. Запустите приложение
3. Фильтруйте по эмодзи или тексту

### В системном логе:
```bash
log stream --predicate 'subsystem == "com.challengeapp"' --level debug
```

---

## 📋 Чеклист для отладки

При отправке логов для отладки, убедитесь что включены:

- [ ] Логи от начала проблемы (SplashView или QuickStartView)
- [ ] Все логи с эмодзи ❌ (ошибки)
- [ ] Контекст (userId, challengeId, userChallengeId)
- [ ] Последовательность действий пользователя
- [ ] Результат операции (успех/провал)

---

**Логирование готово к использованию! 🎉**
