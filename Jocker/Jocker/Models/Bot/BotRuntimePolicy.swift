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

        var utilityTieTolerance: Double
    }

    struct Bidding {
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
