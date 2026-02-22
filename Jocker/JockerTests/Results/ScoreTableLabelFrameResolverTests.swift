//
//  ScoreTableLabelFrameResolverTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
@testable import Jocker

final class ScoreTableLabelFrameResolverTests: XCTestCase {

    func testHeaderFrame_returnsExpectedFrameForDisplayIndex() {
        let resolver = makeResolver()

        XCTAssertEqual(
            resolver.headerFrame(displayIndex: 2),
            CGRect(x: 248, y: 0, width: 108, height: 28)
        )
    }

    func testCardsLabelFrame_returnsExpectedFrameForRowIndex() {
        let resolver = makeResolver()

        XCTAssertEqual(
            resolver.cardsLabelFrame(rowIndex: 3),
            CGRect(x: 0, y: 100, width: 32, height: 24)
        )
    }

    func testTricksAndPointsFrames_returnExpectedFrames() {
        let resolver = makeResolver()

        XCTAssertEqual(
            resolver.tricksLabelFrame(rowIndex: 1, displayIndex: 1),
            CGRect(x: 140, y: 52, width: 44, height: 24)
        )
        XCTAssertEqual(
            resolver.pointsLabelFrame(rowIndex: 1, displayIndex: 1),
            CGRect(x: 184, y: 52, width: 60, height: 24)
        )
    }

    func testPinnedHeaderFrame_preservesBaseFrameAndUpdatesOnlyY() {
        let resolver = makeResolver()
        let baseFrame = CGRect(x: 32, y: 0, width: 108, height: 28)

        XCTAssertEqual(
            resolver.pinnedHeaderFrame(from: baseFrame, contentOffsetY: 73.5),
            CGRect(x: 32, y: 73.5, width: 108, height: 28)
        )
    }

    private func makeResolver() -> ScoreTableLabelFrameResolver {
        return ScoreTableLabelFrameResolver(
            leftColumnWidth: 32,
            trickColumnWidth: 44,
            pointsColumnWidth: 64,
            headerHeight: 28,
            rowHeight: 24,
            pointsLabelTrailingInset: 4
        )
    }
}
