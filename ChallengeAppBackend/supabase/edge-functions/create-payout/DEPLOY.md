# Развертывание Edge Function create-payout

## Быстрый старт

```bash
cd ChallengeAppBackend/supabase
supabase functions deploy create-payout --no-verify-jwt
```

## Настройка переменных окружения

В Supabase Dashboard → Settings → Edge Functions → Secrets добавьте:

```
YOOKASSA_SHOP_ID=ваш_shop_id
YOOKASSA_SECRET_KEY=ваш_secret_key
```

**Примечание:** Используйте ключи для Payouts API (могут отличаться от ключей для Payments API).

## Проверка работы

После развертывания проверьте логи в Supabase Dashboard:
- Edge Functions → create-payout → Logs

## Важно

1. **Подключите YooKassa Payouts** в личном кабинете YooKassa
2. **Пополните баланс YooKassa** для выплат
3. **Проверьте комиссии** - 2.8% + НДС для карт, 4% + НДС для мобильных

## Документация

См. `YOOKASSA_PAYOUTS_SETUP.md` для полной инструкции.
