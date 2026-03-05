//
//  HistoryModelsTests.swift
//  JockerTests
//
//  Created by Codex on 06.03.2026.
//

import XCTest
@testable import Jocker

final class HistoryModelsTests: XCTestCase {
    func testDealHistory_initialization_storesValues() {
        let key = DealHistoryKey(blockIndex: 1, roundIndex: 2)
        let trick = DealTrickHistory(
            moves: [DealTrickMove(playerIndex: 0, card: card(.hearts, .ace))],
            winnerPlayerIndex: 0
        )
        let sample = makeSample()

        let history = DealHistory(
            key: key,
            trump: .spades,
            initialHands: [[card(.hearts, .ace)]],
            tricks: [trick],
            trainingSamples: [sample]
        )

        XCTAssertEqual(history.key, key)
        XCTAssertEqual(history.trump, .spades)
        XCTAssertEqual(history.tricks.count, 1)
        XCTAssertEqual(history.trainingSamples.count, 1)
    }

    func testDealHistory_equatable_comparesAllFields() {
        let key = DealHistoryKey(blockIndex: 0, roundIndex: 0)
        let trick = DealTrickHistory(
            moves: [DealTrickMove(playerIndex: 0, card: card(.diamonds, .six))],
            winnerPlayerIndex: 0
        )
        let sample = makeSample()

        let lhs = DealHistory(key: key, trump: nil, initialHands: [[card(.diamonds, .six)]], tricks: [trick], trainingSamples: [sample])
        let rhs = DealHistory(key: key, trump: nil, initialHands: [[card(.diamonds, .six)]], tricks: [trick], trainingSamples: [sample])
        let different = DealHistory(key: key, trump: .clubs, initialHands: [[card(.diamonds, .six)]], tricks: [trick], trainingSamples: [sample])

        XCTAssertEqual(lhs, rhs)
        XCTAssertNotEqual(lhs, different)
    }

    func testDealHistoryKey_hashable_worksInSet() {
        let a = DealHistoryKey(blockIndex: 1, roundIndex: 2)
        let b = DealHistoryKey(blockIndex: 1, roundIndex: 2)
        let c = DealHistoryKey(blockIndex: 1, roundIndex: 3)

        XCTAssertEqual(Set([a, b, c]).count, 2)
    }

    func testDealTrickMove_regularCard_normalizesJokerFields() {
        let move = DealTrickMove(
            playerIndex: 1,
            card: card(.clubs, .king),
            jokerPlayStyle: .faceDown,
            jokerLeadDeclaration: .wish
        )

        XCTAssertEqual(move.jokerPlayStyle, .faceUp)
        XCTAssertNil(move.jokerLeadDeclaration)
    }

    func testDealTrickMove_joker_preservesJokerFields() {
        let move = DealTrickMove(
            playerIndex: 1,
            card: .joker,
            jokerPlayStyle: .faceDown,
            jokerLeadDeclaration: .above(suit: .spades)
        )

        XCTAssertEqual(move.jokerPlayStyle, .faceDown)
        XCTAssertEqual(move.jokerLeadDeclaration, .above(suit: .spades))
    }

    func testDealTrickHistory_initialization_storesMovesAndWinner() {
        let trick = DealTrickHistory(
            moves: [
                DealTrickMove(playerIndex: 0, card: card(.hearts, .ten)),
                DealTrickMove(playerIndex: 1, card: card(.hearts, .ace))
            ],
            winnerPlayerIndex: 1
        )

        XCTAssertEqual(trick.moves.count, 2)
        XCTAssertEqual(trick.winnerPlayerIndex, 1)
    }

    func testDealTrainingMoveSample_initialization_storesValues() {
        let sample = makeSample()

        XCTAssertEqual(sample.blockIndex, 1)
        XCTAssertEqual(sample.roundIndex, 2)
        XCTAssertEqual(sample.trickIndex, 0)
        XCTAssertEqual(sample.moveIndexInTrick, 1)
        XCTAssertEqual(sample.playerIndex, 3)
        XCTAssertEqual(sample.legalCards.count, 2)
        XCTAssertEqual(sample.selectedCard, card(.clubs, .king))
        XCTAssertEqual(sample.selectedJokerPlayStyle, .faceUp)
        XCTAssertEqual(sample.selectedJokerLeadDeclaration, nil)
        XCTAssertEqual(sample.trickWinnerPlayerIndex, 3)
        XCTAssertTrue(sample.didPlayerWinTrick)
    }

    private func card(_ suit: Suit, _ rank: Rank) -> Card {
        return .regular(suit: suit, rank: rank)
    }

    private func makeSample() -> DealTrainingMoveSample {
        return DealTrainingMoveSample(
            blockIndex: 1,
            roundIndex: 2,
            trickIndex: 0,
            moveIndexInTrick: 1,
            playerIndex: 3,
            playerCount: 4,
            cardsInRound: 9,
            trump: .spades,
            playerBid: 2,
            playerTricksTakenBeforeMove: 1,
            handBeforeMove: [card(.clubs, .king), .joker],
            legalCards: [card(.clubs, .king), .joker],
            playedCardsInTrickBeforeMove: [DealTrickMove(playerIndex: 0, card: card(.spades, .ace))],
            selectedCard: card(.clubs, .king),
            selectedJokerPlayStyle: .faceUp,
            selectedJokerLeadDeclaration: nil,
            trickWinnerPlayerIndex: 3,
            didPlayerWinTrick: true
        )
    }
}
