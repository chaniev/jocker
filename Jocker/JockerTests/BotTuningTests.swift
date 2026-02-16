//
//  BotTuningTests.swift
//  JockerTests
//
//  Created by Codex on 15.02.2026.
//

import XCTest
@testable import Jocker

final class BotTuningTests: XCTestCase {
    func testNormalPreset_matchesLegacyReferenceValues() {
        let tuning = BotTuning(difficulty: .normal)

        XCTAssertEqual(tuning.turnStrategy.chaseWinProbabilityWeight, 50.0, accuracy: 0.000_1)
        XCTAssertEqual(tuning.turnStrategy.dumpSpendJokerPenalty, 70.0, accuracy: 0.000_1)
        XCTAssertEqual(tuning.bidding.blindDesperateBehindThreshold, 250)
        XCTAssertEqual(tuning.trumpSelection.minimumPowerToDeclareTrump, 1.55, accuracy: 0.000_1)
        XCTAssertEqual(tuning.timing.playingBotTurnDelay, 0.35, accuracy: 0.000_1)
    }

    func testDifficultyPresets_changeAggressivenessAndTempo() {
        let easy = BotTuning(difficulty: .easy)
        let normal = BotTuning(difficulty: .normal)
        let hard = BotTuning(difficulty: .hard)

        XCTAssertLessThan(easy.bidding.expectedJokerPower, normal.bidding.expectedJokerPower)
        XCTAssertLessThan(normal.bidding.expectedJokerPower, hard.bidding.expectedJokerPower)

        XCTAssertGreaterThan(easy.trumpSelection.minimumPowerToDeclareTrump, normal.trumpSelection.minimumPowerToDeclareTrump)
        XCTAssertGreaterThan(normal.trumpSelection.minimumPowerToDeclareTrump, hard.trumpSelection.minimumPowerToDeclareTrump)

        XCTAssertGreaterThan(easy.timing.playingBotTurnDelay, normal.timing.playingBotTurnDelay)
        XCTAssertGreaterThan(normal.timing.playingBotTurnDelay, hard.timing.playingBotTurnDelay)
    }

    func testEasyAndHardPresets_matchReferenceValues() {
        let easy = BotTuning(difficulty: .easy)
        let hard = BotTuning(difficulty: .hard)

        XCTAssertEqual(easy.turnStrategy.chaseWinProbabilityWeight, 42.0, accuracy: 0.000_1)
        XCTAssertEqual(easy.bidding.expectedTrumpBaseBonus, 0.35, accuracy: 0.000_1)
        XCTAssertEqual(easy.timing.trickResolutionDelay, 0.65, accuracy: 0.000_1)

        XCTAssertEqual(hard.turnStrategy.chaseWinProbabilityWeight, 55.0, accuracy: 0.000_1)
        XCTAssertEqual(hard.bidding.expectedTrumpBaseBonus, 0.65, accuracy: 0.000_1)
        XCTAssertEqual(hard.timing.trickResolutionDelay, 0.45, accuracy: 0.000_1)
    }

    func testCustomInitializer_keepsProvidedComponents() {
        let base = BotTuning(difficulty: .easy)

        let custom = BotTuning(
            difficulty: .hard,
            turnStrategy: base.turnStrategy,
            bidding: base.bidding,
            trumpSelection: base.trumpSelection,
            timing: base.timing
        )

        XCTAssertEqual(custom.difficulty, .hard)
        XCTAssertEqual(custom.turnStrategy.chaseWinProbabilityWeight, base.turnStrategy.chaseWinProbabilityWeight, accuracy: 0.000_1)
        XCTAssertEqual(custom.bidding.blindDesperateBehindThreshold, base.bidding.blindDesperateBehindThreshold)
        XCTAssertEqual(custom.trumpSelection.minimumPowerToDeclareTrump, base.trumpSelection.minimumPowerToDeclareTrump, accuracy: 0.000_1)
        XCTAssertEqual(custom.timing.playingBotTurnDelay, base.timing.playingBotTurnDelay, accuracy: 0.000_1)
    }

    func testSelfPlayEvolution_withSameSeed_isDeterministic() {
        let base = BotTuning(difficulty: .hard)
        let config = BotTuning.SelfPlayEvolutionConfig(
            populationSize: 4,
            generations: 2,
            gamesPerCandidate: 4,
            roundsPerGame: 2,
            playerCount: 4,
            cardsPerRoundRange: 3...6,
            eliteCount: 2,
            mutationChance: 0.32,
            mutationMagnitude: 0.15,
            selectionPoolRatio: 0.5
        )

        let firstRun = BotTuning.evolveViaSelfPlay(
            baseTuning: base,
            config: config,
            seed: 123_456
        )
        let secondRun = BotTuning.evolveViaSelfPlay(
            baseTuning: base,
            config: config,
            seed: 123_456
        )

        XCTAssertEqual(firstRun.baselineFitness, secondRun.baselineFitness, accuracy: 0.000_001)
        XCTAssertEqual(firstRun.bestFitness, secondRun.bestFitness, accuracy: 0.000_001)
        XCTAssertEqual(firstRun.generationBestFitness.count, secondRun.generationBestFitness.count)
        for index in 0..<firstRun.generationBestFitness.count {
            XCTAssertEqual(
                firstRun.generationBestFitness[index],
                secondRun.generationBestFitness[index],
                accuracy: 0.000_001
            )
        }

        XCTAssertEqual(
            firstRun.bestTuning.turnStrategy.chaseWinProbabilityWeight,
            secondRun.bestTuning.turnStrategy.chaseWinProbabilityWeight,
            accuracy: 0.000_001
        )
        XCTAssertEqual(
            firstRun.bestTuning.bidding.expectedJokerPower,
            secondRun.bestTuning.bidding.expectedJokerPower,
            accuracy: 0.000_001
        )
    }

    func testSelfPlayEvolution_keepsBestNotWorseThanBaseline() {
        let base = BotTuning(difficulty: .hard)
        let config = BotTuning.SelfPlayEvolutionConfig(
            populationSize: 6,
            generations: 3,
            gamesPerCandidate: 6,
            roundsPerGame: 3,
            playerCount: 4,
            cardsPerRoundRange: 2...7,
            eliteCount: 2,
            mutationChance: 0.35,
            mutationMagnitude: 0.18,
            selectionPoolRatio: 0.6
        )

        let result = BotTuning.evolveViaSelfPlay(
            baseTuning: base,
            config: config,
            seed: 424_242
        )

        XCTAssertEqual(result.generationBestFitness.count, config.generations)
        XCTAssertGreaterThanOrEqual(result.bestFitness, result.baselineFitness)
        XCTAssertGreaterThanOrEqual(result.improvement, 0.0)
    }

    func testSelfPlayEvolution_runsTenRounds_reportsFitness() {
        let base = BotTuning(difficulty: .hard)
        let config = BotTuning.SelfPlayEvolutionConfig(
            populationSize: 4,
            generations: 2,
            gamesPerCandidate: 4,
            roundsPerGame: 10,
            playerCount: 4,
            cardsPerRoundRange: 3...8,
            eliteCount: 2,
            mutationChance: 0.30,
            mutationMagnitude: 0.16,
            selectionPoolRatio: 0.5
        )

        let result = BotTuning.evolveViaSelfPlay(
            baseTuning: base,
            config: config,
            seed: 10_000
        )

        print(
            "SELF_PLAY_10_ROUNDS baseline=\(result.baselineFitness) " +
            "best=\(result.bestFitness) " +
            "improvement=\(result.improvement)"
        )

        XCTAssertEqual(result.generationBestFitness.count, config.generations)
        XCTAssertTrue(result.bestFitness.isFinite)
    }
}
