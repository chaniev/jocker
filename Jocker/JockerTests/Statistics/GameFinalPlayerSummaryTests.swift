//
//  GameFinalPlayerSummaryTests.swift
//  JockerTests
//
//  Created by Codex on 15.02.2026.
//

import XCTest
@testable import Jocker

final class GameFinalPlayerSummaryTests: XCTestCase {
    func testBuild_sortsByPlaceAndCalculatesPremiumAndBlindStats() {
        let playerNames = ["Али", "Борис", "Вика", "Гена"]

        let blockOne = makeBlockResult(
            finalScores: [100, 40, 20, 10],
            premiumPlayerIndices: [0],
            zeroPremiumPlayerIndices: []
        )
        let blockTwo = makeBlockResult(
            finalScores: [50, 90, -20, 30],
            premiumPlayerIndices: [1],
            zeroPremiumPlayerIndices: []
        )
        let blockThree = makeBlockResult(
            finalScores: [0, 10, 80, 40],
            premiumPlayerIndices: [],
            zeroPremiumPlayerIndices: [2]
        )
        let blockFour = makeBlockResult(
            finalScores: [20, -10, 60, 30],
            premiumPlayerIndices: [0, 2],
            zeroPremiumPlayerIndices: [],
            roundResults: [
                [roundResult(isBlind: true), roundResult(isBlind: false), roundResult(isBlind: true)],
                [roundResult(isBlind: false), roundResult(isBlind: false), roundResult(isBlind: false)],
                [roundResult(isBlind: true), roundResult(isBlind: true), roundResult(isBlind: false)],
                [roundResult(isBlind: false), roundResult(isBlind: true), roundResult(isBlind: false)]
            ]
        )

        let summaries = GameFinalPlayerSummary.build(
            playerNames: playerNames,
            playerCount: 4,
            completedBlocks: [blockOne, blockTwo, blockThree, blockFour]
        )

        XCTAssertEqual(summaries.map(\.playerName), ["Али", "Вика", "Борис", "Гена"])
        XCTAssertEqual(summaries.map(\.place), [1, 2, 3, 4])

        XCTAssertEqual(summaries[0].totalScore, 170)
        XCTAssertEqual(summaries[0].blockScores, [100, 50, 0, 20])
        XCTAssertEqual(summaries[0].premiumTakenByBlock, [true, false, false, true])
        XCTAssertEqual(summaries[0].totalPremiumsTaken, 2)
        XCTAssertEqual(summaries[0].fourthBlockBlindCount, 2)

        XCTAssertEqual(summaries[1].totalScore, 140)
        XCTAssertEqual(summaries[1].premiumTakenByBlock, [false, false, true, true])
        XCTAssertEqual(summaries[1].totalPremiumsTaken, 2)
        XCTAssertEqual(summaries[1].fourthBlockBlindCount, 2)

        XCTAssertEqual(summaries[2].totalScore, 130)
        XCTAssertEqual(summaries[2].premiumTakenByBlock, [false, true, false, false])
        XCTAssertEqual(summaries[2].totalPremiumsTaken, 1)
        XCTAssertEqual(summaries[2].fourthBlockBlindCount, 0)

        XCTAssertEqual(summaries[3].totalScore, 110)
        XCTAssertEqual(summaries[3].premiumTakenByBlock, [false, false, false, false])
        XCTAssertEqual(summaries[3].totalPremiumsTaken, 0)
        XCTAssertEqual(summaries[3].fourthBlockBlindCount, 1)
    }

    private func makeBlockResult(
        finalScores: [Int],
        premiumPlayerIndices: [Int],
        zeroPremiumPlayerIndices: [Int],
        roundResults: [[RoundResult]]? = nil
    ) -> BlockResult {
        let playerCount = finalScores.count
        let resolvedRoundResults = roundResults ?? Array(repeating: [], count: playerCount)

        return BlockResult(
            roundResults: resolvedRoundResults,
            baseScores: finalScores,
            premiumPlayerIndices: premiumPlayerIndices,
            premiumBonuses: Array(repeating: 0, count: playerCount),
            premiumPenalties: Array(repeating: 0, count: playerCount),
            zeroPremiumPlayerIndices: zeroPremiumPlayerIndices,
            zeroPremiumBonuses: Array(repeating: 0, count: playerCount),
            finalScores: finalScores
        )
    }

    private func roundResult(isBlind: Bool) -> RoundResult {
        return RoundResult(cardsInRound: 1, bid: 0, tricksTaken: 0, isBlind: isBlind)
    }
}
