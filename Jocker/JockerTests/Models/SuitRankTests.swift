//
//  SuitRankTests.swift
//  JockerTests
//
//  Created by Codex on 06.03.2026.
//

import XCTest
@testable import Jocker

final class SuitRankTests: XCTestCase {
    func testSuit_allCases_hasFourSuits() {
        XCTAssertEqual(Suit.allCases.count, 4)
        XCTAssertEqual(Set(Suit.allCases), Set([.diamonds, .hearts, .spades, .clubs]))
    }

    func testSuitComparable_ordersByGameSortOrder() {
        let unordered: [Suit] = [.clubs, .hearts, .spades, .diamonds]

        XCTAssertEqual(unordered.sorted(), [.diamonds, .hearts, .spades, .clubs])
    }

    func testSuitName_returnsLocalizedName() {
        XCTAssertEqual(Suit.hearts.name, "Черви")
        XCTAssertEqual(Suit.spades.name, "Пики")
    }

    func testRank_allCases_hasExpectedCount() {
        XCTAssertEqual(Rank.allCases.count, 9)
        XCTAssertEqual(Rank.allCases.first, .six)
        XCTAssertEqual(Rank.allCases.last, .ace)
    }

    func testRankComparable_ordersByRawValue() {
        XCTAssertTrue(Rank.six < Rank.ten)
        XCTAssertTrue(Rank.king < Rank.ace)
    }

    func testRankSymbol_returnsCorrectSymbol() {
        XCTAssertEqual(Rank.ace.symbol, "A")
        XCTAssertEqual(Rank.ten.symbol, "10")
    }

    func testRankName_returnsCorrectName() {
        XCTAssertEqual(Rank.queen.name, "Дама")
        XCTAssertEqual(Rank.jack.name, "Валет")
    }
}
