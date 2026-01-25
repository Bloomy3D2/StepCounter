#!/usr/bin/env swift

// Скрипт для генерации Config.swift из .xcconfig файлов
// Этот файл генерируется автоматически во время сборки

import Foundation

// Определяем конфигурацию (Debug/Release)
let configuration = ProcessInfo.processInfo.environment["CONFIGURATION"] ?? "Debug"

// Путь к .xcconfig файлу
let configFile: String
if configuration == "Release" {
    configFile = "\(ProcessInfo.processInfo.environment["SRCROOT"] ?? "")/ChallengeApp/Config.Release.xcconfig"
} else {
    configFile = "\(ProcessInfo.processInfo.environment["SRCROOT"] ?? "")/ChallengeApp/Config.xcconfig"
}

// Читаем .xcconfig файл
var supabaseURL = ""
var supabaseKey = ""
var shopId = ""
var secretKey = ""
var testMode = "YES"

if let content = try? String(contentsOfFile: configFile, encoding: .utf8) {
    for line in content.components(separatedBy: .newlines) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty || trimmed.hasPrefix("//") || trimmed.hasPrefix("MARK:") {
            continue
        }
        
        if let range = trimmed.range(of: "=") {
            let key = String(trimmed[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            let value = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            
            if key == "SUPABASE_URL" {
                supabaseURL = value
            } else if key == "SUPABASE_KEY" {
                supabaseKey = value
            } else if key == "YOOKASSA_SHOP_ID" {
                shopId = value
            } else if key == "YOOKASSA_SECRET_KEY" {
                secretKey = value
            } else if key == "YOOKASSA_TEST_MODE" {
                testMode = value
            }
        }
    }
}

// Генерируем Swift код
// ⚠️ ВАЖНО: Для безопасности НЕ включаем реальные ключи в GeneratedConfig
// Вместо этого используем placeholder значения, а реальные ключи читаются из Info.plist
let swiftCode = """
//
//  GeneratedConfig.swift
//  ChallengeApp
//
//  ⚠️ ВНИМАНИЕ: Этот файл генерируется автоматически!
//  НЕ РЕДАКТИРУЙТЕ ВРУЧНУЮ!
//  Генерируется из: \(configFile)
//  Configuration: \(configuration)
//
//  ⚠️ БЕЗОПАСНОСТЬ: Этот файл содержит только placeholder значения.
//  Реальные ключи должны быть в Info.plist (через INFOPLIST_KEY_*) или переменных окружения.
//

import Foundation

struct GeneratedConfig {
    // MARK: - Supabase Configuration
    // Placeholder значения - реальные ключи читаются из Info.plist
    static let supabaseURL: String = "YOUR_SUPABASE_URL"
    static let supabaseKey: String = "YOUR_SUPABASE_KEY"
    
    // MARK: - YooKassa Configuration
    // Placeholder значения - реальные ключи читаются из Info.plist
    static let yooKassaShopId: String = "\(shopId.isEmpty ? "YOUR_SHOP_ID" : shopId)"
    static let yooKassaSecretKey: String = "\(secretKey.isEmpty ? "YOUR_SECRET_KEY" : secretKey)"
    static let yooKassaIsTestMode: Bool = \(testMode == "YES" || testMode == "true" ? "true" : "false")
}
"""

// Записываем в файл
let outputPath = "\(ProcessInfo.processInfo.environment["SRCROOT"] ?? "")/ChallengeApp/Utils/GeneratedConfig.swift"
try? swiftCode.write(toFile: outputPath, atomically: true, encoding: .utf8)

print("✅ Generated Config.swift from \(configFile)")
print("   Supabase URL: \(supabaseURL.isEmpty ? "NOT SET" : supabaseURL)")
print("   Supabase Key: \(supabaseKey.isEmpty ? "NOT SET" : "\(supabaseKey.prefix(20))...")")
print("   Shop ID: \(shopId)")
print("   Test Mode: \(testMode)")
