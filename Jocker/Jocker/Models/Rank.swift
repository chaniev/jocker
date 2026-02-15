//
//  Rank.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import Foundation

/// Ранг карты
enum Rank: Int, CaseIterable, Comparable {
    case six = 6
    case seven = 7
    case eight = 8
    case nine = 9
    case ten = 10
    case jack = 11
    case queen = 12
    case king = 13
    case ace = 14

    static func < (lhs: Rank, rhs: Rank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var symbol: String {
        switch self {
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .ten: return "10"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        case .ace: return "A"
        }
    }

    var name: String {
        switch self {
        case .six: return "Шестёрка"
        case .seven: return "Семёрка"
        case .eight: return "Восьмёрка"
        case .nine: return "Девятка"
        case .ten: return "Десятка"
        case .jack: return "Валет"
        case .queen: return "Дама"
        case .king: return "Король"
        case .ace: return "Туз"
        }
    }
}
