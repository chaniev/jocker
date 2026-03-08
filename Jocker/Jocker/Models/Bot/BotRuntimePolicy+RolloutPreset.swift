//
//  BotRuntimePolicy+RolloutPreset.swift
//  Jocker
//
//  Created by Codex on 07.03.2026.
//

import Foundation

extension BotRuntimePolicy {
    static let hardBaselineRollout = Rollout(
        topCandidateCount: 2,
        utilityTieTolerance: 0.000_001,
        minimumIterations: 4,
        maximumIterations: 8,
        unseenCardsIterationsDivisor: 4,
        maxCardsPerOpponentSample: 2,
        maxTrickHorizon: 2,
        handSizeGateThreshold: 3,
        jokerGateHandSizeThreshold: 4,
        lateBlockUrgencyHandSizeThreshold: 4,
        lateBlockProgressThreshold: 0.90,
        criticalDeficitHandSizeThreshold: 4,
        criticalDeficitMinimumFloor: 2,
        chaseUrgencyBase: 0.45,
        chaseUrgencyDeficitWeight: 0.35,
        chaseUrgencyLateBlockWeight: 0.20,
        dumpUrgencyBase: 0.35,
        dumpUrgencyLateBlockWeight: 0.45,
        dumpUrgencyDeficitWeight: 0.20,
        adjustmentBase: 6.0,
        adjustmentUrgencyWeight: 10.0
    )

    static let hardBaselineEndgame = Endgame(
        solverHandSizeThreshold: 3,
        minimumCandidateCount: 2,
        minimumIterations: 6,
        maximumIterations: 12,
        unseenCardsIterationsDivisor: 3,
        weightBase: 0.22,
        weightUrgencyMultiplier: 0.28,
        adjustmentCap: 55.0
    )
}
