//
//  PremiumRules.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import Foundation

/// Чистые правила расчёта премий/штрафов внутри блока.
enum PremiumRules {
    struct BlockFinalizationOutcome {
        let roundsWithPremiums: [[RoundResult]]
        let baseBlockScores: [Int]
        let finalScores: [Int]
        let allPremiumPlayers: [Int]
        let regularPremiumPlayers: [Int]
        let zeroPremiumPlayers: [Int]
        let premiumBonuses: [Int]
        let zeroPremiumBonuses: [Int]
        let premiumPenalties: [Int]
        let premiumPenaltyRoundIndices: [Int?]
        let premiumPenaltyRoundScores: [Int]
    }

    static func finalizeBlockScores(
        blockRoundResults: [[RoundResult]],
        blockNumber: Int,
        playerCount: Int
    ) -> BlockFinalizationOutcome {
        guard playerCount > 0 else {
            return BlockFinalizationOutcome(
                roundsWithPremiums: [],
                baseBlockScores: [],
                finalScores: [],
                allPremiumPlayers: [],
                regularPremiumPlayers: [],
                zeroPremiumPlayers: [],
                premiumBonuses: [],
                zeroPremiumBonuses: [],
                premiumPenalties: [],
                premiumPenaltyRoundIndices: [],
                premiumPenaltyRoundScores: []
            )
        }

        let allPremiumPlayers = determinePremiumPlayers(
            roundResultsByPlayer: blockRoundResults,
            playerCount: playerCount
        )
        let zeroPremiumPlayers = determineZeroPremiumPlayers(
            among: allPremiumPlayers,
            blockNumber: blockNumber,
            roundResultsByPlayer: blockRoundResults
        )
        let zeroPremiumSet = Set(zeroPremiumPlayers)
        let regularPremiumPlayers = allPremiumPlayers.filter { !zeroPremiumSet.contains($0) }

        let premiumAdjustments = computePremiumAdjustments(
            roundResultsByPlayer: blockRoundResults,
            playerCount: playerCount,
            allPremiumPlayers: allPremiumPlayers,
            regularPremiumPlayers: regularPremiumPlayers,
            zeroPremiumPlayers: zeroPremiumPlayers
        )

        let roundsWithPremiums = applyPremiumBonusesToLastDeal(
            roundResults: blockRoundResults,
            playerCount: playerCount,
            premiumBonuses: premiumAdjustments.premiumBonuses,
            zeroPremiumBonuses: premiumAdjustments.zeroPremiumBonuses
        )
        let baseBlockScores = calculateBlockScores(
            roundsWithPremiums,
            playerCount: playerCount
        )
        let finalScores = (0..<playerCount).map { playerIndex in
            baseBlockScores[playerIndex] - premiumAdjustments.premiumPenalties[playerIndex]
        }

        return BlockFinalizationOutcome(
            roundsWithPremiums: roundsWithPremiums,
            baseBlockScores: baseBlockScores,
            finalScores: finalScores,
            allPremiumPlayers: allPremiumPlayers,
            regularPremiumPlayers: regularPremiumPlayers,
            zeroPremiumPlayers: zeroPremiumPlayers,
            premiumBonuses: premiumAdjustments.premiumBonuses,
            zeroPremiumBonuses: premiumAdjustments.zeroPremiumBonuses,
            premiumPenalties: premiumAdjustments.premiumPenalties,
            premiumPenaltyRoundIndices: premiumAdjustments.premiumPenaltyRoundIndices,
            premiumPenaltyRoundScores: premiumAdjustments.premiumPenaltyRoundScores
        )
    }

    static func findPenaltyTarget(
        for playerIndex: Int,
        premiumPlayers: Set<Int>,
        playerCount: Int
    ) -> Int? {
        guard playerCount > 1 else { return nil }

        var candidate = leftNeighbor(of: playerIndex, playerCount: playerCount)
        var checked = 0

        while checked < playerCount - 1 {
            if !premiumPlayers.contains(candidate) {
                return candidate
            }
            candidate = leftNeighbor(of: candidate, playerCount: playerCount)
            checked += 1
        }

        return nil
    }

    static func leftNeighbor(of playerIndex: Int, playerCount: Int) -> Int {
        guard playerCount > 0 else { return 0 }
        return (playerIndex + 1) % playerCount
    }

    private static func determinePremiumPlayers(
        roundResultsByPlayer: [[RoundResult]],
        playerCount: Int
    ) -> [Int] {
        return (0..<playerCount).filter { playerIndex in
            let results = roundResultsByPlayer.indices.contains(playerIndex)
                ? roundResultsByPlayer[playerIndex]
                : []
            guard !results.isEmpty else { return false }
            return results.allSatisfy(\.bidMatched)
        }
    }

    private static func determineZeroPremiumPlayers(
        among premiumPlayers: [Int],
        blockNumber: Int,
        roundResultsByPlayer: [[RoundResult]]
    ) -> [Int] {
        guard blockNumber == GameBlock.first.rawValue || blockNumber == GameBlock.third.rawValue else {
            return []
        }

        return premiumPlayers.filter { playerIndex in
            let results = roundResultsByPlayer.indices.contains(playerIndex)
                ? roundResultsByPlayer[playerIndex]
                : []
            return ScoreCalculator.isZeroPremiumEligible(roundResults: results)
        }
    }

    private static func calculateBlockScores(
        _ roundResultsByPlayer: [[RoundResult]],
        playerCount: Int
    ) -> [Int] {
        return (0..<playerCount).map { playerIndex in
            guard roundResultsByPlayer.indices.contains(playerIndex) else { return 0 }
            return roundResultsByPlayer[playerIndex].reduce(0) { $0 + $1.score }
        }
    }

    private static func applyPremiumBonusesToLastDeal(
        roundResults: [[RoundResult]],
        playerCount: Int,
        premiumBonuses: [Int],
        zeroPremiumBonuses: [Int]
    ) -> [[RoundResult]] {
        var updatedRoundResults = roundResults

        for playerIndex in 0..<playerCount {
            guard updatedRoundResults.indices.contains(playerIndex) else { continue }
            guard !updatedRoundResults[playerIndex].isEmpty else { continue }

            let premiumBonus = premiumBonuses.indices.contains(playerIndex)
                ? premiumBonuses[playerIndex]
                : 0
            let zeroPremiumBonus = zeroPremiumBonuses.indices.contains(playerIndex)
                ? zeroPremiumBonuses[playerIndex]
                : 0
            let totalBonus = premiumBonus + zeroPremiumBonus
            guard totalBonus != 0 else { continue }

            let lastRoundIndex = updatedRoundResults[playerIndex].count - 1
            let lastRound = updatedRoundResults[playerIndex][lastRoundIndex]
            updatedRoundResults[playerIndex][lastRoundIndex] = lastRound.addingScoreAdjustment(totalBonus)
        }

        return updatedRoundResults
    }

    private static func computePremiumAdjustments(
        roundResultsByPlayer: [[RoundResult]],
        playerCount: Int,
        allPremiumPlayers: [Int],
        regularPremiumPlayers: [Int],
        zeroPremiumPlayers: [Int]
    ) -> (
        premiumBonuses: [Int],
        zeroPremiumBonuses: [Int],
        premiumPenalties: [Int],
        premiumPenaltyRoundIndices: [Int?],
        premiumPenaltyRoundScores: [Int]
    ) {
        var premiumBonuses = Array(repeating: 0, count: playerCount)
        var zeroPremiumBonuses = Array(repeating: 0, count: playerCount)
        var premiumPenalties = Array(repeating: 0, count: playerCount)
        var premiumPenaltyRoundIndices = Array(repeating: Optional<Int>.none, count: playerCount)
        var premiumPenaltyRoundScores = Array(repeating: 0, count: playerCount)

        for playerIndex in regularPremiumPlayers {
            let roundScores = roundResultsByPlayer.indices.contains(playerIndex)
                ? roundResultsByPlayer[playerIndex].map(\.score)
                : []
            premiumBonuses[playerIndex] = ScoreCalculator.calculatePremiumBonus(roundScores: roundScores)
        }

        for playerIndex in zeroPremiumPlayers {
            zeroPremiumBonuses[playerIndex] = ScoreCalculator.zeroPremiumAmount
        }

        let premiumSet = Set(allPremiumPlayers)
        for playerIndex in allPremiumPlayers {
            guard let penaltyTarget = findPenaltyTarget(
                for: playerIndex,
                premiumPlayers: premiumSet,
                playerCount: playerCount
            ) else {
                continue
            }

            let targetRoundScores = roundResultsByPlayer.indices.contains(penaltyTarget)
                ? roundResultsByPlayer[penaltyTarget].map(\.score)
                : []
            let penaltySelection = ScoreCalculator.selectPremiumPenaltyRound(
                roundScores: targetRoundScores
            )
            let penalty = penaltySelection.penalty
            premiumPenalties[penaltyTarget] += penalty

            if
                penalty > 0,
                premiumPenaltyRoundIndices[penaltyTarget] == nil,
                let roundIndex = penaltySelection.roundIndex
            {
                premiumPenaltyRoundIndices[penaltyTarget] = roundIndex
                premiumPenaltyRoundScores[penaltyTarget] = penalty
            }
        }

        return (
            premiumBonuses,
            zeroPremiumBonuses,
            premiumPenalties,
            premiumPenaltyRoundIndices,
            premiumPenaltyRoundScores
        )
    }
}
