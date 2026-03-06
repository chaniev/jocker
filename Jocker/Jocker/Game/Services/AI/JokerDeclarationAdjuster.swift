//
//  JokerDeclarationAdjuster.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

struct JokerDeclarationAdjuster {
    private let opponentPressureAdjuster: OpponentPressureAdjuster

    init(opponentPressureAdjuster: OpponentPressureAdjuster) {
        self.opponentPressureAdjuster = opponentPressureAdjuster
    }

    func utilityAdjustment(
        immediateWinProbability: Double,
        leadControlReserveAfterMove: Double,
        leadPreferredControlSuitAfterMove: Suit?,
        leadPreferredControlSuitStrengthAfterMove: Double,
        move: BotTurnCandidateRankingService.Move,
        context: BotTurnCandidateRankingService.UtilityContext
    ) -> Double {
        declarationUtilityAdjustment(
            immediateWinProbability: immediateWinProbability,
            leadControlReserveAfterMove: leadControlReserveAfterMove,
            leadPreferredControlSuitAfterMove: leadPreferredControlSuitAfterMove,
            leadPreferredControlSuitStrengthAfterMove: leadPreferredControlSuitStrengthAfterMove,
            move: move,
            context: context
        ) + goalOrientedUtilityAdjustment(
            immediateWinProbability: immediateWinProbability,
            leadControlReserveAfterMove: leadControlReserveAfterMove,
            leadPreferredControlSuitAfterMove: leadPreferredControlSuitAfterMove,
            leadPreferredControlSuitStrengthAfterMove: leadPreferredControlSuitStrengthAfterMove,
            move: move,
            context: context
        ) + earlyWishPenalty(
            leadControlReserveAfterMove: leadControlReserveAfterMove,
            move: move,
            context: context
        )
    }

    private func declarationUtilityAdjustment(
        immediateWinProbability: Double,
        leadControlReserveAfterMove: Double,
        leadPreferredControlSuitAfterMove: Suit?,
        leadPreferredControlSuitStrengthAfterMove: Double,
        move: BotTurnCandidateRankingService.Move,
        context: BotTurnCandidateRankingService.UtilityContext
    ) -> Double {
        guard move.card.isJoker else { return 0.0 }
        guard context.trick.playedCards.isEmpty else { return 0.0 }
        guard move.decision.style == .faceUp else { return 0.0 }
        guard let declaration = move.decision.leadDeclaration else { return 0.0 }

        let tricksAfterCurrent = max(0, context.tricksRemainingIncludingCurrent - 1)
        let earlyPhaseWeight = min(1.0, Double(min(tricksAfterCurrent, 4)) / 4.0)
        let blindMultiplier = context.isBlindRound ? 1.15 : 1.0
        let isFinalTrick = context.tricksRemainingIncludingCurrent <= 1
        let isAllInChase = context.shouldChaseTrick &&
            context.tricksNeededToMatchBid >= context.tricksRemainingIncludingCurrent
        let controlReserve = min(1.0, max(0.0, leadControlReserveAfterMove))
        let lowReserveNeedForImmediateControl = 1.0 - controlReserve
        let preferredControlSuit = leadPreferredControlSuitAfterMove
        let preferredControlSuitStrength = min(1.0, max(0.0, leadPreferredControlSuitStrengthAfterMove))
        let premium = context.matchContext?.premium
        let ownPremiumProtectionContext = premium.map {
            $0.isPremiumCandidateSoFar || $0.isZeroPremiumCandidateSoFar
        } ?? false
        let antiPremiumPressureContext = premium.map {
            $0.leftNeighborIsPremiumCandidateSoFar ||
                $0.isPenaltyTargetRiskSoFar ||
                $0.opponentPremiumCandidatesSoFarCount > 0
        } ?? false
        let antiPremiumStyleMultiplier = antiPremiumPressureContext
            ? opponentPressureAdjuster.leadJokerAntiPremiumMultiplier(from: context.matchContext)
            : 1.0

        switch declaration {
        case .wish:
            if context.shouldChaseTrick {
                if isFinalTrick || isAllInChase {
                    var bonus = 4.0 * (0.6 + 0.4 * immediateWinProbability)
                    if isAllInChase && !isFinalTrick && antiPremiumPressureContext {
                        bonus -= 2.5 * antiPremiumStyleMultiplier
                    }
                    return bonus
                }

                let controlLossPenalty = (8.0 + 8.0 * earlyPhaseWeight) * blindMultiplier
                let pressureRelief = 1.0 - 0.35 * context.chasePressure
                let noTrumpRelief = context.trump == nil ? 0.80 : 1.0
                let antiPremiumControlNeedMultiplier = antiPremiumPressureContext ? 1.15 : 1.0
                let lowReserveAmplifier = 0.85 + 0.35 * lowReserveNeedForImmediateControl
                let highReserveWishRelief = 2.0 * controlReserve * (0.4 + 0.6 * earlyPhaseWeight)
                return -controlLossPenalty *
                    pressureRelief *
                    noTrumpRelief *
                    antiPremiumControlNeedMultiplier *
                    lowReserveAmplifier +
                    highReserveWishRelief
            }

            var wishDumpBonus = (2.0 + 4.0 * earlyPhaseWeight) * (context.isBlindRound ? 1.05 : 1.0)
            if ownPremiumProtectionContext {
                wishDumpBonus -= 2.0
            }
            return wishDumpBonus

        case .above(let suit):
            let declaresTrump = context.trump == suit
            let matchesPreferredControlSuit = preferredControlSuit == suit

            if context.shouldChaseTrick {
                var bonus = (4.0 + 7.0 * earlyPhaseWeight + 3.0 * context.chasePressure) * blindMultiplier
                if declaresTrump {
                    bonus += 3.0
                }
                if matchesPreferredControlSuit {
                    bonus += 2.5 + 2.5 * preferredControlSuitStrength
                }
                if isFinalTrick {
                    bonus *= 0.55
                }
                if isAllInChase {
                    bonus *= 0.70
                }
                if antiPremiumPressureContext {
                    bonus += 2.5 * antiPremiumStyleMultiplier
                    if isAllInChase && !isFinalTrick {
                        bonus += 2.0 * antiPremiumStyleMultiplier
                    }
                }
                let lowReserveAmplifier = 0.90 + 0.30 * lowReserveNeedForImmediateControl
                let highReserveAboveRelaxation = isAllInChase ? 1.0 : (1.0 - 0.12 * controlReserve)
                return bonus *
                    (0.65 + 0.35 * immediateWinProbability) *
                    lowReserveAmplifier *
                    highReserveAboveRelaxation
            }

            var penalty = (3.0 + 5.0 * earlyPhaseWeight) * blindMultiplier
            if declaresTrump {
                penalty += 2.5
            }
            if let premium = context.matchContext?.premium,
               premium.isPremiumCandidateSoFar || premium.isZeroPremiumCandidateSoFar {
                penalty += 1.5
            }
            return -penalty

        case .takes(let suit):
            let declaresTrump = context.trump == suit
            let matchesPreferredControlSuit = preferredControlSuit == suit

            if context.shouldChaseTrick {
                var penalty = (5.0 + 8.0 * earlyPhaseWeight) * blindMultiplier
                if declaresTrump {
                    penalty += 2.0
                }
                if matchesPreferredControlSuit {
                    penalty += 1.5 + 1.5 * preferredControlSuitStrength
                }
                if isAllInChase {
                    penalty *= 1.15
                }
                if isFinalTrick {
                    penalty *= 0.75
                }
                let lowReserveAmplifier = 0.90 + 0.25 * lowReserveNeedForImmediateControl
                return -penalty * (0.65 + 0.35 * immediateWinProbability) * lowReserveAmplifier
            }

            var bonus = (4.0 + 6.0 * earlyPhaseWeight) * blindMultiplier
            if declaresTrump {
                bonus -= 5.0
            } else {
                bonus += 3.0
            }
            if matchesPreferredControlSuit {
                bonus -= 1.5 + 1.5 * preferredControlSuitStrength
            }
            if isFinalTrick {
                bonus *= 0.70
            }
            if let premium = context.matchContext?.premium,
               premium.leftNeighborIsPremiumCandidateSoFar || premium.isPenaltyTargetRiskSoFar {
                bonus += 1.5 * antiPremiumStyleMultiplier
            }
            if ownPremiumProtectionContext {
                bonus += 2.0
            }
            if context.trickDeltaToBidBeforeMove > 0 && !context.hasLosingNonJoker {
                let overbidSeverity = min(2.0, Double(context.trickDeltaToBidBeforeMove))
                var controlledLossLeadBonus = (2.5 + 2.0 * earlyPhaseWeight) * overbidSeverity
                if !declaresTrump {
                    controlledLossLeadBonus += 1.0
                }
                bonus += controlledLossLeadBonus
            }
            let lowReserveAmplifier = 0.90 + 0.25 * lowReserveNeedForImmediateControl
            return bonus * (0.80 + 0.20 * (1.0 - immediateWinProbability)) * lowReserveAmplifier
        }
    }

    private func goalOrientedUtilityAdjustment(
        immediateWinProbability: Double,
        leadControlReserveAfterMove: Double,
        leadPreferredControlSuitAfterMove: Suit?,
        leadPreferredControlSuitStrengthAfterMove: Double,
        move: BotTurnCandidateRankingService.Move,
        context: BotTurnCandidateRankingService.UtilityContext
    ) -> Double {
        guard move.card.isJoker else { return 0.0 }
        guard context.trick.playedCards.isEmpty else { return 0.0 }
        guard move.decision.style == .faceUp else { return 0.0 }
        guard let declaration = move.decision.leadDeclaration else { return 0.0 }

        let controlReserve = clamped(leadControlReserveAfterMove, min: 0.0, max: 1.0)
        let preferredControlSuitStrength = clamped(
            leadPreferredControlSuitStrengthAfterMove,
            min: 0.0,
            max: 1.0
        )
        let lowReserveNeed = 1.0 - controlReserve
        let isAllInChase = context.shouldChaseTrick &&
            context.tricksNeededToMatchBid >= context.tricksRemainingIncludingCurrent
        let isPenaltyRiskContext = context.matchContext?.premium.map {
            $0.isPenaltyTargetRiskSoFar && $0.premiumCandidatesThreateningPenaltyCount > 0
        } ?? false
        let antiPremiumContext = context.matchContext?.premium.map {
            $0.leftNeighborIsPremiumCandidateSoFar ||
                $0.opponentPremiumCandidatesSoFarCount > 0 ||
                $0.isPenaltyTargetRiskSoFar
        } ?? false

        let secureTrick: Double
        let preserveControl: Double
        let controlledLoss: Double
        switch declaration {
        case .wish:
            secureTrick = context.shouldChaseTrick
                ? clamped(0.62 + 0.38 * immediateWinProbability, min: 0.0, max: 1.0)
                : 0.34
            preserveControl = clamped(0.38 + 0.30 * controlReserve, min: 0.0, max: 1.0)
            controlledLoss = context.shouldChaseTrick ? 0.0 : 0.32

        case .above(let suit):
            let declaresTrump = context.trump == suit
            let matchesPreferredSuit = leadPreferredControlSuitAfterMove == suit
            secureTrick = clamped(
                0.54 +
                    (context.shouldChaseTrick ? 0.18 : 0.0) +
                    (declaresTrump ? 0.16 : 0.0) +
                    (matchesPreferredSuit ? 0.08 + 0.10 * preferredControlSuitStrength : 0.0),
                min: 0.0,
                max: 1.0
            )
            preserveControl = clamped(
                0.42 +
                    (declaresTrump ? 0.14 : 0.0) +
                    (matchesPreferredSuit ? 0.10 + 0.12 * preferredControlSuitStrength : 0.0) +
                    0.14 * lowReserveNeed,
                min: 0.0,
                max: 1.0
            )
            controlledLoss = context.shouldChaseTrick ? 0.0 : (declaresTrump ? 0.14 : 0.24)

        case .takes(let suit):
            let declaresTrump = context.trump == suit
            let nonTrumpTakes = context.trump.map { $0 != suit } ?? true
            secureTrick = context.shouldChaseTrick
                ? clamped(0.28 + (declaresTrump ? 0.08 : 0.0), min: 0.0, max: 1.0)
                : 0.16
            preserveControl = clamped(
                0.18 +
                    (declaresTrump ? -0.10 : 0.0) +
                    (nonTrumpTakes ? 0.04 : 0.0) +
                    0.10 * lowReserveNeed,
                min: 0.0,
                max: 1.0
            )
            controlledLoss = context.shouldChaseTrick
                ? 0.0
                : clamped(
                    0.54 +
                        (nonTrumpTakes ? 0.18 : -0.12) +
                        (isPenaltyRiskContext ? 0.10 : 0.0),
                    min: 0.0,
                    max: 1.0
                )
        }

        let secureWeight: Double
        let controlWeight: Double
        let controlledLossWeight: Double
        if context.shouldChaseTrick {
            secureWeight = clamped(
                0.52 + 0.34 * context.chasePressure + (isAllInChase ? 0.14 : 0.0),
                min: 0.0,
                max: 1.0
            )
            controlWeight = clamped(
                0.26 + 0.22 * lowReserveNeed + (antiPremiumContext ? 0.10 : 0.0),
                min: 0.0,
                max: 1.0
            )
            controlledLossWeight = -0.18
        } else {
            secureWeight = -0.14
            controlWeight = 0.20 + (antiPremiumContext ? 0.06 : 0.0)
            controlledLossWeight = clamped(
                0.58 + (isPenaltyRiskContext ? 0.18 : 0.0),
                min: 0.0,
                max: 1.0
            )
        }

        let weightedGoalScore =
            secureTrick * secureWeight +
            preserveControl * controlWeight +
            controlledLoss * controlledLossWeight
        let scale: Double = context.shouldChaseTrick
            ? (10.0 + 7.0 * context.chasePressure)
            : (9.0 + 6.0 * (1.0 - immediateWinProbability))
        return weightedGoalScore * scale
    }

    private func earlyWishPenalty(
        leadControlReserveAfterMove: Double,
        move: BotTurnCandidateRankingService.Move,
        context: BotTurnCandidateRankingService.UtilityContext
    ) -> Double {
        let isLeadJoker = move.card.isJoker && context.trick.playedCards.isEmpty
        let isNonFinalLeadWishJoker: Bool
        if isLeadJoker,
           move.decision.style == .faceUp,
           context.tricksRemainingIncludingCurrent > 1,
           case .some(.wish) = move.decision.leadDeclaration {
            isNonFinalLeadWishJoker = true
        } else {
            isNonFinalLeadWishJoker = false
        }

        guard isNonFinalLeadWishJoker else { return 0.0 }

        let tricksAfterCurrent = max(1, context.tricksRemainingIncludingCurrent - 1)
        let basePenalty = 24.0 + Double(tricksAfterCurrent) * 6.0
        let chaseMultiplier = context.shouldChaseTrick ? (1.0 + context.chasePressure * 0.25) : 1.0
        let blindWishPenaltyMultiplier = context.isBlindRound ? 1.25 : 1.0
        let isAllInChase = context.shouldChaseTrick &&
            context.tricksNeededToMatchBid >= context.tricksRemainingIncludingCurrent
        let wishPenaltyReserveMultiplier: Double
        if context.shouldChaseTrick && !isAllInChase {
            let controlReserve = min(1.0, max(0.0, leadControlReserveAfterMove))
            wishPenaltyReserveMultiplier = 1.15 - 0.45 * controlReserve
        } else {
            wishPenaltyReserveMultiplier = 1.0
        }
        return -basePenalty *
            chaseMultiplier *
            blindWishPenaltyMultiplier *
            wishPenaltyReserveMultiplier
    }

    private func clamped(
        _ value: Double,
        min lowerBound: Double,
        max upperBound: Double
    ) -> Double {
        Swift.min(upperBound, Swift.max(lowerBound, value))
    }
}
