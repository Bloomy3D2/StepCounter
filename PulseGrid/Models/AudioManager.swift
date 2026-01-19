//
//  AudioManager.swift
//  PulseGrid
//
//  Менеджер звуков и музыки
//

import SwiftUI
import AVFoundation

/// Менеджер аудио
final class AudioManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isMusicEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isMusicEnabled, forKey: "musicEnabled")
            if isMusicEnabled {
                playBackgroundMusic()
            } else {
                stopBackgroundMusic()
            }
        }
    }
    
    @Published var isSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: "soundEnabled")
        }
    }
    
    // MARK: - Private Properties
    
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var soundEffectPlayers: [String: AVAudioPlayer] = [:]
    
    // MARK: - Initialization
    
    init() {
        self.isMusicEnabled = UserDefaults.standard.object(forKey: "musicEnabled") as? Bool ?? true
        self.isSoundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        
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
    
    // MARK: - Background Music
    
    func playBackgroundMusic() {
        guard isMusicEnabled else { return }
        
        // В реальном приложении загружаем музыку из bundle
        // Для демо создаём синтезированный бит
        
        // Пример загрузки:
        // guard let url = Bundle.main.url(forResource: "background_beat", withExtension: "mp3") else { return }
        // backgroundMusicPlayer = try? AVAudioPlayer(contentsOf: url)
        // backgroundMusicPlayer?.numberOfLoops = -1
        // backgroundMusicPlayer?.volume = 0.3
        // backgroundMusicPlayer?.play()
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
    }
    
    // MARK: - Sound Effects
    
    /// Звук при выборе ячейки
    func playSelectSound() {
        guard isSoundEnabled else { return }
        playHapticFeedback(.light)
        // playSound("select")
    }
    
    /// Звук при успешном матче
    func playMatchSound(combo: Int) {
        guard isSoundEnabled else { return }
        playHapticFeedback(.medium)
        // Повышаем тон в зависимости от комбо
        // playSound("match_\(min(combo, 5))")
    }
    
    /// Звук при пульсе
    func playPulseSound() {
        guard isSoundEnabled else { return }
        // Тихий пульсирующий звук
        // playSound("pulse", volume: 0.1)
    }
    
    /// Звук победы
    func playVictorySound() {
        guard isSoundEnabled else { return }
        playHapticFeedback(.heavy)
        // playSound("victory")
    }
    
    /// Звук проигрыша
    func playGameOverSound() {
        guard isSoundEnabled else { return }
        playHapticFeedback(.heavy)
        // playSound("gameover")
    }
    
    // MARK: - Haptic Feedback
    
    private func playHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    // MARK: - Helper
    
    private func playSound(_ name: String, volume: Float = 1.0) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.play()
            soundEffectPlayers[name] = player
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
}
