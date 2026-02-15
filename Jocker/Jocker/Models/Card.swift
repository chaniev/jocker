//
//  Card.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import Foundation

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
