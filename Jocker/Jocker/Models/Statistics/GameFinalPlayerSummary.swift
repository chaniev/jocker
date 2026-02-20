//
//  GameFinalPlayerSummary.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

struct GameFinalPlayerSummary {
    let playerIndex: Int
    let playerName: String
    let place: Int
    let totalScore: Int
    let blockScores: [Int]
    let premiumTakenByBlock: [Bool]
    let totalPremiumsTaken: Int
    let fourthBlockBlindCount: Int

    static func build(
        playerNames: [String],
        playerCount: Int,
        completedBlocks: [BlockResult]
    ) -> [GameFinalPlayerSummary] {
        guard playerCount > 0 else { return [] }

        let totalBlocks = max(GameConstants.totalBlocks, completedBlocks.count)
        var summaries: [GameFinalPlayerSummary] = []
        summaries.reserveCapacity(playerCount)

        for playerIndex in 0..<playerCount {
            let fallbackName = "Игрок \(playerIndex + 1)"
            let trimmedName = playerNames.indices.contains(playerIndex)
                ? playerNames[playerIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                : ""
            let playerName = trimmedName.isEmpty ? fallbackName : trimmedName

            let blockScores = (0..<totalBlocks).map { blockIndex in
                guard completedBlocks.indices.contains(blockIndex) else { return 0 }
                let block = completedBlocks[blockIndex]
                guard block.finalScores.indices.contains(playerIndex) else { return 0 }
                return block.finalScores[playerIndex]
            }

            let premiumTakenByBlock = (0..<totalBlocks).map { blockIndex in
                guard completedBlocks.indices.contains(blockIndex) else { return false }
                let block = completedBlocks[blockIndex]
                return block.premiumPlayerIndices.contains(playerIndex) ||
                    block.zeroPremiumPlayerIndices.contains(playerIndex)
            }

            let fourthBlockBlindCount: Int
            if completedBlocks.indices.contains(GameBlock.fourth.rawValue - 1) {
                let fourthBlock = completedBlocks[GameBlock.fourth.rawValue - 1]
                if fourthBlock.roundResults.indices.contains(playerIndex) {
                    fourthBlockBlindCount = fourthBlock.roundResults[playerIndex]
                        .filter(\.isBlind)
                        .count
                } else {
                    fourthBlockBlindCount = 0
                }
            } else {
                fourthBlockBlindCount = 0
            }

            let totalScore = blockScores.reduce(0, +)
            let totalPremiumsTaken = premiumTakenByBlock.filter { $0 }.count

            summaries.append(
                GameFinalPlayerSummary(
                    playerIndex: playerIndex,
                    playerName: playerName,
                    place: 0,
                    totalScore: totalScore,
                    blockScores: blockScores,
                    premiumTakenByBlock: premiumTakenByBlock,
                    totalPremiumsTaken: totalPremiumsTaken,
                    fourthBlockBlindCount: fourthBlockBlindCount
                )
            )
        }

        let sorted = summaries.sorted { lhs, rhs in
            if lhs.totalScore == rhs.totalScore {
                return lhs.playerIndex < rhs.playerIndex
            }
            return lhs.totalScore > rhs.totalScore
        }

        return sorted.enumerated().map { index, summary in
            GameFinalPlayerSummary(
                playerIndex: summary.playerIndex,
                playerName: summary.playerName,
                place: index + 1,
                totalScore: summary.totalScore,
                blockScores: summary.blockScores,
                premiumTakenByBlock: summary.premiumTakenByBlock,
                totalPremiumsTaken: summary.totalPremiumsTaken,
                fourthBlockBlindCount: summary.fourthBlockBlindCount
            )
        }
    }
}
