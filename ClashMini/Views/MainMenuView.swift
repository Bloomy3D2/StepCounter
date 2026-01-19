//
//  MainMenuView.swift
//  ClashMini
//
//  Красивое главное меню игры
//

import SwiftUI

struct MainMenuView: View {
    @ObservedObject var gameModel: GameModel
    @ObservedObject var shopManager = ShopManager.shared
    @State private var titleScale: CGFloat = 0.8
    @State private var titleOpacity: Double = 0
    @State private var buttonsOffset: CGFloat = 150
    @State private var crownRotation: Double = -10
    @State private var crownScale: CGFloat = 0
    @State private var cardsAppeared = false
    @State private var glowOpacity: Double = 0.3
    @State private var backgroundHue: Double = 0
    @State private var particlesVisible = false
    @State private var showShop = false
    @State private var showBoosterSelection = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Анимированный градиентный фон
                animatedBackground
                
                // Частицы на фоне
                if particlesVisible {
                    ParticlesView()
                }
                
                // Декоративные башни по бокам
                decorativeTowers(geometry: geometry)
                
                // Основной контент
                VStack(spacing: 0) {
                    // Верхняя панель с валютой и магазином
                    topBar
                    
                    Spacer()
                        .frame(height: geometry.size.height * 0.02)
                    
                    // Логотип с короной
                    logoSection
                    
                    Spacer()
                        .frame(height: 30)
                    
                    // Название игры
                    titleSection
                    
                    Spacer()
                    
                    // Главная кнопка ИГРАТЬ
                    playButton
                    
                    Spacer()
                        .frame(height: 30)
                    
                    // Карточки юнитов
                    cardsPreview
                    
                    Spacer()
                        .frame(height: geometry.size.height * 0.05)
                    
                    // Футер
                    footerSection
                    
                    Spacer()
                        .frame(height: 20)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimations()
        }
        .sheet(isPresented: $showShop) {
            ShopView()
        }
        .sheet(isPresented: $showBoosterSelection) {
            BoosterSelectionView(gameModel: gameModel)
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            // Валюта
            HStack(spacing: 12) {
                // Золото
                HStack(spacing: 4) {
                    Text("🪙")
                        .font(.title3)
                    Text("\(shopManager.gold)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.yellow.opacity(0.15))
                        .overlay(
                            Capsule()
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                )
                
                // Гемы
                HStack(spacing: 4) {
                    Text("💎")
                        .font(.title3)
                    Text("\(shopManager.gems)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.cyan)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.cyan.opacity(0.15))
                        .overlay(
                            Capsule()
                                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            Spacer()
            
            // Кнопка магазина
            Button {
                showShop = true
            } label: {
                HStack(spacing: 6) {
                    Text("🛒")
                        .font(.title2)
                    Text("МАГАЗИН")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: .orange.opacity(0.5), radius: 8)
            }
            .buttonStyle(BounceButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
    }
    
    // MARK: - Animated Background
    
    private var animatedBackground: some View {
        ZStack {
            // Основной градиент
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.18),
                    Color(red: 0.12, green: 0.06, blue: 0.20),
                    Color(red: 0.05, green: 0.05, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Светящиеся круги
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.purple.opacity(0.4), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: -100, y: -200)
                .blur(radius: 60)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.orange.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: 150, y: 300)
                .blur(radius: 50)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.blue.opacity(0.25), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .offset(x: 100, y: -100)
                .blur(radius: 70)
        }
    }
    
    // MARK: - Decorative Towers
    
    private func decorativeTowers(geometry: GeometryProxy) -> some View {
        ZStack {
            // Левая башня
            VStack {
                Spacer()
                Text("🏰")
                    .font(.system(size: 80))
                    .opacity(0.15)
                    .rotationEffect(.degrees(-15))
                    .offset(x: -geometry.size.width * 0.35)
            }
            
            // Правая башня
            VStack {
                Spacer()
                Text("🏰")
                    .font(.system(size: 80))
                    .opacity(0.15)
                    .rotationEffect(.degrees(15))
                    .scaleEffect(x: -1, y: 1)
                    .offset(x: geometry.size.width * 0.35)
            }
            
            // Мечи вверху
            VStack {
                HStack(spacing: -30) {
                    Text("⚔️")
                        .font(.system(size: 50))
                        .rotationEffect(.degrees(-30))
                    Text("⚔️")
                        .font(.system(size: 50))
                        .rotationEffect(.degrees(30))
                        .scaleEffect(x: -1)
                }
                .opacity(0.1)
                .offset(y: 60)
                Spacer()
            }
        }
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        ZStack {
            // Свечение за короной
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.85, blue: 0.3).opacity(glowOpacity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
            
            // Корона
            Text("👑")
                .font(.system(size: 100))
                .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.8), radius: 20)
                .shadow(color: Color(red: 1.0, green: 0.6, blue: 0.1).opacity(0.5), radius: 40)
                .scaleEffect(crownScale)
                .rotationEffect(.degrees(crownRotation))
        }
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(spacing: 8) {
            // CLASH
            Text("CLASH")
                .font(.system(size: 64, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.95, blue: 0.6),
                            Color(red: 1.0, green: 0.75, blue: 0.2),
                            Color(red: 0.95, green: 0.6, blue: 0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.orange.opacity(0.5), radius: 10)
                .shadow(color: Color.black, radius: 2, x: 2, y: 2)
            
            // MINI
            Text("MINI")
                .font(.system(size: 52, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(red: 0.85, green: 0.85, blue: 0.95)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.purple.opacity(0.3), radius: 8)
                .shadow(color: Color.black, radius: 2, x: 2, y: 2)
            
            // Подзаголовок
            HStack(spacing: 12) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 40, height: 2)
                
                Text("TOWER DEFENSE BATTLE")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(2)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 40, height: 2)
            }
            .padding(.top, 10)
        }
        .scaleEffect(titleScale)
        .opacity(titleOpacity)
    }
    
    // MARK: - Play Button
    
    private var playButton: some View {
        VStack(spacing: 15) {
            // Главная кнопка ИГРАТЬ
            mainPlayButton
            
            // Кнопка выбора бустеров (если есть)
            if !shopManager.ownedBoosters.isEmpty {
                boosterButton
            }
        }
        .offset(y: buttonsOffset)
    }
    
    private var boosterButton: some View {
        Button {
            showBoosterSelection = true
        } label: {
            HStack(spacing: 8) {
                Text("⚡")
                    .font(.title3)
                Text("Выбрать бустеры")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                
                // Количество активных бустеров
                if !shopManager.activeBoosters.isEmpty {
                    Text("\(shopManager.activeBoosters.count)")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.green))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.8), .purple.opacity(0.5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.purple.opacity(0.5), lineWidth: 1)
                    )
            )
            .shadow(color: .purple.opacity(0.4), radius: 8)
        }
        .buttonStyle(BounceButtonStyle())
    }
    
    private var mainPlayButton: some View {
        Button {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                gameModel.startGame()
            }
        } label: {
            ZStack {
                // Внешнее свечение
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 280, height: 80)
                    .blur(radius: 20)
                
                // Основная кнопка
                HStack(spacing: 15) {
                    Text("⚔️")
                        .font(.system(size: 32))
                    
                    Text("ИГРАТЬ")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .tracking(2)
                }
                .foregroundColor(.white)
                .frame(width: 260, height: 70)
                .background(
                    ZStack {
                        // Градиент кнопки
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.2, green: 0.8, blue: 0.3),
                                        Color(red: 0.1, green: 0.65, blue: 0.2),
                                        Color(red: 0.05, green: 0.5, blue: 0.15)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // Блик сверху
                        VStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.4),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 35)
                            Spacer()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        
                        // Обводка
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.4, green: 1.0, blue: 0.5),
                                        Color(red: 0.2, green: 0.7, blue: 0.3)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 3
                            )
                    }
                )
                .shadow(color: Color.green.opacity(0.5), radius: 15, y: 8)
                .shadow(color: Color.black.opacity(0.3), radius: 5, y: 3)
            }
        }
        .buttonStyle(BounceButtonStyle())
    }
    
    // MARK: - Cards Preview
    
    private var cardsPreview: some View {
        VStack(spacing: 15) {
            Text("ТВОЯ АРМИЯ")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .tracking(3)
            
            HStack(spacing: -10) {
                ForEach(Array(CardType.allCases.enumerated()), id: \.element) { index, cardType in
                    CardPreviewLarge(cardType: cardType)
                        .rotationEffect(.degrees(Double(index - 2) * 5))
                        .offset(y: abs(CGFloat(index - 2)) * 8)
                        .scaleEffect(cardsAppeared ? 1 : 0.5)
                        .opacity(cardsAppeared ? 1 : 0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.7)
                            .delay(Double(index) * 0.1),
                            value: cardsAppeared
                        )
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 20) {
                StatBadge(icon: "🏆", value: "0", label: "Побед")
                StatBadge(icon: "⚡", value: "\(shopManager.ownedBoosters.values.reduce(0, +))", label: "Бустеры")
                StatBadge(icon: "💎", value: "\(shopManager.gems)", label: "Гемы")
            }
            
            Text("v1.0 • SwiftUI + SpriteKit")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.2))
        }
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        // Появление короны
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
            crownScale = 1.0
        }
        
        // Качание короны
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(1)) {
            crownRotation = 10
        }
        
        // Появление заголовка
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.4)) {
            titleScale = 1.0
            titleOpacity = 1.0
        }
        
        // Появление кнопок
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.6)) {
            buttonsOffset = 0
        }
        
        // Появление карт
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            cardsAppeared = true
        }
        
        // Пульсация свечения
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowOpacity = 0.6
        }
        
        // Частицы
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            particlesVisible = true
        }
    }
}

// MARK: - Card Preview Large

struct CardPreviewLarge: View {
    let cardType: CardType
    @State private var isHovered = false
    
    var body: some View {
        ZStack {
            // Карточка
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(cardType.color),
                            Color(cardType.color).opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 55, height: 75)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: Color(cardType.color).opacity(0.5), radius: 8)
                .shadow(color: Color.black.opacity(0.3), radius: 4, y: 4)
            
            VStack(spacing: 4) {
                // Эмодзи
                Text(cardType.emoji)
                    .font(.system(size: 28))
                    .shadow(color: .black.opacity(0.3), radius: 2)
                
                // Стоимость
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.8, green: 0.4, blue: 1.0),
                                    Color(red: 0.5, green: 0.2, blue: 0.8)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 22, height: 22)
                    
                    Text("\(cardType.elixirCost)")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(icon)
                    .font(.system(size: 16))
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Bounce Button Style

struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Particles View

struct ParticlesView: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .blur(radius: particle.size / 4)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles(in: geometry.size)
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        particles = (0..<20).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 3...8),
                color: [Color.yellow, Color.orange, Color.purple, Color.blue].randomElement()!.opacity(0.4),
                opacity: Double.random(in: 0.2...0.5)
            )
        }
    }
    
    private func animateParticles(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            for i in particles.indices {
                particles[i].position.y -= CGFloat.random(in: 0.5...2)
                particles[i].position.x += CGFloat.random(in: -1...1)
                
                if particles[i].position.y < -20 {
                    particles[i].position.y = size.height + 20
                    particles[i].position.x = CGFloat.random(in: 0...size.width)
                }
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var color: Color
    var opacity: Double
}

// MARK: - Booster Selection View

struct BoosterSelectionView: View {
    @ObservedObject var gameModel: GameModel
    @ObservedObject var shopManager = ShopManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Фон
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color(red: 0.15, green: 0.1, blue: 0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Заголовок
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Text("БУСТЕРЫ")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Spacer()
                    
                    // Placeholder
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(.clear)
                }
                .padding()
                
                Text("Выберите бустеры для следующей игры")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                
                // Активные бустеры
                if !shopManager.activeBoosters.isEmpty {
                    VStack(spacing: 8) {
                        Text("Активировано:")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        HStack {
                            ForEach(Array(shopManager.activeBoosters), id: \.self) { booster in
                                Text(booster.icon)
                                    .font(.title2)
                                    .padding(8)
                                    .background(Circle().fill(Color.green.opacity(0.2)))
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)
                }
                
                // Список бустеров
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(BoosterType.allCases) { booster in
                            BoosterSelectionCard(
                                booster: booster,
                                count: shopManager.boosterCount(booster),
                                isActive: shopManager.isBoosterActive(booster),
                                onActivate: {
                                    _ = shopManager.useBooster(booster)
                                },
                                onDeactivate: {
                                    shopManager.activeBoosters.remove(booster)
                                    shopManager.ownedBoosters[booster, default: 0] += 1
                                }
                            )
                        }
                    }
                    .padding()
                }
                
                // Кнопка готово
                Button {
                    dismiss()
                } label: {
                    Text("ГОТОВО")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(
                                    LinearGradient(
                                        colors: [.green, .green.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .shadow(color: .green.opacity(0.5), radius: 10)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
        }
    }
}

struct BoosterSelectionCard: View {
    let booster: BoosterType
    let count: Int
    let isActive: Bool
    let onActivate: () -> Void
    let onDeactivate: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Иконка
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                isActive ? Color.green.opacity(0.5) : booster.color.opacity(0.3),
                                isActive ? Color.green.opacity(0.2) : booster.color.opacity(0.1)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Text(booster.icon)
                    .font(.title)
            }
            
            // Название
            Text(booster.name)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Количество
            if count > 0 || isActive {
                Text(isActive ? "Активен" : "x\(count)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isActive ? .green : .white.opacity(0.6))
            } else {
                Text("Нет в наличии")
                    .font(.system(size: 10))
                    .foregroundColor(.red.opacity(0.7))
            }
            
            // Кнопка
            if isActive {
                Button(action: onDeactivate) {
                    Text("Снять")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.6))
                        )
                }
            } else if count > 0 {
                Button(action: onActivate) {
                    Text("Активировать")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.6))
                        )
                }
            }
        }
        .padding()
        .frame(height: 160)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    isActive
                        ? Color.green.opacity(0.15)
                        : Color(white: 0.1).opacity(0.9)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isActive ? Color.green.opacity(0.5) : booster.color.opacity(0.3),
                    lineWidth: isActive ? 2 : 1
                )
        )
    }
}

// MARK: - Preview

#Preview {
    MainMenuView(gameModel: GameModel())
}
