//
//  ScoreTableRowNavigationResolverTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
@testable import Jocker

final class ScoreTableRowNavigationResolverTests: XCTestCase {

    func testTargetDealRowIndex_returnsExactMatchForRequestedRound() {
        let resolver = ScoreTableRowNavigationResolver(
            rowMappings: [
                ScoreTableView.RowMapping(kind: .deal(cards: 1), blockIndex: 0, roundIndex: 0),
                ScoreTableView.RowMapping(kind: .deal(cards: 2), blockIndex: 0, roundIndex: 1),
                ScoreTableView.RowMapping(kind: .subtotal, blockIndex: 0, roundIndex: nil)
            ]
        )

        XCTAssertEqual(resolver.targetDealRowIndex(blockIndex: 0, roundIndex: 1), 1)
    }

    func testTargetDealRowIndex_clampsNegativeAndTooLargeRoundIndices() {
        let resolver = ScoreTableRowNavigationResolver(
            rowMappings: [
                ScoreTableView.RowMapping(kind: .deal(cards: 1), blockIndex: 0, roundIndex: 0),
                ScoreTableView.RowMapping(kind: .deal(cards: 2), blockIndex: 0, roundIndex: 1),
                ScoreTableView.RowMapping(kind: .deal(cards: 3), blockIndex: 0, roundIndex: 2)
            ]
        )

        XCTAssertEqual(resolver.targetDealRowIndex(blockIndex: 0, roundIndex: -3), 0)
        XCTAssertEqual(resolver.targetDealRowIndex(blockIndex: 0, roundIndex: 99), 2)
    }

    func testTargetDealRowIndex_fallsBackToPositionalDealRowWhenRoundIndicesAreSparse() {
        let resolver = ScoreTableRowNavigationResolver(
            rowMappings: [
                ScoreTableView.RowMapping(kind: .deal(cards: 2), blockIndex: 0, roundIndex: 0),
                ScoreTableView.RowMapping(kind: .subtotal, blockIndex: 0, roundIndex: nil),
                ScoreTableView.RowMapping(kind: .deal(cards: 2), blockIndex: 0, roundIndex: 2)
            ]
        )

        XCTAssertEqual(
            resolver.targetDealRowIndex(blockIndex: 0, roundIndex: 1),
            2,
            "Sparse round indices should fallback to clamped positional deal row"
        )
    }

    func testTargetDealRowIndex_returnsNilForMissingBlock() {
        let resolver = ScoreTableRowNavigationResolver(
            rowMappings: [
                ScoreTableView.RowMapping(kind: .deal(cards: 1), blockIndex: 0, roundIndex: 0)
            ]
        )

        XCTAssertNil(resolver.targetDealRowIndex(blockIndex: 1, roundIndex: 0))
    }

    func testTargetSummaryRowIndex_returnsLastSummaryRowForBlock() {
        let resolver = ScoreTableRowNavigationResolver(
            rowMappings: [
                ScoreTableView.RowMapping(kind: .deal(cards: 1), blockIndex: 0, roundIndex: 0),
                ScoreTableView.RowMapping(kind: .subtotal, blockIndex: 0, roundIndex: nil),
                ScoreTableView.RowMapping(kind: .cumulative, blockIndex: 0, roundIndex: nil)
            ]
        )

        XCTAssertEqual(resolver.targetSummaryRowIndex(blockIndex: 0), 2)
        XCTAssertNil(resolver.targetSummaryRowIndex(blockIndex: 2))
    }
}
