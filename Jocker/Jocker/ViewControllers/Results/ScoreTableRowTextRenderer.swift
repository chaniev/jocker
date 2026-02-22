//
//  ScoreTableRowTextRenderer.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import Foundation

struct ScoreTableRowTextRenderer {
    typealias ScoreDataSnapshot = ScoreTableRenderSnapshotBuilder.ScoreDataSnapshot
    typealias InProgressRoundSnapshot = ScoreTableInProgressRoundSnapshotProvider.Snapshot
    typealias InProgressRoundCell = ScoreTableInProgressRoundSnapshotProvider.Cell

    struct Snapshot: Equatable {
        let tricksTexts: [[String]]
        let pointsTexts: [[String]]
    }

    private static let summaryScoreFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    private let playerCount: Int
    private let playerDisplayOrder: [Int]
    private let rowMappings: [ScoreTableView.RowMapping]

    init(
        playerCount: Int,
        playerDisplayOrder: [Int],
        rowMappings: [ScoreTableView.RowMapping]
    ) {
        self.playerCount = playerCount
        self.playerDisplayOrder = playerDisplayOrder
        self.rowMappings = rowMappings
    }

    func makeSnapshot(
        dataSnapshot: ScoreDataSnapshot,
        inProgressRoundSnapshot: InProgressRoundSnapshot
    ) -> Snapshot {
        var tricksTexts = Array(
            repeating: Array(repeating: "", count: playerCount),
            count: rowMappings.count
        )
        var pointsTexts = Array(
            repeating: Array(repeating: "", count: playerCount),
            count: rowMappings.count
        )

        for (rowIndex, mapping) in rowMappings.enumerated() {
            switch mapping.kind {
            case .deal:
                fillDealRowTexts(
                    rowIndex: rowIndex,
                    blockIndex: mapping.blockIndex,
                    roundIndex: mapping.roundIndex ?? 0,
                    dataSnapshot: dataSnapshot,
                    inProgressRoundSnapshot: inProgressRoundSnapshot,
                    tricksTexts: &tricksTexts,
                    pointsTexts: &pointsTexts
                )
            case .subtotal:
                let scores = subtotalScores(
                    forBlockIndex: mapping.blockIndex,
                    dataSnapshot: dataSnapshot
                )
                fillSummaryRowTexts(
                    rowIndex: rowIndex,
                    scores: scores,
                    tricksTexts: &tricksTexts,
                    pointsTexts: &pointsTexts
                )
            case .cumulative:
                let scores = cumulativeScores(
                    forBlockIndex: mapping.blockIndex,
                    dataSnapshot: dataSnapshot
                )
                fillSummaryRowTexts(
                    rowIndex: rowIndex,
                    scores: scores,
                    tricksTexts: &tricksTexts,
                    pointsTexts: &pointsTexts
                )
            }
        }

        return Snapshot(tricksTexts: tricksTexts, pointsTexts: pointsTexts)
    }

    private func fillDealRowTexts(
        rowIndex: Int,
        blockIndex: Int,
        roundIndex: Int,
        dataSnapshot: ScoreDataSnapshot,
        inProgressRoundSnapshot: InProgressRoundSnapshot,
        tricksTexts: inout [[String]],
        pointsTexts: inout [[String]]
    ) {
        let completedBlocks = dataSnapshot.completedBlocks
        let currentBlockResults = dataSnapshot.currentBlockResults

        let results: [[RoundResult]]?
        let isCurrentBlock = blockIndex == completedBlocks.count

        if blockIndex < completedBlocks.count {
            results = completedBlocks[blockIndex].roundResults
        } else if isCurrentBlock {
            results = currentBlockResults
        } else {
            results = nil
        }

        for displayIndex in 0..<playerCount {
            let playerIndex = playerDisplayOrder[displayIndex]

            if
                let results,
                playerIndex < results.count,
                roundIndex < results[playerIndex].count
            {
                let roundResult = results[playerIndex][roundIndex]
                tricksTexts[rowIndex][displayIndex] = dealTricksText(
                    roundResult: roundResult,
                    displayedTricksTaken: nil
                )
                pointsTexts[rowIndex][displayIndex] = "\(roundResult.score)"
                continue
            }

            if
                isCurrentBlock,
                let inProgressResult = inProgressRoundSnapshot.roundResultsByCell[
                    InProgressRoundCell(rowIndex: rowIndex, playerIndex: playerIndex)
                ]
            {
                tricksTexts[rowIndex][displayIndex] = dealTricksText(
                    roundResult: inProgressResult,
                    displayedTricksTaken: 0
                )
                pointsTexts[rowIndex][displayIndex] = "0"
                continue
            }

            tricksTexts[rowIndex][displayIndex] = ""
            pointsTexts[rowIndex][displayIndex] = ""
        }
    }

    private func fillSummaryRowTexts(
        rowIndex: Int,
        scores: [Int]?,
        tricksTexts: inout [[String]],
        pointsTexts: inout [[String]]
    ) {
        for displayIndex in 0..<playerCount {
            let playerIndex = playerDisplayOrder[displayIndex]
            tricksTexts[rowIndex][displayIndex] = ""

            if let score = summaryScore(for: playerIndex, in: scores) {
                pointsTexts[rowIndex][displayIndex] = displayedSummaryScore(from: score)
            } else {
                pointsTexts[rowIndex][displayIndex] = ""
            }
        }
    }

    private func subtotalScores(
        forBlockIndex blockIndex: Int,
        dataSnapshot: ScoreDataSnapshot
    ) -> [Int]? {
        let completedBlocks = dataSnapshot.completedBlocks

        if blockIndex < completedBlocks.count {
            return completedBlocks[blockIndex].finalScores
        }
        if blockIndex == completedBlocks.count {
            return dataSnapshot.currentBlockScores
        }
        return nil
    }

    private func cumulativeScores(
        forBlockIndex blockIndex: Int,
        dataSnapshot: ScoreDataSnapshot
    ) -> [Int]? {
        let completedBlocks = dataSnapshot.completedBlocks

        if blockIndex < completedBlocks.count {
            return cumulativeScores(through: blockIndex, completedBlocks: completedBlocks)
        }
        if blockIndex == completedBlocks.count {
            return cumulativeScoresIncludingCurrent(
                completedBlocks: completedBlocks,
                currentBlockScores: dataSnapshot.currentBlockScores
            )
        }
        return nil
    }

    private func dealTricksText(
        roundResult: RoundResult,
        displayedTricksTaken: Int?
    ) -> String {
        let tricksTaken = displayedTricksTaken ?? roundResult.tricksTaken
        if roundResult.isBlind {
            return "\(circledBidText(roundResult.bid))/\(tricksTaken)"
        }
        return "\(roundResult.bid)/\(tricksTaken)"
    }

    private func displayedSummaryScore(from rawScore: Int) -> String {
        let value = NSNumber(value: Double(rawScore) / 100.0)
        return Self.summaryScoreFormatter.string(from: value) ?? "0,0"
    }

    private func cumulativeScores(through blockIndex: Int, completedBlocks: [BlockResult]) -> [Int] {
        var scores = Array(repeating: 0, count: playerCount)
        guard !completedBlocks.isEmpty else { return scores }

        for index in 0...min(blockIndex, completedBlocks.count - 1) {
            let block = completedBlocks[index]
            for playerIndex in 0..<playerCount {
                if block.finalScores.indices.contains(playerIndex) {
                    scores[playerIndex] += block.finalScores[playerIndex]
                }
            }
        }

        return scores
    }

    private func cumulativeScoresIncludingCurrent(
        completedBlocks: [BlockResult],
        currentBlockScores: [Int]
    ) -> [Int] {
        var scores = cumulativeScores(
            through: completedBlocks.count - 1,
            completedBlocks: completedBlocks
        )
        for playerIndex in 0..<playerCount {
            if currentBlockScores.indices.contains(playerIndex) {
                scores[playerIndex] += currentBlockScores[playerIndex]
            }
        }
        return scores
    }

    private func summaryScore(for playerIndex: Int, in scores: [Int]?) -> Int? {
        guard let scores else { return nil }
        guard scores.indices.contains(playerIndex) else { return nil }
        return scores[playerIndex]
    }

    private func circledBidText(_ bid: Int) -> String {
        switch bid {
        case 0:
            return "⓪"
        case 1...20:
            if let scalar = UnicodeScalar(0x2460 + bid - 1) {
                return String(scalar)
            }
            return "\(bid)"
        default:
            return "\(bid)"
        }
    }
}
