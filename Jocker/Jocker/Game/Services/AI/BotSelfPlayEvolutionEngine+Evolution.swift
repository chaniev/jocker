//
//  BotSelfPlayEvolutionEngine+Evolution.swift
//  Jocker
//
//  Created by Codex on 04.03.2026.
//

import Foundation

extension BotSelfPlayEvolutionEngine {
    private final class BlockingResultBox<T>: @unchecked Sendable {
        private let lock = NSLock()
        private var value: T?

        func store(_ newValue: T) {
            lock.lock()
            value = newValue
            lock.unlock()
        }

        func load() -> T {
            lock.lock()
            defer { lock.unlock() }
            return value!
        }
    }

    /// Запускает эволюционный поиск параметров бота на серии self-play матчей (синхронная обёртка).
    static func evolveViaSelfPlay(
        baseTuning: BotTuning,
        config: SelfPlayEvolutionConfig = SelfPlayEvolutionConfig(),
        seed: UInt64 = 0x5EED,
        progress: ((SelfPlayEvolutionProgress) -> Void)? = nil
    ) -> SelfPlayEvolutionResult {
        if config.runMode == .baselineOnly {
            return evaluateBaseline(
                baseTuning: baseTuning,
                config: config,
                seed: seed,
                progress: progress
            )
        }
        return runBlocking {
            await evolveViaSelfPlayAsync(
                baseTuning: baseTuning,
                config: config,
                seed: seed,
                progress: progress
            )
        }
    }

    /// Асинхронная граница: эволюция с structured concurrency (withTaskGroup), merge по candidateIndex.
    static func evolveViaSelfPlayAsync(
        baseTuning: BotTuning,
        config: SelfPlayEvolutionConfig = SelfPlayEvolutionConfig(),
        seed: UInt64 = 0x5EED,
        progress: ((SelfPlayEvolutionProgress) -> Void)? = nil
    ) async -> SelfPlayEvolutionResult {
        if config.runMode == .baselineOnly {
            return evaluateBaseline(
                baseTuning: baseTuning,
                config: config,
                seed: seed,
                progress: progress
            )
        }

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
        let baseSeeds = makeEvaluationSeeds(
            count: config.gamesPerCandidate,
            using: &rng
        )
        let executionConfig = EvolutionExecutionConfig(
            playerCount: playerCount,
            roundsPerGame: config.roundsPerGame,
            cardsPerRoundRange: cardsRange,
            useFullMatchRules: config.useFullMatchRules,
            rotateCandidateAcrossSeats: config.rotateCandidateAcrossSeats,
            fitnessScoring: fitnessScoring
        )

        var population: [EvolutionGenome] = [.identity]
        while population.count < populationSize {
            let seededGenome = applyingEvolutionScopeMask(
                randomGenome(
                    around: .identity,
                    magnitude: max(config.mutationMagnitude, 0.08),
                    using: &rng
                ),
                config: config
            )
            population.append(seededGenome)
        }

        let runStartedAt = Date()
        let totalWorkUnits = 1 + config.generationCount * populationSize
        var completedWorkUnits = 0

        func notifyProgress(
            stage: SelfPlayEvolutionProgress.Stage,
            generationIndex: Int? = nil,
            candidateIndex: Int? = nil,
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
                    candidateIndex: candidateIndex,
                    totalGenerations: config.generationCount,
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

        let identityTuning = tuning(byApplying: .identity, to: baseTuning)
        let baselineResult = evaluateCandidate(
            candidateTuning: identityTuning,
            opponentTuning: baseTuning,
            config: executionConfig,
            baseSeeds: baseSeeds,
            generationIndex: 0,
            candidateIndex: 0
        )
        let baselineBreakdown = baselineResult.fitnessBreakdown
        completedWorkUnits += 1
        notifyProgress(
            stage: .baselineCompleted,
            currentFitness: baselineBreakdown.finalFitness,
            generationBestFitness: baselineBreakdown.finalFitness,
            overallBestFitness: baselineBreakdown.finalFitness
        )

        var bestGenome = EvolutionGenome.identity
        var bestBreakdown = baselineBreakdown
        var generationBestFitness: [Double] = []
        generationBestFitness.reserveCapacity(config.generations)
        var completedGenerations = 0
        var stoppedEarly = false
        var lastMeaningfulImprovementGeneration = 0

        let maxParallel = config.maxParallelEvaluations.resolved()

        for generation in 0..<config.generations {
            notifyProgress(
                stage: .generationStarted,
                generationIndex: generation,
                overallBestFitness: bestBreakdown.finalFitness
            )

            var scoredPopulation: [ScoredGenome]
            var generationBestFitnessSoFar: Double?

            if maxParallel <= 1 {
                scoredPopulation = []
                scoredPopulation.reserveCapacity(populationSize)
                for (candidateOffset, genome) in population.enumerated() {
                    let candidateTuning = tuning(byApplying: genome, to: baseTuning)
                    let result = evaluateCandidate(
                        candidateTuning: candidateTuning,
                        opponentTuning: baseTuning,
                        config: executionConfig,
                        baseSeeds: baseSeeds,
                        generationIndex: generation,
                        candidateIndex: candidateOffset
                    )
                    scoredPopulation.append(ScoredGenome(genome: genome, result: result))
                    completedWorkUnits += 1
                    let breakdown = result.fitnessBreakdown
                    generationBestFitnessSoFar = max(generationBestFitnessSoFar ?? breakdown.finalFitness, breakdown.finalFitness)
                    let overallBestSoFar = max(bestBreakdown.finalFitness, generationBestFitnessSoFar ?? breakdown.finalFitness)
                    notifyProgress(
                        stage: .candidateEvaluated,
                        generationIndex: generation,
                        candidateIndex: candidateOffset,
                        evaluatedCandidatesInGeneration: candidateOffset + 1,
                        currentFitness: breakdown.finalFitness,
                        generationBestFitness: generationBestFitnessSoFar,
                        overallBestFitness: overallBestSoFar
                    )
                }
            } else {
                let parallelResults = await evaluateCandidatesConcurrent(
                    population: population,
                    baseTuning: baseTuning,
                    executionConfig: executionConfig,
                    baseSeeds: baseSeeds,
                    generationIndex: generation,
                    maxParallel: maxParallel
                )
                scoredPopulation = parallelResults
                completedWorkUnits += scoredPopulation.count
                // Deterministic flush: publish progress only from coordinator, strictly by candidateIndex.
                for (idx, scored) in scoredPopulation.enumerated() {
                    let breakdown = scored.result.fitnessBreakdown
                    generationBestFitnessSoFar = max(generationBestFitnessSoFar ?? breakdown.finalFitness, breakdown.finalFitness)
                    let overallBestSoFar = max(bestBreakdown.finalFitness, generationBestFitnessSoFar ?? breakdown.finalFitness)
                    notifyProgress(
                        stage: .candidateEvaluated,
                        generationIndex: generation,
                        candidateIndex: idx,
                        evaluatedCandidatesInGeneration: idx + 1,
                        currentFitness: breakdown.finalFitness,
                        generationBestFitness: generationBestFitnessSoFar,
                        overallBestFitness: overallBestSoFar
                    )
                }
            }

            scoredPopulation.sort(by: { (lhs: ScoredGenome, rhs: ScoredGenome) -> Bool in
                    let lFinal = lhs.result.fitnessBreakdown.finalFitness
                    let rFinal = rhs.result.fitnessBreakdown.finalFitness
                    if lFinal == rFinal {
                        return isLexicographicallySmaller(
                            lhs.genome.lexicographicKey,
                            than: rhs.genome.lexicographicKey
                        )
                    }
                    return lFinal > rFinal
                })

            guard let generationBest = scoredPopulation.first else { continue }
            let generationBestBreakdown = generationBest.result.fitnessBreakdown
            generationBestFitness.append(generationBestBreakdown.finalFitness)
            completedGenerations = generation + 1

            let fitnessImprovement = generationBestBreakdown.finalFitness - bestBreakdown.finalFitness
            if generationBestBreakdown.finalFitness > bestBreakdown.finalFitness {
                bestBreakdown = generationBestBreakdown
                bestGenome = generationBest.genome
                if fitnessImprovement > config.earlyStoppingMinImprovement {
                    lastMeaningfulImprovementGeneration = completedGenerations
                }
            }
            notifyProgress(
                stage: .generationCompleted,
                generationIndex: generation,
                generationBestFitness: generationBestBreakdown.finalFitness,
                overallBestFitness: bestBreakdown.finalFitness
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
                nextPopulation.append(
                    applyingEvolutionScopeMask(
                        mutatedChild,
                        config: config
                    )
                )
            }

            population = nextPopulation
        }

        let bestTuning = tuning(byApplying: bestGenome, to: baseTuning)
        notifyProgress(
            stage: .finished,
            overallBestFitness: bestBreakdown.finalFitness
        )
        return SelfPlayEvolutionResult(
            runMode: config.runMode,
            bestTuning: bestTuning,
            baselineFitness: baselineBreakdown.finalFitness,
            bestFitness: bestBreakdown.finalFitness,
            baselineLegacyFitness: baselineBreakdown.legacyFitness,
            bestLegacyFitness: bestBreakdown.legacyFitness,
            baselinePrimaryFitness: baselineBreakdown.primaryFitness,
            bestPrimaryFitness: bestBreakdown.primaryFitness,
            baselineGuardrailPenalty: baselineBreakdown.guardrailPenalty,
            bestGuardrailPenalty: bestBreakdown.guardrailPenalty,
            baselineFinalFitness: baselineBreakdown.finalFitness,
            bestFinalFitness: bestBreakdown.finalFitness,
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

    private static func evaluateBaseline(
        baseTuning: BotTuning,
        config: SelfPlayEvolutionConfig,
        seed: UInt64,
        progress: ((SelfPlayEvolutionProgress) -> Void)?
    ) -> SelfPlayEvolutionResult {
        let playerCount = min(4, max(3, config.playerCount))
        let cardsRange = normalizedCardsPerRoundRange(
            from: config.cardsPerRoundRange,
            playerCount: playerCount
        )
        let fitnessScoring = FitnessScoringConfig(config: config)

        var rng = SelfPlayRandomGenerator(seed: seed)
        let baseSeeds = makeEvaluationSeeds(
            count: config.gamesPerCandidate,
            using: &rng
        )
        let executionConfig = EvolutionExecutionConfig(
            playerCount: playerCount,
            roundsPerGame: config.roundsPerGame,
            cardsPerRoundRange: cardsRange,
            useFullMatchRules: config.useFullMatchRules,
            rotateCandidateAcrossSeats: config.rotateCandidateAcrossSeats,
            fitnessScoring: fitnessScoring
        )

        let runStartedAt = Date()
        let totalWorkUnits = 1
        var completedWorkUnits = 0

        func notifyProgress(
            stage: SelfPlayEvolutionProgress.Stage,
            currentFitness: Double? = nil,
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
                    generationIndex: nil,
                    candidateIndex: nil,
                    totalGenerations: 0,
                    evaluatedCandidatesInGeneration: nil,
                    populationSize: 0,
                    currentFitness: currentFitness,
                    generationBestFitness: nil,
                    overallBestFitness: overallBestFitness,
                    completedWorkUnits: completedWorkUnits,
                    totalWorkUnits: totalWorkUnits,
                    elapsedSeconds: elapsed,
                    estimatedRemainingSeconds: estimatedRemaining
                )
            )
        }

        notifyProgress(stage: .started)
        let identityTuning = tuning(byApplying: .identity, to: baseTuning)
        let baselineResult = evaluateCandidate(
            candidateTuning: identityTuning,
            opponentTuning: baseTuning,
            config: executionConfig,
            baseSeeds: baseSeeds,
            generationIndex: 0,
            candidateIndex: 0
        )
        let baselineBreakdown = baselineResult.fitnessBreakdown
        completedWorkUnits = 1
        notifyProgress(
            stage: .baselineCompleted,
            currentFitness: baselineBreakdown.finalFitness,
            overallBestFitness: baselineBreakdown.finalFitness
        )
        notifyProgress(
            stage: .finished,
            overallBestFitness: baselineBreakdown.finalFitness
        )

        return SelfPlayEvolutionResult(
            runMode: config.runMode,
            bestTuning: baseTuning,
            baselineFitness: baselineBreakdown.finalFitness,
            bestFitness: baselineBreakdown.finalFitness,
            baselineLegacyFitness: baselineBreakdown.legacyFitness,
            bestLegacyFitness: baselineBreakdown.legacyFitness,
            baselinePrimaryFitness: baselineBreakdown.primaryFitness,
            bestPrimaryFitness: baselineBreakdown.primaryFitness,
            baselineGuardrailPenalty: baselineBreakdown.guardrailPenalty,
            bestGuardrailPenalty: baselineBreakdown.guardrailPenalty,
            baselineFinalFitness: baselineBreakdown.finalFitness,
            bestFinalFitness: baselineBreakdown.finalFitness,
            generationBestFitness: [],
            completedGenerations: 0,
            stoppedEarly: false,
            baselineWinRate: baselineBreakdown.winRate,
            bestWinRate: baselineBreakdown.winRate,
            baselineAverageScoreDiff: baselineBreakdown.averageScoreDiff,
            bestAverageScoreDiff: baselineBreakdown.averageScoreDiff,
            baselineAverageUnderbidLoss: baselineBreakdown.averageUnderbidLoss,
            bestAverageUnderbidLoss: baselineBreakdown.averageUnderbidLoss,
            baselineAverageTrumpDensityUnderbidLoss: baselineBreakdown.averageTrumpDensityUnderbidLoss,
            bestAverageTrumpDensityUnderbidLoss: baselineBreakdown.averageTrumpDensityUnderbidLoss,
            baselineAverageNoTrumpControlUnderbidLoss: baselineBreakdown.averageNoTrumpControlUnderbidLoss,
            bestAverageNoTrumpControlUnderbidLoss: baselineBreakdown.averageNoTrumpControlUnderbidLoss,
            baselineAveragePremiumAssistLoss: baselineBreakdown.averagePremiumAssistLoss,
            bestAveragePremiumAssistLoss: baselineBreakdown.averagePremiumAssistLoss,
            baselineAveragePremiumPenaltyTargetLoss: baselineBreakdown.averagePremiumPenaltyTargetLoss,
            bestAveragePremiumPenaltyTargetLoss: baselineBreakdown.averagePremiumPenaltyTargetLoss,
            baselinePremiumCaptureRate: baselineBreakdown.premiumCaptureRate,
            bestPremiumCaptureRate: baselineBreakdown.premiumCaptureRate,
            baselineBlindSuccessRate: baselineBreakdown.blindSuccessRate,
            bestBlindSuccessRate: baselineBreakdown.blindSuccessRate,
            baselineJokerWishWinRate: baselineBreakdown.jokerWishWinRate,
            bestJokerWishWinRate: baselineBreakdown.jokerWishWinRate,
            baselineEarlyJokerSpendRate: baselineBreakdown.earlyJokerSpendRate,
            bestEarlyJokerSpendRate: baselineBreakdown.earlyJokerSpendRate,
            baselinePenaltyTargetRate: baselineBreakdown.penaltyTargetRate,
            bestPenaltyTargetRate: baselineBreakdown.penaltyTargetRate,
            baselineBidAccuracyRate: baselineBreakdown.bidAccuracyRate,
            bestBidAccuracyRate: baselineBreakdown.bidAccuracyRate,
            baselineOverbidRate: baselineBreakdown.overbidRate,
            bestOverbidRate: baselineBreakdown.overbidRate,
            baselineBlindBidRateBlock4: baselineBreakdown.blindBidRateBlock4,
            bestBlindBidRateBlock4: baselineBreakdown.blindBidRateBlock4,
            baselineAverageBlindBidSize: baselineBreakdown.averageBlindBidSize,
            bestAverageBlindBidSize: baselineBreakdown.averageBlindBidSize,
            baselineBlindBidWhenBehindRate: baselineBreakdown.blindBidWhenBehindRate,
            bestBlindBidWhenBehindRate: baselineBreakdown.blindBidWhenBehindRate,
            baselineBlindBidWhenLeadingRate: baselineBreakdown.blindBidWhenLeadingRate,
            bestBlindBidWhenLeadingRate: baselineBreakdown.blindBidWhenLeadingRate,
            baselineEarlyLeadWishJokerRate: baselineBreakdown.earlyLeadWishJokerRate,
            bestEarlyLeadWishJokerRate: baselineBreakdown.earlyLeadWishJokerRate,
            baselineLeftNeighborPremiumAssistRate: baselineBreakdown.leftNeighborPremiumAssistRate,
            bestLeftNeighborPremiumAssistRate: baselineBreakdown.leftNeighborPremiumAssistRate
        )
    }

    private struct ScoredGenome {
        let genome: EvolutionGenome
        let result: CandidateEvaluationResult
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

    /// Детерминированная производная сида для одной симуляции (game, seat) внутри оценки кандидата.
    /// Одинаковая формула для sequential и parallel — один и тот же (gen, candidate, game, seat) даёт один и тот же сид.
    /// Не использует общий RNG; безопасно вызывать из параллельных воркеров.
    static func deriveEvaluationSeed(
        baseSeed: UInt64,
        generationIndex: Int,
        candidateIndex: Int,
        gameIndex: Int,
        seatRotationIndex: Int
    ) -> UInt64 {
        let g = UInt64(bitPattern: Int64(generationIndex))
        let c = UInt64(bitPattern: Int64(candidateIndex))
        let i = UInt64(bitPattern: Int64(gameIndex))
        let s = UInt64(bitPattern: Int64(seatRotationIndex))
        let mix = g &* 0x9E37_79B9_7F4A_7C15
            &+ c &* 0x9E37_79B9_7F4A_7C16
            &+ i &* 0x9E37_79B9_7F4A_7C17
            &+ s &* 0x9E37_79B9_7F4A_7C18
        return baseSeed ^ mix
    }

    private static func headToHeadValidationResult(
        from breakdown: FitnessBreakdown
    ) -> SelfPlayHeadToHeadValidationResult {
        return SelfPlayHeadToHeadValidationResult(
            fitness: breakdown.finalFitness,
            legacyFitness: breakdown.legacyFitness,
            primaryFitness: breakdown.primaryFitness,
            guardrailPenalty: breakdown.guardrailPenalty,
            finalFitness: breakdown.finalFitness,
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

    /// Оценка кандидатов поколения через structured concurrency; не более maxParallel задач одновременно; merge в фиксированном порядке candidateIndex.
    /// Воркеры не публикуют progress — только возвращают (candidateIndex, ScoredGenome). Coordinator затем делает deterministic flush по candidateIndex.
    private static func evaluateCandidatesConcurrent(
        population: [EvolutionGenome],
        baseTuning: BotTuning,
        executionConfig: EvolutionExecutionConfig,
        baseSeeds: [UInt64],
        generationIndex: Int,
        maxParallel: Int
    ) async -> [ScoredGenome] {
        var ordered: [ScoredGenome] = []
        ordered.reserveCapacity(population.count)
        for chunkStart in stride(from: 0, to: population.count, by: maxParallel) {
            let chunkEnd = min(chunkStart + maxParallel, population.count)
            let chunkIndices = chunkStart..<chunkEnd
            let chunkResults: [ScoredGenome] = await withTaskGroup(of: (Int, ScoredGenome).self) { group in
                for candidateOffset in chunkIndices {
                    let genome = population[candidateOffset]
                    group.addTask {
                        let candidateTuning = tuning(byApplying: genome, to: baseTuning)
                        let result = evaluateCandidate(
                            candidateTuning: candidateTuning,
                            opponentTuning: baseTuning,
                            config: executionConfig,
                            baseSeeds: baseSeeds,
                            generationIndex: generationIndex,
                            candidateIndex: candidateOffset
                        )
                        return (candidateOffset, ScoredGenome(genome: genome, result: result))
                    }
                }
                var pairs: [(Int, ScoredGenome)] = []
                for await pair in group {
                    pairs.append(pair)
                }
                return pairs.sorted(by: { $0.0 < $1.0 }).map(\.1)
            }
            ordered.append(contentsOf: chunkResults)
        }
        return ordered
    }

    /// Блокирующий запуск async-кода для синхронного API.
    private static func runBlocking<T>(_ body: @escaping () async -> T) -> T {
        let box = BlockingResultBox<T>()
        let semaphore = DispatchSemaphore(value: 0)
        Task.detached(priority: .userInitiated) {
            let value = await body()
            box.store(value)
            semaphore.signal()
        }
        semaphore.wait()
        return box.load()
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
