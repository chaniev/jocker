//
//  MoveUtilityComposer.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

struct MoveUtilityComposer {
    private struct Components {
        let base: Double
        let tactical: Double
        let risk: Double
        let opponent: Double
        let joker: Double
    }

    private let strategy: BotTuning.TurnStrategy
    private let policy: BotRuntimePolicy.Ranking.MoveComposition
    private let opponentPressureAdjuster: OpponentPressureAdjuster

    init(
        strategy: BotTuning.TurnStrategy,
        policy: BotRuntimePolicy.Ranking.MoveComposition,
        opponentPressureAdjuster: OpponentPressureAdjuster
    ) {
        self.strategy = strategy
        self.policy = policy
        self.opponentPressureAdjuster = opponentPressureAdjuster
    }

    func moveUtility(
        projectedScore: Double,
        immediateWinProbability: Double,
        threat: Double,
        move: BotTurnCandidateRankingService.Move,
        context: BotTurnCandidateRankingService.UtilityContext,
        matchCatchUpAdjustment: Double,
        premiumPreserveAdjustment: Double,
        penaltyAvoidAdjustment: Double,
        premiumDenyAdjustment: Double,
        opponentBidPressureAdjustment: Double,
        opponentIntentionAdjustment: Double,
        jokerAdjustment: Double
    ) -> Double {
        let premiumSnapshot = context.matchContext?.premium
        let isOwnPremiumProtectionContext = premiumSnapshot.map {
            $0.isPremiumCandidateSoFar || $0.isZeroPremiumCandidateSoFar
        } ?? false
        let hasOpponentPremiumPressureContext = premiumSnapshot.map {
            $0.leftNeighborIsPremiumCandidateSoFar || $0.opponentPremiumCandidatesSoFarCount > 0
        } ?? false
        let isPenaltyTargetRiskContext = premiumSnapshot.map {
            $0.isPenaltyTargetRiskSoFar && $0.premiumCandidatesThreateningPenaltyCount > 0
        } ?? false

        var tacticalComponent = 0.0
        var riskComponent =
            matchCatchUpAdjustment +
            premiumPreserveAdjustment +
            penaltyAvoidAdjustment +
            premiumDenyAdjustment
        let opponentComponent = opponentBidPressureAdjustment + opponentIntentionAdjustment
        var jokerComponent = jokerAdjustment

        if !context.shouldChaseTrick {
            if isOwnPremiumProtectionContext && context.trickDeltaToBidBeforeMove == 0 {
                let lateBlockWeight = policy.lateExactBidDumpProgressBase +
                    policy.lateExactBidDumpProgressWeight *
                    (context.matchContext?.blockProgressFraction ?? 0.0)
                riskComponent +=
                    (1.0 - immediateWinProbability) *
                    policy.lateExactBidDumpBase *
                    lateBlockWeight
            }

            if context.trickDeltaToBidBeforeMove > 0 &&
                !isOwnPremiumProtectionContext &&
                !hasOpponentPremiumPressureContext &&
                !isPenaltyTargetRiskContext {
                let overbidSeverity = min(
                    policy.neutralOverbidSeverityCap,
                    Double(context.trickDeltaToBidBeforeMove)
                )
                tacticalComponent +=
                    immediateWinProbability *
                    policy.neutralOverbidBonus *
                    overbidSeverity
            }

            if context.trickDeltaToBidBeforeMove > 0 && hasOpponentPremiumPressureContext {
                let disciplineSignal = opponentPressureAdjuster.disciplineSignal(from: context.matchContext)
                let erraticSignal = clamped(
                    (policy.pressuredOverbidErraticCenter - disciplineSignal) *
                        policy.pressuredOverbidErraticScale,
                    min: 0.0,
                    max: 1.0
                )
                let overbidSeverity = min(
                    policy.neutralOverbidSeverityCap,
                    Double(context.trickDeltaToBidBeforeMove)
                )
                tacticalComponent +=
                    (1.0 - immediateWinProbability) *
                    (policy.pressuredOverbidBase + policy.pressuredOverbidSeverityWeight * overbidSeverity) *
                    erraticSignal
            }

            if isPenaltyTargetRiskContext {
                riskComponent += (1.0 - immediateWinProbability) * policy.penaltyRiskDumpBonus
            }
        }

        let blindChaseOpponentMultiplier = (context.isBlindRound && context.shouldChaseTrick)
            ? opponentPressureAdjuster.blindChaseContestMultiplier(from: context.matchContext)
            : 1.0
        let blindRewardMultiplier = context.isBlindRound
            ? policy.blindRewardMultiplier * blindChaseOpponentMultiplier
            : 1.0
        let blindRiskMultiplier = context.isBlindRound ? policy.blindRiskMultiplier : 1.0
        let isLeadJoker = move.card.isJoker && context.trick.playedCards.isEmpty

        if context.shouldChaseTrick {
            let conservatism = max(0.0, 1.0 - context.chasePressure)
            let mustWinAllRemaining =
                context.tricksNeededToMatchBid >= context.tricksRemainingIncludingCurrent
            tacticalComponent += immediateWinProbability *
                strategy.chaseWinProbabilityWeight *
                (1.0 + context.chasePressure) *
                blindRewardMultiplier
            tacticalComponent -= threat *
                strategy.chaseThreatPenaltyWeight *
                conservatism *
                blindRiskMultiplier

            if move.card.isJoker && context.hasWinningNonJoker {
                jokerComponent -= strategy.chaseSpendJokerPenalty *
                    conservatism *
                    blindRiskMultiplier
            }

            if move.card.isJoker && context.hasWinningNonJoker && !mustWinAllRemaining {
                jokerComponent -= strategy.chaseSpendJokerPenalty *
                    (policy.chaseJokerExtraSpendBase +
                        policy.chaseJokerExtraSpendPressureWeight * context.chasePressure) *
                    blindRiskMultiplier
            }

            if mustWinAllRemaining {
                jokerComponent -= (1.0 - immediateWinProbability) *
                    strategy.chaseSpendJokerPenalty *
                    blindRiskMultiplier
            }

            if isLeadJoker, case .some(.wish) = move.decision.leadDeclaration {
                jokerComponent += strategy.chaseLeadWishBonus *
                    (policy.chaseLeadWishPressureBase +
                        context.chasePressure * policy.chaseLeadWishPressureWeight) *
                    (context.isBlindRound ? policy.chaseLeadWishBlindMultiplier : 1.0)
            }
        } else {
            tacticalComponent +=
                (1.0 - immediateWinProbability) * strategy.dumpAvoidWinWeight * blindRewardMultiplier
            tacticalComponent += threat * strategy.dumpThreatRewardWeight * blindRewardMultiplier

            if move.card.isJoker && context.hasLosingNonJoker {
                jokerComponent -= strategy.dumpSpendJokerPenalty * blindRiskMultiplier
            }
            if move.card.isJoker && move.decision.style == .faceUp && !context.trick.playedCards.isEmpty {
                jokerComponent -= strategy.dumpFaceUpNonLeadJokerPenalty * blindRiskMultiplier
            }

            if isLeadJoker, case .some(.takes(let suit)) = move.decision.leadDeclaration {
                if let trump = context.trump, suit != trump {
                    jokerComponent += strategy.dumpLeadTakesNonTrumpBonus *
                        (context.isBlindRound ? policy.dumpLeadTakesBlindMultiplier : 1.0)
                }
            }
        }

        return composeUtility(
            components: .init(
                base: projectedScore,
                tactical: tacticalComponent,
                risk: riskComponent,
                opponent: opponentComponent,
                joker: jokerComponent
            ),
            immediateWinProbability: immediateWinProbability,
            threat: threat,
            move: move,
            context: context
        )
    }

    private func composeUtility(
        components: Components,
        immediateWinProbability: Double,
        threat: Double,
        move: BotTurnCandidateRankingService.Move,
        context: BotTurnCandidateRankingService.UtilityContext
    ) -> Double {
        let blockUrgency = context.matchContext?.blockProgressFraction ?? 0.0
        let urgency = clamped(
            policy.urgencyChasePressureWeight * context.chasePressure +
                policy.urgencyBlockProgressWeight * blockUrgency,
            min: 0.0,
            max: 1.0
        )
        let penaltyRisk = context.matchContext?.premium?.isPenaltyTargetRiskSoFar == true
        let hasOpponentEvidence = context.opponentIntention?.hasEvidence == true

        let tacticalMultiplier = clamped(
            1.0 + policy.tacticalMultiplierUrgencyWeight * urgency +
                (context.shouldChaseTrick ? policy.tacticalMultiplierChaseBonus : 0.0),
            min: policy.tacticalMultiplierMin,
            max: policy.tacticalMultiplierMax
        )
        let riskMultiplier = clamped(
            1.0 + policy.riskMultiplierUrgencyWeight * urgency +
                (penaltyRisk ? policy.riskMultiplierPenaltyRiskBonus : 0.0),
            min: policy.riskMultiplierMin,
            max: policy.riskMultiplierMax
        )
        let opponentMultiplier = clamped(
            1.0 + policy.opponentMultiplierUrgencyWeight * urgency +
                (hasOpponentEvidence ? policy.opponentMultiplierEvidenceBonus : 0.0),
            min: policy.opponentMultiplierMin,
            max: policy.opponentMultiplierMax
        )
        let jokerMultiplier = move.card.isJoker
            ? clamped(
                1.0 + policy.jokerMultiplierUrgencyWeight * urgency +
                    (context.shouldChaseTrick
                        ? policy.jokerMultiplierChaseBonus
                        : policy.jokerMultiplierDumpBonus),
                min: policy.jokerMultiplierMin,
                max: policy.jokerMultiplierMax
            )
            : 1.0

        let cappedTactical = clamped(
            components.tactical,
            min: -policy.cappedTacticalMagnitude,
            max: policy.cappedTacticalMagnitude
        )
        let cappedRisk = clamped(
            components.risk,
            min: -policy.cappedRiskMagnitude,
            max: policy.cappedRiskMagnitude
        )
        let cappedOpponent = clamped(
            components.opponent,
            min: -policy.cappedOpponentMagnitude,
            max: policy.cappedOpponentMagnitude
        )
        let cappedJoker = clamped(
            components.joker,
            min: -policy.cappedJokerMagnitude,
            max: policy.cappedJokerMagnitude
        )

        let composed =
            components.base +
            cappedTactical * tacticalMultiplier +
            cappedRisk * riskMultiplier +
            cappedOpponent * opponentMultiplier +
            cappedJoker * jokerMultiplier

        let baselineAnchor =
            components.base +
            cappedTactical +
            cappedRisk +
            cappedOpponent +
            cappedJoker
        let stabilizationWindow = policy.stabilizationWindowBase +
            policy.stabilizationWindowMissWeight * (1.0 - immediateWinProbability) +
            policy.stabilizationWindowThreatWeight * threat
        let minValue = baselineAnchor - stabilizationWindow
        let maxValue = baselineAnchor + stabilizationWindow
        return clamped(composed, min: minValue, max: maxValue)
    }

    private func clamped(
        _ value: Double,
        min lowerBound: Double,
        max upperBound: Double
    ) -> Double {
        Swift.min(upperBound, Swift.max(lowerBound, value))
    }
}
