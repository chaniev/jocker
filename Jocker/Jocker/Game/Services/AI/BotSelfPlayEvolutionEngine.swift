//
//  BotSelfPlayEvolutionEngine.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import Foundation

enum BotSelfPlayEvolutionEngine {
    /// Конфигурация эволюции параметров бота через self-play.
    struct SelfPlayEvolutionConfig {
        let populationSize: Int
        /// Количество seed-сценариев для оценки одного кандидата.
        let gamesPerCandidate: Int
        let generations: Int
        /// Используется только в legacy-режиме (`useFullMatchRules = false`).
        let roundsPerGame: Int
        let playerCount: Int
        /// Используется только в legacy-режиме (`useFullMatchRules = false`).
        let cardsPerRoundRange: ClosedRange<Int>
        let eliteCount: Int
        let mutationChance: Double
        let mutationMagnitude: Double
        let selectionPoolRatio: Double

        /// Включает симуляцию полной партии по блокам (1..4) с премиями и blind.
        let useFullMatchRules: Bool
        /// Для каждого seed кандидат оценивается на всех местах за столом.
        let rotateCandidateAcrossSeats: Bool

        /// Вес win-rate компоненты в fitness.
        let fitnessWinRateWeight: Double
        /// Вес компоненты разницы очков относительно оппонентов.
        let fitnessScoreDiffWeight: Double
        /// Вес компоненты минимизации потерь от недозаказа.
        let fitnessUnderbidLossWeight: Double
        /// Вес компоненты минимизации недозаказа в "козырной плотности".
        let fitnessTrumpDensityUnderbidWeight: Double
        /// Вес компоненты минимизации недозаказа в no-trump контрольных руках.
        let fitnessNoTrumpControlUnderbidWeight: Double
        /// Вес компоненты штрафа за "подаренные" соперникам премии.
        let fitnessPremiumAssistWeight: Double
        /// Вес компоненты штрафа за получение штрафа как цель чужой премии.
        let fitnessPremiumPenaltyTargetWeight: Double
        /// Нормализация score-diff компоненты (чем больше, тем слабее вклад).
        let scoreDiffNormalization: Double
        /// Нормализация underbid-loss компоненты (чем больше, тем слабее вклад).
        let underbidLossNormalization: Double
        /// Нормализация компоненты недозаказа в "козырной плотности".
        let trumpDensityUnderbidNormalization: Double
        /// Нормализация компоненты недозаказа в no-trump контрольных руках.
        let noTrumpControlUnderbidNormalization: Double
        /// Нормализация компоненты "подаренных" премий соперникам.
        let premiumAssistNormalization: Double
        /// Нормализация компоненты штрафа как цели чужой премии.
        let premiumPenaltyTargetNormalization: Double
        /// Early stopping по числу поколений без значимого улучшения best fitness.
        /// `0` отключает early stopping.
        let earlyStoppingPatience: Int
        /// Минимальный прирост fitness, который считается значимым улучшением.
        let earlyStoppingMinImprovement: Double
        /// Минимальное число завершённых поколений перед проверкой early stopping.
        let earlyStoppingWarmupGenerations: Int

        init(
            populationSize: Int = 16,
            generations: Int = 10,
            gamesPerCandidate: Int = 32,
            roundsPerGame: Int = 8,
            playerCount: Int = 4,
            cardsPerRoundRange: ClosedRange<Int> = 3...9,
            eliteCount: Int = 2,
            mutationChance: Double = 0.35,
            mutationMagnitude: Double = 0.18,
            selectionPoolRatio: Double = 0.5,
            useFullMatchRules: Bool = true,
            rotateCandidateAcrossSeats: Bool = true,
            fitnessWinRateWeight: Double = 1.0,
            fitnessScoreDiffWeight: Double = 1.0,
            fitnessUnderbidLossWeight: Double = 0.85,
            fitnessTrumpDensityUnderbidWeight: Double = 0.60,
            fitnessNoTrumpControlUnderbidWeight: Double = 0.70,
            fitnessPremiumAssistWeight: Double = 0.55,
            fitnessPremiumPenaltyTargetWeight: Double = 1.10,
            scoreDiffNormalization: Double = 450.0,
            underbidLossNormalization: Double = 6000.0,
            trumpDensityUnderbidNormalization: Double = 2800.0,
            noTrumpControlUnderbidNormalization: Double = 2200.0,
            premiumAssistNormalization: Double = 1800.0,
            premiumPenaltyTargetNormalization: Double = 1600.0,
            earlyStoppingPatience: Int = 0,
            earlyStoppingMinImprovement: Double = 0.0,
            earlyStoppingWarmupGenerations: Int = 0
        ) {
            let normalizedLowerBound = max(
                1,
                min(cardsPerRoundRange.lowerBound, cardsPerRoundRange.upperBound)
            )
            let normalizedUpperBound = max(
                normalizedLowerBound,
                cardsPerRoundRange.upperBound
            )

            self.populationSize = max(2, populationSize)
            self.generations = max(1, generations)
            self.gamesPerCandidate = max(1, gamesPerCandidate)
            self.roundsPerGame = max(1, roundsPerGame)
            self.playerCount = min(4, max(3, playerCount))
            self.cardsPerRoundRange = normalizedLowerBound...normalizedUpperBound
            self.eliteCount = max(1, eliteCount)
            self.mutationChance = SelfPlayEvolutionConfig.clamp(
                mutationChance,
                to: 0.0...1.0
            )
            self.mutationMagnitude = max(0.0, mutationMagnitude)
            self.selectionPoolRatio = SelfPlayEvolutionConfig.clamp(
                selectionPoolRatio,
                to: 0.2...1.0
            )
            self.useFullMatchRules = useFullMatchRules
            self.rotateCandidateAcrossSeats = rotateCandidateAcrossSeats
            self.fitnessWinRateWeight = max(0.0, fitnessWinRateWeight)
            self.fitnessScoreDiffWeight = max(0.0, fitnessScoreDiffWeight)
            self.fitnessUnderbidLossWeight = max(0.0, fitnessUnderbidLossWeight)
            self.fitnessTrumpDensityUnderbidWeight = max(0.0, fitnessTrumpDensityUnderbidWeight)
            self.fitnessNoTrumpControlUnderbidWeight = max(0.0, fitnessNoTrumpControlUnderbidWeight)
            self.fitnessPremiumAssistWeight = max(0.0, fitnessPremiumAssistWeight)
            self.fitnessPremiumPenaltyTargetWeight = max(0.0, fitnessPremiumPenaltyTargetWeight)
            self.scoreDiffNormalization = max(1.0, scoreDiffNormalization)
            self.underbidLossNormalization = max(1.0, underbidLossNormalization)
            self.trumpDensityUnderbidNormalization = max(1.0, trumpDensityUnderbidNormalization)
            self.noTrumpControlUnderbidNormalization = max(1.0, noTrumpControlUnderbidNormalization)
            self.premiumAssistNormalization = max(1.0, premiumAssistNormalization)
            self.premiumPenaltyTargetNormalization = max(1.0, premiumPenaltyTargetNormalization)
            self.earlyStoppingPatience = max(0, earlyStoppingPatience)
            self.earlyStoppingMinImprovement = max(0.0, earlyStoppingMinImprovement)
            self.earlyStoppingWarmupGenerations = max(0, earlyStoppingWarmupGenerations)
        }

        private static func clamp(
            _ value: Double,
            to range: ClosedRange<Double>
        ) -> Double {
            return min(max(value, range.lowerBound), range.upperBound)
        }
    }

    /// Результат запуска self-play эволюции.
    struct SelfPlayEvolutionResult {
        let bestTuning: BotTuning
        let baselineFitness: Double
        let bestFitness: Double
        let generationBestFitness: [Double]
        let completedGenerations: Int
        let stoppedEarly: Bool
        let baselineWinRate: Double
        let bestWinRate: Double
        let baselineAverageScoreDiff: Double
        let bestAverageScoreDiff: Double
        let baselineAverageUnderbidLoss: Double
        let bestAverageUnderbidLoss: Double
        let baselineAverageTrumpDensityUnderbidLoss: Double
        let bestAverageTrumpDensityUnderbidLoss: Double
        let baselineAverageNoTrumpControlUnderbidLoss: Double
        let bestAverageNoTrumpControlUnderbidLoss: Double
        let baselineAveragePremiumAssistLoss: Double
        let bestAveragePremiumAssistLoss: Double
        let baselineAveragePremiumPenaltyTargetLoss: Double
        let bestAveragePremiumPenaltyTargetLoss: Double
        let baselinePremiumCaptureRate: Double
        let bestPremiumCaptureRate: Double
        let baselineBlindSuccessRate: Double
        let bestBlindSuccessRate: Double
        let baselineJokerWishWinRate: Double
        let bestJokerWishWinRate: Double
        let baselineEarlyJokerSpendRate: Double
        let bestEarlyJokerSpendRate: Double
        let baselinePenaltyTargetRate: Double
        let bestPenaltyTargetRate: Double
        let baselineBidAccuracyRate: Double
        let bestBidAccuracyRate: Double
        let baselineOverbidRate: Double
        let bestOverbidRate: Double
        let baselineBlindBidRateBlock4: Double
        let bestBlindBidRateBlock4: Double
        let baselineAverageBlindBidSize: Double
        let bestAverageBlindBidSize: Double
        let baselineBlindBidWhenBehindRate: Double
        let bestBlindBidWhenBehindRate: Double
        let baselineBlindBidWhenLeadingRate: Double
        let bestBlindBidWhenLeadingRate: Double
        let baselineEarlyLeadWishJokerRate: Double
        let bestEarlyLeadWishJokerRate: Double
        let baselineLeftNeighborPremiumAssistRate: Double
        let bestLeftNeighborPremiumAssistRate: Double

        var improvement: Double {
            return bestFitness - baselineFitness
        }
    }

    /// Метрики head-to-head валидации (кандидат против фиксированных оппонентов).
    struct SelfPlayHeadToHeadValidationResult {
        let fitness: Double
        let winRate: Double
        let averageScoreDiff: Double
        let averageUnderbidLoss: Double
        let averageTrumpDensityUnderbidLoss: Double
        let averageNoTrumpControlUnderbidLoss: Double
        let averagePremiumAssistLoss: Double
        let averagePremiumPenaltyTargetLoss: Double
        let premiumCaptureRate: Double
        let blindSuccessRate: Double
        let jokerWishWinRate: Double
        let earlyJokerSpendRate: Double
        let penaltyTargetRate: Double
        let bidAccuracyRate: Double
        let overbidRate: Double
        let blindBidRateBlock4: Double
        let averageBlindBidSize: Double
        let blindBidWhenBehindRate: Double
        let blindBidWhenLeadingRate: Double
        let earlyLeadWishJokerRate: Double
        let leftNeighborPremiumAssistRate: Double
    }

    /// Событие прогресса эволюции self-play.
    struct SelfPlayEvolutionProgress {
        enum Stage {
            case started
            case baselineCompleted
            case generationStarted
            case candidateEvaluated
            case generationCompleted
            case finished
        }

        let stage: Stage
        let generationIndex: Int?
        let totalGenerations: Int
        let evaluatedCandidatesInGeneration: Int?
        let populationSize: Int
        let currentFitness: Double?
        let generationBestFitness: Double?
        let overallBestFitness: Double?
        let completedWorkUnits: Int
        let totalWorkUnits: Int
        let elapsedSeconds: Double
        let estimatedRemainingSeconds: Double?
    }

    /// Запускает эволюционный поиск параметров бота на серии self-play матчей.
    static func evolveViaSelfPlay(
        baseTuning: BotTuning,
        config: SelfPlayEvolutionConfig = SelfPlayEvolutionConfig(),
        seed: UInt64 = 0x5EED,
        progress: ((SelfPlayEvolutionProgress) -> Void)? = nil
    ) -> SelfPlayEvolutionResult {
        let playerCount = min(4, max(3, config.playerCount))
        let cardsRange = normalizedCardsPerRoundRange(
            from: config.cardsPerRoundRange,
            playerCount: playerCount
        )
        let populationSize = max(config.populationSize, config.eliteCount)
        let eliteCount = min(max(1, config.eliteCount), populationSize)
        let selectionPoolSize = min(
            populationSize,
            max(2, Int((Double(populationSize) * config.selectionPoolRatio).rounded(.up)))
        )
        let fitnessScoring = FitnessScoringConfig(config: config)

        var rng = SelfPlayRandomGenerator(seed: seed)
        let evaluationSeeds = makeEvaluationSeeds(
            count: config.gamesPerCandidate,
            using: &rng
        )
        let baselineEvaluationContext = FitnessEvaluationContext(
            playerCount: playerCount,
            roundsPerGame: config.roundsPerGame,
            cardsPerRoundRange: cardsRange,
            evaluationSeeds: evaluationSeeds,
            useFullMatchRules: config.useFullMatchRules,
            rotateCandidateAcrossSeats: config.rotateCandidateAcrossSeats,
            fitnessScoring: fitnessScoring
        )

        var population: [EvolutionGenome] = [.identity]
        while population.count < populationSize {
            let randomGenome = randomGenome(
                around: .identity,
                magnitude: max(config.mutationMagnitude, 0.08),
                using: &rng
            )
            population.append(randomGenome)
        }

        let runStartedAt = Date()
        let totalWorkUnits = 1 + config.generations * populationSize
        var completedWorkUnits = 0

        func notifyProgress(
            stage: SelfPlayEvolutionProgress.Stage,
            generationIndex: Int? = nil,
            evaluatedCandidatesInGeneration: Int? = nil,
            currentFitness: Double? = nil,
            generationBestFitness: Double? = nil,
            overallBestFitness: Double? = nil
        ) {
            guard let progress else { return }
            let elapsed = Date().timeIntervalSince(runStartedAt)
            let estimatedRemaining: Double?
            if completedWorkUnits > 0 {
                let averagePerUnit = elapsed / Double(completedWorkUnits)
                let unitsLeft = max(0, totalWorkUnits - completedWorkUnits)
                estimatedRemaining = averagePerUnit * Double(unitsLeft)
            } else {
                estimatedRemaining = nil
            }

            progress(
                SelfPlayEvolutionProgress(
                    stage: stage,
                    generationIndex: generationIndex,
                    totalGenerations: config.generations,
                    evaluatedCandidatesInGeneration: evaluatedCandidatesInGeneration,
                    populationSize: populationSize,
                    currentFitness: currentFitness,
                    generationBestFitness: generationBestFitness,
                    overallBestFitness: overallBestFitness,
                    completedWorkUnits: completedWorkUnits,
                    totalWorkUnits: totalWorkUnits,
                    elapsedSeconds: elapsed,
                    estimatedRemainingSeconds: estimatedRemaining
                )
            )
        }

        notifyProgress(stage: .started)

        let baselineBreakdown = evaluateGenome(
            .identity,
            baseTuning: baseTuning,
            context: baselineEvaluationContext
        )
        completedWorkUnits += 1
        notifyProgress(
            stage: .baselineCompleted,
            currentFitness: baselineBreakdown.fitness,
            generationBestFitness: baselineBreakdown.fitness,
            overallBestFitness: baselineBreakdown.fitness
        )

        var bestGenome = EvolutionGenome.identity
        var bestBreakdown = baselineBreakdown
        var generationBestFitness: [Double] = []
        generationBestFitness.reserveCapacity(config.generations)
        var completedGenerations = 0
        var stoppedEarly = false
        var lastMeaningfulImprovementGeneration = 0

        for generation in 0..<config.generations {
            notifyProgress(
                stage: .generationStarted,
                generationIndex: generation,
                overallBestFitness: bestBreakdown.fitness
            )
            let generationSeedMask = UInt64(generation + 1) &* 0x9E37_79B9_7F4A_7C15
            let generationSeeds = evaluationSeeds.map { $0 ^ generationSeedMask }
            let generationEvaluationContext = baselineEvaluationContext.withEvaluationSeeds(generationSeeds)

            var scoredPopulation: [ScoredGenome] = []
            scoredPopulation.reserveCapacity(populationSize)
            var generationBestFitnessSoFar: Double?

            for (candidateOffset, genome) in population.enumerated() {
                let breakdown = evaluateGenome(
                    genome,
                    baseTuning: baseTuning,
                    context: generationEvaluationContext
                )
                scoredPopulation.append(
                    ScoredGenome(
                        genome: genome,
                        breakdown: breakdown
                    )
                )

                completedWorkUnits += 1
                generationBestFitnessSoFar = max(generationBestFitnessSoFar ?? breakdown.fitness, breakdown.fitness)
                let overallBestSoFar = max(bestBreakdown.fitness, generationBestFitnessSoFar ?? breakdown.fitness)
                notifyProgress(
                    stage: .candidateEvaluated,
                    generationIndex: generation,
                    evaluatedCandidatesInGeneration: candidateOffset + 1,
                    currentFitness: breakdown.fitness,
                    generationBestFitness: generationBestFitnessSoFar,
                    overallBestFitness: overallBestSoFar
                )
            }

            scoredPopulation.sort(by: { (lhs: ScoredGenome, rhs: ScoredGenome) -> Bool in
                    if lhs.breakdown.fitness == rhs.breakdown.fitness {
                        return isLexicographicallySmaller(
                            lhs.genome.lexicographicKey,
                            than: rhs.genome.lexicographicKey
                        )
                    }
                    return lhs.breakdown.fitness > rhs.breakdown.fitness
                })

            guard let generationBest = scoredPopulation.first else { continue }
            generationBestFitness.append(generationBest.breakdown.fitness)
            completedGenerations = generation + 1

            let fitnessImprovement = generationBest.breakdown.fitness - bestBreakdown.fitness
            if generationBest.breakdown.fitness > bestBreakdown.fitness {
                bestBreakdown = generationBest.breakdown
                bestGenome = generationBest.genome
                if fitnessImprovement > config.earlyStoppingMinImprovement {
                    lastMeaningfulImprovementGeneration = completedGenerations
                }
            }
            notifyProgress(
                stage: .generationCompleted,
                generationIndex: generation,
                generationBestFitness: generationBest.breakdown.fitness,
                overallBestFitness: bestBreakdown.fitness
            )

            let shouldEarlyStop = config.earlyStoppingPatience > 0 &&
                completedGenerations >= config.earlyStoppingWarmupGenerations &&
                (completedGenerations - lastMeaningfulImprovementGeneration) >= config.earlyStoppingPatience
            if shouldEarlyStop {
                stoppedEarly = generation + 1 < config.generations
                break
            }

            guard generation + 1 < config.generations else { continue }

            var nextPopulation: [EvolutionGenome] = scoredPopulation
                .prefix(eliteCount)
                .map { $0.genome }

            while nextPopulation.count < populationSize {
                let firstParent = scoredPopulation[
                    Int.random(in: 0..<selectionPoolSize, using: &rng)
                ].genome
                let secondParent = scoredPopulation[
                    Int.random(in: 0..<selectionPoolSize, using: &rng)
                ].genome

                let crossoverChild = crossover(firstParent, secondParent, using: &rng)
                let mutatedChild = mutateGenome(
                    crossoverChild,
                    chance: config.mutationChance,
                    magnitude: config.mutationMagnitude,
                    using: &rng
                )
                nextPopulation.append(mutatedChild)
            }

            population = nextPopulation
        }

        let bestTuning = tuning(byApplying: bestGenome, to: baseTuning)
        notifyProgress(
            stage: .finished,
            overallBestFitness: bestBreakdown.fitness
        )
        return SelfPlayEvolutionResult(
            bestTuning: bestTuning,
            baselineFitness: baselineBreakdown.fitness,
            bestFitness: bestBreakdown.fitness,
            generationBestFitness: generationBestFitness,
            completedGenerations: completedGenerations,
            stoppedEarly: stoppedEarly,
            baselineWinRate: baselineBreakdown.winRate,
            bestWinRate: bestBreakdown.winRate,
            baselineAverageScoreDiff: baselineBreakdown.averageScoreDiff,
            bestAverageScoreDiff: bestBreakdown.averageScoreDiff,
            baselineAverageUnderbidLoss: baselineBreakdown.averageUnderbidLoss,
            bestAverageUnderbidLoss: bestBreakdown.averageUnderbidLoss,
            baselineAverageTrumpDensityUnderbidLoss: baselineBreakdown.averageTrumpDensityUnderbidLoss,
            bestAverageTrumpDensityUnderbidLoss: bestBreakdown.averageTrumpDensityUnderbidLoss,
            baselineAverageNoTrumpControlUnderbidLoss: baselineBreakdown.averageNoTrumpControlUnderbidLoss,
            bestAverageNoTrumpControlUnderbidLoss: bestBreakdown.averageNoTrumpControlUnderbidLoss,
            baselineAveragePremiumAssistLoss: baselineBreakdown.averagePremiumAssistLoss,
            bestAveragePremiumAssistLoss: bestBreakdown.averagePremiumAssistLoss,
            baselineAveragePremiumPenaltyTargetLoss: baselineBreakdown.averagePremiumPenaltyTargetLoss,
            bestAveragePremiumPenaltyTargetLoss: bestBreakdown.averagePremiumPenaltyTargetLoss,
            baselinePremiumCaptureRate: baselineBreakdown.premiumCaptureRate,
            bestPremiumCaptureRate: bestBreakdown.premiumCaptureRate,
            baselineBlindSuccessRate: baselineBreakdown.blindSuccessRate,
            bestBlindSuccessRate: bestBreakdown.blindSuccessRate,
            baselineJokerWishWinRate: baselineBreakdown.jokerWishWinRate,
            bestJokerWishWinRate: bestBreakdown.jokerWishWinRate,
            baselineEarlyJokerSpendRate: baselineBreakdown.earlyJokerSpendRate,
            bestEarlyJokerSpendRate: bestBreakdown.earlyJokerSpendRate,
            baselinePenaltyTargetRate: baselineBreakdown.penaltyTargetRate,
            bestPenaltyTargetRate: bestBreakdown.penaltyTargetRate,
            baselineBidAccuracyRate: baselineBreakdown.bidAccuracyRate,
            bestBidAccuracyRate: bestBreakdown.bidAccuracyRate,
            baselineOverbidRate: baselineBreakdown.overbidRate,
            bestOverbidRate: bestBreakdown.overbidRate,
            baselineBlindBidRateBlock4: baselineBreakdown.blindBidRateBlock4,
            bestBlindBidRateBlock4: bestBreakdown.blindBidRateBlock4,
            baselineAverageBlindBidSize: baselineBreakdown.averageBlindBidSize,
            bestAverageBlindBidSize: bestBreakdown.averageBlindBidSize,
            baselineBlindBidWhenBehindRate: baselineBreakdown.blindBidWhenBehindRate,
            bestBlindBidWhenBehindRate: bestBreakdown.blindBidWhenBehindRate,
            baselineBlindBidWhenLeadingRate: baselineBreakdown.blindBidWhenLeadingRate,
            bestBlindBidWhenLeadingRate: bestBreakdown.blindBidWhenLeadingRate,
            baselineEarlyLeadWishJokerRate: baselineBreakdown.earlyLeadWishJokerRate,
            bestEarlyLeadWishJokerRate: bestBreakdown.earlyLeadWishJokerRate,
            baselineLeftNeighborPremiumAssistRate: baselineBreakdown.leftNeighborPremiumAssistRate,
            bestLeftNeighborPremiumAssistRate: bestBreakdown.leftNeighborPremiumAssistRate
        )
    }

    private struct ScoredGenome {
        let genome: EvolutionGenome
        let breakdown: FitnessBreakdown
    }

    private struct FitnessBreakdown {
        let fitness: Double
        let winRate: Double
        let averageScoreDiff: Double
        let averageUnderbidLoss: Double
        let averageTrumpDensityUnderbidLoss: Double
        let averageNoTrumpControlUnderbidLoss: Double
        let averagePremiumAssistLoss: Double
        let averagePremiumPenaltyTargetLoss: Double
        let premiumCaptureRate: Double
        let blindSuccessRate: Double
        let jokerWishWinRate: Double
        let earlyJokerSpendRate: Double
        let penaltyTargetRate: Double
        let bidAccuracyRate: Double
        let overbidRate: Double
        let blindBidRateBlock4: Double
        let averageBlindBidSize: Double
        let blindBidWhenBehindRate: Double
        let blindBidWhenLeadingRate: Double
        let earlyLeadWishJokerRate: Double
        let leftNeighborPremiumAssistRate: Double

        static let zero = FitnessBreakdown(
            fitness: 0.0,
            winRate: 0.0,
            averageScoreDiff: 0.0,
            averageUnderbidLoss: 0.0,
            averageTrumpDensityUnderbidLoss: 0.0,
            averageNoTrumpControlUnderbidLoss: 0.0,
            averagePremiumAssistLoss: 0.0,
            averagePremiumPenaltyTargetLoss: 0.0,
            premiumCaptureRate: 0.0,
            blindSuccessRate: 0.0,
            jokerWishWinRate: 0.0,
            earlyJokerSpendRate: 0.0,
            penaltyTargetRate: 0.0,
            bidAccuracyRate: 0.0,
            overbidRate: 0.0,
            blindBidRateBlock4: 0.0,
            averageBlindBidSize: 0.0,
            blindBidWhenBehindRate: 0.0,
            blindBidWhenLeadingRate: 0.0,
            earlyLeadWishJokerRate: 0.0,
            leftNeighborPremiumAssistRate: 0.0
        )
    }

    private struct FitnessScoringConfig {
        let winRateWeight: Double
        let scoreDiffWeight: Double
        let underbidLossWeight: Double
        let trumpDensityUnderbidWeight: Double
        let noTrumpControlUnderbidWeight: Double
        let premiumAssistWeight: Double
        let premiumPenaltyTargetWeight: Double
        let scoreDiffNormalization: Double
        let underbidLossNormalization: Double
        let trumpDensityUnderbidNormalization: Double
        let noTrumpControlUnderbidNormalization: Double
        let premiumAssistNormalization: Double
        let premiumPenaltyTargetNormalization: Double

        init(config: SelfPlayEvolutionConfig) {
            self.winRateWeight = config.fitnessWinRateWeight
            self.scoreDiffWeight = config.fitnessScoreDiffWeight
            self.underbidLossWeight = config.fitnessUnderbidLossWeight
            self.trumpDensityUnderbidWeight = config.fitnessTrumpDensityUnderbidWeight
            self.noTrumpControlUnderbidWeight = config.fitnessNoTrumpControlUnderbidWeight
            self.premiumAssistWeight = config.fitnessPremiumAssistWeight
            self.premiumPenaltyTargetWeight = config.fitnessPremiumPenaltyTargetWeight
            self.scoreDiffNormalization = config.scoreDiffNormalization
            self.underbidLossNormalization = config.underbidLossNormalization
            self.trumpDensityUnderbidNormalization = config.trumpDensityUnderbidNormalization
            self.noTrumpControlUnderbidNormalization = config.noTrumpControlUnderbidNormalization
            self.premiumAssistNormalization = config.premiumAssistNormalization
            self.premiumPenaltyTargetNormalization = config.premiumPenaltyTargetNormalization
        }

        func fitness(
            winRate: Double,
            averageScoreDiff: Double,
            averageUnderbidLoss: Double,
            averageTrumpDensityUnderbidLoss: Double,
            averageNoTrumpControlUnderbidLoss: Double,
            averagePremiumAssistLoss: Double,
            averagePremiumPenaltyTargetLoss: Double
        ) -> Double {
            return winRate * winRateWeight +
                (averageScoreDiff / scoreDiffNormalization) * scoreDiffWeight +
                -(averageUnderbidLoss / underbidLossNormalization) * underbidLossWeight +
                -(averageTrumpDensityUnderbidLoss / trumpDensityUnderbidNormalization) * trumpDensityUnderbidWeight +
                -(averageNoTrumpControlUnderbidLoss / noTrumpControlUnderbidNormalization) * noTrumpControlUnderbidWeight +
                -(averagePremiumAssistLoss / premiumAssistNormalization) * premiumAssistWeight +
                -(averagePremiumPenaltyTargetLoss / premiumPenaltyTargetNormalization) * premiumPenaltyTargetWeight
        }
    }

    private struct FitnessEvaluationContext {
        let playerCount: Int
        let roundsPerGame: Int
        let cardsPerRoundRange: ClosedRange<Int>
        let evaluationSeeds: [UInt64]
        let useFullMatchRules: Bool
        let rotateCandidateAcrossSeats: Bool
        let fitnessScoring: FitnessScoringConfig

        func withEvaluationSeeds(_ evaluationSeeds: [UInt64]) -> FitnessEvaluationContext {
            return FitnessEvaluationContext(
                playerCount: playerCount,
                roundsPerGame: roundsPerGame,
                cardsPerRoundRange: cardsPerRoundRange,
                evaluationSeeds: evaluationSeeds,
                useFullMatchRules: useFullMatchRules,
                rotateCandidateAcrossSeats: rotateCandidateAcrossSeats,
                fitnessScoring: fitnessScoring
            )
        }
    }

    private struct CandidateSeatMetrics {
        let winShare: Double
        let scoreDiff: Double
        let underbidLoss: Double
        let trumpDensityUnderbidLoss: Double
        let noTrumpControlUnderbidLoss: Double
        let premiumAssistLoss: Double
        let premiumPenaltyTargetLoss: Double
        let premiumCaptureRate: Double
        let blindSuccessRate: Double
        let jokerWishWinRate: Double
        let earlyJokerSpendRate: Double
        let penaltyTargetRate: Double
        let bidAccuracyRate: Double
        let overbidRate: Double
        let blindBidRateBlock4: Double
        let averageBlindBidSize: Double
        let blindBidWhenBehindRate: Double
        let blindBidWhenLeadingRate: Double
        let earlyLeadWishJokerRate: Double
        let leftNeighborPremiumAssistRate: Double
    }

    private struct FitnessAccumulator {
        private var totalWinRate = 0.0
        private var totalScoreDiff = 0.0
        private var totalUnderbidLoss = 0.0
        private var totalTrumpDensityUnderbidLoss = 0.0
        private var totalNoTrumpControlUnderbidLoss = 0.0
        private var totalPremiumAssistLoss = 0.0
        private var totalPremiumPenaltyTargetLoss = 0.0
        private var totalPremiumCaptureRate = 0.0
        private var totalBlindSuccessRate = 0.0
        private var totalJokerWishWinRate = 0.0
        private var totalEarlyJokerSpendRate = 0.0
        private var totalPenaltyTargetRate = 0.0
        private var totalBidAccuracyRate = 0.0
        private var totalOverbidRate = 0.0
        private var totalBlindBidRateBlock4 = 0.0
        private var totalAverageBlindBidSize = 0.0
        private var totalBlindBidWhenBehindRate = 0.0
        private var totalBlindBidWhenLeadingRate = 0.0
        private var totalEarlyLeadWishJokerRate = 0.0
        private var totalLeftNeighborPremiumAssistRate = 0.0
        private var samplesCount = 0

        mutating func append(_ metrics: CandidateSeatMetrics) {
            totalWinRate += metrics.winShare
            totalScoreDiff += metrics.scoreDiff
            totalUnderbidLoss += metrics.underbidLoss
            totalTrumpDensityUnderbidLoss += metrics.trumpDensityUnderbidLoss
            totalNoTrumpControlUnderbidLoss += metrics.noTrumpControlUnderbidLoss
            totalPremiumAssistLoss += metrics.premiumAssistLoss
            totalPremiumPenaltyTargetLoss += metrics.premiumPenaltyTargetLoss
            totalPremiumCaptureRate += metrics.premiumCaptureRate
            totalBlindSuccessRate += metrics.blindSuccessRate
            totalJokerWishWinRate += metrics.jokerWishWinRate
            totalEarlyJokerSpendRate += metrics.earlyJokerSpendRate
            totalPenaltyTargetRate += metrics.penaltyTargetRate
            totalBidAccuracyRate += metrics.bidAccuracyRate
            totalOverbidRate += metrics.overbidRate
            totalBlindBidRateBlock4 += metrics.blindBidRateBlock4
            totalAverageBlindBidSize += metrics.averageBlindBidSize
            totalBlindBidWhenBehindRate += metrics.blindBidWhenBehindRate
            totalBlindBidWhenLeadingRate += metrics.blindBidWhenLeadingRate
            totalEarlyLeadWishJokerRate += metrics.earlyLeadWishJokerRate
            totalLeftNeighborPremiumAssistRate += metrics.leftNeighborPremiumAssistRate
            samplesCount += 1
        }

        func makeBreakdown(fitnessScoring: FitnessScoringConfig) -> FitnessBreakdown {
            guard samplesCount > 0 else { return .zero }

            let denominator = Double(samplesCount)
            let averageWinRate = totalWinRate / denominator
            let averageScoreDiff = totalScoreDiff / denominator
            let averageUnderbidLoss = totalUnderbidLoss / denominator
            let averageTrumpDensityUnderbidLoss = totalTrumpDensityUnderbidLoss / denominator
            let averageNoTrumpControlUnderbidLoss = totalNoTrumpControlUnderbidLoss / denominator
            let averagePremiumAssistLoss = totalPremiumAssistLoss / denominator
            let averagePremiumPenaltyTargetLoss = totalPremiumPenaltyTargetLoss / denominator
            let premiumCaptureRate = totalPremiumCaptureRate / denominator
            let blindSuccessRate = totalBlindSuccessRate / denominator
            let jokerWishWinRate = totalJokerWishWinRate / denominator
            let earlyJokerSpendRate = totalEarlyJokerSpendRate / denominator
            let penaltyTargetRate = totalPenaltyTargetRate / denominator
            let bidAccuracyRate = totalBidAccuracyRate / denominator
            let overbidRate = totalOverbidRate / denominator
            let blindBidRateBlock4 = totalBlindBidRateBlock4 / denominator
            let averageBlindBidSize = totalAverageBlindBidSize / denominator
            let blindBidWhenBehindRate = totalBlindBidWhenBehindRate / denominator
            let blindBidWhenLeadingRate = totalBlindBidWhenLeadingRate / denominator
            let earlyLeadWishJokerRate = totalEarlyLeadWishJokerRate / denominator
            let leftNeighborPremiumAssistRate = totalLeftNeighborPremiumAssistRate / denominator
            let fitness = fitnessScoring.fitness(
                winRate: averageWinRate,
                averageScoreDiff: averageScoreDiff,
                averageUnderbidLoss: averageUnderbidLoss,
                averageTrumpDensityUnderbidLoss: averageTrumpDensityUnderbidLoss,
                averageNoTrumpControlUnderbidLoss: averageNoTrumpControlUnderbidLoss,
                averagePremiumAssistLoss: averagePremiumAssistLoss,
                averagePremiumPenaltyTargetLoss: averagePremiumPenaltyTargetLoss
            )

            return FitnessBreakdown(
                fitness: fitness,
                winRate: averageWinRate,
                averageScoreDiff: averageScoreDiff,
                averageUnderbidLoss: averageUnderbidLoss,
                averageTrumpDensityUnderbidLoss: averageTrumpDensityUnderbidLoss,
                averageNoTrumpControlUnderbidLoss: averageNoTrumpControlUnderbidLoss,
                averagePremiumAssistLoss: averagePremiumAssistLoss,
                averagePremiumPenaltyTargetLoss: averagePremiumPenaltyTargetLoss,
                premiumCaptureRate: premiumCaptureRate,
                blindSuccessRate: blindSuccessRate,
                jokerWishWinRate: jokerWishWinRate,
                earlyJokerSpendRate: earlyJokerSpendRate,
                penaltyTargetRate: penaltyTargetRate,
                bidAccuracyRate: bidAccuracyRate,
                overbidRate: overbidRate,
                blindBidRateBlock4: blindBidRateBlock4,
                averageBlindBidSize: averageBlindBidSize,
                blindBidWhenBehindRate: blindBidWhenBehindRate,
                blindBidWhenLeadingRate: blindBidWhenLeadingRate,
                earlyLeadWishJokerRate: earlyLeadWishJokerRate,
                leftNeighborPremiumAssistRate: leftNeighborPremiumAssistRate
            )
        }
    }

    private static func normalizedCardsPerRoundRange(
        from range: ClosedRange<Int>,
        playerCount: Int
    ) -> ClosedRange<Int> {
        let deckLimit = max(1, Deck().cards.count / max(1, playerCount))
        let lowerCards = min(max(1, range.lowerBound), deckLimit)
        let upperCards = min(max(lowerCards, range.upperBound), deckLimit)
        return lowerCards...upperCards
    }

    private static func makeEvaluationSeeds(
        count: Int,
        using rng: inout SelfPlayRandomGenerator
    ) -> [UInt64] {
        var seeds: [UInt64] = []
        seeds.reserveCapacity(max(0, count))
        for _ in 0..<max(0, count) {
            seeds.append(rng.next())
        }
        return seeds
    }

    private static func candidateSeatIndices(
        playerCount: Int,
        rotateCandidateAcrossSeats: Bool
    ) -> [Int] {
        guard playerCount > 0 else { return [] }
        if rotateCandidateAcrossSeats {
            return Array(0..<playerCount)
        }
        return [0]
    }

    private static func doubleMetricValue(
        _ values: [Double],
        at index: Int
    ) -> Double {
        guard values.indices.contains(index) else { return 0.0 }
        return values[index]
    }

    private static func ratio(_ numerator: Double, _ denominator: Double) -> Double {
        guard denominator > 0 else { return 0.0 }
        return numerator / denominator
    }

    private static func candidateSeatMetrics(
        from gameOutcome: SimulatedGameOutcome,
        candidateSeat: Int,
        playerCount: Int
    ) -> CandidateSeatMetrics? {
        let totalScores = gameOutcome.totalScores
        guard totalScores.indices.contains(candidateSeat) else { return nil }

        let candidateScore = totalScores[candidateSeat]
        let opponentsTotal = totalScores.reduce(0, +) - candidateScore
        let opponentsAverage = Double(opponentsTotal) / Double(max(1, playerCount - 1))
        let maxScore = totalScores.max() ?? candidateScore
        let winnersCount = max(1, totalScores.filter { $0 == maxScore }.count)
        let winShare = candidateScore == maxScore ? 1.0 / Double(winnersCount) : 0.0

        return CandidateSeatMetrics(
            winShare: winShare,
            scoreDiff: Double(candidateScore) - opponentsAverage,
            underbidLoss: doubleMetricValue(gameOutcome.underbidLosses, at: candidateSeat),
            trumpDensityUnderbidLoss: doubleMetricValue(
                gameOutcome.trumpDensityUnderbidLosses,
                at: candidateSeat
            ),
            noTrumpControlUnderbidLoss: doubleMetricValue(
                gameOutcome.noTrumpControlUnderbidLosses,
                at: candidateSeat
            ),
            premiumAssistLoss: doubleMetricValue(gameOutcome.premiumAssistLosses, at: candidateSeat),
            premiumPenaltyTargetLoss: doubleMetricValue(
                gameOutcome.premiumPenaltyTargetLosses,
                at: candidateSeat
            ),
            premiumCaptureRate: doubleMetricValue(gameOutcome.premiumCaptureRates, at: candidateSeat),
            blindSuccessRate: doubleMetricValue(gameOutcome.blindSuccessRates, at: candidateSeat),
            jokerWishWinRate: doubleMetricValue(gameOutcome.jokerWishWinRates, at: candidateSeat),
            earlyJokerSpendRate: doubleMetricValue(gameOutcome.earlyJokerSpendRates, at: candidateSeat),
            penaltyTargetRate: doubleMetricValue(gameOutcome.penaltyTargetRates, at: candidateSeat),
            bidAccuracyRate: doubleMetricValue(gameOutcome.bidAccuracyRates, at: candidateSeat),
            overbidRate: doubleMetricValue(gameOutcome.overbidRates, at: candidateSeat),
            blindBidRateBlock4: doubleMetricValue(gameOutcome.blindBidRatesBlock4, at: candidateSeat),
            averageBlindBidSize: doubleMetricValue(gameOutcome.averageBlindBidSizes, at: candidateSeat),
            blindBidWhenBehindRate: doubleMetricValue(gameOutcome.blindBidWhenBehindRates, at: candidateSeat),
            blindBidWhenLeadingRate: doubleMetricValue(gameOutcome.blindBidWhenLeadingRates, at: candidateSeat),
            earlyLeadWishJokerRate: doubleMetricValue(gameOutcome.earlyLeadWishJokerRates, at: candidateSeat),
            leftNeighborPremiumAssistRate: doubleMetricValue(
                gameOutcome.leftNeighborPremiumAssistRates,
                at: candidateSeat
            )
        )
    }

    private static func evaluateCandidateTuning(
        candidateTuning: BotTuning,
        opponentTuning: BotTuning,
        context: FitnessEvaluationContext
    ) -> FitnessBreakdown {
        guard !context.evaluationSeeds.isEmpty else { return .zero }

        let candidateSeats = candidateSeatIndices(
            playerCount: context.playerCount,
            rotateCandidateAcrossSeats: context.rotateCandidateAcrossSeats
        )
        var accumulator = FitnessAccumulator()

        for evaluationSeed in context.evaluationSeeds {
            for candidateSeat in candidateSeats {
                var tuningsBySeat = Array(repeating: opponentTuning, count: context.playerCount)
                tuningsBySeat[candidateSeat] = candidateTuning

                let gameOutcome = simulateGame(
                    tuningsBySeat: tuningsBySeat,
                    rounds: context.roundsPerGame,
                    cardsPerRoundRange: context.cardsPerRoundRange,
                    seed: evaluationSeed,
                    useFullMatchRules: context.useFullMatchRules
                )

                guard let metrics = candidateSeatMetrics(
                    from: gameOutcome,
                    candidateSeat: candidateSeat,
                    playerCount: context.playerCount
                ) else {
                    continue
                }
                accumulator.append(metrics)
            }
        }

        return accumulator.makeBreakdown(fitnessScoring: context.fitnessScoring)
    }

    private static func headToHeadValidationResult(
        from breakdown: FitnessBreakdown
    ) -> SelfPlayHeadToHeadValidationResult {
        return SelfPlayHeadToHeadValidationResult(
            fitness: breakdown.fitness,
            winRate: breakdown.winRate,
            averageScoreDiff: breakdown.averageScoreDiff,
            averageUnderbidLoss: breakdown.averageUnderbidLoss,
            averageTrumpDensityUnderbidLoss: breakdown.averageTrumpDensityUnderbidLoss,
            averageNoTrumpControlUnderbidLoss: breakdown.averageNoTrumpControlUnderbidLoss,
            averagePremiumAssistLoss: breakdown.averagePremiumAssistLoss,
            averagePremiumPenaltyTargetLoss: breakdown.averagePremiumPenaltyTargetLoss,
            premiumCaptureRate: breakdown.premiumCaptureRate,
            blindSuccessRate: breakdown.blindSuccessRate,
            jokerWishWinRate: breakdown.jokerWishWinRate,
            earlyJokerSpendRate: breakdown.earlyJokerSpendRate,
            penaltyTargetRate: breakdown.penaltyTargetRate,
            bidAccuracyRate: breakdown.bidAccuracyRate,
            overbidRate: breakdown.overbidRate,
            blindBidRateBlock4: breakdown.blindBidRateBlock4,
            averageBlindBidSize: breakdown.averageBlindBidSize,
            blindBidWhenBehindRate: breakdown.blindBidWhenBehindRate,
            blindBidWhenLeadingRate: breakdown.blindBidWhenLeadingRate,
            earlyLeadWishJokerRate: breakdown.earlyLeadWishJokerRate,
            leftNeighborPremiumAssistRate: breakdown.leftNeighborPremiumAssistRate
        )
    }

    private struct EvolutionGenome {
        var chaseWinProbabilityScale: Double
        var chaseThreatPenaltyScale: Double
        var chaseSpendJokerPenaltyScale: Double
        var dumpAvoidWinScale: Double
        var dumpThreatRewardScale: Double
        var dumpSpendJokerPenaltyScale: Double
        var holdDistributionScale: Double
        var futureTricksScale: Double
        var futureJokerPowerScale: Double
        var threatPreservationScale: Double

        var biddingJokerPowerScale: Double
        var biddingRankWeightScale: Double
        var biddingTrumpBaseBonusScale: Double
        var biddingTrumpRankWeightScale: Double
        var biddingHighRankBonusScale: Double
        var biddingLongSuitBonusScale: Double
        var biddingTrumpDensityBonusScale: Double
        var biddingNoTrumpHighCardBonusScale: Double
        var biddingNoTrumpJokerSynergyScale: Double
        var blindDesperateBehindThresholdScale: Double
        var blindCatchUpBehindThresholdScale: Double
        var blindSafeLeadThresholdScale: Double
        var blindDesperateTargetShareScale: Double
        var blindCatchUpTargetShareScale: Double
        var blindCatchUpConservativeTargetShareScale: Double

        var trumpCardBasePowerScale: Double
        var trumpThresholdScale: Double

        static let identity = EvolutionGenome(
            chaseWinProbabilityScale: 1.0,
            chaseThreatPenaltyScale: 1.0,
            chaseSpendJokerPenaltyScale: 1.0,
            dumpAvoidWinScale: 1.0,
            dumpThreatRewardScale: 1.0,
            dumpSpendJokerPenaltyScale: 1.0,
            holdDistributionScale: 1.0,
            futureTricksScale: 1.0,
            futureJokerPowerScale: 1.0,
            threatPreservationScale: 1.0,
            biddingJokerPowerScale: 1.0,
            biddingRankWeightScale: 1.0,
            biddingTrumpBaseBonusScale: 1.0,
            biddingTrumpRankWeightScale: 1.0,
            biddingHighRankBonusScale: 1.0,
            biddingLongSuitBonusScale: 1.0,
            biddingTrumpDensityBonusScale: 1.0,
            biddingNoTrumpHighCardBonusScale: 1.0,
            biddingNoTrumpJokerSynergyScale: 1.0,
            blindDesperateBehindThresholdScale: 1.0,
            blindCatchUpBehindThresholdScale: 1.0,
            blindSafeLeadThresholdScale: 1.0,
            blindDesperateTargetShareScale: 1.0,
            blindCatchUpTargetShareScale: 1.0,
            blindCatchUpConservativeTargetShareScale: 1.0,
            trumpCardBasePowerScale: 1.0,
            trumpThresholdScale: 1.0
        )

        var lexicographicKey: [Double] {
            return [
                chaseWinProbabilityScale,
                chaseThreatPenaltyScale,
                chaseSpendJokerPenaltyScale,
                dumpAvoidWinScale,
                dumpThreatRewardScale,
                dumpSpendJokerPenaltyScale,
                holdDistributionScale,
                futureTricksScale,
                futureJokerPowerScale,
                threatPreservationScale,
                biddingJokerPowerScale,
                biddingRankWeightScale,
                biddingTrumpBaseBonusScale,
                biddingTrumpRankWeightScale,
                biddingHighRankBonusScale,
                biddingLongSuitBonusScale,
                biddingTrumpDensityBonusScale,
                biddingNoTrumpHighCardBonusScale,
                biddingNoTrumpJokerSynergyScale,
                blindDesperateBehindThresholdScale,
                blindCatchUpBehindThresholdScale,
                blindSafeLeadThresholdScale,
                blindDesperateTargetShareScale,
                blindCatchUpTargetShareScale,
                blindCatchUpConservativeTargetShareScale,
                trumpCardBasePowerScale,
                trumpThresholdScale
            ]
        }
    }

    private struct SelfPlayRandomGenerator: RandomNumberGenerator {
        private var state: UInt64

        init(seed: UInt64) {
            state = seed == 0 ? 0xA409_3822_299F_31D0 : seed
        }

        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15

            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }

        mutating func nextUnit() -> Double {
            let bits = next() >> 11
            let max53 = Double(1 << 53)
            return Double(bits) / max53
        }
    }

    private struct PreDealBlindContext {
        let lockedBids: [Int]
        let blindSelections: [Bool]
        let eligibleWhenBehind: [Bool]
        let chosenWhenBehind: [Bool]
        let eligibleWhenLeading: [Bool]
        let chosenWhenLeading: [Bool]
    }

    private struct SimulatedGameOutcome {
        let totalScores: [Int]
        let underbidLosses: [Double]
        let trumpDensityUnderbidLosses: [Double]
        let noTrumpControlUnderbidLosses: [Double]
        let premiumAssistLosses: [Double]
        let premiumPenaltyTargetLosses: [Double]
        let premiumCaptureRates: [Double]
        let blindSuccessRates: [Double]
        let jokerWishWinRates: [Double]
        let earlyJokerSpendRates: [Double]
        let penaltyTargetRates: [Double]
        let bidAccuracyRates: [Double]
        let overbidRates: [Double]
        let blindBidRatesBlock4: [Double]
        let averageBlindBidSizes: [Double]
        let blindBidWhenBehindRates: [Double]
        let blindBidWhenLeadingRates: [Double]
        let earlyLeadWishJokerRates: [Double]
        let leftNeighborPremiumAssistRates: [Double]
    }

    private struct SeatServiceBundle {
        let turnServices: [BotTurnStrategyService]
        let biddingServices: [BotBiddingService]
        let trumpServices: [BotTrumpSelectionService]
    }

    private struct SimulationMetricsAccumulator {
        private(set) var totalScores: [Int]
        private(set) var underbidLosses: [Double]
        private(set) var trumpDensityUnderbidLosses: [Double]
        private(set) var noTrumpControlUnderbidLosses: [Double]
        private(set) var premiumAssistLosses: [Double]
        private(set) var premiumPenaltyTargetLosses: [Double]
        private var totalRoundsCount: [Int]
        private var exactBidRoundsCount: [Int]
        private var overbidRoundsCount: [Int]
        private var totalBlindRoundsCount: [Int]
        private var successfulBlindRoundsCount: [Int]
        private var totalBlocksCount: [Int]
        private var premiumCapturedBlocksCount: [Int]
        private var penaltyTargetBlocksCount: [Int]
        private var totalWishLeadDeclarationCounts: [Int]
        private var winningWishLeadDeclarationCounts: [Int]
        private var totalJokerPlayCounts: [Int]
        private var earlyJokerPlayCounts: [Int]
        private var totalEarlyLeadWishCounts: [Int]
        private var totalDealsBlock4Count: [Int]
        private var blindDealsBlock4Count: [Int]
        private var totalBlindBidAmount: [Int]
        private var blindOpportunitiesWhenBehindCount: [Int]
        private var blindChosenWhenBehindCount: [Int]
        private var blindOpportunitiesWhenLeadingCount: [Int]
        private var blindChosenWhenLeadingCount: [Int]
        private var leftNeighborPremiumEventsCount: [Int]
        private var assistedLeftNeighborPremiumCount: [Int]

        init(playerCount: Int) {
            self.totalScores = Array(repeating: 0, count: playerCount)
            self.underbidLosses = Array(repeating: 0.0, count: playerCount)
            self.trumpDensityUnderbidLosses = Array(repeating: 0.0, count: playerCount)
            self.noTrumpControlUnderbidLosses = Array(repeating: 0.0, count: playerCount)
            self.premiumAssistLosses = Array(repeating: 0.0, count: playerCount)
            self.premiumPenaltyTargetLosses = Array(repeating: 0.0, count: playerCount)
            self.totalRoundsCount = Array(repeating: 0, count: playerCount)
            self.exactBidRoundsCount = Array(repeating: 0, count: playerCount)
            self.overbidRoundsCount = Array(repeating: 0, count: playerCount)
            self.totalBlindRoundsCount = Array(repeating: 0, count: playerCount)
            self.successfulBlindRoundsCount = Array(repeating: 0, count: playerCount)
            self.totalBlocksCount = Array(repeating: 0, count: playerCount)
            self.premiumCapturedBlocksCount = Array(repeating: 0, count: playerCount)
            self.penaltyTargetBlocksCount = Array(repeating: 0, count: playerCount)
            self.totalWishLeadDeclarationCounts = Array(repeating: 0, count: playerCount)
            self.winningWishLeadDeclarationCounts = Array(repeating: 0, count: playerCount)
            self.totalJokerPlayCounts = Array(repeating: 0, count: playerCount)
            self.earlyJokerPlayCounts = Array(repeating: 0, count: playerCount)
            self.totalEarlyLeadWishCounts = Array(repeating: 0, count: playerCount)
            self.totalDealsBlock4Count = Array(repeating: 0, count: playerCount)
            self.blindDealsBlock4Count = Array(repeating: 0, count: playerCount)
            self.totalBlindBidAmount = Array(repeating: 0, count: playerCount)
            self.blindOpportunitiesWhenBehindCount = Array(repeating: 0, count: playerCount)
            self.blindChosenWhenBehindCount = Array(repeating: 0, count: playerCount)
            self.blindOpportunitiesWhenLeadingCount = Array(repeating: 0, count: playerCount)
            self.blindChosenWhenLeadingCount = Array(repeating: 0, count: playerCount)
            self.leftNeighborPremiumEventsCount = Array(repeating: 0, count: playerCount)
            self.assistedLeftNeighborPremiumCount = Array(repeating: 0, count: playerCount)
        }

        mutating func evaluateRound(
            hands: [[Card]],
            biddingOutcome: BiddingRoundOutcome,
            playOutcome: RoundPlayOutcome,
            cardsInRound: Int,
            trump: Suit?,
            blindSelections: [Bool]?,
            noTrumpControlEmphasisMultiplier: Double
        ) -> [RoundResult] {
            let playerCount = hands.count
            var roundResults: [RoundResult] = []
            roundResults.reserveCapacity(playerCount)

            for playerIndex in 0..<playerCount {
                let isBlind: Bool
                if let blindSelections, blindSelections.indices.contains(playerIndex) {
                    isBlind = blindSelections[playerIndex]
                } else {
                    isBlind = false
                }

                let roundResult = RoundResult(
                    cardsInRound: cardsInRound,
                    bid: biddingOutcome.bids[playerIndex],
                    tricksTaken: playOutcome.tricksTaken[playerIndex],
                    isBlind: isBlind
                )
                roundResults.append(roundResult)

                totalRoundsCount[playerIndex] += 1
                if roundResult.bidMatched {
                    exactBidRoundsCount[playerIndex] += 1
                } else if roundResult.tricksTaken > roundResult.bid {
                    overbidRoundsCount[playerIndex] += 1
                }
                if isBlind {
                    totalBlindRoundsCount[playerIndex] += 1
                    totalBlindBidAmount[playerIndex] += roundResult.bid
                    if roundResult.bidMatched {
                        successfulBlindRoundsCount[playerIndex] += 1
                    }
                }
                if playOutcome.totalWishLeadDeclarationCounts.indices.contains(playerIndex) {
                    totalWishLeadDeclarationCounts[playerIndex] += playOutcome.totalWishLeadDeclarationCounts[playerIndex]
                }
                if playOutcome.winningWishLeadDeclarationCounts.indices.contains(playerIndex) {
                    winningWishLeadDeclarationCounts[playerIndex] += playOutcome.winningWishLeadDeclarationCounts[playerIndex]
                }
                if playOutcome.totalJokerPlayCounts.indices.contains(playerIndex) {
                    totalJokerPlayCounts[playerIndex] += playOutcome.totalJokerPlayCounts[playerIndex]
                }
                if playOutcome.earlyJokerPlayCounts.indices.contains(playerIndex) {
                    earlyJokerPlayCounts[playerIndex] += playOutcome.earlyJokerPlayCounts[playerIndex]
                }
                if playOutcome.nonFinalLeadWishCounts.indices.contains(playerIndex) {
                    totalEarlyLeadWishCounts[playerIndex] += playOutcome.nonFinalLeadWishCounts[playerIndex]
                }

                underbidLosses[playerIndex] += BotSelfPlayEvolutionEngine.underbidLoss(
                    cardsInRound: cardsInRound,
                    bid: biddingOutcome.bids[playerIndex],
                    tricksTaken: playOutcome.tricksTaken[playerIndex],
                    isBlind: isBlind
                )
                underbidLosses[playerIndex] += BotSelfPlayEvolutionEngine.jokerBidFloorUnderbidPenalty(
                    hand: hands[playerIndex],
                    bid: biddingOutcome.bids[playerIndex],
                    maxAllowedBid: biddingOutcome.maxAllowedBids[playerIndex]
                )
                underbidLosses[playerIndex] += BotSelfPlayEvolutionEngine.jokerAllInEdgeMaxBidPenalty(
                    hand: hands[playerIndex],
                    bid: biddingOutcome.bids[playerIndex],
                    cardsInRound: cardsInRound,
                    maxAllowedBid: biddingOutcome.maxAllowedBids[playerIndex]
                )
                underbidLosses[playerIndex] += BotSelfPlayEvolutionEngine.nonFinalLeadWishWithoutAbovePenalty(
                    nonFinalLeadWishCount: playOutcome.nonFinalLeadWishCounts[playerIndex],
                    cardsInRound: cardsInRound
                )
                trumpDensityUnderbidLosses[playerIndex] += BotSelfPlayEvolutionEngine.trumpDensityUnderbidPenalty(
                    hand: hands[playerIndex],
                    bid: biddingOutcome.bids[playerIndex],
                    cardsInRound: cardsInRound,
                    trump: trump
                )
                noTrumpControlUnderbidLosses[playerIndex] += BotSelfPlayEvolutionEngine.noTrumpControlUnderbidPenalty(
                    hand: hands[playerIndex],
                    bid: biddingOutcome.bids[playerIndex],
                    cardsInRound: cardsInRound,
                    trump: trump,
                    emphasisMultiplier: noTrumpControlEmphasisMultiplier
                )
            }

            return roundResults
        }

        mutating func addRoundScores(_ roundResults: [RoundResult]) {
            for (playerIndex, roundResult) in roundResults.enumerated() {
                guard totalScores.indices.contains(playerIndex) else { continue }
                totalScores[playerIndex] += roundResult.score
            }
        }

        mutating func addFinalScores(_ finalScores: [Int]) {
            for (playerIndex, score) in finalScores.enumerated() {
                guard totalScores.indices.contains(playerIndex) else { continue }
                totalScores[playerIndex] += score
            }
        }

        mutating func recordBlock4BlindExposure(
            blindSelections: [Bool]
        ) {
            let playerCount = min(blindSelections.count, totalDealsBlock4Count.count)
            for playerIndex in 0..<playerCount {
                totalDealsBlock4Count[playerIndex] += 1
                if blindSelections[playerIndex] {
                    blindDealsBlock4Count[playerIndex] += 1
                }
            }
        }

        mutating func recordBlindChoiceContext(
            eligibleWhenBehind: [Bool],
            chosenWhenBehind: [Bool],
            eligibleWhenLeading: [Bool],
            chosenWhenLeading: [Bool]
        ) {
            let counts = [
                eligibleWhenBehind.count,
                chosenWhenBehind.count,
                eligibleWhenLeading.count,
                chosenWhenLeading.count,
                blindOpportunitiesWhenBehindCount.count
            ]
            let playerCount = counts.min() ?? 0
            guard playerCount > 0 else { return }

            for playerIndex in 0..<playerCount {
                if eligibleWhenBehind[playerIndex] {
                    blindOpportunitiesWhenBehindCount[playerIndex] += 1
                }
                if chosenWhenBehind[playerIndex] {
                    blindChosenWhenBehindCount[playerIndex] += 1
                }
                if eligibleWhenLeading[playerIndex] {
                    blindOpportunitiesWhenLeadingCount[playerIndex] += 1
                }
                if chosenWhenLeading[playerIndex] {
                    blindChosenWhenLeadingCount[playerIndex] += 1
                }
            }
        }

        mutating func accumulatePremiumSupportLosses(
            blockOutcome: PremiumRules.BlockFinalizationOutcome,
            playerCount: Int
        ) {
            let boundedPlayerCount = min(playerCount, totalBlocksCount.count)
            let premiumPlayersSet = Set(blockOutcome.allPremiumPlayers)
            for playerIndex in 0..<boundedPlayerCount {
                totalBlocksCount[playerIndex] += 1
                if premiumPlayersSet.contains(playerIndex) {
                    premiumCapturedBlocksCount[playerIndex] += 1
                }
                let penalty = blockOutcome.premiumPenalties.indices.contains(playerIndex)
                    ? blockOutcome.premiumPenalties[playerIndex]
                    : 0
                if penalty > 0 {
                    penaltyTargetBlocksCount[playerIndex] += 1
                }

                let leftNeighbor = PremiumRules.leftNeighbor(of: playerIndex, playerCount: boundedPlayerCount)
                if premiumPlayersSet.contains(leftNeighbor) {
                    leftNeighborPremiumEventsCount[playerIndex] += 1
                    if !premiumPlayersSet.contains(playerIndex) {
                        assistedLeftNeighborPremiumCount[playerIndex] += 1
                    }
                }
            }
            BotSelfPlayEvolutionEngine.accumulatePremiumSupportLosses(
                premiumAssistLosses: &premiumAssistLosses,
                premiumPenaltyTargetLosses: &premiumPenaltyTargetLosses,
                blockOutcome: blockOutcome,
                playerCount: playerCount
            )
        }

        func makeOutcome() -> SimulatedGameOutcome {
            let playerCount = totalScores.count
            let premiumCaptureRates = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(premiumCapturedBlocksCount[playerIndex]),
                    Double(totalBlocksCount[playerIndex])
                )
            }
            let blindSuccessRates = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(successfulBlindRoundsCount[playerIndex]),
                    Double(totalBlindRoundsCount[playerIndex])
                )
            }
            let jokerWishWinRates = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(winningWishLeadDeclarationCounts[playerIndex]),
                    Double(totalWishLeadDeclarationCounts[playerIndex])
                )
            }
            let earlyJokerSpendRates = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(earlyJokerPlayCounts[playerIndex]),
                    Double(totalJokerPlayCounts[playerIndex])
                )
            }
            let penaltyTargetRates = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(penaltyTargetBlocksCount[playerIndex]),
                    Double(totalBlocksCount[playerIndex])
                )
            }
            let bidAccuracyRates = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(exactBidRoundsCount[playerIndex]),
                    Double(totalRoundsCount[playerIndex])
                )
            }
            let overbidRates = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(overbidRoundsCount[playerIndex]),
                    Double(totalRoundsCount[playerIndex])
                )
            }
            let blindBidRatesBlock4 = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(blindDealsBlock4Count[playerIndex]),
                    Double(totalDealsBlock4Count[playerIndex])
                )
            }
            let averageBlindBidSizes = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(totalBlindBidAmount[playerIndex]),
                    Double(totalBlindRoundsCount[playerIndex])
                )
            }
            let blindBidWhenBehindRates = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(blindChosenWhenBehindCount[playerIndex]),
                    Double(blindOpportunitiesWhenBehindCount[playerIndex])
                )
            }
            let blindBidWhenLeadingRates = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(blindChosenWhenLeadingCount[playerIndex]),
                    Double(blindOpportunitiesWhenLeadingCount[playerIndex])
                )
            }
            let earlyLeadWishJokerRates = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(totalEarlyLeadWishCounts[playerIndex]),
                    Double(totalRoundsCount[playerIndex])
                )
            }
            let leftNeighborPremiumAssistRates = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(assistedLeftNeighborPremiumCount[playerIndex]),
                    Double(leftNeighborPremiumEventsCount[playerIndex])
                )
            }

            return SimulatedGameOutcome(
                totalScores: totalScores,
                underbidLosses: underbidLosses,
                trumpDensityUnderbidLosses: trumpDensityUnderbidLosses,
                noTrumpControlUnderbidLosses: noTrumpControlUnderbidLosses,
                premiumAssistLosses: premiumAssistLosses,
                premiumPenaltyTargetLosses: premiumPenaltyTargetLosses,
                premiumCaptureRates: premiumCaptureRates,
                blindSuccessRates: blindSuccessRates,
                jokerWishWinRates: jokerWishWinRates,
                earlyJokerSpendRates: earlyJokerSpendRates,
                penaltyTargetRates: penaltyTargetRates,
                bidAccuracyRates: bidAccuracyRates,
                overbidRates: overbidRates,
                blindBidRatesBlock4: blindBidRatesBlock4,
                averageBlindBidSizes: averageBlindBidSizes,
                blindBidWhenBehindRates: blindBidWhenBehindRates,
                blindBidWhenLeadingRates: blindBidWhenLeadingRates,
                earlyLeadWishJokerRates: earlyLeadWishJokerRates,
                leftNeighborPremiumAssistRates: leftNeighborPremiumAssistRates
            )
        }
    }

    private static func makeSeatServices(
        for tuningsBySeat: [BotTuning]
    ) -> SeatServiceBundle {
        return SeatServiceBundle(
            turnServices: tuningsBySeat.map { BotTurnStrategyService(tuning: $0) },
            biddingServices: tuningsBySeat.map { BotBiddingService(tuning: $0) },
            trumpServices: tuningsBySeat.map { BotTrumpSelectionService(tuning: $0) }
        )
    }

    private static func randomGenome(
        around base: EvolutionGenome,
        magnitude: Double,
        using rng: inout SelfPlayRandomGenerator
    ) -> EvolutionGenome {
        return EvolutionGenome(
            chaseWinProbabilityScale: randomizedScale(
                base.chaseWinProbabilityScale,
                magnitude: magnitude,
                range: 0.50...1.80,
                using: &rng
            ),
            chaseThreatPenaltyScale: randomizedScale(
                base.chaseThreatPenaltyScale,
                magnitude: magnitude,
                range: 0.45...1.90,
                using: &rng
            ),
            chaseSpendJokerPenaltyScale: randomizedScale(
                base.chaseSpendJokerPenaltyScale,
                magnitude: magnitude,
                range: 0.45...1.90,
                using: &rng
            ),
            dumpAvoidWinScale: randomizedScale(
                base.dumpAvoidWinScale,
                magnitude: magnitude,
                range: 0.50...1.80,
                using: &rng
            ),
            dumpThreatRewardScale: randomizedScale(
                base.dumpThreatRewardScale,
                magnitude: magnitude,
                range: 0.50...1.90,
                using: &rng
            ),
            dumpSpendJokerPenaltyScale: randomizedScale(
                base.dumpSpendJokerPenaltyScale,
                magnitude: magnitude,
                range: 0.45...1.90,
                using: &rng
            ),
            holdDistributionScale: randomizedScale(
                base.holdDistributionScale,
                magnitude: magnitude,
                range: 0.70...1.20,
                using: &rng
            ),
            futureTricksScale: randomizedScale(
                base.futureTricksScale,
                magnitude: magnitude,
                range: 0.55...1.60,
                using: &rng
            ),
            futureJokerPowerScale: randomizedScale(
                base.futureJokerPowerScale,
                magnitude: magnitude,
                range: 0.55...1.70,
                using: &rng
            ),
            threatPreservationScale: randomizedScale(
                base.threatPreservationScale,
                magnitude: magnitude,
                range: 0.55...1.70,
                using: &rng
            ),
            biddingJokerPowerScale: randomizedScale(
                base.biddingJokerPowerScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...4.00,
                using: &rng
            ),
            biddingRankWeightScale: randomizedScale(
                base.biddingRankWeightScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...12.00,
                using: &rng
            ),
            biddingTrumpBaseBonusScale: randomizedScale(
                base.biddingTrumpBaseBonusScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...12.00,
                using: &rng
            ),
            biddingTrumpRankWeightScale: randomizedScale(
                base.biddingTrumpRankWeightScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...12.00,
                using: &rng
            ),
            biddingHighRankBonusScale: randomizedScale(
                base.biddingHighRankBonusScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...15.00,
                using: &rng
            ),
            biddingLongSuitBonusScale: randomizedScale(
                base.biddingLongSuitBonusScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...15.00,
                using: &rng
            ),
            biddingTrumpDensityBonusScale: randomizedScale(
                base.biddingTrumpDensityBonusScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...15.00,
                using: &rng
            ),
            biddingNoTrumpHighCardBonusScale: randomizedScale(
                base.biddingNoTrumpHighCardBonusScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...15.00,
                using: &rng
            ),
            biddingNoTrumpJokerSynergyScale: randomizedScale(
                base.biddingNoTrumpJokerSynergyScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...15.00,
                using: &rng
            ),
            blindDesperateBehindThresholdScale: randomizedScale(
                base.blindDesperateBehindThresholdScale,
                magnitude: magnitude,
                range: 0.60...1.70,
                using: &rng
            ),
            blindCatchUpBehindThresholdScale: randomizedScale(
                base.blindCatchUpBehindThresholdScale,
                magnitude: magnitude,
                range: 0.55...1.75,
                using: &rng
            ),
            blindSafeLeadThresholdScale: randomizedScale(
                base.blindSafeLeadThresholdScale,
                magnitude: magnitude,
                range: 0.55...1.80,
                using: &rng
            ),
            blindDesperateTargetShareScale: randomizedScale(
                base.blindDesperateTargetShareScale,
                magnitude: magnitude,
                range: 0.60...1.55,
                using: &rng
            ),
            blindCatchUpTargetShareScale: randomizedScale(
                base.blindCatchUpTargetShareScale,
                magnitude: magnitude,
                range: 0.55...1.65,
                using: &rng
            ),
            blindCatchUpConservativeTargetShareScale: randomizedScale(
                base.blindCatchUpConservativeTargetShareScale,
                magnitude: magnitude,
                range: 0.55...1.70,
                using: &rng
            ),
            trumpCardBasePowerScale: randomizedScale(
                base.trumpCardBasePowerScale,
                magnitude: magnitude,
                range: 0.50...1.65,
                using: &rng
            ),
            trumpThresholdScale: randomizedScale(
                base.trumpThresholdScale,
                magnitude: magnitude,
                range: 0.55...1.65,
                using: &rng
            )
        )
    }

    private static func crossover(
        _ first: EvolutionGenome,
        _ second: EvolutionGenome,
        using rng: inout SelfPlayRandomGenerator
    ) -> EvolutionGenome {
        return EvolutionGenome(
            chaseWinProbabilityScale: mixedScale(
                first.chaseWinProbabilityScale,
                second.chaseWinProbabilityScale,
                range: 0.50...1.80,
                using: &rng
            ),
            chaseThreatPenaltyScale: mixedScale(
                first.chaseThreatPenaltyScale,
                second.chaseThreatPenaltyScale,
                range: 0.45...1.90,
                using: &rng
            ),
            chaseSpendJokerPenaltyScale: mixedScale(
                first.chaseSpendJokerPenaltyScale,
                second.chaseSpendJokerPenaltyScale,
                range: 0.45...1.90,
                using: &rng
            ),
            dumpAvoidWinScale: mixedScale(
                first.dumpAvoidWinScale,
                second.dumpAvoidWinScale,
                range: 0.50...1.80,
                using: &rng
            ),
            dumpThreatRewardScale: mixedScale(
                first.dumpThreatRewardScale,
                second.dumpThreatRewardScale,
                range: 0.50...1.90,
                using: &rng
            ),
            dumpSpendJokerPenaltyScale: mixedScale(
                first.dumpSpendJokerPenaltyScale,
                second.dumpSpendJokerPenaltyScale,
                range: 0.45...1.90,
                using: &rng
            ),
            holdDistributionScale: mixedScale(
                first.holdDistributionScale,
                second.holdDistributionScale,
                range: 0.70...1.20,
                using: &rng
            ),
            futureTricksScale: mixedScale(
                first.futureTricksScale,
                second.futureTricksScale,
                range: 0.55...1.60,
                using: &rng
            ),
            futureJokerPowerScale: mixedScale(
                first.futureJokerPowerScale,
                second.futureJokerPowerScale,
                range: 0.55...1.70,
                using: &rng
            ),
            threatPreservationScale: mixedScale(
                first.threatPreservationScale,
                second.threatPreservationScale,
                range: 0.55...1.70,
                using: &rng
            ),
            biddingJokerPowerScale: mixedScale(
                first.biddingJokerPowerScale,
                second.biddingJokerPowerScale,
                range: 0.35...4.00,
                using: &rng
            ),
            biddingRankWeightScale: mixedScale(
                first.biddingRankWeightScale,
                second.biddingRankWeightScale,
                range: 0.35...12.00,
                using: &rng
            ),
            biddingTrumpBaseBonusScale: mixedScale(
                first.biddingTrumpBaseBonusScale,
                second.biddingTrumpBaseBonusScale,
                range: 0.35...12.00,
                using: &rng
            ),
            biddingTrumpRankWeightScale: mixedScale(
                first.biddingTrumpRankWeightScale,
                second.biddingTrumpRankWeightScale,
                range: 0.35...12.00,
                using: &rng
            ),
            biddingHighRankBonusScale: mixedScale(
                first.biddingHighRankBonusScale,
                second.biddingHighRankBonusScale,
                range: 0.35...15.00,
                using: &rng
            ),
            biddingLongSuitBonusScale: mixedScale(
                first.biddingLongSuitBonusScale,
                second.biddingLongSuitBonusScale,
                range: 0.35...15.00,
                using: &rng
            ),
            biddingTrumpDensityBonusScale: mixedScale(
                first.biddingTrumpDensityBonusScale,
                second.biddingTrumpDensityBonusScale,
                range: 0.35...15.00,
                using: &rng
            ),
            biddingNoTrumpHighCardBonusScale: mixedScale(
                first.biddingNoTrumpHighCardBonusScale,
                second.biddingNoTrumpHighCardBonusScale,
                range: 0.35...15.00,
                using: &rng
            ),
            biddingNoTrumpJokerSynergyScale: mixedScale(
                first.biddingNoTrumpJokerSynergyScale,
                second.biddingNoTrumpJokerSynergyScale,
                range: 0.35...15.00,
                using: &rng
            ),
            blindDesperateBehindThresholdScale: mixedScale(
                first.blindDesperateBehindThresholdScale,
                second.blindDesperateBehindThresholdScale,
                range: 0.60...1.70,
                using: &rng
            ),
            blindCatchUpBehindThresholdScale: mixedScale(
                first.blindCatchUpBehindThresholdScale,
                second.blindCatchUpBehindThresholdScale,
                range: 0.55...1.75,
                using: &rng
            ),
            blindSafeLeadThresholdScale: mixedScale(
                first.blindSafeLeadThresholdScale,
                second.blindSafeLeadThresholdScale,
                range: 0.55...1.80,
                using: &rng
            ),
            blindDesperateTargetShareScale: mixedScale(
                first.blindDesperateTargetShareScale,
                second.blindDesperateTargetShareScale,
                range: 0.60...1.55,
                using: &rng
            ),
            blindCatchUpTargetShareScale: mixedScale(
                first.blindCatchUpTargetShareScale,
                second.blindCatchUpTargetShareScale,
                range: 0.55...1.65,
                using: &rng
            ),
            blindCatchUpConservativeTargetShareScale: mixedScale(
                first.blindCatchUpConservativeTargetShareScale,
                second.blindCatchUpConservativeTargetShareScale,
                range: 0.55...1.70,
                using: &rng
            ),
            trumpCardBasePowerScale: mixedScale(
                first.trumpCardBasePowerScale,
                second.trumpCardBasePowerScale,
                range: 0.50...1.65,
                using: &rng
            ),
            trumpThresholdScale: mixedScale(
                first.trumpThresholdScale,
                second.trumpThresholdScale,
                range: 0.55...1.65,
                using: &rng
            )
        )
    }

    private static func mutateGenome(
        _ genome: EvolutionGenome,
        chance: Double,
        magnitude: Double,
        using rng: inout SelfPlayRandomGenerator
    ) -> EvolutionGenome {
        var mutated = genome
        mutateScale(
            &mutated.chaseWinProbabilityScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.50...1.80,
            using: &rng
        )
        mutateScale(
            &mutated.chaseThreatPenaltyScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.45...1.90,
            using: &rng
        )
        mutateScale(
            &mutated.chaseSpendJokerPenaltyScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.45...1.90,
            using: &rng
        )
        mutateScale(
            &mutated.dumpAvoidWinScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.50...1.80,
            using: &rng
        )
        mutateScale(
            &mutated.dumpThreatRewardScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.50...1.90,
            using: &rng
        )
        mutateScale(
            &mutated.dumpSpendJokerPenaltyScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.45...1.90,
            using: &rng
        )
        mutateScale(
            &mutated.holdDistributionScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.70...1.20,
            using: &rng
        )
        mutateScale(
            &mutated.futureTricksScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.55...1.60,
            using: &rng
        )
        mutateScale(
            &mutated.futureJokerPowerScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.55...1.70,
            using: &rng
        )
        mutateScale(
            &mutated.threatPreservationScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.55...1.70,
            using: &rng
        )
        mutateScale(
            &mutated.biddingJokerPowerScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...4.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingRankWeightScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...12.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingTrumpBaseBonusScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...12.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingTrumpRankWeightScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...12.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingHighRankBonusScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...15.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingLongSuitBonusScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...15.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingTrumpDensityBonusScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...15.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingNoTrumpHighCardBonusScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...15.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingNoTrumpJokerSynergyScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...15.00,
            using: &rng
        )
        mutateScale(
            &mutated.blindDesperateBehindThresholdScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.60...1.70,
            using: &rng
        )
        mutateScale(
            &mutated.blindCatchUpBehindThresholdScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.55...1.75,
            using: &rng
        )
        mutateScale(
            &mutated.blindSafeLeadThresholdScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.55...1.80,
            using: &rng
        )
        mutateScale(
            &mutated.blindDesperateTargetShareScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.60...1.55,
            using: &rng
        )
        mutateScale(
            &mutated.blindCatchUpTargetShareScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.55...1.65,
            using: &rng
        )
        mutateScale(
            &mutated.blindCatchUpConservativeTargetShareScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.55...1.70,
            using: &rng
        )
        mutateScale(
            &mutated.trumpCardBasePowerScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.50...1.65,
            using: &rng
        )
        mutateScale(
            &mutated.trumpThresholdScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.55...1.65,
            using: &rng
        )

        return mutated
    }

    private static func evaluateGenome(
        _ genome: EvolutionGenome,
        baseTuning: BotTuning,
        context: FitnessEvaluationContext
    ) -> FitnessBreakdown {
        let candidateTuning = tuning(byApplying: genome, to: baseTuning)
        return evaluateCandidateTuning(
            candidateTuning: candidateTuning,
            opponentTuning: baseTuning,
            context: context
        )
    }

    /// Head-to-head оценка фиксированного кандидата против фиксированных оппонентов.
    /// Удобно для CLI A/B-валидации после обучения.
    static func evaluateHeadToHead(
        candidateTuning: BotTuning,
        opponentTuning: BotTuning,
        config: SelfPlayEvolutionConfig = SelfPlayEvolutionConfig(),
        seed: UInt64 = 0x5EED
    ) -> SelfPlayHeadToHeadValidationResult {
        let playerCount = min(4, max(3, config.playerCount))
        let cardsRange = normalizedCardsPerRoundRange(
            from: config.cardsPerRoundRange,
            playerCount: playerCount
        )
        let fitnessScoring = FitnessScoringConfig(config: config)

        var rng = SelfPlayRandomGenerator(seed: seed)
        let evaluationSeeds = makeEvaluationSeeds(
            count: config.gamesPerCandidate,
            using: &rng
        )
        let evaluationContext = FitnessEvaluationContext(
            playerCount: playerCount,
            roundsPerGame: config.roundsPerGame,
            cardsPerRoundRange: cardsRange,
            evaluationSeeds: evaluationSeeds,
            useFullMatchRules: config.useFullMatchRules,
            rotateCandidateAcrossSeats: config.rotateCandidateAcrossSeats,
            fitnessScoring: fitnessScoring
        )
        let breakdown = evaluateCandidateTuning(
            candidateTuning: candidateTuning,
            opponentTuning: opponentTuning,
            context: evaluationContext
        )
        return headToHeadValidationResult(from: breakdown)
    }

    struct DebugPreDealBlindContext {
        let lockedBids: [Int]
        let blindSelections: [Bool]
    }

    struct DebugBiddingRoundOutcome {
        let bids: [Int]
        let maxAllowedBids: [Int]
    }

    static func debugBiddingOrder(dealer: Int, playerCount: Int) -> [Int] {
        return biddingOrder(dealer: dealer, playerCount: playerCount)
    }

    static func debugCanChooseBlindBid(
        forPlayer playerIndex: Int,
        dealer: Int,
        blindSelections: [Bool]
    ) -> Bool {
        return canChooseBlindBid(
            forPlayer: playerIndex,
            dealer: dealer,
            blindSelections: blindSelections
        )
    }

    static func debugResolvePreDealBlindContext(
        dealer: Int,
        cardsInRound: Int,
        playerCount: Int,
        biddingServices: [BotBiddingService],
        totalScoresIncludingCurrentBlock: [Int]
    ) -> DebugPreDealBlindContext {
        let context = resolvePreDealBlindContext(
            dealer: dealer,
            cardsInRound: cardsInRound,
            playerCount: playerCount,
            biddingServices: biddingServices,
            totalScoresIncludingCurrentBlock: totalScoresIncludingCurrentBlock
        )
        return DebugPreDealBlindContext(
            lockedBids: context.lockedBids,
            blindSelections: context.blindSelections
        )
    }

    static func debugMakeBids(
        hands: [[Card]],
        dealer: Int,
        cardsInRound: Int,
        trump: Suit?,
        biddingServices: [BotBiddingService],
        preLockedBids: [Int]? = nil,
        blindSelections: [Bool]? = nil
    ) -> DebugBiddingRoundOutcome {
        let outcome = makeBids(
            hands: hands,
            dealer: dealer,
            cardsInRound: cardsInRound,
            trump: trump,
            biddingServices: biddingServices,
            preLockedBids: preLockedBids,
            blindSelections: blindSelections
        )
        return DebugBiddingRoundOutcome(
            bids: outcome.bids,
            maxAllowedBids: outcome.maxAllowedBids
        )
    }

    private static func simulateGame(
        tuningsBySeat: [BotTuning],
        rounds: Int,
        cardsPerRoundRange: ClosedRange<Int>,
        seed: UInt64,
        useFullMatchRules: Bool
    ) -> SimulatedGameOutcome {
        if useFullMatchRules {
            return simulateFullMatch(
                tuningsBySeat: tuningsBySeat,
                seed: seed
            )
        }

        return simulateLegacyGame(
            tuningsBySeat: tuningsBySeat,
            rounds: rounds,
            cardsPerRoundRange: cardsPerRoundRange,
            seed: seed
        )
    }

    private static func simulateLegacyGame(
        tuningsBySeat: [BotTuning],
        rounds: Int,
        cardsPerRoundRange: ClosedRange<Int>,
        seed: UInt64
    ) -> SimulatedGameOutcome {
        let playerCount = tuningsBySeat.count
        var rng = SelfPlayRandomGenerator(seed: seed)

        let services = makeSeatServices(for: tuningsBySeat)
        var metrics = SimulationMetricsAccumulator(playerCount: playerCount)
        var dealer = Int.random(in: 0..<playerCount, using: &rng)

        for _ in 0..<rounds {
            let cardsInRound = Int.random(in: cardsPerRoundRange, using: &rng)
            let hands = dealHands(
                cardsPerPlayer: cardsInRound,
                playerCount: playerCount,
                dealer: dealer,
                using: &rng
            )

            let trumpChooser = normalizedPlayerIndex(dealer + 1, playerCount: playerCount)
            let trump = services.trumpServices[trumpChooser].selectTrump(from: hands[trumpChooser])
            let roundSimulation = simulateScoredRound(
                RoundSimulationInput(
                    hands: hands,
                    dealer: dealer,
                    cardsInRound: cardsInRound,
                    trump: trump,
                    preLockedBids: nil,
                    blindSelections: nil,
                    noTrumpControlEmphasisMultiplier: 0.75
                ),
                services: services,
                metrics: &metrics
            )
            metrics.addRoundScores(roundSimulation.roundResults)

            dealer = normalizedPlayerIndex(dealer + 1, playerCount: playerCount)
        }

        return metrics.makeOutcome()
    }

    private static func simulateFullMatch(
        tuningsBySeat: [BotTuning],
        seed: UInt64
    ) -> SimulatedGameOutcome {
        let playerCount = tuningsBySeat.count
        var rng = SelfPlayRandomGenerator(seed: seed)

        let services = makeSeatServices(for: tuningsBySeat)

        let blockDeals = GameConstants.allBlockDeals(playerCount: playerCount)

        var metrics = SimulationMetricsAccumulator(playerCount: playerCount)
        var dealer = Int.random(in: 0..<playerCount, using: &rng)

        for (blockIndex, dealsInBlock) in blockDeals.enumerated() {
            let blockNumber = blockIndex + 1
            var blockRoundResults = Array(repeating: [RoundResult](), count: playerCount)
            var blockBaseScores = Array(repeating: 0, count: playerCount)

            for cardsInRound in dealsInBlock {
                let roundDeal = dealRoundForFullMatch(
                    cardsPerPlayer: cardsInRound,
                    playerCount: playerCount,
                    dealer: dealer,
                    blockNumber: blockNumber,
                    trumpServices: services.trumpServices,
                    using: &rng
                )
                let hands = roundDeal.hands
                let trump = roundDeal.trump

                let totalsIncludingCurrentBlock = (0..<playerCount).map { index in
                    metrics.totalScores[index] + blockBaseScores[index]
                }

                let blindContext: PreDealBlindContext
                if blockNumber == GameBlock.fourth.rawValue {
                    blindContext = resolvePreDealBlindContext(
                        dealer: dealer,
                        cardsInRound: cardsInRound,
                        playerCount: playerCount,
                        biddingServices: services.biddingServices,
                        totalScoresIncludingCurrentBlock: totalsIncludingCurrentBlock
                    )
                } else {
                    blindContext = PreDealBlindContext(
                        lockedBids: Array(repeating: 0, count: playerCount),
                        blindSelections: Array(repeating: false, count: playerCount),
                        eligibleWhenBehind: Array(repeating: false, count: playerCount),
                        chosenWhenBehind: Array(repeating: false, count: playerCount),
                        eligibleWhenLeading: Array(repeating: false, count: playerCount),
                        chosenWhenLeading: Array(repeating: false, count: playerCount)
                    )
                }

                let noTrumpControlEmphasisMultiplier =
                    (blockNumber == GameBlock.first.rawValue ||
                     blockNumber == GameBlock.third.rawValue) ? 1.0 : 0.55
                if blockNumber == GameBlock.fourth.rawValue {
                    metrics.recordBlindChoiceContext(
                        eligibleWhenBehind: blindContext.eligibleWhenBehind,
                        chosenWhenBehind: blindContext.chosenWhenBehind,
                        eligibleWhenLeading: blindContext.eligibleWhenLeading,
                        chosenWhenLeading: blindContext.chosenWhenLeading
                    )
                    metrics.recordBlock4BlindExposure(
                        blindSelections: blindContext.blindSelections
                    )
                }
                let roundSimulation = simulateScoredRound(
                    RoundSimulationInput(
                        hands: hands,
                        dealer: dealer,
                        cardsInRound: cardsInRound,
                        trump: trump,
                        preLockedBids: blindContext.lockedBids,
                        blindSelections: blindContext.blindSelections,
                        noTrumpControlEmphasisMultiplier: noTrumpControlEmphasisMultiplier
                    ),
                    services: services,
                    metrics: &metrics
                )
                let roundResults = roundSimulation.roundResults

                appendRoundResultsToBlock(
                    roundResults,
                    blockRoundResults: &blockRoundResults,
                    blockBaseScores: &blockBaseScores
                )

                dealer = normalizedPlayerIndex(dealer + 1, playerCount: playerCount)
            }

            let finalizedBlockOutcome = finalizeBlockScores(
                blockRoundResults: blockRoundResults,
                blockNumber: blockNumber,
                playerCount: playerCount
            )
            metrics.accumulatePremiumSupportLosses(
                blockOutcome: finalizedBlockOutcome,
                playerCount: playerCount
            )
            metrics.addFinalScores(finalizedBlockOutcome.finalScores)
        }

        return metrics.makeOutcome()
    }

    private static func appendRoundResultsToBlock(
        _ roundResults: [RoundResult],
        blockRoundResults: inout [[RoundResult]],
        blockBaseScores: inout [Int]
    ) {
        for (playerIndex, roundResult) in roundResults.enumerated() {
            guard blockRoundResults.indices.contains(playerIndex) else { continue }
            blockRoundResults[playerIndex].append(roundResult)
            if blockBaseScores.indices.contains(playerIndex) {
                blockBaseScores[playerIndex] += roundResult.score
            }
        }
    }

    private static func resolvePreDealBlindContext(
        dealer: Int,
        cardsInRound: Int,
        playerCount: Int,
        biddingServices: [BotBiddingService],
        totalScoresIncludingCurrentBlock: [Int]
    ) -> PreDealBlindContext {
        var lockedBids = Array(repeating: 0, count: playerCount)
        var blindSelections = Array(repeating: false, count: playerCount)
        var eligibleWhenBehind = Array(repeating: false, count: playerCount)
        var chosenWhenBehind = Array(repeating: false, count: playerCount)
        var eligibleWhenLeading = Array(repeating: false, count: playerCount)
        var chosenWhenLeading = Array(repeating: false, count: playerCount)
        let maxScore = totalScoresIncludingCurrentBlock.max() ?? 0

        for playerIndex in biddingOrder(dealer: dealer, playerCount: playerCount) {
            guard canChooseBlindBid(
                forPlayer: playerIndex,
                dealer: dealer,
                blindSelections: blindSelections
            ) else {
                continue
            }

            let allowedBlindBids = allowedBids(
                forPlayer: playerIndex,
                dealer: dealer,
                cardsInRound: cardsInRound,
                bids: lockedBids,
                playerCount: playerCount
            )
            guard !allowedBlindBids.isEmpty else { continue }

            let playerScore = totalScoresIncludingCurrentBlock.indices.contains(playerIndex)
                ? totalScoresIncludingCurrentBlock[playerIndex]
                : 0
            let isLeading = playerScore == maxScore
            let isBehind = playerScore < maxScore
            if isLeading {
                eligibleWhenLeading[playerIndex] = true
            } else if isBehind {
                eligibleWhenBehind[playerIndex] = true
            }

            let blindBid = biddingServices[playerIndex].makePreDealBlindBid(
                playerIndex: playerIndex,
                dealerIndex: dealer,
                cardsInRound: cardsInRound,
                allowedBlindBids: allowedBlindBids,
                canChooseBlind: true,
                totalScores: totalScoresIncludingCurrentBlock
            )

            guard let blindBid else { continue }
            let resolvedBlindBid = allowedBlindBids.contains(blindBid)
                ? blindBid
                : (allowedBlindBids.first ?? 0)
            blindSelections[playerIndex] = true
            lockedBids[playerIndex] = resolvedBlindBid
            if isLeading {
                chosenWhenLeading[playerIndex] = true
            } else if isBehind {
                chosenWhenBehind[playerIndex] = true
            }
        }

        return PreDealBlindContext(
            lockedBids: lockedBids,
            blindSelections: blindSelections,
            eligibleWhenBehind: eligibleWhenBehind,
            chosenWhenBehind: chosenWhenBehind,
            eligibleWhenLeading: eligibleWhenLeading,
            chosenWhenLeading: chosenWhenLeading
        )
    }

    /// Потери очков из-за недозаказа: сколько очков не добрал игрок,
    /// если фактические взятки были бы заказаны точно.
    private static func underbidLoss(
        cardsInRound: Int,
        bid: Int,
        tricksTaken: Int,
        isBlind: Bool
    ) -> Double {
        guard tricksTaken > bid else { return 0.0 }
        let idealBid = min(max(0, tricksTaken), max(0, cardsInRound))
        let idealScore = ScoreCalculator.calculateRoundScore(
            cardsInRound: cardsInRound,
            bid: idealBid,
            tricksTaken: tricksTaken,
            isBlind: isBlind
        )
        let actualScore = ScoreCalculator.calculateRoundScore(
            cardsInRound: cardsInRound,
            bid: bid,
            tricksTaken: tricksTaken,
            isBlind: isBlind
        )
        return Double(max(0, idealScore - actualScore))
    }

    /// Жесткий штраф за заказ ниже количества джокеров на руке.
    /// Каждый джокер в большинстве сценариев является контролируемым ресурсом взятки,
    /// поэтому такое занижение рассматривается как потеря потенциальных очков.
    private static func jokerBidFloorUnderbidPenalty(
        hand: [Card],
        bid: Int,
        maxAllowedBid: Int
    ) -> Double {
        let jokerCount = hand.reduce(0) { partial, card in
            partial + (card.isJoker ? 1 : 0)
        }
        let reachableJokerFloor = min(jokerCount, max(0, maxAllowedBid))
        let deficit = max(0, reachableJokerFloor - max(0, bid))
        guard deficit > 0 else { return 0.0 }
        let penaltyPerMissingTrick = 10_000.0
        var penalty = Double(deficit) * penaltyPerMissingTrick

        // Отдельно усиливаем штраф при двух джокерах:
        // такие руки должны заметно поднимать заказ.
        if jokerCount >= 2 {
            penalty += Double(deficit) * 25_000.0
        }

        return penalty
    }

    /// Граничный сценарий для self-play: если на руке ровно 2 джокера при раздаче 2 карт,
    /// бот должен стремиться к максимально допустимому заказу.
    private static func jokerAllInEdgeMaxBidPenalty(
        hand: [Card],
        bid: Int,
        cardsInRound: Int,
        maxAllowedBid: Int
    ) -> Double {
        guard cardsInRound == 2 else { return 0.0 }
        guard hand.count == 2 else { return 0.0 }
        let jokerCount = hand.reduce(0) { partial, card in
            partial + (card.isJoker ? 1 : 0)
        }
        guard jokerCount == 2 else { return 0.0 }

        let targetBid = min(max(0, maxAllowedBid), cardsInRound)
        let resolvedBid = min(max(0, bid), cardsInRound)
        let deficit = max(0, targetBid - resolvedBid)
        guard deficit > 0 else { return 0.0 }

        let penaltyPerMissingTrick = 65_000.0
        let certaintyBonus = targetBid == cardsInRound ? 25_000.0 : 10_000.0
        return Double(deficit) * penaltyPerMissingTrick + certaintyBonus
    }

    /// Штраф за ранний заход джокером в режиме "wish":
    /// без заказа масти бот хуже контролирует последующие взятки.
    private static func nonFinalLeadWishWithoutAbovePenalty(
        nonFinalLeadWishCount: Int,
        cardsInRound: Int
    ) -> Double {
        guard nonFinalLeadWishCount > 0 else { return 0.0 }
        let depthMultiplier = cardsInRound >= 5 ? 1.20 : 1.0
        return Double(nonFinalLeadWishCount) * 2_400.0 * depthMultiplier
    }

    /// Дополнительный штраф за недозаказ в руках с высокой плотностью козырей.
    private static func trumpDensityUnderbidPenalty(
        hand: [Card],
        bid: Int,
        cardsInRound: Int,
        trump: Suit?
    ) -> Double {
        guard let trump else { return 0.0 }
        guard cardsInRound > 0 else { return 0.0 }

        let trumpCount = hand.reduce(0) { partial, card in
            partial + ((card.suit == trump) ? 1 : 0)
        }
        let jokerCount = hand.reduce(0) { partial, card in
            partial + (card.isJoker ? 1 : 0)
        }
        let effectiveControl = Double(trumpCount) + Double(jokerCount) * 0.85
        let trumpDensity = effectiveControl / Double(cardsInRound)
        guard trumpDensity >= 0.45 else { return 0.0 }

        let suggestedFloor = min(
            cardsInRound,
            max(1, Int((effectiveControl * 0.75).rounded(.down)))
        )
        let deficit = max(0, suggestedFloor - max(0, bid))
        guard deficit > 0 else { return 0.0 }

        let densityMultiplier = 1.0 + max(0.0, trumpDensity - 0.45) * 2.5
        return Double(deficit) * 2_400.0 * densityMultiplier
    }

    /// Штраф за недозаказ в no-trump руках контроля:
    /// много старших карт и/или длина масти, особенно с джокером.
    private static func noTrumpControlUnderbidPenalty(
        hand: [Card],
        bid: Int,
        cardsInRound: Int,
        trump: Suit?,
        emphasisMultiplier: Double
    ) -> Double {
        guard trump == nil else { return 0.0 }
        guard cardsInRound > 0 else { return 0.0 }

        let regularCards = hand.compactMap { card -> (suit: Suit, rank: Rank)? in
            guard case .regular(let suit, let rank) = card else { return nil }
            return (suit, rank)
        }
        let suitCounts = Dictionary(grouping: regularCards, by: \.suit).mapValues(\.count)
        let longestSuit = suitCounts.values.max() ?? 0
        let highCards = regularCards.reduce(0) { partial, card in
            partial + (card.rank.rawValue >= Rank.queen.rawValue ? 1 : 0)
        }
        let jokerCount = hand.reduce(0) { partial, card in
            partial + (card.isJoker ? 1 : 0)
        }

        let hasControlPattern = highCards >= 4 || (jokerCount >= 1 && (highCards >= 3 || longestSuit >= 4))
        guard hasControlPattern else { return 0.0 }

        let controlScore = Double(highCards) * 0.70 +
            Double(max(0, longestSuit - 2)) * 1.00 +
            Double(jokerCount) * 1.20
        let suggestedFloor = min(
            cardsInRound,
            max(1, Int((controlScore * 0.42).rounded()))
        )
        let deficit = max(0, suggestedFloor - max(0, bid))
        guard deficit > 0 else { return 0.0 }

        let jokerMultiplier = jokerCount > 0 ? 1.35 : 1.0
        return Double(deficit) * 1_900.0 * jokerMultiplier * max(0.0, emphasisMultiplier)
    }

    private typealias BlockFinalizationOutcome = PremiumRules.BlockFinalizationOutcome

    private static func finalizeBlockScores(
        blockRoundResults: [[RoundResult]],
        blockNumber: Int,
        playerCount: Int
    ) -> BlockFinalizationOutcome {
        return PremiumRules.finalizeBlockScores(
            blockRoundResults: blockRoundResults,
            blockNumber: blockNumber,
            playerCount: playerCount
        )
    }

    private static func accumulatePremiumSupportLosses(
        premiumAssistLosses: inout [Double],
        premiumPenaltyTargetLosses: inout [Double],
        blockOutcome: BlockFinalizationOutcome,
        playerCount: Int
    ) {
        guard playerCount > 0 else { return }
        guard !blockOutcome.allPremiumPlayers.isEmpty else { return }

        let premiumPlayersSet = Set(blockOutcome.allPremiumPlayers)
        let premiumGains = (0..<playerCount).map { playerIndex in
            let regularBonus = blockOutcome.premiumBonuses.indices.contains(playerIndex)
                ? blockOutcome.premiumBonuses[playerIndex]
                : 0
            let zeroBonus = blockOutcome.zeroPremiumBonuses.indices.contains(playerIndex)
                ? blockOutcome.zeroPremiumBonuses[playerIndex]
                : 0
            return regularBonus + zeroBonus
        }

        for playerIndex in 0..<playerCount {
            let penalty = blockOutcome.premiumPenalties.indices.contains(playerIndex)
                ? blockOutcome.premiumPenalties[playerIndex]
                : 0
            premiumPenaltyTargetLosses[playerIndex] += Double(max(0, penalty))

            // Если игрок сам не взял премию, но соперники взяли,
            // считаем это "подарком премии" и штрафуем в self-play.
            guard !premiumPlayersSet.contains(playerIndex) else { continue }
            let opponentPremiumPlayers = blockOutcome.allPremiumPlayers.filter { $0 != playerIndex }
            guard !opponentPremiumPlayers.isEmpty else { continue }

            let opponentsPremiumGain = opponentPremiumPlayers.reduce(0) { partial, opponentIndex in
                partial + (premiumGains.indices.contains(opponentIndex) ? premiumGains[opponentIndex] : 0)
            }
            let structureLoss = Double(opponentPremiumPlayers.count) * 120.0
            let gainLoss = Double(max(0, opponentsPremiumGain)) * 0.45
            premiumAssistLosses[playerIndex] += structureLoss + gainLoss
        }
    }

    private struct BiddingRoundOutcome {
        let bids: [Int]
        let maxAllowedBids: [Int]
    }

    private static func makeBids(
        hands: [[Card]],
        dealer: Int,
        cardsInRound: Int,
        trump: Suit?,
        biddingServices: [BotBiddingService],
        preLockedBids: [Int]? = nil,
        blindSelections: [Bool]? = nil
    ) -> BiddingRoundOutcome {
        let playerCount = hands.count
        let firstBidder = normalizedPlayerIndex(dealer + 1, playerCount: playerCount)

        let resolvedLockedBids: [Int]
        if let preLockedBids, preLockedBids.count == playerCount {
            resolvedLockedBids = preLockedBids
        } else {
            resolvedLockedBids = Array(repeating: 0, count: playerCount)
        }

        let resolvedBlindSelections: [Bool]
        if let blindSelections, blindSelections.count == playerCount {
            resolvedBlindSelections = blindSelections
        } else {
            resolvedBlindSelections = Array(repeating: false, count: playerCount)
        }

        var bids = resolvedLockedBids
        var maxAllowedBids = Array(repeating: 0, count: playerCount)

        for step in 0..<playerCount {
            let player = normalizedPlayerIndex(firstBidder + step, playerCount: playerCount)
            let allowed = allowedBids(
                forPlayer: player,
                dealer: dealer,
                cardsInRound: cardsInRound,
                bids: bids,
                playerCount: playerCount
            )
            maxAllowedBids[player] = allowed.max() ?? 0

            if resolvedBlindSelections[player] {
                continue
            }

            let fallbackBid = allowed.first ?? 0
            let forbiddenBid = dealerForbiddenBid(
                forPlayer: player,
                dealer: dealer,
                cardsInRound: cardsInRound,
                bids: bids,
                playerCount: playerCount
            )

            let candidateBid = biddingServices[player].makeBid(
                hand: hands[player],
                cardsInRound: cardsInRound,
                trump: trump,
                forbiddenBid: forbiddenBid
            )

            bids[player] = allowed.contains(candidateBid)
                ? candidateBid
                : fallbackBid
        }

        return BiddingRoundOutcome(
            bids: bids,
            maxAllowedBids: maxAllowedBids
        )
    }

    private static func playRound(
        hands: [[Card]],
        bids: [Int],
        dealer: Int,
        cardsInRound: Int,
        trump: Suit?,
        turnServices: [BotTurnStrategyService]
    ) -> RoundPlayOutcome {
        let playerCount = hands.count
        var tricksTaken = Array(repeating: 0, count: playerCount)
        var nonFinalLeadWishCounts = Array(repeating: 0, count: playerCount)
        var totalWishLeadDeclarationCounts = Array(repeating: 0, count: playerCount)
        var winningWishLeadDeclarationCounts = Array(repeating: 0, count: playerCount)
        var totalJokerPlayCounts = Array(repeating: 0, count: playerCount)
        var earlyJokerPlayCounts = Array(repeating: 0, count: playerCount)
        var mutableHands = hands
        var trickLeader = normalizedPlayerIndex(dealer + 1, playerCount: playerCount)

        for trickIndex in 0..<cardsInRound {
            let trickNode = TrickNode(rendersCards: false)

            for offset in 0..<playerCount {
                let player = normalizedPlayerIndex(trickLeader + offset, playerCount: playerCount)
                let playerHand = mutableHands[player]

                guard !playerHand.isEmpty else { continue }

                let strategyMove = turnServices[player].makeTurnDecision(
                    context: .init(
                        handCards: playerHand,
                        trickNode: trickNode,
                        trump: trump,
                        bid: bids[player],
                        tricksTaken: tricksTaken[player],
                        cardsInRound: cardsInRound,
                        playerCount: playerCount
                    )
                )

                let move: (card: Card, decision: JokerPlayDecision)
                if let strategyMove {
                    move = (strategyMove.card, strategyMove.jokerDecision)
                } else if let fallbackMove = fallbackMove(
                    hand: playerHand,
                    trickNode: trickNode,
                    trump: trump
                ) {
                    move = fallbackMove
                } else {
                    continue
                }

                if isNonFinalLeadWishJokerMove(
                    move: move,
                    trickNode: trickNode,
                    trickIndex: trickIndex,
                    cardsInRound: cardsInRound
                ) {
                    nonFinalLeadWishCounts[player] += 1
                }

                let isLeadMove = trickNode.playedCards.isEmpty
                if move.card.isJoker {
                    totalJokerPlayCounts[player] += 1
                    if trickIndex + 1 < cardsInRound {
                        earlyJokerPlayCounts[player] += 1
                    }
                    if isLeadMove, move.decision.leadDeclaration == .wish {
                        totalWishLeadDeclarationCounts[player] += 1
                    }
                }

                if let removeIndex = mutableHands[player].firstIndex(of: move.card) {
                    mutableHands[player].remove(at: removeIndex)
                } else if let fallbackCard = mutableHands[player].first {
                    let isLeadFallback = trickNode.playedCards.isEmpty
                    if fallbackCard.isJoker {
                        totalJokerPlayCounts[player] += 1
                        if trickIndex + 1 < cardsInRound {
                            earlyJokerPlayCounts[player] += 1
                        }
                        if isLeadFallback {
                            totalWishLeadDeclarationCounts[player] += 1
                        }
                    }
                    mutableHands[player].removeFirst()
                    _ = trickNode.playCard(
                        fallbackCard,
                        fromPlayer: player + 1,
                        jokerPlayStyle: .faceUp,
                        jokerLeadDeclaration: fallbackCard.isJoker && trickNode.playedCards.isEmpty
                            ? .wish
                            : nil,
                        animated: false
                    )
                    continue
                } else {
                    continue
                }

                _ = trickNode.playCard(
                    move.card,
                    fromPlayer: player + 1,
                    jokerPlayStyle: move.decision.style,
                    jokerLeadDeclaration: move.decision.leadDeclaration,
                    animated: false
                )
            }

            let winner = TrickTakingResolver.winnerPlayerIndex(
                playedCards: trickNode.playedCards,
                trump: trump
            ) ?? trickLeader

            tricksTaken[winner] += 1
            if
                let winnerMove = trickNode.playedCards.first(where: { $0.playerIndex == winner + 1 }),
                winnerMove.card.isJoker,
                winnerMove.jokerLeadDeclaration == .wish,
                trickNode.playedCards.first?.playerIndex == winner + 1
            {
                winningWishLeadDeclarationCounts[winner] += 1
            }
            trickLeader = winner
        }

        return RoundPlayOutcome(
            tricksTaken: tricksTaken,
            nonFinalLeadWishCounts: nonFinalLeadWishCounts,
            totalWishLeadDeclarationCounts: totalWishLeadDeclarationCounts,
            winningWishLeadDeclarationCounts: winningWishLeadDeclarationCounts,
            totalJokerPlayCounts: totalJokerPlayCounts,
            earlyJokerPlayCounts: earlyJokerPlayCounts
        )
    }

    private struct RoundPlayOutcome {
        let tricksTaken: [Int]
        let nonFinalLeadWishCounts: [Int]
        let totalWishLeadDeclarationCounts: [Int]
        let winningWishLeadDeclarationCounts: [Int]
        let totalJokerPlayCounts: [Int]
        let earlyJokerPlayCounts: [Int]
    }

    private struct RoundSimulationInput {
        let hands: [[Card]]
        let dealer: Int
        let cardsInRound: Int
        let trump: Suit?
        let preLockedBids: [Int]?
        let blindSelections: [Bool]?
        let noTrumpControlEmphasisMultiplier: Double
    }

    private struct RoundSimulationOutputs {
        let biddingOutcome: BiddingRoundOutcome
        let playOutcome: RoundPlayOutcome
        let roundResults: [RoundResult]
    }

    private static func simulateScoredRound(
        _ input: RoundSimulationInput,
        services: SeatServiceBundle,
        metrics: inout SimulationMetricsAccumulator
    ) -> RoundSimulationOutputs {
        let biddingOutcome = makeBids(
            hands: input.hands,
            dealer: input.dealer,
            cardsInRound: input.cardsInRound,
            trump: input.trump,
            biddingServices: services.biddingServices,
            preLockedBids: input.preLockedBids,
            blindSelections: input.blindSelections
        )
        let playOutcome = playRound(
            hands: input.hands,
            bids: biddingOutcome.bids,
            dealer: input.dealer,
            cardsInRound: input.cardsInRound,
            trump: input.trump,
            turnServices: services.turnServices
        )
        let roundResults = metrics.evaluateRound(
            hands: input.hands,
            biddingOutcome: biddingOutcome,
            playOutcome: playOutcome,
            cardsInRound: input.cardsInRound,
            trump: input.trump,
            blindSelections: input.blindSelections,
            noTrumpControlEmphasisMultiplier: input.noTrumpControlEmphasisMultiplier
        )
        return RoundSimulationOutputs(
            biddingOutcome: biddingOutcome,
            playOutcome: playOutcome,
            roundResults: roundResults
        )
    }

    private static func isNonFinalLeadWishJokerMove(
        move: (card: Card, decision: JokerPlayDecision),
        trickNode: TrickNode,
        trickIndex: Int,
        cardsInRound: Int
    ) -> Bool {
        guard move.card.isJoker else { return false }
        guard move.decision.style == .faceUp else { return false }
        guard trickNode.playedCards.isEmpty else { return false }
        guard trickIndex < cardsInRound - 1 else { return false }
        guard case .some(.wish) = move.decision.leadDeclaration else { return false }
        return true
    }

    private static func fallbackMove(
        hand: [Card],
        trickNode: TrickNode,
        trump: Suit?
    ) -> (card: Card, decision: JokerPlayDecision)? {
        guard !hand.isEmpty else { return nil }

        let legalCard = hand.first { card in
            trickNode.canPlayCard(card, fromHand: hand, trump: trump)
        } ?? hand[0]

        let decision: JokerPlayDecision
        if legalCard.isJoker {
            decision = trickNode.playedCards.isEmpty ? .defaultLead : .defaultNonLead
        } else {
            decision = .defaultNonLead
        }

        return (legalCard, decision)
    }

    private struct FullMatchRoundDeal {
        let hands: [[Card]]
        let trump: Suit?
    }

    private static func dealRoundForFullMatch(
        cardsPerPlayer: Int,
        playerCount: Int,
        dealer: Int,
        blockNumber: Int,
        trumpServices: [BotTrumpSelectionService],
        using rng: inout SelfPlayRandomGenerator
    ) -> FullMatchRoundDeal {
        var deckCards = Deck().cards
        deckCards.shuffle(using: &rng)
        let startingPlayer = normalizedPlayerIndex(dealer + 1, playerCount: playerCount)

        if blockNumber == GameBlock.first.rawValue || blockNumber == GameBlock.third.rawValue {
            let dealResult = dealHandsFromDeckCards(
                cardsPerPlayer: cardsPerPlayer,
                playerCount: playerCount,
                startingPlayer: startingPlayer,
                deckCards: deckCards,
                startingDeckIndex: 0
            )
            let topDeckCard = dealResult.nextDeckIndex < deckCards.count
                ? deckCards[dealResult.nextDeckIndex]
                : nil
            return FullMatchRoundDeal(
                hands: sortedHands(dealResult.hands),
                trump: trumpSuit(from: topDeckCard)
            )
        }

        let cardsBeforeChoice = min(cardsPerPlayer, max(1, cardsPerPlayer / 3))
        let initialDeal = dealHandsFromDeckCards(
            cardsPerPlayer: cardsBeforeChoice,
            playerCount: playerCount,
            startingPlayer: startingPlayer,
            deckCards: deckCards,
            startingDeckIndex: 0
        )
        let trumpChooser = normalizedPlayerIndex(dealer + 1, playerCount: playerCount)
        let trump = trumpServices[trumpChooser].selectTrump(
            from: initialDeal.hands[trumpChooser],
            isPlayerChosenTrumpStage: true
        )

        let remainingCards = max(0, cardsPerPlayer - cardsBeforeChoice)
        var fullHands = initialDeal.hands
        if remainingCards > 0 {
            let remainingDeal = dealHandsFromDeckCards(
                cardsPerPlayer: remainingCards,
                playerCount: playerCount,
                startingPlayer: startingPlayer,
                deckCards: deckCards,
                startingDeckIndex: initialDeal.nextDeckIndex
            )
            for index in 0..<playerCount {
                fullHands[index].append(contentsOf: remainingDeal.hands[index])
            }
        }

        return FullMatchRoundDeal(
            hands: sortedHands(fullHands),
            trump: trump
        )
    }

    private static func dealHands(
        cardsPerPlayer: Int,
        playerCount: Int,
        dealer: Int,
        using rng: inout SelfPlayRandomGenerator
    ) -> [[Card]] {
        var deckCards = Deck().cards
        deckCards.shuffle(using: &rng)

        let startingPlayer = normalizedPlayerIndex(dealer + 1, playerCount: playerCount)
        let dealResult = dealHandsFromDeckCards(
            cardsPerPlayer: cardsPerPlayer,
            playerCount: playerCount,
            startingPlayer: startingPlayer,
            deckCards: deckCards,
            startingDeckIndex: 0
        )
        return sortedHands(dealResult.hands)
    }

    private static func dealHandsFromDeckCards(
        cardsPerPlayer: Int,
        playerCount: Int,
        startingPlayer: Int,
        deckCards: [Card],
        startingDeckIndex: Int
    ) -> (hands: [[Card]], nextDeckIndex: Int) {
        var hands = Array(repeating: [Card](), count: playerCount)
        var deckIndex = max(0, startingDeckIndex)

        for _ in 0..<cardsPerPlayer {
            for offset in 0..<playerCount where deckIndex < deckCards.count {
                let player = normalizedPlayerIndex(startingPlayer + offset, playerCount: playerCount)
                hands[player].append(deckCards[deckIndex])
                deckIndex += 1
            }
        }

        return (hands: hands, nextDeckIndex: deckIndex)
    }

    private static func trumpSuit(from trumpCard: Card?) -> Suit? {
        guard let trumpCard else { return nil }
        guard case .regular(let suit, _) = trumpCard else { return nil }
        return suit
    }

    private static func sortedHands(_ hands: [[Card]]) -> [[Card]] {
        return hands.map { hand in
            hand.sorted()
        }
    }

    private static func allowedBids(
        forPlayer playerIndex: Int,
        dealer: Int,
        cardsInRound: Int,
        bids: [Int],
        playerCount: Int
    ) -> [Int] {
        return BiddingRules.allowedBids(
            forPlayer: playerIndex,
            dealer: dealer,
            cardsInRound: cardsInRound,
            bids: bids,
            playerCount: playerCount
        )
    }

    private static func dealerForbiddenBid(
        forPlayer playerIndex: Int,
        dealer: Int,
        cardsInRound: Int,
        bids: [Int],
        playerCount: Int
    ) -> Int? {
        return BiddingRules.dealerForbiddenBid(
            forPlayer: playerIndex,
            dealer: dealer,
            cardsInRound: cardsInRound,
            bids: bids,
            playerCount: playerCount
        )
    }

    private static func canChooseBlindBid(
        forPlayer playerIndex: Int,
        dealer: Int,
        blindSelections: [Bool]
    ) -> Bool {
        return BiddingRules.canChooseBlindBid(
            forPlayer: playerIndex,
            dealer: dealer,
            blindSelections: blindSelections,
            playerCount: blindSelections.count
        )
    }

    private static func biddingOrder(dealer: Int, playerCount: Int) -> [Int] {
        return BiddingRules.biddingOrder(
            dealer: dealer,
            playerCount: playerCount
        )
    }

    private static func tuning(
        byApplying genome: EvolutionGenome,
        to base: BotTuning
    ) -> BotTuning {
        let baseTurn = base.turnStrategy
        let holdWeight = clamp(
            baseTurn.holdFromDistributionWeight * genome.holdDistributionScale,
            to: 0.55...0.97
        )
        let powerWeight = 1.0 - holdWeight

        let turnStrategy = BotTuning.TurnStrategy(
            utilityTieTolerance: baseTurn.utilityTieTolerance,

            chaseWinProbabilityWeight: clamp(
                baseTurn.chaseWinProbabilityWeight * genome.chaseWinProbabilityScale,
                to: 15.0...140.0
            ),
            chaseThreatPenaltyWeight: clamp(
                baseTurn.chaseThreatPenaltyWeight * genome.chaseThreatPenaltyScale,
                to: 0.02...1.20
            ),
            chaseSpendJokerPenalty: clamp(
                baseTurn.chaseSpendJokerPenalty * genome.chaseSpendJokerPenaltyScale,
                to: 5.0...220.0
            ),
            chaseLeadWishBonus: baseTurn.chaseLeadWishBonus,

            dumpAvoidWinWeight: clamp(
                baseTurn.dumpAvoidWinWeight * genome.dumpAvoidWinScale,
                to: 15.0...140.0
            ),
            dumpThreatRewardWeight: clamp(
                baseTurn.dumpThreatRewardWeight * genome.dumpThreatRewardScale,
                to: 0.01...1.50
            ),
            dumpSpendJokerPenalty: clamp(
                baseTurn.dumpSpendJokerPenalty * genome.dumpSpendJokerPenaltyScale,
                to: 5.0...220.0
            ),
            dumpFaceUpNonLeadJokerPenalty: baseTurn.dumpFaceUpNonLeadJokerPenalty,
            dumpLeadTakesNonTrumpBonus: baseTurn.dumpLeadTakesNonTrumpBonus,

            holdFromDistributionWeight: holdWeight,
            powerConfidenceWeight: powerWeight,

            futureJokerPower: clamp(
                baseTurn.futureJokerPower * genome.futureJokerPowerScale,
                to: 0.40...2.60
            ),
            futureRegularBasePower: baseTurn.futureRegularBasePower,
            futureRegularRankWeight: baseTurn.futureRegularRankWeight,
            futureTrumpBaseBonus: baseTurn.futureTrumpBaseBonus,
            futureTrumpRankWeight: baseTurn.futureTrumpRankWeight,
            futureHighRankBonus: baseTurn.futureHighRankBonus,
            futureLongSuitBonusPerCard: baseTurn.futureLongSuitBonusPerCard,
            futureTricksScale: clamp(
                baseTurn.futureTricksScale * genome.futureTricksScale,
                to: 0.20...1.35
            ),

            threatFaceDownLeadJoker: baseTurn.threatFaceDownLeadJoker,
            threatFaceDownNonLeadJoker: baseTurn.threatFaceDownNonLeadJoker,
            threatLeadTakesJoker: baseTurn.threatLeadTakesJoker,
            threatLeadAboveJoker: baseTurn.threatLeadAboveJoker,
            threatLeadWishJoker: baseTurn.threatLeadWishJoker,
            threatNonLeadFaceUpJoker: baseTurn.threatNonLeadFaceUpJoker,
            threatTrumpBonus: clamp(
                baseTurn.threatTrumpBonus * genome.threatPreservationScale,
                to: 1.0...24.0
            ),
            threatHighRankBonus: clamp(
                baseTurn.threatHighRankBonus * genome.threatPreservationScale,
                to: 0.5...12.0
            ),

            powerFaceDownJoker: baseTurn.powerFaceDownJoker,
            powerLeadTakesJoker: baseTurn.powerLeadTakesJoker,
            powerLeadAboveJoker: baseTurn.powerLeadAboveJoker,
            powerLeadWishJoker: baseTurn.powerLeadWishJoker,
            powerNonLeadFaceUpJoker: baseTurn.powerNonLeadFaceUpJoker,
            powerTrumpBonus: baseTurn.powerTrumpBonus,
            powerLeadSuitBonus: baseTurn.powerLeadSuitBonus,
            powerNormalizationValue: baseTurn.powerNormalizationValue
        )

        let baseBidding = base.bidding
        let evolvedBlindDesperateBehindThreshold = Int(
            clamp(
                Double(baseBidding.blindDesperateBehindThreshold) * genome.blindDesperateBehindThresholdScale,
                to: 100.0...700.0
            ).rounded()
        )
        let evolvedBlindCatchUpBehindThreshold = Int(
            clamp(
                Double(baseBidding.blindCatchUpBehindThreshold) * genome.blindCatchUpBehindThresholdScale,
                to: 60.0...600.0
            ).rounded()
        )
        let resolvedBlindCatchUpBehindThreshold = min(
            evolvedBlindDesperateBehindThreshold,
            evolvedBlindCatchUpBehindThreshold
        )
        let resolvedBlindSafeLeadThreshold = Int(
            clamp(
                Double(baseBidding.blindSafeLeadThreshold) * genome.blindSafeLeadThresholdScale,
                to: 80.0...800.0
            ).rounded()
        )
        let evolvedBlindCatchUpTargetShare = clamp(
            baseBidding.blindCatchUpTargetShare * genome.blindCatchUpTargetShareScale,
            to: 0.10...0.90
        )
        let evolvedBlindCatchUpConservativeTargetShare = clamp(
            baseBidding.blindCatchUpConservativeTargetShare * genome.blindCatchUpConservativeTargetShareScale,
            to: 0.05...0.85
        )
        let resolvedBlindCatchUpConservativeTargetShare = min(
            evolvedBlindCatchUpTargetShare,
            evolvedBlindCatchUpConservativeTargetShare
        )
        let evolvedBlindDesperateTargetShare = clamp(
            baseBidding.blindDesperateTargetShare * genome.blindDesperateTargetShareScale,
            to: 0.15...0.95
        )
        let resolvedBlindDesperateTargetShare = max(
            evolvedBlindCatchUpTargetShare,
            evolvedBlindDesperateTargetShare
        )
        let bidding = BotTuning.Bidding(
            expectedJokerPower: clamp(
                baseBidding.expectedJokerPower * genome.biddingJokerPowerScale,
                to: 0.40...2.60
            ),
            expectedRankWeight: clamp(
                baseBidding.expectedRankWeight * genome.biddingRankWeightScale,
                to: 0.10...1.80
            ),
            expectedTrumpBaseBonus: clamp(
                baseBidding.expectedTrumpBaseBonus * genome.biddingTrumpBaseBonusScale,
                to: 0.05...2.20
            ),
            expectedTrumpRankWeight: clamp(
                baseBidding.expectedTrumpRankWeight * genome.biddingTrumpRankWeightScale,
                to: 0.05...2.20
            ),
            expectedHighRankBonus: clamp(
                baseBidding.expectedHighRankBonus * genome.biddingHighRankBonusScale,
                to: 0.02...1.20
            ),
            expectedLongSuitBonusPerCard: clamp(
                baseBidding.expectedLongSuitBonusPerCard * genome.biddingLongSuitBonusScale,
                to: 0.02...0.95
            ),
            expectedTrumpDensityBonus: clamp(
                baseBidding.expectedTrumpDensityBonus * genome.biddingTrumpDensityBonusScale,
                to: 0.05...1.80
            ),
            expectedNoTrumpHighCardBonus: clamp(
                baseBidding.expectedNoTrumpHighCardBonus * genome.biddingNoTrumpHighCardBonusScale,
                to: 0.02...1.20
            ),
            expectedNoTrumpJokerSynergy: clamp(
                baseBidding.expectedNoTrumpJokerSynergy * genome.biddingNoTrumpJokerSynergyScale,
                to: 0.05...2.20
            ),

            blindDesperateBehindThreshold: evolvedBlindDesperateBehindThreshold,
            blindCatchUpBehindThreshold: resolvedBlindCatchUpBehindThreshold,
            blindSafeLeadThreshold: resolvedBlindSafeLeadThreshold,
            blindDesperateTargetShare: resolvedBlindDesperateTargetShare,
            blindCatchUpTargetShare: evolvedBlindCatchUpTargetShare,
            blindCatchUpConservativeTargetShare: resolvedBlindCatchUpConservativeTargetShare
        )

        let baseTrump = base.trumpSelection
        let trumpSelection = BotTuning.TrumpSelection(
            cardBasePower: clamp(
                baseTrump.cardBasePower * genome.trumpCardBasePowerScale,
                to: 0.10...1.80
            ),
            minimumPowerToDeclareTrump: clamp(
                baseTrump.minimumPowerToDeclareTrump * genome.trumpThresholdScale,
                to: 0.35...3.20
            )
        )

        return BotTuning(
            difficulty: base.difficulty,
            turnStrategy: turnStrategy,
            bidding: bidding,
            trumpSelection: trumpSelection,
            timing: base.timing
        )
    }

    private static func randomizedScale(
        _ value: Double,
        magnitude: Double,
        range: ClosedRange<Double>,
        using rng: inout SelfPlayRandomGenerator
    ) -> Double {
        let offset = (rng.nextUnit() * 2.0 - 1.0) * magnitude
        return clamp(value * (1.0 + offset), to: range)
    }

    private static func mixedScale(
        _ first: Double,
        _ second: Double,
        range: ClosedRange<Double>,
        using rng: inout SelfPlayRandomGenerator
    ) -> Double {
        let alpha = rng.nextUnit()
        let mixed = first * (1.0 - alpha) + second * alpha
        return clamp(mixed, to: range)
    }

    private static func mutateScale(
        _ value: inout Double,
        chance: Double,
        magnitude: Double,
        range: ClosedRange<Double>,
        using rng: inout SelfPlayRandomGenerator
    ) {
        guard chance > 0.0 else { return }
        guard rng.nextUnit() < chance else { return }
        value = randomizedScale(value, magnitude: magnitude, range: range, using: &rng)
    }

    private static func normalizedPlayerIndex(
        _ rawIndex: Int,
        playerCount: Int
    ) -> Int {
        guard playerCount > 0 else { return 0 }
        let remainder = rawIndex % playerCount
        return remainder >= 0 ? remainder : remainder + playerCount
    }

    private static func clamp(
        _ value: Double,
        to range: ClosedRange<Double>
    ) -> Double {
        return min(max(value, range.lowerBound), range.upperBound)
    }

    private static func isLexicographicallySmaller(
        _ lhs: [Double],
        than rhs: [Double]
    ) -> Bool {
        let comparedCount = min(lhs.count, rhs.count)
        for index in 0..<comparedCount {
            if lhs[index] == rhs[index] {
                continue
            }
            return lhs[index] < rhs[index]
        }
        return lhs.count < rhs.count
    }
}
