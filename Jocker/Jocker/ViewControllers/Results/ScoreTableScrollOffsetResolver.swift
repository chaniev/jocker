//
//  ScoreTableScrollOffsetResolver.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import CoreGraphics

struct ScoreTableScrollOffsetResolver {
    private let headerHeight: CGFloat
    private let rowHeight: CGFloat

    init(
        headerHeight: CGFloat,
        rowHeight: CGFloat
    ) {
        self.headerHeight = headerHeight
        self.rowHeight = rowHeight
    }

    func targetOffsetY(
        forRowIndex rowIndex: Int,
        visibleHeight: CGFloat,
        contentHeight: CGFloat
    ) -> CGFloat {
        let rowTop = headerHeight + CGFloat(rowIndex) * rowHeight
        let safeVisibleHeight = max(visibleHeight, 1)
        let maxOffsetY = max(0, contentHeight - safeVisibleHeight)
        let centeredOffsetY = rowTop - (safeVisibleHeight - rowHeight) / 2
        return min(max(0, centeredOffsetY), maxOffsetY)
    }
}
