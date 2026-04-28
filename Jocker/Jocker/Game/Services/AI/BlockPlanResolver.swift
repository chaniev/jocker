//
//  BlockPlanResolver.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

struct BlockPlanResolver {
    struct BlockPlan {
        let urgency: Double
        let riskBudget: Double
        let preserveOwnPremiumBias: Double
        let denyOpponentPremiumBias: Double
    }

    private let rankingPolicy: BotRuntimePolicy.Ranking
    private let opponentPressureAdjuster: OpponentPressureAdjuster

    init(
        rankingPolicy: BotRuntimePolicy.Ranking,
        opponentPressureAdjuster: OpponentPressureAdjuster
    ) {
        self.rankingPolicy = rankingPolicy
        self.opponentPressureAdjuster = opponentPressureAdjuster
    }

    func matchCatchUpUtilityAdjustment(
        projectedScore: Double,
        immediateWinProbability: Double,
        threat: Double,
        context: BotTurnCandidateRankingService.UtilityContext
    ) -> Double {
        guard let plan = blockPlan(from: context.matchContext) else { return 0.0 }
        guard abs(plan.riskBudget) > rankingPolicy.utilityTieTolerance else { return 0.0 }

        let phase = context.matchContext.map {
            BotBlockPhase.from(blockProgressFraction: $0.blockProgressFraction)
        } ?? .mid
        let phaseMultiplier = rankingPolicy.phaseMatchCatchUp.multiplier(for: phase)

        let chaseAggressionSignal =
            immediateWinProbability * rankingPolicy.matchCatchUpChaseAggressionBase -
            threat * rankingPolicy.matchCatchUpChaseAggressionThreatWeight +
            context.chasePressure * rankingPolicy.matchCatchUpChaseAggressionPressureWeight
        let finalTrickUrgencyBonus =
            context.tricksNeededToMatchBid >= context.tricksRemainingIncludingCurrent &&
            context.shouldChaseTrick
            ? rankingPolicy.matchCatchUpFinalTrickUrgencyBonus
            : 0.0
        let opponentUrgencyMultiplier = opponentPressureAdjuster.matchCatchUpUrgencyMultiplier(
            from: context.matchContext
        )
        let urgencyWeight = rankingPolicy.matchCatchUpOpponentUrgencyBase +
            rankingPolicy.matchCatchUpUrgencyWeightProgress * plan.urgency

        if context.shouldChaseTrick {
            var adjustment = plan.riskBudget *
                opponentUrgencyMultiplier *
                (chaseAggressionSignal + finalTrickUrgencyBonus) *
                urgencyWeight
            if plan.preserveOwnPremiumBias > 0, context.trickDeltaToBidBeforeMove >= 0 {
                adjustment -= immediateWinProbability *
                    rankingPolicy.matchCatchUpPreservePremiumPenalty *
                    plan.preserveOwnPremiumBias
            }
            return adjustment * phaseMultiplier
        }

        let conservativeDumpSignal =
            (1.0 - immediateWinProbability) * rankingPolicy.matchCatchUpConservativeDumpBase +
            threat * rankingPolicy.matchCatchUpConservativeDumpThreatWeight +
            max(0.0, projectedScore) * rankingPolicy.matchCatchUpConservativeDumpScoreWeight
        var adjustment = (-plan.riskBudget) *
            opponentUrgencyMultiplier *
            conservativeDumpSignal *
            (rankingPolicy.matchCatchUpUrgencyWeightBase +
                rankingPolicy.matchCatchUpUrgencyWeightProgress * urgencyWeight)
        if plan.denyOpponentPremiumBias > 0 {
            adjustment -=
                (1.0 - immediateWinProbability) *
                rankingPolicy.matchCatchUpDenyOpponentPenaltyBase *
                plan.denyOpponentPremiumBias
        }
        return adjustment * phaseMultiplier
    }

    private func blockPlan(from matchContext: BotMatchContext?) -> BlockPlan? {
        guard let matchContext else { return nil }
        guard matchContext.playerCount > 1 else { return nil }
        guard matchContext.playerIndex >= 0, matchContext.playerIndex < matchContext.playerCount else {
            return nil
        }
        guard matchContext.totalScores.count >= matchContext.playerCount else { return nil }

        let scorePerspective = scorePerspective(from: matchContext)
        guard let scorePerspective else {
            return nil
        }

        let behindLeader = max(0, scorePerspective.leaderScore - scorePerspective.ownScore)
        let safeLead = max(0, scorePerspective.ownScore - scorePerspective.bestOpponentScore)

        let scoreScale = matchContext.block == .fourth
            ? rankingPolicy.fourthBlockScoreScale
            : rankingPolicy.standardBlockScoreScale
        let behindSignal = min(1.0, Double(behindLeader) / scoreScale)
        let leadSignal = min(1.0, Double(safeLead) / scoreScale)
        let blockWeight = matchContext.block == .fourth ? rankingPolicy.fourthBlockWeight : 1.0

        let premium = matchContext.premium
        let preserveOwnPremiumBias: Double = {
            guard let premium else { return 0.0 }
            guard premium.isPremiumCandidateSoFar || premium.isZeroPremiumCandidateSoFar else {
                return 0.0
            }
            return rankingPolicy.premiumPreserveBase +
                rankingPolicy.premiumPreserveProgressWeight * matchContext.blockProgressFraction
        }()
        let denyOpponentPremiumBias: Double = {
            guard let premium else { return 0.0 }
            guard premium.leftNeighborIsPremiumCandidateSoFar ||
                    premium.isPenaltyTargetRiskSoFar ||
                    premium.opponentPremiumCandidatesSoFarCount > 0 else {
                return 0.0
            }
            return rankingPolicy.denyPremiumBase +
                rankingPolicy.denyPremiumProgressWeight * matchContext.blockProgressFraction
        }()

        var riskBudget = (behindSignal - leadSignal) * blockWeight
        let baseActivationWeight = rankingPolicy.baseActivationWeight +
            rankingPolicy.progressActivationWeight * matchContext.blockProgressFraction
        let roundsRemainingForActivation = max(
            0,
            matchContext.totalRoundsInBlock - matchContext.roundIndexInBlock - 1
        )
        let finalRoundsActivationBoost: Double
        switch roundsRemainingForActivation {
        case 0...1:
            finalRoundsActivationBoost = rankingPolicy.finalRoundsActivationFull
        case 2:
            finalRoundsActivationBoost = rankingPolicy.finalRoundsActivationHalf
        default:
            finalRoundsActivationBoost = baseActivationWeight
        }
        riskBudget *= min(1.0, max(0.0, finalRoundsActivationBoost))
        riskBudget = min(1.0, max(-1.0, riskBudget))

        let roundsRemaining: Int = {
            if let premium {
                return max(0, premium.remainingRoundsInBlock)
            }
            let estimated = matchContext.totalRoundsInBlock - matchContext.roundIndexInBlock - 1
            return max(0, estimated)
        }()
        let endgameUrgency: Double
        switch roundsRemaining {
        case 0...1:
            endgameUrgency = rankingPolicy.endgameUrgencyFull
        case 2:
            endgameUrgency = rankingPolicy.endgameUrgencyTwoRounds
        case 3:
            endgameUrgency = rankingPolicy.endgameUrgencyThreeRounds
        default:
            endgameUrgency = rankingPolicy.endgameUrgencyDefault
        }
        let urgency = min(
            1.0,
            max(
                0.0,
                max(
                    abs(riskBudget) * rankingPolicy.riskBudgetWeight,
                    endgameUrgency * rankingPolicy.endgameUrgencyWeight +
                        matchContext.blockProgressFraction * rankingPolicy.blockProgressWeight +
                        max(preserveOwnPremiumBias, denyOpponentPremiumBias) *
                        rankingPolicy.premiumBiasWeight
                )
            )
        )

        return BlockPlan(
            urgency: urgency,
            riskBudget: riskBudget,
            preserveOwnPremiumBias: preserveOwnPremiumBias,
            denyOpponentPremiumBias: denyOpponentPremiumBias
        )
    }

    private func scorePerspective(
        from matchContext: BotMatchContext
    ) -> (ownScore: Int, leaderScore: Int, bestOpponentScore: Int)? {
        if matchContext.isPairsMode {
            let ownTeamIndex = matchContext.playerIndex.isMultiple(of: 2) ? 0 : 1
            guard matchContext.teamScores.indices.contains(ownTeamIndex) else { return nil }
            let ownScore = matchContext.teamScores[ownTeamIndex]
            let opponentTeamIndex = ownTeamIndex == 0 ? 1 : 0
            let bestOpponentScore = matchContext.teamScores.indices.contains(opponentTeamIndex)
                ? matchContext.teamScores[opponentTeamIndex]
                : ownScore
            let leaderScore = max(ownScore, bestOpponentScore)
            return (ownScore, leaderScore, bestOpponentScore)
        }

        let ownScore = matchContext.totalScores[matchContext.playerIndex]
        let opponentScores = matchContext.totalScores.enumerated()
            .filter { $0.offset != matchContext.playerIndex }
            .map(\.element)
        guard let leaderScore = matchContext.totalScores.max(), !opponentScores.isEmpty else {
            return nil
        }
        return (ownScore, leaderScore, opponentScores.max() ?? ownScore)
    }
}
