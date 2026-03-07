//
//  BotRuntimePolicy.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

/// Единый runtime policy для нетюнимых AI-коэффициентов.
/// Хранится внутри `BotTuning`, чтобы все active bot config dependencies
/// передавались одним объектом, а не через `static let` в сервисах.
struct BotRuntimePolicy {
    struct Ranking {
        struct JokerDeclaration {
            var earlyPhaseTrickCap: Double
            var blindUtilityMultiplier: Double

            var wishFinalChaseBonusBase: Double
            var wishFinalChaseImmediateWinBase: Double
            var wishFinalChaseImmediateWinWeight: Double
            var wishAllInAntiPremiumPenalty: Double
            var wishChaseControlLossBase: Double
            var wishChaseControlLossEarlyPhaseWeight: Double
            var wishChasePressureReliefWeight: Double
            var wishChaseNoTrumpRelief: Double
            var wishChaseAntiPremiumControlNeedMultiplier: Double
            var wishChaseLowReserveBase: Double
            var wishChaseLowReserveWeight: Double
            var wishChaseHighReserveReliefBase: Double
            var wishChaseHighReserveEarlyPhaseBase: Double
            var wishChaseHighReserveEarlyPhaseWeight: Double
            var wishDumpBonusBase: Double
            var wishDumpBonusEarlyPhaseWeight: Double
            var wishDumpBlindMultiplier: Double
            var wishDumpOwnPremiumPenalty: Double

            var aboveChaseBonusBase: Double
            var aboveChaseBonusEarlyPhaseWeight: Double
            var aboveChaseBonusPressureWeight: Double
            var aboveChaseTrumpBonus: Double
            var aboveChasePreferredSuitBase: Double
            var aboveChasePreferredSuitStrengthWeight: Double
            var aboveChaseFinalTrickMultiplier: Double
            var aboveChaseAllInMultiplier: Double
            var aboveChaseAntiPremiumBonus: Double
            var aboveChaseAllInAntiPremiumBonus: Double
            var aboveChaseLowReserveBase: Double
            var aboveChaseLowReserveWeight: Double
            var aboveChaseHighReserveRelaxationWeight: Double
            var aboveChaseImmediateWinBase: Double
            var aboveChaseImmediateWinWeight: Double
            var aboveDumpPenaltyBase: Double
            var aboveDumpPenaltyEarlyPhaseWeight: Double
            var aboveDumpTrumpPenalty: Double
            var aboveDumpOwnPremiumPenalty: Double

            var takesChasePenaltyBase: Double
            var takesChasePenaltyEarlyPhaseWeight: Double
            var takesChaseTrumpPenalty: Double
            var takesChasePreferredSuitBase: Double
            var takesChasePreferredSuitStrengthWeight: Double
            var takesChaseAllInMultiplier: Double
            var takesChaseFinalTrickMultiplier: Double
            var takesChaseLowReserveBase: Double
            var takesChaseLowReserveWeight: Double
            var takesChaseImmediateWinBase: Double
            var takesChaseImmediateWinWeight: Double

            var takesDumpBonusBase: Double
            var takesDumpBonusEarlyPhaseWeight: Double
            var takesDumpTrumpPenalty: Double
            var takesDumpNonTrumpBonus: Double
            var takesDumpPreferredSuitBase: Double
            var takesDumpPreferredSuitStrengthWeight: Double
            var takesDumpFinalTrickMultiplier: Double
            var takesDumpAntiPremiumBonus: Double
            var takesDumpOwnPremiumBonus: Double
            var takesDumpOverbidSeverityCap: Double
            var takesDumpOverbidBase: Double
            var takesDumpOverbidEarlyPhaseWeight: Double
            var takesDumpOverbidNonTrumpBonus: Double
            var takesDumpLowReserveBase: Double
            var takesDumpLowReserveWeight: Double
            var takesDumpImmediateWinBase: Double
            var takesDumpImmediateWinMissWeight: Double

            var goalWishSecureTrickBase: Double
            var goalWishSecureTrickImmediateWinWeight: Double
            var goalWishDumpSecureTrick: Double
            var goalWishPreserveControlBase: Double
            var goalWishPreserveControlReserveWeight: Double
            var goalWishDumpControlledLoss: Double

            var goalAboveSecureTrickBase: Double
            var goalAboveSecureTrickChaseBonus: Double
            var goalAboveSecureTrickTrumpBonus: Double
            var goalAboveSecureTrickPreferredSuitBase: Double
            var goalAboveSecureTrickPreferredSuitStrengthWeight: Double
            var goalAbovePreserveControlBase: Double
            var goalAbovePreserveControlTrumpBonus: Double
            var goalAbovePreserveControlPreferredSuitBase: Double
            var goalAbovePreserveControlPreferredSuitStrengthWeight: Double
            var goalAbovePreserveControlLowReserveWeight: Double
            var goalAboveDumpControlledLossTrump: Double
            var goalAboveDumpControlledLossNonTrump: Double

            var goalTakesChaseSecureTrickBase: Double
            var goalTakesChaseSecureTrickTrumpBonus: Double
            var goalTakesDumpSecureTrick: Double
            var goalTakesPreserveControlBase: Double
            var goalTakesPreserveControlTrumpPenalty: Double
            var goalTakesPreserveControlNonTrumpBonus: Double
            var goalTakesPreserveControlLowReserveWeight: Double
            var goalTakesControlledLossBase: Double
            var goalTakesControlledLossNonTrumpBonus: Double
            var goalTakesControlledLossTrumpPenalty: Double
            var goalTakesControlledLossPenaltyRiskBonus: Double

            var goalChaseSecureWeightBase: Double
            var goalChaseSecureWeightPressure: Double
            var goalChaseSecureWeightAllInBonus: Double
            var goalChaseControlWeightBase: Double
            var goalChaseControlWeightLowReserveWeight: Double
            var goalChaseControlWeightAntiPremiumBonus: Double
            var goalChaseControlledLossWeight: Double
            var goalDumpSecureWeight: Double
            var goalDumpControlWeightBase: Double
            var goalDumpControlWeightAntiPremiumBonus: Double
            var goalDumpControlledLossWeightBase: Double
            var goalDumpControlledLossWeightPenaltyRiskBonus: Double
            var goalChaseScaleBase: Double
            var goalChaseScalePressureWeight: Double
            var goalDumpScaleBase: Double
            var goalDumpScaleMissWeight: Double

            var earlyWishPenaltyBase: Double
            var earlyWishPenaltyPerRemainingTrick: Double
            var earlyWishPenaltyChasePressureWeight: Double
            var earlyWishPenaltyBlindMultiplier: Double
            var earlyWishPenaltyReserveBase: Double
            var earlyWishPenaltyReserveWeight: Double
        }

        struct MoveComposition {
            var lateExactBidDumpBase: Double
            var lateExactBidDumpProgressBase: Double
            var lateExactBidDumpProgressWeight: Double
            var neutralOverbidSeverityCap: Double
            var neutralOverbidBonus: Double
            var pressuredOverbidErraticCenter: Double
            var pressuredOverbidErraticScale: Double
            var pressuredOverbidBase: Double
            var pressuredOverbidSeverityWeight: Double
            var penaltyRiskDumpBonus: Double

            var blindRewardMultiplier: Double
            var blindRiskMultiplier: Double
            var chaseJokerExtraSpendBase: Double
            var chaseJokerExtraSpendPressureWeight: Double
            var chaseLeadWishPressureBase: Double
            var chaseLeadWishPressureWeight: Double
            var chaseLeadWishBlindMultiplier: Double
            var dumpLeadTakesBlindMultiplier: Double

            var urgencyChasePressureWeight: Double
            var urgencyBlockProgressWeight: Double
            var tacticalMultiplierUrgencyWeight: Double
            var tacticalMultiplierChaseBonus: Double
            var tacticalMultiplierMin: Double
            var tacticalMultiplierMax: Double
            var riskMultiplierUrgencyWeight: Double
            var riskMultiplierPenaltyRiskBonus: Double
            var riskMultiplierMin: Double
            var riskMultiplierMax: Double
            var opponentMultiplierUrgencyWeight: Double
            var opponentMultiplierEvidenceBonus: Double
            var opponentMultiplierMin: Double
            var opponentMultiplierMax: Double
            var jokerMultiplierUrgencyWeight: Double
            var jokerMultiplierChaseBonus: Double
            var jokerMultiplierDumpBonus: Double
            var jokerMultiplierMin: Double
            var jokerMultiplierMax: Double

            var cappedTacticalMagnitude: Double
            var cappedRiskMagnitude: Double
            var cappedOpponentMagnitude: Double
            var cappedJokerMagnitude: Double
            var stabilizationWindowBase: Double
            var stabilizationWindowMissWeight: Double
            var stabilizationWindowThreatWeight: Double
        }

        var fourthBlockScoreScale: Double
        var standardBlockScoreScale: Double
        var fourthBlockWeight: Double

        var premiumPreserveBase: Double
        var premiumPreserveProgressWeight: Double
        var denyPremiumBase: Double
        var denyPremiumProgressWeight: Double

        var baseActivationWeight: Double
        var progressActivationWeight: Double
        var finalRoundsActivationFull: Double
        var finalRoundsActivationHalf: Double

        var endgameUrgencyFull: Double
        var endgameUrgencyTwoRounds: Double
        var endgameUrgencyThreeRounds: Double
        var endgameUrgencyDefault: Double

        var riskBudgetWeight: Double
        var endgameUrgencyWeight: Double
        var blockProgressWeight: Double
        var premiumBiasWeight: Double

        var matchCatchUpChaseAggressionBase: Double
        var matchCatchUpChaseAggressionThreatWeight: Double
        var matchCatchUpChaseAggressionPressureWeight: Double
        var matchCatchUpFinalTrickUrgencyBonus: Double
        var matchCatchUpOpponentUrgencyBase: Double
        var matchCatchUpPreservePremiumPenalty: Double
        var matchCatchUpUrgencyWeightBase: Double
        var matchCatchUpUrgencyWeightProgress: Double
        var matchCatchUpConservativeDumpBase: Double
        var matchCatchUpConservativeDumpThreatWeight: Double
        var matchCatchUpConservativeDumpScoreWeight: Double
        var matchCatchUpDenyOpponentPenaltyBase: Double

        var premiumPreserveEvidenceBase: Double
        var premiumPreserveEvidenceProgress: Double
        var premiumPreserveClosingRoundsWeight: Double
        var premiumPreserveClosingRoundsTwo: Double
        var premiumPreserveClosingRoundsDefault: Double
        var premiumPreserveProgressBase: Double
        var premiumPreserveEvidenceProgressWeight: Double
        var premiumPreserveMustWinAllMultiplier: Double
        var premiumPreserveZeroConflictDampener: Double
        var premiumPreserveExactBidMultiplier: Double
        var premiumPreserveAlreadyBrokenMultiplier: Double
        var premiumPreserveChaseBonusBase: Double
        var premiumPreserveChaseBonusProgress: Double
        var premiumPreserveDumpBonus: Double
        var premiumPreserveExactZeroMultiplier: Double
        var premiumPreserveZeroChasePenalty: Double
        var premiumPreserveZeroDumpBonus: Double
        var premiumPreserveZeroAlreadyBrokenMultiplier: Double

        var penaltyAvoidThreatCountMin: Double
        var penaltyAvoidThreatCountProgress: Double
        var penaltyAvoidThreatCountMax: Double
        var penaltyAvoidEvidenceBase: Double
        var penaltyAvoidEvidenceProgress: Double
        var penaltyAvoidEndBlockBase: Double
        var penaltyAvoidEndBlockProgress: Double
        var penaltyAvoidProjectedScoreWeight: Double
        var penaltyAvoidOverbidPenalty: Double
        var penaltyAvoidDumpBonus: Double
        var penaltyAvoidLateBlockBoost: Double

        var premiumDenyEvidenceBase: Double
        var premiumDenyEvidenceProgress: Double
        var premiumDenyEndBlockBase: Double
        var premiumDenyEndBlockProgress: Double
        var premiumDenyLeftNeighborWeight: Double
        var premiumDenyOtherOpponentsWeight: Double
        var premiumDenyOtherOpponentsMax: Double
        var premiumDenyChaseBonus: Double
        var premiumDenyDumpPenalty: Double
        var premiumDenyOverbidRelaxation: Double

        var jokerDeclaration: JokerDeclaration
        var moveComposition: MoveComposition
        var utilityTieTolerance: Double
    }

    struct Bidding {
        struct BidSelection {
            var utilityTieTolerance: Double
            var optimalityPenaltyBase: Double
            var optimalityPenaltyProgress: Double
            var optimalityPenaltyBaseNoForbidden: Double
            var optimalityPenaltyProgressNoForbidden: Double
            var expectedPenaltyBase: Double
            var expectedPenaltyProgress: Double
            var scoreGapPenaltyForbidden: Double
            var scoreGapPenaltyNoForbidden: Double
        }

        struct BlindPolicy {
            var riskScoreBase: Double
            var catchUpThresholdBonus: Double
            var desperateThresholdBonus: Double
            var catchUpPressureMultiplier: Double
            var desperatePressureMultiplier: Double
            var safetyPenaltyMultiplier: Double
            var leaderPenalty: Double
            var dealerPenalty: Double
            var nonDealerBonus: Double
            var tableLeaderPenalty: Double
            var longRoundBonusCap: Double
            var longRoundThreshold: Int
            var longRoundBonusDivisor: Double
            var minAllowedPenalty: Double
            var narrowRangePenalty: Double
            var mediumRangePenalty: Double
            var wideRangeBonus: Double
            var riskScoreThreshold: Double
            var desperateModeThreshold: Double
            var overflowDivisor: Double
            var desperateOverflowBonus: Double
            var catchUpModeThreshold: Double
            var modeProgressDivisor: Double
            var catchUpToDesperateWeight: Double
            var conservativeProgressDivisor: Double
            var conservativeToCatchUpWeight: Double
            var dealerPositionAdjustment: Double
            var nonDealerAdjustment: Double
            var longRoundAdjustment: Double
            var longRoundAdjustmentThreshold: Int
            var safetyAdjustment: Double
            var targetShareCap: Double
            var riskBudgetNormalizationDivisor: Double
            var minAggressiveBidDesperateMin: Int
            var minAggressiveBidDesperateShare: Double
            var minAggressiveBidCatchUpBase: Double
            var minAggressiveBidCatchUpProgress: Double
        }

        struct BlindMonteCarlo {
            var minimumIterations: Int
            var maximumIterations: Int
            var iterationsPerCard: Int
            var iterationsPerBid: Int
            var utilityTieTolerance: Double
            var variancePenaltyBase: Double
            var safeLeadPressureMax: Double
            var desperatePenaltyWeight: Double
            var variancePenaltyWeightMin: Double
            var variancePenaltyWeightMax: Double
            var varianceRiskBudgetModifier: Double
            var deviationPenaltyBase: Double
            var deviationRiskBudgetMultiplier: Double
            var overshootPenaltyBase: Double
            var overshootSafeLeadMultiplier: Double
            var catchUpAggressionBase: Double
            var catchUpAggressionPressureMultiplier: Double
            var defaultRNGSeed: UInt64
            var rngMultiplier: UInt64
            var rngIncrement: UInt64
            var baseSeed: UInt64
            var hashShiftRight1: UInt64
            var hashShiftLeft: UInt64
            var hashShiftRight2: UInt64
        }

        var bidSelection: BidSelection
        var blindPolicy: BlindPolicy
        var blindMonteCarlo: BlindMonteCarlo
    }

    struct Evaluator {
        struct LeadControlReserve {
            var nonRegularCardValue: Double
            var trumpAceValue: Double
            var trumpKingValue: Double
            var trumpQueenValue: Double
            var trumpJackValue: Double
            var trumpLowValue: Double
            var nonTrumpAceValue: Double
            var nonTrumpKingValue: Double
            var nonTrumpQueenValue: Double
            var nonTrumpJackValue: Double
            var extraTrumpCountThreshold: Int
            var extraTrumpCountBonusPerCard: Double
        }

        struct PreferredControlSuit {
            var baseScore: Double
            var aceBonus: Double
            var kingBonus: Double
            var queenBonus: Double
            var jackBonus: Double
            var tenBonus: Double
            var lowRankBonus: Double
            var trumpBonus: Double
            var concentrationShareBaseline: Double
            var concentrationShareNormalizer: Double
            var tieTolerance: Double
        }

        var leadControlReserve: LeadControlReserve
        var preferredControlSuit: PreferredControlSuit
    }

    struct Rollout {
        var topCandidateCount: Int
        var utilityTieTolerance: Double
        var minimumIterations: Int
        var maximumIterations: Int
        var unseenCardsIterationsDivisor: Int
        var maxCardsPerOpponentSample: Int
        var maxTrickHorizon: Int
        var handSizeGateThreshold: Int
        var jokerGateHandSizeThreshold: Int
        var lateBlockUrgencyHandSizeThreshold: Int
        var lateBlockProgressThreshold: Double
        var criticalDeficitHandSizeThreshold: Int
        var criticalDeficitMinimumFloor: Int
        var chaseUrgencyBase: Double
        var chaseUrgencyDeficitWeight: Double
        var chaseUrgencyLateBlockWeight: Double
        var dumpUrgencyBase: Double
        var dumpUrgencyLateBlockWeight: Double
        var dumpUrgencyDeficitWeight: Double
        var adjustmentBase: Double
        var adjustmentUrgencyWeight: Double
    }

    struct Endgame {
        var solverHandSizeThreshold: Int
        var minimumCandidateCount: Int
        var minimumIterations: Int
        var maximumIterations: Int
        var unseenCardsIterationsDivisor: Int
        var weightBase: Double
        var weightUrgencyMultiplier: Double
        var adjustmentCap: Double
    }

    struct Simulation {
        var chaseJokerPower: Double
        var dumpJokerPower: Double
        var trumpBonus: Double
        var leadSuitBonus: Double
        var highRankThreshold: Rank
        var highRankBonus: Double
    }

    struct HandStrength {
        var trumpSelectionControlTopRankWeight: Double
        var trumpSelectionControlSequenceWeight: Double
        var noTrumpJokerSupportHighCardWeight: Double
        var noTrumpJokerSupportLongSuitWeight: Double
        var sequenceStrengthNormalizationDivisor: Double
    }

    struct Heuristics {
        struct HoldBlend {
            var legalAwareSimulationWeight: Double
            var distributionWeight: Double
        }

        struct LegalAwareSimulationCardPower {
            var jokerPower: Double
            var trumpBonus: Double
            var leadSuitBonus: Double
        }

        struct ThreatPhase {
            var jokerResourceWeight: Double
            var trumpResourceWeight: Double
            var highRankThreshold: Rank
            var highRankResourceWeight: Double
            var midRankThreshold: Rank
            var midRankResourceWeight: Double
            var lowRankResourceWeight: Double
            var earlyPreservationBonusWeight: Double
            var lateConversionDiscountWeight: Double
            var finalCardReliefWeight: Double
            var minMultiplier: Double
            var maxMultiplier: Double
        }

        struct ThreatPosition {
            var leadMultiplier: Double
            var secondSeatMultiplier: Double
            var middleSeatMultiplier: Double
            var lastSeatMultiplier: Double
        }

        struct ThreatHistory {
            var jokerSeenBoost: Double
            var jokerLeadPositionMultiplier: Double
            var jokerFollowPositionMultiplier: Double
            var jokerMinMultiplier: Double
            var jokerMaxMultiplier: Double
            var topCardTerminalReliefLate: Double
            var topCardTerminalReliefDefault: Double
            var topCardMinMultiplier: Double
            var topCardMaxMultiplier: Double
            var roundContextBase: Double
            var roundContextDepletionWeight: Double
            var inTrickReliefPerHigherCard: Double
            var inTrickReliefMin: Double
            var trumpResourceBase: Double
            var trumpResourceDepletionWeight: Double
            var regularMinMultiplier: Double
            var regularMaxMultiplier: Double
        }

        var legalAwareMinIterations: Int
        var legalAwareMaxIterations: Int
        var legalAwareReducedMinIterations: Int
        var legalAwareReducedMaxIterations: Int
        var legalAwareRotationStride: Int
        var legalAwareReducedMaxCardsPerOpponentSample: Int
        var legalAwareEndgameHandSizeThreshold: Int
        var holdBlend: HoldBlend
        var legalAwareSimulationCardPower: LegalAwareSimulationCardPower
        var threatPhase: ThreatPhase
        var threatPosition: ThreatPosition
        var threatHistory: ThreatHistory

        var minimumIterations: Int { legalAwareMinIterations }
        var maximumIterations: Int { legalAwareMaxIterations }
        var reducedMinimumIterations: Int { legalAwareReducedMinIterations }
        var reducedMaximumIterations: Int { legalAwareReducedMaxIterations }
        var rotationStride: Int { legalAwareRotationStride }
        var reducedMaxCardsPerOpponentSample: Int { legalAwareReducedMaxCardsPerOpponentSample }
        var endgameHandSizeThreshold: Int { legalAwareEndgameHandSizeThreshold }
    }

    struct OpponentModeling {
        var opponentDisciplineNeutralValue: Double
        var opponentDisciplineMismatchWeight: Double
        var opponentDisciplineNormalizationWeight: Double

        var opponentStyleEvidenceSaturationRounds: Int
        var opponentStyleMultiplierMin: Double
        var opponentStyleMultiplierMax: Double
        var opponentStyleDisciplineWeight: Double
        var opponentStyleAggressionWeight: Double
        var opponentStyleBlindPressureWeight: Double
        var opponentStyleExactBase: Double
        var opponentStyleAggressionBase: Double
        var opponentStyleBlindBase: Double

        var opponentLeadJokerAntiPremiumWeight: Double
        var opponentMatchCatchUpUrgencyWeight: Double
        var opponentBlindChaseContestWeight: Double
        var opponentLateBlockWeightBase: Double
        var opponentLateBlockWeightProgress: Double

        var opponentBidPressureNextWeight: Double
        var opponentBidPressureLeftNeighborWeight: Double
        var opponentBidPressureOtherWeight: Double
        var opponentBidPressureMax: Double
        var opponentBidPressureChaseBase: Double
        var opponentBidPressureChaseProgress: Double
        var opponentBidPressureDumpBase: Double
        var opponentBidPressureDumpProgress: Double

        var opponentIntentionPressureMax: Double
        var opponentIntentionAggregateWeight: Double
        var opponentIntentionChaseBase: Double
        var opponentIntentionChaseProgress: Double
        var opponentIntentionDumpBase: Double
        var opponentIntentionDumpProgress: Double
    }

    let ranking: Ranking
    let bidding: Bidding
    let evaluator: Evaluator
    let rollout: Rollout
    let endgame: Endgame
    let simulation: Simulation
    let handStrength: HandStrength
    let heuristics: Heuristics
    let opponentModeling: OpponentModeling

    static func preset(for difficulty: BotDifficulty) -> BotRuntimePolicy {
        let baseline = hardBaselinePreset

        switch difficulty {
        case .hard:
            return baseline

        case .normal:
            var bidding = baseline.bidding
            bidding.blindMonteCarlo.minimumIterations = 20
            bidding.blindMonteCarlo.maximumIterations = 44

            var heuristics = baseline.heuristics
            heuristics.legalAwareMinIterations = 16
            heuristics.legalAwareMaxIterations = 40

            var opponentModeling = baseline.opponentModeling
            opponentModeling.opponentStyleMultiplierMin = 0.88
            opponentModeling.opponentStyleMultiplierMax = 1.18
            opponentModeling.opponentLeadJokerAntiPremiumWeight = 0.52

            return baseline.overriding(
                bidding: bidding,
                heuristics: heuristics,
                opponentModeling: opponentModeling
            )

        case .easy:
            var bidding = baseline.bidding
            bidding.blindMonteCarlo.minimumIterations = 16
            bidding.blindMonteCarlo.maximumIterations = 32

            var heuristics = baseline.heuristics
            heuristics.legalAwareMinIterations = 12
            heuristics.legalAwareMaxIterations = 28
            heuristics.legalAwareReducedMinIterations = 6
            heuristics.legalAwareReducedMaxIterations = 14

            var opponentModeling = baseline.opponentModeling
            opponentModeling.opponentStyleMultiplierMin = 0.92
            opponentModeling.opponentStyleMultiplierMax = 1.10
            opponentModeling.opponentLeadJokerAntiPremiumWeight = 0.38
            opponentModeling.opponentMatchCatchUpUrgencyWeight = 0.24
            opponentModeling.opponentBlindChaseContestWeight = 0.16

            return baseline.overriding(
                bidding: bidding,
                heuristics: heuristics,
                opponentModeling: opponentModeling
            )
        }
    }

    static func assembled(
        difficulty: BotDifficulty,
        ranking: Ranking? = nil,
        bidding: Bidding? = nil,
        evaluator: Evaluator? = nil,
        rollout: Rollout? = nil,
        endgame: Endgame? = nil,
        simulation: Simulation? = nil,
        handStrength: HandStrength? = nil,
        heuristics: Heuristics? = nil,
        opponentModeling: OpponentModeling? = nil
    ) -> BotRuntimePolicy {
        let preset = BotRuntimePolicy.preset(for: difficulty)
        return preset.overriding(
            ranking: ranking,
            bidding: bidding,
            evaluator: evaluator,
            rollout: rollout,
            endgame: endgame,
            simulation: simulation,
            handStrength: handStrength,
            heuristics: heuristics,
            opponentModeling: opponentModeling
        )
    }

    private func overriding(
        ranking: Ranking? = nil,
        bidding: Bidding? = nil,
        evaluator: Evaluator? = nil,
        rollout: Rollout? = nil,
        endgame: Endgame? = nil,
        simulation: Simulation? = nil,
        handStrength: HandStrength? = nil,
        heuristics: Heuristics? = nil,
        opponentModeling: OpponentModeling? = nil
    ) -> BotRuntimePolicy {
        BotRuntimePolicy(
            ranking: ranking ?? self.ranking,
            bidding: bidding ?? self.bidding,
            evaluator: evaluator ?? self.evaluator,
            rollout: rollout ?? self.rollout,
            endgame: endgame ?? self.endgame,
            simulation: simulation ?? self.simulation,
            handStrength: handStrength ?? self.handStrength,
            heuristics: heuristics ?? self.heuristics,
            opponentModeling: opponentModeling ?? self.opponentModeling
        )
    }
}
