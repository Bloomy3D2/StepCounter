//
//  Challenge.swift
//  ChallengeApp
//
//  Модель челленджа
//

import Foundation

struct Challenge: Identifiable, Codable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let duration: Int // дни
    let entryFee: Double
    let serviceFee: Double // процент комиссии
    let startDate: Date
    let endDate: Date
    var participants: Int
    var prizePool: Double
    var activeParticipants: Int
    var completedToday: Int // Количество участников, выполнивших день сегодня
    var failedToday: Int // Количество участников, выбывших сегодня
    var description: String
    var rules: [String]
    
    var isActive: Bool {
        Date() >= startDate && Date() <= endDate
    }
    
    var timeUntilStart: TimeInterval {
        max(0, startDate.timeIntervalSinceNow)
    }
    
    var formattedTimeUntilStart: String {
        let totalSeconds = Int(timeUntilStart)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if days > 0 {
            // Если больше суток, показываем дни и часы
            return String(format: "%d д %02d ч", days, hours)
        } else if hours > 0 {
            // Если больше часа, показываем часы и минуты
            return String(format: "%02d:%02d", hours, minutes)
        } else {
            // Если меньше часа, показываем минуты и секунды
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// Дата начала в локальном часовом поясе
    var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter.string(from: startDate)
    }
    
    /// Нормализованная дата старта (00:00 в локальном часовом поясе)
    /// Берёт день из startDate в UTC и создаёт дату в 00:00 локального времени для этого дня
    private var normalizedStartDate: Date {
        // Сначала получаем день из startDate в UTC
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(abbreviation: "UTC") ?? TimeZone.current
        let utcComponents = utcCalendar.dateComponents([.year, .month, .day], from: startDate)
        
        // Затем создаём дату в 00:00 локального времени для этого дня
        var localCalendar = Calendar.current
        localCalendar.timeZone = TimeZone.current
        
        return localCalendar.date(from: DateComponents(
            year: utcComponents.year,
            month: utcComponents.month,
            day: utcComponents.day,
            hour: 0,
            minute: 0,
            second: 0
        )) ?? startDate
    }
    
    /// Время старта (только время) - всегда 00:00 в локальном часовом поясе
    var formattedStartTime: String {
        return "00:00"
    }
    
    /// Дата старта (только дата) в локальном часовом поясе
    var formattedStartDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.timeZone = TimeZone.current
        // Используем нормализованную дату для отображения (00:00 локального времени)
        return formatter.string(from: normalizedStartDate)
    }
    
    /// Создать дату в 00:00 по локальному времени на указанный день
    static func midnightDate(daysFromNow: Int = 1) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: daysFromNow, to: today) ?? today
    }
    
    var formattedPrizePool: String {
        String(format: "%.0f ₽", prizePool)
    }
    
    var formattedEntryFee: String {
        String(format: "%.0f ₽", entryFee)
    }
    
    init(id: String = UUID().uuidString,
         title: String,
         subtitle: String,
         icon: String,
         duration: Int,
         entryFee: Double,
         serviceFee: Double = 15.0,
         startDate: Date,
         endDate: Date,
         participants: Int = 0,
         prizePool: Double = 0,
         activeParticipants: Int = 0,
         completedToday: Int = 0,
         failedToday: Int = 0,
         description: String = "",
         rules: [String] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.duration = duration
        self.entryFee = entryFee
        self.serviceFee = serviceFee
        self.startDate = startDate
        self.endDate = endDate
        self.participants = participants
        self.prizePool = prizePool
        self.activeParticipants = activeParticipants
        self.completedToday = completedToday
        self.failedToday = failedToday
        self.description = description
        self.rules = rules
    }
}

// MARK: - User Challenge Participation
struct UserChallenge: Identifiable, Codable, Equatable {
    let id: String
    let challengeId: String
    let userId: String
    let entryDate: Date
    var completedDays: [Date]
    var isActive: Bool
    var isCompleted: Bool
    var isFailed: Bool
    var payout: Double?
    
    var currentDay: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: entryDate)
        let today = calendar.startOfDay(for: Date())
        let days = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return days + 1
    }
    
    var hasCompletedToday: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return completedDays.contains { calendar.isDate($0, inSameDayAs: today) }
    }
    
    init(id: String = UUID().uuidString,
         challengeId: String,
         userId: String,
         entryDate: Date = Date(),
         completedDays: [Date] = [],
         isActive: Bool = true,
         isCompleted: Bool = false,
         isFailed: Bool = false,
         payout: Double? = nil) {
        self.id = id
        self.challengeId = challengeId
        self.userId = userId
        self.entryDate = entryDate
        self.completedDays = completedDays
        self.isActive = isActive
        self.isCompleted = isCompleted
        self.isFailed = isFailed
        self.payout = payout
    }
}

// MARK: - Challenge Statistics
struct ChallengeStats: Codable {
    var totalChallenges: Int
    var completedChallenges: Int
    var failedChallenges: Int
    var totalEarned: Double
    var totalLost: Double
    
    var winRate: Double {
        guard totalChallenges > 0 else { return 0 }
        return Double(completedChallenges) / Double(totalChallenges) * 100
    }
}
