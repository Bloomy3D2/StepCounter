//
//  CalendarExtensions.swift
//  StepCounter
//
//  Безопасные расширения для работы с датами
//

import Foundation

extension Calendar {
    /// Безопасное добавление компонента к дате
    /// - Parameters:
    ///   - component: Компонент календаря для добавления
    ///   - value: Значение для добавления
    ///   - date: Исходная дата
    ///   - fallback: Дата по умолчанию, если вычисление не удалось
    /// - Returns: Новая дата или fallback
    func safeDate(
        byAdding component: Calendar.Component,
        value: Int,
        to date: Date,
        fallback: Date? = nil
    ) -> Date? {
        return self.date(byAdding: component, value: value, to: date) ?? fallback
    }
    
    /// Безопасное добавление компонента к дате с обязательным результатом
    /// - Parameters:
    ///   - component: Компонент календаря для добавления
    ///   - value: Значение для добавления
    ///   - date: Исходная дата
    ///   - defaultDate: Дата по умолчанию, если вычисление не удалось
    /// - Returns: Новая дата или defaultDate
    func safeDate(
        byAdding component: Calendar.Component,
        value: Int,
        to date: Date,
        default defaultDate: Date
    ) -> Date {
        return self.date(byAdding: component, value: value, to: date) ?? defaultDate
    }
    
    /// Безопасное вычисление начала недели
    /// - Parameter date: Исходная дата
    /// - Returns: Начало недели или nil
    func safeStartOfWeek(for date: Date) -> Date? {
        guard let startOfWeek = self.date(from: self.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) else {
            return nil
        }
        return startOfWeek
    }
    
    /// Безопасное вычисление начала месяца
    /// - Parameter date: Исходная дата
    /// - Returns: Начало месяца
    func safeStartOfMonth(for date: Date) -> Date {
        let components = self.dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
    
    /// Безопасное вычисление начала года
    /// - Parameter date: Исходная дата
    /// - Returns: Начало года
    func safeStartOfYear(for date: Date) -> Date {
        let components = self.dateComponents([.year], from: date)
        return self.date(from: components) ?? date
    }
    
    /// Безопасное вычисление количества дней между датами
    /// - Parameters:
    ///   - start: Начальная дата
    ///   - end: Конечная дата
    /// - Returns: Количество дней или 0, если вычисление не удалось
    func safeDaysBetween(_ start: Date, and end: Date) -> Int {
        let components = self.dateComponents([.day], from: start, to: end)
        return abs(components.day ?? 0)
    }
}
