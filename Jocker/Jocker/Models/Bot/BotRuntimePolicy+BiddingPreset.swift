//
//  BotRuntimePolicy+BiddingPreset.swift
//  Jocker
//
//  Created by Codex on 07.03.2026.
//

import Foundation

extension BotRuntimePolicy {
    static let hardBaselineBidding = Bidding(
        bidSelection: Bidding.BidSelection(
            utilityTieTolerance: 0.000_001,
            optimalityPenaltyBase: 7.4,
            optimalityPenaltyProgress: 2.8,
            optimalityPenaltyBaseNoForbidden: 3.0,
            optimalityPenaltyProgressNoForbidden: 1.2,
            expectedPenaltyBase: 1.7,
            expectedPenaltyProgress: 0.9,
            scoreGapPenaltyForbidden: 0.70,
            scoreGapPenaltyNoForbidden: 0.38
        ),
        blindPolicy: Bidding.BlindPolicy(
            riskScoreBase: -0.55,
            catchUpThresholdBonus: 0.35,
            desperateThresholdBonus: 0.35,
            catchUpPressureMultiplier: 1.2,
            desperatePressureMultiplier: 0.95,
            safetyPenaltyMultiplier: 1.1,
            leaderPenalty: 0.5,
            dealerPenalty: 0.2,
            nonDealerBonus: 0.08,
            tableLeaderPenalty: 0.35,
            longRoundBonusCap: 0.35,
            longRoundThreshold: 4,
            longRoundBonusDivisor: 10.0,
            minAllowedPenalty: 0.35,
            narrowRangePenalty: 0.2,
            mediumRangePenalty: 0.1,
            wideRangeBonus: 0.05,
            riskScoreThreshold: 0.05,
            desperateModeThreshold: 1.6,
            overflowDivisor: 1.2,
            desperateOverflowBonus: 0.08,
            catchUpModeThreshold: 0.85,
            modeProgressDivisor: 0.75,
            catchUpToDesperateWeight: 0.35,
            conservativeProgressDivisor: 0.8,
            conservativeToCatchUpWeight: 0.45,
            dealerPositionAdjustment: -0.03,
            nonDealerAdjustment: 0.02,
            longRoundAdjustment: 0.03,
            longRoundAdjustmentThreshold: 8,
            safetyAdjustment: -0.05,
            targetShareCap: 0.95,
            riskBudgetNormalizationDivisor: 2.0,
            minAggressiveBidDesperateMin: 2,
            minAggressiveBidDesperateShare: 0.62,
            minAggressiveBidCatchUpBase: 0.28,
            minAggressiveBidCatchUpProgress: 0.20
        ),
        blindMonteCarlo: Bidding.BlindMonteCarlo(
            minimumIterations: 24,
            maximumIterations: 56,
            iterationsPerCard: 5,
            iterationsPerBid: 2,
            utilityTieTolerance: 0.000_001,
            variancePenaltyBase: 0.50,
            safeLeadPressureMax: 0.55,
            desperatePenaltyWeight: 0.35,
            variancePenaltyWeightMin: 0.08,
            variancePenaltyWeightMax: 1.35,
            varianceRiskBudgetModifier: 0.55,
            deviationPenaltyBase: 1.2,
            deviationRiskBudgetMultiplier: 3.6,
            overshootPenaltyBase: 1.4,
            overshootSafeLeadMultiplier: 1.1,
            catchUpAggressionBase: 1.7,
            catchUpAggressionPressureMultiplier: 1.1,
            defaultRNGSeed: 0xA24B_AED4_963E_E407,
            rngMultiplier: 6364136223846793005,
            rngIncrement: 1442695040888963407,
            baseSeed: 0x9E37_79B9_7F4A_7C15,
            hashShiftRight1: 21,
            hashShiftLeft: 37,
            hashShiftRight2: 4
        )
    )
}
