//
//  BotBlindBidPolicy.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

struct BotBlindBidPolicy {
    private let tuning: BotTuning.Bidding
    private let policy: BotRuntimePolicy.Bidding.BlindPolicy
    private let monteCarloEstimator: BotBlindBidMonteCarloEstimator

    init(
        tuning: BotTuning.Bidding,
        policy: BotRuntimePolicy.Bidding.BlindPolicy,
        monteCarloEstimator: BotBlindBidMonteCarloEstimator
    ) {
        self.tuning = tuning
        self.policy = policy
        self.monteCarloEstimator = monteCarloEstimator
    }

    func makePreDealBlindBid(
        playerIndex: Int,
        dealerIndex: Int,
        cardsInRound: Int,
        allowedBlindBids: [Int],
        canChooseBlind: Bool,
        totalScores: [Int],
        matchContext: BotMatchContext? = nil
    ) -> Int? {
        guard canChooseBlind else { return nil }

        let allowed = Array(Set(allowedBlindBids)).sorted()
        guard !allowed.isEmpty else { return nil }

        let clampedPlayerIndex = min(max(playerIndex, 0), max(0, totalScores.count - 1))
        let clampedDealerIndex = min(max(dealerIndex, 0), max(0, totalScores.count - 1))
        let scorePerspective = resolveScorePerspective(
            playerIndex: clampedPlayerIndex,
            totalScores: totalScores,
            matchContext: matchContext
        )
        let playerScore = scorePerspective.playerScore
        let leaderScore = scorePerspective.leaderScore
        let closestChaserScore = scorePerspective.closestChaserScore

        let behindByLeader = max(0, leaderScore - playerScore)
        let aheadOfOpponent = max(0, playerScore - closestChaserScore)
        let cards = max(0, cardsInRound)
        let minAllowed = allowed.first ?? 0
        let maxAllowed = allowed.last ?? 0
        let allowedRange = max(0, maxAllowed - minAllowed)

        let catchUpThreshold = max(1, tuning.blindCatchUpBehindThreshold)
        let desperateThreshold = max(catchUpThreshold + 1, tuning.blindDesperateBehindThreshold)
        let safeLeadThreshold = max(1, tuning.blindSafeLeadThreshold)

        var blindRiskScore = policy.riskScoreBase

        if behindByLeader >= tuning.blindCatchUpBehindThreshold {
            blindRiskScore += policy.catchUpThresholdBonus
        }
        if behindByLeader >= tuning.blindDesperateBehindThreshold {
            blindRiskScore += policy.desperateThresholdBonus
        }

        let catchUpPressure = Double(max(0, behindByLeader - catchUpThreshold)) / Double(catchUpThreshold)
        blindRiskScore += catchUpPressure * policy.catchUpPressureMultiplier

        let desperatePressureDenominator = max(1, desperateThreshold - catchUpThreshold)
        let desperatePressure = Double(max(0, behindByLeader - desperateThreshold)) /
            Double(desperatePressureDenominator)
        blindRiskScore += desperatePressure * policy.desperatePressureMultiplier

        let safetyPenalty = Double(aheadOfOpponent) / Double(safeLeadThreshold)
        blindRiskScore -= safetyPenalty * policy.safetyPenaltyMultiplier
        if aheadOfOpponent >= tuning.blindSafeLeadThreshold &&
            behindByLeader < tuning.blindDesperateBehindThreshold {
            blindRiskScore -= policy.leaderPenalty
        }

        if playerScore >= leaderScore {
            blindRiskScore -= policy.tableLeaderPenalty
        }

        if clampedPlayerIndex == clampedDealerIndex {
            blindRiskScore -= policy.dealerPenalty
        } else {
            blindRiskScore += policy.nonDealerBonus
        }

        blindRiskScore += min(
            policy.longRoundBonusCap,
            Double(max(0, cards - policy.longRoundThreshold)) / policy.longRoundBonusDivisor
        )

        let effectiveRoundCapacity = max(1, max(cards, maxAllowed))
        blindRiskScore -= Double(minAllowed) / Double(effectiveRoundCapacity) * policy.minAllowedPenalty

        if allowedRange <= 2 {
            blindRiskScore -= policy.narrowRangePenalty
        } else if allowedRange <= 4 {
            blindRiskScore -= policy.mediumRangePenalty
        } else {
            blindRiskScore += policy.wideRangeBonus
        }

        if let mc = matchContext, mc.block == .fourth {
            let phase = BotBlockPhase.from(blockProgressFraction: mc.blockProgressFraction)
            blindRiskScore *= policy.phaseBlock4.multiplier(for: phase)
        }

        guard blindRiskScore > policy.riskScoreThreshold else { return nil }

        let conservativeShare = min(
            tuning.blindCatchUpTargetShare,
            max(0.0, tuning.blindCatchUpConservativeTargetShare)
        )
        let catchUpShare = max(conservativeShare, tuning.blindCatchUpTargetShare)
        let desperateShare = max(catchUpShare, tuning.blindDesperateTargetShare)

        let modeTargetShare: Double
        if behindByLeader >= desperateThreshold || blindRiskScore >= policy.desperateModeThreshold {
            let overflow = min(
                1.0,
                max(
                    0.0,
                    (blindRiskScore - policy.desperateModeThreshold) / policy.overflowDivisor
                )
            )
            modeTargetShare = desperateShare + policy.desperateOverflowBonus * overflow
        } else if behindByLeader >= catchUpThreshold || blindRiskScore >= policy.catchUpModeThreshold {
            let modeProgress = min(
                1.0,
                max(
                    0.0,
                    (blindRiskScore - policy.catchUpModeThreshold) / policy.modeProgressDivisor
                )
            )
            modeTargetShare = catchUpShare +
                (desperateShare - catchUpShare) * policy.catchUpToDesperateWeight * modeProgress
        } else {
            let modeProgress = min(
                1.0,
                max(
                    0.0,
                    (blindRiskScore - policy.riskScoreThreshold) / policy.conservativeProgressDivisor
                )
            )
            modeTargetShare = conservativeShare +
                (catchUpShare - conservativeShare) * policy.conservativeToCatchUpWeight * modeProgress
        }

        let positionAdjustment = clampedPlayerIndex == clampedDealerIndex
            ? policy.dealerPositionAdjustment
            : policy.nonDealerAdjustment
        let longRoundAdjustment = cards >= policy.longRoundAdjustmentThreshold
            ? policy.longRoundAdjustment
            : 0.0
        let safetyAdjustment = aheadOfOpponent >= tuning.blindSafeLeadThreshold
            ? policy.safetyAdjustment
            : 0.0
        let targetShare = min(
            policy.targetShareCap,
            max(0.0, modeTargetShare + positionAdjustment + longRoundAdjustment + safetyAdjustment)
        )
        let targetBid = nearestAllowedBid(
            to: Int((Double(cards) * targetShare).rounded()),
            allowed: allowed
        )

        let monteCarloInput = BotBlindBidMonteCarloEstimator.Input(
            cardsInRound: cards,
            allowedBlindBids: allowed,
            targetBid: targetBid,
            riskBudget: riskBudget(for: blindRiskScore),
            behindByLeader: behindByLeader,
            aheadOfOpponent: aheadOfOpponent,
            catchUpThreshold: catchUpThreshold,
            desperateThreshold: desperateThreshold,
            safeLeadThreshold: safeLeadThreshold,
            playerIndex: clampedPlayerIndex,
            dealerIndex: clampedDealerIndex,
            totalScores: totalScores
        )
        var bestBid = monteCarloEstimator.bestBlindBid(for: monteCarloInput) ?? targetBid

        let riskBudget = riskBudget(for: blindRiskScore)
        let minimumAggressiveBid = minimumBlindBidFloor(
            targetBid: targetBid,
            behindByLeader: behindByLeader,
            catchUpThreshold: catchUpThreshold,
            desperateThreshold: desperateThreshold,
            blindRiskScore: blindRiskScore,
            riskBudget: riskBudget
        )
        if let flooredBid = firstAllowedBid(atLeast: minimumAggressiveBid, in: allowed), bestBid < flooredBid {
            bestBid = flooredBid
        }

        return bestBid
    }

    private func resolveScorePerspective(
        playerIndex: Int,
        totalScores: [Int],
        matchContext: BotMatchContext?
    ) -> (playerScore: Int, leaderScore: Int, closestChaserScore: Int) {
        guard let matchContext, matchContext.isPairsMode else {
            let playerScore = totalScores.indices.contains(playerIndex) ? totalScores[playerIndex] : 0
            let leaderScore = totalScores.max() ?? playerScore
            let scoresWithoutPlayer = totalScores.enumerated()
                .filter { $0.offset != playerIndex }
                .map(\.element)
            let closestChaserScore = scoresWithoutPlayer
                .filter { $0 <= playerScore }
                .max() ?? playerScore
            return (playerScore, leaderScore, closestChaserScore)
        }

        let ownTeamIndex = playerIndex.isMultiple(of: 2) ? 0 : 1
        let ownTeamScore = matchContext.teamScores.indices.contains(ownTeamIndex)
            ? matchContext.teamScores[ownTeamIndex]
            : 0
        let opponentTeamIndex = ownTeamIndex == 0 ? 1 : 0
        let opponentTeamScore = matchContext.teamScores.indices.contains(opponentTeamIndex)
            ? matchContext.teamScores[opponentTeamIndex]
            : ownTeamScore

        return (
            playerScore: ownTeamScore,
            leaderScore: max(ownTeamScore, opponentTeamScore),
            closestChaserScore: min(ownTeamScore, opponentTeamScore)
        )
    }

    private func riskBudget(for blindRiskScore: Double) -> Double {
        let normalizationDivisor = max(policy.riskBudgetNormalizationDivisor, 0.000_001)
        return min(
            1.0,
            max(0.0, (blindRiskScore - policy.riskScoreThreshold) / normalizationDivisor)
        )
    }

    private func nearestAllowedBid(to target: Int, allowed: [Int]) -> Int {
        guard let first = allowed.first else { return 0 }
        var best = first
        var bestDistance = abs(first - target)

        for bid in allowed.dropFirst() {
            let distance = abs(bid - target)
            if distance < bestDistance || (distance == bestDistance && bid < best) {
                best = bid
                bestDistance = distance
            }
        }

        return best
    }

    private func minimumBlindBidFloor(
        targetBid: Int,
        behindByLeader: Int,
        catchUpThreshold: Int,
        desperateThreshold: Int,
        blindRiskScore: Double,
        riskBudget: Double
    ) -> Int {
        guard targetBid > 0 else { return 0 }
        let isDesperateMode = behindByLeader >= desperateThreshold ||
            blindRiskScore >= policy.desperateModeThreshold
        if isDesperateMode {
            return max(
                policy.minAggressiveBidDesperateMin,
                Int((Double(targetBid) * policy.minAggressiveBidDesperateShare).rounded(.down))
            )
        }
        guard behindByLeader >= catchUpThreshold else { return 0 }
        let catchUpShare = policy.minAggressiveBidCatchUpBase +
            policy.minAggressiveBidCatchUpProgress * riskBudget
        return max(1, Int((Double(targetBid) * catchUpShare).rounded(.down)))
    }

    private func firstAllowedBid(atLeast minimumBid: Int, in allowed: [Int]) -> Int? {
        guard !allowed.isEmpty else { return nil }
        if minimumBid <= allowed[0] {
            return allowed[0]
        }
        return allowed.first(where: { $0 >= minimumBid }) ?? allowed.last
    }
}
