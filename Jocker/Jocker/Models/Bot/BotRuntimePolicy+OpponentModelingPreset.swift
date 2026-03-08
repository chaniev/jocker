//
//  BotRuntimePolicy+OpponentModelingPreset.swift
//  Jocker
//
//  Created by Codex on 07.03.2026.
//

import Foundation

extension BotRuntimePolicy {
    static let hardBaselineOpponentModeling = OpponentModeling(
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
}
