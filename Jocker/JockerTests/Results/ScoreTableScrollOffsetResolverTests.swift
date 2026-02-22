//
//  ScoreTableScrollOffsetResolverTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
@testable import Jocker

final class ScoreTableScrollOffsetResolverTests: XCTestCase {

    func testTargetOffsetY_centersRowWhenWithinScrollableRange() {
        let resolver = ScoreTableScrollOffsetResolver(headerHeight: 28, rowHeight: 24)

        let offsetY = resolver.targetOffsetY(
            forRowIndex: 4,
            visibleHeight: 200,
            contentHeight: 600
        )

        XCTAssertEqual(offsetY, 36, accuracy: 0.0001)
    }

    func testTargetOffsetY_clampsToTop() {
        let resolver = ScoreTableScrollOffsetResolver(headerHeight: 28, rowHeight: 24)

        let offsetY = resolver.targetOffsetY(
            forRowIndex: 0,
            visibleHeight: 220,
            contentHeight: 500
        )

        XCTAssertEqual(offsetY, 0, accuracy: 0.0001)
    }

    func testTargetOffsetY_clampsToBottom() {
        let resolver = ScoreTableScrollOffsetResolver(headerHeight: 28, rowHeight: 24)

        let offsetY = resolver.targetOffsetY(
            forRowIndex: 20,
            visibleHeight: 180,
            contentHeight: 420
        )

        XCTAssertEqual(offsetY, 240, accuracy: 0.0001)
    }

    func testTargetOffsetY_usesSafeVisibleHeightWhenZero() {
        let resolver = ScoreTableScrollOffsetResolver(headerHeight: 28, rowHeight: 24)

        let offsetY = resolver.targetOffsetY(
            forRowIndex: 1,
            visibleHeight: 0,
            contentHeight: 100
        )

        XCTAssertEqual(offsetY, 63.5, accuracy: 0.0001)
    }
}
