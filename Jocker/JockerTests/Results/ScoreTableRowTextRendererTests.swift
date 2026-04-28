//
//  ScoreTableRowTextRendererTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
@testable import Jocker

final class ScoreTableRowTextRendererTests: XCTestCase {

    func testMakeSnapshot_rendersCompletedDealRowWithBlindCircledBid() {
        let rowMappings = [
            ScoreTableView.RowMapping(kind: .deal(cards: 2), blockIndex: 0, roundIndex: 0)
        ]
        let renderer = ScoreTableRowTextRenderer(
            playerCount: 2,
            playerDisplayOrder: [0, 1],
            rowMappings: rowMappings
        )

        let blindResult = RoundResult(cardsInRound: 2, bid: 2, tricksTaken: 2, isBlind: true)
        let regularResult = RoundResult(cardsInRound: 2, bid: 1, tricksTaken: 1, isBlind: false)
        let snapshot = renderer.makeSnapshot(
            dataSnapshot: ScoreTableRenderSnapshotBuilder.ScoreDataSnapshot(
                completedBlocks: [
                    makeBlockResult(
                        roundResults: [[blindResult], [regularResult]],
                        finalScores: [0, 0]
                    )
                ],
                currentBlockResults: [],
                currentBlockScores: [0, 0]
            ),
            inProgressRoundSnapshot: .empty
        )

        XCTAssertEqual(snapshot.cardsTexts, ["2"])
        XCTAssertEqual(snapshot.tricksTexts, [["②/2", "1/1"]])
        XCTAssertEqual(
            snapshot.pointsTexts,
            [["\(blindResult.score)", "\(regularResult.score)"]]
        )
    }

    func testMakeSnapshot_rendersInProgressOverlayWithZeroPointsAndZeroDisplayedTricks() {
        let rowMappings = [
            ScoreTableView.RowMapping(kind: .deal(cards: 3), blockIndex: 0, roundIndex: 0)
        ]
        let renderer = ScoreTableRowTextRenderer(
            playerCount: 2,
            playerDisplayOrder: [0, 1],
            rowMappings: rowMappings
        )

        let inProgressSnapshot = ScoreTableInProgressRoundSnapshotProvider.Snapshot(
            roundResultsByCell: [
                ScoreTableInProgressRoundSnapshotProvider.Cell(rowIndex: 0, playerIndex: 0):
                    RoundResult(cardsInRound: 3, bid: 1, tricksTaken: 1, isBlind: false),
                ScoreTableInProgressRoundSnapshotProvider.Cell(rowIndex: 0, playerIndex: 1):
                    RoundResult(cardsInRound: 3, bid: 3, tricksTaken: 2, isBlind: true)
            ]
        )

        let snapshot = renderer.makeSnapshot(
            dataSnapshot: ScoreTableRenderSnapshotBuilder.ScoreDataSnapshot(
                completedBlocks: [],
                currentBlockResults: [],
                currentBlockScores: [0, 0]
            ),
            inProgressRoundSnapshot: inProgressSnapshot
        )

        XCTAssertEqual(snapshot.cardsTexts, ["3"])
        XCTAssertEqual(snapshot.tricksTexts, [["1/0", "③/0"]])
        XCTAssertEqual(snapshot.pointsTexts, [["0", "0"]])
    }

    func testMakeSnapshot_rendersSubtotalAndCumulativeRowsWithDisplayOrderAndRuFormatting() {
        let rowMappings = [
            ScoreTableView.RowMapping(kind: .deal(cards: 1), blockIndex: 0, roundIndex: 0),
            ScoreTableView.RowMapping(kind: .subtotal, blockIndex: 0, roundIndex: nil),
            ScoreTableView.RowMapping(kind: .deal(cards: 2), blockIndex: 1, roundIndex: 0),
            ScoreTableView.RowMapping(kind: .subtotal, blockIndex: 1, roundIndex: nil),
            ScoreTableView.RowMapping(kind: .cumulative, blockIndex: 1, roundIndex: nil)
        ]
        let renderer = ScoreTableRowTextRenderer(
            playerCount: 2,
            playerDisplayOrder: [1, 0],
            rowMappings: rowMappings
        )

        let completedBlock = makeBlockResult(
            roundResults: [[
                RoundResult(cardsInRound: 1, bid: 0, tricksTaken: 0, isBlind: false)
            ], [
                RoundResult(cardsInRound: 1, bid: 1, tricksTaken: 1, isBlind: false)
            ]],
            finalScores: [120, -50]
        )

        let snapshot = renderer.makeSnapshot(
            dataSnapshot: ScoreTableRenderSnapshotBuilder.ScoreDataSnapshot(
                completedBlocks: [completedBlock],
                currentBlockResults: [],
                currentBlockScores: [80, 20]
            ),
            inProgressRoundSnapshot: .empty
        )

        XCTAssertEqual(snapshot.cardsTexts[0], "1")
        XCTAssertEqual(snapshot.cardsTexts[1], "")
        XCTAssertEqual(snapshot.cardsTexts[3], "")
        XCTAssertEqual(snapshot.pointsTexts[1], ["-0,5", "1,2"])
        XCTAssertEqual(snapshot.pointsTexts[3], ["0,2", "0,8"])
        XCTAssertEqual(snapshot.pointsTexts[4], ["-0,3", "2,0"])
        XCTAssertEqual(snapshot.tricksTexts[1], ["", ""])
        XCTAssertEqual(snapshot.tricksTexts[3], ["", ""])
        XCTAssertEqual(snapshot.tricksTexts[4], ["", ""])
    }

    func testMakeSnapshot_pairsMode_rendersTeamTotalsInSummaryCardsColumn() {
        let rowMappings = [
            ScoreTableView.RowMapping(kind: .deal(cards: 1), blockIndex: 0, roundIndex: 0),
            ScoreTableView.RowMapping(kind: .subtotal, blockIndex: 0, roundIndex: nil),
            ScoreTableView.RowMapping(kind: .cumulative, blockIndex: 0, roundIndex: nil)
        ]
        let renderer = ScoreTableRowTextRenderer(
            playerCount: 4,
            gameMode: .pairs,
            playerDisplayOrder: [0, 1, 2, 3],
            rowMappings: rowMappings
        )

        let completedBlock = makeBlockResult(
            roundResults: Array(repeating: [
                RoundResult(cardsInRound: 1, bid: 0, tricksTaken: 0, isBlind: false)
            ], count: 4),
            finalScores: [120, -40, 80, 20]
        )

        let snapshot = renderer.makeSnapshot(
            dataSnapshot: ScoreTableRenderSnapshotBuilder.ScoreDataSnapshot(
                completedBlocks: [completedBlock],
                currentBlockResults: [],
                currentBlockScores: [0, 0, 0, 0]
            ),
            inProgressRoundSnapshot: .empty
        )

        XCTAssertEqual(snapshot.cardsTexts[1], "1+3: 2,0\n2+4: -0,2")
        XCTAssertEqual(snapshot.cardsTexts[2], "1+3: 2,0\n2+4: -0,2")
    }

    private func makeBlockResult(
        roundResults: [[RoundResult]],
        finalScores: [Int]
    ) -> BlockResult {
        let playerCount = roundResults.count
        let zeroArray = Array(repeating: 0, count: playerCount)

        return BlockResult(
            roundResults: roundResults,
            baseScores: zeroArray,
            premiumPlayerIndices: [],
            premiumBonuses: zeroArray,
            premiumPenalties: zeroArray,
            premiumPenaltyRoundIndices: Array(repeating: nil, count: playerCount),
            premiumPenaltyRoundScores: zeroArray,
            zeroPremiumPlayerIndices: [],
            zeroPremiumBonuses: zeroArray,
            finalScores: finalScores
        )
    }
}
