//
//  CardView.swift
//  ClashMini
//
//  Визуальное представление карты
//

import SwiftUI

struct CardView: View {
    let card: Card
    let isSelected: Bool
    let canPlay: Bool
    let isSmall: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    private var cardWidth: CGFloat { isSmall ? 50 : 70 }
    private var cardHeight: CGFloat { isSmall ? 70 : 95 }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Фон карты
                RoundedRectangle(cornerRadius: isSmall ? 8 : 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(card.type.color).opacity(canPlay ? 1 : 0.5),
                                Color(card.type.color).opacity(canPlay ? 0.7 : 0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: isSmall ? 8 : 12)
                            .stroke(
                                isSelected ? Color.yellow : Color.white.opacity(0.3),
                                lineWidth: isSelected ? 3 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? Color.yellow.opacity(0.5) : Color.black.opacity(0.3),
                        radius: isSelected ? 10 : 5
                    )
                
                VStack(spacing: isSmall ? 4 : 8) {
                    // Эмодзи юнита
                    Text(card.emoji)
                        .font(.system(size: isSmall ? 24 : 32))
                    
                    if !isSmall {
                        // Название
                        Text(card.name)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                
                // Стоимость эликсира
                VStack {
                    HStack {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.7, green: 0.3, blue: 0.9),
                                            Color(red: 0.5, green: 0.2, blue: 0.7)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: isSmall ? 18 : 24, height: isSmall ? 18 : 24)
                            
                            Text("\(card.elixirCost)")
                                .font(.system(size: isSmall ? 10 : 14, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .offset(x: 5, y: -5)
                    }
                    
                    Spacer()
                }
                
                // Затемнение если нельзя сыграть
                if !canPlay {
                    RoundedRectangle(cornerRadius: isSmall ? 8 : 12)
                        .fill(Color.black.opacity(0.4))
                }
            }
            .frame(width: cardWidth, height: cardHeight)
        }
        .buttonStyle(CardButtonStyle())
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .offset(y: isSelected ? -10 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        .disabled(!canPlay && !isSmall)
    }
}

// MARK: - Card Button Style

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Card Detail View (для просмотра колоды)

struct CardDetailView: View {
    let cardType: CardType
    
    var body: some View {
        VStack(spacing: 15) {
            // Заголовок с эмодзи
            HStack {
                Text(cardType.emoji)
                    .font(.system(size: 50))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(cardType.rawValue)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 5) {
                        Image(systemName: "drop.fill")
                            .foregroundColor(Color(red: 0.7, green: 0.3, blue: 0.9))
                        Text("\(cardType.elixirCost)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.7, green: 0.3, blue: 0.9))
                    }
                }
                
                Spacer()
            }
            
            // Описание
            Text(cardType.description)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Характеристики
            HStack(spacing: 20) {
                StatView(icon: "❤️", label: "HP", value: "\(cardType.health)")
                StatView(icon: "⚔️", label: "DMG", value: "\(cardType.damage)")
                StatView(icon: "⚡", label: "SPD", value: String(format: "%.1f", cardType.attackSpeed))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(cardType.color).opacity(0.3),
                            Color(red: 0.1, green: 0.1, blue: 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(cardType.color).opacity(0.5), lineWidth: 2)
                )
        )
    }
}

struct StatView: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 5) {
            Text(icon)
                .font(.system(size: 20))
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        VStack(spacing: 30) {
            HStack(spacing: 15) {
                CardView(
                    card: Card(type: .knight),
                    isSelected: false,
                    canPlay: true,
                    isSmall: false
                ) {}
                
                CardView(
                    card: Card(type: .archer),
                    isSelected: true,
                    canPlay: true,
                    isSmall: false
                ) {}
                
                CardView(
                    card: Card(type: .giant),
                    isSelected: false,
                    canPlay: false,
                    isSmall: false
                ) {}
            }
            
            CardDetailView(cardType: .dragon)
                .padding(.horizontal)
        }
    }
}
