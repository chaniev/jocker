//
//  ScoreTableRowPresentationResolverTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
@testable import Jocker

final class ScoreTableRowPresentationResolverTests: XCTestCase {

    func testCardsLabelText_returnsCardCountForDealRow() {
        let resolver = ScoreTableRowPresentationResolver()

        XCTAssertEqual(resolver.cardsLabelText(for: .deal(cards: 7)), "7")
    }

    func testCardsLabelText_returnsEmptyForSummaryRows() {
        let resolver = ScoreTableRowPresentationResolver()

        XCTAssertEqual(resolver.cardsLabelText(for: .subtotal), "")
        XCTAssertEqual(resolver.cardsLabelText(for: .cumulative), "")
    }

    func testPointsLabelStyle_returnsRegularForDealRows() {
        let resolver = ScoreTableRowPresentationResolver()

        XCTAssertEqual(resolver.pointsLabelStyle(for: .deal(cards: 3)), .regular)
    }

    func testPointsLabelStyle_returnsSummaryForSubtotalAndCumulativeRows() {
        let resolver = ScoreTableRowPresentationResolver()

        XCTAssertEqual(resolver.pointsLabelStyle(for: .subtotal), .summary)
        XCTAssertEqual(resolver.pointsLabelStyle(for: .cumulative), .summary)
    }
}
