//
//  JokerDeclarationAdjuster.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

struct JokerDeclarationAdjuster {
    private let policy: BotRuntimePolicy.Ranking.JokerDeclaration
    private let opponentPressureAdjuster: OpponentPressureAdjuster

    init(
        policy: BotRuntimePolicy.Ranking.JokerDeclaration,
        opponentPressureAdjuster: OpponentPressureAdjuster
    ) {
        self.policy = policy
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
        let phase = context.matchContext.map {
            BotBlockPhase.from(blockProgressFraction: $0.blockProgressFraction)
        } ?? .mid
        let declarationPressureMult = policy.phaseDeclarationPressure.multiplier(for: phase)
        let earlySpendMult = policy.phaseEarlySpend.multiplier(for: phase)

        let declarationPart = declarationUtilityAdjustment(
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
        )
        let earlyPart = earlyWishPenalty(
            leadControlReserveAfterMove: leadControlReserveAfterMove,
            move: move,
            context: context
        )
        return declarationPart * declarationPressureMult + earlyPart * earlySpendMult
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
        let earlyPhaseTrickCap = max(1.0, policy.earlyPhaseTrickCap)
        let earlyPhaseWeight = min(
            1.0,
            Double(min(tricksAfterCurrent, Int(earlyPhaseTrickCap))) / earlyPhaseTrickCap
        )
        let blindMultiplier = context.isBlindRound ? policy.blindUtilityMultiplier : 1.0
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
                    var bonus = policy.wishFinalChaseBonusBase *
                        (policy.wishFinalChaseImmediateWinBase +
                            policy.wishFinalChaseImmediateWinWeight * immediateWinProbability)
                    if isAllInChase && !isFinalTrick && antiPremiumPressureContext {
                        bonus -= policy.wishAllInAntiPremiumPenalty * antiPremiumStyleMultiplier
                    }
                    return bonus
                }

                let controlLossPenalty =
                    (policy.wishChaseControlLossBase +
                        policy.wishChaseControlLossEarlyPhaseWeight * earlyPhaseWeight) *
                    blindMultiplier
                let pressureRelief = 1.0 - policy.wishChasePressureReliefWeight * context.chasePressure
                let noTrumpRelief = context.trump == nil ? policy.wishChaseNoTrumpRelief : 1.0
                let antiPremiumControlNeedMultiplier = antiPremiumPressureContext
                    ? policy.wishChaseAntiPremiumControlNeedMultiplier
                    : 1.0
                let lowReserveAmplifier = policy.wishChaseLowReserveBase +
                    policy.wishChaseLowReserveWeight * lowReserveNeedForImmediateControl
                let highReserveWishRelief =
                    policy.wishChaseHighReserveReliefBase *
                    controlReserve *
                    (policy.wishChaseHighReserveEarlyPhaseBase +
                        policy.wishChaseHighReserveEarlyPhaseWeight * earlyPhaseWeight)
                return -controlLossPenalty *
                    pressureRelief *
                    noTrumpRelief *
                    antiPremiumControlNeedMultiplier *
                    lowReserveAmplifier +
                    highReserveWishRelief
            }

            var wishDumpBonus =
                (policy.wishDumpBonusBase + policy.wishDumpBonusEarlyPhaseWeight * earlyPhaseWeight) *
                (context.isBlindRound ? policy.wishDumpBlindMultiplier : 1.0)
            if ownPremiumProtectionContext {
                wishDumpBonus -= policy.wishDumpOwnPremiumPenalty
            }
            return wishDumpBonus

        case .above(let suit):
            let declaresTrump = context.trump == suit
            let matchesPreferredControlSuit = preferredControlSuit == suit

            if context.shouldChaseTrick {
                var bonus =
                    (policy.aboveChaseBonusBase +
                        policy.aboveChaseBonusEarlyPhaseWeight * earlyPhaseWeight +
                        policy.aboveChaseBonusPressureWeight * context.chasePressure) *
                    blindMultiplier
                if declaresTrump {
                    bonus += policy.aboveChaseTrumpBonus
                }
                if matchesPreferredControlSuit {
                    bonus += policy.aboveChasePreferredSuitBase +
                        policy.aboveChasePreferredSuitStrengthWeight * preferredControlSuitStrength
                }
                if isFinalTrick {
                    bonus *= policy.aboveChaseFinalTrickMultiplier
                }
                if isAllInChase {
                    bonus *= policy.aboveChaseAllInMultiplier
                }
                if antiPremiumPressureContext {
                    bonus += policy.aboveChaseAntiPremiumBonus * antiPremiumStyleMultiplier
                    if isAllInChase && !isFinalTrick {
                        bonus += policy.aboveChaseAllInAntiPremiumBonus * antiPremiumStyleMultiplier
                    }
                }
                let lowReserveAmplifier = policy.aboveChaseLowReserveBase +
                    policy.aboveChaseLowReserveWeight * lowReserveNeedForImmediateControl
                let highReserveAboveRelaxation = isAllInChase
                    ? 1.0
                    : (1.0 - policy.aboveChaseHighReserveRelaxationWeight * controlReserve)
                return bonus *
                    (policy.aboveChaseImmediateWinBase +
                        policy.aboveChaseImmediateWinWeight * immediateWinProbability) *
                    lowReserveAmplifier *
                    highReserveAboveRelaxation
            }

            var penalty =
                (policy.aboveDumpPenaltyBase + policy.aboveDumpPenaltyEarlyPhaseWeight * earlyPhaseWeight) *
                blindMultiplier
            if declaresTrump {
                penalty += policy.aboveDumpTrumpPenalty
            }
            if let premium = context.matchContext?.premium,
               premium.isPremiumCandidateSoFar || premium.isZeroPremiumCandidateSoFar {
                penalty += policy.aboveDumpOwnPremiumPenalty
            }
            return -penalty

        case .takes(let suit):
            let declaresTrump = context.trump == suit
            let matchesPreferredControlSuit = preferredControlSuit == suit

            if context.shouldChaseTrick {
                var penalty =
                    (policy.takesChasePenaltyBase +
                        policy.takesChasePenaltyEarlyPhaseWeight * earlyPhaseWeight) *
                    blindMultiplier
                if declaresTrump {
                    penalty += policy.takesChaseTrumpPenalty
                }
                if matchesPreferredControlSuit {
                    penalty += policy.takesChasePreferredSuitBase +
                        policy.takesChasePreferredSuitStrengthWeight * preferredControlSuitStrength
                }
                if isAllInChase {
                    penalty *= policy.takesChaseAllInMultiplier
                }
                if isFinalTrick {
                    penalty *= policy.takesChaseFinalTrickMultiplier
                }
                let lowReserveAmplifier = policy.takesChaseLowReserveBase +
                    policy.takesChaseLowReserveWeight * lowReserveNeedForImmediateControl
                return -penalty *
                    (policy.takesChaseImmediateWinBase +
                        policy.takesChaseImmediateWinWeight * immediateWinProbability) *
                    lowReserveAmplifier
            }

            var bonus =
                (policy.takesDumpBonusBase + policy.takesDumpBonusEarlyPhaseWeight * earlyPhaseWeight) *
                blindMultiplier
            if declaresTrump {
                bonus -= policy.takesDumpTrumpPenalty
            } else {
                bonus += policy.takesDumpNonTrumpBonus
            }
            if matchesPreferredControlSuit {
                bonus -= policy.takesDumpPreferredSuitBase +
                    policy.takesDumpPreferredSuitStrengthWeight * preferredControlSuitStrength
            }
            if isFinalTrick {
                bonus *= policy.takesDumpFinalTrickMultiplier
            }
            if let premium = context.matchContext?.premium,
               premium.leftNeighborIsPremiumCandidateSoFar || premium.isPenaltyTargetRiskSoFar {
                bonus += policy.takesDumpAntiPremiumBonus * antiPremiumStyleMultiplier
            }
            if ownPremiumProtectionContext {
                bonus += policy.takesDumpOwnPremiumBonus
            }
            if context.trickDeltaToBidBeforeMove > 0 && !context.hasLosingNonJoker {
                let overbidSeverity = min(
                    policy.takesDumpOverbidSeverityCap,
                    Double(context.trickDeltaToBidBeforeMove)
                )
                var controlledLossLeadBonus =
                    (policy.takesDumpOverbidBase +
                        policy.takesDumpOverbidEarlyPhaseWeight * earlyPhaseWeight) *
                    overbidSeverity
                if !declaresTrump {
                    controlledLossLeadBonus += policy.takesDumpOverbidNonTrumpBonus
                }
                bonus += controlledLossLeadBonus
            }
            let lowReserveAmplifier = policy.takesDumpLowReserveBase +
                policy.takesDumpLowReserveWeight * lowReserveNeedForImmediateControl
            return bonus *
                (policy.takesDumpImmediateWinBase +
                    policy.takesDumpImmediateWinMissWeight * (1.0 - immediateWinProbability)) *
                lowReserveAmplifier
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
                ? clamped(
                    policy.goalWishSecureTrickBase +
                        policy.goalWishSecureTrickImmediateWinWeight * immediateWinProbability,
                    min: 0.0,
                    max: 1.0
                )
                : policy.goalWishDumpSecureTrick
            preserveControl = clamped(
                policy.goalWishPreserveControlBase +
                    policy.goalWishPreserveControlReserveWeight * controlReserve,
                min: 0.0,
                max: 1.0
            )
            controlledLoss = context.shouldChaseTrick ? 0.0 : policy.goalWishDumpControlledLoss

        case .above(let suit):
            let declaresTrump = context.trump == suit
            let matchesPreferredSuit = leadPreferredControlSuitAfterMove == suit
            secureTrick = clamped(
                policy.goalAboveSecureTrickBase +
                    (context.shouldChaseTrick ? policy.goalAboveSecureTrickChaseBonus : 0.0) +
                    (declaresTrump ? policy.goalAboveSecureTrickTrumpBonus : 0.0) +
                    (matchesPreferredSuit
                        ? policy.goalAboveSecureTrickPreferredSuitBase +
                            policy.goalAboveSecureTrickPreferredSuitStrengthWeight * preferredControlSuitStrength
                        : 0.0),
                min: 0.0,
                max: 1.0
            )
            preserveControl = clamped(
                policy.goalAbovePreserveControlBase +
                    (declaresTrump ? policy.goalAbovePreserveControlTrumpBonus : 0.0) +
                    (matchesPreferredSuit
                        ? policy.goalAbovePreserveControlPreferredSuitBase +
                            policy.goalAbovePreserveControlPreferredSuitStrengthWeight * preferredControlSuitStrength
                        : 0.0) +
                    policy.goalAbovePreserveControlLowReserveWeight * lowReserveNeed,
                min: 0.0,
                max: 1.0
            )
            controlledLoss = context.shouldChaseTrick
                ? 0.0
                : (declaresTrump
                    ? policy.goalAboveDumpControlledLossTrump
                    : policy.goalAboveDumpControlledLossNonTrump)

        case .takes(let suit):
            let declaresTrump = context.trump == suit
            let nonTrumpTakes = context.trump.map { $0 != suit } ?? true
            secureTrick = context.shouldChaseTrick
                ? clamped(
                    policy.goalTakesChaseSecureTrickBase +
                        (declaresTrump ? policy.goalTakesChaseSecureTrickTrumpBonus : 0.0),
                    min: 0.0,
                    max: 1.0
                )
                : policy.goalTakesDumpSecureTrick
            preserveControl = clamped(
                policy.goalTakesPreserveControlBase +
                    (declaresTrump ? -policy.goalTakesPreserveControlTrumpPenalty : 0.0) +
                    (nonTrumpTakes ? policy.goalTakesPreserveControlNonTrumpBonus : 0.0) +
                    policy.goalTakesPreserveControlLowReserveWeight * lowReserveNeed,
                min: 0.0,
                max: 1.0
            )
            controlledLoss = context.shouldChaseTrick
                ? 0.0
                : clamped(
                    policy.goalTakesControlledLossBase +
                        (nonTrumpTakes ? policy.goalTakesControlledLossNonTrumpBonus : -policy.goalTakesControlledLossTrumpPenalty) +
                        (isPenaltyRiskContext ? policy.goalTakesControlledLossPenaltyRiskBonus : 0.0),
                    min: 0.0,
                    max: 1.0
                )
        }

        let secureWeight: Double
        let controlWeight: Double
        let controlledLossWeight: Double
        if context.shouldChaseTrick {
            secureWeight = clamped(
                policy.goalChaseSecureWeightBase +
                    policy.goalChaseSecureWeightPressure * context.chasePressure +
                    (isAllInChase ? policy.goalChaseSecureWeightAllInBonus : 0.0),
                min: 0.0,
                max: 1.0
            )
            controlWeight = clamped(
                policy.goalChaseControlWeightBase +
                    policy.goalChaseControlWeightLowReserveWeight * lowReserveNeed +
                    (antiPremiumContext ? policy.goalChaseControlWeightAntiPremiumBonus : 0.0),
                min: 0.0,
                max: 1.0
            )
            controlledLossWeight = policy.goalChaseControlledLossWeight
        } else {
            secureWeight = policy.goalDumpSecureWeight
            controlWeight = policy.goalDumpControlWeightBase +
                (antiPremiumContext ? policy.goalDumpControlWeightAntiPremiumBonus : 0.0)
            controlledLossWeight = clamped(
                policy.goalDumpControlledLossWeightBase +
                    (isPenaltyRiskContext ? policy.goalDumpControlledLossWeightPenaltyRiskBonus : 0.0),
                min: 0.0,
                max: 1.0
            )
        }

        let weightedGoalScore =
            secureTrick * secureWeight +
            preserveControl * controlWeight +
            controlledLoss * controlledLossWeight
        let scale: Double = context.shouldChaseTrick
            ? (policy.goalChaseScaleBase + policy.goalChaseScalePressureWeight * context.chasePressure)
            : (policy.goalDumpScaleBase + policy.goalDumpScaleMissWeight * (1.0 - immediateWinProbability))
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
        let basePenalty = policy.earlyWishPenaltyBase +
            Double(tricksAfterCurrent) * policy.earlyWishPenaltyPerRemainingTrick
        let chaseMultiplier = context.shouldChaseTrick
            ? (1.0 + context.chasePressure * policy.earlyWishPenaltyChasePressureWeight)
            : 1.0
        let blindWishPenaltyMultiplier = context.isBlindRound
            ? policy.earlyWishPenaltyBlindMultiplier
            : 1.0
        let isAllInChase = context.shouldChaseTrick &&
            context.tricksNeededToMatchBid >= context.tricksRemainingIncludingCurrent
        let wishPenaltyReserveMultiplier: Double
        if context.shouldChaseTrick && !isAllInChase {
            let controlReserve = min(1.0, max(0.0, leadControlReserveAfterMove))
            wishPenaltyReserveMultiplier = policy.earlyWishPenaltyReserveBase -
                policy.earlyWishPenaltyReserveWeight * controlReserve
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
