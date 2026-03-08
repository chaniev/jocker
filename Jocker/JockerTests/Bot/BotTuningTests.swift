//
//  BotTuningTests.swift
//  JockerTests
//
//  Created by Codex on 15.02.2026.
//

import XCTest
@testable import Jocker

#if canImport(JockerSelfPlayTools)
@testable import JockerSelfPlayTools
#endif

final class BotTuningTests: XCTestCase {
    /// Тестирует, что normal preset совпадает с legacy reference значениями.
    /// Проверяет:
    /// - chaseWinProbabilityWeight = 50.0
    /// - dumpSpendJokerPenalty = 70.0
    /// - blindDesperateBehindThreshold = 250
    /// - minimumPowerToDeclareTrump = 1.55
    /// - playingBotTurnDelay = 0.35
    /// - runtimePolicy.bidding.blindMonteCarlo.maximumIterations = 44
    func testNormalPreset_matchesLegacyReferenceValues() {
        let tuning = Jocker.BotTuning(difficulty: .normal)

        XCTAssertEqual(tuning.turnStrategy.chaseWinProbabilityWeight, 50.0, accuracy: 0.000_1)
        XCTAssertEqual(tuning.turnStrategy.dumpSpendJokerPenalty, 70.0, accuracy: 0.000_1)
        XCTAssertEqual(tuning.bidding.blindDesperateBehindThreshold, 250)
        XCTAssertEqual(tuning.trumpSelection.minimumPowerToDeclareTrump, 1.55, accuracy: 0.000_1)
        XCTAssertEqual(tuning.timing.playingBotTurnDelay, 0.35, accuracy: 0.000_1)
        XCTAssertEqual(tuning.runtimePolicy.bidding.blindMonteCarlo.maximumIterations, 44)
    }

    /// Тестирует, что difficulty presets меняют aggressiveness и tempo.
    /// Проверяет:
    /// - easy < normal < hard для chaseSpendJokerPenalty
    /// - hard > easy > normal для minimumPowerToDeclareTrump
    /// - easy > normal > hard для playingBotTurnDelay
    /// - easy < normal < hard для runtime Monte Carlo budgets
    func testDifficultyPresets_changeAggressivenessAndTempo() {
        let easy = Jocker.BotTuning(difficulty: .easy)
        let normal = Jocker.BotTuning(difficulty: .normal)
        let hard = Jocker.BotTuning(difficulty: .hard)

        XCTAssertLessThan(easy.turnStrategy.chaseSpendJokerPenalty, normal.turnStrategy.chaseSpendJokerPenalty)
        XCTAssertLessThan(normal.turnStrategy.chaseSpendJokerPenalty, hard.turnStrategy.chaseSpendJokerPenalty)

        XCTAssertGreaterThan(hard.trumpSelection.minimumPowerToDeclareTrump, easy.trumpSelection.minimumPowerToDeclareTrump)
        XCTAssertGreaterThan(easy.trumpSelection.minimumPowerToDeclareTrump, normal.trumpSelection.minimumPowerToDeclareTrump)

        XCTAssertGreaterThan(easy.timing.playingBotTurnDelay, normal.timing.playingBotTurnDelay)
        XCTAssertGreaterThan(normal.timing.playingBotTurnDelay, hard.timing.playingBotTurnDelay)

        XCTAssertLessThan(
            easy.runtimePolicy.bidding.blindMonteCarlo.maximumIterations,
            normal.runtimePolicy.bidding.blindMonteCarlo.maximumIterations
        )
        XCTAssertLessThan(
            normal.runtimePolicy.bidding.blindMonteCarlo.maximumIterations,
            hard.runtimePolicy.bidding.blindMonteCarlo.maximumIterations
        )
    }

    /// Тестирует, что easy preset совпадает с reference значениями и hard держит разумные границы.
    /// Проверяет:
    /// - easy: chaseWinProbabilityWeight = 42.0, expectedTrumpBaseBonus = 0.35
    /// - hard: trickResolutionDelay в диапазоне [0.45, 0.65]
    func testEasyPreset_matchesReferenceValues_andHardKeepsReasonableBounds() {
        let easy = Jocker.BotTuning(difficulty: .easy)
        let hard = Jocker.BotTuning(difficulty: .hard)

        XCTAssertEqual(easy.turnStrategy.chaseWinProbabilityWeight, 42.0, accuracy: 0.000_1)
        XCTAssertEqual(easy.bidding.expectedTrumpBaseBonus, 0.35, accuracy: 0.000_1)
        XCTAssertEqual(easy.timing.trickResolutionDelay, 0.65, accuracy: 0.000_1)
        XCTAssertEqual(hard.timing.trickResolutionDelay, 0.45, accuracy: 0.000_1)
        XCTAssertGreaterThanOrEqual(hard.bidding.expectedLongSuitBonusPerCard, 0.0)
        XCTAssertGreaterThanOrEqual(hard.bidding.expectedTrumpDensityBonus, 0.0)
        XCTAssertGreaterThanOrEqual(hard.bidding.expectedNoTrumpHighCardBonus, 0.0)
        XCTAssertGreaterThanOrEqual(hard.bidding.expectedNoTrumpJokerSynergy, 0.0)
        XCTAssertEqual(hard.runtimePolicy.ranking.standardBlockScoreScale, 260.0, accuracy: 0.000_1)
        XCTAssertEqual(hard.runtimePolicy.ranking.jokerDeclaration.earlyWishPenaltyBase, 24.0, accuracy: 0.000_1)
        XCTAssertEqual(hard.runtimePolicy.ranking.moveComposition.blindRewardMultiplier, 1.55, accuracy: 0.000_1)
        XCTAssertEqual(hard.runtimePolicy.opponentModeling.opponentLeadJokerAntiPremiumWeight, 0.60, accuracy: 0.000_1)
        XCTAssertEqual(hard.runtimePolicy.opponentModeling.opponentDisciplineNeutralValue, 0.50, accuracy: 0.000_1)
    }

    func testRuntimePolicy_exposesEvaluatorRolloutEndgameSimulationHeuristicsAndHandStrengthGroups() {
        let tuning = Jocker.BotTuning(difficulty: .hard)

        XCTAssertEqual(
            tuning.runtimePolicy.evaluator.leadControlReserve.trumpAceValue,
            1.20,
            accuracy: 0.000_1
        )
        XCTAssertEqual(
            tuning.runtimePolicy.evaluator.preferredControlSuit.concentrationShareNormalizer,
            0.55,
            accuracy: 0.000_1
        )
        XCTAssertEqual(tuning.runtimePolicy.rollout.topCandidateCount, 2)
        XCTAssertEqual(tuning.runtimePolicy.rollout.maximumIterations, 8)
        XCTAssertEqual(
            tuning.runtimePolicy.rollout.utilityTieTolerance,
            0.000_001,
            accuracy: 0.000_000_1
        )
        XCTAssertEqual(
            tuning.runtimePolicy.rollout.adjustmentUrgencyWeight,
            10.0,
            accuracy: 0.000_1
        )
        XCTAssertEqual(tuning.runtimePolicy.endgame.maximumIterations, 12)
        XCTAssertEqual(tuning.runtimePolicy.endgame.adjustmentCap, 55.0, accuracy: 0.000_1)
        XCTAssertEqual(tuning.runtimePolicy.simulation.trumpBonus, 18.0, accuracy: 0.000_1)
        XCTAssertEqual(
            tuning.runtimePolicy.simulation.highRankThreshold,
            .queen
        )
        XCTAssertEqual(
            tuning.runtimePolicy.heuristics.holdBlend.legalAwareSimulationWeight,
            0.72,
            accuracy: 0.000_1
        )
        XCTAssertEqual(
            tuning.runtimePolicy.heuristics.legalAwareSimulationCardPower.leadSuitBonus,
            40.0,
            accuracy: 0.000_1
        )
        XCTAssertEqual(
            tuning.runtimePolicy.heuristics.threatPhase.highRankThreshold,
            .queen
        )
        XCTAssertEqual(
            tuning.runtimePolicy.heuristics.threatPosition.lastSeatMultiplier,
            0.90,
            accuracy: 0.000_1
        )
        XCTAssertEqual(
            tuning.runtimePolicy.heuristics.threatHistory.regularMaxMultiplier,
            1.22,
            accuracy: 0.000_1
        )
        XCTAssertEqual(
            tuning.runtimePolicy.handStrength.trumpSelectionControlTopRankWeight,
            0.58,
            accuracy: 0.000_1
        )
        XCTAssertEqual(
            tuning.runtimePolicy.handStrength.noTrumpJokerSupportLongSuitWeight,
            0.65,
            accuracy: 0.000_1
        )
        XCTAssertEqual(
            tuning.trumpSelection.playerChosenPairBonus,
            1.40,
            accuracy: 0.000_1
        )
        XCTAssertEqual(
            tuning.trumpSelection.jokerSynergyControlWeight,
            0.48,
            accuracy: 0.000_1
        )
    }

    func testRuntimePolicyPreset_matchesSectionedCanonicalValuesAcrossDifficulties() {
        let easy = Jocker.BotTuning(difficulty: .easy)
        let normal = Jocker.BotTuning(difficulty: .normal)
        let hard = Jocker.BotTuning(difficulty: .hard)

        XCTAssertEqual(hard.runtimePolicy.ranking.standardBlockScoreScale, 260.0, accuracy: 0.000_1)
        XCTAssertEqual(
            hard.runtimePolicy.bidding.bidSelection.utilityTieTolerance,
            0.000_001,
            accuracy: 0.000_000_1
        )
        XCTAssertEqual(
            hard.runtimePolicy.bidding.blindPolicy.riskScoreBase,
            -0.55,
            accuracy: 0.000_1
        )
        XCTAssertEqual(hard.runtimePolicy.rollout.maximumIterations, 8)
        XCTAssertEqual(
            hard.runtimePolicy.heuristics.threatPhase.highRankThreshold,
            .queen
        )
        XCTAssertEqual(
            hard.runtimePolicy.opponentModeling.opponentLeadJokerAntiPremiumWeight,
            0.60,
            accuracy: 0.000_1
        )

        XCTAssertEqual(normal.runtimePolicy.bidding.blindMonteCarlo.minimumIterations, 20)
        XCTAssertEqual(normal.runtimePolicy.bidding.blindMonteCarlo.maximumIterations, 44)
        XCTAssertEqual(
            normal.runtimePolicy.opponentModeling.opponentLeadJokerAntiPremiumWeight,
            0.52,
            accuracy: 0.000_1
        )

        XCTAssertEqual(easy.runtimePolicy.bidding.blindMonteCarlo.minimumIterations, 16)
        XCTAssertEqual(easy.runtimePolicy.bidding.blindMonteCarlo.maximumIterations, 32)
        XCTAssertEqual(easy.runtimePolicy.heuristics.legalAwareMinIterations, 12)
        XCTAssertEqual(
            easy.runtimePolicy.opponentModeling.opponentBlindChaseContestWeight,
            0.16,
            accuracy: 0.000_1
        )
    }

    /// Тестирует, что custom initializer сохраняет предоставленные компоненты.
    /// Проверяет:
    /// - difficulty = .hard (новый)
    /// - Все компоненты из base (easy) сохраняются
    func testCustomInitializer_keepsProvidedComponents() {
        let base = Jocker.BotTuning(difficulty: .easy)

        let custom = Jocker.BotTuning(
            difficulty: .hard,
            turnStrategy: base.turnStrategy,
            bidding: base.bidding,
            trumpSelection: base.trumpSelection,
            runtimePolicy: base.runtimePolicy,
            timing: base.timing
        )

        XCTAssertEqual(custom.difficulty, .hard)
        XCTAssertEqual(custom.turnStrategy.chaseWinProbabilityWeight, base.turnStrategy.chaseWinProbabilityWeight, accuracy: 0.000_1)
        XCTAssertEqual(custom.bidding.blindDesperateBehindThreshold, base.bidding.blindDesperateBehindThreshold)
        XCTAssertEqual(custom.trumpSelection.minimumPowerToDeclareTrump, base.trumpSelection.minimumPowerToDeclareTrump, accuracy: 0.000_1)
        XCTAssertEqual(
            custom.runtimePolicy.bidding.blindMonteCarlo.minimumIterations,
            base.runtimePolicy.bidding.blindMonteCarlo.minimumIterations
        )
        XCTAssertEqual(custom.timing.playingBotTurnDelay, base.timing.playingBotTurnDelay, accuracy: 0.000_1)
    }

    func testTurnStrategy_exposesJokerCoefficientsDirectly() {
        let tuning = Jocker.BotTuning(difficulty: .hard)

        XCTAssertEqual(tuning.turnStrategy.chaseSpendJokerPenalty, 120.116_961, accuracy: 0.000_1)
        XCTAssertEqual(tuning.turnStrategy.dumpLeadTakesNonTrumpBonus, 8.0, accuracy: 0.000_1)
        XCTAssertEqual(tuning.turnStrategy.threatLeadWishJoker, 110.0, accuracy: 0.000_1)
        XCTAssertEqual(tuning.turnStrategy.powerLeadAboveJoker, 995)
    }

    func testRuntimePolicyPresets_allDifficulties_haveConsistentSections() {
        for difficulty in [Jocker.BotDifficulty.easy, Jocker.BotDifficulty.normal, Jocker.BotDifficulty.hard] {
            let tuning = Jocker.BotTuning(difficulty: difficulty)
            let policy = tuning.runtimePolicy

            XCTAssertGreaterThan(policy.ranking.standardBlockScoreScale, 0)
            XCTAssertGreaterThan(policy.bidding.bidSelection.optimalityPenaltyBase, 0)
            XCTAssertGreaterThan(policy.evaluator.leadControlReserve.trumpAceValue, 0)
            XCTAssertGreaterThan(policy.rollout.maximumIterations, 0)
            XCTAssertGreaterThan(policy.endgame.maximumIterations, 0)
            XCTAssertGreaterThan(policy.simulation.trumpBonus, 0)
            XCTAssertGreaterThan(policy.handStrength.trumpSelectionControlTopRankWeight, 0)
            XCTAssertGreaterThan(policy.heuristics.legalAwareMaxIterations, 0)
            XCTAssertGreaterThan(policy.opponentModeling.opponentStyleEvidenceSaturationRounds, 0)
        }
    }

    func testBotTuningPresets_allDifficulties_havePositiveTurnStrategyWeights() {
        for difficulty in [Jocker.BotDifficulty.easy, Jocker.BotDifficulty.normal, Jocker.BotDifficulty.hard] {
            let tuning = Jocker.BotTuning(difficulty: difficulty)
            XCTAssertGreaterThan(tuning.turnStrategy.chaseWinProbabilityWeight, 0)
            XCTAssertGreaterThan(tuning.turnStrategy.dumpAvoidWinWeight, 0)
            XCTAssertGreaterThan(tuning.turnStrategy.holdFromDistributionWeight, 0)
            XCTAssertGreaterThan(tuning.turnStrategy.futureTricksScale, 0)
        }
    }

    func testBotTuningPresets_allDifficulties_havePositiveBiddingWeights() {
        for difficulty in [Jocker.BotDifficulty.easy, Jocker.BotDifficulty.normal, Jocker.BotDifficulty.hard] {
            let tuning = Jocker.BotTuning(difficulty: difficulty)
            XCTAssertGreaterThan(tuning.bidding.expectedJokerPower, 0)
            XCTAssertGreaterThan(tuning.bidding.blindDesperateBehindThreshold, 0)
            XCTAssertGreaterThan(tuning.bidding.blindCatchUpBehindThreshold, 0)
            XCTAssertGreaterThan(tuning.bidding.blindSafeLeadThreshold, 0)
            XCTAssertGreaterThan(tuning.bidding.blindDesperateTargetShare, 0)
        }
    }

    func testBotTuningPresets_allDifficulties_havePositiveTrumpSelectionWeights() {
        for difficulty in [Jocker.BotDifficulty.easy, Jocker.BotDifficulty.normal, Jocker.BotDifficulty.hard] {
            let tuning = Jocker.BotTuning(difficulty: difficulty)
            XCTAssertGreaterThan(tuning.trumpSelection.cardBasePower, 0)
            XCTAssertGreaterThan(tuning.trumpSelection.minimumPowerToDeclareTrump, 0)
        }
    }

#if canImport(JockerSelfPlayTools)
    /// Тестирует, что self-play evolution с одинаковым seed детерминирован.
    /// Проверяет:
    /// - firstRun и secondRun с seed = 123456 дают одинаковые результаты
    /// - baselineFitness, bestFitness, generationBestFitness совпадают
    func testSelfPlayEvolution_withSameSeed_isDeterministic() {
        let base = JockerSelfPlayTools.BotTuning(difficulty: .hard)
        let config = JockerSelfPlayTools.BotTuning.SelfPlayEvolutionConfig(
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

        let firstRun = JockerSelfPlayTools.BotTuning.evolveViaSelfPlay(
            baseTuning: base,
            config: config,
            seed: 123_456
        )
        let secondRun = JockerSelfPlayTools.BotTuning.evolveViaSelfPlay(
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

    /// Тестирует, что self-play evolution держит best не хуже baseline.
    /// Проверяет:
    /// - generationBestFitness.count = config.generations
    /// - bestFitness >= baselineFitness
    /// - improvement >= 0.0
    func testSelfPlayEvolution_keepsBestNotWorseThanBaseline() {
        let base = JockerSelfPlayTools.BotTuning(difficulty: .hard)
        let config = JockerSelfPlayTools.BotTuning.SelfPlayEvolutionConfig(
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

        let result = JockerSelfPlayTools.BotTuning.evolveViaSelfPlay(
            baseTuning: base,
            config: config,
            seed: 424_242
        )

        XCTAssertEqual(result.generationBestFitness.count, config.generations)
        XCTAssertGreaterThanOrEqual(result.bestFitness, result.baselineFitness)
        XCTAssertGreaterThanOrEqual(result.improvement, 0.0)
    }

    func testSelfPlayEvolution_baselineOnly_skipsGenerationLoop() {
        let base = JockerSelfPlayTools.BotTuning(difficulty: .hard)
        let config = JockerSelfPlayTools.BotTuning.SelfPlayEvolutionConfig(
            runMode: .baselineOnly,
            populationSize: 4,
            generations: 3,
            gamesPerCandidate: 2,
            roundsPerGame: 2,
            playerCount: 3,
            cardsPerRoundRange: 1...3,
            eliteCount: 1,
            mutationChance: 0.25,
            mutationMagnitude: 0.12,
            selectionPoolRatio: 0.5
        )

        let result = JockerSelfPlayTools.BotTuning.evolveViaSelfPlay(
            baseTuning: base,
            config: config,
            seed: 2026_0307
        )

        XCTAssertEqual(result.runMode, .baselineOnly)
        XCTAssertEqual(result.completedGenerations, 0)
        XCTAssertTrue(result.generationBestFitness.isEmpty)
        XCTAssertEqual(result.bestFitness, result.baselineFitness, accuracy: 0.000_001)
        XCTAssertFalse(result.stoppedEarly)
    }

    /// Тестирует self-play evolution с 10 раундами и report fitness.
    /// Проверяет:
    /// - generationBestFitness.count = config.generations
    /// - Все fitness компоненты конечные (isFinite)
    func testSelfPlayEvolution_runsTenRounds_reportsFitness() {
        let base = JockerSelfPlayTools.BotTuning(difficulty: .hard)
        let config = JockerSelfPlayTools.BotTuning.SelfPlayEvolutionConfig(
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

        let result = JockerSelfPlayTools.BotTuning.evolveViaSelfPlay(
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
        XCTAssertTrue(result.baselineWinRate.isFinite)
        XCTAssertTrue(result.bestWinRate.isFinite)
        XCTAssertTrue(result.baselineAverageScoreDiff.isFinite)
        XCTAssertTrue(result.bestAverageScoreDiff.isFinite)
        XCTAssertTrue(result.baselineAverageUnderbidLoss.isFinite)
        XCTAssertTrue(result.bestAverageUnderbidLoss.isFinite)
        XCTAssertTrue(result.baselineAverageTrumpDensityUnderbidLoss.isFinite)
        XCTAssertTrue(result.bestAverageTrumpDensityUnderbidLoss.isFinite)
        XCTAssertTrue(result.baselineAverageNoTrumpControlUnderbidLoss.isFinite)
        XCTAssertTrue(result.bestAverageNoTrumpControlUnderbidLoss.isFinite)
        XCTAssertTrue(result.baselineAveragePremiumAssistLoss.isFinite)
        XCTAssertTrue(result.bestAveragePremiumAssistLoss.isFinite)
        XCTAssertTrue(result.baselineAveragePremiumPenaltyTargetLoss.isFinite)
        XCTAssertTrue(result.bestAveragePremiumPenaltyTargetLoss.isFinite)
    }

    /// Тестирует self-play evolution с full match rules и seat rotation.
    /// Проверяет:
    /// - useFullMatchRules = true, rotateCandidateAcrossSeats = true
    /// - winRate в диапазоне [0, 1]
    /// - Все fitness компоненты конечные
    func testSelfPlayEvolution_fullMatchAndSeatRotation_reportsFitnessComponents() {
        let base = JockerSelfPlayTools.BotTuning(difficulty: .hard)
        let config = JockerSelfPlayTools.BotTuning.SelfPlayEvolutionConfig(
            populationSize: 4,
            generations: 2,
            gamesPerCandidate: 2,
            roundsPerGame: 4,
            playerCount: 4,
            cardsPerRoundRange: 2...6,
            eliteCount: 1,
            mutationChance: 0.25,
            mutationMagnitude: 0.12,
            selectionPoolRatio: 0.5,
            useFullMatchRules: true,
            rotateCandidateAcrossSeats: true,
            fitnessWinRateWeight: 1.0,
            fitnessScoreDiffWeight: 1.0,
            fitnessUnderbidLossWeight: 0.85,
            scoreDiffNormalization: 450.0,
            underbidLossNormalization: 6000.0
        )

        let result = JockerSelfPlayTools.BotTuning.evolveViaSelfPlay(
            baseTuning: base,
            config: config,
            seed: 2026_0221
        )

        XCTAssertEqual(result.generationBestFitness.count, config.generations)
        XCTAssertGreaterThanOrEqual(result.baselineWinRate, 0.0)
        XCTAssertLessThanOrEqual(result.baselineWinRate, 1.0)
        XCTAssertGreaterThanOrEqual(result.bestWinRate, 0.0)
        XCTAssertLessThanOrEqual(result.bestWinRate, 1.0)
        XCTAssertTrue(result.baselineAverageScoreDiff.isFinite)
        XCTAssertTrue(result.bestAverageScoreDiff.isFinite)
        XCTAssertGreaterThanOrEqual(result.baselineAverageUnderbidLoss, 0.0)
        XCTAssertGreaterThanOrEqual(result.bestAverageUnderbidLoss, 0.0)
        XCTAssertGreaterThanOrEqual(result.baselineAverageTrumpDensityUnderbidLoss, 0.0)
        XCTAssertGreaterThanOrEqual(result.bestAverageTrumpDensityUnderbidLoss, 0.0)
        XCTAssertGreaterThanOrEqual(result.baselineAverageNoTrumpControlUnderbidLoss, 0.0)
        XCTAssertGreaterThanOrEqual(result.bestAverageNoTrumpControlUnderbidLoss, 0.0)
        XCTAssertGreaterThanOrEqual(result.baselineAveragePremiumAssistLoss, 0.0)
        XCTAssertGreaterThanOrEqual(result.bestAveragePremiumAssistLoss, 0.0)
        XCTAssertGreaterThanOrEqual(result.baselineAveragePremiumPenaltyTargetLoss, 0.0)
        XCTAssertGreaterThanOrEqual(result.bestAveragePremiumPenaltyTargetLoss, 0.0)
    }
#endif
}
