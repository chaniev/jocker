//
//  BotTestCards.swift
//  JockerTests
//
//  Created by Codex on 06.03.2026.
//

@testable import Jocker

enum BotTestCards {
    static func card(_ suit: Suit, _ rank: Rank) -> Card {
        return .regular(suit: suit, rank: rank)
    }

    static func hand(_ cards: Card...) -> [Card] {
        return cards
    }

    static func hand(_ cards: [Card]) -> [Card] {
        return cards
    }
}
