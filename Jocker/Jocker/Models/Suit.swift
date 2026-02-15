//
//  Suit.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import Foundation

/// Масть карты
enum Suit: String, CaseIterable, Comparable {
    // Используем text presentation symbols (FE0E), чтобы избежать emoji-рендера.
    case diamonds = "♦︎"  // Бубны
    case hearts = "♥︎"    // Черви
    case spades = "♠︎"    // Пики
    case clubs = "♣︎"     // Крести

    /// Порядок мастей для сортировки: бубны < черви < пики < крести
    private static let sortOrder: [Suit] = [.diamonds, .hearts, .spades, .clubs]

    static func < (lhs: Suit, rhs: Suit) -> Bool {
        let lhsIndex = sortOrder.firstIndex(of: lhs) ?? 0
        let rhsIndex = sortOrder.firstIndex(of: rhs) ?? 0
        return lhsIndex < rhsIndex
    }

    var color: CardColor {
        switch self {
        case .diamonds, .hearts:
            return .red
        case .spades, .clubs:
            return .black
        }
    }

    var name: String {
        switch self {
        case .diamonds: return "Бубны"
        case .hearts: return "Черви"
        case .spades: return "Пики"
        case .clubs: return "Крести"
        }
    }
}
