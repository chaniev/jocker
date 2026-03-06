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
    private let jokerPolicy: BotTuning.JokerPolicy
    private let opponentPressureAdjuster: OpponentPressureAdjuster

    init(
        strategy: BotTuning.TurnStrategy,
        jokerPolicy: BotTuning.JokerPolicy,
        opponentPressureAdjuster: OpponentPressureAdjuster
    ) {
        self.strategy = strategy
        self.jokerPolicy = jokerPolicy
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
                let lateBlockWeight = 0.5 + 0.5 * (context.matchContext?.blockProgressFraction ?? 0.0)
                riskComponent += (1.0 - immediateWinProbability) * 64.0 * lateBlockWeight
            }

            if context.trickDeltaToBidBeforeMove > 0 &&
                !isOwnPremiumProtectionContext &&
                !hasOpponentPremiumPressureContext &&
                !isPenaltyTargetRiskContext {
                let overbidSeverity = min(2.0, Double(context.trickDeltaToBidBeforeMove))
                tacticalComponent += immediateWinProbability * 14.0 * overbidSeverity
            }

            if context.trickDeltaToBidBeforeMove > 0 && hasOpponentPremiumPressureContext {
                let disciplineSignal = opponentPressureAdjuster.disciplineSignal(from: context.matchContext)
                let erraticSignal = clamped((0.5 - disciplineSignal) * 2.0, min: 0.0, max: 1.0)
                let overbidSeverity = min(2.0, Double(context.trickDeltaToBidBeforeMove))
                tacticalComponent +=
                    (1.0 - immediateWinProbability) *
                    (12.0 + 20.0 * overbidSeverity) *
                    erraticSignal
            }

            if isPenaltyTargetRiskContext {
                riskComponent += (1.0 - immediateWinProbability) * 8.0
            }
        }

        let blindChaseOpponentMultiplier = (context.isBlindRound && context.shouldChaseTrick)
            ? opponentPressureAdjuster.blindChaseContestMultiplier(from: context.matchContext)
            : 1.0
        let blindRewardMultiplier = context.isBlindRound ? 1.55 * blindChaseOpponentMultiplier : 1.0
        let blindRiskMultiplier = context.isBlindRound ? 1.30 : 1.0
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
                jokerComponent -= jokerPolicy.chaseSpendJokerPenalty *
                    conservatism *
                    blindRiskMultiplier
            }

            if move.card.isJoker && context.hasWinningNonJoker && !mustWinAllRemaining {
                jokerComponent -= jokerPolicy.chaseSpendJokerPenalty *
                    (0.55 + 0.45 * context.chasePressure) *
                    blindRiskMultiplier
            }

            if mustWinAllRemaining {
                jokerComponent -= (1.0 - immediateWinProbability) *
                    jokerPolicy.chaseSpendJokerPenalty *
                    blindRiskMultiplier
            }

            if isLeadJoker, case .some(.wish) = move.decision.leadDeclaration {
                jokerComponent += jokerPolicy.chaseLeadWishBonus *
                    (0.5 + context.chasePressure * 0.5) *
                    (context.isBlindRound ? 1.15 : 1.0)
            }
        } else {
            tacticalComponent +=
                (1.0 - immediateWinProbability) * strategy.dumpAvoidWinWeight * blindRewardMultiplier
            tacticalComponent += threat * strategy.dumpThreatRewardWeight * blindRewardMultiplier

            if move.card.isJoker && context.hasLosingNonJoker {
                jokerComponent -= jokerPolicy.dumpSpendJokerPenalty * blindRiskMultiplier
            }
            if move.card.isJoker && move.decision.style == .faceUp && !context.trick.playedCards.isEmpty {
                jokerComponent -= jokerPolicy.dumpFaceUpNonLeadJokerPenalty * blindRiskMultiplier
            }

            if isLeadJoker, case .some(.takes(let suit)) = move.decision.leadDeclaration {
                if let trump = context.trump, suit != trump {
                    jokerComponent += jokerPolicy.dumpLeadTakesNonTrumpBonus *
                        (context.isBlindRound ? 1.2 : 1.0)
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
            0.58 * context.chasePressure + 0.42 * blockUrgency,
            min: 0.0,
            max: 1.0
        )
        let penaltyRisk = context.matchContext?.premium?.isPenaltyTargetRiskSoFar == true
        let hasOpponentEvidence = context.opponentIntention?.hasEvidence == true

        let tacticalMultiplier = clamped(
            1.0 + 0.04 * urgency + (context.shouldChaseTrick ? 0.03 : 0.0),
            min: 0.95,
            max: 1.10
        )
        let riskMultiplier = clamped(
            1.0 + 0.08 * urgency + (penaltyRisk ? 0.06 : 0.0),
            min: 0.94,
            max: 1.18
        )
        let opponentMultiplier = clamped(
            1.0 + 0.06 * urgency + (hasOpponentEvidence ? 0.05 : 0.0),
            min: 0.95,
            max: 1.16
        )
        let jokerMultiplier = move.card.isJoker
            ? clamped(
                1.0 + 0.10 * urgency + (context.shouldChaseTrick ? 0.05 : 0.06),
                min: 0.90,
                max: 1.22
            )
            : 1.0

        let cappedTactical = clamped(components.tactical, min: -180.0, max: 180.0)
        let cappedRisk = clamped(components.risk, min: -180.0, max: 180.0)
        let cappedOpponent = clamped(components.opponent, min: -120.0, max: 120.0)
        let cappedJoker = clamped(components.joker, min: -180.0, max: 180.0)

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
        let stabilizationWindow = 90.0 + 50.0 * (1.0 - immediateWinProbability) + 0.15 * threat
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
