//
//  ScoreTableTapTargetResolverTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
@testable import Jocker

final class ScoreTableTapTargetResolverTests: XCTestCase {

    func testDealRowTarget_returnsNilForHeaderTap() {
        let resolver = makeResolver()

        let target = resolver.dealRowTarget(
            scrollViewTapLocationY: 10,
            contentTapLocation: CGPoint(x: 20, y: 40),
            contentWidth: 200
        )

        XCTAssertNil(target)
    }

    func testDealRowTarget_returnsNilForHorizontalOutOfBoundsTap() {
        let resolver = makeResolver()

        XCTAssertNil(
            resolver.dealRowTarget(
                scrollViewTapLocationY: 40,
                contentTapLocation: CGPoint(x: -1, y: 40),
                contentWidth: 200
            )
        )
        XCTAssertNil(
            resolver.dealRowTarget(
                scrollViewTapLocationY: 40,
                contentTapLocation: CGPoint(x: 201, y: 40),
                contentWidth: 200
            )
        )
    }

    func testDealRowTarget_returnsDealTargetForDealRowTap() {
        let resolver = makeResolver()

        let target = resolver.dealRowTarget(
            scrollViewTapLocationY: 40,
            contentTapLocation: CGPoint(x: 20, y: 40),
            contentWidth: 200
        )

        XCTAssertEqual(
            target,
            ScoreTableTapTargetResolver.DealRowTarget(blockIndex: 0, roundIndex: 0)
        )
    }

    func testDealRowTarget_returnsNilForSummaryRowTap() {
        let resolver = makeResolver()

        let target = resolver.dealRowTarget(
            scrollViewTapLocationY: 70,
            contentTapLocation: CGPoint(x: 20, y: 70),
            contentWidth: 200
        )

        XCTAssertNil(target)
    }

    func testDealRowTarget_returnsNilForTapOutsideRowMappings() {
        let resolver = makeResolver()

        let target = resolver.dealRowTarget(
            scrollViewTapLocationY: 500,
            contentTapLocation: CGPoint(x: 20, y: 500),
            contentWidth: 200
        )

        XCTAssertNil(target)
    }

    func testDealRowTarget_matchesCoordinatesProducedByLabelFrameResolver_forDealRow() {
        let resolver = makeResolver()
        let frameResolver = makeFrameResolver()
        let dealRowFrame = frameResolver.cardsLabelFrame(rowIndex: 2)
        let tapPoint = CGPoint(x: dealRowFrame.midX, y: dealRowFrame.midY)

        let target = resolver.dealRowTarget(
            scrollViewTapLocationY: tapPoint.y,
            contentTapLocation: tapPoint,
            contentWidth: 220
        )

        XCTAssertEqual(
            target,
            ScoreTableTapTargetResolver.DealRowTarget(blockIndex: 1, roundIndex: 0)
        )
    }

    func testDealRowTarget_returnsNilForSummaryRowCoordinatesProducedByLabelFrameResolver() {
        let resolver = makeResolver()
        let frameResolver = makeFrameResolver()
        let summaryRowFrame = frameResolver.cardsLabelFrame(rowIndex: 1)
        let tapPoint = CGPoint(x: summaryRowFrame.midX, y: summaryRowFrame.midY)

        let target = resolver.dealRowTarget(
            scrollViewTapLocationY: tapPoint.y,
            contentTapLocation: tapPoint,
            contentWidth: 220
        )

        XCTAssertNil(target)
    }

    private func makeResolver() -> ScoreTableTapTargetResolver {
        return ScoreTableTapTargetResolver(
            rowMappings: [
                ScoreTableView.RowMapping(kind: .deal(cards: 1), blockIndex: 0, roundIndex: 0),
                ScoreTableView.RowMapping(kind: .subtotal, blockIndex: 0, roundIndex: nil),
                ScoreTableView.RowMapping(kind: .deal(cards: 2), blockIndex: 1, roundIndex: 0)
            ],
            headerHeight: 28,
            rowHeight: 24
        )
    }

    private func makeFrameResolver() -> ScoreTableLabelFrameResolver {
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
