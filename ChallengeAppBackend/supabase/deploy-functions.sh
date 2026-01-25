#!/bin/bash

# Скрипт для развертывания Edge Functions в Supabase
# Использование: ./deploy-functions.sh

set -e

echo "🚀 Развертывание Edge Functions в Supabase..."
echo ""

# Проверка, что supabase CLI установлен
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI не установлен!"
    echo "Установите: brew install supabase/tap/supabase"
    exit 1
fi

# Проверка авторизации
echo "📋 Проверка авторизации..."
if ! supabase projects list &> /dev/null; then
    echo "⚠️  Вы не авторизованы в Supabase"
    echo "Выполните: supabase login"
    echo "Это откроет браузер для авторизации"
    exit 1
fi

# Связывание проекта (если еще не связано)
echo "🔗 Связывание проекта..."
PROJECT_REF="qvyxkbeafgarcjjppttd"

if [ ! -f ".supabase/config.toml" ]; then
    echo "Связываем проект с ref: $PROJECT_REF"
    supabase link --project-ref $PROJECT_REF
else
    echo "✅ Проект уже связан"
fi

# Копирование функций в правильную структуру (если нужно)
if [ ! -d "supabase/functions" ]; then
    echo "📁 Создание структуры папок..."
    mkdir -p supabase/functions
    cp -r edge-functions/join-challenge supabase/functions/
    cp -r edge-functions/complete-day supabase/functions/
    cp -r edge-functions/fail-challenge supabase/functions/
    echo "✅ Структура создана"
fi

echo ""
echo "📦 Развертывание функций..."
echo ""

# Развертывание join-challenge
echo "1️⃣  Развертывание join-challenge..."
supabase functions deploy join-challenge --no-verify-jwt

# Развертывание complete-day
echo ""
echo "2️⃣  Развертывание complete-day..."
supabase functions deploy complete-day --no-verify-jwt

# Развертывание fail-challenge
echo ""
echo "3️⃣  Развертывание fail-challenge..."
supabase functions deploy fail-challenge --no-verify-jwt

echo ""
echo "✅ Все функции успешно развернуты!"
echo ""
echo "Проверьте в Supabase Dashboard → Edge Functions"
echo "URL: https://supabase.com/dashboard/project/$PROJECT_REF/functions"
