//
//  Level.swift
//  NegativeSpace
//
//  Модель уровня
//

import SwiftUI

/// Уровень игры
struct Level: Identifiable {
    let id: Int
    let targetShape: [[Bool]]  // Форма, которую нужно заполнить (true = нужно заполнить)
    let blocks: [Block]        // Блоки для заполнения
    let difficulty: Difficulty
    
    enum Difficulty: String {
        case easy = "Легко"
        case medium = "Средне"
        case hard = "Сложно"
        case expert = "Эксперт"
        
        var color: Color {
            switch self {
            case .easy: return .green
            case .medium: return .yellow
            case .hard: return .orange
            case .expert: return .red
            }
        }
    }
}

/// Блок для размещения
struct Block: Identifiable, Equatable {
    let id: UUID
    let shape: [[Bool]]  // Форма блока
    let color: Color
    
    init(shape: [[Bool]], color: Color) {
        self.id = UUID()
        self.shape = shape
        self.color = color
    }
    
    static func == (lhs: Block, rhs: Block) -> Bool {
        lhs.id == rhs.id
    }
    
    /// Размер блока
    var size: (rows: Int, cols: Int) {
        let rows = shape.count
        let cols = shape.first?.count ?? 0
        return (rows, cols)
    }
    
    /// Количество заполненных ячеек
    var cellCount: Int {
        shape.flatMap { $0 }.filter { $0 }.count
    }
}

// MARK: - Predefined Block Shapes

extension Block {
    
    // Базовые формы блоков
    
    /// Квадрат 1x1
    static func single(_ color: Color) -> Block {
        Block(shape: [[true]], color: color)
    }
    
    /// Линия 2
    static func line2(_ color: Color) -> Block {
        Block(shape: [[true, true]], color: color)
    }
    
    /// Линия 3
    static func line3(_ color: Color) -> Block {
        Block(shape: [[true, true, true]], color: color)
    }
    
    /// Линия 4
    static func line4(_ color: Color) -> Block {
        Block(shape: [[true, true, true, true]], color: color)
    }
    
    /// Вертикальная линия 2
    static func vLine2(_ color: Color) -> Block {
        Block(shape: [[true], [true]], color: color)
    }
    
    /// Вертикальная линия 3
    static func vLine3(_ color: Color) -> Block {
        Block(shape: [[true], [true], [true]], color: color)
    }
    
    /// Квадрат 2x2
    static func square2(_ color: Color) -> Block {
        Block(shape: [
            [true, true],
            [true, true]
        ], color: color)
    }
    
    /// L-блок
    static func lBlock(_ color: Color) -> Block {
        Block(shape: [
            [true, false],
            [true, false],
            [true, true]
        ], color: color)
    }
    
    /// Обратный L-блок
    static func lBlockReverse(_ color: Color) -> Block {
        Block(shape: [
            [false, true],
            [false, true],
            [true, true]
        ], color: color)
    }
    
    /// T-блок
    static func tBlock(_ color: Color) -> Block {
        Block(shape: [
            [true, true, true],
            [false, true, false]
        ], color: color)
    }
    
    /// S-блок
    static func sBlock(_ color: Color) -> Block {
        Block(shape: [
            [false, true, true],
            [true, true, false]
        ], color: color)
    }
    
    /// Z-блок
    static func zBlock(_ color: Color) -> Block {
        Block(shape: [
            [true, true, false],
            [false, true, true]
        ], color: color)
    }
    
    /// Угол
    static func corner(_ color: Color) -> Block {
        Block(shape: [
            [true, true],
            [true, false]
        ], color: color)
    }
}
