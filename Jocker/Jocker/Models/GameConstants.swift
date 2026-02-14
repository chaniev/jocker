//
//  GameConstants.swift
//  Jocker
//
//  Created by Чаниев Мурад on 08.02.2026.
//

import Foundation

/// Константы игры
enum GameConstants {
    /// Размер колоды (36 карт: 9 бубен, 9 червей, 8 пик, 8 крестей + 2 джокера)
    static let deckSize = 36
    /// Количество джокеров в колоде
    static let jokersCount = 2
    /// Количество блоков в игре
    static let totalBlocks = 4

    /// Максимальное число карт на игрока в фиксированных блоках
    static func maxCardsPerPlayer(for playerCount: Int) -> Int {
        let safePlayerCount = max(1, playerCount)
        return deckSize / safePlayerCount
    }

    /// Последовательность раздач для конкретного блока
    static func deals(for block: GameBlock, playerCount: Int) -> [Int] {
        let maxCards = maxCardsPerPlayer(for: playerCount)
        let rampDeals: [Int]
        if maxCards > 1 {
            rampDeals = Array(1...(maxCards - 1))
        } else {
            rampDeals = []
        }
        let fixedDeals = Array(repeating: maxCards, count: max(1, playerCount))

        switch block {
        case .first:
            return rampDeals
        case .second:
            return fixedDeals
        case .third:
            return Array(rampDeals.reversed())
        case .fourth:
            return fixedDeals
        }
    }

    /// Последовательности раздач по всем блокам
    static func allBlockDeals(playerCount: Int) -> [[Int]] {
        return GameBlock.allCases.map { block in
            deals(for: block, playerCount: playerCount)
        }
    }

    /// Количество карт на игрока для раунда в конкретном блоке
    static func cardsPerPlayer(for block: GameBlock, roundIndex: Int, playerCount: Int) -> Int? {
        let dealsInBlock = deals(for: block, playerCount: playerCount)
        guard roundIndex >= 0, roundIndex < dealsInBlock.count else { return nil }
        return dealsInBlock[roundIndex]
    }
}
