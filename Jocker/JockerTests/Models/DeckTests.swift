//
//  DeckTests.swift
//  JockerTests
//
//  Created by Codex on 06.03.2026.
//

import XCTest
@testable import Jocker

final class DeckTests: XCTestCase {
    func testDeckInit_containsExpectedCardCount() {
        let deck = Deck()

        XCTAssertEqual(deck.count, GameConstants.deckSize)
    }

    func testDeckContains_allExpectedRegularCardsPresent() {
        let deck = Deck()
        let cards = Set(deck.cards)

        for rank in Rank.allCases {
            XCTAssertTrue(cards.contains(card(.diamonds, rank)))
            XCTAssertTrue(cards.contains(card(.hearts, rank)))

            if rank == .six {
                XCTAssertFalse(cards.contains(card(.spades, rank)))
                XCTAssertFalse(cards.contains(card(.clubs, rank)))
            } else {
                XCTAssertTrue(cards.contains(card(.spades, rank)))
                XCTAssertTrue(cards.contains(card(.clubs, rank)))
            }
        }
    }

    func testDeckContains_exactlyTwoJokers() {
        let deck = Deck()
        let jokerCount = deck.cards.filter(\.isJoker).count

        XCTAssertEqual(jokerCount, GameConstants.jokersCount)
    }

    func testDeckShuffle_changesOrder() {
        let original = Deck().cards
        var orderChanged = false

        for _ in 0..<5 {
            var deck = Deck()
            deck.shuffle()
            if deck.cards != original {
                orderChanged = true
                break
            }
        }

        XCTAssertTrue(orderChanged, "Shuffle should change order in repeated attempts.")
    }

    func testDeckCount_afterShuffle_sameCount() {
        var deck = Deck()
        let originalCount = deck.count

        deck.shuffle()

        XCTAssertEqual(deck.count, originalCount)
    }

    private func card(_ suit: Suit, _ rank: Rank) -> Card {
        return .regular(suit: suit, rank: rank)
    }
}
