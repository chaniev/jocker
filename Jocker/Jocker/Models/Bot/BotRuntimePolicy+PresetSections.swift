//
//  BotRuntimePolicy+PresetSections.swift
//  Jocker
//
//  Created by Codex on 07.03.2026.
//

import Foundation

extension BotRuntimePolicy {
    static let hardBaselinePreset = BotRuntimePolicy(
        ranking: hardBaselineRanking,
        bidding: hardBaselineBidding,
        evaluator: hardBaselineEvaluator,
        rollout: hardBaselineRollout,
        endgame: hardBaselineEndgame,
        simulation: hardBaselineSimulation,
        handStrength: hardBaselineHandStrength,
        heuristics: hardBaselineHeuristics,
        opponentModeling: hardBaselineOpponentModeling
    )
}
