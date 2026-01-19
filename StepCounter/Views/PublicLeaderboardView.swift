//
//  PublicLeaderboardView.swift
//  StepCounter
//
//  Публичные лидерборды (глобальные, по странам, городам)
//

import SwiftUI

/// Область лидерборда
enum LeaderboardScope: String, CaseIterable {
    case global = "Весь мир"
    case country = "Страна"
    case city = "Город"
    case friends = "Друзья"
    
    var icon: String {
        switch self {
        case .global: return "globe"
        case .country: return "flag.fill"
        case .city: return "building.2.fill"
        case .friends: return "person.2.fill"
        }
    }
}

/// Период лидерборда
enum LeaderboardPeriod: String, CaseIterable {
    case daily = "День"
    case weekly = "Неделя"
    case monthly = "Месяц"
    case yearly = "Год"
    case allTime = "Все время"
    
    var days: Int {
        switch self {
        case .daily: return 1
        case .weekly: return 7
        case .monthly: return 30
        case .yearly: return 365
        case .allTime: return 10000
        }
    }
}


/// Менеджер публичных лидербордов
@MainActor
final class PublicLeaderboardManager: ObservableObject {
    static let shared = PublicLeaderboardManager()
    
    @Published var entries: [LeaderboardEntry] = []
    @Published var userRank: Int = 0
    @Published var isLoading: Bool = false
    
    private let storage = StorageManager.shared
    private let entriesKey = "leaderboardEntries"
    
    init() {
        loadMockEntries() // Для демонстрации
    }
    
    func loadLeaderboard(scope: LeaderboardScope, period: LeaderboardPeriod) {
        isLoading = true
        
        // TODO: Загрузить из Firebase/сервера
        // Пока используем моковые данные
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.entries = self.generateMockEntries(scope: scope, period: period)
            self.updateRanks()
            self.isLoading = false
        }
    }
    
    private func generateMockEntries(scope: LeaderboardScope, period: LeaderboardPeriod) -> [LeaderboardEntry] {
        // Генерируем моковые данные для демонстрации
        var entries: [LeaderboardEntry] = []
        
        // Пользователь всегда в топ-10
        entries.append(LeaderboardEntry(
            id: "user",
            userId: "user",
            displayName: "Вы",
            avatarEmoji: "🚶",
            steps: Int.random(in: 8000...12000),
            rank: 0
        ))
        
        // Генерируем других участников
        for i in 1...50 {
            entries.append(LeaderboardEntry(
                id: "user\(i)",
                userId: "user\(i)",
                displayName: "Участник \(i)",
                avatarEmoji: ["🚶", "🏃", "💪", "🔥", "⭐"].randomElement()!,
                steps: Int.random(in: 5000...20000),
                rank: 0
            ))
        }
        
        // Сортируем по шагам
        entries.sort { $0.steps > $1.steps }
        
        return entries
    }
    
    private func updateRanks() {
        for index in entries.indices {
            entries[index].rank = index + 1
        }
        
        // Находим ранг пользователя
        if let userIndex = entries.firstIndex(where: { $0.userId == "user" }) {
            userRank = entries[userIndex].rank
        }
    }
    
    private func loadMockEntries() {
        entries = generateMockEntries(scope: .global, period: .daily)
        updateRanks()
    }
}

struct PublicLeaderboardView: View {
    @StateObject private var leaderboardManager = PublicLeaderboardManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var selectedScope: LeaderboardScope = .global
    @State private var selectedPeriod: LeaderboardPeriod = .daily
    @State private var selectedCountry: String? = nil
    @State private var selectedCity: String? = nil
    @State private var showCountryPicker = false
    @State private var showCityPicker = false
    @State private var showAllEntries = false
    
    private let storage = StorageManager.shared
    private let scopeKey = "leaderboardScope"
    private let periodKey = "leaderboardPeriod"
    private let countryKey = "leaderboardCountry"
    private let cityKey = "leaderboardCity"
    
    private var accentGreen: Color { themeManager.accentGreen }
    private var accentGold: Color { Color(red: 1.0, green: 0.84, blue: 0.0) }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Фильтры
                    filtersSection
                    
                    // Лидерборд
                    if leaderboardManager.isLoading {
                        ProgressView("Загрузка...")
                            .tint(.white)
                            .padding(.top, 40)
                    } else {
                        leaderboardList
                    }
                }
            }
            .navigationTitle("Лидеры")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadSavedFilters()
                leaderboardManager.loadLeaderboard(scope: selectedScope, period: selectedPeriod)
            }
            .onChange(of: selectedScope) { _, newScope in
                saveFilters()
                if newScope == .country {
                    showCountryPicker = true
                } else if newScope == .city {
                    // Если страна не выбрана, сначала выбираем страну
                    if selectedCountry == nil {
                        showCountryPicker = true
                    } else {
                        showCityPicker = true
                    }
                } else {
                    leaderboardManager.loadLeaderboard(scope: newScope, period: selectedPeriod)
                }
            }
            .onChange(of: selectedPeriod) { _, newPeriod in
                saveFilters()
                leaderboardManager.loadLeaderboard(scope: selectedScope, period: newPeriod)
            }
            .onChange(of: selectedCountry) { _, _ in
                saveFilters()
                if selectedScope == .country {
                    leaderboardManager.loadLeaderboard(scope: selectedScope, period: selectedPeriod)
                } else if selectedScope == .city {
                    // Если был выбран scope "city", но страна не была выбрана, теперь показываем города
                    showCityPicker = true
                }
            }
            .onChange(of: selectedCity) { _, _ in
                saveFilters()
                if selectedScope == .city {
                    leaderboardManager.loadLeaderboard(scope: selectedScope, period: selectedPeriod)
                }
            }
            .sheet(isPresented: $showCountryPicker) {
                CountryPickerSheet(selectedCountry: $selectedCountry)
            }
            .sheet(isPresented: $showCityPicker) {
                CityPickerSheet(selectedCity: $selectedCity, country: selectedCountry)
            }
        }
    }
    
    // MARK: - Filters
    
    private var filtersSection: some View {
        VStack(spacing: 16) {
            // Область
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(LeaderboardScope.allCases, id: \.self) { scope in
                        let title = scope.rawValue + (scope == .country && selectedCountry != nil ? ": \(selectedCountry!)" : "") + (scope == .city && selectedCity != nil ? ": \(selectedCity!)" : "")
                        FilterChip(
                            title: title,
                            icon: scope.icon,
                            isSelected: selectedScope == scope
                        ) {
                            HapticManager.impact(style: .light)
                            selectedScope = scope
                        }
                    }
                    
                    // Кнопка сброса фильтров
                    if selectedScope != .global || selectedPeriod != .daily || selectedCountry != nil || selectedCity != nil {
                        Button {
                            HapticManager.impact(style: .light)
                            resetFilters()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 12))
                                Text("Сбросить")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Период
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(LeaderboardPeriod.allCases, id: \.self) { period in
                        FilterChip(
                            title: period.rawValue,
                            icon: nil,
                            isSelected: selectedPeriod == period
                        ) {
                            HapticManager.impact(style: .light)
                            selectedPeriod = period
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
    }
    
    private func resetFilters() {
        selectedScope = .global
        selectedPeriod = .daily
        selectedCountry = nil
        selectedCity = nil
        saveFilters()
        leaderboardManager.loadLeaderboard(scope: .global, period: .daily)
    }
    
    // MARK: - Filter Persistence
    
    private func loadSavedFilters() {
        // Load scope
        if let scopeRaw = storage.loadString(forKey: scopeKey),
           let scope = LeaderboardScope.allCases.first(where: { $0.rawValue == scopeRaw }) {
            selectedScope = scope
        }
        
        // Load period
        if let periodRaw = storage.loadString(forKey: periodKey),
           let period = LeaderboardPeriod.allCases.first(where: { $0.rawValue == periodRaw }) {
            selectedPeriod = period
        }
        
        // Load country
        if let country = storage.loadString(forKey: countryKey), !country.isEmpty {
            selectedCountry = country
        }
        
        // Load city
        if let city = storage.loadString(forKey: cityKey), !city.isEmpty {
            selectedCity = city
        }
    }
    
    private func saveFilters() {
        storage.saveString(selectedScope.rawValue, forKey: scopeKey)
        storage.saveString(selectedPeriod.rawValue, forKey: periodKey)
        if let country = selectedCountry {
            storage.saveString(country, forKey: countryKey)
        }
        if let city = selectedCity {
            storage.saveString(city, forKey: cityKey)
        }
    }
    
    // MARK: - Leaderboard List
    
    private var entriesToShow: ArraySlice<LeaderboardEntry> {
        if showAllEntries {
            return leaderboardManager.entries[...]
        } else {
            return leaderboardManager.entries.prefix(10)
        }
    }
    
    private var leaderboardList: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Позиция пользователя (если не в топ-10)
                if leaderboardManager.userRank > 10 {
                    userPositionCard
                }
                
                // Коллекция записей (топ-10 или полный список)
                ForEach(Array(entriesToShow.enumerated()), id: \.element.id) { index, entry in
                    LeaderboardRow(
                        entry: entry,
                        position: index + 1,
                        isUser: entry.userId == "user"
                    )
                }
                
                // Кнопка переключения режима (если есть больше 10 записей)
                if leaderboardManager.entries.count > 10 {
                    Button {
                        withAnimation(.spring()) {
                            showAllEntries.toggle()
                        }
                    } label: {
                        Text(showAllEntries
                             ? "Показать топ-10"
                             : "Показать все (\(leaderboardManager.entries.count))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.vertical, 12)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - User Position Card
    
    @ViewBuilder
    private var userPositionCard: some View {
        if let userEntry = leaderboardManager.entries.first(where: { $0.userId == "user" }) {
            GlassCard(cornerRadius: 16, padding: 16, glowColor: accentGreen.opacity(0.3)) {
                HStack {
                    Text("№\(userEntry.rank)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(userEntry.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(userEntry.steps)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(accentGreen)
                }
            }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void
    
    @StateObject private var themeManager = ThemeManager.shared
    
    private var accentGreen: Color { themeManager.accentGreen }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? accentGreen : Color.white.opacity(0.1))
            )
        }
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let position: Int
    let isUser: Bool
    
    @StateObject private var themeManager = ThemeManager.shared
    
    private var accentGold: Color { Color(red: 1.0, green: 0.84, blue: 0.0) }
    
    var body: some View {
        GlassCard(cornerRadius: 16, padding: 16, glowColor: isUser ? themeManager.accentGreen.opacity(0.3) : nil) {
            HStack(spacing: 12) {
                // Позиция
                ZStack {
                    if position <= 3 {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        position == 1 ? accentGold : position == 2 ? .gray : Color(red: 0.8, green: 0.5, blue: 0.2),
                                        position == 1 ? Color(red: 1.0, green: 0.65, blue: 0.0) : .gray.opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "medal.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    } else {
                        Text("\(position)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 36, height: 36)
                    }
                }
                
                // Аватар
                Text(entry.avatarEmoji)
                    .font(.system(size: 32))
                
                // Имя
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.displayName)
                        .font(.system(size: 16, weight: isUser ? .bold : .medium))
                        .foregroundColor(isUser ? themeManager.accentGreen : .white)
                }
                
                Spacer()
                
                // Шаги
                Text("\(entry.steps)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Country Picker Sheet

struct CountryPickerSheet: View {
    @Binding var selectedCountry: String?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    private let countries = [
        "Россия", "США", "Великобритания", "Германия", "Франция",
        "Испания", "Италия", "Канада", "Австралия", "Япония",
        "Китай", "Индия", "Бразилия", "Мексика", "Польша",
        "Нидерланды", "Швеция", "Норвегия", "Финляндия", "Дания"
    ]
    
    private var accentGreen: Color { themeManager.accentGreen }
    private var cardColor: Color { themeManager.cardColor }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(countries, id: \.self) { country in
                            Button {
                                HapticManager.impact(style: .light)
                                selectedCountry = country
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "flag.fill")
                                        .foregroundColor(selectedCountry == country ? accentGreen : .white.opacity(0.5))
                                    
                                    Text(country)
                                        .font(.system(size: 16, weight: selectedCountry == country ? .semibold : .regular))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if selectedCountry == country {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(accentGreen)
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedCountry == country ? accentGreen.opacity(0.2) : cardColor)
                                )
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Выберите страну")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(accentGreen)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - City Picker Sheet

struct CityPickerSheet: View {
    @Binding var selectedCity: String?
    let country: String?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    private var cities: [String] {
        switch country {
        case "Россия":
            return ["Москва", "Санкт-Петербург", "Новосибирск", "Екатеринбург", "Казань", "Нижний Новгород", "Челябинск", "Самара", "Омск", "Ростов-на-Дону"]
        case "США":
            return ["Нью-Йорк", "Лос-Анджелес", "Чикаго", "Хьюстон", "Финикс", "Филадельфия", "Сан-Антонио", "Сан-Диего", "Даллас", "Сан-Хосе"]
        case "Великобритания":
            return ["Лондон", "Манчестер", "Бирмингем", "Ливерпуль", "Лидс", "Шеффилд", "Эдинбург", "Глазго", "Бристоль", "Кардифф"]
        default:
            return ["Москва", "Санкт-Петербург", "Новосибирск", "Екатеринбург", "Казань", "Нью-Йорк", "Лондон", "Берлин", "Париж", "Мадрид", "Рим", "Токио", "Пекин", "Сидней"]
        }
    }
    
    private var accentGreen: Color { themeManager.accentGreen }
    private var cardColor: Color { themeManager.cardColor }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(cities, id: \.self) { city in
                            Button {
                                HapticManager.impact(style: .light)
                                selectedCity = city
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "building.2.fill")
                                        .foregroundColor(selectedCity == city ? accentGreen : .white.opacity(0.5))
                                    
                                    Text(city)
                                        .font(.system(size: 16, weight: selectedCity == city ? .semibold : .regular))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if selectedCity == city {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(accentGreen)
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedCity == city ? accentGreen.opacity(0.2) : cardColor)
                                )
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(country != nil ? "Города \(country!)" : "Выберите город")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(accentGreen)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    PublicLeaderboardView()
}
