//
//  PremiumPreserveAdjuster.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

struct PremiumPreserveAdjuster {
    private let rankingPolicy: BotRuntimePolicy.Ranking

    init(rankingPolicy: BotRuntimePolicy.Ranking) {
        self.rankingPolicy = rankingPolicy
    }

    func utilityAdjustment(
        immediateWinProbability: Double,
        context: BotTurnCandidateRankingService.UtilityContext
    ) -> Double {
        guard let matchContext = context.matchContext else { return 0.0 }
        guard let premium = matchContext.premium else { return 0.0 }
        guard premium.isPremiumCandidateSoFar || premium.isZeroPremiumCandidateSoFar else {
            return 0.0
        }

        let evidenceWeight = rankingPolicy.premiumPreserveEvidenceBase +
            rankingPolicy.premiumPreserveEvidenceProgress *
            min(
                1.0,
                Double(max(0, premium.completedRoundsInBlock)) /
                    Double(max(1, matchContext.totalRoundsInBlock - 1))
            )
        let closingRoundsWeight: Double
        switch premium.remainingRoundsInBlock {
        case ...1:
            closingRoundsWeight = rankingPolicy.premiumPreserveClosingRoundsWeight
        case 2:
            closingRoundsWeight = rankingPolicy.premiumPreserveClosingRoundsTwo
        default:
            closingRoundsWeight = rankingPolicy.premiumPreserveClosingRoundsDefault
        }
        let progressWeight =
            (rankingPolicy.premiumPreserveProgressBase +
                rankingPolicy.premiumPreserveEvidenceProgressWeight * matchContext.blockProgressFraction) *
            evidenceWeight *
            closingRoundsWeight
        var adjustment = 0.0
        let bidTrajectoryDelta = context.trickDeltaToBidBeforeMove
        let isExactlyOnBidBeforeMove = bidTrajectoryDelta == 0
        let hasAlreadyBrokenRoundExactBid = bidTrajectoryDelta > 0

        if premium.isPremiumCandidateSoFar {
            if context.shouldChaseTrick {
                let deficitUrgency = min(
                    1.0,
                    Double(context.tricksNeededToMatchBid) /
                        Double(max(1, context.tricksRemainingIncludingCurrent))
                )
                let mustWinAllRemaining =
                    context.tricksNeededToMatchBid >= context.tricksRemainingIncludingCurrent
                let trajectoryMultiplier = mustWinAllRemaining
                    ? rankingPolicy.premiumPreserveMustWinAllMultiplier
                    : 1.0
                let zeroPremiumConflictDampener = premium.isZeroPremiumCandidateSoFar
                    ? rankingPolicy.premiumPreserveZeroConflictDampener
                    : 1.0
                adjustment += immediateWinProbability *
                    (rankingPolicy.premiumPreserveChaseBonusBase +
                        rankingPolicy.premiumPreserveChaseBonusProgress * deficitUrgency) *
                    progressWeight *
                    trajectoryMultiplier *
                    zeroPremiumConflictDampener
            } else {
                let exactBidPreserveMultiplier = isExactlyOnBidBeforeMove
                    ? rankingPolicy.premiumPreserveExactBidMultiplier
                    : 1.0
                let alreadyBrokenMultiplier = hasAlreadyBrokenRoundExactBid
                    ? rankingPolicy.premiumPreserveAlreadyBrokenMultiplier
                    : 1.0
                adjustment += (1.0 - immediateWinProbability) *
                    rankingPolicy.premiumPreserveDumpBonus *
                    progressWeight *
                    exactBidPreserveMultiplier *
                    alreadyBrokenMultiplier
            }
        }

        if premium.isZeroPremiumCandidateSoFar {
            if context.shouldChaseTrick {
                let alreadyBrokenMultiplier = hasAlreadyBrokenRoundExactBid
                    ? rankingPolicy.premiumPreserveZeroAlreadyBrokenMultiplier
                    : 1.0
                adjustment -= immediateWinProbability *
                    rankingPolicy.premiumPreserveZeroChasePenalty *
                    progressWeight *
                    alreadyBrokenMultiplier
            } else {
                let exactZeroProtectMultiplier = isExactlyOnBidBeforeMove
                    ? rankingPolicy.premiumPreserveExactZeroMultiplier
                    : 1.0
                let alreadyBrokenMultiplier = hasAlreadyBrokenRoundExactBid
                    ? rankingPolicy.premiumPreserveZeroAlreadyBrokenMultiplier
                    : 1.0
                adjustment += (1.0 - immediateWinProbability) *
                    rankingPolicy.premiumPreserveZeroDumpBonus *
                    progressWeight *
                    exactZeroProtectMultiplier *
                    alreadyBrokenMultiplier
            }
        }

        return adjustment
    }
}
