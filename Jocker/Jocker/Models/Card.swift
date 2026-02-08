//
//  Card.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import Foundation

/// Масть карты
enum Suit: String, CaseIterable {
    case diamonds = "♦️"  // Бубны
    case hearts = "♥️"    // Черви
    case spades = "♠️"    // Пики
    case clubs = "♣️"     // Крести
    
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
enum Rank: Int, CaseIterable {
    case six = 6
    case seven = 7
    case eight = 8
    case nine = 9
    case ten = 10
    case jack = 11
    case queen = 12
    case king = 13
    case ace = 14
    
    var symbol: String {
        switch self {
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .ten: return "10"
        case .jack: return "В"  // Валет
        case .queen: return "Д"  // Дама
        case .king: return "К"   // Король
        case .ace: return "Т"    // Туз
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
struct Card: Equatable, Hashable {
    let suit: Suit?  // nil для джокера
    let rank: Rank?  // nil для джокера
    let isJoker: Bool
    
    /// Создание обычной карты
    init(suit: Suit, rank: Rank) {
        self.suit = suit
        self.rank = rank
        self.isJoker = false
    }
    
    /// Создание джокера
    init(joker: Bool) {
        self.suit = nil
        self.rank = nil
        self.isJoker = joker
    }
    
    /// Описание карты
    var description: String {
        if isJoker {
            return "🃏 Джокер"
        }
        guard let suit = suit, let rank = rank else {
            return "Неизвестная карта"
        }
        return "\(suit.rawValue) \(rank.symbol)"
    }
    
    /// Полное название карты
    var fullName: String {
        if isJoker {
            return "Джокер"
        }
        guard let suit = suit, let rank = rank else {
            return "Неизвестная карта"
        }
        return "\(rank.name) \(suit.name)"
    }
    
    /// Сравнение карт по старшинству (без учёта козыря)
    func beats(_ other: Card, trump: Suit?) -> Bool {
        // Джокер бьёт всё
        if self.isJoker {
            return true
        }
        
        // Если другая карта - джокер, она бьёт эту
        if other.isJoker {
            return false
        }
        
        guard let selfSuit = self.suit, let selfRank = self.rank,
              let otherSuit = other.suit, let otherRank = other.rank else {
            return false
        }
        
        // Если есть козырь
        if let trump = trump {
            let selfIsTrump = selfSuit == trump
            let otherIsTrump = otherSuit == trump
            
            // Козырь бьёт не козырь
            if selfIsTrump && !otherIsTrump {
                return true
            }
            if !selfIsTrump && otherIsTrump {
                return false
            }
            
            // Оба козыри - сравниваем по рангу
            if selfIsTrump && otherIsTrump {
                return selfRank.rawValue > otherRank.rawValue
            }
        }
        
        // Разные масти, нет козыря - карта той же масти что первая бьёт
        if selfSuit != otherSuit {
            return false
        }
        
        // Одинаковые масти - сравниваем по рангу
        return selfRank.rawValue > otherRank.rawValue
    }
}

