//
//  ScoreTableRowNavigationResolver.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import Foundation

struct ScoreTableRowNavigationResolver {
    typealias RowMapping = ScoreTableLayout.RowMapping
    private typealias DealRow = (rowIndex: Int, roundIndex: Int)

    private let dealRowsByBlock: [Int: [DealRow]]
    private let summaryRowsByBlock: [Int: [Int]]

    init(rowMappings: [RowMapping]) {
        var dealRowsByBlock: [Int: [DealRow]] = [:]
        var summaryRowsByBlock: [Int: [Int]] = [:]

        for (rowIndex, mapping) in rowMappings.enumerated() {
            switch mapping.kind {
            case .deal:
                dealRowsByBlock[mapping.blockIndex, default: []].append(
                    (rowIndex: rowIndex, roundIndex: mapping.roundIndex ?? 0)
                )
            case .subtotal, .cumulative:
                summaryRowsByBlock[mapping.blockIndex, default: []].append(rowIndex)
            }
        }

        self.dealRowsByBlock = dealRowsByBlock
        self.summaryRowsByBlock = summaryRowsByBlock
    }

    func targetDealRowIndex(blockIndex: Int, roundIndex: Int) -> Int? {
        let dealRows = dealRowsByBlock[blockIndex] ?? []
        guard !dealRows.isEmpty else { return nil }

        let safeRound = min(max(roundIndex, 0), dealRows.count - 1)
        if let exactMatch = dealRows.first(where: { $0.roundIndex == safeRound }) {
            return exactMatch.rowIndex
        }

        return dealRows[safeRound].rowIndex
    }

    func targetSummaryRowIndex(blockIndex: Int) -> Int? {
        return summaryRowsForBlock(blockIndex).max()
    }

    private func summaryRowsForBlock(_ blockIndex: Int) -> [Int] {
        return summaryRowsByBlock[blockIndex] ?? []
    }
}
