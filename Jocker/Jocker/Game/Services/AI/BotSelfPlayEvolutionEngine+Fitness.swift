//
//  BotSelfPlayEvolutionEngine+Fitness.swift
//  Jocker
//
//  Created by Codex on 04.03.2026.
//

import Foundation

extension BotSelfPlayEvolutionEngine {
    /// Веса и нормализации только для основной цели (winRate, scoreDiff, underbid, premiumAssist, premiumPenaltyTarget).
    struct PrimaryFitnessWeights {
        let winRateWeight: Double
        let scoreDiffWeight: Double
        let underbidLossWeight: Double
        let premiumAssistWeight: Double
        let premiumPenaltyTargetWeight: Double
        let scoreDiffNormalization: Double
        let underbidLossNormalization: Double
        let premiumAssistNormalization: Double
        let premiumPenaltyTargetNormalization: Double
    }

    /// Веса штрафов за guardrail-метрики (чем выше вклад — тем сильнее штраф за отклонение).
    struct GuardrailPenaltyWeights {
        let bidAccuracyWeight: Double
        let overbidWeight: Double
        let blindSuccessWeight: Double
        let penaltyTargetWeight: Double
        let earlyJokerSpendWeight: Double
        let leftNeighborPremiumAssistWeight: Double
        let jokerWishWinWeight: Double
    }

    /// Приемлемые диапазоны guardrail-метрик.
    /// Для метрик "higher is better" штрафуется только часть ниже минимума.
    /// Для метрик "lower is better" штрафуется только часть выше максимума.
    struct GuardrailThresholds {
        let bidAccuracyMinimum: Double
        let overbidMaximum: Double
        let blindSuccessMinimum: Double
        let penaltyTargetMaximum: Double
        let earlyJokerSpendMaximum: Double
        let leftNeighborPremiumAssistMaximum: Double
        let jokerWishWinMinimum: Double
    }

    struct FitnessBreakdown {
        /// Итоговый критерий отбора: primaryFitness - guardrailPenalty.
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

        static let zero = FitnessBreakdown(
            fitness: 0.0,
            legacyFitness: 0.0,
            primaryFitness: 0.0,
            guardrailPenalty: 0.0,
            finalFitness: 0.0,
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

    struct FitnessScoringConfig {
        let primaryWeights: PrimaryFitnessWeights
        let guardrailWeights: GuardrailPenaltyWeights
        let guardrailThresholds: GuardrailThresholds
        /// Legacy: все 7 компонент (включая trumpDensity и noTrumpControl).
        let legacyWinRateWeight: Double
        let legacyScoreDiffWeight: Double
        let legacyUnderbidLossWeight: Double
        let legacyTrumpDensityUnderbidWeight: Double
        let legacyNoTrumpControlUnderbidWeight: Double
        let legacyPremiumAssistWeight: Double
        let legacyPremiumPenaltyTargetWeight: Double
        let legacyScoreDiffNormalization: Double
        let legacyUnderbidLossNormalization: Double
        let legacyTrumpDensityUnderbidNormalization: Double
        let legacyNoTrumpControlUnderbidNormalization: Double
        let legacyPremiumAssistNormalization: Double
        let legacyPremiumPenaltyTargetNormalization: Double

        init(config: SelfPlayEvolutionConfig) {
            self.primaryWeights = PrimaryFitnessWeights(
                winRateWeight: config.fitnessWinRateWeight,
                scoreDiffWeight: config.fitnessScoreDiffWeight,
                underbidLossWeight: config.fitnessUnderbidLossWeight,
                premiumAssistWeight: config.fitnessPremiumAssistWeight,
                premiumPenaltyTargetWeight: config.fitnessPremiumPenaltyTargetWeight,
                scoreDiffNormalization: config.scoreDiffNormalization,
                underbidLossNormalization: config.underbidLossNormalization,
                premiumAssistNormalization: config.premiumAssistNormalization,
                premiumPenaltyTargetNormalization: config.premiumPenaltyTargetNormalization
            )
            self.guardrailWeights = GuardrailPenaltyWeights(
                bidAccuracyWeight: config.guardrailBidAccuracyWeight,
                overbidWeight: config.guardrailOverbidWeight,
                blindSuccessWeight: config.guardrailBlindSuccessWeight,
                penaltyTargetWeight: config.guardrailPenaltyTargetWeight,
                earlyJokerSpendWeight: config.guardrailEarlyJokerSpendWeight,
                leftNeighborPremiumAssistWeight: config.guardrailLeftNeighborPremiumAssistWeight,
                jokerWishWinWeight: config.guardrailJokerWishWinWeight
            )
            self.guardrailThresholds = GuardrailThresholds(
                bidAccuracyMinimum: config.guardrailBidAccuracyMinimum,
                overbidMaximum: config.guardrailOverbidMaximum,
                blindSuccessMinimum: config.guardrailBlindSuccessMinimum,
                penaltyTargetMaximum: config.guardrailPenaltyTargetMaximum,
                earlyJokerSpendMaximum: config.guardrailEarlyJokerSpendMaximum,
                leftNeighborPremiumAssistMaximum: config.guardrailLeftNeighborPremiumAssistMaximum,
                jokerWishWinMinimum: config.guardrailJokerWishWinMinimum
            )
            self.legacyWinRateWeight = config.fitnessWinRateWeight
            self.legacyScoreDiffWeight = config.fitnessScoreDiffWeight
            self.legacyUnderbidLossWeight = config.fitnessUnderbidLossWeight
            self.legacyTrumpDensityUnderbidWeight = config.fitnessTrumpDensityUnderbidWeight
            self.legacyNoTrumpControlUnderbidWeight = config.fitnessNoTrumpControlUnderbidWeight
            self.legacyPremiumAssistWeight = config.fitnessPremiumAssistWeight
            self.legacyPremiumPenaltyTargetWeight = config.fitnessPremiumPenaltyTargetWeight
            self.legacyScoreDiffNormalization = config.scoreDiffNormalization
            self.legacyUnderbidLossNormalization = config.underbidLossNormalization
            self.legacyTrumpDensityUnderbidNormalization = config.trumpDensityUnderbidNormalization
            self.legacyNoTrumpControlUnderbidNormalization = config.noTrumpControlUnderbidNormalization
            self.legacyPremiumAssistNormalization = config.premiumAssistNormalization
            self.legacyPremiumPenaltyTargetNormalization = config.premiumPenaltyTargetNormalization
        }

        /// Только winRate, scoreDiff, underbidLoss, premiumAssist, premiumPenaltyTarget.
        func primaryFitness(
            winRate: Double,
            averageScoreDiff: Double,
            averageUnderbidLoss: Double,
            averagePremiumAssistLoss: Double,
            averagePremiumPenaltyTargetLoss: Double
        ) -> Double {
            let w = primaryWeights
            return winRate * w.winRateWeight +
                (averageScoreDiff / w.scoreDiffNormalization) * w.scoreDiffWeight +
                -(averageUnderbidLoss / w.underbidLossNormalization) * w.underbidLossWeight +
                -(averagePremiumAssistLoss / w.premiumAssistNormalization) * w.premiumAssistWeight +
                -(averagePremiumPenaltyTargetLoss / w.premiumPenaltyTargetNormalization) * w.premiumPenaltyTargetWeight
        }

        /// Сумма штрафов по guardrail-метрикам. nil = нет данных, вклад по этой метрике 0.
        func guardrailPenalty(
            bidAccuracyRate: Double?,
            overbidRate: Double?,
            blindSuccessRate: Double?,
            penaltyTargetRate: Double?,
            earlyJokerSpendRate: Double?,
            leftNeighborPremiumAssistRate: Double?,
            jokerWishWinRate: Double?
        ) -> Double {
            let g = guardrailWeights
            let t = guardrailThresholds
            var sum = 0.0
            sum += normalizedShortfallPenalty(
                rate: bidAccuracyRate,
                minimum: t.bidAccuracyMinimum,
                weight: g.bidAccuracyWeight
            )
            sum += normalizedExcessPenalty(
                rate: overbidRate,
                maximum: t.overbidMaximum,
                weight: g.overbidWeight
            )
            sum += normalizedShortfallPenalty(
                rate: blindSuccessRate,
                minimum: t.blindSuccessMinimum,
                weight: g.blindSuccessWeight
            )
            sum += normalizedExcessPenalty(
                rate: penaltyTargetRate,
                maximum: t.penaltyTargetMaximum,
                weight: g.penaltyTargetWeight
            )
            sum += normalizedExcessPenalty(
                rate: earlyJokerSpendRate,
                maximum: t.earlyJokerSpendMaximum,
                weight: g.earlyJokerSpendWeight
            )
            sum += normalizedExcessPenalty(
                rate: leftNeighborPremiumAssistRate,
                maximum: t.leftNeighborPremiumAssistMaximum,
                weight: g.leftNeighborPremiumAssistWeight
            )
            sum += normalizedShortfallPenalty(
                rate: jokerWishWinRate,
                minimum: t.jokerWishWinMinimum,
                weight: g.jokerWishWinWeight
            )
            return sum
        }

        private func normalizedShortfallPenalty(
            rate: Double?,
            minimum: Double,
            weight: Double
        ) -> Double {
            guard weight > 0, let rate else { return 0.0 }
            guard minimum > 0 else { return 0.0 }
            let shortfall = max(0.0, minimum - rate)
            return min(1.0, shortfall / minimum) * weight
        }

        private func normalizedExcessPenalty(
            rate: Double?,
            maximum: Double,
            weight: Double
        ) -> Double {
            guard weight > 0, let rate else { return 0.0 }
            guard maximum < 1.0 else { return 0.0 }
            let excess = max(0.0, rate - maximum)
            return min(1.0, excess / max(1.0 - maximum, 1e-9)) * weight
        }

        /// Старая формула: все 7 компонент (включая trumpDensity и noTrumpControl).
        func legacyFitness(
            winRate: Double,
            averageScoreDiff: Double,
            averageUnderbidLoss: Double,
            averageTrumpDensityUnderbidLoss: Double,
            averageNoTrumpControlUnderbidLoss: Double,
            averagePremiumAssistLoss: Double,
            averagePremiumPenaltyTargetLoss: Double
        ) -> Double {
            return winRate * legacyWinRateWeight +
                (averageScoreDiff / legacyScoreDiffNormalization) * legacyScoreDiffWeight +
                -(averageUnderbidLoss / legacyUnderbidLossNormalization) * legacyUnderbidLossWeight +
                -(averageTrumpDensityUnderbidLoss / legacyTrumpDensityUnderbidNormalization) * legacyTrumpDensityUnderbidWeight +
                -(averageNoTrumpControlUnderbidLoss / legacyNoTrumpControlUnderbidNormalization) * legacyNoTrumpControlUnderbidWeight +
                -(averagePremiumAssistLoss / legacyPremiumAssistNormalization) * legacyPremiumAssistWeight +
                -(averagePremiumPenaltyTargetLoss / legacyPremiumPenaltyTargetNormalization) * legacyPremiumPenaltyTargetWeight
        }
    }

    /// Summary payload for one candidate evaluation (games × seat rotations).
    struct CandidateSummary {
        let gamesCount: Int
        let seatRotationsCount: Int
        var evaluationsCount: Int { gamesCount * seatRotationsCount }
    }

    /// Unified worker payload: fitness breakdown + aggregated simulation metrics + candidate summary.
    struct CandidateEvaluationResult {
        let fitnessBreakdown: FitnessBreakdown
        let aggregatedMetrics: SimulatedGameOutcome
        let candidateSummary: CandidateSummary
    }

    /// Неизменяемый конфиг для оценки кандидата (без сидов). Используется в evaluateCandidate для sequential и parallel.
    struct EvolutionExecutionConfig {
        let playerCount: Int
        let roundsPerGame: Int
        let cardsPerRoundRange: ClosedRange<Int>
        let useFullMatchRules: Bool
        let rotateCandidateAcrossSeats: Bool
        let fitnessScoring: FitnessScoringConfig
    }

    struct FitnessEvaluationContext {
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
        let blindSuccessRate: Double?
        let jokerWishWinRate: Double?
        let earlyJokerSpendRate: Double?
        let penaltyTargetRate: Double?
        let bidAccuracyRate: Double?
        let overbidRate: Double?
        let blindBidRateBlock4: Double
        let averageBlindBidSize: Double
        let blindBidWhenBehindRate: Double
        let blindBidWhenLeadingRate: Double
        let earlyLeadWishJokerRate: Double
        let leftNeighborPremiumAssistRate: Double?
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
        private var blindSuccessRateSamplesCount = 0
        private var totalJokerWishWinRate = 0.0
        private var jokerWishWinRateSamplesCount = 0
        private var totalEarlyJokerSpendRate = 0.0
        private var earlyJokerSpendRateSamplesCount = 0
        private var totalPenaltyTargetRate = 0.0
        private var penaltyTargetRateSamplesCount = 0
        private var totalBidAccuracyRate = 0.0
        private var bidAccuracyRateSamplesCount = 0
        private var totalOverbidRate = 0.0
        private var overbidRateSamplesCount = 0
        private var totalBlindBidRateBlock4 = 0.0
        private var totalAverageBlindBidSize = 0.0
        private var totalBlindBidWhenBehindRate = 0.0
        private var totalBlindBidWhenLeadingRate = 0.0
        private var totalEarlyLeadWishJokerRate = 0.0
        private var totalLeftNeighborPremiumAssistRate = 0.0
        private var leftNeighborPremiumAssistRateSamplesCount = 0
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
            Self.appendOptionalMetric(
                metrics.blindSuccessRate,
                total: &totalBlindSuccessRate,
                count: &blindSuccessRateSamplesCount
            )
            Self.appendOptionalMetric(
                metrics.jokerWishWinRate,
                total: &totalJokerWishWinRate,
                count: &jokerWishWinRateSamplesCount
            )
            Self.appendOptionalMetric(
                metrics.earlyJokerSpendRate,
                total: &totalEarlyJokerSpendRate,
                count: &earlyJokerSpendRateSamplesCount
            )
            Self.appendOptionalMetric(
                metrics.penaltyTargetRate,
                total: &totalPenaltyTargetRate,
                count: &penaltyTargetRateSamplesCount
            )
            Self.appendOptionalMetric(
                metrics.bidAccuracyRate,
                total: &totalBidAccuracyRate,
                count: &bidAccuracyRateSamplesCount
            )
            Self.appendOptionalMetric(
                metrics.overbidRate,
                total: &totalOverbidRate,
                count: &overbidRateSamplesCount
            )
            totalBlindBidRateBlock4 += metrics.blindBidRateBlock4
            totalAverageBlindBidSize += metrics.averageBlindBidSize
            totalBlindBidWhenBehindRate += metrics.blindBidWhenBehindRate
            totalBlindBidWhenLeadingRate += metrics.blindBidWhenLeadingRate
            totalEarlyLeadWishJokerRate += metrics.earlyLeadWishJokerRate
            Self.appendOptionalMetric(
                metrics.leftNeighborPremiumAssistRate,
                total: &totalLeftNeighborPremiumAssistRate,
                count: &leftNeighborPremiumAssistRateSamplesCount
            )
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
            let blindSuccessRate = averagedOptionalMetric(
                total: totalBlindSuccessRate,
                count: blindSuccessRateSamplesCount
            )
            let jokerWishWinRate = averagedOptionalMetric(
                total: totalJokerWishWinRate,
                count: jokerWishWinRateSamplesCount
            )
            let earlyJokerSpendRate = averagedOptionalMetric(
                total: totalEarlyJokerSpendRate,
                count: earlyJokerSpendRateSamplesCount
            )
            let penaltyTargetRate = averagedOptionalMetric(
                total: totalPenaltyTargetRate,
                count: penaltyTargetRateSamplesCount
            )
            let bidAccuracyRate = averagedOptionalMetric(
                total: totalBidAccuracyRate,
                count: bidAccuracyRateSamplesCount
            )
            let overbidRate = averagedOptionalMetric(
                total: totalOverbidRate,
                count: overbidRateSamplesCount
            )
            let blindBidRateBlock4 = totalBlindBidRateBlock4 / denominator
            let averageBlindBidSize = totalAverageBlindBidSize / denominator
            let blindBidWhenBehindRate = totalBlindBidWhenBehindRate / denominator
            let blindBidWhenLeadingRate = totalBlindBidWhenLeadingRate / denominator
            let earlyLeadWishJokerRate = totalEarlyLeadWishJokerRate / denominator
            let leftNeighborPremiumAssistRate = averagedOptionalMetric(
                total: totalLeftNeighborPremiumAssistRate,
                count: leftNeighborPremiumAssistRateSamplesCount
            )

            let legacy = fitnessScoring.legacyFitness(
                winRate: averageWinRate,
                averageScoreDiff: averageScoreDiff,
                averageUnderbidLoss: averageUnderbidLoss,
                averageTrumpDensityUnderbidLoss: averageTrumpDensityUnderbidLoss,
                averageNoTrumpControlUnderbidLoss: averageNoTrumpControlUnderbidLoss,
                averagePremiumAssistLoss: averagePremiumAssistLoss,
                averagePremiumPenaltyTargetLoss: averagePremiumPenaltyTargetLoss
            )
            let primary = fitnessScoring.primaryFitness(
                winRate: averageWinRate,
                averageScoreDiff: averageScoreDiff,
                averageUnderbidLoss: averageUnderbidLoss,
                averagePremiumAssistLoss: averagePremiumAssistLoss,
                averagePremiumPenaltyTargetLoss: averagePremiumPenaltyTargetLoss
            )
            let guardrail = fitnessScoring.guardrailPenalty(
                bidAccuracyRate: bidAccuracyRate,
                overbidRate: overbidRate,
                blindSuccessRate: blindSuccessRate,
                penaltyTargetRate: penaltyTargetRate,
                earlyJokerSpendRate: earlyJokerSpendRate,
                leftNeighborPremiumAssistRate: leftNeighborPremiumAssistRate,
                jokerWishWinRate: jokerWishWinRate
            )
            let finalFitness = primary - guardrail

            return FitnessBreakdown(
                fitness: finalFitness,
                legacyFitness: legacy,
                primaryFitness: primary,
                guardrailPenalty: guardrail,
                finalFitness: finalFitness,
                winRate: averageWinRate,
                averageScoreDiff: averageScoreDiff,
                averageUnderbidLoss: averageUnderbidLoss,
                averageTrumpDensityUnderbidLoss: averageTrumpDensityUnderbidLoss,
                averageNoTrumpControlUnderbidLoss: averageNoTrumpControlUnderbidLoss,
                averagePremiumAssistLoss: averagePremiumAssistLoss,
                averagePremiumPenaltyTargetLoss: averagePremiumPenaltyTargetLoss,
                premiumCaptureRate: premiumCaptureRate,
                blindSuccessRate: blindSuccessRate ?? 0.0,
                jokerWishWinRate: jokerWishWinRate ?? 0.0,
                earlyJokerSpendRate: earlyJokerSpendRate ?? 0.0,
                penaltyTargetRate: penaltyTargetRate ?? 0.0,
                bidAccuracyRate: bidAccuracyRate ?? 0.0,
                overbidRate: overbidRate ?? 0.0,
                blindBidRateBlock4: blindBidRateBlock4,
                averageBlindBidSize: averageBlindBidSize,
                blindBidWhenBehindRate: blindBidWhenBehindRate,
                blindBidWhenLeadingRate: blindBidWhenLeadingRate,
                earlyLeadWishJokerRate: earlyLeadWishJokerRate,
                leftNeighborPremiumAssistRate: leftNeighborPremiumAssistRate ?? 0.0
            )
        }

        private func averagedOptionalMetric(total: Double, count: Int) -> Double? {
            guard count > 0 else { return nil }
            return total / Double(count)
        }

        private static func appendOptionalMetric(
            _ value: Double?,
            total: inout Double,
            count: inout Int
        ) {
            guard let value else { return }
            total += value
            count += 1
        }
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

    private static func optionalDoubleMetricValue(
        _ values: [Double?],
        at index: Int
    ) -> Double? {
        guard values.indices.contains(index) else { return nil }
        return values[index]
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
            blindSuccessRate: optionalDoubleMetricValue(gameOutcome.blindSuccessRates, at: candidateSeat),
            jokerWishWinRate: optionalDoubleMetricValue(gameOutcome.jokerWishWinRates, at: candidateSeat),
            earlyJokerSpendRate: optionalDoubleMetricValue(gameOutcome.earlyJokerSpendRates, at: candidateSeat),
            penaltyTargetRate: optionalDoubleMetricValue(gameOutcome.penaltyTargetRates, at: candidateSeat),
            bidAccuracyRate: optionalDoubleMetricValue(gameOutcome.bidAccuracyRates, at: candidateSeat),
            overbidRate: optionalDoubleMetricValue(gameOutcome.overbidRates, at: candidateSeat),
            blindBidRateBlock4: doubleMetricValue(gameOutcome.blindBidRatesBlock4, at: candidateSeat),
            averageBlindBidSize: doubleMetricValue(gameOutcome.averageBlindBidSizes, at: candidateSeat),
            blindBidWhenBehindRate: doubleMetricValue(gameOutcome.blindBidWhenBehindRates, at: candidateSeat),
            blindBidWhenLeadingRate: doubleMetricValue(gameOutcome.blindBidWhenLeadingRates, at: candidateSeat),
            earlyLeadWishJokerRate: doubleMetricValue(gameOutcome.earlyLeadWishJokerRates, at: candidateSeat),
            leftNeighborPremiumAssistRate: optionalDoubleMetricValue(
                gameOutcome.leftNeighborPremiumAssistRates,
                at: candidateSeat
            )
        )
    }

    /// Оценка кандидата по явному списку сидов (контекст). Единый путь через evaluateCandidate.
    static func evaluateCandidateTuning(
        candidateTuning: BotTuning,
        opponentTuning: BotTuning,
        context: FitnessEvaluationContext
    ) -> FitnessBreakdown {
        let config = EvolutionExecutionConfig(
            playerCount: context.playerCount,
            roundsPerGame: context.roundsPerGame,
            cardsPerRoundRange: context.cardsPerRoundRange,
            useFullMatchRules: context.useFullMatchRules,
            rotateCandidateAcrossSeats: context.rotateCandidateAcrossSeats,
            fitnessScoring: context.fitnessScoring
        )
        let result = evaluateCandidate(
            candidateTuning: candidateTuning,
            opponentTuning: opponentTuning,
            config: config,
            baseSeeds: context.evaluationSeeds,
            generationIndex: 0,
            candidateIndex: 0
        )
        return result.fitnessBreakdown
    }

    /// Чистая единица работы: оценка одного кандидата по заданным сидам без общего mutable state.
    /// Вход: tuning кандидата, индекс поколения, индекс кандидата, base seeds, неизменяемый config.
    /// Выход: CandidateEvaluationResult (fitness + aggregated metrics + summary). Сиды выводятся детерминированно из (generationIndex, candidateIndex, gameIndex, seatRotationIndex).
    static func evaluateCandidate(
        candidateTuning: BotTuning,
        opponentTuning: BotTuning,
        config: EvolutionExecutionConfig,
        baseSeeds: [UInt64],
        generationIndex: Int,
        candidateIndex: Int
    ) -> CandidateEvaluationResult {
        guard !baseSeeds.isEmpty else {
            let emptySnapshot = SimulationMetricsSnapshot.empty(playerCount: config.playerCount)
            return CandidateEvaluationResult(
                fitnessBreakdown: .zero,
                aggregatedMetrics: emptySnapshot.toOutcome(),
                candidateSummary: CandidateSummary(gamesCount: 0, seatRotationsCount: 0)
            )
        }

        let candidateSeats = candidateSeatIndices(
            playerCount: config.playerCount,
            rotateCandidateAcrossSeats: config.rotateCandidateAcrossSeats
        )
        var accumulator = FitnessAccumulator()
        var mergedSnapshot: SimulationMetricsSnapshot?

        for (gameIndex, baseSeed) in baseSeeds.enumerated() {
            for (seatOffset, candidateSeat) in candidateSeats.enumerated() {
                let derivedSeed = BotSelfPlayEvolutionEngine.deriveEvaluationSeed(
                    baseSeed: baseSeed,
                    generationIndex: generationIndex,
                    candidateIndex: candidateIndex,
                    gameIndex: gameIndex,
                    seatRotationIndex: seatOffset
                )
                var tuningsBySeat = Array(repeating: opponentTuning, count: config.playerCount)
                tuningsBySeat[candidateSeat] = candidateTuning

                let run = simulateGame(
                    tuningsBySeat: tuningsBySeat,
                    rounds: config.roundsPerGame,
                    cardsPerRoundRange: config.cardsPerRoundRange,
                    seed: derivedSeed,
                    useFullMatchRules: config.useFullMatchRules
                )

                if let existing = mergedSnapshot {
                    mergedSnapshot = existing.merged(with: run.metricsSnapshot)
                } else {
                    mergedSnapshot = run.metricsSnapshot
                }

                guard let metrics = candidateSeatMetrics(
                    from: run.outcome,
                    candidateSeat: candidateSeat,
                    playerCount: config.playerCount
                ) else {
                    continue
                }
                accumulator.append(metrics)
            }
        }

        let fitnessBreakdown = accumulator.makeBreakdown(fitnessScoring: config.fitnessScoring)
        let aggregatedMetrics = mergedSnapshot.map { $0.toOutcome() } ?? SimulationMetricsSnapshot.empty(playerCount: config.playerCount).toOutcome()
        let summary = CandidateSummary(gamesCount: baseSeeds.count, seatRotationsCount: candidateSeats.count)

        return CandidateEvaluationResult(
            fitnessBreakdown: fitnessBreakdown,
            aggregatedMetrics: aggregatedMetrics,
            candidateSummary: summary
        )
    }

}
