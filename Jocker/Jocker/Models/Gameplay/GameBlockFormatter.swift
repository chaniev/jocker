//
//  GameBlockFormatter.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

/// Единый formatter текстов блоков для UI.
enum GameBlockFormatter {
    /// Короткий заголовок блока для компактных UI-строк.
    static func shortTitle(for block: GameBlock, playerCount: Int) -> String {
        let rangeLabel = cardsRangeLabel(for: block, playerCount: playerCount)
        return "Блок \(block.rawValue) (\(rangeLabel))"
    }

    /// Расширенное описание блока.
    static func detailedDescription(for block: GameBlock, playerCount: Int) -> String {
        let rangeLabel = cardsRangeLabel(for: block, playerCount: playerCount)

        switch block {
        case .first:
            return "Блок 1: возрастающее количество карт (\(rangeLabel))"
        case .second:
            return "Блок 2: фиксированное количество карт (\(rangeLabel))"
        case .third:
            return "Блок 3: убывающее количество карт (\(rangeLabel))"
        case .fourth:
            return "Блок 4: фиксированное количество карт (\(rangeLabel))"
        }
    }

    private static func cardsRangeLabel(for block: GameBlock, playerCount: Int) -> String {
        let deals = GameConstants.deals(for: block, playerCount: playerCount)
        guard let first = deals.first, let last = deals.last else {
            return "0 карт"
        }

        if first == last {
            return "\(first) карт"
        }
        return "\(first)-\(last) карт"
    }
}
