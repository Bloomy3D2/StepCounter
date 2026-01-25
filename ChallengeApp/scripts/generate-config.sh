#!/bin/bash

# Скрипт для генерации GeneratedConfig.swift из .xcconfig файлов
# Этот файл генерируется автоматически во время сборки

# Не используем set -e, чтобы не прерывать сборку при ошибках

# Определяем конфигурацию (Debug/Release)
CONFIG="${CONFIGURATION:-Debug}"

# Определяем правильный путь к корню проекта
# SRCROOT в Xcode указывает на директорию, где находится .xcodeproj файл
# В нашем случае это ChallengeApp/, поэтому скрипт находится в ${SRCROOT}/scripts/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Используем SRCROOT, если он задан, иначе определяем относительно скрипта
if [ -n "$SRCROOT" ]; then
    BASE_DIR="$SRCROOT"
else
    BASE_DIR="$PROJECT_ROOT"
fi

# Путь к .xcconfig файлу
if [ "$CONFIG" = "Release" ]; then
    CONFIG_FILE="${BASE_DIR}/ChallengeApp/Config.Release.xcconfig"
else
    CONFIG_FILE="${BASE_DIR}/ChallengeApp/Config.xcconfig"
fi

# Проверяем, что файл существует
if [ ! -f "$CONFIG_FILE" ]; then
    echo "⚠️ WARNING: Config file not found: $CONFIG_FILE"
    exit 0
fi

# Читаем значения из .xcconfig
SUPABASE_URL=""
SUPABASE_KEY=""
SHOP_ID=""
SECRET_KEY=""
TEST_MODE="YES"

while IFS='=' read -r key value; do
    # Убираем пробелы и комментарии
    key=$(echo "$key" | xargs)
    # Убираем inline-комментарии вида "  // comment", но НЕ режем URL "https://..."
    value=$(echo "$value" | xargs | sed 's/[[:space:]]\/\/.*$//' | xargs)
    
    # Пропускаем пустые строки и комментарии
    if [[ -z "$key" ]] || [[ "$key" =~ ^\/\/ ]] || [[ "$key" =~ ^MARK: ]]; then
        continue
    fi
    
    if [ "$key" = "SUPABASE_URL" ]; then
        SUPABASE_URL="$value"
    elif [ "$key" = "SUPABASE_KEY" ]; then
        SUPABASE_KEY="$value"
    elif [ "$key" = "YOOKASSA_SHOP_ID" ]; then
        SHOP_ID="$value"
    elif [ "$key" = "YOOKASSA_SECRET_KEY" ]; then
        SECRET_KEY="$value"
    elif [ "$key" = "YOOKASSA_TEST_MODE" ]; then
        TEST_MODE="$value"
    fi
done < "$CONFIG_FILE"

# Экранируем значения для безопасной вставки в Swift код
escape_for_swift_string() {
    # escape backslashes and double quotes
    echo "$1" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g'
}

SUPABASE_URL_ESCAPED="$(escape_for_swift_string "$SUPABASE_URL")"
SUPABASE_KEY_ESCAPED="$(escape_for_swift_string "$SUPABASE_KEY")"
SHOP_ID_ESCAPED="$(escape_for_swift_string "$SHOP_ID")"
SECRET_KEY_ESCAPED="$(escape_for_swift_string "$SECRET_KEY")"

# Определяем bool значение для TEST_MODE
if [ "$TEST_MODE" = "YES" ] || [ "$TEST_MODE" = "true" ]; then
    TEST_MODE_BOOL="true"
else
    TEST_MODE_BOOL="false"
fi

# Генерируем Swift код
OUTPUT_FILE="${BASE_DIR}/ChallengeApp/Utils/GeneratedConfig.swift"

cat > "$OUTPUT_FILE" << EOF
//
//  GeneratedConfig.swift
//  ChallengeApp
//
//  ⚠️ ВНИМАНИЕ: Этот файл генерируется автоматически!
//  НЕ РЕДАКТИРУЙТЕ ВРУЧНУЮ!
//  Генерируется из: $CONFIG_FILE
//  Configuration: $CONFIG
//

import Foundation

struct GeneratedConfig {
    // MARK: - Supabase
    static let supabaseURL: String = "${SUPABASE_URL_ESCAPED:-YOUR_SUPABASE_URL}"
    static let supabaseKey: String = "${SUPABASE_KEY_ESCAPED:-YOUR_SUPABASE_KEY}"
    
    // MARK: - YooKassa
    static let yooKassaShopId: String = "${SHOP_ID_ESCAPED:-YOUR_SHOP_ID}"
    static let yooKassaSecretKey: String = "${SECRET_KEY_ESCAPED:-YOUR_SECRET_KEY}"
    static let yooKassaIsTestMode: Bool = $TEST_MODE_BOOL
}
EOF

echo "✅ Generated GeneratedConfig.swift from $CONFIG_FILE"
echo "   Supabase URL: ${SUPABASE_URL:-NOT SET}"
if [ -n "$SUPABASE_KEY" ]; then
    echo "   Supabase Key: ${SUPABASE_KEY:0:20}..."
else
    echo "   Supabase Key: NOT SET"
fi
echo "   Shop ID: ${SHOP_ID:-NOT SET}"
echo "   Test Mode: $TEST_MODE_BOOL"
