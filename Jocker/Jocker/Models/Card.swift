//
//  Card.swift
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

/// Цвет карты
enum CardColor {
    case red
    case black
}

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

/// Модель карты
///
/// Enum с associated values — устраняет невозможные состояния
/// (ранее suit/rank были Optional, что допускало невалидные комбинации)
enum Card: Equatable, Hashable, Comparable {
    case regular(suit: Suit, rank: Rank)
    case joker
    
    // MARK: - Совместимые computed-свойства (обратная совместимость)
    
    /// Масть карты (nil для джокера)
    var suit: Suit? {
        if case .regular(let suit, _) = self { return suit }
        return nil
    }
    
    /// Ранг карты (nil для джокера)
    var rank: Rank? {
        if case .regular(_, let rank) = self { return rank }
        return nil
    }
    
    /// Является ли карта джокером
    var isJoker: Bool {
        if case .joker = self { return true }
        return false
    }
    
    // MARK: - Comparable
    
    /// Сортировка: обычные карты по масти, затем по рангу; джокеры в конец
    static func < (lhs: Card, rhs: Card) -> Bool {
        switch (lhs, rhs) {
        case (.regular(let s1, let r1), .regular(let s2, let r2)):
            if s1 != s2 { return s1 < s2 }
            return r1 < r2
        case (.regular, .joker):
            return true   // обычные карты перед джокерами
        case (.joker, .regular):
            return false
        case (.joker, .joker):
            return false
        }
    }
    
    // MARK: - Описание
    
    /// Краткое описание карты
    var description: String {
        switch self {
        case .joker:
            return "🃏 Джокер"
        case .regular(let suit, let rank):
            return "\(suit.rawValue) \(rank.symbol)"
        }
    }
    
    /// Полное название карты
    var fullName: String {
        switch self {
        case .joker:
            return "Джокер"
        case .regular(let suit, let rank):
            return "\(rank.name) \(suit.name)"
        }
    }
    
    /// Сравнение карт по старшинству в игре (с учётом козыря)
    func beats(_ other: Card, trump: Suit?) -> Bool {
        // Джокер бьёт всё
        if self.isJoker { return true }
        if other.isJoker { return false }
        
        guard case .regular(let selfSuit, let selfRank) = self,
              case .regular(let otherSuit, let otherRank) = other else {
            return false
        }
        
        // Если есть козырь
        if let trump = trump {
            let selfIsTrump = selfSuit == trump
            let otherIsTrump = otherSuit == trump
            
            if selfIsTrump && !otherIsTrump { return true }
            if !selfIsTrump && otherIsTrump { return false }
            if selfIsTrump && otherIsTrump { return selfRank > otherRank }
        }
        
        // Разные масти без козыря — первая карта побеждает
        if selfSuit != otherSuit { return false }
        
        // Одинаковые масти — сравниваем по рангу
        return selfRank > otherRank
    }
}
