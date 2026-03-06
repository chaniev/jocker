//
//  PremiumDenyAdjuster.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

struct PremiumDenyAdjuster {
    private let rankingPolicy: BotRuntimePolicy.Ranking
    private let opponentPressureAdjuster: OpponentPressureAdjuster

    init(
        rankingPolicy: BotRuntimePolicy.Ranking,
        opponentPressureAdjuster: OpponentPressureAdjuster
    ) {
        self.rankingPolicy = rankingPolicy
        self.opponentPressureAdjuster = opponentPressureAdjuster
    }

    func utilityAdjustment(
        immediateWinProbability: Double,
        context: BotTurnCandidateRankingService.UtilityContext
    ) -> Double {
        guard let matchContext = context.matchContext else { return 0.0 }
        guard let premium = matchContext.premium else { return 0.0 }
        guard premium.leftNeighborIsPremiumCandidateSoFar || premium.opponentPremiumCandidatesSoFarCount > 0 else {
            return 0.0
        }

        if premium.isPremiumCandidateSoFar || premium.isZeroPremiumCandidateSoFar {
            return 0.0
        }

        let evidenceWeight = rankingPolicy.premiumDenyEvidenceBase +
            rankingPolicy.premiumDenyEvidenceProgress *
            min(
                1.0,
                Double(max(0, premium.completedRoundsInBlock)) /
                    Double(max(1, matchContext.totalRoundsInBlock - 1))
            )
        let endBlockWeight = rankingPolicy.premiumDenyEndBlockBase +
            rankingPolicy.premiumDenyEndBlockProgress * matchContext.blockProgressFraction
        let leftNeighborWeight = premium.leftNeighborIsPremiumCandidateSoFar
            ? rankingPolicy.premiumDenyLeftNeighborWeight
            : 0.0
        let otherOpponentCandidates = max(
            0,
            premium.opponentPremiumCandidatesSoFarCount - (premium.leftNeighborIsPremiumCandidateSoFar ? 1 : 0)
        )
        let otherOpponentsWeight = min(
            rankingPolicy.premiumDenyOtherOpponentsMax,
            Double(otherOpponentCandidates) * rankingPolicy.premiumDenyOtherOpponentsWeight
        )
        let opponentStyleMultiplier = opponentPressureAdjuster.premiumDenyPressureMultiplier(
            from: matchContext
        )
        let denyWeight = (leftNeighborWeight + otherOpponentsWeight) *
            evidenceWeight *
            endBlockWeight *
            opponentStyleMultiplier
        guard denyWeight > 0 else { return 0.0 }
        let overbidRelaxation = context.trickDeltaToBidBeforeMove > 0
            ? rankingPolicy.premiumDenyOverbidRelaxation
            : 1.0

        if context.shouldChaseTrick {
            return immediateWinProbability *
                rankingPolicy.premiumDenyChaseBonus *
                denyWeight *
                overbidRelaxation
        }

        return -(1.0 - immediateWinProbability) *
            rankingPolicy.premiumDenyDumpPenalty *
            denyWeight *
            overbidRelaxation
    }
}
