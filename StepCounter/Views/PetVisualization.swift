//
//  PetVisualization.swift
//  StepCounter
//
//  Визуализация питомца с аксессуарами
//

import SwiftUI

struct PetVisualization: View {
    let pet: Pet
    let accessories: [PetAccessory]
    let size: CGFloat
    
    @State private var bounce = false
    
    private var equippedAccessories: [PetAccessory] {
        accessories.filter { $0.isUnlocked && pet.accessories.contains($0.type.rawValue) }
    }
    
    var body: some View {
        ZStack {
            // Тело питомца (основной эмодзи/изображение)
            petBody
            
            // Аксессуары поверх (масштабируются вместе с питомцем через общий scaleEffect)
            ForEach(equippedAccessories) { accessory in
                accessoryView(accessory)
            }
        }
        .scaleEffect(bounce ? 1.05 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                bounce = true
            }
        }
    }
    
    // MARK: - Pet Body
    
    private var petBody: some View {
        ZStack {
            // Тень под питомцем
            Ellipse()
                .fill(Color.black.opacity(0.3))
                .frame(width: size * 0.9, height: size * 0.3)
                .offset(y: size * 0.5)
                .blur(radius: 8)
            
            // Эмодзи питомца (просто, без дорисовок)
            Text(pet.type.emoji)
                .font(.system(size: size * 0.9))
                .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
        }
    }
    
    // MARK: - Accessories
    
    private func accessoryView(_ accessory: PetAccessory) -> some View {
        Group {
            switch accessory.type.category {
            case .head:
                headAccessory(accessory)
            case .neck:
                neckAccessory(accessory)
            case .chest:
                chestAccessory(accessory)
            }
        }
    }
    
    private func headAccessory(_ accessory: PetAccessory) -> some View {
        // Головные уборы позиционируются на голове питомца
        // Эмодзи питомца имеет размер size * 0.9, голова находится в верхней части
        // Разные аксессуары требуют разного позиционирования
        let (emojiSize, yOffset) = headAccessoryPosition(for: accessory.type)
        return Text(accessory.type.emoji)
            .font(.system(size: emojiSize))
            .offset(y: yOffset)
    }
    
    private func headAccessoryPosition(for type: AccessoryType) -> (size: CGFloat, offset: CGFloat) {
        // Размеры и позиции для разных головных аксессуаров
        switch type {
        case .cap, .beanie:
            // Кепка и шапка - на макушке
            return (size * 0.35, -size * 0.38)
        case .crown:
            // Корона - немного выше, чтобы сидеть на голове
            return (size * 0.4, -size * 0.42)
        case .sunglasses:
            // Очки - на уровне глаз (чуть ниже других головных уборов)
            return (size * 0.3, -size * 0.25)
        case .bandana:
            // Бандана - на голове, но ниже кепки
            return (size * 0.35, -size * 0.32)
        case .partyHat:
            // Праздничная шляпа - на макушке, яркая
            return (size * 0.38, -size * 0.40)
        case .wizardHat:
            // Шляпа мага - высокая, на голове
            return (size * 0.42, -size * 0.45)
        default:
            return (size * 0.35, -size * 0.38)
        }
    }
    
    private func neckAccessory(_ accessory: PetAccessory) -> some View {
        // Шейные аксессуары позиционируются в области шеи
        // Шея находится примерно в середине эмодзи, чуть выше центра
        let (emojiSize, yOffset) = neckAccessoryPosition(for: accessory.type)
        return Text(accessory.type.emoji)
            .font(.system(size: emojiSize))
            .offset(y: yOffset)
    }
    
    private func neckAccessoryPosition(for type: AccessoryType) -> (size: CGFloat, offset: CGFloat) {
        switch type {
        case .scarf:
            // Шарф - длиннее, позиционируется в области шеи
            return (size * 0.4, -size * 0.05)
        case .bowtie:
            // Бабочка - на шее, чуть выше центра
            return (size * 0.3, -size * 0.08)
        case .tie:
            // Галстук - на шее, может быть длиннее
            return (size * 0.35, -size * 0.05)
        case .necklace:
            // Ожерелье - на шее, блестящее
            return (size * 0.32, -size * 0.06)
        default:
            return (size * 0.35, -size * 0.05)
        }
    }
    
    private func chestAccessory(_ accessory: PetAccessory) -> some View {
        // Нагрудные аксессуары позиционируются в области груди
        // Грудь находится в нижней части эмодзи, чуть ниже центра
        let (emojiSize, yOffset, xOffset) = chestAccessoryPosition(for: accessory.type)
        return Text(accessory.type.emoji)
            .font(.system(size: emojiSize))
            .offset(x: xOffset, y: yOffset)
    }
    
    private func chestAccessoryPosition(for type: AccessoryType) -> (size: CGFloat, yOffset: CGFloat, xOffset: CGFloat) {
        switch type {
        case .medal:
            // Медаль - на груди, слева
            return (size * 0.28, size * 0.12, -size * 0.15)
        case .badge:
            // Значок - на груди, справа
            return (size * 0.25, size * 0.15, size * 0.15)
        case .heartPin:
            // Брошь-сердечко - на груди, по центру
            return (size * 0.26, size * 0.13, 0)
        default:
            return (size * 0.3, size * 0.15, 0)
        }
    }
}

// MARK: - Pet Shop View

struct PetShopView: View {
    @EnvironmentObject var petManager: PetManager
    @Binding var pet: Pet
    
    @State private var availableAccessories: [PetAccessory] = []
    
    @StateObject private var themeManager = ThemeManager.shared
    
    private var bgColor: Color { themeManager.backgroundColor }
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Питомец в одежде
                    previewSection
                    
                    // Доступные аксессуары
                    accessoriesSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(bgColor.ignoresSafeArea())
            .navigationTitle("Гардероб питомца")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadAccessories()
            }
        }
    }
    
    private var previewSection: some View {
        VStack(spacing: 16) {
            Text("Как вы будете выглядеть")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            PetVisualization(
                pet: pet,
                accessories: availableAccessories,
                size: 120
            )
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 20).fill(cardColor))
    }
    
    private var accessoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Аксессуары")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(availableAccessories) { accessory in
                    AccessoryCard(
                        accessory: accessory,
                        petXP: pet.totalXP,
                        isEquipped: pet.accessories.contains(accessory.type.rawValue)
                    ) {
                        toggleAccessory(accessory)
                    }
                }
            }
        }
    }
    
    private func loadAccessories() {
        let subscriptionManager = SubscriptionManager.shared
        let hasExclusiveAccessories = subscriptionManager.hasAccess(to: .exclusiveAccessories)
        
        availableAccessories = AccessoryType.allCases.map { type in
            let accessory = PetAccessory(type: type)
            var newAccessory = accessory
            
            // Проверяем Premium для эксклюзивных аксессуаров
            if type.isPremium && !hasExclusiveAccessories {
                newAccessory.isUnlocked = false // Всегда заблокированы для free
            } else {
                newAccessory.isUnlocked = pet.totalXP >= type.unlockRequirement
            }
            
            return newAccessory
        }
    }
    
    private func toggleAccessory(_ accessory: PetAccessory) {
        guard accessory.isUnlocked else { return }
        
        var updatedPet = pet
        
        if updatedPet.accessories.contains(accessory.type.rawValue) {
            updatedPet.accessories.removeAll { $0 == accessory.type.rawValue }
        } else {
            // Снимаем другие аксессуары того же типа
            let sameCategory = AccessoryType.allCases.filter { $0.category == accessory.type.category }
            updatedPet.accessories.removeAll { accId in
                sameCategory.contains { $0.rawValue == accId }
            }
            updatedPet.accessories.append(accessory.type.rawValue)
        }
        
        pet = updatedPet
        petManager.pet = updatedPet
        petManager.savePet()
    }
}

struct AccessoryCard: View {
    let accessory: PetAccessory
    let petXP: Int
    let isEquipped: Bool
    let onTap: () -> Void
    
    @StateObject private var themeManager = ThemeManager.shared
    private var cardColor: Color { themeManager.cardColor }
    private var accentGreen: Color { themeManager.accentGreen }
    
    private var rarityColor: Color {
        accessory.type.rarity.color
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // Иконка аксессуара с градиентом редкости
                ZStack {
                    // Фон с цветом редкости
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: accessory.isUnlocked ? [
                                    rarityColor.opacity(0.3),
                                    rarityColor.opacity(0.1)
                                ] : [
                                    Color.gray.opacity(0.1),
                                    Color.gray.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    if accessory.isUnlocked {
                        Text(accessory.type.emoji)
                            .font(.system(size: 36))
                            .shadow(color: rarityColor.opacity(0.5), radius: 4)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    
                    // Индикатор надетого
                    if isEquipped {
                        Circle()
                            .stroke(accentGreen, lineWidth: 3)
                            .frame(width: 68, height: 68)
                    }
                    
                    // Блеск для премиум и легендарных
                    if accessory.type.isPremium || accessory.type.rarity == .legendary {
                        Circle()
                            .stroke(rarityColor.opacity(0.6), lineWidth: 1.5)
                            .frame(width: 66, height: 66)
                    }
                }
                
                // Название
                Text(accessory.type.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(accessory.isUnlocked ? .white : .white.opacity(0.4))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // Описание (только для разблокированных)
                if accessory.isUnlocked {
                    Text(accessory.type.description)
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                
                // Индикатор разблокировки
                if !accessory.isUnlocked {
                    if accessory.type.isPremium {
                        HStack(spacing: 3) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 7))
                            Text("Premium")
                                .font(.system(size: 8, weight: .medium))
                        }
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.yellow.opacity(0.2))
                        )
                    } else {
                        Text("\(formatNumber(accessory.type.unlockRequirement)) XP")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                } else {
                    // Показываем редкость для разблокированных
                    Text(accessory.type.rarity.name)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(rarityColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(rarityColor.opacity(0.2))
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                cardColor,
                                cardColor.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isEquipped ? accentGreen :
                                (accessory.isUnlocked ? rarityColor.opacity(0.3) : Color.clear),
                                lineWidth: isEquipped ? 2.5 : 1
                            )
                    )
                    .shadow(
                        color: isEquipped ? accentGreen.opacity(0.3) : Color.black.opacity(0.2),
                        radius: isEquipped ? 8 : 4
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

#Preview {
    PetVisualization(
        pet: Pet(name: "Пудель", type: .poodle),
        accessories: [],
        size: 100
    )
}
