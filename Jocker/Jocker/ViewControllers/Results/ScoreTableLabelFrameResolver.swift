//
//  ScoreTableLabelFrameResolver.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import CoreGraphics

struct ScoreTableLabelFrameResolver {
    private let leftColumnWidth: CGFloat
    private let trickColumnWidth: CGFloat
    private let pointsColumnWidth: CGFloat
    private let headerHeight: CGFloat
    private let rowHeight: CGFloat
    private let pointsLabelTrailingInset: CGFloat

    init(
        leftColumnWidth: CGFloat,
        trickColumnWidth: CGFloat,
        pointsColumnWidth: CGFloat,
        headerHeight: CGFloat,
        rowHeight: CGFloat,
        pointsLabelTrailingInset: CGFloat
    ) {
        self.leftColumnWidth = leftColumnWidth
        self.trickColumnWidth = trickColumnWidth
        self.pointsColumnWidth = pointsColumnWidth
        self.headerHeight = headerHeight
        self.rowHeight = rowHeight
        self.pointsLabelTrailingInset = pointsLabelTrailingInset
    }

    func headerFrame(displayIndex: Int) -> CGRect {
        return CGRect(
            x: leftColumnWidth + CGFloat(displayIndex) * (trickColumnWidth + pointsColumnWidth),
            y: 0,
            width: trickColumnWidth + pointsColumnWidth,
            height: headerHeight
        )
    }

    func cardsLabelFrame(rowIndex: Int) -> CGRect {
        return CGRect(
            x: 0,
            y: rowY(for: rowIndex),
            width: leftColumnWidth,
            height: rowHeight
        )
    }

    func tricksLabelFrame(rowIndex: Int, displayIndex: Int) -> CGRect {
        return CGRect(
            x: playerBaseX(for: displayIndex),
            y: rowY(for: rowIndex),
            width: trickColumnWidth,
            height: rowHeight
        )
    }

    func pointsLabelFrame(rowIndex: Int, displayIndex: Int) -> CGRect {
        return CGRect(
            x: playerBaseX(for: displayIndex) + trickColumnWidth,
            y: rowY(for: rowIndex),
            width: pointsColumnWidth - pointsLabelTrailingInset,
            height: rowHeight
        )
    }

    private func rowY(for rowIndex: Int) -> CGFloat {
        return headerHeight + CGFloat(rowIndex) * rowHeight
    }

    private func playerBaseX(for displayIndex: Int) -> CGFloat {
        return leftColumnWidth + CGFloat(displayIndex) * (trickColumnWidth + pointsColumnWidth)
    }
}
