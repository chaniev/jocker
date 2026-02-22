//
//  BotTuning+SelfPlayEvolution.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import Foundation

extension BotTuning {
    typealias SelfPlayEvolutionConfig = BotSelfPlayEvolutionEngine.SelfPlayEvolutionConfig
    typealias SelfPlayEvolutionResult = BotSelfPlayEvolutionEngine.SelfPlayEvolutionResult
    typealias SelfPlayHeadToHeadValidationResult = BotSelfPlayEvolutionEngine.SelfPlayHeadToHeadValidationResult
    typealias SelfPlayEvolutionProgress = BotSelfPlayEvolutionEngine.SelfPlayEvolutionProgress

    static func evolveViaSelfPlay(
        baseTuning: BotTuning,
        config: SelfPlayEvolutionConfig = SelfPlayEvolutionConfig(),
        seed: UInt64 = 0x5EED,
        progress: ((SelfPlayEvolutionProgress) -> Void)? = nil
    ) -> SelfPlayEvolutionResult {
        return BotSelfPlayEvolutionEngine.evolveViaSelfPlay(
            baseTuning: baseTuning,
            config: config,
            seed: seed,
            progress: progress
        )
    }

    static func evaluateHeadToHead(
        candidateTuning: BotTuning,
        opponentTuning: BotTuning,
        config: SelfPlayEvolutionConfig = SelfPlayEvolutionConfig(),
        seed: UInt64 = 0x5EED
    ) -> SelfPlayHeadToHeadValidationResult {
        return BotSelfPlayEvolutionEngine.evaluateHeadToHead(
            candidateTuning: candidateTuning,
            opponentTuning: opponentTuning,
            config: config,
            seed: seed
        )
    }
}
