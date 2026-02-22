//
//  ScoreTableInProgressRoundSnapshotProvider.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import Foundation

struct ScoreTableInProgressRoundSnapshotProvider {
    struct Cell: Hashable {
        let rowIndex: Int
        let playerIndex: Int
    }

    struct Snapshot {
        static let empty = Snapshot(roundResultsByCell: [:])

        let roundResultsByCell: [Cell: RoundResult]
    }

    private let playerCount: Int
    private let rowMappings: [ScoreTableView.RowMapping]

    init(
        playerCount: Int,
        rowMappings: [ScoreTableView.RowMapping]
    ) {
        self.playerCount = playerCount
        self.rowMappings = rowMappings
    }

    func makeSnapshot(from scoreManager: ScoreManager) -> Snapshot {
        var resultsByCell: [Cell: RoundResult] = [:]

        for (rowIndex, mapping) in rowMappings.enumerated() {
            guard case .deal = mapping.kind else { continue }
            guard let roundIndex = mapping.roundIndex else { continue }

            for playerIndex in 0..<playerCount {
                guard let result = scoreManager.inProgressRoundResult(
                    forBlockIndex: mapping.blockIndex,
                    roundIndex: roundIndex,
                    playerIndex: playerIndex
                ) else {
                    continue
                }

                resultsByCell[Cell(rowIndex: rowIndex, playerIndex: playerIndex)] = result
            }
        }

        return Snapshot(roundResultsByCell: resultsByCell)
    }
}
