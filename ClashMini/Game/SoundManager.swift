//
//  SoundManager.swift
//  ClashMini
//
//  Менеджер звуковых эффектов
//

import AVFoundation
import SpriteKit

/// Типы звуковых эффектов
enum SoundEffect: String {
    // Интерфейс
    case buttonTap = "button_tap"
    case cardSelect = "card_select"
    case cardPlay = "card_play"
    
    // Юниты
    case unitSpawn = "unit_spawn"
    case unitDeath = "unit_death"
    case unitAttack = "unit_attack"
    
    // Атаки
    case swordSwing = "sword_swing"
    case arrowShoot = "arrow_shoot"
    case magicCast = "magic_cast"
    case fireBreath = "fire_breath"
    
    // Башни
    case towerShoot = "tower_shoot"
    case towerHit = "tower_hit"
    case towerDestroy = "tower_destroy"
    
    // Игра
    case gameStart = "game_start"
    case victory = "victory"
    case defeat = "defeat"
    case elixirFull = "elixir_full"
    case doubleElixir = "double_elixir"
    case crownEarned = "crown_earned"
}

/// Менеджер звуков (Singleton)
final class SoundManager {
    
    static let shared = SoundManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var isSoundEnabled: Bool = true
    private var isMusicEnabled: Bool = true
    private var soundVolume: Float = 0.8
    private var musicVolume: Float = 0.5
    
    private var backgroundMusicPlayer: AVAudioPlayer?
    
    private init() {
        setupAudioSession()
    }
    
    // MARK: - Setup
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Sound Control
    
    func setSoundEnabled(_ enabled: Bool) {
        isSoundEnabled = enabled
    }
    
    func setMusicEnabled(_ enabled: Bool) {
        isMusicEnabled = enabled
        if !enabled {
            stopBackgroundMusic()
        }
    }
    
    func setSoundVolume(_ volume: Float) {
        soundVolume = max(0, min(1, volume))
    }
    
    func setMusicVolume(_ volume: Float) {
        musicVolume = max(0, min(1, volume))
        backgroundMusicPlayer?.volume = musicVolume
    }
    
    // MARK: - Play Sound Effects
    
    /// Проигрывает звуковой эффект
    /// Примечание: Реальные звуки нужно добавить в проект
    func playSound(_ effect: SoundEffect) {
        guard isSoundEnabled else { return }
        
        // Здесь должна быть загрузка реального звукового файла
        // Для прототипа используем системные звуки через AudioServicesPlaySystemSound
        
        // Пример с реальными файлами:
        /*
        guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav") else {
            print("Sound file not found: \(effect.rawValue)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = soundVolume
            player.prepareToPlay()
            player.play()
            
            audioPlayers[effect.rawValue] = player
        } catch {
            print("Failed to play sound: \(error)")
        }
        */
        
        // Для прототипа - haptic feedback вместо звука
        playHapticFeedback(for: effect)
    }
    
    /// Проигрывает звук в SpriteKit сцене (оптимизировано)
    func playSoundAction(for effect: SoundEffect) -> SKAction {
        // Для реальных звуков:
        // return SKAction.playSoundFileNamed("\(effect.rawValue).wav", waitForCompletion: false)
        
        // Для прототипа возвращаем пустое действие
        return SKAction.run { [weak self] in
            self?.playHapticFeedback(for: effect)
        }
    }
    
    // MARK: - Background Music
    
    func playBackgroundMusic(filename: String) {
        guard isMusicEnabled else { return }
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
            print("Music file not found: \(filename)")
            return
        }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.numberOfLoops = -1 // Бесконечный цикл
            backgroundMusicPlayer?.volume = musicVolume
            backgroundMusicPlayer?.prepareToPlay()
            backgroundMusicPlayer?.play()
        } catch {
            print("Failed to play background music: \(error)")
        }
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
    }
    
    func pauseBackgroundMusic() {
        backgroundMusicPlayer?.pause()
    }
    
    func resumeBackgroundMusic() {
        guard isMusicEnabled else { return }
        backgroundMusicPlayer?.play()
    }
    
    // MARK: - Haptic Feedback
    
    private func playHapticFeedback(for effect: SoundEffect) {
        let generator: UIImpactFeedbackGenerator
        
        switch effect {
        case .buttonTap, .cardSelect:
            generator = UIImpactFeedbackGenerator(style: .light)
        case .cardPlay, .unitSpawn:
            generator = UIImpactFeedbackGenerator(style: .medium)
        case .towerDestroy, .victory, .defeat:
            generator = UIImpactFeedbackGenerator(style: .heavy)
        case .unitDeath, .crownEarned:
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.notificationOccurred(.success)
            return
        default:
            generator = UIImpactFeedbackGenerator(style: .light)
        }
        
        generator.impactOccurred()
    }
    
    // MARK: - Convenience Methods
    
    /// Проигрывает звук атаки в зависимости от типа карты
    func playAttackSound(for cardType: CardType) {
        switch cardType {
        case .knight, .giant, .goblin:
            playSound(.swordSwing)
        case .archer:
            playSound(.arrowShoot)
        case .wizard:
            playSound(.magicCast)
        case .dragon:
            playSound(.fireBreath)
        }
    }
}

// MARK: - Sound Effect SKActions

extension SKAction {
    
    /// Создаёт действие проигрывания звука
    static func playGameSound(_ effect: SoundEffect) -> SKAction {
        return SoundManager.shared.playSoundAction(for: effect)
    }
}
