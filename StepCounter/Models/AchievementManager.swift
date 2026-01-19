//
//  AchievementManager.swift
//  StepCounter
//
//  Система достижений и наград с уникальными медалями
//

import Foundation
import SwiftUI

// MARK: - Редкость достижения

enum AchievementRarity: String, Codable {
    case common      // Обычное (бронза)
    case rare        // Редкое (серебро)
    case epic        // Эпическое (золото)
    case legendary   // Легендарное (платина/радуга)
    
    var name: String {
        switch self {
        case .common: return "Обычное"
        case .rare: return "Редкое"
        case .epic: return "Эпическое"
        case .legendary: return "Легендарное"
        }
    }
    
    var frameColors: [Color] {
        switch self {
        case .common:
            return [Color(hex: "CD7F32"), Color(hex: "8B4513")]  // Бронза
        case .rare:
            return [Color(hex: "C0C0C0"), Color(hex: "71797E")]  // Серебро
        case .epic:
            return [Color(hex: "FFD700"), Color(hex: "FFA500")]  // Золото
        case .legendary:
            return [Color(hex: "E5E4E2"), Color(hex: "9FE2BF"), Color(hex: "87CEEB"), Color(hex: "DDA0DD")]  // Платина/радуга
        }
    }
    
    var glowColor: Color {
        switch self {
        case .common: return Color(hex: "CD7F32").opacity(0.5)
        case .rare: return Color(hex: "C0C0C0").opacity(0.6)
        case .epic: return Color(hex: "FFD700").opacity(0.7)
        case .legendary: return Color(hex: "E5E4E2").opacity(0.8)
        }
    }
    
    var xpBonus: Int {
        switch self {
        case .common: return 50
        case .rare: return 150
        case .epic: return 500
        case .legendary: return 2000
        }
    }
}

// MARK: - Категория достижения

enum AchievementCategory: String, Codable, CaseIterable {
    case steps      // Шаги
    case streak     // Серии
    case distance   // Дистанция
    case calories   // Калории
    case time       // Время суток
    case special    // Особые
    
    var name: String {
        switch self {
        case .steps: return "Шаги"
        case .streak: return "Серии"
        case .distance: return "Путешествия"
        case .calories: return "Калории"
        case .time: return "Время"
        case .special: return "Особые"
        }
    }
    
    var icon: String {
        switch self {
        case .steps: return "figure.walk"
        case .streak: return "flame.fill"
        case .distance: return "map.fill"
        case .calories: return "bolt.heart.fill"
        case .time: return "clock.fill"
        case .special: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .steps: return .green
        case .streak: return .orange
        case .distance: return .cyan
        case .calories: return .red
        case .time: return .purple
        case .special: return .yellow
        }
    }
}

// MARK: - Типы достижений

enum AchievementType: String, Codable, CaseIterable {
    // Шаги
    case firstSteps = "first_steps"
    case step5k = "step_5k"
    case step10k = "step_10k"
    case step15k = "step_15k"
    case step20k = "step_20k"
    case step50k = "step_50k"
    case stepMillion = "step_million"
    
    // Серии
    case streak3 = "streak_3"
    case streak7 = "streak_7"
    case streak14 = "streak_14"
    case streak30 = "streak_30"
    case streak100 = "streak_100"
    case streak365 = "streak_365"
    
    // Дистанция
    case distance10km = "distance_10km"
    case distance50km = "distance_50km"
    case distance100km = "distance_100km"
    case distanceMoon = "distance_moon"
    
    // Калории
    case calories1000 = "calories_1000"
    case calories5000 = "calories_5000"
    case calories10000 = "calories_10000"
    
    // Время суток
    case earlyBird = "early_bird"
    case nightOwl = "night_owl"
    case weekendWarrior = "weekend_warrior"
    case mondayMotivation = "monday_motivation"
    
    // Особые
    case perfectWeek = "perfect_week"
    case newYearWalker = "new_year_walker"
    case birthdaySteps = "birthday_steps"
    case socialButterfly = "social_butterfly"
    
    // Сезонные
    case springBloom = "spring_bloom"
    case summerSun = "summer_sun"
    case autumnLeaves = "autumn_leaves"
    case winterFrost = "winter_frost"
    
    // Специальные события
    case valentineSteps = "valentine_steps"
    case easterSteps = "easter_steps"
    case halloweenWalk = "halloween_walk"
    case christmasWalk = "christmas_walk"
    case newYearChallenge = "new_year_challenge"
    
    // Расширенные шаги
    case step25k = "step_25k"
    case step30k = "step_30k"
    case step100k = "step_100k"
    case stepWeek100k = "step_week_100k"
    case stepMonth500k = "step_month_500k"
    
    // Расширенные серии
    case streak50 = "streak_50"
    case streak200 = "streak_200"
    case streak500 = "streak_500"
    
    // Расширенные дистанции
    case distance25km = "distance_25km"
    case distance75km = "distance_75km"
    case distance200km = "distance_200km"
    
    // Расширенные калории
    case calories2500 = "calories_2500"
    case calories15000 = "calories_15000"
    
    // Скрытые (Easter eggs)
    case midnightWalker = "midnight_walker"
    case marathonRunner = "marathon_runner"
    case speedDemon = "speed_demon"
    
    // Коллекционные
    case achievementCollector = "achievement_collector"
    
    var title: String {
        switch self {
        case .firstSteps: return "Первые шаги"
        case .step5k: return "Активный день"
        case .step10k: return "Настоящий ходок"
        case .step15k: return "Неутомимый"
        case .step20k: return "Марафонец"
        case .step50k: return "Ультрамарафон"
        case .stepMillion: return "Миллионер шагов"
        case .streak3: return "Тройка"
        case .streak7: return "Неделя силы"
        case .streak14: return "Железная воля"
        case .streak30: return "Месяц чемпиона"
        case .streak100: return "Легенда 100 дней"
        case .streak365: return "Годовой титан"
        case .distance10km: return "Исследователь"
        case .distance50km: return "Путешественник"
        case .distance100km: return "Кругосветка"
        case .distanceMoon: return "До Луны"
        case .calories1000: return "Сжигатель"
        case .calories5000: return "Инферно"
        case .calories10000: return "Вулкан"
        case .earlyBird: return "Ранняя пташка"
        case .nightOwl: return "Ночная сова"
        case .weekendWarrior: return "Воин выходных"
        case .mondayMotivation: return "Понедельник — сила"
        case .perfectWeek: return "Идеальная неделя"
        case .newYearWalker: return "Новогодний ходок"
        case .birthdaySteps: return "День рождения"
        case .socialButterfly: return "Социальная бабочка"
        case .springBloom: return "Весенний цвет"
        case .summerSun: return "Летнее солнце"
        case .autumnLeaves: return "Осенние листья"
        case .winterFrost: return "Зимний иней"
        case .valentineSteps: return "День влюбленных"
        case .easterSteps: return "Пасхальный шаг"
        case .halloweenWalk: return "Хэллоуин прогулка"
        case .christmasWalk: return "Рождественская прогулка"
        case .newYearChallenge: return "Новогодний челлендж"
        case .step25k: return "Супер ходок"
        case .step30k: return "Ультра ходок"
        case .step100k: return "100K мастер"
        case .stepWeek100k: return "Неделя 100K"
        case .stepMonth500k: return "Месяц 500K"
        case .streak50: return "50 дней силы"
        case .streak200: return "200 дней легенды"
        case .streak500: return "500 дней бессмертия"
        case .distance25km: return "25 км путешественник"
        case .distance75km: return "75 км исследователь"
        case .distance200km: return "200 км мастер"
        case .calories2500: return "2500 калорий"
        case .calories15000: return "15000 калорий"
        case .midnightWalker: return "Полночный ходок"
        case .marathonRunner: return "Марафонский бегун"
        case .speedDemon: return "Демон скорости"
        case .achievementCollector: return "Коллекционер"
        }
    }
    
    var description: String {
        switch self {
        case .firstSteps: return "Сделайте первые 1,000 шагов"
        case .step5k: return "Пройдите 5,000 шагов за день"
        case .step10k: return "Пройдите 10,000 шагов за день"
        case .step15k: return "Пройдите 15,000 шагов за день"
        case .step20k: return "Пройдите 20,000 шагов за день"
        case .step50k: return "Пройдите 50,000 шагов за день"
        case .stepMillion: return "Накопите 1,000,000 шагов"
        case .streak3: return "3 дня подряд с целью"
        case .streak7: return "7 дней подряд с целью"
        case .streak14: return "14 дней подряд с целью"
        case .streak30: return "30 дней подряд с целью"
        case .streak100: return "100 дней подряд с целью"
        case .streak365: return "365 дней подряд с целью"
        case .distance10km: return "Пройдите 10 км за неделю"
        case .distance50km: return "Пройдите 50 км за месяц"
        case .distance100km: return "Пройдите 100 км за месяц"
        case .distanceMoon: return "Пройдите 384,400 км (до Луны)"
        case .calories1000: return "Сожгите 1,000 калорий за день"
        case .calories5000: return "Сожгите 5,000 калорий за неделю"
        case .calories10000: return "Сожгите 10,000 калорий за неделю"
        case .earlyBird: return "1,000 шагов до 7 утра"
        case .nightOwl: return "1,000 шагов после 22:00"
        case .weekendWarrior: return "15,000 шагов в выходной"
        case .mondayMotivation: return "10,000 шагов в понедельник"
        case .perfectWeek: return "Выполняйте цель каждый день недели"
        case .newYearWalker: return "Выполните цель 1 января"
        case .birthdaySteps: return "Выполните цель в свой день рождения"
        case .socialButterfly: return "Добавьте 5 друзей"
        case .springBloom: return "Выполните цель в весенний сезон"
        case .summerSun: return "Выполните цель в летний сезон"
        case .autumnLeaves: return "Выполните цель в осенний сезон"
        case .winterFrost: return "Выполните цель в зимний сезон"
        case .valentineSteps: return "Выполните цель 14 февраля"
        case .easterSteps: return "Выполните цель на Пасху"
        case .halloweenWalk: return "Выполните цель 31 октября"
        case .christmasWalk: return "Выполните цель 25 декабря"
        case .newYearChallenge: return "Выполните цель в новогоднюю ночь"
        case .step25k: return "Пройдите 25,000 шагов за день"
        case .step30k: return "Пройдите 30,000 шагов за день"
        case .step100k: return "Пройдите 100,000 шагов за день"
        case .stepWeek100k: return "Пройдите 100,000 шагов за неделю"
        case .stepMonth500k: return "Пройдите 500,000 шагов за месяц"
        case .streak50: return "50 дней подряд с целью"
        case .streak200: return "200 дней подряд с целью"
        case .streak500: return "500 дней подряд с целью"
        case .distance25km: return "Пройдите 25 км за неделю"
        case .distance75km: return "Пройдите 75 км за месяц"
        case .distance200km: return "Пройдите 200 км за месяц"
        case .calories2500: return "Сожгите 2,500 калорий за день"
        case .calories15000: return "Сожгите 15,000 калорий за неделю"
        case .midnightWalker: return "Выполните цель ровно в полночь"
        case .marathonRunner: return "Пройдите марафонскую дистанцию (42.2 км)"
        case .speedDemon: return "Пройдите 5 км менее чем за 30 минут"
        case .achievementCollector: return "Разблокируйте 50 достижений"
        }
    }
    
    var category: AchievementCategory {
        switch self {
        case .firstSteps, .step5k, .step10k, .step15k, .step20k, .step50k, .stepMillion:
            return .steps
        case .streak3, .streak7, .streak14, .streak30, .streak100, .streak365:
            return .streak
        case .distance10km, .distance50km, .distance100km, .distanceMoon:
            return .distance
        case .calories1000, .calories5000, .calories10000:
            return .calories
        case .earlyBird, .nightOwl, .weekendWarrior, .mondayMotivation:
            return .time
        case .perfectWeek, .newYearWalker, .birthdaySteps, .socialButterfly, .springBloom, .summerSun, .autumnLeaves, .winterFrost, .valentineSteps, .easterSteps, .halloweenWalk, .christmasWalk, .newYearChallenge, .midnightWalker, .marathonRunner, .speedDemon, .achievementCollector:
            return .special
        case .step25k, .step30k, .step100k, .stepWeek100k, .stepMonth500k:
            return .steps
        case .streak50, .streak200, .streak500:
            return .streak
        case .distance25km, .distance75km, .distance200km:
            return .distance
        case .calories2500, .calories15000:
            return .calories
        }
    }
    
    var rarity: AchievementRarity {
        switch self {
        case .firstSteps, .step5k, .streak3, .distance10km, .earlyBird:
            return .common
        case .step10k, .streak7, .distance50km, .calories1000, .nightOwl, .weekendWarrior, .mondayMotivation:
            return .rare
        case .step15k, .step20k, .streak14, .streak30, .distance100km, .calories5000, .calories10000, .perfectWeek:
            return .epic
        case .step50k, .stepMillion, .streak100, .streak365, .distanceMoon, .newYearWalker, .birthdaySteps, .socialButterfly, .step100k, .stepWeek100k, .stepMonth500k, .streak200, .streak500, .distance200km, .calories15000, .midnightWalker, .marathonRunner, .speedDemon, .achievementCollector, .newYearChallenge:
            return .legendary
        case .step25k, .step30k, .streak50, .distance75km, .calories2500:
            return .epic
        case .springBloom, .summerSun, .autumnLeaves, .winterFrost, .valentineSteps, .easterSteps, .halloweenWalk, .christmasWalk, .distance25km:
            return .rare
        }
    }
    
    /// Является ли достижение эксклюзивным (доступно только для Premium)
    var isPremium: Bool {
        // Эксклюзивные достижения - это легендарные сложные достижения
        switch self {
        case .step100k, .stepMonth500k, .streak200, .streak500, .distance200km, .calories15000, .achievementCollector:
            return true
        default:
            return false
        }
    }
    
    var requirement: Int {
        switch self {
        case .firstSteps: return 1000
        case .step5k: return 5000
        case .step10k: return 10000
        case .step15k: return 15000
        case .step20k: return 20000
        case .step50k: return 50000
        case .stepMillion: return 1000000
        case .streak3: return 3
        case .streak7: return 7
        case .streak14: return 14
        case .streak30: return 30
        case .streak100: return 100
        case .streak365: return 365
        case .distance10km: return 10000
        case .distance50km: return 50000
        case .distance100km: return 100000
        case .distanceMoon: return 384400000
        case .calories1000: return 1000
        case .calories5000: return 5000
        case .calories10000: return 10000
        case .earlyBird: return 1000
        case .nightOwl: return 1000
        case .weekendWarrior: return 15000
        case .mondayMotivation: return 10000
        case .perfectWeek: return 7
        case .newYearWalker: return 1
        case .birthdaySteps: return 1
        case .socialButterfly: return 5
        case .springBloom, .summerSun, .autumnLeaves, .winterFrost: return 1
        case .valentineSteps, .easterSteps, .halloweenWalk, .christmasWalk, .newYearChallenge: return 1
        case .step25k: return 25000
        case .step30k: return 30000
        case .step100k: return 100000
        case .stepWeek100k: return 100000
        case .stepMonth500k: return 500000
        case .streak50: return 50
        case .streak200: return 200
        case .streak500: return 500
        case .distance25km: return 25000
        case .distance75km: return 75000
        case .distance200km: return 200000
        case .calories2500: return 2500
        case .calories15000: return 15000
        case .midnightWalker: return 1
        case .marathonRunner: return 42200
        case .speedDemon: return 5000
        case .achievementCollector: return 50
        }
    }
    
    // Уникальные градиенты для каждой медали
    var medalGradient: [Color] {
        switch self {
        case .firstSteps:
            return [Color(hex: "56ab2f"), Color(hex: "a8e6cf")]
        case .step5k:
            return [Color(hex: "667eea"), Color(hex: "764ba2")]
        case .step10k:
            return [Color(hex: "f093fb"), Color(hex: "f5576c")]
        case .step15k:
            return [Color(hex: "4facfe"), Color(hex: "00f2fe")]
        case .step20k:
            return [Color(hex: "fa709a"), Color(hex: "fee140")]
        case .step50k:
            return [Color(hex: "a18cd1"), Color(hex: "fbc2eb")]
        case .stepMillion:
            return [Color(hex: "ffecd2"), Color(hex: "fcb69f"), Color(hex: "ff9a9e")]
        case .streak3:
            return [Color(hex: "f12711"), Color(hex: "f5af19")]
        case .streak7:
            return [Color(hex: "ff6a00"), Color(hex: "ee0979")]
        case .streak14:
            return [Color(hex: "f7971e"), Color(hex: "ffd200")]
        case .streak30:
            return [Color(hex: "fc4a1a"), Color(hex: "f7b733")]
        case .streak100:
            return [Color(hex: "eb3349"), Color(hex: "f45c43")]
        case .streak365:
            return [Color(hex: "ff0844"), Color(hex: "ffb199")]
        case .distance10km:
            return [Color(hex: "00c6fb"), Color(hex: "005bea")]
        case .distance50km:
            return [Color(hex: "0082c8"), Color(hex: "667db6")]
        case .distance100km:
            return [Color(hex: "1e3c72"), Color(hex: "2a5298")]
        case .distanceMoon:
            return [Color(hex: "2c3e50"), Color(hex: "4ca1af"), Color(hex: "c4e0e5")]
        case .calories1000:
            return [Color(hex: "f83600"), Color(hex: "f9d423")]
        case .calories5000:
            return [Color(hex: "ff416c"), Color(hex: "ff4b2b")]
        case .calories10000:
            return [Color(hex: "b92b27"), Color(hex: "1565c0")]
        case .earlyBird:
            return [Color(hex: "f7971e"), Color(hex: "ffd200"), Color(hex: "fff9e6")]
        case .nightOwl:
            return [Color(hex: "0f0c29"), Color(hex: "302b63"), Color(hex: "24243e")]
        case .weekendWarrior:
            return [Color(hex: "ec008c"), Color(hex: "fc6767")]
        case .mondayMotivation:
            return [Color(hex: "3494e6"), Color(hex: "ec6ead")]
        case .perfectWeek:
            return [Color(hex: "f5af19"), Color(hex: "f12711"), Color(hex: "667eea")]
        case .newYearWalker:
            return [Color(hex: "00d2ff"), Color(hex: "3a7bd5"), Color(hex: "fff")]
        case .birthdaySteps:
            return [Color(hex: "f953c6"), Color(hex: "b91d73")]
        case .socialButterfly:
            return [Color(hex: "a8edea"), Color(hex: "fed6e3")]
        case .springBloom:
            return [Color(hex: "FFB6C1"), Color(hex: "98FB98")]
        case .summerSun:
            return [Color(hex: "FFD700"), Color(hex: "FFA500")]
        case .autumnLeaves:
            return [Color(hex: "D2691E"), Color(hex: "CD853F")]
        case .winterFrost:
            return [Color(hex: "E0E0E0"), Color(hex: "87CEEB")]
        case .valentineSteps:
            return [Color(hex: "FF1493"), Color(hex: "FF69B4")]
        case .easterSteps:
            return [Color(hex: "FFB6C1"), Color(hex: "FFD700")]
        case .halloweenWalk:
            return [Color(hex: "FF4500"), Color(hex: "FFD700")]
        case .christmasWalk:
            return [Color(hex: "DC143C"), Color(hex: "228B22")]
        case .newYearChallenge:
            return [Color(hex: "00CED1"), Color(hex: "FFD700"), Color(hex: "FFF")]
        case .step25k:
            return [Color(hex: "9b59b6"), Color(hex: "e74c3c")]
        case .step30k:
            return [Color(hex: "e67e22"), Color(hex: "f39c12")]
        case .step100k:
            return [Color(hex: "c0392b"), Color(hex: "8e44ad")]
        case .stepWeek100k:
            return [Color(hex: "16a085"), Color(hex: "27ae60")]
        case .stepMonth500k:
            return [Color(hex: "2ecc71"), Color(hex: "3498db")]
        case .streak50:
            return [Color(hex: "e74c3c"), Color(hex: "c0392b")]
        case .streak200:
            return [Color(hex: "8e44ad"), Color(hex: "9b59b6")]
        case .streak500:
            return [Color(hex: "1a1a2e"), Color(hex: "16213e")]
        case .distance25km:
            return [Color(hex: "3498db"), Color(hex: "2980b9")]
        case .distance75km:
            return [Color(hex: "16a085"), Color(hex: "1abc9c")]
        case .distance200km:
            return [Color(hex: "34495e"), Color(hex: "2c3e50")]
        case .calories2500:
            return [Color(hex: "e74c3c"), Color(hex: "c0392b")]
        case .calories15000:
            return [Color(hex: "c0392b"), Color(hex: "8e44ad")]
        case .midnightWalker:
            return [Color(hex: "0f0c29"), Color(hex: "302b63"), Color(hex: "24243e")]
        case .marathonRunner:
            return [Color(hex: "f12711"), Color(hex: "f5af19")]
        case .speedDemon:
            return [Color(hex: "ff416c"), Color(hex: "ff4b2b")]
        case .achievementCollector:
            return [Color(hex: "ffecd2"), Color(hex: "fcb69f"), Color(hex: "ff9a9e"), Color(hex: "a8edea")]
    }
}

    // Уникальный символ/эмодзи для медали (для обратной совместимости)
    var medalSymbol: String {
        switch self {
        case .firstSteps: return "👟"
        case .step5k: return "🚶"
        case .step10k: return "🏃"
        case .step15k: return "💨"
        case .step20k: return "🏅"
        case .step50k: return "🦸"
        case .stepMillion: return "💎"
        case .streak3: return "🔥"
        case .streak7: return "⚡"
        case .streak14: return "💪"
        case .streak30: return "👑"
        case .streak100: return "🏆"
        case .streak365: return "🌟"
        case .distance10km: return "🗺️"
        case .distance50km: return "🧭"
        case .distance100km: return "🌍"
        case .distanceMoon: return "🌙"
        case .calories1000: return "🔥"
        case .calories5000: return "💥"
        case .calories10000: return "🌋"
        case .earlyBird: return "🌅"
        case .nightOwl: return "🦉"
        case .weekendWarrior: return "⚔️"
        case .mondayMotivation: return "💼"
        case .perfectWeek: return "✨"
        case .newYearWalker: return "🎆"
        case .birthdaySteps: return "🎂"
        case .socialButterfly: return "🦋"
        case .springBloom: return "🌸"
        case .summerSun: return "☀️"
        case .autumnLeaves: return "🍂"
        case .winterFrost: return "❄️"
        case .valentineSteps: return "💝"
        case .easterSteps: return "🐰"
        case .halloweenWalk: return "🎃"
        case .christmasWalk: return "🎄"
        case .newYearChallenge: return "🎆"
        case .step25k: return "⚡"
        case .step30k: return "🌟"
        case .step100k: return "💫"
        case .stepWeek100k: return "⭐"
        case .stepMonth500k: return "✨"
        case .streak50: return "🔥"
        case .streak200: return "💎"
        case .streak500: return "👑"
        case .distance25km: return "🗺️"
        case .distance75km: return "🧭"
        case .distance200km: return "🌍"
        case .calories2500: return "🔥"
        case .calories15000: return "💥"
        case .midnightWalker: return "🌙"
        case .marathonRunner: return "🏃"
        case .speedDemon: return "💨"
        case .achievementCollector: return "🏆"
        }
    }
    
    // Уникальная SF Symbols иконка для медали (в стиле Apple Fitness)
    var medalIcon: String {
        switch self {
        case .firstSteps: return "figure.walk"
        case .step5k: return "figure.walk.circle.fill"
        case .step10k: return "figure.run"
        case .step15k: return "figure.run.circle.fill"
        case .step20k: return "flame.fill"
        case .step50k: return "bolt.fill"
        case .stepMillion: return "diamond.fill"
        case .streak3: return "flame.fill"
        case .streak7: return "bolt.fill"
        case .streak14: return "bolt.circle.fill"
        case .streak30: return "crown.fill"
        case .streak100: return "trophy.fill"
        case .streak365: return "star.fill"
        case .distance10km: return "map.fill"
        case .distance50km: return "location.fill"
        case .distance100km: return "globe"
        case .distanceMoon: return "moon.fill"
        case .calories1000: return "flame.fill"
        case .calories5000: return "flame.circle.fill"
        case .calories10000: return "flame.circle"
        case .earlyBird: return "sunrise.fill"
        case .nightOwl: return "moon.stars.fill"
        case .weekendWarrior: return "calendar"
        case .mondayMotivation: return "briefcase.fill"
        case .perfectWeek: return "sparkles"
        case .newYearWalker: return "party.popper.fill"
        case .birthdaySteps: return "birthday.cake.fill"
        case .socialButterfly: return "person.2.fill"
        case .springBloom: return "leaf.fill"
        case .summerSun: return "sun.max.fill"
        case .autumnLeaves: return "leaf.fill"
        case .winterFrost: return "snowflake"
        case .valentineSteps: return "heart.fill"
        case .easterSteps: return "bunny.fill"
        case .halloweenWalk: return "pumpkin.fill"
        case .christmasWalk: return "tree.fill"
        case .newYearChallenge: return "party.popper.fill"
        case .step25k: return "bolt.fill"
        case .step30k: return "star.fill"
        case .step100k: return "sparkles"
        case .stepWeek100k: return "star.circle.fill"
        case .stepMonth500k: return "star.fill"
        case .streak50: return "flame.fill"
        case .streak200: return "diamond.fill"
        case .streak500: return "crown.fill"
        case .distance25km: return "map.fill"
        case .distance75km: return "location.fill"
        case .distance200km: return "globe.americas.fill"
        case .calories2500: return "flame.fill"
        case .calories15000: return "flame.circle.fill"
        case .midnightWalker: return "moon.fill"
        case .marathonRunner: return "figure.run"
        case .speedDemon: return "bolt.fill"
        case .achievementCollector: return "trophy.fill"
        }
    }
}

// MARK: - Достижение

struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let type: AchievementType
    var isUnlocked: Bool
    var unlockedDate: Date?
    var progress: Int
    
    static func == (lhs: Achievement, rhs: Achievement) -> Bool {
        lhs.id == rhs.id && lhs.isUnlocked == rhs.isUnlocked && lhs.progress == rhs.progress
    }
    
    init(type: AchievementType) {
        self.id = type.rawValue
        self.type = type
        self.isUnlocked = false
        self.unlockedDate = nil
        self.progress = 0
    }
    
    var progressPercent: Double {
        guard type.requirement > 0 else { return 0 }
        return min(1.0, Double(progress) / Double(type.requirement))
    }
}

// MARK: - Менеджер достижений

final class AchievementManager: ObservableObject {
    
    @Published var achievements: [Achievement] = []
    @Published var newlyUnlocked: Achievement?
    @Published var currentStreak: Int = 0
    @Published var totalStepsEver: Int = 0
    @Published var totalDistanceEver: Double = 0
    
    private let userDefaultsKey = "achievements_v2"
    private let streakKey = "currentStreak"
    private let lastGoalDateKey = "lastGoalDate"
    private let totalStepsKey = "totalStepsEver"
    private let totalDistanceKey = "totalDistanceEver"
    
    init() {
        // Быстрая загрузка критичных данных синхронно
        loadStreak()
        loadTotals()
        
        // Тяжелая загрузка достижений - асинхронно
        Task { @MainActor in
            loadAchievements()
        }
    }
    
    // MARK: - Persistence
    
    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let saved = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = saved
            
            // Добавляем новые достижения, если их нет
            let existingTypes = Set(achievements.map { $0.type })
            for type in AchievementType.allCases {
                if !existingTypes.contains(type) {
                    achievements.append(Achievement(type: type))
                }
            }
        } else {
            achievements = AchievementType.allCases.map { Achievement(type: $0) }
        }
    }
    
    private func saveAchievements() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    private func loadStreak() {
        currentStreak = UserDefaults.standard.integer(forKey: streakKey)
    }
    
    private func saveStreak() {
        UserDefaults.standard.set(currentStreak, forKey: streakKey)
        
        // Сохраняем streak в App Group для виджета
        if let sharedDefaults = UserDefaults(suiteName: "group.stepcounter.shared") {
            sharedDefaults.set(currentStreak, forKey: "streakDays")
        }
    }
    
    private func loadTotals() {
        totalStepsEver = UserDefaults.standard.integer(forKey: totalStepsKey)
        totalDistanceEver = UserDefaults.standard.double(forKey: totalDistanceKey)
    }
    
    private func saveTotals() {
        UserDefaults.standard.set(totalStepsEver, forKey: totalStepsKey)
        UserDefaults.standard.set(totalDistanceEver, forKey: totalDistanceKey)
    }
    
    // MARK: - Check Achievements
    
    func checkAchievements(steps: Int, distance: Double, calories: Double, goalReached: Bool, stepGoal: Int) {
        // Обновляем накопительные значения
        totalStepsEver += steps
        totalDistanceEver += distance
        saveTotals()
        
        // Проверяем достижения по шагам
        checkStepAchievements(steps: steps)
        
        // Проверяем серии
        if goalReached {
            updateStreak()
        }
        checkStreakAchievements()
        
        // Проверяем калории
        checkCalorieAchievements(calories: Int(calories))
        
        // Проверяем время суток
        checkTimeAchievements(steps: steps)
        
        // Проверяем особые
        checkSpecialAchievements()
        
        saveAchievements()
    }
    
    private func checkStepAchievements(steps: Int) {
        let stepAchievements: [(AchievementType, Int)] = [
            (.firstSteps, 1000),
            (.step5k, 5000),
            (.step10k, 10000),
            (.step15k, 15000),
            (.step20k, 20000),
            (.step50k, 50000)
        ]
        
        for (type, required) in stepAchievements {
            if let index = achievements.firstIndex(where: { $0.type == type }) {
                achievements[index].progress = min(steps, required)
                
                if steps >= required && !achievements[index].isUnlocked {
                    unlockAchievement(at: index)
                }
            }
        }
        
        // Миллион шагов (накопительно)
        if let index = achievements.firstIndex(where: { $0.type == .stepMillion }) {
            achievements[index].progress = min(totalStepsEver, 1000000)
            if totalStepsEver >= 1000000 && !achievements[index].isUnlocked {
                unlockAchievement(at: index)
            }
        }
    }
    
    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastDateString = UserDefaults.standard.string(forKey: lastGoalDateKey),
           let lastDate = ISO8601DateFormatter().date(from: lastDateString) {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            let daysDiff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if daysDiff == 1 {
                currentStreak += 1
            } else if daysDiff > 1 {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }
        
        UserDefaults.standard.set(ISO8601DateFormatter().string(from: today), forKey: lastGoalDateKey)
        saveStreak()
    }
    
    private func checkStreakAchievements() {
        let streakAchievements: [(AchievementType, Int)] = [
            (.streak3, 3),
            (.streak7, 7),
            (.streak14, 14),
            (.streak30, 30),
            (.streak100, 100),
            (.streak365, 365)
        ]
        
        for (type, required) in streakAchievements {
            if let index = achievements.firstIndex(where: { $0.type == type }) {
                achievements[index].progress = min(currentStreak, required)
                
                if currentStreak >= required && !achievements[index].isUnlocked {
                    unlockAchievement(at: index)
                }
            }
        }
    }
    
    private func checkCalorieAchievements(calories: Int) {
        let calorieAchievements: [(AchievementType, Int)] = [
            (.calories1000, 1000),
            (.calories5000, 5000),
            (.calories10000, 10000)
        ]
        
        for (type, required) in calorieAchievements {
            if let index = achievements.firstIndex(where: { $0.type == type }) {
                achievements[index].progress = min(calories, required)
                if calories >= required && !achievements[index].isUnlocked {
                    unlockAchievement(at: index)
                }
            }
        }
    }
    
    private func checkTimeAchievements(steps: Int) {
        let hour = Calendar.current.component(.hour, from: Date())
        let weekday = Calendar.current.component(.weekday, from: Date())
        
        // Ранняя пташка (до 7 утра)
        if hour < 7 && steps >= 1000 {
            if let index = achievements.firstIndex(where: { $0.type == .earlyBird }) {
                if !achievements[index].isUnlocked {
                    achievements[index].progress = 1000
                    unlockAchievement(at: index)
                }
            }
        }
        
        // Ночная сова (после 22:00)
        if hour >= 22 && steps >= 1000 {
            if let index = achievements.firstIndex(where: { $0.type == .nightOwl }) {
                if !achievements[index].isUnlocked {
                    achievements[index].progress = 1000
                    unlockAchievement(at: index)
                }
            }
        }
        
        // Понедельник (weekday == 2)
        if weekday == 2 && steps >= 10000 {
            if let index = achievements.firstIndex(where: { $0.type == .mondayMotivation }) {
                if !achievements[index].isUnlocked {
                    achievements[index].progress = 10000
                    unlockAchievement(at: index)
                }
            }
        }
        
        // Выходные (weekday == 1 или 7)
        if (weekday == 1 || weekday == 7) && steps >= 15000 {
            if let index = achievements.firstIndex(where: { $0.type == .weekendWarrior }) {
                if !achievements[index].isUnlocked {
                    achievements[index].progress = 15000
                    unlockAchievement(at: index)
                }
            }
        }
    }
    
    private func checkSpecialAchievements() {
        let today = Date()
        let calendar = Calendar.current
        
        // Новогодний ходок
        let month = calendar.component(.month, from: today)
        let day = calendar.component(.day, from: today)
        
        if month == 1 && day == 1 {
            if let index = achievements.firstIndex(where: { $0.type == .newYearWalker }) {
                if !achievements[index].isUnlocked && currentStreak >= 1 {
                    achievements[index].progress = 1
                unlockAchievement(at: index)
                }
            }
        }
    }
    
    private func unlockAchievement(at index: Int) {
        achievements[index].isUnlocked = true
        achievements[index].unlockedDate = Date()
        newlyUnlocked = achievements[index]
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Stats
    
    var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }
    
    var totalCount: Int {
        achievements.count
    }
    
    var unlockedAchievements: [Achievement] {
        achievements.filter { $0.isUnlocked }.sorted { ($0.unlockedDate ?? Date()) > ($1.unlockedDate ?? Date()) }
    }
    
    var lockedAchievements: [Achievement] {
        achievements.filter { !$0.isUnlocked }
    }
    
    func achievements(for category: AchievementCategory) -> [Achievement] {
        achievements.filter { $0.type.category == category }
    }
    
    func achievements(for rarity: AchievementRarity) -> [Achievement] {
        achievements.filter { $0.type.rarity == rarity }
    }
    
    var totalXPEarned: Int {
        achievements.filter { $0.isUnlocked }.reduce(0) { $0 + $1.type.rarity.xpBonus }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
