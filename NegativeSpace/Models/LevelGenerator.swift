//
//  LevelGenerator.swift
//  NegativeSpace
//
//  Генератор уровней
//

import SwiftUI

/// Генератор уровней
final class LevelGenerator {
    
    // Цветовая палитра для блоков
    private let colors: [Color] = [
        Color(red: 0.4, green: 0.8, blue: 0.95),  // Голубой
        Color(red: 1.0, green: 0.45, blue: 0.5),  // Розовый
        Color(red: 0.6, green: 0.9, blue: 0.5),   // Зелёный
        Color(red: 1.0, green: 0.75, blue: 0.3),  // Оранжевый
        Color(red: 0.7, green: 0.5, blue: 0.9),   // Фиолетовый
        Color(red: 0.95, green: 0.9, blue: 0.4),  // Жёлтый
    ]
    
    /// Генерация уровня по номеру
    func generateLevel(number: Int) -> Level {
        switch number {
        case 1: return level1()
        case 2: return level2()
        case 3: return level3()
        case 4: return level4()
        case 5: return level5()
        case 6: return level6()
        case 7: return level7()
        case 8: return level8()
        case 9: return level9()
        case 10: return level10()
        case 11: return level11()
        case 12: return level12()
        case 13: return level13()
        case 14: return level14()
        case 15: return level15()
        case 16: return level16()
        case 17: return level17()
        case 18: return level18()
        case 19: return level19()
        case 20: return level20()
        default: return generateProceduralLevel(number: number)
        }
    }
    
    /// Общее количество уровней
    var totalLevels: Int { 50 }
    
    // MARK: - Tutorial Levels (1-5)
    
    private func level1() -> Level {
        // Простой квадрат 2x2
        Level(
            id: 1,
            targetShape: [
                [true, true],
                [true, true]
            ],
            blocks: [
                .square2(colors[0])
            ],
            difficulty: .easy
        )
    }
    
    private func level2() -> Level {
        // Линия 3x1
        Level(
            id: 2,
            targetShape: [
                [true, true, true]
            ],
            blocks: [
                .line3(colors[1])
            ],
            difficulty: .easy
        )
    }
    
    private func level3() -> Level {
        // Два квадрата рядом
        Level(
            id: 3,
            targetShape: [
                [true, true, true, true],
                [true, true, true, true]
            ],
            blocks: [
                .square2(colors[0]),
                .square2(colors[2])
            ],
            difficulty: .easy
        )
    }
    
    private func level4() -> Level {
        // L-форма
        Level(
            id: 4,
            targetShape: [
                [true, false],
                [true, false],
                [true, true]
            ],
            blocks: [
                .lBlock(colors[3])
            ],
            difficulty: .easy
        )
    }
    
    private func level5() -> Level {
        // Квадрат 3x3: квадрат 2x2 + линия 3 + 2 одиночных
        Level(
            id: 5,
            targetShape: [
                [true, true, true],
                [true, true, true],
                [true, true, true]
            ],
            blocks: [
                .square2(colors[0]),   // 4 ячейки
                .line3(colors[1]),     // 3 ячейки
                .single(colors[2]),    // 1 ячейка
                .single(colors[3])     // 1 ячейка = 9 всего ✓
            ],
            difficulty: .easy
        )
    }
    
    // MARK: - Medium Levels (6-10)
    
    private func level6() -> Level {
        // Крест
        Level(
            id: 6,
            targetShape: [
                [false, true, false],
                [true, true, true],
                [false, true, false]
            ],
            blocks: [
                .vLine3(colors[0]),  // 3 ячейки
                .line2(colors[1])    // 2 ячейки = 5 всего ✓
            ],
            difficulty: .medium
        )
    }
    
    private func level7() -> Level {
        // Лесенка
        Level(
            id: 7,
            targetShape: [
                [true, false, false],
                [true, true, false],
                [true, true, true]
            ],
            blocks: [
                .corner(colors[0]),   // 3
                .line3(colors[1])     // 3 = 6 ✓
            ],
            difficulty: .medium
        )
    }
    
    private func level8() -> Level {
        // Т-форма
        Level(
            id: 8,
            targetShape: [
                [true, true, true],
                [false, true, false],
                [false, true, false]
            ],
            blocks: [
                .line3(colors[0]),   // 3
                .vLine2(colors[1])   // 2 = 5 ✓
            ],
            difficulty: .medium
        )
    }
    
    private func level9() -> Level {
        // Змейка
        Level(
            id: 9,
            targetShape: [
                [true, true, false],
                [false, true, true],
                [false, false, true]
            ],
            blocks: [
                .sBlock(colors[0]),   // 4
                .single(colors[1])    // 1 = 5 ✓
            ],
            difficulty: .medium
        )
    }
    
    private func level10() -> Level {
        // Большой квадрат с дыркой
        Level(
            id: 10,
            targetShape: [
                [true, true, true],
                [true, false, true],
                [true, true, true]
            ],
            blocks: [
                .line3(colors[0]),   // 3
                .line3(colors[1]),   // 3
                .vLine2(colors[2])   // 2 = 8 ✓
            ],
            difficulty: .medium
        )
    }
    
    // MARK: - Hard Levels (11-15)
    
    private func level11() -> Level {
        // Сердце
        Level(
            id: 11,
            targetShape: [
                [false, true, false, true, false],
                [true, true, true, true, true],
                [true, true, true, true, true],
                [false, true, true, true, false],
                [false, false, true, false, false]
            ],
            blocks: [
                .square2(colors[0]),   // 4
                .square2(colors[1]),   // 4
                .tBlock(colors[2]),    // 4
                .vLine3(colors[3]),    // 3
                .single(colors[4])     // 1 = 16 ✓
            ],
            difficulty: .hard
        )
    }
    
    private func level12() -> Level {
        // Песочные часы
        Level(
            id: 12,
            targetShape: [
                [true, true, true],
                [false, true, false],
                [true, true, true]
            ],
            blocks: [
                .line3(colors[0]),   // 3
                .line3(colors[1]),   // 3
                .single(colors[2])   // 1 = 7 ✓
            ],
            difficulty: .hard
        )
    }
    
    private func level13() -> Level {
        // Стрелка вверх
        Level(
            id: 13,
            targetShape: [
                [false, false, true, false, false],
                [false, true, true, true, false],
                [true, true, true, true, true],
                [false, false, true, false, false],
                [false, false, true, false, false]
            ],
            blocks: [
                .tBlock(colors[0]),    // 4
                .line3(colors[1]),     // 3
                .line3(colors[2]),     // 3
                .vLine2(colors[3]),    // 2
                .single(colors[4])     // 1 = 13 ✓
            ],
            difficulty: .hard
        )
    }
    
    private func level14() -> Level {
        // Рамка
        Level(
            id: 14,
            targetShape: [
                [true, true, true, true],
                [true, false, false, true],
                [true, false, false, true],
                [true, true, true, true]
            ],
            blocks: [
                .lBlock(colors[0]),        // 4
                .lBlockReverse(colors[1]), // 4
                .line2(colors[2]),         // 2
                .line2(colors[3])          // 2 = 12 ✓
            ],
            difficulty: .hard
        )
    }
    
    private func level15() -> Level {
        // Тетрис
        Level(
            id: 15,
            targetShape: [
                [true, true, true, true],
                [true, true, true, true],
                [true, true, true, true]
            ],
            blocks: [
                .tBlock(colors[0]),    // 4
                .lBlock(colors[1]),    // 4
                .line2(colors[2]),     // 2
                .line2(colors[3])      // 2 = 12 ✓
            ],
            difficulty: .hard
        )
    }
    
    // MARK: - Expert Levels (16-20)
    
    private func level16() -> Level {
        Level(
            id: 16,
            targetShape: [
                [true, true, true, true, true],
                [true, true, true, true, true],
                [true, true, true, true, true]
            ],
            blocks: [
                .lBlock(colors[0]),
                .lBlockReverse(colors[1]),
                .tBlock(colors[2]),
                .line2(colors[3])
            ],
            difficulty: .expert
        )
    }
    
    private func level17() -> Level {
        Level(
            id: 17,
            targetShape: [
                [false, true, true, true, false],
                [true, true, true, true, true],
                [true, true, true, true, true],
                [false, true, true, true, false]
            ],
            blocks: [
                .square2(colors[0]),
                .square2(colors[1]),
                .tBlock(colors[2]),
                .line3(colors[3]),
                .single(colors[4]),
                .single(colors[5])
            ],
            difficulty: .expert
        )
    }
    
    private func level18() -> Level {
        Level(
            id: 18,
            targetShape: [
                [true, true, true, true],
                [true, true, true, true],
                [true, true, true, true],
                [true, true, true, true]
            ],
            blocks: [
                .square2(colors[0]),
                .square2(colors[1]),
                .square2(colors[2]),
                .square2(colors[3])
            ],
            difficulty: .expert
        )
    }
    
    private func level19() -> Level {
        Level(
            id: 19,
            targetShape: [
                [true, false, false, false, true],
                [true, true, true, true, true],
                [true, true, true, true, true],
                [true, false, false, false, true]
            ],
            blocks: [
                .lBlock(colors[0]),
                .lBlockReverse(colors[1]),
                .lBlock(colors[2]),
                .lBlockReverse(colors[3])
            ],
            difficulty: .expert
        )
    }
    
    private func level20() -> Level {
        Level(
            id: 20,
            targetShape: [
                [true, true, true, true, true],
                [true, true, true, true, true],
                [true, true, true, true, true],
                [true, true, true, true, true]
            ],
            blocks: [
                .sBlock(colors[0]),
                .zBlock(colors[1]),
                .tBlock(colors[2]),
                .lBlock(colors[3]),
                .single(colors[4]),
                .single(colors[5])
            ],
            difficulty: .expert
        )
    }
    
    // MARK: - Procedural Generation
    
    private func generateProceduralLevel(number: Int) -> Level {
        // Для уровней 21+ генерируем процедурно
        let size = min(4 + (number - 20) / 5, 6)
        let difficulty: Level.Difficulty = {
            switch number {
            case 21...30: return .medium
            case 31...40: return .hard
            default: return .expert
            }
        }()
        
        // Создаём случайную форму
        var shape = Array(repeating: Array(repeating: true, count: size), count: size)
        
        // Убираем случайные углы
        let seed = number * 12345
        var random = SeededRandomGenerator(seed: seed)
        
        if random.next() % 2 == 0 { shape[0][0] = false }
        if random.next() % 2 == 0 { shape[0][size-1] = false }
        if random.next() % 2 == 0 { shape[size-1][0] = false }
        if random.next() % 2 == 0 { shape[size-1][size-1] = false }
        
        // Генерируем блоки для заполнения
        let blocks = generateBlocksForShape(shape, seed: seed)
        
        return Level(
            id: number,
            targetShape: shape,
            blocks: blocks,
            difficulty: difficulty
        )
    }
    
    private func generateBlocksForShape(_ shape: [[Bool]], seed: Int) -> [Block] {
        var random = SeededRandomGenerator(seed: seed)
        var blocks: [Block] = []
        
        // Подсчитываем количество ячеек
        let totalCells = shape.flatMap { $0 }.filter { $0 }.count
        var remainingCells = totalCells
        
        while remainingCells > 0 {
            let colorIndex = random.next() % colors.count
            let color = colors[colorIndex]
            
            let block: Block
            if remainingCells >= 4 && random.next() % 3 == 0 {
                block = .square2(color)
                remainingCells -= 4
            } else if remainingCells >= 3 && random.next() % 2 == 0 {
                block = .line3(color)
                remainingCells -= 3
            } else if remainingCells >= 2 {
                block = random.next() % 2 == 0 ? .line2(color) : .vLine2(color)
                remainingCells -= 2
            } else {
                block = .single(color)
                remainingCells -= 1
            }
            
            blocks.append(block)
        }
        
        return blocks
    }
}

// MARK: - Seeded Random Generator

/// Простой генератор псевдослучайных чисел с сидом
struct SeededRandomGenerator {
    private var state: Int
    
    init(seed: Int) {
        self.state = seed
    }
    
    mutating func next() -> Int {
        state = (state &* 1103515245 &+ 12345) & 0x7fffffff
        return abs(state)
    }
}
