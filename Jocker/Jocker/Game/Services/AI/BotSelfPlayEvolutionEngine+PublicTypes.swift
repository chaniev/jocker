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

        /// Количество параллельных оценок кандидатов внутри поколения. `auto` — по числу процессоров (с ограничением).
               enum MaxParallelEvaluations: Equatable {
            case one
            case two
            case four
            case auto

            func resolved(availableProcessors: Int = ProcessInfo.processInfo.processorCount) -> Int {
                switch self {
                case .one: return 1
                case .two: return 2
                case .four: return 4
                case .auto: return min(max(1, availableProcessors), 8)
                }
            }
        }

        let runMode: RunMode
        let maxParallelEvaluations: MaxParallelEvaluations
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
        /// Guardrail: вес штрафа за низкую точность заказа (1 - bidAccuracyRate).
        let guardrailBidAccuracyWeight: Double
        /// Guardrail: вес штрафа за перезаказ (overbidRate).
        let guardrailOverbidWeight: Double
        /// Guardrail: вес штрафа за низкий успех блайнда (1 - blindSuccessRate).
        let guardrailBlindSuccessWeight: Double
        /// Guardrail: вес штрафа за частоту цели премии (penaltyTargetRate).
        let guardrailPenaltyTargetWeight: Double
        /// Guardrail: вес штрафа за раннюю трату джокера (earlyJokerSpendRate).
        let guardrailEarlyJokerSpendWeight: Double
        /// Guardrail: вес штрафа за помощь соседу в премии (leftNeighborPremiumAssistRate).
        let guardrailLeftNeighborPremiumAssistWeight: Double
        /// Guardrail: вес штрафа за низкий выигрыш wish-джокера (1 - jokerWishWinRate).
        let guardrailJokerWishWinWeight: Double
        /// Guardrail floor: минимально приемлемая точность заказа.
        let guardrailBidAccuracyMinimum: Double
        /// Guardrail ceiling: максимально приемлемая частота перезаказа.
        let guardrailOverbidMaximum: Double
        /// Guardrail floor: минимально приемлемая успешность blind.
        let guardrailBlindSuccessMinimum: Double
        /// Guardrail ceiling: максимально приемлемая частота попадания под premium penalty.
        let guardrailPenaltyTargetMaximum: Double
        /// Guardrail ceiling: максимально приемлемая частота ранней траты джокера.
        let guardrailEarlyJokerSpendMaximum: Double
        /// Guardrail ceiling: максимально приемлемая частота помощи левому соседу в premium.
        let guardrailLeftNeighborPremiumAssistMaximum: Double
        /// Guardrail floor: минимально приемлемая успешность lead-wish джокера.
        let guardrailJokerWishWinMinimum: Double
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
        /// Разрешить эволюции менять ranking match catch-up / premium / penalty avoid.
        let tuneRankingPolicy: Bool
        /// Разрешить эволюции менять rollout activation и adjustment.
        let tuneRolloutPolicy: Bool
        /// Разрешить эволюции менять endgame activation и adjustment.
        let tuneEndgamePolicy: Bool
        /// Разрешить эволюции менять opponent modeling pressure.
        let tuneOpponentModelingPolicy: Bool
        /// Разрешить эволюции менять joker declaration utility.
        let tuneJokerDeclarationPolicy: Bool
        /// Разрешить эволюции менять фазовые множители (ranking / rollout / joker / blind).
        let tunePhasePolicy: Bool

        init(
            runMode: RunMode = .evolution,
            maxParallelEvaluations: MaxParallelEvaluations = .one,
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
            guardrailBidAccuracyWeight: Double = 0.0,
            guardrailOverbidWeight: Double = 0.0,
            guardrailBlindSuccessWeight: Double = 0.0,
            guardrailPenaltyTargetWeight: Double = 0.0,
            guardrailEarlyJokerSpendWeight: Double = 0.0,
            guardrailLeftNeighborPremiumAssistWeight: Double = 0.0,
            guardrailJokerWishWinWeight: Double = 0.0,
            guardrailBidAccuracyMinimum: Double = 1.0,
            guardrailOverbidMaximum: Double = 0.0,
            guardrailBlindSuccessMinimum: Double = 1.0,
            guardrailPenaltyTargetMaximum: Double = 0.0,
            guardrailEarlyJokerSpendMaximum: Double = 0.0,
            guardrailLeftNeighborPremiumAssistMaximum: Double = 0.0,
            guardrailJokerWishWinMinimum: Double = 1.0,
            earlyStoppingPatience: Int = 0,
            earlyStoppingMinImprovement: Double = 0.0,
            earlyStoppingWarmupGenerations: Int = 0,
            tuneTurnStrategy: Bool = true,
            tuneBidding: Bool = true,
            tuneTrumpSelection: Bool = true,
            tuneRankingPolicy: Bool = true,
            tuneRolloutPolicy: Bool = true,
            tuneEndgamePolicy: Bool = false,
            tuneOpponentModelingPolicy: Bool = true,
            tuneJokerDeclarationPolicy: Bool = false,
            tunePhasePolicy: Bool = false
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
            self.maxParallelEvaluations = maxParallelEvaluations
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
            self.guardrailBidAccuracyWeight = max(0.0, guardrailBidAccuracyWeight)
            self.guardrailOverbidWeight = max(0.0, guardrailOverbidWeight)
            self.guardrailBlindSuccessWeight = max(0.0, guardrailBlindSuccessWeight)
            self.guardrailPenaltyTargetWeight = max(0.0, guardrailPenaltyTargetWeight)
            self.guardrailEarlyJokerSpendWeight = max(0.0, guardrailEarlyJokerSpendWeight)
            self.guardrailLeftNeighborPremiumAssistWeight = max(0.0, guardrailLeftNeighborPremiumAssistWeight)
            self.guardrailJokerWishWinWeight = max(0.0, guardrailJokerWishWinWeight)
            self.guardrailBidAccuracyMinimum = SelfPlayEvolutionConfig.clamp(
                guardrailBidAccuracyMinimum,
                to: 0.0...1.0
            )
            self.guardrailOverbidMaximum = SelfPlayEvolutionConfig.clamp(
                guardrailOverbidMaximum,
                to: 0.0...1.0
            )
            self.guardrailBlindSuccessMinimum = SelfPlayEvolutionConfig.clamp(
                guardrailBlindSuccessMinimum,
                to: 0.0...1.0
            )
            self.guardrailPenaltyTargetMaximum = SelfPlayEvolutionConfig.clamp(
                guardrailPenaltyTargetMaximum,
                to: 0.0...1.0
            )
            self.guardrailEarlyJokerSpendMaximum = SelfPlayEvolutionConfig.clamp(
                guardrailEarlyJokerSpendMaximum,
                to: 0.0...1.0
            )
            self.guardrailLeftNeighborPremiumAssistMaximum = SelfPlayEvolutionConfig.clamp(
                guardrailLeftNeighborPremiumAssistMaximum,
                to: 0.0...1.0
            )
            self.guardrailJokerWishWinMinimum = SelfPlayEvolutionConfig.clamp(
                guardrailJokerWishWinMinimum,
                to: 0.0...1.0
            )
            self.earlyStoppingPatience = max(0, earlyStoppingPatience)
            self.earlyStoppingMinImprovement = max(0.0, earlyStoppingMinImprovement)
            self.earlyStoppingWarmupGenerations = max(0, earlyStoppingWarmupGenerations)
            self.tuneTurnStrategy = tuneTurnStrategy
            self.tuneBidding = tuneBidding
            self.tuneTrumpSelection = tuneTrumpSelection
            self.tuneRankingPolicy = tuneRankingPolicy
            self.tuneRolloutPolicy = tuneRolloutPolicy
            self.tuneEndgamePolicy = tuneEndgamePolicy
            self.tuneOpponentModelingPolicy = tuneOpponentModelingPolicy
            self.tuneJokerDeclarationPolicy = tuneJokerDeclarationPolicy
            self.tunePhasePolicy = tunePhasePolicy
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
        /// Legacy formula (all primary+underbid terms); для сравнения в переходный период.
        let baselineLegacyFitness: Double
        let bestLegacyFitness: Double
        /// Только winRate/scoreDiff/underbid/premiumAssist/premiumPenaltyTarget.
        let baselinePrimaryFitness: Double
        let bestPrimaryFitness: Double
        /// Сумма штрафов по guardrail-метрикам.
        let baselineGuardrailPenalty: Double
        let bestGuardrailPenalty: Double
        /// primaryFitness - guardrailPenalty; критерий отбора.
        let baselineFinalFitness: Double
        let bestFinalFitness: Double
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
        /// Итоговый fitness для сравнения (finalFitness).
        let fitness: Double
        let legacyFitness: Double
        let primaryFitness: Double
        let guardrailPenalty: Double
        let finalFitness: Double
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
    /// Progress публикуется только из coordinator-потока после deterministic flush по candidateIndex.
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
        /// Для .candidateEvaluated — индекс кандидата в поколении; порядок flush строго по этому полю.
        let candidateIndex: Int?
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
