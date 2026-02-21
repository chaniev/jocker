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
        store.setInitialHands(
            [
                [.regular(suit: .spades, rank: .ace)],
                [.regular(suit: .hearts, rank: .six)],
                [.joker]
            ],
            blockIndex: 1,
            roundIndex: 2
        )

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
        XCTAssertEqual(history?.initialHands.count, 3)
        XCTAssertEqual(history?.initialHands[0], [.regular(suit: .spades, rank: .ace)])
        XCTAssertEqual(history?.initialHands[2], [.joker])
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

    func testHistory_whenMoveSamplesRecorded_containsStateActionAndOutcome() {
        let store = DealHistoryStore()
        store.startDeal(blockIndex: 0, roundIndex: 1)
        store.setTrump(.clubs, blockIndex: 0, roundIndex: 1)

        store.appendMoveSample(
            blockIndex: 0,
            roundIndex: 1,
            trickIndex: 0,
            moveIndexInTrick: 0,
            playerIndex: 0,
            playerCount: 4,
            cardsInRound: 2,
            trump: .clubs,
            playerBid: 1,
            playerTricksTakenBeforeMove: 0,
            handBeforeMove: [
                .regular(suit: .spades, rank: .ace),
                .regular(suit: .clubs, rank: .seven)
            ],
            legalCards: [
                .regular(suit: .spades, rank: .ace),
                .regular(suit: .clubs, rank: .seven)
            ],
            playedCardsInTrickBeforeMove: [],
            selectedCard: .regular(suit: .spades, rank: .ace),
            selectedJokerPlayStyle: .faceUp,
            selectedJokerLeadDeclaration: nil
        )

        store.appendMoveSample(
            blockIndex: 0,
            roundIndex: 1,
            trickIndex: 0,
            moveIndexInTrick: 1,
            playerIndex: 1,
            playerCount: 4,
            cardsInRound: 2,
            trump: .clubs,
            playerBid: 0,
            playerTricksTakenBeforeMove: 0,
            handBeforeMove: [
                .regular(suit: .spades, rank: .king),
                .regular(suit: .diamonds, rank: .queen)
            ],
            legalCards: [
                .regular(suit: .spades, rank: .king)
            ],
            playedCardsInTrickBeforeMove: [
                PlayedTrickCard(
                    playerIndex: 0,
                    card: .regular(suit: .spades, rank: .ace)
                )
            ],
            selectedCard: .regular(suit: .spades, rank: .king),
            selectedJokerPlayStyle: .faceUp,
            selectedJokerLeadDeclaration: nil
        )

        store.appendTrick(
            blockIndex: 0,
            roundIndex: 1,
            playedCards: [
                PlayedTrickCard(playerIndex: 0, card: .regular(suit: .spades, rank: .ace)),
                PlayedTrickCard(playerIndex: 1, card: .regular(suit: .spades, rank: .king))
            ],
            winnerPlayerIndex: 0
        )

        guard let history = store.history(blockIndex: 0, roundIndex: 1) else {
            XCTFail("Expected history for recorded deal")
            return
        }

        XCTAssertEqual(history.trainingSamples.count, 2)

        let first = history.trainingSamples[0]
        XCTAssertEqual(first.playerIndex, 0)
        XCTAssertEqual(first.trickWinnerPlayerIndex, 0)
        XCTAssertTrue(first.didPlayerWinTrick)
        XCTAssertEqual(first.handBeforeMove.count, 2)
        XCTAssertEqual(first.legalCards.count, 2)
        XCTAssertEqual(first.playedCardsInTrickBeforeMove.count, 0)
        XCTAssertEqual(first.selectedCard, .regular(suit: .spades, rank: .ace))

        let second = history.trainingSamples[1]
        XCTAssertEqual(second.playerIndex, 1)
        XCTAssertEqual(second.trickWinnerPlayerIndex, 0)
        XCTAssertFalse(second.didPlayerWinTrick)
        XCTAssertEqual(second.playedCardsInTrickBeforeMove.count, 1)
        XCTAssertEqual(second.legalCards, [.regular(suit: .spades, rank: .king)])
    }
}
