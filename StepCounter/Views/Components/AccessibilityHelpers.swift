//
//  AccessibilityHelpers.swift
//  StepCounter
//
//  Вспомогательные функции и модификаторы для accessibility
//

import SwiftUI

// MARK: - Accessibility Labels

/// Стандартные accessibility labels для приложения
enum AccessibilityLabels {
    static let steps = "Шаги"
    static let distance = "Дистанция"
    static let calories = "Калории"
    static let activeMinutes = "Активные минуты"
    static let goal = "Цель"
    static let progress = "Прогресс"
    static let level = "Уровень"
    static let rank = "Звание"
    static let achievements = "Достижения"
    static let challenges = "Челленджи"
    static let pet = "Питомец"
    static let tournament = "Турнир"
    static let share = "Поделиться"
    static let refresh = "Обновить"
    static let settings = "Настройки"
    static let close = "Закрыть"
    static let back = "Назад"
    static let next = "Далее"
    static let done = "Готово"
    static let cancel = "Отмена"
    static let save = "Сохранить"
    static let delete = "Удалить"
    static let edit = "Редактировать"
    static let add = "Добавить"
    static let premium = "Премиум"
    static let loading = "Загрузка"
    static let error = "Ошибка"
}

// MARK: - Accessibility Hints

/// Стандартные accessibility hints для приложения
enum AccessibilityHints {
    static func steps(_ count: Int) -> String {
        "У вас \(count) шагов сегодня"
    }
    
    static func distance(_ meters: Double) -> String {
        let km = meters / 1000
        return String(format: "Вы прошли %.2f километров", km)
    }
    
    static func calories(_ count: Double) -> String {
        "Вы сожгли \(Int(count)) калорий"
    }
    
    static func goalProgress(_ current: Int, _ goal: Int) -> String {
        let percent = Int((Double(current) / Double(goal)) * 100)
        return "Выполнено \(percent) процентов от цели в \(goal) шагов"
    }
    
    static func level(_ level: Int) -> String {
        "Ваш уровень: \(level)"
    }
    
    static func rank(_ rank: String) -> String {
        "Ваше звание: \(rank)"
    }
    
    static let doubleTapToActivate = "Двойное нажатие для активации"
    static let swipeToNavigate = "Свайп для навигации"
    static let longPressForOptions = "Долгое нажатие для дополнительных опций"
}

// MARK: - Accessibility Traits

// AccessibilityTraits уже доступен в SwiftUI через .accessibilityAddTraits() модификатор
// Используйте: .accessibilityAddTraits(.button), .accessibilityAddTraits(.header) и т.д.

// MARK: - View Extensions

extension View {
    /// Добавить accessibility label
    func accessibilityLabel(_ label: String) -> some View {
        self.accessibilityLabel(Text(label))
    }
    
    /// Добавить accessibility label с форматированием
    func accessibilityLabel(_ label: String, _ args: CVarArg...) -> some View {
        self.accessibilityLabel(Text(String(format: label, arguments: args)))
    }
    
    /// Добавить accessibility hint
    func accessibilityHint(_ hint: String) -> some View {
        self.accessibilityHint(Text(hint))
    }
    
    /// Добавить accessibility value
    func accessibilityValue(_ value: String) -> some View {
        self.accessibilityValue(Text(value))
    }
    
    /// Добавить accessibility value с форматированием
    func accessibilityValue(_ value: String, _ args: CVarArg...) -> some View {
        self.accessibilityValue(Text(String(format: value, arguments: args)))
    }
    
    /// Настроить accessibility для кнопки
    func accessibilityButton(
        label: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? AccessibilityHints.doubleTapToActivate)
            .accessibilityAddTraits(.isButton)
    }
    
    /// Настроить accessibility для заголовка
    func accessibilityHeader(_ text: String) -> some View {
        self
            .accessibilityLabel(text)
            .accessibilityAddTraits(.isHeader)
    }
    
    /// Настроить accessibility для статистики
    func accessibilityStatistic(
        label: String,
        value: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(value)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.updatesFrequently)
    }
    
    /// Настроить accessibility для карточки
    func accessibilityCard(
        title: String,
        content: String? = nil
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(title + (content.map { ", \($0)" } ?? ""))
    }
    
    /// Настроить accessibility для графика
    func accessibilityChart(
        title: String,
        dataPoints: Int,
        maxValue: Int
    ) -> some View {
        self
            .accessibilityLabel("\(title), график с \(dataPoints) точками данных")
            .accessibilityValue("Максимальное значение: \(maxValue)")
            .accessibilityAddTraits(.allowsDirectInteraction)
    }
    
    /// Настроить accessibility для списка
    func accessibilityList(
        title: String,
        itemCount: Int
    ) -> some View {
        self
            .accessibilityLabel("\(title), список из \(itemCount) элементов")
    }
}

// MARK: - Dynamic Type Support

// Dynamic Type уже доступен в SwiftUI через .dynamicTypeSize() модификатор

// MARK: - Voice Control Support

extension View {
    /// Добавить voice control label для голосового управления
    func voiceControlLabel(_ label: String) -> some View {
        self.accessibilityInputLabels([label])
    }
    
    /// Добавить несколько voice control labels
    func voiceControlLabels(_ labels: [String]) -> some View {
        self.accessibilityInputLabels(labels)
    }
}

// MARK: - Color Contrast

extension Color {
    /// Проверка контрастности для accessibility
    func accessibilityContrast(_ level: AccessibilityContrastLevel) -> Color {
        // В реальном приложении здесь была бы логика улучшения контрастности
        return self
    }
}

enum AccessibilityContrastLevel {
    case standard
    case increased
}

// MARK: - Reduce Motion Support

extension View {
    /// Учитывать настройку "Уменьшить движение"
    func reduceMotion(_ animated: Bool = true) -> some View {
        if animated {
            return self.animation(.default, value: UUID())
        } else {
            return self.animation(nil, value: UUID())
        }
    }
}
