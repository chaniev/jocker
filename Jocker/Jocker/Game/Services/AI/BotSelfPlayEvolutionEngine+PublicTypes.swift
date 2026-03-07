//
//  BotSelfPlayEvolutionEngine+PublicTypes.swift
//  Jocker
//
//  Created by Codex on 04.03.2026.
//

import Foundation

extension BotSelfPlayEvolutionEngine {
    /// Конфигурация эволюции параметров бота через self-play.
    struct SelfPlayEvolutionConfig {
        enum RunMode: String {
            case evolution
            case baselineOnly
        }

        let runMode: RunMode
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
        /// Разрешить эволюции менять веса `turnStrategy`.
        let tuneTurnStrategy: Bool
        /// Разрешить эволюции менять веса `bidding` (включая blind sub-weights).
        let tuneBidding: Bool
        /// Разрешить эволюции менять веса `trumpSelection`.
        let tuneTrumpSelection: Bool

        init(
            runMode: RunMode = .evolution,
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
            earlyStoppingWarmupGenerations: Int = 0,
            tuneTurnStrategy: Bool = true,
            tuneBidding: Bool = true,
            tuneTrumpSelection: Bool = true
        ) {
            let normalizedLowerBound = max(
                1,
                min(cardsPerRoundRange.lowerBound, cardsPerRoundRange.upperBound)
            )
            let normalizedUpperBound = max(
                normalizedLowerBound,
                cardsPerRoundRange.upperBound
            )

            self.runMode = runMode
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
            self.tuneTurnStrategy = tuneTurnStrategy
            self.tuneBidding = tuneBidding
            self.tuneTrumpSelection = tuneTrumpSelection
        }

        var generationCount: Int {
            runMode == .baselineOnly ? 0 : generations
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
        let runMode: SelfPlayEvolutionConfig.RunMode
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
}
