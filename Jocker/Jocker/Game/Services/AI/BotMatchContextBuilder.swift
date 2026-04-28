//
//  BotMatchContextBuilder.swift
//  Jocker
//
//  Created by Codex on 04.03.2026.
//

import Foundation

/// Pure builder that maps runtime game/scoring state to `BotMatchContext`.
///
/// Extracted from `GameScene` to keep UI layer thin and make context construction testable.
struct BotMatchContextBuilder {
    static func build(
        gameState: GameState,
        scoreManager: ScoreManager,
        playerIndex: Int,
        playerCount: Int
    ) -> BotMatchContext? {
        guard playerCount > 0 else { return nil }
        guard gameState.players.indices.contains(playerIndex) else { return nil }

        let totalScores = scoreManager.totalScoresIncludingCurrentBlock
        let partnerships = gameState.partnerships
        let normalizedScores: [Int]
        if totalScores.count == playerCount {
            normalizedScores = totalScores
        } else {
            normalizedScores = Array(totalScores.prefix(playerCount)) +
                Array(repeating: 0, count: max(0, playerCount - totalScores.count))
        }
        let teamScores = partnerships.teamTotals(from: normalizedScores)

        return BotMatchContext(
            block: gameState.currentBlock,
            roundIndexInBlock: gameState.currentRoundInBlock,
            totalRoundsInBlock: gameState.totalRoundsInBlock,
            gameMode: gameState.gameMode,
            totalScores: normalizedScores,
            teamScores: teamScores,
            teamScoreMargin: partnerships.teamScoreMargin(
                forPlayerIndex: playerIndex,
                from: normalizedScores
            ),
            playerIndex: playerIndex,
            partnerIndex: partnerships.partnerIndex(for: playerIndex),
            teammatePlayerIndices: partnerships.teammatePlayerIndices(for: playerIndex),
            opponentPlayerIndices: partnerships.opponentPlayerIndices(for: playerIndex),
            dealerIndex: gameState.currentDealer,
            playerCount: playerCount,
            round: makeRoundSnapshot(
                gameState: gameState,
                playerCount: playerCount
            ),
            premium: makePremiumSnapshot(
                gameState: gameState,
                scoreManager: scoreManager,
                playerIndex: playerIndex,
                playerCount: playerCount,
                partnerships: partnerships
            ),
            opponents: makeOpponentModel(
                gameState: gameState,
                scoreManager: scoreManager,
                playerIndex: playerIndex,
                playerCount: playerCount,
                partnerships: partnerships
            )
        )
    }

    private static func makeRoundSnapshot(
        gameState: GameState,
        playerCount: Int
    ) -> BotMatchContext.RoundSnapshot {
        let bids = (0..<playerCount).map { playerIndex in
            guard gameState.players.indices.contains(playerIndex) else { return 0 }
            return gameState.players[playerIndex].currentBid
        }
        let tricksTaken = (0..<playerCount).map { playerIndex in
            guard gameState.players.indices.contains(playerIndex) else { return 0 }
            return gameState.players[playerIndex].tricksTaken
        }
        let isBlindBid = (0..<playerCount).map { playerIndex in
            guard gameState.players.indices.contains(playerIndex) else { return false }
            return gameState.players[playerIndex].isBlindBid
        }

        return BotMatchContext.RoundSnapshot(
            bids: bids,
            tricksTaken: tricksTaken,
            isBlindBid: isBlindBid
        )
    }

    private static func makePremiumSnapshot(
        gameState: GameState,
        scoreManager: ScoreManager,
        playerIndex: Int,
        playerCount: Int,
        partnerships: GamePartnerships
    ) -> BotMatchContext.PremiumSnapshot? {
        guard playerIndex >= 0, playerIndex < playerCount else { return nil }
        guard scoreManager.currentBlockRoundResults.indices.contains(playerIndex) else { return nil }

        let roundResults = scoreManager.currentBlockRoundResults[playerIndex]
        let totalRounds = max(0, gameState.totalRoundsInBlock)
        let completedRounds = min(roundResults.count, totalRounds)
        let remainingRounds = max(0, totalRounds - completedRounds)
        let consideredResults = Array(roundResults.prefix(completedRounds))
        let zeroPremiumRelevant = gameState.currentBlock == .first || gameState.currentBlock == .third
        let leftNeighborIndex = playerCount > 1
            ? PremiumRules.leftNeighbor(of: playerIndex, playerCount: playerCount)
            : nil

        let isPremiumCandidateSoFar = consideredResults.allSatisfy(\.bidMatched)
        let isZeroPremiumCandidateSoFar = zeroPremiumRelevant
            ? (consideredResults.isEmpty || ScoreCalculator.isZeroPremiumEligible(roundResults: consideredResults))
            : false

        let allPlayerResults = scoreManager.currentBlockRoundResults
        let candidateIndices = (0..<playerCount).filter { index in
            guard allPlayerResults.indices.contains(index) else { return false }
            let playerResults = Array(allPlayerResults[index].prefix(totalRounds))
            return playerResults.allSatisfy(\.bidMatched)
        }
        let premiumCandidateSet = Set(candidateIndices)
        let opponentPremiumCandidatesSoFarCount = candidateIndices.filter { candidateIndex in
            candidateIndex != playerIndex && !partnerships.areTeammates(candidateIndex, playerIndex)
        }.count
        let partnerIndex = partnerships.partnerIndex(for: playerIndex)
        let hasAnyCompletedRoundEvidence = allPlayerResults.contains { !$0.isEmpty }

        let threateningPenaltyCandidatesCount: Int
        if hasAnyCompletedRoundEvidence {
            threateningPenaltyCandidatesCount = candidateIndices
                .filter { $0 != playerIndex }
                .reduce(0) { partial, premiumPlayerIndex in
                    let target = PremiumRules.findPenaltyTarget(
                        for: premiumPlayerIndex,
                        premiumPlayers: premiumCandidateSet,
                        playerCount: playerCount
                    )
                    let adjustedTarget: Int?
                    if let target, partnerships.areTeammates(premiumPlayerIndex, target) {
                        adjustedTarget = nil
                    } else {
                        adjustedTarget = target
                    }
                    return partial + (adjustedTarget == playerIndex ? 1 : 0)
                }
        } else {
            threateningPenaltyCandidatesCount = 0
        }
        let isPenaltyTargetRiskSoFar = threateningPenaltyCandidatesCount > 0
        let leftNeighborIsPremiumCandidateSoFar = leftNeighborIndex.map {
            premiumCandidateSet.contains($0) && !partnerships.areTeammates(playerIndex, $0)
        } ?? false

        return BotMatchContext.PremiumSnapshot(
            completedRoundsInBlock: completedRounds,
            remainingRoundsInBlock: remainingRounds,
            isPremiumCandidateSoFar: isPremiumCandidateSoFar,
            partnerIsPremiumCandidateSoFar: partnerIndex.map { premiumCandidateSet.contains($0) } ?? false,
            isZeroPremiumRelevantInBlock: zeroPremiumRelevant,
            isZeroPremiumCandidateSoFar: isZeroPremiumCandidateSoFar,
            leftNeighborIndex: leftNeighborIndex,
            leftNeighborIsPremiumCandidateSoFar: leftNeighborIsPremiumCandidateSoFar,
            isPenaltyTargetRiskSoFar: isPenaltyTargetRiskSoFar,
            premiumCandidatesThreateningPenaltyCount: threateningPenaltyCandidatesCount,
            opponentPremiumCandidatesSoFarCount: opponentPremiumCandidatesSoFarCount
        )
    }

    private static func makeOpponentModel(
        gameState: GameState,
        scoreManager: ScoreManager,
        playerIndex: Int,
        playerCount: Int,
        partnerships: GamePartnerships
    ) -> BotOpponentModel? {
        guard playerIndex >= 0, playerIndex < playerCount else { return nil }

        let totalRounds = max(0, gameState.totalRoundsInBlock)
        let leftNeighborIndex = playerCount > 1
            ? PremiumRules.leftNeighbor(of: playerIndex, playerCount: playerCount)
            : nil

        let snapshots = (0..<playerCount).compactMap { opponentIndex -> BotOpponentModel.OpponentSnapshot? in
            guard opponentIndex != playerIndex else { return nil }
            guard !partnerships.areTeammates(playerIndex, opponentIndex) else { return nil }
            guard scoreManager.currentBlockRoundResults.indices.contains(opponentIndex) else { return nil }

            let results = Array(scoreManager.currentBlockRoundResults[opponentIndex].prefix(totalRounds))
            let observedRounds = results.count
            guard observedRounds > 0 else {
                return BotOpponentModel.OpponentSnapshot(
                    playerIndex: opponentIndex,
                    observedRounds: 0,
                    blindBidRate: 0.0,
                    exactBidRate: 0.0,
                    overbidRate: 0.0,
                    underbidRate: 0.0,
                    averageBidAggression: 0.0
                )
            }

            let blindCount = results.reduce(0) { $0 + ($1.isBlind ? 1 : 0) }
            let exactCount = results.reduce(0) { $0 + ($1.bidMatched ? 1 : 0) }
            let overbidCount = results.reduce(0) { $0 + ($1.tricksTaken > $1.bid ? 1 : 0) }
            let underbidCount = results.reduce(0) { $0 + ($1.tricksTaken < $1.bid ? 1 : 0) }
            let bidAggressionSum = results.reduce(0.0) { partial, result in
                let cards = Double(max(1, result.cardsInRound))
                return partial + Double(max(0, result.bid)) / cards
            }
            let rounds = Double(observedRounds)

            return BotOpponentModel.OpponentSnapshot(
                playerIndex: opponentIndex,
                observedRounds: observedRounds,
                blindBidRate: Double(blindCount) / rounds,
                exactBidRate: Double(exactCount) / rounds,
                overbidRate: Double(overbidCount) / rounds,
                underbidRate: Double(underbidCount) / rounds,
                averageBidAggression: bidAggressionSum / rounds
            )
        }

        return BotOpponentModel(
            perspectivePlayerIndex: playerIndex,
            leftNeighborIndex: leftNeighborIndex,
            snapshots: snapshots
        )
    }
}
