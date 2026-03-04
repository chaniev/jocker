//
//  BotSelfPlayEvolutionEngine+Evolution.swift
//  Jocker
//
//  Created by Codex on 04.03.2026.
//

import Foundation

extension BotSelfPlayEvolutionEngine {
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
