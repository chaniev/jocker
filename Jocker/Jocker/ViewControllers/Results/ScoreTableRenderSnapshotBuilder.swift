//
//  ScoreTableRenderSnapshotBuilder.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import Foundation

struct ScoreTableRenderSnapshotBuilder {
    struct ScoreDataSnapshot {
        let completedBlocks: [BlockResult]
        let currentBlockResults: [[RoundResult]]
        let currentBlockScores: [Int]
    }

    struct ScoreDecorationsSnapshot {
        struct PenaltyStrikeCell: Hashable {
            let rowIndex: Int
            let playerIndex: Int
        }

        enum ColumnMarkKind {
            case trophy
            case premiumLoss
        }

        struct ColumnMark {
            let playerIndex: Int
            let topSummaryRowIndex: Int
            let bottomSummaryRowIndex: Int
            let kind: ColumnMarkKind
        }

        static let empty = ScoreDecorationsSnapshot(
            penaltyStrikeCells: [],
            columnMarks: []
        )

        let penaltyStrikeCells: Set<PenaltyStrikeCell>
        let columnMarks: [ColumnMark]
    }

    private let playerCount: Int
    private let rowMappings: [ScoreTableView.RowMapping]
    private let summaryRowRangeByBlock: [Int: ClosedRange<Int>]
    private let maxBlockIndex: Int

    init(
        playerCount: Int,
        rowMappings: [ScoreTableView.RowMapping]
    ) {
        self.playerCount = playerCount
        self.rowMappings = rowMappings
        self.summaryRowRangeByBlock = Self.buildSummaryRowRanges(rowMappings: rowMappings)
        self.maxBlockIndex = rowMappings.map(\.blockIndex).max() ?? -1
    }

    func makeDataSnapshot(from scoreManager: ScoreManager) -> ScoreDataSnapshot {
        return ScoreDataSnapshot(
            completedBlocks: scoreManager.completedBlocks,
            currentBlockResults: scoreManager.currentBlockRoundResults,
            currentBlockScores: scoreManager.currentBlockBaseScores
        )
    }

    func makeDecorationsSnapshot(
        from snapshot: ScoreDataSnapshot
    ) -> ScoreDecorationsSnapshot {
        return ScoreDecorationsSnapshot(
            penaltyStrikeCells: makePenaltyStrikeCells(completedBlocks: snapshot.completedBlocks),
            columnMarks: makePremiumColumnMarks(
                completedBlocks: snapshot.completedBlocks,
                currentBlockResults: snapshot.currentBlockResults
            )
        )
    }

    private func makePenaltyStrikeCells(
        completedBlocks: [BlockResult]
    ) -> Set<ScoreDecorationsSnapshot.PenaltyStrikeCell> {
        guard !completedBlocks.isEmpty else { return [] }

        let penaltyStrikeDataByBlock = completedBlocks.map { penaltyStrikeData(for: $0) }
        var strikeCells: Set<ScoreDecorationsSnapshot.PenaltyStrikeCell> = []

        for (rowIndex, mapping) in rowMappings.enumerated() {
            guard case .deal = mapping.kind else { continue }
            guard let roundIndex = mapping.roundIndex else { continue }
            guard completedBlocks.indices.contains(mapping.blockIndex) else { continue }

            let block = completedBlocks[mapping.blockIndex]
            let penaltyDataByPlayer = penaltyStrikeDataByBlock[mapping.blockIndex]

            for playerIndex in 0..<playerCount {
                guard let strikeData = penaltyDataByPlayer[playerIndex] else { continue }
                guard strikeData.roundIndex == roundIndex else { continue }
                guard block.roundResults.indices.contains(playerIndex) else { continue }
                guard block.roundResults[playerIndex].indices.contains(roundIndex) else { continue }

                let roundResult = block.roundResults[playerIndex][roundIndex]
                guard roundResult.score == strikeData.score else { continue }

                strikeCells.insert(
                    ScoreDecorationsSnapshot.PenaltyStrikeCell(
                        rowIndex: rowIndex,
                        playerIndex: playerIndex
                    )
                )
            }
        }

        return strikeCells
    }

    private func makePremiumColumnMarks(
        completedBlocks: [BlockResult],
        currentBlockResults: [[RoundResult]]
    ) -> [ScoreDecorationsSnapshot.ColumnMark] {
        guard maxBlockIndex >= 0 else { return [] }

        var marks: [ScoreDecorationsSnapshot.ColumnMark] = []

        for blockIndex in 0...maxBlockIndex {
            guard let summaryRange = summaryRowRangeByBlock[blockIndex] else { continue }

            let roundResultsByPlayer: [[RoundResult]]?
            let premiumPlayers: Set<Int>

            if blockIndex < completedBlocks.count {
                let block = completedBlocks[blockIndex]
                roundResultsByPlayer = block.roundResults
                premiumPlayers = Set(block.premiumPlayerIndices + block.zeroPremiumPlayerIndices)
            } else if blockIndex == completedBlocks.count {
                roundResultsByPlayer = currentBlockResults
                premiumPlayers = []
            } else {
                roundResultsByPlayer = nil
                premiumPlayers = []
            }

            guard let roundResultsByPlayer else { continue }

            for playerIndex in 0..<playerCount {
                guard roundResultsByPlayer.indices.contains(playerIndex) else { continue }

                let markKind: ScoreDecorationsSnapshot.ColumnMarkKind?
                if premiumPlayers.contains(playerIndex) {
                    markKind = .trophy
                } else if hasLostPremium(in: roundResultsByPlayer[playerIndex]) {
                    markKind = .premiumLoss
                } else {
                    markKind = nil
                }

                guard let markKind else { continue }
                marks.append(
                    ScoreDecorationsSnapshot.ColumnMark(
                        playerIndex: playerIndex,
                        topSummaryRowIndex: summaryRange.lowerBound,
                        bottomSummaryRowIndex: summaryRange.upperBound,
                        kind: markKind
                    )
                )
            }
        }

        return marks
    }

    private func penaltyStrikeData(for blockResult: BlockResult) -> [Int: (roundIndex: Int, score: Int)] {
        var data: [Int: (roundIndex: Int, score: Int)] = [:]

        for playerIndex in 0..<playerCount {
            guard blockResult.premiumPenaltyRoundIndices.indices.contains(playerIndex) else { continue }
            guard blockResult.premiumPenaltyRoundScores.indices.contains(playerIndex) else { continue }
            guard let roundIndex = blockResult.premiumPenaltyRoundIndices[playerIndex] else { continue }
            let score = blockResult.premiumPenaltyRoundScores[playerIndex]
            guard score > 0 else { continue }
            data[playerIndex] = (roundIndex: roundIndex, score: score)
        }

        return data
    }

    private func hasLostPremium(in roundResults: [RoundResult]) -> Bool {
        return roundResults.contains(where: { $0.bid != $0.tricksTaken })
    }

    private static func buildSummaryRowRanges(
        rowMappings: [ScoreTableView.RowMapping]
    ) -> [Int: ClosedRange<Int>] {
        var ranges: [Int: ClosedRange<Int>] = [:]

        for (rowIndex, mapping) in rowMappings.enumerated() {
            let isSummaryRow: Bool
            switch mapping.kind {
            case .subtotal, .cumulative:
                isSummaryRow = true
            case .deal:
                isSummaryRow = false
            }
            guard isSummaryRow else { continue }

            if let existingRange = ranges[mapping.blockIndex] {
                let lower = min(existingRange.lowerBound, rowIndex)
                let upper = max(existingRange.upperBound, rowIndex)
                ranges[mapping.blockIndex] = lower...upper
            } else {
                ranges[mapping.blockIndex] = rowIndex...rowIndex
            }
        }

        return ranges
    }
}
