//
//  TrickTakingResolverTests.swift
//  JockerTests
//
//  Created by Codex on 14.02.2026.
//

import XCTest
@testable import Jocker

final class TrickTakingResolverTests: XCTestCase {

    func testWinnerPlayerIndex_returnsNilForEmptyTrick() {
        let winner = TrickTakingResolver.winnerPlayerIndex(playedCards: [], trump: .hearts)
        XCTAssertNil(winner)
    }

    func testWinnerPlayerIndex_whenAllCardsSameSuit_returnsHighestOfLeadSuit() {
        let trick: [(playerIndex: Int, card: Card)] = [
            (playerIndex: 0, card: card(.hearts, .seven)),
            (playerIndex: 1, card: card(.hearts, .king)),
            (playerIndex: 2, card: card(.hearts, .ten)),
            (playerIndex: 3, card: card(.hearts, .ace))
        ]

        let winner = TrickTakingResolver.winnerPlayerIndex(playedCards: trick, trump: .spades)

        XCTAssertEqual(winner, 3)
    }

    func testWinnerPlayerIndex_whenTrumpOnTable_returnsHighestTrump() {
        let trick: [(playerIndex: Int, card: Card)] = [
            (playerIndex: 0, card: card(.hearts, .ace)),
            (playerIndex: 1, card: card(.spades, .seven)),
            (playerIndex: 2, card: card(.hearts, .king)),
            (playerIndex: 3, card: card(.spades, .ace))
        ]

        let winner = TrickTakingResolver.winnerPlayerIndex(playedCards: trick, trump: .spades)

        XCTAssertEqual(winner, 3)
    }

    func testWinnerPlayerIndex_whenNoTrumpAndNoOtherLeadSuit_returnsLeadPlayer() {
        let trick: [(playerIndex: Int, card: Card)] = [
            (playerIndex: 0, card: card(.diamonds, .ace)),
            (playerIndex: 1, card: card(.hearts, .king)),
            (playerIndex: 2, card: card(.spades, .queen)),
            (playerIndex: 3, card: card(.clubs, .jack))
        ]

        let winner = TrickTakingResolver.winnerPlayerIndex(playedCards: trick, trump: nil)

        XCTAssertEqual(winner, 0)
    }

    func testWinnerPlayerIndex_whenNoTrumpAndLeadSuitSupported_returnsHighestLeadSuit() {
        let trick: [(playerIndex: Int, card: Card)] = [
            (playerIndex: 0, card: card(.diamonds, .nine)),
            (playerIndex: 1, card: card(.clubs, .ace)),
            (playerIndex: 2, card: card(.diamonds, .king)),
            (playerIndex: 3, card: card(.spades, .ace))
        ]

        let winner = TrickTakingResolver.winnerPlayerIndex(playedCards: trick, trump: nil)

        XCTAssertEqual(winner, 2)
    }

    func testWinnerPlayerIndex_whenJokerPlayed_returnsJokerPlayer() {
        let trick: [(playerIndex: Int, card: Card)] = [
            (playerIndex: 0, card: card(.hearts, .ace)),
            (playerIndex: 1, card: .joker),
            (playerIndex: 2, card: card(.spades, .ace)),
            (playerIndex: 3, card: card(.spades, .king))
        ]

        let winner = TrickTakingResolver.winnerPlayerIndex(playedCards: trick, trump: .spades)

        XCTAssertEqual(winner, 1)
    }

    func testWinnerPlayerIndex_whenMultipleJokersPlayed_returnsLastJokerPlayer() {
        let trick: [(playerIndex: Int, card: Card)] = [
            (playerIndex: 0, card: card(.hearts, .ace)),
            (playerIndex: 1, card: .joker),
            (playerIndex: 2, card: card(.spades, .ace)),
            (playerIndex: 3, card: .joker)
        ]

        let winner = TrickTakingResolver.winnerPlayerIndex(playedCards: trick, trump: .spades)

        XCTAssertEqual(winner, 3)
    }

    private func card(_ suit: Suit, _ rank: Rank) -> Card {
        .regular(suit: suit, rank: rank)
    }
}
