//
//  ScoreTableInProgressRoundSnapshotProviderTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
@testable import Jocker

final class ScoreTableInProgressRoundSnapshotProviderTests: XCTestCase {

    func testMakeSnapshot_returnsEmptyWhenScoreManagerHasNoInProgressRound() {
        let provider = ScoreTableInProgressRoundSnapshotProvider(
            playerCount: 2,
            rowMappings: [
                ScoreTableView.RowMapping(kind: .deal(cards: 1), blockIndex: 0, roundIndex: 0),
                ScoreTableView.RowMapping(kind: .subtotal, blockIndex: 0, roundIndex: nil)
            ]
        )
        let scoreManager = ScoreManager(playerCount: 2)

        let snapshot = provider.makeSnapshot(from: scoreManager)

        XCTAssertEqual(snapshot.roundResultsByCell.count, 0)
    }

    func testMakeSnapshot_includesOnlyMatchingDealRowsForCurrentInProgressRound() {
        let rowMappings = [
            ScoreTableView.RowMapping(kind: .deal(cards: 1), blockIndex: 0, roundIndex: 0),
            ScoreTableView.RowMapping(kind: .subtotal, blockIndex: 0, roundIndex: nil),
            ScoreTableView.RowMapping(kind: .deal(cards: 2), blockIndex: 1, roundIndex: 0),
            ScoreTableView.RowMapping(kind: .deal(cards: 2), blockIndex: 1, roundIndex: 1),
            ScoreTableView.RowMapping(kind: .cumulative, blockIndex: 1, roundIndex: nil)
        ]
        let provider = ScoreTableInProgressRoundSnapshotProvider(
            playerCount: 2,
            rowMappings: rowMappings
        )
        let scoreManager = ScoreManager(playerCount: 2)
        let inProgressResults = [
            RoundResult(cardsInRound: 2, bid: 0, tricksTaken: 0, isBlind: false),
            RoundResult(cardsInRound: 2, bid: 1, tricksTaken: 0, isBlind: true)
        ]
        scoreManager.setInProgressRoundResults(inProgressResults, blockIndex: 1, roundIndex: 1)

        let snapshot = provider.makeSnapshot(from: scoreManager)

        XCTAssertEqual(snapshot.roundResultsByCell.count, 2)
        XCTAssertEqual(
            snapshot.roundResultsByCell[
                ScoreTableInProgressRoundSnapshotProvider.Cell(rowIndex: 3, playerIndex: 0)
            ]?.bid,
            0
        )
        XCTAssertEqual(
            snapshot.roundResultsByCell[
                ScoreTableInProgressRoundSnapshotProvider.Cell(rowIndex: 3, playerIndex: 1)
            ]?.isBlind,
            true
        )

        XCTAssertNil(
            snapshot.roundResultsByCell[
                ScoreTableInProgressRoundSnapshotProvider.Cell(rowIndex: 0, playerIndex: 0)
            ],
            "Different block/round should not be included"
        )
        XCTAssertNil(
            snapshot.roundResultsByCell[
                ScoreTableInProgressRoundSnapshotProvider.Cell(rowIndex: 1, playerIndex: 0)
            ],
            "Summary rows should never produce in-progress cells"
        )
    }
}
