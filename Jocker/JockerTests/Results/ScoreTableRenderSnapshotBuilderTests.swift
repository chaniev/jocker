//
//  ScoreTableRenderSnapshotBuilderTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
@testable import Jocker

final class ScoreTableRenderSnapshotBuilderTests: XCTestCase {

    func testMakeDecorationsSnapshot_buildsPenaltyStrikeCellFromCompletedBlockPenaltyMetadata() {
        let rowMappings = [
            ScoreTableView.RowMapping(kind: .deal(cards: 2), blockIndex: 0, roundIndex: 0),
            ScoreTableView.RowMapping(kind: .deal(cards: 2), blockIndex: 0, roundIndex: 1),
            ScoreTableView.RowMapping(kind: .subtotal, blockIndex: 0, roundIndex: nil)
        ]
        let builder = ScoreTableRenderSnapshotBuilder(
            playerCount: 2,
            rowMappings: rowMappings
        )

        let player0Rounds = [
            RoundResult(cardsInRound: 2, bid: 0, tricksTaken: 0, isBlind: false),
            RoundResult(cardsInRound: 2, bid: 1, tricksTaken: 1, isBlind: false)
        ]
        let player1PenaltyRound = RoundResult(cardsInRound: 2, bid: 2, tricksTaken: 2, isBlind: false)
        let player1Rounds = [
            RoundResult(cardsInRound: 2, bid: 1, tricksTaken: 1, isBlind: false),
            player1PenaltyRound
        ]

        let completedBlock = makeBlockResult(
            roundResults: [player0Rounds, player1Rounds],
            premiumPlayerIndices: [],
            zeroPremiumPlayerIndices: [],
            premiumPenaltyRoundIndices: [nil, 1],
            premiumPenaltyRoundScores: [0, player1PenaltyRound.score]
        )

        let snapshot = ScoreTableRenderSnapshotBuilder.ScoreDataSnapshot(
            completedBlocks: [completedBlock],
            currentBlockResults: [],
            currentBlockScores: [0, 0]
        )
        let decorations = builder.makeDecorationsSnapshot(from: snapshot)

        XCTAssertEqual(
            decorations.penaltyStrikeCells,
            [ScoreTableRenderSnapshotBuilder.ScoreDecorationsSnapshot.PenaltyStrikeCell(rowIndex: 1, playerIndex: 1)]
        )
    }

    func testMakeDecorationsSnapshot_buildsTrophyAndPremiumLossMarksWithSingleAndDoubleSummaryRanges() {
        let rowMappings = [
            ScoreTableView.RowMapping(kind: .deal(cards: 1), blockIndex: 0, roundIndex: 0),
            ScoreTableView.RowMapping(kind: .subtotal, blockIndex: 0, roundIndex: nil),
            ScoreTableView.RowMapping(kind: .deal(cards: 2), blockIndex: 1, roundIndex: 0),
            ScoreTableView.RowMapping(kind: .deal(cards: 2), blockIndex: 1, roundIndex: 1),
            ScoreTableView.RowMapping(kind: .subtotal, blockIndex: 1, roundIndex: nil),
            ScoreTableView.RowMapping(kind: .cumulative, blockIndex: 1, roundIndex: nil)
        ]
        let builder = ScoreTableRenderSnapshotBuilder(
            playerCount: 2,
            rowMappings: rowMappings
        )

        let block0 = makeBlockResult(
            roundResults: [[
                RoundResult(cardsInRound: 1, bid: 0, tricksTaken: 0, isBlind: false)
            ], [
                RoundResult(cardsInRound: 1, bid: 1, tricksTaken: 1, isBlind: false)
            ]],
            premiumPlayerIndices: [0],
            zeroPremiumPlayerIndices: [],
            premiumPenaltyRoundIndices: [nil, nil],
            premiumPenaltyRoundScores: [0, 0]
        )

        let block1 = makeBlockResult(
            roundResults: [[
                RoundResult(cardsInRound: 2, bid: 0, tricksTaken: 0, isBlind: false),
                RoundResult(cardsInRound: 2, bid: 1, tricksTaken: 1, isBlind: false)
            ], [
                RoundResult(cardsInRound: 2, bid: 1, tricksTaken: 0, isBlind: false),
                RoundResult(cardsInRound: 2, bid: 1, tricksTaken: 1, isBlind: false)
            ]],
            premiumPlayerIndices: [0],
            zeroPremiumPlayerIndices: [],
            premiumPenaltyRoundIndices: [nil, nil],
            premiumPenaltyRoundScores: [0, 0]
        )

        let snapshot = ScoreTableRenderSnapshotBuilder.ScoreDataSnapshot(
            completedBlocks: [block0, block1],
            currentBlockResults: [],
            currentBlockScores: [0, 0]
        )
        let decorations = builder.makeDecorationsSnapshot(from: snapshot)
        let marks = decorations.columnMarks

        XCTAssertTrue(
            marks.contains(
                ScoreTableRenderSnapshotBuilder.ScoreDecorationsSnapshot.ColumnMark(
                    playerIndex: 0,
                    topSummaryRowIndex: 1,
                    bottomSummaryRowIndex: 1,
                    kind: .trophy
                )
            ),
            "First block should map to a single summary row"
        )

        XCTAssertTrue(
            marks.contains(
                ScoreTableRenderSnapshotBuilder.ScoreDecorationsSnapshot.ColumnMark(
                    playerIndex: 0,
                    topSummaryRowIndex: 4,
                    bottomSummaryRowIndex: 5,
                    kind: .trophy
                )
            ),
            "Second block premium should span subtotal + cumulative rows"
        )

        XCTAssertTrue(
            marks.contains(
                ScoreTableRenderSnapshotBuilder.ScoreDecorationsSnapshot.ColumnMark(
                    playerIndex: 1,
                    topSummaryRowIndex: 4,
                    bottomSummaryRowIndex: 5,
                    kind: .premiumLoss
                )
            ),
            "Mismatched player should receive premium-loss mark over the summary range"
        )
    }

    private func makeBlockResult(
        roundResults: [[RoundResult]],
        premiumPlayerIndices: [Int],
        zeroPremiumPlayerIndices: [Int],
        premiumPenaltyRoundIndices: [Int?],
        premiumPenaltyRoundScores: [Int]
    ) -> BlockResult {
        let playerCount = roundResults.count
        let zeroArray = Array(repeating: 0, count: playerCount)

        return BlockResult(
            roundResults: roundResults,
            baseScores: zeroArray,
            premiumPlayerIndices: premiumPlayerIndices,
            premiumBonuses: zeroArray,
            premiumPenalties: zeroArray,
            premiumPenaltyRoundIndices: premiumPenaltyRoundIndices,
            premiumPenaltyRoundScores: premiumPenaltyRoundScores,
            zeroPremiumPlayerIndices: zeroPremiumPlayerIndices,
            zeroPremiumBonuses: zeroArray,
            finalScores: zeroArray
        )
    }
}
