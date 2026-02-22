//
//  BotRankNormalizationTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
@testable import Jocker

final class BotRankNormalizationTests: XCTestCase {
    func testNormalizedForBidding_matchesLegacyFormulaForAllRanks() {
        for rank in Rank.allCases {
            let legacy = Double(rank.rawValue - 5) / 9.0
            XCTAssertEqual(
                BotRankNormalization.normalizedForBidding(rank),
                legacy,
                accuracy: 0.000_000_1,
                "Mismatch for rank \(rank)"
            )
        }
    }

    func testNormalizedForFutureProjection_matchesLegacyFormulaForAllRanks() {
        let span = Double(Rank.ace.rawValue - Rank.six.rawValue)
        for rank in Rank.allCases {
            let legacy = Double(rank.rawValue - Rank.six.rawValue) / max(1.0, span)
            XCTAssertEqual(
                BotRankNormalization.normalizedForFutureProjection(rank),
                legacy,
                accuracy: 0.000_000_1,
                "Mismatch for rank \(rank)"
            )
        }
    }

    func testNormalizedForTrumpSelection_matchesLegacyFormulaForAllRanks() {
        for rank in Rank.allCases {
            let legacy = Double(rank.rawValue - Rank.six.rawValue) / 8.0
            XCTAssertEqual(
                BotRankNormalization.normalizedForTrumpSelection(rank),
                legacy,
                accuracy: 0.000_000_1,
                "Mismatch for rank \(rank)"
            )
        }
    }

    func testIsHighCard_usesQueenThreshold() {
        XCTAssertFalse(BotRankNormalization.isHighCard(.jack))
        XCTAssertTrue(BotRankNormalization.isHighCard(.queen))
        XCTAssertTrue(BotRankNormalization.isHighCard(.king))
        XCTAssertTrue(BotRankNormalization.isHighCard(.ace))
    }
}
