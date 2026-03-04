//
//  BotSelfPlayEvolutionEngine+Fitness.swift
//  Jocker
//
//  Created by Codex on 04.03.2026.
//

import Foundation

extension BotSelfPlayEvolutionEngine {
    struct FitnessBreakdown {
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

    struct FitnessScoringConfig {
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

    static func evaluateCandidateTuning(
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

}
