//
//  DealHistoryStoreTests.swift
//  JockerTests
//
//  Created by Codex on 19.02.2026.
//

import XCTest
@testable import Jocker

final class DealHistoryStoreTests: XCTestCase {
    func testHistory_whenDealRecorded_containsTrumpMovesAndWinner() {
        let store = DealHistoryStore()
        store.startDeal(blockIndex: 1, roundIndex: 2)
        store.setTrump(.hearts, blockIndex: 1, roundIndex: 2)

        store.appendTrick(
            blockIndex: 1,
            roundIndex: 2,
            playedCards: [
                PlayedTrickCard(playerIndex: 0, card: .regular(suit: .spades, rank: .ace)),
                PlayedTrickCard(playerIndex: 1, card: .regular(suit: .spades, rank: .king)),
                PlayedTrickCard(playerIndex: 2, card: .regular(suit: .hearts, rank: .six))
            ],
            winnerPlayerIndex: 2
        )

        let history = store.history(blockIndex: 1, roundIndex: 2)
        XCTAssertNotNil(history)
        XCTAssertEqual(history?.trump, .hearts)
        XCTAssertEqual(history?.tricks.count, 1)
        XCTAssertEqual(history?.tricks.first?.winnerPlayerIndex, 2)
        XCTAssertEqual(history?.tricks.first?.moves.count, 3)
        XCTAssertEqual(history?.tricks.first?.moves.first?.playerIndex, 0)
        XCTAssertEqual(history?.tricks.first?.moves.first?.card, .regular(suit: .spades, rank: .ace))
    }

    func testHistory_whenJokerPlayed_preservesJokerContext() {
        let store = DealHistoryStore()

        store.appendTrick(
            blockIndex: 0,
            roundIndex: 0,
            playedCards: [
                PlayedTrickCard(
                    playerIndex: 0,
                    card: .joker,
                    jokerPlayStyle: .faceUp,
                    jokerLeadDeclaration: .above(suit: .clubs)
                )
            ],
            winnerPlayerIndex: 0
        )

        let move = store
            .history(blockIndex: 0, roundIndex: 0)?
            .tricks
            .first?
            .moves
            .first

        XCTAssertEqual(move?.card, .joker)
        XCTAssertEqual(move?.jokerPlayStyle, .faceUp)
        XCTAssertEqual(move?.jokerLeadDeclaration, .above(suit: .clubs))
    }

    func testReset_clearsAllRecordedDeals() {
        let store = DealHistoryStore()
        store.startDeal(blockIndex: 0, roundIndex: 0)
        store.setTrump(.diamonds, blockIndex: 0, roundIndex: 0)
        store.reset()

        XCTAssertNil(store.history(blockIndex: 0, roundIndex: 0))
    }
}
