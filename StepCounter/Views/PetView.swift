//
//  PetView.swift
//  StepCounter
//
//  Экран виртуального питомца
//

import SwiftUI

struct PetView: View {
    @EnvironmentObject var petManager: PetManager
    @EnvironmentObject var healthManager: HealthManager
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var showCreatePet = false
    @State private var showPetShop = false
    @State private var showEditName = false
    @State private var petAnimation = false
    @State private var showDeleteConfirmation = false
    @State private var petToDelete: Pet?
    @State private var showPremiumView = false
    
    private var bgColor: Color { themeManager.backgroundColor }
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if petManager.hasPet {
                        // Выбор питомца (всегда показываем, даже для одного, чтобы была кнопка "Новый")
                        petsSelector
                        
                        if let pet = petManager.pet {
                            petCard(pet)
                            moodCard(pet)
                            evolutionCard(pet)
                            statsCard(pet)
                        }
                    } else {
                        noPetView
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 80)
            }
            .background(
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .ignoresSafeArea()
            )
            .navigationTitle("Питомец")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if petManager.pet != nil {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        // Кнопка создания нового питомца
                        Button {
                            showCreatePet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(accentGreen)
                        }
                        
                        Button {
                            showEditName = true
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundColor(accentGreen)
                        }
                        
                        Button {
                            showPetShop = true
                        } label: {
                            Image(systemName: "bag.fill")
                                .foregroundColor(accentGreen)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreatePet) {
                CreatePetSheet()
                    .environmentObject(petManager)
            }
            .sheet(isPresented: $showPetShop) {
                if let pet = petManager.pet {
                    PetShopView(pet: Binding(
                        get: { pet },
                        set: { petManager.pet = $0 }
                    ))
                }
            }
            .sheet(isPresented: $showEditName) {
                if let pet = petManager.pet {
                    EditPetNameView(pet: pet) { newName in
                        petManager.updatePetName(pet, newName: newName)
                    }
                }
            }
            .sheet(isPresented: $showPremiumView) {
                PremiumView()
            }
            .confirmationDialog(
                "Удалить питомца?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                if let pet = petToDelete {
                    Button("Удалить \(pet.name)", role: .destructive) {
                        petManager.deletePet(pet)
                        petToDelete = nil
                    }
                    Button("Отмена", role: .cancel) {
                        petToDelete = nil
                    }
                }
            } message: {
                if let pet = petToDelete {
                    Text("Вы уверены, что хотите удалить \(pet.name)? Это действие нельзя отменить.")
                }
            }
            .onChange(of: healthManager.todaySteps) { _, steps in
                petManager.feedPet(steps: steps)
            }
        }
    }
    
    // MARK: - Pets Selector
    
    private var petsSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(petManager.pets) { pet in
                    let isPremiumLocked = !subscriptionManager.isPremium && pet.type.requiresPremium
                    
                    HStack(spacing: 8) {
                        Button {
                            HapticManager.impact(style: .light)
                            if isPremiumLocked {
                                showPremiumView = true
                            } else {
                                petManager.selectPet(pet)
                            }
                        } label: {
                            VStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            petManager.selectedPetId == pet.id
                                                ? LinearGradient(
                                                    colors: [accentGreen.opacity(0.3), accentGreen.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                                : LinearGradient(
                                                    colors: [cardColor.opacity(0.5), cardColor.opacity(0.3)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                        )
                                        .frame(width: 50, height: 50)
                                    
                                    Text(pet.type.emoji)
                                        .font(.system(size: 28))
                                        .scaleEffect(petManager.selectedPetId == pet.id ? 1.1 : 1.0)
                                        .animation(.spring(response: 0.3), value: petManager.selectedPetId == pet.id)
                                        .opacity(isPremiumLocked ? 0.5 : 1.0)
                                    
                                    // Иконка блокировки для премиум питомцев
                                    if isPremiumLocked {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.yellow)
                                            .offset(x: 18, y: -18)
                                    }
                                }
                                
                                Text(pet.name)
                                    .font(.system(size: 11, weight: petManager.selectedPetId == pet.id ? .bold : .medium))
                                    .foregroundColor(isPremiumLocked ? .white.opacity(0.5) : .white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                petManager.selectedPetId == pet.id
                                                    ? LinearGradient(
                                                        colors: [accentGreen, accentGreen.opacity(0.5)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                    : LinearGradient(
                                                        colors: [Color.clear],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                lineWidth: petManager.selectedPetId == pet.id ? 2.5 : 0
                                            )
                                    )
                                    .shadow(
                                        color: petManager.selectedPetId == pet.id ? accentGreen.opacity(0.4) : .clear,
                                        radius: 12,
                                        x: 0,
                                        y: 6
                                    )
                            )
                        }
                        
                        // Кнопка удаления (показываем только если питомцев больше одного)
                        if petManager.pets.count > 1 {
                            Button {
                                HapticManager.impact(style: .medium)
                                petToDelete = pet
                                showDeleteConfirmation = true
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.red, .red.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                        }
                    }
                }
                
                // Кнопка добавления
                Button {
                    HapticManager.impact(style: .light)
                    showCreatePet = true
                } label: {
                            VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [accentGreen.opacity(0.2), accentGreen.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [accentGreen, accentGreen.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        Text("Новый")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        LinearGradient(
                                            colors: [accentGreen.opacity(0.5), accentGreen.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [6, 6])
                                    )
                            )
                    )
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Pet Card
    
    private func petCard(_ pet: Pet) -> some View {
        ZStack {
            // Декоративные элементы фона
            ZStack {
                // Внешнее свечение
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                pet.mood.color.opacity(0.3),
                                pet.mood.color.opacity(0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 60,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 30)
                    .offset(y: -30)
                
                // Внутреннее свечение
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                accentGreen.opacity(0.2),
                                accentGreen.opacity(0.05),
                                .clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)
                    .blur(radius: 15)
            }
            
            GlassCard(cornerRadius: 20, padding: 20, glowColor: pet.mood.color.opacity(0.4)) {
                VStack(spacing: 16) {
                    // Питомец с визуализацией
                    ZStack {
                        // Внешний круг с градиентом
                        Circle()
                            .fill(
                                AngularGradient(
                                    colors: [
                                        pet.mood.color.opacity(0.3),
                                        accentGreen.opacity(0.2),
                                        pet.mood.color.opacity(0.3),
                                        accentGreen.opacity(0.2)
                                    ],
                                    center: .center,
                                    startAngle: .degrees(0),
                                    endAngle: .degrees(360)
                                )
                            )
                            .frame(width: min(pet.evolution.size + 60, 180), height: min(pet.evolution.size + 60, 180))
                            .blur(radius: 15)
                        
                        // Средний круг
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        pet.mood.color.opacity(0.2),
                                        pet.mood.color.opacity(0.05),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 60
                                )
                            )
                            .frame(width: min(pet.evolution.size + 50, 160), height: min(pet.evolution.size + 50, 160))
                        
                        // Питомец с аксессуарами
                        PetVisualization(
                            pet: pet,
                            accessories: allAccessories(for: pet),
                            size: min(pet.evolution.size, 120)
                        )
                        .scaleEffect(petAnimation ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: petAnimation)
                    }
                    .frame(height: 140)
                    .onAppear {
                        petAnimation = true
                    }
                    
                    // Имя и звание
                    VStack(spacing: 6) {
                        Text(pet.name)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(accentGreen)
                            Text(pet.evolution.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(accentGreen)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(accentGreen.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(accentGreen.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    // Настроение
                    HStack(spacing: 8) {
                        Text(pet.mood.emoji)
                            .font(.system(size: 20))
                        
                        Text(pet.mood.message)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        pet.mood.color.opacity(0.3),
                                        pet.mood.color.opacity(0.15)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(pet.mood.color.opacity(0.4), lineWidth: 1.5)
                            )
                    )
                    .shadow(color: pet.mood.color.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Mood Card
    
    private func moodCard(_ pet: Pet) -> some View {
        GlassCard(cornerRadius: 20, padding: 16, glowColor: accentGreen.opacity(0.3)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(accentGreen)
                    
                    Text("Шаги сегодня")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                HStack(alignment: .center, spacing: 12) {
                    // Большое значение
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(pet.todaySteps)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("шагов")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Индикаторы настроения (компактные)
                    VStack(alignment: .trailing, spacing: 4) {
                        EnhancedMoodIndicator(emoji: "😴", label: "0", active: pet.todaySteps < 1000, color: .gray)
                        EnhancedMoodIndicator(emoji: "😢", label: "1k", active: pet.todaySteps >= 1000 && pet.todaySteps < 5000, color: .red)
                        EnhancedMoodIndicator(emoji: "😐", label: "5k", active: pet.todaySteps >= 5000 && pet.todaySteps < 10000, color: .orange)
                        EnhancedMoodIndicator(emoji: "😊", label: "10k", active: pet.todaySteps >= 10000 && pet.todaySteps < 15000, color: .yellow)
                        EnhancedMoodIndicator(emoji: "🤩", label: "15k+", active: pet.todaySteps >= 15000, color: accentGreen)
                    }
                }
            }
        }
    }
    
    private func moodIndicator(emoji: String, label: String, active: Bool) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(active ? .white : .white.opacity(0.3))
            Text(emoji)
                .font(.system(size: 14))
                .opacity(active ? 1 : 0.3)
        }
    }
    
    // MARK: - Enhanced Mood Indicator
    
        struct EnhancedMoodIndicator: View {
        let emoji: String
        let label: String
        let active: Bool
        let color: Color
        
        var body: some View {
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.system(size: 14))
                    .scaleEffect(active ? 1.1 : 0.85)
                    .animation(.spring(response: 0.3), value: active)
                
                Text(label)
                    .font(.system(size: 10, weight: active ? .bold : .regular))
                    .foregroundColor(active ? .white : .white.opacity(0.4))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(active ? color.opacity(0.2) : Color.clear)
                    .overlay(
                        Capsule()
                            .stroke(active ? color.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            )
            .shadow(color: active ? color.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Evolution Card
    
    private func evolutionCard(_ pet: Pet) -> some View {
        GlassCard(cornerRadius: 20, padding: 20, glowColor: accentGreen.opacity(0.4)) {
            VStack(alignment: .leading, spacing: 16) {
                // Заголовок с XP
                HStack {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [accentGreen.opacity(0.3), accentGreen.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(accentGreen)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Эволюция")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            if let next = pet.nextEvolution {
                                Text("→ \(next.name)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(accentGreen.opacity(0.8))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // XP бейдж
                    VStack(spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.yellow)
                            Text("\(pet.totalXP)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        Text("XP")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [accentGreen.opacity(0.2), accentGreen.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [accentGreen.opacity(0.5), accentGreen.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                    )
                    .shadow(color: accentGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                // Улучшенный прогресс-бар
                VStack(spacing: 12) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Фон с текстурой
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.gray.opacity(0.25),
                                            Color.gray.opacity(0.15)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 16)
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                            
                            // Прогресс с анимированным градиентом
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            accentGreen,
                                            .cyan,
                                            accentGreen.opacity(0.8),
                                            accentGreen
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(8, geo.size.width * pet.evolutionProgress), height: 16)
                                .shadow(color: accentGreen.opacity(0.6), radius: 8, x: 0, y: 0)
                                .overlay(
                                    // Анимированный блеск
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    .white.opacity(0.4),
                                                    .white.opacity(0.0),
                                                    .white.opacity(0.2)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: max(8, geo.size.width * pet.evolutionProgress), height: 16)
                                )
                            
                            // Процент прогресса (если есть место)
                            if pet.evolutionProgress > 0.3 {
                                HStack {
                                    Spacer()
                                    Text("\(Int(pet.evolutionProgress * 100))%")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.trailing, 6)
                                }
                            }
                        }
                    }
                    .frame(height: 16)
                    
                    // Информация о следующей эволюции
                    if let next = pet.nextEvolution, let xpNeeded = pet.xpToNextEvolution {
                        HStack(spacing: 12) {
                            // Текущая стадия
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(accentGreen.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                Text(pet.evolution.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            // Стрелка
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(accentGreen.opacity(0.6))
                            
                            // Следующая стадия
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(accentGreen)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: accentGreen.opacity(0.6), radius: 4, x: 0, y: 0)
                                Text(next.name)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(accentGreen)
                            }
                            
                            Spacer()
                            
                            // XP до следующей стадии
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.yellow)
                                Text("\(xpNeeded)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                Text("XP")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.yellow.opacity(0.15))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    } else {
                        // Максимальный уровень
                        HStack {
                            Spacer()
                            HStack(spacing: 8) {
                                Text("🎉")
                                    .font(.system(size: 20))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Максимальный уровень!")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(accentGreen)
                                    Text("Питомец достиг пика эволюции")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Улучшенные стадии эволюции
                VStack(spacing: 8) {
                    HStack {
                        Text("Стадии эволюции")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(PetEvolution.allCases, id: \.self) { evo in
                            VStack(spacing: 6) {
                                ZStack {
                                    // Фон круга
                                    Circle()
                                        .fill(
                                            pet.evolution == evo || pet.totalXP >= evo.requiredXP
                                                ? LinearGradient(
                                                    colors: [accentGreen.opacity(0.4), accentGreen.opacity(0.2)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                                : LinearGradient(
                                                    colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                        )
                                        .frame(width: 24, height: 24)
                                        .shadow(
                                            color: (pet.evolution == evo || pet.totalXP >= evo.requiredXP) ? accentGreen.opacity(0.4) : .clear,
                                            radius: 6,
                                            x: 0,
                                            y: 3
                                        )
                                    
                                    // Иконка или индикатор
                                    if pet.evolution == evo {
                                        Circle()
                                            .stroke(accentGreen, lineWidth: 2.5)
                                            .frame(width: 28, height: 28)
                                        
                                        Circle()
                                            .fill(accentGreen)
                                            .frame(width: 10, height: 10)
                                            .shadow(color: accentGreen.opacity(0.8), radius: 4, x: 0, y: 0)
                                    } else if pet.totalXP >= evo.requiredXP {
                                        Circle()
                                            .fill(accentGreen.opacity(0.6))
                                            .frame(width: 8, height: 8)
                                    } else {
                                        Circle()
                                            .fill(Color.gray.opacity(0.4))
                                            .frame(width: 6, height: 6)
                                    }
                                }
                                
                                // Название стадии
                                Text(evo.name)
                                    .font(.system(size: 9, weight: pet.evolution == evo ? .bold : .medium))
                                    .foregroundColor(
                                        pet.evolution == evo || pet.totalXP >= evo.requiredXP
                                            ? .white
                                            : .white.opacity(0.5)
                                    )
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                // XP требования
                                Text("\(evo.requiredXP)")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(
                                        pet.totalXP >= evo.requiredXP
                                            ? accentGreen.opacity(0.8)
                                            : .white.opacity(0.4)
                                    )
                            }
                            
                            // Линия между стадиями
                            if evo != PetEvolution.allCases.last {
                                Spacer()
                                Capsule()
                                    .fill(
                                        pet.totalXP >= evo.requiredXP
                                            ? LinearGradient(
                                                colors: [accentGreen.opacity(0.6), accentGreen.opacity(0.3)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                            : LinearGradient(
                                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                    )
                                    .frame(height: 2)
                                    .shadow(
                                        color: pet.totalXP >= evo.requiredXP ? accentGreen.opacity(0.3) : .clear,
                                        radius: 2,
                                        x: 0,
                                        y: 0
                                    )
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Stats Card
    
    private func statsCard(_ pet: Pet) -> some View {
        GlassCard(cornerRadius: 20, padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(accentGreen)
                    
                    Text("Статистика питомца")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    EnhancedStatMiniCard(
                        icon: "calendar",
                        value: "\(pet.daysOld)",
                        label: "Дней вместе",
                        color: .blue,
                        gradient: LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    
                    EnhancedStatMiniCard(
                        icon: "star.fill",
                        value: "\(pet.totalXP)",
                        label: "Всего XP",
                        color: .yellow,
                        gradient: LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
            }
        }
    }
    
    // MARK: - No Pet View
    
    private var noPetView: some View {
        VStack(spacing: 32) {
            // Анимированная иконка
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                accentGreen.opacity(0.3),
                                accentGreen.opacity(0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                
                Text("🐾")
                    .font(.system(size: 100))
                    .scaleEffect(petAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: petAnimation)
            }
            .onAppear {
                petAnimation = true
            }
            
            VStack(spacing: 12) {
                Text("У вас ещё нет питомца!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Создайте виртуального друга, который будет гулять с вами и расти от ваших шагов!")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 20)
            
            Button {
                HapticManager.impact(style: .medium)
                showCreatePet = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Создать питомца")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [accentGreen, accentGreen.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: accentGreen.opacity(0.5), radius: 15, x: 0, y: 8)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper
    
    private func allAccessories(for pet: Pet) -> [PetAccessory] {
        return AccessoryType.allCases.map { type in
            var accessory = PetAccessory(type: type)
            accessory.isUnlocked = pet.totalXP >= type.unlockRequirement
            return accessory
        }
    }
}

// MARK: - Create Pet Sheet

struct CreatePetSheet: View {
    @EnvironmentObject var petManager: PetManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @FocusState private var isNameFieldFocused: Bool
    
    @State private var petName = ""
    @State private var selectedType: PetType = .poodle
    @State private var showPremiumAlert = false
    @State private var showMaxPetsAlert = false
    @State private var showPremiumView = false
    
    private var bgColor: Color { themeManager.backgroundColor }
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Выбор типа
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Выберите питомца")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(PetType.allCases, id: \.self) { type in
                                let isLocked = !subscriptionManager.isPremium && type.requiresPremium
                                
                                Button {
                                    if isLocked {
                                        showPremiumAlert = true
                                    } else {
                                    selectedType = type
                                    }
                                } label: {
                                    VStack(spacing: 8) {
                                        Text(type.emoji)
                                            .font(.system(size: 40))
                                            .opacity(isLocked ? 0.5 : 1.0)
                                        Text(type.name)
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                        
                                        if isLocked {
                                            Image(systemName: "lock.fill")
                                                .font(.system(size: 10))
                                                .foregroundColor(.yellow)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(cardColor)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(selectedType == type ? accentGreen : Color.clear, lineWidth: 2)
                                            )
                                    )
                                    .opacity(isLocked ? 0.6 : 1.0)
                                }
                            }
                        }
                    }
                    
                    // Имя
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Имя питомца")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        TextField("Введите имя", text: $petName)
                            .padding()
                            .background(cardColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundColor(.white)
                            .focused($isNameFieldFocused)
                            .submitLabel(.done)
                    }
                    
                    // Превью
                    VStack(spacing: 12) {
                        Text(selectedType.emoji)
                            .font(.system(size: 80))
                        
                        Text(petName.isEmpty ? selectedType.name : petName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(32)
                    .background(RoundedRectangle(cornerRadius: 24).fill(cardColor))
                    
                    // Кнопка создания
                    Button {
                        // Проверяем, не заблокирован ли выбранный тип
                        if selectedType.requiresPremium && !subscriptionManager.isPremium {
                            showPremiumAlert = true
                            return
                        }
                        
                        let name = petName.isEmpty ? selectedType.name : petName
                        let success = petManager.createPet(name: name, type: selectedType)
                        if success {
                            dismiss()
                        } else {
                            showMaxPetsAlert = true
                        }
                    } label: {
                        Text("Создать питомца")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(accentGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(20)
            }
            .background(
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .ignoresSafeArea()
            )
            .navigationTitle("Новый питомец")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(accentGreen)
                }
            }
            .alert("Требуется Premium", isPresented: $showPremiumAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Оформить Premium") {
                    showPremiumView = true
                }
            } message: {
                Text("Этот тип питомца доступен только для Premium пользователей. Оформите Premium, чтобы разблокировать всех питомцев!")
            }
            .sheet(isPresented: $showPremiumView) {
                PremiumView()
            }
            .alert("Лимит питомцев", isPresented: $showMaxPetsAlert) {
                Button("OK") { }
            } message: {
                Text("У вас уже есть питомец. Для создания нескольких питомцев оформите Premium.")
            }
            .onAppear {
                // Автоматически фокусируем поле ввода имени после небольшой задержки
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isNameFieldFocused = true
                }
            }
        }
    }
}

// MARK: - Edit Pet Name View

struct EditPetNameView: View {
    let pet: Pet
    let onSave: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @State private var newName: String
    
    private var bgColor: Color { themeManager.backgroundColor }
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    
    init(pet: Pet, onSave: @escaping (String) -> Void) {
        self.pet = pet
        self.onSave = onSave
        self._newName = State(initialValue: pet.name)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Text("Изменить имя")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    TextField("Имя питомца", text: $newName)
                        .padding()
                        .background(cardColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(.white)
                        .submitLabel(.done)
                    
                    Button {
                        onSave(newName.isEmpty ? pet.type.name : newName)
                        dismiss()
                    } label: {
                        Text("Сохранить")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(accentGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 24).fill(cardColor))
                
                Spacer()
            }
            .padding(20)
            .background(
                AnimatedGradientBackground(theme: themeManager.currentTheme)
                    .ignoresSafeArea()
            )
            .navigationTitle("Редактировать имя")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(accentGreen)
                }
            }
        }
    }
}

struct StatMiniCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        GlassCard(cornerRadius: 12, padding: 12, glowColor: color.opacity(0.3)) {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Enhanced Stat Mini Card

struct EnhancedStatMiniCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let gradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 8) {
            // Иконка в круге
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(gradient)
            }
            
            // Значение
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.4),
                                    color.opacity(0.1),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    PetView()
        .environmentObject(PetManager())
        .environmentObject(HealthManager())
}
