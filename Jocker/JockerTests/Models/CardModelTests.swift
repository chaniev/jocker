//
//  CardModelTests.swift
//  JockerTests
//
//  Created by Codex on 06.03.2026.
//

import XCTest
@testable import Jocker

final class CardModelTests: XCTestCase {
    func testCardSuit_returnsNilForJoker() {
        XCTAssertNil(Card.joker.suit)
    }

    func testCardRank_returnsNilForJoker() {
        XCTAssertNil(Card.joker.rank)
    }

    func testCardIsJoker_returnsExpectedValue() {
        XCTAssertTrue(Card.joker.isJoker)
        XCTAssertFalse(card(.hearts, .ace).isJoker)
    }

    func testCardComparable_sortsRegularBeforeJoker() {
        let cards: [Card] = [.joker, card(.spades, .ace), card(.diamonds, .six)]

        XCTAssertEqual(cards.sorted(), [card(.diamonds, .six), card(.spades, .ace), .joker])
    }

    func testCardDescription_joker_containsJokerName() {
        XCTAssertEqual(Card.joker.description, "🃏 Джокер")
    }

    func testCardFullName_regular_returnsRankAndSuitName() {
        XCTAssertEqual(card(.hearts, .queen).fullName, "Дама Черви")
    }

    func testCardBeats_jokerBeatsEverything() {
        XCTAssertTrue(Card.joker.beats(card(.clubs, .ace), trump: .spades))
        XCTAssertFalse(card(.clubs, .ace).beats(.joker, trump: .spades))
    }

    func testCardBeats_trumpBeatsNonTrump() {
        let trumpCard = card(.spades, .seven)
        let nonTrumpCard = card(.hearts, .ace)

        XCTAssertTrue(trumpCard.beats(nonTrumpCard, trump: .spades))
        XCTAssertFalse(nonTrumpCard.beats(trumpCard, trump: .spades))
    }

    func testCardBeats_sameSuitHigherRankWins() {
        XCTAssertTrue(card(.diamonds, .ace).beats(card(.diamonds, .king), trump: nil))
        XCTAssertFalse(card(.diamonds, .seven).beats(card(.diamonds, .king), trump: nil))
    }

    func testCardEquality_sameSuitAndRank_areEqual() {
        XCTAssertEqual(card(.clubs, .ten), card(.clubs, .ten))
        XCTAssertNotEqual(card(.clubs, .ten), card(.clubs, .jack))
    }

    private func card(_ suit: Suit, _ rank: Rank) -> Card {
        return .regular(suit: suit, rank: rank)
    }
}
