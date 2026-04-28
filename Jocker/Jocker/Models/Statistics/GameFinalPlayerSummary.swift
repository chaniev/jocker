//
//  GameFinalPlayerSummary.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

struct GameFinalTeamSummary {
    let teamIndex: Int
    let teamLabel: String
    let memberPlayerIndices: [Int]
    let memberNames: [String]
    let place: Int
    let totalScore: Int
    let blockScores: [Int]

    static func build(
        playerNames: [String],
        playerCount: Int,
        gameMode: GameMode,
        completedBlocks: [BlockResult]
    ) -> [GameFinalTeamSummary] {
        let partnerships = GamePartnerships(playerCount: playerCount, gameMode: gameMode)
        guard partnerships.isEnabled else { return [] }

        let blockCount = max(GameConstants.totalBlocks, completedBlocks.count)
        let teamTotalsByIndex = partnerships.orderedTeamIndices.reduce(into: [Int: Int]()) { partialResult, teamIndex in
            let total = (0..<blockCount).reduce(0) { runningTotal, blockIndex in
                runningTotal + blockScore(
                    teamIndex: teamIndex,
                    blockIndex: blockIndex,
                    completedBlocks: completedBlocks,
                    partnerships: partnerships
                )
            }
            partialResult[teamIndex] = total
        }

        let placesByTeamIndex = partnerships.orderedTeamIndices
            .sorted { lhs, rhs in
                let lhsScore = teamTotalsByIndex[lhs] ?? 0
                let rhsScore = teamTotalsByIndex[rhs] ?? 0
                if lhsScore == rhsScore {
                    return lhs < rhs
                }
                return lhsScore > rhsScore
            }
            .enumerated()
            .reduce(into: [Int: Int]()) { partialResult, item in
                partialResult[item.element] = item.offset + 1
            }

        return partnerships.orderedTeamIndices.map { teamIndex in
            let memberIndices = partnerships.teamMembers(for: teamIndex)
            let memberNames = memberIndices.map {
                PlayerDisplayNameFormatter.displayName(for: $0, in: playerNames)
            }
            let blockScores = (0..<blockCount).map { blockIndex in
                blockScore(
                    teamIndex: teamIndex,
                    blockIndex: blockIndex,
                    completedBlocks: completedBlocks,
                    partnerships: partnerships
                )
            }

            return GameFinalTeamSummary(
                teamIndex: teamIndex,
                teamLabel: partnerships.teamDisplayLabel(for: teamIndex),
                memberPlayerIndices: memberIndices,
                memberNames: memberNames,
                place: placesByTeamIndex[teamIndex] ?? (teamIndex + 1),
                totalScore: blockScores.reduce(0, +),
                blockScores: blockScores
            )
        }
        .sorted { lhs, rhs in
            if lhs.place == rhs.place {
                return lhs.teamIndex < rhs.teamIndex
            }
            return lhs.place < rhs.place
        }
    }

    private static func blockScore(
        teamIndex: Int,
        blockIndex: Int,
        completedBlocks: [BlockResult],
        partnerships: GamePartnerships
    ) -> Int {
        guard completedBlocks.indices.contains(blockIndex) else { return 0 }
        let teamScores = partnerships.teamTotals(from: completedBlocks[blockIndex].finalScores)
        guard teamScores.indices.contains(teamIndex) else { return 0 }
        return teamScores[teamIndex]
    }
}

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
        gameMode: GameMode = .freeForAll,
        completedBlocks: [BlockResult]
    ) -> [GameFinalPlayerSummary] {
        guard playerCount > 0 else { return [] }

        let totalBlocks = max(GameConstants.totalBlocks, completedBlocks.count)
        let partnerships = GamePartnerships(playerCount: playerCount, gameMode: gameMode)
        let teamTotals = completedBlocks.reduce(into: Array(repeating: 0, count: max(2, partnerships.teamCount))) { partialResult, block in
            let blockTeamTotals = partnerships.teamTotals(from: block.finalScores)
            for (teamIndex, score) in blockTeamTotals.enumerated() {
                if partialResult.indices.contains(teamIndex) {
                    partialResult[teamIndex] += score
                }
            }
        }
        let teamPlaces: [Int: Int] = partnerships.orderedTeamIndices
            .sorted { lhs, rhs in
                let lhsScore = teamTotals.indices.contains(lhs) ? teamTotals[lhs] : 0
                let rhsScore = teamTotals.indices.contains(rhs) ? teamTotals[rhs] : 0
                if lhsScore == rhsScore {
                    return lhs < rhs
                }
                return lhsScore > rhsScore
            }
            .enumerated()
            .reduce(into: [Int: Int]()) { partialResult, item in
                partialResult[item.element] = item.offset + 1
            }
        var summaries: [GameFinalPlayerSummary] = []
        summaries.reserveCapacity(playerCount)

        for playerIndex in 0..<playerCount {
            let playerName = PlayerDisplayNameFormatter.displayName(
                for: playerIndex,
                in: playerNames
            )

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
            let place: Int
            if let teamIndex = partnerships.teamIndex(for: playerIndex) {
                place = teamPlaces[teamIndex] ?? (teamIndex + 1)
            } else {
                place = 0
            }

            summaries.append(
                GameFinalPlayerSummary(
                    playerIndex: playerIndex,
                    playerName: playerName,
                    place: place,
                    totalScore: totalScore,
                    blockScores: blockScores,
                    premiumTakenByBlock: premiumTakenByBlock,
                    totalPremiumsTaken: totalPremiumsTaken,
                    fourthBlockBlindCount: fourthBlockBlindCount
                )
            )
        }

        let sorted = summaries.sorted { lhs, rhs in
            if lhs.place != rhs.place, partnerships.isEnabled {
                return lhs.place < rhs.place
            }
            if lhs.totalScore == rhs.totalScore {
                return lhs.playerIndex < rhs.playerIndex
            }
            return lhs.totalScore > rhs.totalScore
        }

        guard !partnerships.isEnabled else {
            return sorted
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
