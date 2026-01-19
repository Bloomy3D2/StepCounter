//
//  GameView.swift
//  ClashMini
//
//  Красивый игровой экран
//

import SwiftUI
import SpriteKit

struct GameView: View {
    @ObservedObject var gameModel: GameModel
    @State private var scene: GameScene?
    @State private var selectedCardIndex: Int?
    @State private var showPauseMenu = false
    @State private var elixirPulse = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Игровая сцена SpriteKit
                SpriteView(scene: createScene(size: geometry.size))
                    .ignoresSafeArea()
                
                // UI поверх сцены
                VStack(spacing: 0) {
                    // Верхняя панель
                    topHUD
                        .padding(.top, geometry.safeAreaInsets.top + 10)
                    
                    Spacer()
                    
                    // Нижняя панель
                    bottomHUD
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 10)
                }
                
                // Меню паузы
                if showPauseMenu {
                    pauseMenuOverlay
                        .transition(.opacity.combined(with: .scale))
                }
                
                // Экран победы/поражения
                if gameModel.phase == .victory || gameModel.phase == .defeat {
                    gameEndOverlay
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Scene
    
    private func createScene(size: CGSize) -> GameScene {
        if let existingScene = scene {
            return existingScene
        }
        
        let newScene = GameScene(size: size)
        newScene.scaleMode = .resizeFill
        newScene.gameModel = gameModel
        
        DispatchQueue.main.async {
            self.scene = newScene
        }
        
        return newScene
    }
    
    // MARK: - Top HUD
    
    private var topHUD: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top) {
                // Кнопка паузы
                Button {
                    withAnimation(.spring()) {
                        showPauseMenu = true
                        gameModel.pauseGame()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "pause.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                // Центральная панель с коронами
                crownsDisplay
                
                Spacer()
                
                // Таймер
                timerDisplay
            }
            .padding(.horizontal, 15)
            
            // Индикатор двойного эликсира
            if gameModel.isDoubleElixir {
                doubleElixirBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private var crownsDisplay: some View {
        HStack(spacing: 0) {
            // Короны игрока
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    ZStack {
                        Text("👑")
                            .font(.system(size: 22))
                            .opacity(i < gameModel.playerCrowns ? 1 : 0.2)
                            .scaleEffect(i < gameModel.playerCrowns ? 1.15 : 0.9)
                            .shadow(color: i < gameModel.playerCrowns ? Color.yellow.opacity(0.8) : .clear, radius: 5)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                    )
            )
            
            // VS
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 40, height: 40)
                
                Text("VS")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            .offset(x: 0)
            .zIndex(1)
            
            // Короны противника
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    ZStack {
                        Text("👑")
                            .font(.system(size: 22))
                            .opacity(i < gameModel.enemyCrowns ? 1 : 0.2)
                            .scaleEffect(i < gameModel.enemyCrowns ? 1.15 : 0.9)
                            .shadow(color: i < gameModel.enemyCrowns ? Color.yellow.opacity(0.8) : .clear, radius: 5)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.4), Color.red.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.red.opacity(0.5), lineWidth: 2)
                    )
            )
        }
    }
    
    private var timerDisplay: some View {
        let minutes = Int(gameModel.timeRemaining) / 60
        let seconds = Int(gameModel.timeRemaining) % 60
        let isLowTime = gameModel.timeRemaining <= 30
        
        return ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.5))
                .frame(width: 80, height: 50)
            
            RoundedRectangle(cornerRadius: 15)
                .stroke(isLowTime ? Color.red : Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: 80, height: 50)
            
            HStack(spacing: 2) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(isLowTime ? .red : .white.opacity(0.7))
                
                Text(String(format: "%d:%02d", minutes, seconds))
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(isLowTime ? .red : .white)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLowTime)
    }
    
    private var doubleElixirBanner: some View {
        HStack(spacing: 8) {
            Text("⚡")
            Text("ДВОЙНОЙ ЭЛИКСИР")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .tracking(1)
            Text("⚡")
        }
        .foregroundColor(.yellow)
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.8), Color.red.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .shadow(color: Color.orange.opacity(0.5), radius: 10)
    }
    
    // MARK: - Bottom HUD
    
    private var bottomHUD: some View {
        VStack(spacing: 12) {
            // Полоска эликсира
            elixirBar
                .padding(.horizontal, 15)
            
            // Карты
            cardsHand
                .padding(.horizontal, 10)
        }
        .padding(.vertical, 15)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 25,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 25
            )
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.15, green: 0.15, blue: 0.2).opacity(0.95),
                        Color(red: 0.1, green: 0.1, blue: 0.15).opacity(0.98)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 25,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 25
                )
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.5), radius: 20, y: -10)
        )
    }
    
    private var elixirBar: some View {
        HStack(spacing: 12) {
            // Иконка эликсира
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.9, green: 0.4, blue: 1.0),
                                Color(red: 0.6, green: 0.2, blue: 0.8)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 20
                        )
                    )
                    .frame(width: 40, height: 40)
                    .shadow(color: Color.purple.opacity(0.5), radius: 8)
                    .scaleEffect(elixirPulse ? 1.1 : 1.0)
                
                Text("💧")
                    .font(.system(size: 20))
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    elixirPulse = true
                }
            }
            
            // Полоска
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Фон
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.5))
                    
                    // Заполнение
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.9, green: 0.4, blue: 1.0),
                                    Color(red: 0.7, green: 0.3, blue: 0.9),
                                    Color(red: 0.5, green: 0.2, blue: 0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(gameModel.elixir / GameModel.maxElixir))
                        .animation(.spring(response: 0.3), value: gameModel.elixir)
                    
                    // Деления
                    HStack(spacing: 0) {
                        ForEach(1..<10, id: \.self) { i in
                            Spacer()
                            Rectangle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 2)
                        }
                        Spacer()
                    }
                    
                    // Обводка
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.purple.opacity(0.5), lineWidth: 2)
                }
            }
            .frame(height: 28)
            
            // Значение
            Text("\(Int(gameModel.elixir))")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color.purple.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 35)
                .shadow(color: Color.purple.opacity(0.5), radius: 5)
        }
    }
    
    private var cardsHand: some View {
        HStack(spacing: 10) {
            // Следующая карта
            if let nextCard = gameModel.playerDeck.nextCard {
                VStack(spacing: 6) {
                    Text("СЛЕД")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)
                    
                    CardViewBeautiful(
                        card: nextCard,
                        isSelected: false,
                        canPlay: false,
                        isSmall: true
                    ) {}
                }
            }
            
            // Разделитель
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.2), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2, height: 90)
            
            // Карты в руке
            HStack(spacing: 8) {
                ForEach(Array(gameModel.playerDeck.handCards.enumerated()), id: \.element.id) { index, card in
                    CardViewBeautiful(
                        card: card,
                        isSelected: selectedCardIndex == index,
                        canPlay: gameModel.canPlayCard(card),
                        isSmall: false
                    ) {
                        if gameModel.canPlayCard(card) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if selectedCardIndex == index {
                                    selectedCardIndex = nil
                                    scene?.deselectCard()
                                } else {
                                    selectedCardIndex = index
                                    scene?.selectCard(card)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Pause Menu
    
    private var pauseMenuOverlay: some View {
        ZStack {
            // Затемнение
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            // Размытие фона
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .opacity(0.5)
            
            VStack(spacing: 30) {
                // Заголовок
                VStack(spacing: 10) {
                    Text("⏸️")
                        .font(.system(size: 60))
                    
                    Text("ПАУЗА")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .gray],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                
                // Кнопки
                VStack(spacing: 15) {
                    MenuButton(
                        icon: "▶️",
                        title: "ПРОДОЛЖИТЬ",
                        color: .green
                    ) {
                        withAnimation(.spring()) {
                            showPauseMenu = false
                            gameModel.resumeGame()
                        }
                    }
                    
                    MenuButton(
                        icon: "🏠",
                        title: "В МЕНЮ",
                        color: .red
                    ) {
                        withAnimation(.spring()) {
                            showPauseMenu = false
                            scene?.resetGame()
                            gameModel.returnToMenu()
                        }
                    }
                }
            }
            .padding(50)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.white.opacity(0.1), lineWidth: 2)
                    )
            )
            .shadow(color: Color.black.opacity(0.5), radius: 30)
        }
    }
    
    // MARK: - Game End Overlay
    
    private var gameEndOverlay: some View {
        ZStack {
            // Затемнение
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Результат
                VStack(spacing: 15) {
                    if gameModel.phase == .victory {
                        Text("🏆")
                            .font(.system(size: 100))
                            .shadow(color: Color.yellow.opacity(0.8), radius: 30)
                        
                        Text("ПОБЕДА!")
                            .font(.system(size: 50, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.95, blue: 0.5),
                                        Color(red: 1.0, green: 0.7, blue: 0.2)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color.orange.opacity(0.5), radius: 15)
                    } else {
                        Text("💔")
                            .font(.system(size: 100))
                        
                        Text("ПОРАЖЕНИЕ")
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundColor(.red)
                            .shadow(color: Color.red.opacity(0.3), radius: 10)
                    }
                }
                
                // Счёт корон
                HStack(spacing: 40) {
                    CrownResult(
                        title: "ВЫ",
                        crowns: gameModel.playerCrowns,
                        color: .blue
                    )
                    
                    Text(":")
                        .font(.system(size: 48, weight: .black))
                        .foregroundColor(.white)
                    
                    CrownResult(
                        title: "ВРАГ",
                        crowns: gameModel.enemyCrowns,
                        color: .red
                    )
                }
                .padding(.vertical, 25)
                .padding(.horizontal, 40)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                
                // Кнопки
                VStack(spacing: 15) {
                    MenuButton(
                        icon: "🔄",
                        title: "ЕЩЁ РАЗ",
                        color: .green
                    ) {
                        withAnimation(.spring()) {
                            scene?.resetGame()
                            gameModel.startGame()
                        }
                    }
                    
                    MenuButton(
                        icon: "🏠",
                        title: "В МЕНЮ",
                        color: .gray
                    ) {
                        withAnimation(.spring()) {
                            scene?.resetGame()
                            gameModel.returnToMenu()
                        }
                    }
                }
            }
            .padding(40)
        }
    }
}

// MARK: - Beautiful Card View

struct CardViewBeautiful: View {
    let card: Card
    let isSelected: Bool
    let canPlay: Bool
    let isSmall: Bool
    let action: () -> Void
    
    private var width: CGFloat { isSmall ? 55 : 68 }
    private var height: CGFloat { isSmall ? 75 : 95 }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Свечение для выбранной карты
                if isSelected {
                    RoundedRectangle(cornerRadius: isSmall ? 10 : 14)
                        .fill(Color.yellow.opacity(0.3))
                        .frame(width: width + 10, height: height + 10)
                        .blur(radius: 10)
                }
                
                // Основная карта
                ZStack {
                    // Фон карты
                    RoundedRectangle(cornerRadius: isSmall ? 10 : 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(card.type.color),
                                    Color(card.type.color).opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Блик
                    VStack {
                        RoundedRectangle(cornerRadius: isSmall ? 10 : 14)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.35),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .frame(height: height / 2)
                        Spacer()
                    }
                    
                    // Обводка
                    RoundedRectangle(cornerRadius: isSmall ? 10 : 14)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isSelected ? 0.9 : 0.5),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isSelected ? 3 : 2
                        )
                    
                    VStack(spacing: isSmall ? 4 : 8) {
                        // Эмодзи
                        Text(card.emoji)
                            .font(.system(size: isSmall ? 26 : 34))
                            .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                        
                        if !isSmall {
                            // Название
                            Text(card.name)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 1)
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
                                                Color(red: 0.9, green: 0.5, blue: 1.0),
                                                Color(red: 0.6, green: 0.2, blue: 0.9)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: isSmall ? 20 : 26, height: isSmall ? 20 : 26)
                                    .shadow(color: Color.purple.opacity(0.5), radius: 3)
                                
                                Text("\(card.elixirCost)")
                                    .font(.system(size: isSmall ? 11 : 14, weight: .black))
                                    .foregroundColor(.white)
                            }
                            .offset(x: 6, y: -6)
                        }
                        Spacer()
                    }
                    
                    // Затемнение если нельзя сыграть
                    if !canPlay && !isSmall {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.black.opacity(0.5))
                        
                        Image(systemName: "lock.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .frame(width: width, height: height)
            }
        }
        .buttonStyle(CardPressStyle())
        .scaleEffect(isSelected ? 1.12 : 1.0)
        .offset(y: isSelected ? -12 : 0)
        .shadow(
            color: isSelected ? Color.yellow.opacity(0.5) : Color.black.opacity(0.4),
            radius: isSelected ? 15 : 8,
            y: isSelected ? 5 : 4
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
        .disabled(!canPlay && !isSmall)
    }
}

struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Menu Button

struct MenuButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(icon)
                    .font(.system(size: 24))
                
                Text(title)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .tracking(1)
            }
            .foregroundColor(.white)
            .frame(width: 240, height: 60)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    VStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 30)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(color.opacity(0.8), lineWidth: 2)
                }
            )
            .shadow(color: color.opacity(0.4), radius: 10, y: 5)
        }
        .buttonStyle(BounceButtonStyle())
    }
}

// MARK: - Crown Result

struct CrownResult: View {
    let title: String
    let crowns: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
            
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Text("👑")
                        .font(.system(size: 32))
                        .opacity(i < crowns ? 1 : 0.2)
                        .shadow(color: i < crowns ? Color.yellow : .clear, radius: 10)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    GameView(gameModel: {
        let model = GameModel()
        model.startGame()
        return model
    }())
}
