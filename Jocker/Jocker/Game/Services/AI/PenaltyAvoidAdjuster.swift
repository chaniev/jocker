//
//  PenaltyAvoidAdjuster.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

struct PenaltyAvoidAdjuster {
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
        projectedScore: Double,
        immediateWinProbability: Double,
        context: BotTurnCandidateRankingService.UtilityContext
    ) -> Double {
        guard let matchContext = context.matchContext else { return 0.0 }
        guard let premium = matchContext.premium else { return 0.0 }
        guard premium.isPenaltyTargetRiskSoFar else { return 0.0 }
        guard premium.premiumCandidatesThreateningPenaltyCount > 0 else { return 0.0 }

        let threatCountWeight = min(
            rankingPolicy.penaltyAvoidThreatCountMax,
            rankingPolicy.penaltyAvoidThreatCountMin +
                rankingPolicy.penaltyAvoidThreatCountProgress *
                Double(premium.premiumCandidatesThreateningPenaltyCount)
        )
        let evidenceWeight = rankingPolicy.penaltyAvoidEvidenceBase +
            rankingPolicy.penaltyAvoidEvidenceProgress *
            min(
                1.0,
                Double(max(0, premium.completedRoundsInBlock)) /
                    Double(max(1, matchContext.totalRoundsInBlock - 1))
            )
        let endBlockWeight = rankingPolicy.penaltyAvoidEndBlockBase +
            rankingPolicy.penaltyAvoidEndBlockProgress * matchContext.blockProgressFraction
        let opponentStyleMultiplier = opponentPressureAdjuster.premiumDenyPressureMultiplier(
            from: matchContext
        )
        let riskWeight = threatCountWeight *
            evidenceWeight *
            endBlockWeight *
            opponentStyleMultiplier
        let lateBlockPenaltyAvoidBoost = 1.0 +
            rankingPolicy.penaltyAvoidLateBlockBoost * matchContext.blockProgressFraction

        var adjustment = 0.0
        let positiveProjectedScore = max(0.0, projectedScore)
        if positiveProjectedScore > 0 {
            adjustment -= positiveProjectedScore *
                rankingPolicy.penaltyAvoidProjectedScoreWeight *
                riskWeight
        }

        if context.shouldChaseTrick {
            if context.trickDeltaToBidBeforeMove > 0 {
                adjustment -= immediateWinProbability *
                    rankingPolicy.penaltyAvoidOverbidPenalty *
                    riskWeight *
                    lateBlockPenaltyAvoidBoost
            }
        } else {
            adjustment += (1.0 - immediateWinProbability) *
                rankingPolicy.penaltyAvoidDumpBonus *
                riskWeight *
                lateBlockPenaltyAvoidBoost
        }

        return adjustment
    }
}
