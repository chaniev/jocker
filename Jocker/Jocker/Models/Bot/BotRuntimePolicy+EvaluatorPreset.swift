//
//  BotRuntimePolicy+EvaluatorPreset.swift
//  Jocker
//
//  Created by Codex on 07.03.2026.
//

import Foundation

extension BotRuntimePolicy {
    static let hardBaselineEvaluator = Evaluator(
        leadControlReserve: Evaluator.LeadControlReserve(
            nonRegularCardValue: 1.0,
            trumpAceValue: 1.20,
            trumpKingValue: 1.00,
            trumpQueenValue: 0.85,
            trumpJackValue: 0.65,
            trumpLowValue: 0.35,
            nonTrumpAceValue: 0.70,
            nonTrumpKingValue: 0.55,
            nonTrumpQueenValue: 0.40,
            nonTrumpJackValue: 0.22,
            extraTrumpCountThreshold: 2,
            extraTrumpCountBonusPerCard: 0.20
        ),
        preferredControlSuit: Evaluator.PreferredControlSuit(
            baseScore: 0.20,
            aceBonus: 1.20,
            kingBonus: 0.95,
            queenBonus: 0.75,
            jackBonus: 0.50,
            tenBonus: 0.35,
            lowRankBonus: 0.12,
            trumpBonus: 0.45,
            concentrationShareBaseline: 0.25,
            concentrationShareNormalizer: 0.55,
            tieTolerance: 0.000_001
        )
    )
}
