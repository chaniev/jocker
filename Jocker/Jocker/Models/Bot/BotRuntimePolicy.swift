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
            let utilityTieTolerance: Double
            let optimalityPenaltyBase: Double
            let optimalityPenaltyProgress: Double
            let optimalityPenaltyBaseNoForbidden: Double
            let optimalityPenaltyProgressNoForbidden: Double
            let expectedPenaltyBase: Double
            let expectedPenaltyProgress: Double
            let scoreGapPenaltyForbidden: Double
            let scoreGapPenaltyNoForbidden: Double
        }

        struct BlindPolicy {
            let riskScoreBase: Double
            let catchUpThresholdBonus: Double
            let desperateThresholdBonus: Double
            let catchUpPressureMultiplier: Double
            let desperatePressureMultiplier: Double
            let safetyPenaltyMultiplier: Double
            let leaderPenalty: Double
            let dealerPenalty: Double
            let nonDealerBonus: Double
            let tableLeaderPenalty: Double
            let longRoundBonusCap: Double
            let longRoundThreshold: Int
            let longRoundBonusDivisor: Double
            let minAllowedPenalty: Double
            let narrowRangePenalty: Double
            let mediumRangePenalty: Double
            let wideRangeBonus: Double
            let riskScoreThreshold: Double
            let desperateModeThreshold: Double
            let overflowDivisor: Double
            let desperateOverflowBonus: Double
            let catchUpModeThreshold: Double
            let modeProgressDivisor: Double
            let catchUpToDesperateWeight: Double
            let conservativeProgressDivisor: Double
            let conservativeToCatchUpWeight: Double
            let dealerPositionAdjustment: Double
            let nonDealerAdjustment: Double
            let longRoundAdjustment: Double
            let longRoundAdjustmentThreshold: Int
            let safetyAdjustment: Double
            let targetShareCap: Double
            let riskBudgetNormalizationDivisor: Double
            let minAggressiveBidDesperateMin: Int
            let minAggressiveBidDesperateShare: Double
            let minAggressiveBidCatchUpBase: Double
            let minAggressiveBidCatchUpProgress: Double
        }

        struct BlindMonteCarlo {
            let minimumIterations: Int
            let maximumIterations: Int
            let iterationsPerCard: Int
            let iterationsPerBid: Int
            let utilityTieTolerance: Double
            let variancePenaltyBase: Double
            let safeLeadPressureMax: Double
            let desperatePenaltyWeight: Double
            let variancePenaltyWeightMin: Double
            let variancePenaltyWeightMax: Double
            let varianceRiskBudgetModifier: Double
            let deviationPenaltyBase: Double
            let deviationRiskBudgetMultiplier: Double
            let overshootPenaltyBase: Double
            let overshootSafeLeadMultiplier: Double
            let catchUpAggressionBase: Double
            let catchUpAggressionPressureMultiplier: Double
            let defaultRNGSeed: UInt64
            let rngMultiplier: UInt64
            let rngIncrement: UInt64
            let baseSeed: UInt64
            let hashShiftRight1: UInt64
            let hashShiftLeft: UInt64
            let hashShiftRight2: UInt64
        }

        var blindMonteCarloMinIterations: Int
        var blindMonteCarloMaxIterations: Int
        var blindMonteCarloIterationsPerCard: Int
        var blindMonteCarloIterationsPerBid: Int

        var bidUtilityTieTolerance: Double

        var blindRiskScoreBase: Double
        var blindCatchUpThresholdBonus: Double
        var blindDesperateThresholdBonus: Double
        var blindCatchUpPressureMultiplier: Double
        var blindDesperatePressureMultiplier: Double
        var blindSafetyPenaltyMultiplier: Double
        var blindLeaderPenalty: Double
        var blindDealerPenalty: Double
        var blindNonDealerBonus: Double
        var blindTableLeaderPenalty: Double
        var blindLongRoundBonusCap: Double
        var blindLongRoundThreshold: Int
        var blindLongRoundBonusDivisor: Double
        var blindMinAllowedPenalty: Double
        var blindNarrowRangePenalty: Double
        var blindMediumRangePenalty: Double
        var blindWideRangeBonus: Double
        var blindRiskScoreThreshold: Double

        var blindDesperateModeThreshold: Double
        var blindOverflowDivisor: Double
        var blindDesperateOverflowBonus: Double
        var blindCatchUpModeThreshold: Double
        var blindModeProgressDivisor: Double
        var blindCatchUpToDesperateWeight: Double
        var blindConservativeProgressDivisor: Double
        var blindConservativeToCatchUpWeight: Double

        var blindDealerPositionAdjustment: Double
        var blindNonDealerAdjustment: Double
        var blindLongRoundAdjustment: Double
        var blindLongRoundAdjustmentThreshold: Int
        var blindSafetyAdjustment: Double
        var blindTargetShareCap: Double
        var blindRiskBudgetNormalizationDivisor: Double

        var bidUtilityOptimalityPenaltyBase: Double
        var bidUtilityOptimalityPenaltyProgress: Double
        var bidUtilityOptimalityPenaltyBaseNoForbidden: Double
        var bidUtilityOptimalityPenaltyProgressNoForbidden: Double
        var bidUtilityExpectedPenaltyBase: Double
        var bidUtilityExpectedPenaltyProgress: Double
        var bidUtilityScoreGapPenaltyForbidden: Double
        var bidUtilityScoreGapPenaltyNoForbidden: Double

        var mcVariancePenaltyBase: Double
        var mcSafeLeadPressureMax: Double
        var mcDesperatePenaltyWeight: Double
        var mcVariancePenaltyWeightMin: Double
        var mcVariancePenaltyWeightMax: Double
        var mcVarianceRiskBudgetModifier: Double
        var mcDeviationPenaltyBase: Double
        var mcDeviationRiskBudgetMultiplier: Double
        var mcOvershootPenaltyBase: Double
        var mcOvershootSafeLeadMultiplier: Double
        var mcCatchUpAggressionBase: Double
        var mcCatchUpAggressionPressureMultiplier: Double

        var minAggressiveBidDesperateMin: Int
        var minAggressiveBidDesperateShare: Double
        var minAggressiveBidCatchUpBase: Double
        var minAggressiveBidCatchUpProgress: Double

        var defaultRNGSeed: UInt64
        var rngMultiplier: UInt64
        var rngIncrement: UInt64
        var monteCarloBaseSeed: UInt64
        var hashShiftRight1: UInt64
        var hashShiftLeft: UInt64
        var hashShiftRight2: UInt64

        var bidSelection: BidSelection {
            BidSelection(
                utilityTieTolerance: bidUtilityTieTolerance,
                optimalityPenaltyBase: bidUtilityOptimalityPenaltyBase,
                optimalityPenaltyProgress: bidUtilityOptimalityPenaltyProgress,
                optimalityPenaltyBaseNoForbidden: bidUtilityOptimalityPenaltyBaseNoForbidden,
                optimalityPenaltyProgressNoForbidden: bidUtilityOptimalityPenaltyProgressNoForbidden,
                expectedPenaltyBase: bidUtilityExpectedPenaltyBase,
                expectedPenaltyProgress: bidUtilityExpectedPenaltyProgress,
                scoreGapPenaltyForbidden: bidUtilityScoreGapPenaltyForbidden,
                scoreGapPenaltyNoForbidden: bidUtilityScoreGapPenaltyNoForbidden
            )
        }

        var blindPolicy: BlindPolicy {
            BlindPolicy(
                riskScoreBase: blindRiskScoreBase,
                catchUpThresholdBonus: blindCatchUpThresholdBonus,
                desperateThresholdBonus: blindDesperateThresholdBonus,
                catchUpPressureMultiplier: blindCatchUpPressureMultiplier,
                desperatePressureMultiplier: blindDesperatePressureMultiplier,
                safetyPenaltyMultiplier: blindSafetyPenaltyMultiplier,
                leaderPenalty: blindLeaderPenalty,
                dealerPenalty: blindDealerPenalty,
                nonDealerBonus: blindNonDealerBonus,
                tableLeaderPenalty: blindTableLeaderPenalty,
                longRoundBonusCap: blindLongRoundBonusCap,
                longRoundThreshold: blindLongRoundThreshold,
                longRoundBonusDivisor: blindLongRoundBonusDivisor,
                minAllowedPenalty: blindMinAllowedPenalty,
                narrowRangePenalty: blindNarrowRangePenalty,
                mediumRangePenalty: blindMediumRangePenalty,
                wideRangeBonus: blindWideRangeBonus,
                riskScoreThreshold: blindRiskScoreThreshold,
                desperateModeThreshold: blindDesperateModeThreshold,
                overflowDivisor: blindOverflowDivisor,
                desperateOverflowBonus: blindDesperateOverflowBonus,
                catchUpModeThreshold: blindCatchUpModeThreshold,
                modeProgressDivisor: blindModeProgressDivisor,
                catchUpToDesperateWeight: blindCatchUpToDesperateWeight,
                conservativeProgressDivisor: blindConservativeProgressDivisor,
                conservativeToCatchUpWeight: blindConservativeToCatchUpWeight,
                dealerPositionAdjustment: blindDealerPositionAdjustment,
                nonDealerAdjustment: blindNonDealerAdjustment,
                longRoundAdjustment: blindLongRoundAdjustment,
                longRoundAdjustmentThreshold: blindLongRoundAdjustmentThreshold,
                safetyAdjustment: blindSafetyAdjustment,
                targetShareCap: blindTargetShareCap,
                riskBudgetNormalizationDivisor: blindRiskBudgetNormalizationDivisor,
                minAggressiveBidDesperateMin: minAggressiveBidDesperateMin,
                minAggressiveBidDesperateShare: minAggressiveBidDesperateShare,
                minAggressiveBidCatchUpBase: minAggressiveBidCatchUpBase,
                minAggressiveBidCatchUpProgress: minAggressiveBidCatchUpProgress
            )
        }

        var blindMonteCarlo: BlindMonteCarlo {
            BlindMonteCarlo(
                minimumIterations: blindMonteCarloMinIterations,
                maximumIterations: blindMonteCarloMaxIterations,
                iterationsPerCard: blindMonteCarloIterationsPerCard,
                iterationsPerBid: blindMonteCarloIterationsPerBid,
                utilityTieTolerance: bidUtilityTieTolerance,
                variancePenaltyBase: mcVariancePenaltyBase,
                safeLeadPressureMax: mcSafeLeadPressureMax,
                desperatePenaltyWeight: mcDesperatePenaltyWeight,
                variancePenaltyWeightMin: mcVariancePenaltyWeightMin,
                variancePenaltyWeightMax: mcVariancePenaltyWeightMax,
                varianceRiskBudgetModifier: mcVarianceRiskBudgetModifier,
                deviationPenaltyBase: mcDeviationPenaltyBase,
                deviationRiskBudgetMultiplier: mcDeviationRiskBudgetMultiplier,
                overshootPenaltyBase: mcOvershootPenaltyBase,
                overshootSafeLeadMultiplier: mcOvershootSafeLeadMultiplier,
                catchUpAggressionBase: mcCatchUpAggressionBase,
                catchUpAggressionPressureMultiplier: mcCatchUpAggressionPressureMultiplier,
                defaultRNGSeed: defaultRNGSeed,
                rngMultiplier: rngMultiplier,
                rngIncrement: rngIncrement,
                baseSeed: monteCarloBaseSeed,
                hashShiftRight1: hashShiftRight1,
                hashShiftLeft: hashShiftLeft,
                hashShiftRight2: hashShiftRight2
            )
        }
    }

    struct Heuristics {
        var legalAwareMinIterations: Int
        var legalAwareMaxIterations: Int
        var legalAwareReducedMinIterations: Int
        var legalAwareReducedMaxIterations: Int
        var legalAwareRotationStride: Int
        var legalAwareReducedMaxCardsPerOpponentSample: Int
        var legalAwareEndgameHandSizeThreshold: Int

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
    let heuristics: Heuristics
    let opponentModeling: OpponentModeling

    static func preset(for difficulty: BotDifficulty) -> BotRuntimePolicy {
        let baseline = baselinePreset

        switch difficulty {
        case .hard:
            return baseline

        case .normal:
            var bidding = baseline.bidding
            bidding.blindMonteCarloMinIterations = 20
            bidding.blindMonteCarloMaxIterations = 44

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
            bidding.blindMonteCarloMinIterations = 16
            bidding.blindMonteCarloMaxIterations = 32

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

    private static let baselinePreset = BotRuntimePolicy(
        ranking: Ranking(
            fourthBlockScoreScale: 180.0,
            standardBlockScoreScale: 260.0,
            fourthBlockWeight: 1.15,
            premiumPreserveBase: 0.35,
            premiumPreserveProgressWeight: 0.65,
            denyPremiumBase: 0.30,
            denyPremiumProgressWeight: 0.70,
            baseActivationWeight: 0.05,
            progressActivationWeight: 0.95,
            finalRoundsActivationFull: 1.0,
            finalRoundsActivationHalf: 0.75,
            endgameUrgencyFull: 1.0,
            endgameUrgencyTwoRounds: 0.82,
            endgameUrgencyThreeRounds: 0.68,
            endgameUrgencyDefault: 0.42,
            riskBudgetWeight: 0.75,
            endgameUrgencyWeight: 0.60,
            blockProgressWeight: 0.40,
            premiumBiasWeight: 0.12,
            matchCatchUpChaseAggressionBase: 120.0,
            matchCatchUpChaseAggressionThreatWeight: 0.05,
            matchCatchUpChaseAggressionPressureWeight: 18.0,
            matchCatchUpFinalTrickUrgencyBonus: 8.0,
            matchCatchUpOpponentUrgencyBase: 0.20,
            matchCatchUpPreservePremiumPenalty: 3.0,
            matchCatchUpUrgencyWeightBase: 0.20,
            matchCatchUpUrgencyWeightProgress: 0.55,
            matchCatchUpConservativeDumpBase: 96.0,
            matchCatchUpConservativeDumpThreatWeight: 0.035,
            matchCatchUpConservativeDumpScoreWeight: 0.06,
            matchCatchUpDenyOpponentPenaltyBase: 2.5,
            premiumPreserveEvidenceBase: 0.25,
            premiumPreserveEvidenceProgress: 0.75,
            premiumPreserveClosingRoundsWeight: 1.35,
            premiumPreserveClosingRoundsTwo: 1.15,
            premiumPreserveClosingRoundsDefault: 1.0,
            premiumPreserveProgressBase: 0.20,
            premiumPreserveEvidenceProgressWeight: 1.10,
            premiumPreserveMustWinAllMultiplier: 1.30,
            premiumPreserveZeroConflictDampener: 0.94,
            premiumPreserveExactBidMultiplier: 1.45,
            premiumPreserveAlreadyBrokenMultiplier: 0.15,
            premiumPreserveChaseBonusBase: 10.0,
            premiumPreserveChaseBonusProgress: 12.0,
            premiumPreserveDumpBonus: 16.0,
            premiumPreserveExactZeroMultiplier: 1.60,
            premiumPreserveZeroChasePenalty: 28.0,
            premiumPreserveZeroDumpBonus: 24.0,
            premiumPreserveZeroAlreadyBrokenMultiplier: 0.10,
            penaltyAvoidThreatCountMin: 0.8,
            penaltyAvoidThreatCountProgress: 0.25,
            penaltyAvoidThreatCountMax: 1.6,
            penaltyAvoidEvidenceBase: 0.25,
            penaltyAvoidEvidenceProgress: 0.75,
            penaltyAvoidEndBlockBase: 0.20,
            penaltyAvoidEndBlockProgress: 1.00,
            penaltyAvoidProjectedScoreWeight: 0.18,
            penaltyAvoidOverbidPenalty: 18.0,
            penaltyAvoidDumpBonus: 10.8,
            penaltyAvoidLateBlockBoost: 0.18,
            premiumDenyEvidenceBase: 0.25,
            premiumDenyEvidenceProgress: 0.75,
            premiumDenyEndBlockBase: 0.20,
            premiumDenyEndBlockProgress: 1.00,
            premiumDenyLeftNeighborWeight: 1.0,
            premiumDenyOtherOpponentsWeight: 0.55,
            premiumDenyOtherOpponentsMax: 1.4,
            premiumDenyChaseBonus: 10.0,
            premiumDenyDumpPenalty: 12.0,
            premiumDenyOverbidRelaxation: 1.20,
            jokerDeclaration: Ranking.JokerDeclaration(
                earlyPhaseTrickCap: 4.0,
                blindUtilityMultiplier: 1.15,
                wishFinalChaseBonusBase: 4.0,
                wishFinalChaseImmediateWinBase: 0.6,
                wishFinalChaseImmediateWinWeight: 0.4,
                wishAllInAntiPremiumPenalty: 2.5,
                wishChaseControlLossBase: 8.0,
                wishChaseControlLossEarlyPhaseWeight: 8.0,
                wishChasePressureReliefWeight: 0.35,
                wishChaseNoTrumpRelief: 0.80,
                wishChaseAntiPremiumControlNeedMultiplier: 1.15,
                wishChaseLowReserveBase: 0.85,
                wishChaseLowReserveWeight: 0.35,
                wishChaseHighReserveReliefBase: 2.0,
                wishChaseHighReserveEarlyPhaseBase: 0.4,
                wishChaseHighReserveEarlyPhaseWeight: 0.6,
                wishDumpBonusBase: 2.0,
                wishDumpBonusEarlyPhaseWeight: 4.0,
                wishDumpBlindMultiplier: 1.05,
                wishDumpOwnPremiumPenalty: 2.0,
                aboveChaseBonusBase: 4.0,
                aboveChaseBonusEarlyPhaseWeight: 7.0,
                aboveChaseBonusPressureWeight: 3.0,
                aboveChaseTrumpBonus: 3.0,
                aboveChasePreferredSuitBase: 2.5,
                aboveChasePreferredSuitStrengthWeight: 2.5,
                aboveChaseFinalTrickMultiplier: 0.55,
                aboveChaseAllInMultiplier: 0.70,
                aboveChaseAntiPremiumBonus: 2.5,
                aboveChaseAllInAntiPremiumBonus: 2.0,
                aboveChaseLowReserveBase: 0.90,
                aboveChaseLowReserveWeight: 0.30,
                aboveChaseHighReserveRelaxationWeight: 0.12,
                aboveChaseImmediateWinBase: 0.65,
                aboveChaseImmediateWinWeight: 0.35,
                aboveDumpPenaltyBase: 3.0,
                aboveDumpPenaltyEarlyPhaseWeight: 5.0,
                aboveDumpTrumpPenalty: 2.5,
                aboveDumpOwnPremiumPenalty: 1.5,
                takesChasePenaltyBase: 5.0,
                takesChasePenaltyEarlyPhaseWeight: 8.0,
                takesChaseTrumpPenalty: 2.0,
                takesChasePreferredSuitBase: 1.5,
                takesChasePreferredSuitStrengthWeight: 1.5,
                takesChaseAllInMultiplier: 1.15,
                takesChaseFinalTrickMultiplier: 0.75,
                takesChaseLowReserveBase: 0.90,
                takesChaseLowReserveWeight: 0.25,
                takesChaseImmediateWinBase: 0.65,
                takesChaseImmediateWinWeight: 0.35,
                takesDumpBonusBase: 4.0,
                takesDumpBonusEarlyPhaseWeight: 6.0,
                takesDumpTrumpPenalty: 5.0,
                takesDumpNonTrumpBonus: 3.0,
                takesDumpPreferredSuitBase: 1.5,
                takesDumpPreferredSuitStrengthWeight: 1.5,
                takesDumpFinalTrickMultiplier: 0.70,
                takesDumpAntiPremiumBonus: 1.5,
                takesDumpOwnPremiumBonus: 2.0,
                takesDumpOverbidSeverityCap: 2.0,
                takesDumpOverbidBase: 2.5,
                takesDumpOverbidEarlyPhaseWeight: 2.0,
                takesDumpOverbidNonTrumpBonus: 1.0,
                takesDumpLowReserveBase: 0.90,
                takesDumpLowReserveWeight: 0.25,
                takesDumpImmediateWinBase: 0.80,
                takesDumpImmediateWinMissWeight: 0.20,
                goalWishSecureTrickBase: 0.62,
                goalWishSecureTrickImmediateWinWeight: 0.38,
                goalWishDumpSecureTrick: 0.34,
                goalWishPreserveControlBase: 0.38,
                goalWishPreserveControlReserveWeight: 0.30,
                goalWishDumpControlledLoss: 0.32,
                goalAboveSecureTrickBase: 0.54,
                goalAboveSecureTrickChaseBonus: 0.18,
                goalAboveSecureTrickTrumpBonus: 0.16,
                goalAboveSecureTrickPreferredSuitBase: 0.08,
                goalAboveSecureTrickPreferredSuitStrengthWeight: 0.10,
                goalAbovePreserveControlBase: 0.42,
                goalAbovePreserveControlTrumpBonus: 0.14,
                goalAbovePreserveControlPreferredSuitBase: 0.10,
                goalAbovePreserveControlPreferredSuitStrengthWeight: 0.12,
                goalAbovePreserveControlLowReserveWeight: 0.14,
                goalAboveDumpControlledLossTrump: 0.14,
                goalAboveDumpControlledLossNonTrump: 0.24,
                goalTakesChaseSecureTrickBase: 0.28,
                goalTakesChaseSecureTrickTrumpBonus: 0.08,
                goalTakesDumpSecureTrick: 0.16,
                goalTakesPreserveControlBase: 0.18,
                goalTakesPreserveControlTrumpPenalty: 0.10,
                goalTakesPreserveControlNonTrumpBonus: 0.04,
                goalTakesPreserveControlLowReserveWeight: 0.10,
                goalTakesControlledLossBase: 0.54,
                goalTakesControlledLossNonTrumpBonus: 0.18,
                goalTakesControlledLossTrumpPenalty: 0.12,
                goalTakesControlledLossPenaltyRiskBonus: 0.10,
                goalChaseSecureWeightBase: 0.52,
                goalChaseSecureWeightPressure: 0.34,
                goalChaseSecureWeightAllInBonus: 0.14,
                goalChaseControlWeightBase: 0.26,
                goalChaseControlWeightLowReserveWeight: 0.22,
                goalChaseControlWeightAntiPremiumBonus: 0.10,
                goalChaseControlledLossWeight: -0.18,
                goalDumpSecureWeight: -0.14,
                goalDumpControlWeightBase: 0.20,
                goalDumpControlWeightAntiPremiumBonus: 0.06,
                goalDumpControlledLossWeightBase: 0.58,
                goalDumpControlledLossWeightPenaltyRiskBonus: 0.18,
                goalChaseScaleBase: 10.0,
                goalChaseScalePressureWeight: 7.0,
                goalDumpScaleBase: 9.0,
                goalDumpScaleMissWeight: 6.0,
                earlyWishPenaltyBase: 24.0,
                earlyWishPenaltyPerRemainingTrick: 6.0,
                earlyWishPenaltyChasePressureWeight: 0.25,
                earlyWishPenaltyBlindMultiplier: 1.25,
                earlyWishPenaltyReserveBase: 1.15,
                earlyWishPenaltyReserveWeight: 0.45
            ),
            moveComposition: Ranking.MoveComposition(
                lateExactBidDumpBase: 64.0,
                lateExactBidDumpProgressBase: 0.5,
                lateExactBidDumpProgressWeight: 0.5,
                neutralOverbidSeverityCap: 2.0,
                neutralOverbidBonus: 14.0,
                pressuredOverbidErraticCenter: 0.5,
                pressuredOverbidErraticScale: 2.0,
                pressuredOverbidBase: 12.0,
                pressuredOverbidSeverityWeight: 20.0,
                penaltyRiskDumpBonus: 8.0,
                blindRewardMultiplier: 1.55,
                blindRiskMultiplier: 1.30,
                chaseJokerExtraSpendBase: 0.55,
                chaseJokerExtraSpendPressureWeight: 0.45,
                chaseLeadWishPressureBase: 0.5,
                chaseLeadWishPressureWeight: 0.5,
                chaseLeadWishBlindMultiplier: 1.15,
                dumpLeadTakesBlindMultiplier: 1.2,
                urgencyChasePressureWeight: 0.58,
                urgencyBlockProgressWeight: 0.42,
                tacticalMultiplierUrgencyWeight: 0.04,
                tacticalMultiplierChaseBonus: 0.03,
                tacticalMultiplierMin: 0.95,
                tacticalMultiplierMax: 1.10,
                riskMultiplierUrgencyWeight: 0.08,
                riskMultiplierPenaltyRiskBonus: 0.06,
                riskMultiplierMin: 0.94,
                riskMultiplierMax: 1.18,
                opponentMultiplierUrgencyWeight: 0.06,
                opponentMultiplierEvidenceBonus: 0.05,
                opponentMultiplierMin: 0.95,
                opponentMultiplierMax: 1.16,
                jokerMultiplierUrgencyWeight: 0.10,
                jokerMultiplierChaseBonus: 0.05,
                jokerMultiplierDumpBonus: 0.06,
                jokerMultiplierMin: 0.90,
                jokerMultiplierMax: 1.22,
                cappedTacticalMagnitude: 180.0,
                cappedRiskMagnitude: 180.0,
                cappedOpponentMagnitude: 120.0,
                cappedJokerMagnitude: 180.0,
                stabilizationWindowBase: 90.0,
                stabilizationWindowMissWeight: 50.0,
                stabilizationWindowThreatWeight: 0.15
            ),
            utilityTieTolerance: 0.000_001
        ),
        bidding: Bidding(
            blindMonteCarloMinIterations: 24,
            blindMonteCarloMaxIterations: 56,
            blindMonteCarloIterationsPerCard: 5,
            blindMonteCarloIterationsPerBid: 2,
            bidUtilityTieTolerance: 0.000_001,
            blindRiskScoreBase: -0.55,
            blindCatchUpThresholdBonus: 0.35,
            blindDesperateThresholdBonus: 0.35,
            blindCatchUpPressureMultiplier: 1.2,
            blindDesperatePressureMultiplier: 0.95,
            blindSafetyPenaltyMultiplier: 1.1,
            blindLeaderPenalty: 0.5,
            blindDealerPenalty: 0.2,
            blindNonDealerBonus: 0.08,
            blindTableLeaderPenalty: 0.35,
            blindLongRoundBonusCap: 0.35,
            blindLongRoundThreshold: 4,
            blindLongRoundBonusDivisor: 10.0,
            blindMinAllowedPenalty: 0.35,
            blindNarrowRangePenalty: 0.2,
            blindMediumRangePenalty: 0.1,
            blindWideRangeBonus: 0.05,
            blindRiskScoreThreshold: 0.05,
            blindDesperateModeThreshold: 1.6,
            blindOverflowDivisor: 1.2,
            blindDesperateOverflowBonus: 0.08,
            blindCatchUpModeThreshold: 0.85,
            blindModeProgressDivisor: 0.75,
            blindCatchUpToDesperateWeight: 0.35,
            blindConservativeProgressDivisor: 0.8,
            blindConservativeToCatchUpWeight: 0.45,
            blindDealerPositionAdjustment: -0.03,
            blindNonDealerAdjustment: 0.02,
            blindLongRoundAdjustment: 0.03,
            blindLongRoundAdjustmentThreshold: 8,
            blindSafetyAdjustment: -0.05,
            blindTargetShareCap: 0.95,
            blindRiskBudgetNormalizationDivisor: 2.0,
            bidUtilityOptimalityPenaltyBase: 7.4,
            bidUtilityOptimalityPenaltyProgress: 2.8,
            bidUtilityOptimalityPenaltyBaseNoForbidden: 3.0,
            bidUtilityOptimalityPenaltyProgressNoForbidden: 1.2,
            bidUtilityExpectedPenaltyBase: 1.7,
            bidUtilityExpectedPenaltyProgress: 0.9,
            bidUtilityScoreGapPenaltyForbidden: 0.70,
            bidUtilityScoreGapPenaltyNoForbidden: 0.38,
            mcVariancePenaltyBase: 0.50,
            mcSafeLeadPressureMax: 0.55,
            mcDesperatePenaltyWeight: 0.35,
            mcVariancePenaltyWeightMin: 0.08,
            mcVariancePenaltyWeightMax: 1.35,
            mcVarianceRiskBudgetModifier: 0.55,
            mcDeviationPenaltyBase: 1.2,
            mcDeviationRiskBudgetMultiplier: 3.6,
            mcOvershootPenaltyBase: 1.4,
            mcOvershootSafeLeadMultiplier: 1.1,
            mcCatchUpAggressionBase: 1.7,
            mcCatchUpAggressionPressureMultiplier: 1.1,
            minAggressiveBidDesperateMin: 2,
            minAggressiveBidDesperateShare: 0.62,
            minAggressiveBidCatchUpBase: 0.28,
            minAggressiveBidCatchUpProgress: 0.20,
            defaultRNGSeed: 0xA24B_AED4_963E_E407,
            rngMultiplier: 6364136223846793005,
            rngIncrement: 1442695040888963407,
            monteCarloBaseSeed: 0x9E37_79B9_7F4A_7C15,
            hashShiftRight1: 21,
            hashShiftLeft: 37,
            hashShiftRight2: 4
        ),
        heuristics: Heuristics(
            legalAwareMinIterations: 20,
            legalAwareMaxIterations: 48,
            legalAwareReducedMinIterations: 8,
            legalAwareReducedMaxIterations: 20,
            legalAwareRotationStride: 7,
            legalAwareReducedMaxCardsPerOpponentSample: 3,
            legalAwareEndgameHandSizeThreshold: 4
        ),
        opponentModeling: OpponentModeling(
            opponentDisciplineNeutralValue: 0.5,
            opponentDisciplineMismatchWeight: 0.5,
            opponentDisciplineNormalizationWeight: 0.5,
            opponentStyleEvidenceSaturationRounds: 4,
            opponentStyleMultiplierMin: 0.85,
            opponentStyleMultiplierMax: 1.25,
            opponentStyleDisciplineWeight: 0.22,
            opponentStyleAggressionWeight: 0.10,
            opponentStyleBlindPressureWeight: 0.04,
            opponentStyleExactBase: 0.5,
            opponentStyleAggressionBase: 0.45,
            opponentStyleBlindBase: 0.20,
            opponentLeadJokerAntiPremiumWeight: 0.60,
            opponentMatchCatchUpUrgencyWeight: 0.35,
            opponentBlindChaseContestWeight: 0.25,
            opponentLateBlockWeightBase: 0.15,
            opponentLateBlockWeightProgress: 0.85,
            opponentBidPressureNextWeight: 1.0,
            opponentBidPressureLeftNeighborWeight: 0.9,
            opponentBidPressureOtherWeight: 0.45,
            opponentBidPressureMax: 1.8,
            opponentBidPressureChaseBase: 10.0,
            opponentBidPressureChaseProgress: 8.0,
            opponentBidPressureDumpBase: 7.0,
            opponentBidPressureDumpProgress: 9.0,
            opponentIntentionPressureMax: 1.9,
            opponentIntentionAggregateWeight: 0.22,
            opponentIntentionChaseBase: 8.0,
            opponentIntentionChaseProgress: 7.5,
            opponentIntentionDumpBase: 6.5,
            opponentIntentionDumpProgress: 8.5
        )
    )

    private func overriding(
        ranking: Ranking? = nil,
        bidding: Bidding? = nil,
        heuristics: Heuristics? = nil,
        opponentModeling: OpponentModeling? = nil
    ) -> BotRuntimePolicy {
        BotRuntimePolicy(
            ranking: ranking ?? self.ranking,
            bidding: bidding ?? self.bidding,
            heuristics: heuristics ?? self.heuristics,
            opponentModeling: opponentModeling ?? self.opponentModeling
        )
    }
}
