//
//  ScoreTableLabelFrameResolverTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
import UIKit
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

    func testLabelManager_updateColumnWidths_rebuildsFramesForExpandedPointsColumn() {
        let manager = ScoreTableLabelManager(
            playerCount: 2,
            playerDisplayOrder: [0, 1],
            rowMappings: [ScoreTableView.RowMapping(kind: .deal(cards: 1), blockIndex: 0, roundIndex: 0)],
            headerHeight: 28,
            rowHeight: 24,
            leftColumnWidth: 36,
            trickColumnWidth: 44,
            pointsColumnWidth: 64
        )
        let contentView = UIView()
        manager.buildLabels(in: contentView)
        manager.updateHeaderFrames()
        manager.updateRowFrames()

        XCTAssertEqual(manager.headerLabels[1].frame, CGRect(x: 144, y: 0, width: 108, height: 28))
        XCTAssertEqual(manager.pointsLabels[0][1].frame, CGRect(x: 188, y: 28, width: 60, height: 24))

        manager.updateColumnWidths(leftColumnWidth: 36, trickColumnWidth: 44, pointsColumnWidth: 200)
        manager.updateHeaderFrames()
        manager.updateRowFrames()

        XCTAssertEqual(manager.headerLabels[1].frame, CGRect(x: 280, y: 0, width: 244, height: 28))
        XCTAssertEqual(manager.pointsLabels[0][1].frame, CGRect(x: 324, y: 28, width: 196, height: 24))
    }

    func testPremiumDecorator_updateLayoutMetrics_movesTrophyMarkWithColumnWidth() {
        let decorator = ScoreTablePremiumDecorator(
            playerCount: 2,
            displayIndexByPlayerIndex: [0: 0, 1: 1],
            layout: ScoreTableLayout(playerCount: 2, headerHeight: 28, rowHeight: 24),
            headerHeight: 28,
            rowHeight: 24,
            leftColumnWidth: 36,
            trickColumnWidth: 44,
            pointsColumnWidth: 64
        )
        let contentView = UIView(frame: CGRect(x: 0, y: 0, width: 640, height: 360))
        decorator.addPremiumLossLayer(to: contentView)

        let snapshot = ScoreTableRenderSnapshotBuilder.ScoreDecorationsSnapshot(
            penaltyStrikeCells: [],
            columnMarks: [
                .init(
                    playerIndex: 1,
                    topSummaryRowIndex: 0,
                    bottomSummaryRowIndex: 0,
                    kind: .trophy
                )
            ]
        )
        let pointsLabels: [[UILabel]] = [[UILabel(), UILabel()]]

        decorator.renderDecorations(from: snapshot, pointsLabels: pointsLabels, in: contentView)
        let firstTrophyX = trophyX(in: contentView)

        decorator.updateLayoutMetrics(leftColumnWidth: 36, trickColumnWidth: 44, pointsColumnWidth: 200)
        decorator.renderDecorations(from: snapshot, pointsLabels: pointsLabels, in: contentView)
        let secondTrophyX = trophyX(in: contentView)

        XCTAssertEqual(firstTrophyX, 147, accuracy: 0.001)
        XCTAssertEqual(secondTrophyX, 283, accuracy: 0.001)
        XCTAssertGreaterThan(secondTrophyX, firstTrophyX)
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

    private func trophyX(in contentView: UIView) -> CGFloat {
        guard let trophyLabel = contentView.subviews
            .compactMap({ $0 as? UILabel })
            .first(where: { $0.text == "🏆" }) else {
            XCTFail("Не удалось найти trophy label")
            return .zero
        }
        return trophyLabel.frame.minX
    }
}
