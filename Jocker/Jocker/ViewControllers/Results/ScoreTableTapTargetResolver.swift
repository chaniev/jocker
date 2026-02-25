//
//  ScoreTableTapTargetResolver.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import CoreGraphics

struct ScoreTableTapTargetResolver {
    struct DealRowTarget: Equatable {
        let blockIndex: Int
        let roundIndex: Int
    }

    private let rowMappings: [ScoreTableLayout.RowMapping]
    private let headerHeight: CGFloat
    private let rowHeight: CGFloat

    init(
        rowMappings: [ScoreTableLayout.RowMapping],
        headerHeight: CGFloat,
        rowHeight: CGFloat
    ) {
        self.rowMappings = rowMappings
        self.headerHeight = headerHeight
        self.rowHeight = rowHeight
    }

    func dealRowTarget(
        scrollViewTapLocationY: CGFloat,
        contentTapLocation: CGPoint,
        contentWidth: CGFloat
    ) -> DealRowTarget? {
        guard scrollViewTapLocationY >= headerHeight else { return nil }
        guard contentTapLocation.x >= 0, contentTapLocation.x <= contentWidth else { return nil }

        let rowIndex = Int((contentTapLocation.y - headerHeight) / rowHeight)
        guard rowMappings.indices.contains(rowIndex) else { return nil }

        let mapping = rowMappings[rowIndex]
        guard case .deal = mapping.kind else { return nil }
        guard let roundIndex = mapping.roundIndex else { return nil }

        return DealRowTarget(
            blockIndex: mapping.blockIndex,
            roundIndex: roundIndex
        )
    }
}
