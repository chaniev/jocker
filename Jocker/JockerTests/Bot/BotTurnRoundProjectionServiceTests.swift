//
//  BotTurnRoundProjectionServiceTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
@testable import Jocker

final class BotTurnRoundProjectionServiceTests: XCTestCase {
    private let service = BotTurnRoundProjectionService(tuning: BotTuning(difficulty: .hard))

    func testNormalizedBid_clampsExplicitBidToRoundBounds() {
        let hand = [card(.hearts, .ace), card(.clubs, .king)]

        XCTAssertEqual(service.normalizedBid(bid: -3, handCards: hand, cardsInRound: 2, trump: nil), 0)
        XCTAssertEqual(service.normalizedBid(bid: 9, handCards: hand, cardsInRound: 2, trump: nil), 2)
        XCTAssertEqual(service.normalizedBid(bid: 1, handCards: hand, cardsInRound: 2, trump: nil), 1)
    }

    func testRemainingOpponentsCount_accountsForCardsAlreadyOnTable() {
        XCTAssertEqual(service.remainingOpponentsCount(playerCount: 4, cardsAlreadyOnTable: 0), 3)
        XCTAssertEqual(service.remainingOpponentsCount(playerCount: 4, cardsAlreadyOnTable: 2), 1)
        XCTAssertEqual(service.remainingOpponentsCount(playerCount: 3, cardsAlreadyOnTable: 2), 0)
    }

    func testRemainingHand_removesOnlyOneMatchingCard() {
        let hand: [Card] = [.joker, .joker, card(.spades, .ace)]

        let remaining = service.remainingHand(afterPlaying: .joker, from: hand)

        XCTAssertEqual(remaining.count, 2)
        XCTAssertEqual(remaining.filter { $0 == .joker }.count, 1)
        XCTAssertTrue(remaining.contains(card(.spades, .ace)))
    }

    func testExpectedRoundScore_matchesExactScoreForIntegerExpectedTricks() {
        let expected = service.expectedRoundScore(
            cardsInRound: 3,
            bid: 1,
            expectedTricks: 1.0
        )

        XCTAssertEqual(
            expected,
            Double(ScoreCalculator.calculateRoundScore(cardsInRound: 3, bid: 1, tricksTaken: 1, isBlind: false))
        )
    }

    func testExpectedRoundScore_interpolatesBetweenFloorAndCeilScores() {
        let value = service.expectedRoundScore(
            cardsInRound: 3,
            bid: 1,
            expectedTricks: 1.25
        )
        let lower = Double(ScoreCalculator.calculateRoundScore(cardsInRound: 3, bid: 1, tricksTaken: 1, isBlind: false))
        let upper = Double(ScoreCalculator.calculateRoundScore(cardsInRound: 3, bid: 1, tricksTaken: 2, isBlind: false))
        let expected = lower * 0.75 + upper * 0.25

        XCTAssertEqual(value, expected, accuracy: 0.0001)
    }

    func testProjectedFinalTricks_clampsToCardsInRound() {
        let projected = service.projectedFinalTricks(
            currentTricks: 2,
            immediateWinProbability: 1.0,
            remainingHand: [],
            trump: nil,
            cardsInRound: 2
        )

        XCTAssertEqual(projected, 2.0, accuracy: 0.0001)
    }

    private func card(_ suit: Suit, _ rank: Rank) -> Card {
        return .regular(suit: suit, rank: rank)
    }
}
