//
//  PremiumRulesTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
@testable import Jocker

final class PremiumRulesTests: XCTestCase {

    func testFindPenaltyTarget_skipsPremiumPlayersAndWrapsAround() {
        let premiumPlayers: Set<Int> = [0, 1, 3]

        let target = PremiumRules.findPenaltyTarget(
            for: 3,
            premiumPlayers: premiumPlayers,
            playerCount: 4
        )

        XCTAssertEqual(target, 2)
    }

    func testFindPenaltyTarget_returnsNilWhenAllOtherPlayersHavePremium() {
        let premiumPlayers: Set<Int> = [0, 1, 2, 3]

        let target = PremiumRules.findPenaltyTarget(
            for: 0,
            premiumPlayers: premiumPlayers,
            playerCount: 4
        )

        XCTAssertNil(target)
    }

    func testFinalizeBlockScores_regularPremiumAppliesBonusAndPenaltyToLeftNeighbor() {
        let roundsByPlayer = roundsByPlayer([
            [
                matchedResult(bid: 1, cardsInRound: 1),
                matchedResult(bid: 0, cardsInRound: 1),
                matchedResult(bid: 0, cardsInRound: 1),
                matchedResult(bid: 0, cardsInRound: 1)
            ],
            [
                matchedResult(bid: 1, cardsInRound: 2),
                mismatchedResult(bid: 1, tricksTaken: 2, cardsInRound: 2),
                matchedResult(bid: 1, cardsInRound: 2),
                mismatchedResult(bid: 1, tricksTaken: 0, cardsInRound: 2)
            ],
            [
                matchedResult(bid: 2, cardsInRound: 3),
                matchedResult(bid: 1, cardsInRound: 3),
                mismatchedResult(bid: 2, tricksTaken: 0, cardsInRound: 3),
                matchedResult(bid: 0, cardsInRound: 3)
            ]
        ])

        let outcome = PremiumRules.finalizeBlockScores(
            blockRoundResults: roundsByPlayer,
            blockNumber: GameBlock.second.rawValue,
            playerCount: 4
        )

        XCTAssertEqual(outcome.regularPremiumPlayers, [0])
        XCTAssertTrue(outcome.zeroPremiumPlayers.isEmpty)
        XCTAssertEqual(outcome.premiumBonuses[0], 100)
        XCTAssertEqual(outcome.zeroPremiumBonuses[0], 0)
        XCTAssertEqual(outcome.premiumPenalties, [0, 50, 0, 0])
        XCTAssertEqual(outcome.premiumPenaltyRoundIndices[1], 0)
        XCTAssertEqual(outcome.premiumPenaltyRoundScores[1], 50)
        XCTAssertEqual(outcome.roundsWithPremiums[0][2].score, 250)
        XCTAssertEqual(outcome.baseBlockScores, [450, 170, 0, 0])
        XCTAssertEqual(outcome.finalScores, [450, 120, 0, 0])
    }

    func testFinalizeBlockScores_zeroPremiumInBlockOneIsExclusiveWithRegularPremium() {
        let roundsByPlayer = roundsByPlayer([
            [
                matchedResult(bid: 1, cardsInRound: 1),
                matchedResult(bid: 0, cardsInRound: 1),
                matchedResult(bid: 0, cardsInRound: 1),
                matchedResult(bid: 0, cardsInRound: 1)
            ],
            [
                matchedResult(bid: 1, cardsInRound: 2),
                matchedResult(bid: 0, cardsInRound: 2),
                mismatchedResult(bid: 1, tricksTaken: 2, cardsInRound: 2),
                matchedResult(bid: 1, cardsInRound: 2)
            ],
            [
                matchedResult(bid: 2, cardsInRound: 3),
                matchedResult(bid: 0, cardsInRound: 3),
                matchedResult(bid: 1, cardsInRound: 3),
                matchedResult(bid: 0, cardsInRound: 3)
            ]
        ])

        let outcome = PremiumRules.finalizeBlockScores(
            blockRoundResults: roundsByPlayer,
            blockNumber: GameBlock.first.rawValue,
            playerCount: 4
        )

        XCTAssertTrue(outcome.allPremiumPlayers.contains(1))
        XCTAssertTrue(outcome.zeroPremiumPlayers.contains(1))
        XCTAssertFalse(outcome.regularPremiumPlayers.contains(1))
        XCTAssertEqual(outcome.zeroPremiumBonuses[1], ScoreCalculator.zeroPremiumAmount)
        XCTAssertEqual(outcome.premiumBonuses[1], 0)
        XCTAssertEqual(outcome.roundsWithPremiums[1][2].score, 550)
        XCTAssertEqual(outcome.baseBlockScores[1], 650)
    }

    func testFinalizeBlockScores_penaltyMetadataUsesEarliestPositiveRound() {
        let roundsByPlayer = roundsByPlayer([
            [
                matchedResult(bid: 1, cardsInRound: 1),
                matchedResult(bid: 1, cardsInRound: 1),
                mismatchedResult(bid: 0, tricksTaken: 1, cardsInRound: 1),
                mismatchedResult(bid: 0, tricksTaken: 1, cardsInRound: 1)
            ],
            [
                matchedResult(bid: 1, cardsInRound: 2),
                matchedResult(bid: 1, cardsInRound: 2),
                mismatchedResult(bid: 1, tricksTaken: 0, cardsInRound: 2),
                matchedResult(bid: 0, cardsInRound: 2)
            ],
            [
                matchedResult(bid: 1, cardsInRound: 3),
                mismatchedResult(bid: 2, tricksTaken: 0, cardsInRound: 3),
                matchedResult(bid: 1, cardsInRound: 3),
                mismatchedResult(bid: 0, tricksTaken: 2, cardsInRound: 3)
            ]
        ])

        let outcome = PremiumRules.finalizeBlockScores(
            blockRoundResults: roundsByPlayer,
            blockNumber: GameBlock.first.rawValue,
            playerCount: 4
        )

        XCTAssertEqual(outcome.regularPremiumPlayers, [0])
        XCTAssertEqual(outcome.premiumPenalties[1], 100)
        XCTAssertEqual(outcome.premiumPenaltyRoundIndices[1], 0)
        XCTAssertEqual(outcome.premiumPenaltyRoundScores[1], 100)
    }

    func testFinalizeBlockScores_zeroPlayersReturnsEmptyOutcome() {
        let outcome = PremiumRules.finalizeBlockScores(
            blockRoundResults: [],
            blockNumber: 0,
            playerCount: 0
        )

        XCTAssertTrue(outcome.roundsWithPremiums.isEmpty)
        XCTAssertTrue(outcome.baseBlockScores.isEmpty)
        XCTAssertTrue(outcome.finalScores.isEmpty)
        XCTAssertTrue(outcome.allPremiumPlayers.isEmpty)
        XCTAssertTrue(outcome.regularPremiumPlayers.isEmpty)
        XCTAssertTrue(outcome.zeroPremiumPlayers.isEmpty)
        XCTAssertTrue(outcome.premiumBonuses.isEmpty)
        XCTAssertTrue(outcome.zeroPremiumBonuses.isEmpty)
        XCTAssertTrue(outcome.premiumPenalties.isEmpty)
        XCTAssertTrue(outcome.premiumPenaltyRoundIndices.isEmpty)
        XCTAssertTrue(outcome.premiumPenaltyRoundScores.isEmpty)
    }

    // MARK: - Helpers

    private func matchedResult(bid: Int, cardsInRound: Int, isBlind: Bool = false) -> RoundResult {
        return RoundResult(cardsInRound: cardsInRound, bid: bid, tricksTaken: bid, isBlind: isBlind)
    }

    private func mismatchedResult(
        bid: Int,
        tricksTaken: Int,
        cardsInRound: Int,
        isBlind: Bool = false
    ) -> RoundResult {
        return RoundResult(
            cardsInRound: cardsInRound,
            bid: bid,
            tricksTaken: tricksTaken,
            isBlind: isBlind
        )
    }

    /// Converts per-round rows (`[round][player]`) into `PremiumRules` input (`[player][round]`).
    private func roundsByPlayer(_ roundsByRound: [[RoundResult]]) -> [[RoundResult]] {
        guard let firstRound = roundsByRound.first else { return [] }
        var result = Array(repeating: [RoundResult](), count: firstRound.count)
        for round in roundsByRound {
            XCTAssertEqual(round.count, firstRound.count)
            for (playerIndex, roundResult) in round.enumerated() {
                result[playerIndex].append(roundResult)
            }
        }
        return result
    }
}
