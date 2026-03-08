//
//  BotTrainingRunner.swift
//  Jocker
//
//  Created by Codex on 07.03.2026.
//

import Foundation

struct BotTrainingRunner {
    enum EnsembleMethod: String {
        case median
        case mean
    }

    enum TuningScope: String {
        case all
        case turnStrategyOnly = "turnStrategy-only"
        case runtimePolicyOnly = "runtimePolicy-only"
    }

    struct Invocation {
        var difficulty: BotDifficulty = .hard
        var seed: UInt64 = 20_260_220
        var seedList: [UInt64] = []
        var ensembleMethod: EnsembleMethod = .median
        var runMode: BotTuning.SelfPlayEvolutionConfig.RunMode = .evolution
        var populationSize = 12
        var generations = 10
        var gamesPerCandidate = 20
        var roundsPerGame = 8
        var playerCount = 4
        var cardsMin = 2
        var cardsMax = 9
        var eliteCount = 3
        var mutationChance = 0.34
        var mutationMagnitude = 0.16
        var selectionPoolRatio = 0.55
        var tuningScope: TuningScope = .all
        var useFullMatchRules = true
        var rotateCandidateAcrossSeats = true
        var fitnessWinRateWeight = 1.0
        var fitnessScoreDiffWeight = 1.0
        var fitnessUnderbidLossWeight = 0.85
        var fitnessTrumpDensityUnderbidWeight = 0.60
        var fitnessNoTrumpControlUnderbidWeight = 0.70
        var fitnessPremiumAssistWeight = 0.55
        var fitnessPremiumPenaltyTargetWeight = 1.10
        var scoreDiffNormalization = 450.0
        var underbidLossNormalization = 6_000.0
        var trumpDensityUnderbidNormalization = 2_800.0
        var noTrumpControlUnderbidNormalization = 2_200.0
        var premiumAssistNormalization = 1_800.0
        var premiumPenaltyTargetNormalization = 1_600.0
        var guardrailBidAccuracyWeight = 0.0
        var guardrailOverbidWeight = 0.0
        var guardrailBlindSuccessWeight = 0.0
        var guardrailPenaltyTargetWeight = 0.0
        var guardrailEarlyJokerSpendWeight = 0.0
        var guardrailLeftNeighborPremiumAssistWeight = 0.0
        var guardrailJokerWishWinWeight = 0.0
        var guardrailBidAccuracyMinimum = 1.0
        var guardrailOverbidMaximum = 0.0
        var guardrailBlindSuccessMinimum = 1.0
        var guardrailPenaltyTargetMaximum = 0.0
        var guardrailEarlyJokerSpendMaximum = 0.0
        var guardrailLeftNeighborPremiumAssistMaximum = 0.0
        var guardrailJokerWishWinMinimum = 1.0
        var showProgress = true
        var progressCandidateStep = 1
        var earlyStoppingPatience = 0
        var earlyStoppingMinImprovement = 0.0
        var earlyStoppingWarmupGenerations = 0
        var abValidate = true
        var abValidationSeedList: [UInt64] = []
        var abValidationHoldoutSeedList: [UInt64] = []
        var abValidationGamesPerCandidate = 0

        var cardsPerRoundRange: ClosedRange<Int> {
            cardsMin...max(cardsMin, cardsMax)
        }

        var tuneTurnStrategy: Bool { tuningScope != .runtimePolicyOnly }
        var tuneBidding: Bool { tuningScope == .all }
        var tuneTrumpSelection: Bool { tuningScope == .all }
        var tuneRankingPolicy: Bool = true
        var tuneRolloutPolicy: Bool = true
        var tuneEndgamePolicy: Bool = false
        var tuneOpponentModelingPolicy: Bool = true
        var tuneJokerDeclarationPolicy: Bool = false

        var runSeeds: [UInt64] {
            seedList.isEmpty ? [seed] : seedList
        }

        var abValidationPrimarySeeds: [UInt64] {
            abValidationSeedList.isEmpty ? runSeeds : abValidationSeedList
        }

        var resolvedABValidationGamesPerCandidate: Int {
            abValidationGamesPerCandidate > 0
                ? abValidationGamesPerCandidate
                : gamesPerCandidate
        }
    }

    private struct SeedRun {
        let seed: UInt64
        let result: BotTuning.SelfPlayEvolutionResult
    }

    private struct ABValidationSeedRun {
        let seed: UInt64
        let bVsA: BotTuning.SelfPlayHeadToHeadValidationResult
        let aVsB: BotTuning.SelfPlayHeadToHeadValidationResult
    }

    enum RunnerError: Error {
        case usageRequested
        case message(String)

        var text: String {
            switch self {
            case .usageRequested:
                return Self.usageHint
            case .message(let message):
                return message
            }
        }

        private static let usageHint = "Use --help to show BotTrainingRunner options."
    }

    static func main(arguments: [String]) -> Int32 {
        do {
            let invocation = try parse(arguments: Array(arguments.dropFirst()))
            try run(invocation: invocation)
            return 0
        } catch RunnerError.usageRequested {
            print(usageText)
            return 0
        } catch let error as RunnerError {
            writeToStderr(error.text + "\n")
            return 1
        } catch {
            writeToStderr("Unexpected error: \(error)\n")
            return 1
        }
    }

    static var usageText: String {
        """
        Usage:
          scripts/train_bot_tuning.sh [options]

        Purpose:
          Runs offline BotTuning self-play training and prints a summary plus
          suggested tuned values. Baseline evaluation uses --run-mode baselineOnly.

        Options:
          --difficulty <easy|normal|hard>
          --seed <uint64>
          --seed-list <a,b,c>
          --ensemble-method <median|mean>
          --run-mode <evolution|baselineOnly>
          --population-size <int>
          --generations <int>
          --games-per-candidate <int>
          --rounds-per-game <int>
          --player-count <int>
          --cards-min <int>
          --cards-max <int>
          --elite-count <int>
          --mutation-chance <double>
          --mutation-magnitude <double>
          --selection-pool-ratio <double>
          --tuning-scope <all|turnStrategy-only|runtimePolicy-only>
          --use-full-match-rules <true|false>
          --rotate-candidate-across-seats <true|false>
          --fitness-win-rate-weight <double>
          --fitness-score-diff-weight <double>
          --fitness-underbid-loss-weight <double>
          --fitness-trump-density-underbid-weight <double>
          --fitness-notrump-control-underbid-weight <double>
          --fitness-premium-assist-weight <double>
          --fitness-premium-penalty-target-weight <double>
          --score-diff-normalization <double>
          --underbid-loss-normalization <double>
          --trump-density-underbid-normalization <double>
          --notrump-control-underbid-normalization <double>
          --premium-assist-normalization <double>
          --premium-penalty-target-normalization <double>
          --guardrail-bid-accuracy-weight <double>
          --guardrail-overbid-weight <double>
          --guardrail-blind-success-weight <double>
          --guardrail-penalty-target-weight <double>
          --guardrail-early-joker-spend-weight <double>
          --guardrail-left-neighbor-premium-assist-weight <double>
          --guardrail-joker-wish-win-weight <double>
          --guardrail-bid-accuracy-minimum <double>
          --guardrail-overbid-maximum <double>
          --guardrail-blind-success-minimum <double>
          --guardrail-penalty-target-maximum <double>
          --guardrail-early-joker-spend-maximum <double>
          --guardrail-left-neighbor-premium-assist-maximum <double>
          --guardrail-joker-wish-win-minimum <double>
          --show-progress <true|false>
          --progress-candidate-step <int>
          --early-stop-patience <int>
          --early-stop-min-improvement <double>
          --early-stop-warmup-generations <int>
          --ab-validate <true|false>
          --ab-validation-seed-list <a,b,c>
          --ab-validation-holdout-seed-list <a,b,c>
          --ab-validation-games-per-candidate <int>
          --tune-ranking-policy <true|false>
          --tune-rollout-policy <true|false>
          --tune-endgame-policy <true|false>
          --tune-opponent-modeling-policy <true|false>
          --tune-joker-declaration-policy <true|false>
          -h, --help

        Examples:
          scripts/train_bot_tuning.sh
          scripts/train_bot_tuning.sh --run-mode baselineOnly --seed-list 20260220,20260221
          scripts/train_bot_tuning.sh --seed 123456 --generations 4 --games-per-candidate 6
          scripts/train_bot_tuning.sh --seed-list 20260220,20260221,20260222 --ensemble-method median
        """
    }

    private static func run(invocation: Invocation) throws {
        let baseTuning = BotTuning(difficulty: invocation.difficulty)
        let config = BotTuning.SelfPlayEvolutionConfig(
            runMode: invocation.runMode,
            populationSize: invocation.populationSize,
            generations: invocation.generations,
            gamesPerCandidate: invocation.gamesPerCandidate,
            roundsPerGame: invocation.roundsPerGame,
            playerCount: invocation.playerCount,
            cardsPerRoundRange: invocation.cardsPerRoundRange,
            eliteCount: invocation.eliteCount,
            mutationChance: invocation.mutationChance,
            mutationMagnitude: invocation.mutationMagnitude,
            selectionPoolRatio: invocation.selectionPoolRatio,
            useFullMatchRules: invocation.useFullMatchRules,
            rotateCandidateAcrossSeats: invocation.rotateCandidateAcrossSeats,
            fitnessWinRateWeight: invocation.fitnessWinRateWeight,
            fitnessScoreDiffWeight: invocation.fitnessScoreDiffWeight,
            fitnessUnderbidLossWeight: invocation.fitnessUnderbidLossWeight,
            fitnessTrumpDensityUnderbidWeight: invocation.fitnessTrumpDensityUnderbidWeight,
            fitnessNoTrumpControlUnderbidWeight: invocation.fitnessNoTrumpControlUnderbidWeight,
            fitnessPremiumAssistWeight: invocation.fitnessPremiumAssistWeight,
            fitnessPremiumPenaltyTargetWeight: invocation.fitnessPremiumPenaltyTargetWeight,
            scoreDiffNormalization: invocation.scoreDiffNormalization,
            underbidLossNormalization: invocation.underbidLossNormalization,
            trumpDensityUnderbidNormalization: invocation.trumpDensityUnderbidNormalization,
            noTrumpControlUnderbidNormalization: invocation.noTrumpControlUnderbidNormalization,
            premiumAssistNormalization: invocation.premiumAssistNormalization,
            premiumPenaltyTargetNormalization: invocation.premiumPenaltyTargetNormalization,
            guardrailBidAccuracyWeight: invocation.guardrailBidAccuracyWeight,
            guardrailOverbidWeight: invocation.guardrailOverbidWeight,
            guardrailBlindSuccessWeight: invocation.guardrailBlindSuccessWeight,
            guardrailPenaltyTargetWeight: invocation.guardrailPenaltyTargetWeight,
            guardrailEarlyJokerSpendWeight: invocation.guardrailEarlyJokerSpendWeight,
            guardrailLeftNeighborPremiumAssistWeight: invocation.guardrailLeftNeighborPremiumAssistWeight,
            guardrailJokerWishWinWeight: invocation.guardrailJokerWishWinWeight,
            guardrailBidAccuracyMinimum: invocation.guardrailBidAccuracyMinimum,
            guardrailOverbidMaximum: invocation.guardrailOverbidMaximum,
            guardrailBlindSuccessMinimum: invocation.guardrailBlindSuccessMinimum,
            guardrailPenaltyTargetMaximum: invocation.guardrailPenaltyTargetMaximum,
            guardrailEarlyJokerSpendMaximum: invocation.guardrailEarlyJokerSpendMaximum,
            guardrailLeftNeighborPremiumAssistMaximum: invocation.guardrailLeftNeighborPremiumAssistMaximum,
            guardrailJokerWishWinMinimum: invocation.guardrailJokerWishWinMinimum,
            earlyStoppingPatience: invocation.earlyStoppingPatience,
            earlyStoppingMinImprovement: invocation.earlyStoppingMinImprovement,
            earlyStoppingWarmupGenerations: invocation.earlyStoppingWarmupGenerations,
            tuneTurnStrategy: invocation.tuneTurnStrategy,
            tuneBidding: invocation.tuneBidding,
            tuneTrumpSelection: invocation.tuneTrumpSelection,
            tuneRankingPolicy: invocation.tuneRankingPolicy,
            tuneRolloutPolicy: invocation.tuneRolloutPolicy,
            tuneEndgamePolicy: invocation.tuneEndgamePolicy,
            tuneOpponentModelingPolicy: invocation.tuneOpponentModelingPolicy,
            tuneJokerDeclarationPolicy: invocation.tuneJokerDeclarationPolicy
        )

        let abValidationConfig = BotTuning.SelfPlayEvolutionConfig(
            runMode: .baselineOnly,
            populationSize: config.populationSize,
            generations: 1,
            gamesPerCandidate: invocation.resolvedABValidationGamesPerCandidate,
            roundsPerGame: config.roundsPerGame,
            playerCount: config.playerCount,
            cardsPerRoundRange: config.cardsPerRoundRange,
            eliteCount: 1,
            mutationChance: 0.0,
            mutationMagnitude: 0.0,
            selectionPoolRatio: 0.5,
            useFullMatchRules: config.useFullMatchRules,
            rotateCandidateAcrossSeats: config.rotateCandidateAcrossSeats,
            fitnessWinRateWeight: config.fitnessWinRateWeight,
            fitnessScoreDiffWeight: config.fitnessScoreDiffWeight,
            fitnessUnderbidLossWeight: config.fitnessUnderbidLossWeight,
            fitnessTrumpDensityUnderbidWeight: config.fitnessTrumpDensityUnderbidWeight,
            fitnessNoTrumpControlUnderbidWeight: config.fitnessNoTrumpControlUnderbidWeight,
            fitnessPremiumAssistWeight: config.fitnessPremiumAssistWeight,
            fitnessPremiumPenaltyTargetWeight: config.fitnessPremiumPenaltyTargetWeight,
            scoreDiffNormalization: config.scoreDiffNormalization,
            underbidLossNormalization: config.underbidLossNormalization,
            trumpDensityUnderbidNormalization: config.trumpDensityUnderbidNormalization,
            noTrumpControlUnderbidNormalization: config.noTrumpControlUnderbidNormalization,
            premiumAssistNormalization: config.premiumAssistNormalization,
            premiumPenaltyTargetNormalization: config.premiumPenaltyTargetNormalization,
            guardrailBidAccuracyWeight: config.guardrailBidAccuracyWeight,
            guardrailOverbidWeight: config.guardrailOverbidWeight,
            guardrailBlindSuccessWeight: config.guardrailBlindSuccessWeight,
            guardrailPenaltyTargetWeight: config.guardrailPenaltyTargetWeight,
            guardrailEarlyJokerSpendWeight: config.guardrailEarlyJokerSpendWeight,
            guardrailLeftNeighborPremiumAssistWeight: config.guardrailLeftNeighborPremiumAssistWeight,
            guardrailJokerWishWinWeight: config.guardrailJokerWishWinWeight,
            guardrailBidAccuracyMinimum: config.guardrailBidAccuracyMinimum,
            guardrailOverbidMaximum: config.guardrailOverbidMaximum,
            guardrailBlindSuccessMinimum: config.guardrailBlindSuccessMinimum,
            guardrailPenaltyTargetMaximum: config.guardrailPenaltyTargetMaximum,
            guardrailEarlyJokerSpendMaximum: config.guardrailEarlyJokerSpendMaximum,
            guardrailLeftNeighborPremiumAssistMaximum: config.guardrailLeftNeighborPremiumAssistMaximum,
            guardrailJokerWishWinMinimum: config.guardrailJokerWishWinMinimum,
            earlyStoppingPatience: 0,
            earlyStoppingMinImprovement: 0.0,
            earlyStoppingWarmupGenerations: 0,
            tuneTurnStrategy: config.tuneTurnStrategy,
            tuneBidding: config.tuneBidding,
            tuneTrumpSelection: config.tuneTrumpSelection,
            tuneRankingPolicy: config.tuneRankingPolicy,
            tuneRolloutPolicy: config.tuneRolloutPolicy,
            tuneEndgamePolicy: config.tuneEndgamePolicy,
            tuneOpponentModelingPolicy: config.tuneOpponentModelingPolicy,
            tuneJokerDeclarationPolicy: config.tuneJokerDeclarationPolicy
        )

        let seedRuns = invocation.runSeeds.map { runSeed in
            SeedRun(
                seed: runSeed,
                result: BotTuning.evolveViaSelfPlay(
                    baseTuning: baseTuning,
                    config: config,
                    seed: runSeed,
                    progress: invocation.showProgress
                        ? { event in
                            logProgress(
                                seed: runSeed,
                                event: event,
                                candidateStep: invocation.progressCandidateStep
                            )
                        }
                        : nil
                )
            )
        }

        if invocation.showProgress {
            for run in seedRuns where run.result.stoppedEarly {
                print(
                    "[progress] seed=\(run.seed) early-stop " +
                    "generationCount=\(run.result.completedGenerations)/\(config.generationCount) " +
                    "bestFitness=\(fmt(run.result.bestFitness))"
                )
            }
        }

        guard let selectedRun = seedRuns.max(by: { $0.result.bestFitness < $1.result.bestFitness }) else {
            throw RunnerError.message("Failed to run self-play evolution.")
        }

        let tunedForOutput: BotTuning
        if seedRuns.count > 1 {
            tunedForOutput = aggregateTunings(
                seedRuns.map(\.result.bestTuning),
                method: invocation.ensembleMethod
            )
        } else {
            tunedForOutput = selectedRun.result.bestTuning
        }

        printSummary(
            invocation: invocation,
            config: config,
            seedRuns: seedRuns,
            selectedRun: selectedRun,
            baseTuning: baseTuning,
            tunedForOutput: tunedForOutput,
            abValidationConfig: abValidationConfig
        )
    }

    private static func printSummary(
        invocation: Invocation,
        config: BotTuning.SelfPlayEvolutionConfig,
        seedRuns: [SeedRun],
        selectedRun: SeedRun,
        baseTuning: BotTuning,
        tunedForOutput: BotTuning,
        abValidationConfig: BotTuning.SelfPlayEvolutionConfig
    ) {
        let turn = tunedForOutput.turnStrategy
        let bidding = tunedForOutput.bidding
        let trump = tunedForOutput.trumpSelection

        print("=== Bot Self-Play Training ===")
        print("difficulty=\(invocation.difficulty.rawValue)")
        if seedRuns.count == 1 {
            print("seed=\(selectedRun.seed)")
        } else {
            print("seedList=[\(invocation.runSeeds.map(String.init).joined(separator: ", "))]")
            print("ensembleMethod=\(invocation.ensembleMethod.rawValue)")
            print("ensembleRuns=\(seedRuns.count)")
        }
        print("mode=\(selectedRun.result.runMode.rawValue)")
        print("useFullMatchRules=\(config.useFullMatchRules)")
        print("rotateCandidateAcrossSeats=\(config.rotateCandidateAcrossSeats)")
        print("tuningScope=\(invocation.tuningScope.rawValue)")
        print(
            "tuningScopeFlags " +
            "turnStrategy=\(config.tuneTurnStrategy) " +
            "bidding=\(config.tuneBidding) " +
            "trumpSelection=\(config.tuneTrumpSelection) " +
            "rankingPolicy=\(config.tuneRankingPolicy) " +
            "rolloutPolicy=\(config.tuneRolloutPolicy) " +
            "endgamePolicy=\(config.tuneEndgamePolicy) " +
            "opponentModelingPolicy=\(config.tuneOpponentModelingPolicy) " +
            "jokerDeclarationPolicy=\(config.tuneJokerDeclarationPolicy)"
        )
        print("fitnessWinRateWeight=\(fmt(config.fitnessWinRateWeight))")
        print("fitnessScoreDiffWeight=\(fmt(config.fitnessScoreDiffWeight))")
        print("fitnessUnderbidLossWeight=\(fmt(config.fitnessUnderbidLossWeight))")
        print("fitnessTrumpDensityUnderbidWeight=\(fmt(config.fitnessTrumpDensityUnderbidWeight))")
        print("fitnessNoTrumpControlUnderbidWeight=\(fmt(config.fitnessNoTrumpControlUnderbidWeight))")
        print("fitnessPremiumAssistWeight=\(fmt(config.fitnessPremiumAssistWeight))")
        print("fitnessPremiumPenaltyTargetWeight=\(fmt(config.fitnessPremiumPenaltyTargetWeight))")
        print("scoreDiffNormalization=\(fmt(config.scoreDiffNormalization))")
        print("underbidLossNormalization=\(fmt(config.underbidLossNormalization))")
        print("trumpDensityUnderbidNormalization=\(fmt(config.trumpDensityUnderbidNormalization))")
        print("noTrumpControlUnderbidNormalization=\(fmt(config.noTrumpControlUnderbidNormalization))")
        print("premiumAssistNormalization=\(fmt(config.premiumAssistNormalization))")
        print("premiumPenaltyTargetNormalization=\(fmt(config.premiumPenaltyTargetNormalization))")
        print("guardrailBidAccuracyWeight=\(fmt(config.guardrailBidAccuracyWeight))")
        print("guardrailOverbidWeight=\(fmt(config.guardrailOverbidWeight))")
        print("guardrailBlindSuccessWeight=\(fmt(config.guardrailBlindSuccessWeight))")
        print("guardrailPenaltyTargetWeight=\(fmt(config.guardrailPenaltyTargetWeight))")
        print("guardrailEarlyJokerSpendWeight=\(fmt(config.guardrailEarlyJokerSpendWeight))")
        print("guardrailLeftNeighborPremiumAssistWeight=\(fmt(config.guardrailLeftNeighborPremiumAssistWeight))")
        print("guardrailJokerWishWinWeight=\(fmt(config.guardrailJokerWishWinWeight))")
        print("guardrailBidAccuracyMinimum=\(fmt(config.guardrailBidAccuracyMinimum))")
        print("guardrailOverbidMaximum=\(fmt(config.guardrailOverbidMaximum))")
        print("guardrailBlindSuccessMinimum=\(fmt(config.guardrailBlindSuccessMinimum))")
        print("guardrailPenaltyTargetMaximum=\(fmt(config.guardrailPenaltyTargetMaximum))")
        print("guardrailEarlyJokerSpendMaximum=\(fmt(config.guardrailEarlyJokerSpendMaximum))")
        print("guardrailLeftNeighborPremiumAssistMaximum=\(fmt(config.guardrailLeftNeighborPremiumAssistMaximum))")
        print("guardrailJokerWishWinMinimum=\(fmt(config.guardrailJokerWishWinMinimum))")
        print("showProgress=\(invocation.showProgress)")
        print("progressCandidateStep=\(invocation.progressCandidateStep)")
        print("earlyStopPatience=\(config.earlyStoppingPatience)")
        print("earlyStopMinImprovement=\(fmt(config.earlyStoppingMinImprovement))")
        print("earlyStopWarmupGenerations=\(config.earlyStoppingWarmupGenerations)")
        if seedRuns.count > 1 {
            let perSeedFitness = seedRuns
                .map { "\($0.seed):\(fmt($0.result.bestFitness))" }
                .joined(separator: ", ")
            print("perSeedBestFitness=[\(perSeedFitness)]")
            let perSeedGenerationCounts = seedRuns
                .map { "\($0.seed):\($0.result.completedGenerations)" }
                .joined(separator: ", ")
            print("perSeedGenerationCount=[\(perSeedGenerationCounts)]")
            let perSeedStoppedEarly = seedRuns
                .map { "\($0.seed):\($0.result.stoppedEarly)" }
                .joined(separator: ", ")
            print("perSeedStoppedEarly=[\(perSeedStoppedEarly)]")
            print("ensembleAverageBestFitness=\(fmt(average(seedRuns.map { $0.result.bestFitness })))")
            print("ensembleAverageBestLegacyFitness=\(fmt(average(seedRuns.map { $0.result.bestLegacyFitness })))")
            print("ensembleAverageBestPrimaryFitness=\(fmt(average(seedRuns.map { $0.result.bestPrimaryFitness })))")
            print("ensembleAverageBestGuardrailPenalty=\(fmt(average(seedRuns.map { $0.result.bestGuardrailPenalty })))")
            print("ensembleAverageBestFinalFitness=\(fmt(average(seedRuns.map { $0.result.bestFinalFitness })))")
            print("ensembleAverageBestWinRate=\(fmt(average(seedRuns.map { $0.result.bestWinRate })))")
            print("ensembleAverageBestScoreDiff=\(fmt(average(seedRuns.map { $0.result.bestAverageScoreDiff })))")
            print("ensembleAverageBestUnderbidLoss=\(fmt(average(seedRuns.map { $0.result.bestAverageUnderbidLoss })))")
            print("ensembleAverageBestTrumpDensityUnderbidLoss=\(fmt(average(seedRuns.map { $0.result.bestAverageTrumpDensityUnderbidLoss })))")
            print("ensembleAverageBestNoTrumpControlUnderbidLoss=\(fmt(average(seedRuns.map { $0.result.bestAverageNoTrumpControlUnderbidLoss })))")
            print("ensembleAverageBestPremiumAssistLoss=\(fmt(average(seedRuns.map { $0.result.bestAveragePremiumAssistLoss })))")
            print("ensembleAverageBestPremiumPenaltyTargetLoss=\(fmt(average(seedRuns.map { $0.result.bestAveragePremiumPenaltyTargetLoss })))")
            print("ensembleAverageBestPremiumCaptureRate=\(fmt(average(seedRuns.map { $0.result.bestPremiumCaptureRate })))")
            print("ensembleAverageBestBlindSuccessRate=\(fmt(average(seedRuns.map { $0.result.bestBlindSuccessRate })))")
            print("ensembleAverageBestJokerWishWinRate=\(fmt(average(seedRuns.map { $0.result.bestJokerWishWinRate })))")
            print("ensembleAverageBestEarlyJokerSpendRate=\(fmt(average(seedRuns.map { $0.result.bestEarlyJokerSpendRate })))")
            print("ensembleAverageBestPenaltyTargetRate=\(fmt(average(seedRuns.map { $0.result.bestPenaltyTargetRate })))")
            print("ensembleAverageBestBidAccuracyRate=\(fmt(average(seedRuns.map { $0.result.bestBidAccuracyRate })))")
            print("ensembleAverageBestOverbidRate=\(fmt(average(seedRuns.map { $0.result.bestOverbidRate })))")
            print("ensembleAverageBestBlindBidRateBlock4=\(fmt(average(seedRuns.map { $0.result.bestBlindBidRateBlock4 })))")
            print("ensembleAverageBestAverageBlindBidSize=\(fmt(average(seedRuns.map { $0.result.bestAverageBlindBidSize })))")
            print("ensembleAverageBestBlindBidWhenBehindRate=\(fmt(average(seedRuns.map { $0.result.bestBlindBidWhenBehindRate })))")
            print("ensembleAverageBestBlindBidWhenLeadingRate=\(fmt(average(seedRuns.map { $0.result.bestBlindBidWhenLeadingRate })))")
            print("ensembleAverageBestEarlyLeadWishJokerRate=\(fmt(average(seedRuns.map { $0.result.bestEarlyLeadWishJokerRate })))")
            print("ensembleAverageBestLeftNeighborPremiumAssistRate=\(fmt(average(seedRuns.map { $0.result.bestLeftNeighborPremiumAssistRate })))")
        }
        print("selectedSeed=\(selectedRun.seed)")
        print("baselineFitness=\(fmt(selectedRun.result.baselineFitness))")
        print("bestFitness=\(fmt(selectedRun.result.bestFitness))")
        print("baselineLegacyFitness=\(fmt(selectedRun.result.baselineLegacyFitness))")
        print("bestLegacyFitness=\(fmt(selectedRun.result.bestLegacyFitness))")
        print("baselinePrimaryFitness=\(fmt(selectedRun.result.baselinePrimaryFitness))")
        print("bestPrimaryFitness=\(fmt(selectedRun.result.bestPrimaryFitness))")
        print("baselineGuardrailPenalty=\(fmt(selectedRun.result.baselineGuardrailPenalty))")
        print("bestGuardrailPenalty=\(fmt(selectedRun.result.bestGuardrailPenalty))")
        print("baselineFinalFitness=\(fmt(selectedRun.result.baselineFinalFitness))")
        print("bestFinalFitness=\(fmt(selectedRun.result.bestFinalFitness))")
        print("improvement=\(fmt(selectedRun.result.improvement))")
        print("generationCount=\(selectedRun.result.completedGenerations)")
        print("completedGenerations=\(selectedRun.result.completedGenerations)")
        print("stoppedEarly=\(selectedRun.result.stoppedEarly)")
        print("baselineWinRate=\(fmt(selectedRun.result.baselineWinRate))")
        print("bestWinRate=\(fmt(selectedRun.result.bestWinRate))")
        print("baselineAverageScoreDiff=\(fmt(selectedRun.result.baselineAverageScoreDiff))")
        print("bestAverageScoreDiff=\(fmt(selectedRun.result.bestAverageScoreDiff))")
        print("baselineAverageUnderbidLoss=\(fmt(selectedRun.result.baselineAverageUnderbidLoss))")
        print("bestAverageUnderbidLoss=\(fmt(selectedRun.result.bestAverageUnderbidLoss))")
        print("baselineAverageTrumpDensityUnderbidLoss=\(fmt(selectedRun.result.baselineAverageTrumpDensityUnderbidLoss))")
        print("bestAverageTrumpDensityUnderbidLoss=\(fmt(selectedRun.result.bestAverageTrumpDensityUnderbidLoss))")
        print("baselineAverageNoTrumpControlUnderbidLoss=\(fmt(selectedRun.result.baselineAverageNoTrumpControlUnderbidLoss))")
        print("bestAverageNoTrumpControlUnderbidLoss=\(fmt(selectedRun.result.bestAverageNoTrumpControlUnderbidLoss))")
        print("baselineAveragePremiumAssistLoss=\(fmt(selectedRun.result.baselineAveragePremiumAssistLoss))")
        print("bestAveragePremiumAssistLoss=\(fmt(selectedRun.result.bestAveragePremiumAssistLoss))")
        print("baselineAveragePremiumPenaltyTargetLoss=\(fmt(selectedRun.result.baselineAveragePremiumPenaltyTargetLoss))")
        print("bestAveragePremiumPenaltyTargetLoss=\(fmt(selectedRun.result.bestAveragePremiumPenaltyTargetLoss))")
        print("baselinePremiumCaptureRate=\(fmt(selectedRun.result.baselinePremiumCaptureRate))")
        print("bestPremiumCaptureRate=\(fmt(selectedRun.result.bestPremiumCaptureRate))")
        print("baselineBlindSuccessRate=\(fmt(selectedRun.result.baselineBlindSuccessRate))")
        print("bestBlindSuccessRate=\(fmt(selectedRun.result.bestBlindSuccessRate))")
        print("baselineJokerWishWinRate=\(fmt(selectedRun.result.baselineJokerWishWinRate))")
        print("bestJokerWishWinRate=\(fmt(selectedRun.result.bestJokerWishWinRate))")
        print("baselineEarlyJokerSpendRate=\(fmt(selectedRun.result.baselineEarlyJokerSpendRate))")
        print("bestEarlyJokerSpendRate=\(fmt(selectedRun.result.bestEarlyJokerSpendRate))")
        print("baselinePenaltyTargetRate=\(fmt(selectedRun.result.baselinePenaltyTargetRate))")
        print("bestPenaltyTargetRate=\(fmt(selectedRun.result.bestPenaltyTargetRate))")
        print("baselineBidAccuracyRate=\(fmt(selectedRun.result.baselineBidAccuracyRate))")
        print("bestBidAccuracyRate=\(fmt(selectedRun.result.bestBidAccuracyRate))")
        print("baselineOverbidRate=\(fmt(selectedRun.result.baselineOverbidRate))")
        print("bestOverbidRate=\(fmt(selectedRun.result.bestOverbidRate))")
        print("baselineBlindBidRateBlock4=\(fmt(selectedRun.result.baselineBlindBidRateBlock4))")
        print("bestBlindBidRateBlock4=\(fmt(selectedRun.result.bestBlindBidRateBlock4))")
        print("baselineAverageBlindBidSize=\(fmt(selectedRun.result.baselineAverageBlindBidSize))")
        print("bestAverageBlindBidSize=\(fmt(selectedRun.result.bestAverageBlindBidSize))")
        print("baselineBlindBidWhenBehindRate=\(fmt(selectedRun.result.baselineBlindBidWhenBehindRate))")
        print("bestBlindBidWhenBehindRate=\(fmt(selectedRun.result.bestBlindBidWhenBehindRate))")
        print("baselineBlindBidWhenLeadingRate=\(fmt(selectedRun.result.baselineBlindBidWhenLeadingRate))")
        print("bestBlindBidWhenLeadingRate=\(fmt(selectedRun.result.bestBlindBidWhenLeadingRate))")
        print("baselineEarlyLeadWishJokerRate=\(fmt(selectedRun.result.baselineEarlyLeadWishJokerRate))")
        print("bestEarlyLeadWishJokerRate=\(fmt(selectedRun.result.bestEarlyLeadWishJokerRate))")
        print("baselineLeftNeighborPremiumAssistRate=\(fmt(selectedRun.result.baselineLeftNeighborPremiumAssistRate))")
        print("bestLeftNeighborPremiumAssistRate=\(fmt(selectedRun.result.bestLeftNeighborPremiumAssistRate))")
        print("generationBestFitness=[\(selectedRun.result.generationBestFitness.map(fmt).joined(separator: ", "))]")
        print("")
        print("=== Suggested Tuned Values ===")
        print("turnStrategy.chaseWinProbabilityWeight=\(fmt(turn.chaseWinProbabilityWeight))")
        print("turnStrategy.chaseThreatPenaltyWeight=\(fmt(turn.chaseThreatPenaltyWeight))")
        print("turnStrategy.chaseSpendJokerPenalty=\(fmt(turn.chaseSpendJokerPenalty))")
        print("turnStrategy.dumpAvoidWinWeight=\(fmt(turn.dumpAvoidWinWeight))")
        print("turnStrategy.dumpThreatRewardWeight=\(fmt(turn.dumpThreatRewardWeight))")
        print("turnStrategy.dumpSpendJokerPenalty=\(fmt(turn.dumpSpendJokerPenalty))")
        print("turnStrategy.holdFromDistributionWeight=\(fmt(turn.holdFromDistributionWeight))")
        print("turnStrategy.powerConfidenceWeight=\(fmt(turn.powerConfidenceWeight))")
        print("turnStrategy.futureJokerPower=\(fmt(turn.futureJokerPower))")
        print("turnStrategy.futureTricksScale=\(fmt(turn.futureTricksScale))")
        print("turnStrategy.threatTrumpBonus=\(fmt(turn.threatTrumpBonus))")
        print("turnStrategy.threatHighRankBonus=\(fmt(turn.threatHighRankBonus))")
        print("bidding.expectedJokerPower=\(fmt(bidding.expectedJokerPower))")
        print("bidding.expectedRankWeight=\(fmt(bidding.expectedRankWeight))")
        print("bidding.expectedTrumpBaseBonus=\(fmt(bidding.expectedTrumpBaseBonus))")
        print("bidding.expectedTrumpRankWeight=\(fmt(bidding.expectedTrumpRankWeight))")
        print("bidding.expectedHighRankBonus=\(fmt(bidding.expectedHighRankBonus))")
        print("bidding.expectedLongSuitBonusPerCard=\(fmt(bidding.expectedLongSuitBonusPerCard))")
        print("bidding.expectedTrumpDensityBonus=\(fmt(bidding.expectedTrumpDensityBonus))")
        print("bidding.expectedNoTrumpHighCardBonus=\(fmt(bidding.expectedNoTrumpHighCardBonus))")
        print("bidding.expectedNoTrumpJokerSynergy=\(fmt(bidding.expectedNoTrumpJokerSynergy))")
        print("bidding.blindDesperateBehindThreshold=\(bidding.blindDesperateBehindThreshold)")
        print("bidding.blindCatchUpBehindThreshold=\(bidding.blindCatchUpBehindThreshold)")
        print("bidding.blindSafeLeadThreshold=\(bidding.blindSafeLeadThreshold)")
        print("bidding.blindDesperateTargetShare=\(fmt(bidding.blindDesperateTargetShare))")
        print("bidding.blindCatchUpTargetShare=\(fmt(bidding.blindCatchUpTargetShare))")
        print("bidding.blindCatchUpConservativeTargetShare=\(fmt(bidding.blindCatchUpConservativeTargetShare))")
        print("trumpSelection.cardBasePower=\(fmt(trump.cardBasePower))")
        print("trumpSelection.minimumPowerToDeclareTrump=\(fmt(trump.minimumPowerToDeclareTrump))")
        print("trumpSelection.playerChosenPairBonus=\(fmt(trump.playerChosenPairBonus))")
        print("trumpSelection.lengthBonusPerExtraCard=\(fmt(trump.lengthBonusPerExtraCard))")
        print("trumpSelection.densityBonusWeight=\(fmt(trump.densityBonusWeight))")
        print("trumpSelection.sequenceBonusWeight=\(fmt(trump.sequenceBonusWeight))")
        print("trumpSelection.controlBonusWeight=\(fmt(trump.controlBonusWeight))")
        print("trumpSelection.jokerSynergyBase=\(fmt(trump.jokerSynergyBase))")
        print("trumpSelection.jokerSynergyControlWeight=\(fmt(trump.jokerSynergyControlWeight))")
        print("")
        let baselinePolicy = BotRuntimePolicy.preset(for: invocation.difficulty)
        let tunedPolicy = tunedForOutput.runtimePolicy
        let effectiveRuntimePolicyPatch = BotSelfPlayEvolutionEngine.runtimePolicyPatch(
            from: tunedPolicy,
            relativeTo: baselinePolicy
        )
        print("=== Runtime Policy Genes ===")
        print("runtimeGeneSource=\(invocation.runSeeds.count > 1 ? "ensembleAggregate" : "selectedSeed")")
        logRuntimePolicyPatchMetrics(effectiveRuntimePolicyPatch)
        print("")
        print("=== Runtime Policy Patch (diff vs baseline) ===")
        logRuntimePolicyDiffs(
            baseline: baselinePolicy,
            tuned: tunedPolicy
        )
        print("")
        print("=== Post-Training A/B Validation ===")
        print("abValidate=\(invocation.abValidate)")
        if invocation.abValidate {
            print("abValidationGamesPerCandidate=\(abValidationConfig.gamesPerCandidate)")
            print("abValidationPrimarySeeds=[\(invocation.abValidationPrimarySeeds.map(String.init).joined(separator: ", "))]")
            if invocation.abValidationHoldoutSeedList.isEmpty {
                print("abValidationHoldoutSeeds=[]")
            } else {
                print("abValidationHoldoutSeeds=[\(invocation.abValidationHoldoutSeedList.map(String.init).joined(separator: ", "))]")
            }
            print("")
            logABValidationSet(
                label: "primary",
                seeds: invocation.abValidationPrimarySeeds,
                baseTuning: baseTuning,
                tunedTuning: tunedForOutput,
                config: abValidationConfig
            )
            if !invocation.abValidationHoldoutSeedList.isEmpty {
                logABValidationSet(
                    label: "holdout",
                    seeds: invocation.abValidationHoldoutSeedList,
                    baseTuning: baseTuning,
                    tunedTuning: tunedForOutput,
                    config: abValidationConfig
                )
            }
        }
    }

    private static func parse(arguments: [String]) throws -> Invocation {
        var invocation = Invocation()
        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
            case "-h", "--help":
                throw RunnerError.usageRequested
            case "--difficulty":
                invocation.difficulty = try parseDifficulty(
                    try value(after: argument, in: arguments, at: &index)
                )
            case "--seed":
                invocation.seed = try parseUInt64(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument
                )
            case "--seed-list":
                invocation.seedList = try parseSeedList(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument
                )
            case "--ensemble-method":
                invocation.ensembleMethod = try parseEnum(
                    EnsembleMethod.self,
                    value: try value(after: argument, in: arguments, at: &index),
                    flag: argument
                )
            case "--run-mode":
                invocation.runMode = try parseEnum(
                    BotTuning.SelfPlayEvolutionConfig.RunMode.self,
                    value: try value(after: argument, in: arguments, at: &index),
                    flag: argument
                )
            case "--population-size":
                invocation.populationSize = try parseInt(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 2
                )
            case "--generations":
                invocation.generations = try parseInt(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 1
                )
            case "--games-per-candidate":
                invocation.gamesPerCandidate = try parseInt(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 1
                )
            case "--rounds-per-game":
                invocation.roundsPerGame = try parseInt(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 1
                )
            case "--player-count":
                invocation.playerCount = try parseInt(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 3
                )
            case "--cards-min":
                invocation.cardsMin = try parseInt(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 1
                )
            case "--cards-max":
                invocation.cardsMax = try parseInt(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 1
                )
            case "--elite-count":
                invocation.eliteCount = try parseInt(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 1
                )
            case "--mutation-chance":
                invocation.mutationChance = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0
                )
            case "--mutation-magnitude":
                invocation.mutationMagnitude = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0
                )
            case "--selection-pool-ratio":
                invocation.selectionPoolRatio = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0
                )
            case "--tuning-scope":
                invocation.tuningScope = try parseEnum(
                    TuningScope.self,
                    value: try value(after: argument, in: arguments, at: &index),
                    flag: argument
                )
            case "--use-full-match-rules":
                invocation.useFullMatchRules = try parseBool(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument
                )
            case "--rotate-candidate-across-seats":
                invocation.rotateCandidateAcrossSeats = try parseBool(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument
                )
            case "--fitness-win-rate-weight":
                invocation.fitnessWinRateWeight = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0
                )
            case "--fitness-score-diff-weight":
                invocation.fitnessScoreDiffWeight = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0
                )
            case "--fitness-underbid-loss-weight":
                invocation.fitnessUnderbidLossWeight = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0
                )
            case "--fitness-trump-density-underbid-weight":
                invocation.fitnessTrumpDensityUnderbidWeight = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0
                )
            case "--fitness-notrump-control-underbid-weight":
                invocation.fitnessNoTrumpControlUnderbidWeight = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0
                )
            case "--fitness-premium-assist-weight":
                invocation.fitnessPremiumAssistWeight = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0
                )
            case "--fitness-premium-penalty-target-weight":
                invocation.fitnessPremiumPenaltyTargetWeight = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0
                )
            case "--score-diff-normalization":
                invocation.scoreDiffNormalization = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 1.0
                )
            case "--underbid-loss-normalization":
                invocation.underbidLossNormalization = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 1.0
                )
            case "--trump-density-underbid-normalization":
                invocation.trumpDensityUnderbidNormalization = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 1.0
                )
            case "--notrump-control-underbid-normalization":
                invocation.noTrumpControlUnderbidNormalization = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 1.0
                )
            case "--premium-assist-normalization":
                invocation.premiumAssistNormalization = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 1.0
                )
            case "--premium-penalty-target-normalization":
                invocation.premiumPenaltyTargetNormalization = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 1.0
                )
            case "--guardrail-bid-accuracy-weight":
                invocation.guardrailBidAccuracyWeight = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0
                )
            case "--guardrail-overbid-weight":
                invocation.guardrailOverbidWeight = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0
                )
            case "--guardrail-blind-success-weight":
                invocation.guardrailBlindSuccessWeight = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0
                )
            case "--guardrail-penalty-target-weight":
                invocation.guardrailPenaltyTargetWeight = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0
                )
            case "--guardrail-early-joker-spend-weight":
                invocation.guardrailEarlyJokerSpendWeight = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0
                )
            case "--guardrail-left-neighbor-premium-assist-weight":
                invocation.guardrailLeftNeighborPremiumAssistWeight = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0
                )
            case "--guardrail-joker-wish-win-weight":
                invocation.guardrailJokerWishWinWeight = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0
                )
            case "--guardrail-bid-accuracy-minimum":
                invocation.guardrailBidAccuracyMinimum = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0,
                    maximum: 1.0
                )
            case "--guardrail-overbid-maximum":
                invocation.guardrailOverbidMaximum = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0,
                    maximum: 1.0
                )
            case "--guardrail-blind-success-minimum":
                invocation.guardrailBlindSuccessMinimum = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0,
                    maximum: 1.0
                )
            case "--guardrail-penalty-target-maximum":
                invocation.guardrailPenaltyTargetMaximum = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0,
                    maximum: 1.0
                )
            case "--guardrail-early-joker-spend-maximum":
                invocation.guardrailEarlyJokerSpendMaximum = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0,
                    maximum: 1.0
                )
            case "--guardrail-left-neighbor-premium-assist-maximum":
                invocation.guardrailLeftNeighborPremiumAssistMaximum = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0,
                    maximum: 1.0
                )
            case "--guardrail-joker-wish-win-minimum":
                invocation.guardrailJokerWishWinMinimum = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0,
                    maximum: 1.0
                )
            case "--show-progress":
                invocation.showProgress = try parseBool(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument
                )
            case "--progress-candidate-step":
                invocation.progressCandidateStep = try parseInt(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 1
                )
            case "--early-stop-patience":
                invocation.earlyStoppingPatience = try parseInt(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0
                )
            case "--early-stop-min-improvement":
                invocation.earlyStoppingMinImprovement = try parseDouble(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0.0
                )
            case "--early-stop-warmup-generations":
                invocation.earlyStoppingWarmupGenerations = try parseInt(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0
                )
            case "--ab-validate":
                invocation.abValidate = try parseBool(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument
                )
            case "--ab-validation-seed-list":
                invocation.abValidationSeedList = try parseSeedList(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument
                )
            case "--ab-validation-holdout-seed-list":
                invocation.abValidationHoldoutSeedList = try parseSeedList(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument
                )
            case "--ab-validation-games-per-candidate":
                invocation.abValidationGamesPerCandidate = try parseInt(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument,
                    minimum: 0
                )
            case "--tune-ranking-policy":
                invocation.tuneRankingPolicy = try parseBool(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument
                )
            case "--tune-rollout-policy":
                invocation.tuneRolloutPolicy = try parseBool(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument
                )
            case "--tune-endgame-policy":
                invocation.tuneEndgamePolicy = try parseBool(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument
                )
            case "--tune-opponent-modeling-policy":
                invocation.tuneOpponentModelingPolicy = try parseBool(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument
                )
            case "--tune-joker-declaration-policy":
                invocation.tuneJokerDeclarationPolicy = try parseBool(
                    try value(after: argument, in: arguments, at: &index),
                    flag: argument
                )
            default:
                throw RunnerError.message("Unknown option: \(argument)")
            }
            index += 1
        }

        return invocation
    }

    private static func logABValidationSet(
        label: String,
        seeds: [UInt64],
        baseTuning: BotTuning,
        tunedTuning: BotTuning,
        config: BotTuning.SelfPlayEvolutionConfig
    ) {
        guard !seeds.isEmpty else { return }

        print("=== A/B Validation :: \(label) ===")
        print(
            "gamesPerCandidate=\(config.gamesPerCandidate) " +
            "useFullMatchRules=\(config.useFullMatchRules) " +
            "rotateCandidateAcrossSeats=\(config.rotateCandidateAcrossSeats)"
        )
        print("A=basePreset B=tunedOutput")

        var runs: [ABValidationSeedRun] = []
        runs.reserveCapacity(seeds.count)

        for seed in seeds {
            let bVsA = BotTuning.evaluateHeadToHead(
                candidateTuning: tunedTuning,
                opponentTuning: baseTuning,
                config: config,
                seed: seed
            )
            let aVsB = BotTuning.evaluateHeadToHead(
                candidateTuning: baseTuning,
                opponentTuning: tunedTuning,
                config: config,
                seed: seed
            )
            runs.append(
                ABValidationSeedRun(
                    seed: seed,
                    bVsA: bVsA,
                    aVsB: aVsB
                )
            )
            print(
                "seed=\(seed) " +
                "finalFitness BvA=\(fmt(bVsA.finalFitness)) AvB=\(fmt(aVsB.finalFitness)) Badv=\(fmt(bVsA.finalFitness - aVsB.finalFitness)) | " +
                "legacyFitness BvA=\(fmt(bVsA.legacyFitness)) AvB=\(fmt(aVsB.legacyFitness)) | " +
                "primaryFitness BvA=\(fmt(bVsA.primaryFitness)) AvB=\(fmt(aVsB.primaryFitness)) | " +
                "guardrailPenalty BvA=\(fmt(bVsA.guardrailPenalty)) AvB=\(fmt(aVsB.guardrailPenalty)) | " +
                "wr BvA=\(fmt(bVsA.winRate)) AvB=\(fmt(aVsB.winRate)) Badv=\(fmt(bVsA.winRate - aVsB.winRate)) | " +
                "scoreDiff BvA=\(fmt(bVsA.averageScoreDiff)) AvB=\(fmt(aVsB.averageScoreDiff)) Badv=\(fmt(bVsA.averageScoreDiff - aVsB.averageScoreDiff))"
            )
        }

        let bVaFitnessValues = runs.map(\.bVsA.finalFitness)
        let aVbFitnessValues = runs.map(\.aVsB.finalFitness)
        let bVaWinRateValues = runs.map(\.bVsA.winRate)
        let aVbWinRateValues = runs.map(\.aVsB.winRate)
        let bVaScoreDiffValues = runs.map(\.bVsA.averageScoreDiff)
        let aVbScoreDiffValues = runs.map(\.aVsB.averageScoreDiff)
        let bVaUnderbidValues = runs.map(\.bVsA.averageUnderbidLoss)
        let aVbUnderbidValues = runs.map(\.aVsB.averageUnderbidLoss)
        let bVaTrumpDensityValues = runs.map(\.bVsA.averageTrumpDensityUnderbidLoss)
        let aVbTrumpDensityValues = runs.map(\.aVsB.averageTrumpDensityUnderbidLoss)
        let bVaNoTrumpControlValues = runs.map(\.bVsA.averageNoTrumpControlUnderbidLoss)
        let aVbNoTrumpControlValues = runs.map(\.aVsB.averageNoTrumpControlUnderbidLoss)
        let bVaPremiumAssistValues = runs.map(\.bVsA.averagePremiumAssistLoss)
        let aVbPremiumAssistValues = runs.map(\.aVsB.averagePremiumAssistLoss)
        let bVaPremiumPenaltyValues = runs.map(\.bVsA.averagePremiumPenaltyTargetLoss)
        let aVbPremiumPenaltyValues = runs.map(\.aVsB.averagePremiumPenaltyTargetLoss)
        let bVaPremiumCaptureRateValues = runs.map(\.bVsA.premiumCaptureRate)
        let aVbPremiumCaptureRateValues = runs.map(\.aVsB.premiumCaptureRate)
        let bVaBlindSuccessRateValues = runs.map(\.bVsA.blindSuccessRate)
        let aVbBlindSuccessRateValues = runs.map(\.aVsB.blindSuccessRate)
        let bVaJokerWishWinRateValues = runs.map(\.bVsA.jokerWishWinRate)
        let aVbJokerWishWinRateValues = runs.map(\.aVsB.jokerWishWinRate)
        let bVaEarlyJokerSpendRateValues = runs.map(\.bVsA.earlyJokerSpendRate)
        let aVbEarlyJokerSpendRateValues = runs.map(\.aVsB.earlyJokerSpendRate)
        let bVaPenaltyTargetRateValues = runs.map(\.bVsA.penaltyTargetRate)
        let aVbPenaltyTargetRateValues = runs.map(\.aVsB.penaltyTargetRate)
        let bVaBidAccuracyRateValues = runs.map(\.bVsA.bidAccuracyRate)
        let aVbBidAccuracyRateValues = runs.map(\.aVsB.bidAccuracyRate)
        let bVaOverbidRateValues = runs.map(\.bVsA.overbidRate)
        let aVbOverbidRateValues = runs.map(\.aVsB.overbidRate)
        let bVaBlindBidRateBlock4Values = runs.map(\.bVsA.blindBidRateBlock4)
        let aVbBlindBidRateBlock4Values = runs.map(\.aVsB.blindBidRateBlock4)
        let bVaAverageBlindBidSizeValues = runs.map(\.bVsA.averageBlindBidSize)
        let aVbAverageBlindBidSizeValues = runs.map(\.aVsB.averageBlindBidSize)
        let bVaBlindBidWhenBehindRateValues = runs.map(\.bVsA.blindBidWhenBehindRate)
        let aVbBlindBidWhenBehindRateValues = runs.map(\.aVsB.blindBidWhenBehindRate)
        let bVaBlindBidWhenLeadingRateValues = runs.map(\.bVsA.blindBidWhenLeadingRate)
        let aVbBlindBidWhenLeadingRateValues = runs.map(\.aVsB.blindBidWhenLeadingRate)
        let bVaEarlyLeadWishJokerRateValues = runs.map(\.bVsA.earlyLeadWishJokerRate)
        let aVbEarlyLeadWishJokerRateValues = runs.map(\.aVsB.earlyLeadWishJokerRate)
        let bVaLeftNeighborPremiumAssistRateValues = runs.map(\.bVsA.leftNeighborPremiumAssistRate)
        let aVbLeftNeighborPremiumAssistRateValues = runs.map(\.aVsB.leftNeighborPremiumAssistRate)

        let fitnessDeltaValues = zip(bVaFitnessValues, aVbFitnessValues).map(-)
        let winRateDeltaValues = zip(bVaWinRateValues, aVbWinRateValues).map(-)
        let scoreDiffDeltaValues = zip(bVaScoreDiffValues, aVbScoreDiffValues).map(-)
        let underbidDeltaValues = zip(bVaUnderbidValues, aVbUnderbidValues).map(-)
        let trumpDensityDeltaValues = zip(bVaTrumpDensityValues, aVbTrumpDensityValues).map(-)
        let noTrumpControlDeltaValues = zip(bVaNoTrumpControlValues, aVbNoTrumpControlValues).map(-)
        let premiumAssistDeltaValues = zip(bVaPremiumAssistValues, aVbPremiumAssistValues).map(-)
        let premiumPenaltyDeltaValues = zip(bVaPremiumPenaltyValues, aVbPremiumPenaltyValues).map(-)
        let premiumCaptureRateDeltaValues = zip(bVaPremiumCaptureRateValues, aVbPremiumCaptureRateValues).map(-)
        let blindSuccessRateDeltaValues = zip(bVaBlindSuccessRateValues, aVbBlindSuccessRateValues).map(-)
        let jokerWishWinRateDeltaValues = zip(bVaJokerWishWinRateValues, aVbJokerWishWinRateValues).map(-)
        let earlyJokerSpendRateDeltaValues = zip(bVaEarlyJokerSpendRateValues, aVbEarlyJokerSpendRateValues).map(-)
        let penaltyTargetRateDeltaValues = zip(bVaPenaltyTargetRateValues, aVbPenaltyTargetRateValues).map(-)
        let bidAccuracyRateDeltaValues = zip(bVaBidAccuracyRateValues, aVbBidAccuracyRateValues).map(-)
        let overbidRateDeltaValues = zip(bVaOverbidRateValues, aVbOverbidRateValues).map(-)
        let blindBidRateBlock4DeltaValues = zip(bVaBlindBidRateBlock4Values, aVbBlindBidRateBlock4Values).map(-)
        let averageBlindBidSizeDeltaValues = zip(bVaAverageBlindBidSizeValues, aVbAverageBlindBidSizeValues).map(-)
        let blindBidWhenBehindRateDeltaValues = zip(bVaBlindBidWhenBehindRateValues, aVbBlindBidWhenBehindRateValues).map(-)
        let blindBidWhenLeadingRateDeltaValues = zip(bVaBlindBidWhenLeadingRateValues, aVbBlindBidWhenLeadingRateValues).map(-)
        let earlyLeadWishJokerRateDeltaValues = zip(bVaEarlyLeadWishJokerRateValues, aVbEarlyLeadWishJokerRateValues).map(-)
        let leftNeighborPremiumAssistRateDeltaValues = zip(bVaLeftNeighborPremiumAssistRateValues, aVbLeftNeighborPremiumAssistRateValues).map(-)

        print("summary.mean finalFitness BvA=\(fmt(average(bVaFitnessValues))) AvB=\(fmt(average(aVbFitnessValues))) Badv=\(fmt(average(fitnessDeltaValues)))")
        let bVaLegacyValues = runs.map(\.bVsA.legacyFitness)
        let aVbLegacyValues = runs.map(\.aVsB.legacyFitness)
        let bVaPrimaryValues = runs.map(\.bVsA.primaryFitness)
        let aVbPrimaryValues = runs.map(\.aVsB.primaryFitness)
        let bVaGuardrailValues = runs.map(\.bVsA.guardrailPenalty)
        let aVbGuardrailValues = runs.map(\.aVsB.guardrailPenalty)
        print("summary.mean legacyFitness BvA=\(fmt(average(bVaLegacyValues))) AvB=\(fmt(average(aVbLegacyValues)))")
        print("summary.mean primaryFitness BvA=\(fmt(average(bVaPrimaryValues))) AvB=\(fmt(average(aVbPrimaryValues)))")
        print("summary.mean guardrailPenalty BvA=\(fmt(average(bVaGuardrailValues))) AvB=\(fmt(average(aVbGuardrailValues)))")
        print("summary.mean winRate BvA=\(fmt(average(bVaWinRateValues))) AvB=\(fmt(average(aVbWinRateValues))) Badv=\(fmt(average(winRateDeltaValues)))")
        print("summary.mean scoreDiff BvA=\(fmt(average(bVaScoreDiffValues))) AvB=\(fmt(average(aVbScoreDiffValues))) Badv=\(fmt(average(scoreDiffDeltaValues)))")
        print("summary.mean underbidLoss BvA=\(fmt(average(bVaUnderbidValues))) AvB=\(fmt(average(aVbUnderbidValues))) Badv=\(fmt(average(underbidDeltaValues)))")
        print("summary.mean trumpDensityUnderbidLoss BvA=\(fmt(average(bVaTrumpDensityValues))) AvB=\(fmt(average(aVbTrumpDensityValues))) Badv=\(fmt(average(trumpDensityDeltaValues)))")
        print("summary.mean noTrumpControlUnderbidLoss BvA=\(fmt(average(bVaNoTrumpControlValues))) AvB=\(fmt(average(aVbNoTrumpControlValues))) Badv=\(fmt(average(noTrumpControlDeltaValues)))")
        print("summary.mean premiumAssistLoss BvA=\(fmt(average(bVaPremiumAssistValues))) AvB=\(fmt(average(aVbPremiumAssistValues))) Badv=\(fmt(average(premiumAssistDeltaValues)))")
        print("summary.mean premiumPenaltyTargetLoss BvA=\(fmt(average(bVaPremiumPenaltyValues))) AvB=\(fmt(average(aVbPremiumPenaltyValues))) Badv=\(fmt(average(premiumPenaltyDeltaValues)))")
        print("summary.mean premiumCaptureRate BvA=\(fmt(average(bVaPremiumCaptureRateValues))) AvB=\(fmt(average(aVbPremiumCaptureRateValues))) Badv=\(fmt(average(premiumCaptureRateDeltaValues)))")
        print("summary.mean blindSuccessRate BvA=\(fmt(average(bVaBlindSuccessRateValues))) AvB=\(fmt(average(aVbBlindSuccessRateValues))) Badv=\(fmt(average(blindSuccessRateDeltaValues)))")
        print("summary.mean jokerWishWinRate BvA=\(fmt(average(bVaJokerWishWinRateValues))) AvB=\(fmt(average(aVbJokerWishWinRateValues))) Badv=\(fmt(average(jokerWishWinRateDeltaValues)))")
        print("summary.mean earlyJokerSpendRate BvA=\(fmt(average(bVaEarlyJokerSpendRateValues))) AvB=\(fmt(average(aVbEarlyJokerSpendRateValues))) Badv=\(fmt(average(earlyJokerSpendRateDeltaValues)))")
        print("summary.mean penaltyTargetRate BvA=\(fmt(average(bVaPenaltyTargetRateValues))) AvB=\(fmt(average(aVbPenaltyTargetRateValues))) Badv=\(fmt(average(penaltyTargetRateDeltaValues)))")
        print("summary.mean bidAccuracyRate BvA=\(fmt(average(bVaBidAccuracyRateValues))) AvB=\(fmt(average(aVbBidAccuracyRateValues))) Badv=\(fmt(average(bidAccuracyRateDeltaValues)))")
        print("summary.mean overbidRate BvA=\(fmt(average(bVaOverbidRateValues))) AvB=\(fmt(average(aVbOverbidRateValues))) Badv=\(fmt(average(overbidRateDeltaValues)))")
        print("summary.mean blindBidRateBlock4 BvA=\(fmt(average(bVaBlindBidRateBlock4Values))) AvB=\(fmt(average(aVbBlindBidRateBlock4Values))) Badv=\(fmt(average(blindBidRateBlock4DeltaValues)))")
        print("summary.mean averageBlindBidSize BvA=\(fmt(average(bVaAverageBlindBidSizeValues))) AvB=\(fmt(average(aVbAverageBlindBidSizeValues))) Badv=\(fmt(average(averageBlindBidSizeDeltaValues)))")
        print("summary.mean blindBidWhenBehindRate BvA=\(fmt(average(bVaBlindBidWhenBehindRateValues))) AvB=\(fmt(average(aVbBlindBidWhenBehindRateValues))) Badv=\(fmt(average(blindBidWhenBehindRateDeltaValues)))")
        print("summary.mean blindBidWhenLeadingRate BvA=\(fmt(average(bVaBlindBidWhenLeadingRateValues))) AvB=\(fmt(average(aVbBlindBidWhenLeadingRateValues))) Badv=\(fmt(average(blindBidWhenLeadingRateDeltaValues)))")
        print("summary.mean earlyLeadWishJokerRate BvA=\(fmt(average(bVaEarlyLeadWishJokerRateValues))) AvB=\(fmt(average(aVbEarlyLeadWishJokerRateValues))) Badv=\(fmt(average(earlyLeadWishJokerRateDeltaValues)))")
        print("summary.mean leftNeighborPremiumAssistRate BvA=\(fmt(average(bVaLeftNeighborPremiumAssistRateValues))) AvB=\(fmt(average(aVbLeftNeighborPremiumAssistRateValues))) Badv=\(fmt(average(leftNeighborPremiumAssistRateDeltaValues)))")
        print("")
    }

    private static func logRuntimePolicyPatchMetrics(
        _ patch: BotSelfPlayEvolutionEngine.RuntimePolicyEvolutionPatch
    ) {
        print("runtimeGene.rankingMatchCatchUpScale=\(fmt(patch.rankingMatchCatchUpScale))")
        print("runtimeGene.rankingPremiumScale=\(fmt(patch.rankingPremiumScale))")
        print("runtimeGene.rankingPenaltyAvoidScale=\(fmt(patch.rankingPenaltyAvoidScale))")
        print("runtimeGene.jokerDeclarationScale=\(fmt(patch.jokerDeclarationScale))")
        print("runtimeGene.rolloutActivationScale=\(fmt(patch.rolloutActivationScale))")
        print("runtimeGene.rolloutAdjustmentScale=\(fmt(patch.rolloutAdjustmentScale))")
        print("runtimeGene.endgameActivationScale=\(fmt(patch.endgameActivationScale))")
        print("runtimeGene.endgameAdjustmentScale=\(fmt(patch.endgameAdjustmentScale))")
        print("runtimeGene.opponentPressureScale=\(fmt(patch.opponentPressureScale))")
        print("runtimeGene.phaseRankingScale=\(fmt(patch.phaseRankingScale))")
        print("runtimeGene.phaseRolloutScale=\(fmt(patch.phaseRolloutScale))")
        print("runtimeGene.phaseJokerScale=\(fmt(patch.phaseJokerScale))")
        print("runtimeGene.phaseBlindScale=\(fmt(patch.phaseBlindScale))")

        print("runtimePolicyPatch.ranking.matchCatchUpScale=\(fmt(patch.rankingMatchCatchUpScale))")
        print("runtimePolicyPatch.ranking.premiumScale=\(fmt(patch.rankingPremiumScale))")
        print("runtimePolicyPatch.ranking.penaltyAvoidScale=\(fmt(patch.rankingPenaltyAvoidScale))")
        print("runtimePolicyPatch.ranking.jokerDeclarationScale=\(fmt(patch.jokerDeclarationScale))")
        print("runtimePolicyPatch.rollout.activationScale=\(fmt(patch.rolloutActivationScale))")
        print("runtimePolicyPatch.rollout.adjustmentScale=\(fmt(patch.rolloutAdjustmentScale))")
        print("runtimePolicyPatch.endgame.activationScale=\(fmt(patch.endgameActivationScale))")
        print("runtimePolicyPatch.endgame.adjustmentScale=\(fmt(patch.endgameAdjustmentScale))")
        print("runtimePolicyPatch.opponentModeling.pressureScale=\(fmt(patch.opponentPressureScale))")
        print("runtimePolicyPatch.phase.rankingScale=\(fmt(patch.phaseRankingScale))")
        print("runtimePolicyPatch.phase.rolloutScale=\(fmt(patch.phaseRolloutScale))")
        print("runtimePolicyPatch.phase.jokerScale=\(fmt(patch.phaseJokerScale))")
        print("runtimePolicyPatch.phase.blindScale=\(fmt(patch.phaseBlindScale))")
    }

    private static func logRuntimePolicyDiffs(
        baseline: BotRuntimePolicy,
        tuned: BotRuntimePolicy
    ) {
        logRuntimePolicyDiff(
            "ranking.matchCatchUpChaseAggressionBase",
            baseline: baseline.ranking.matchCatchUpChaseAggressionBase,
            tuned: tuned.ranking.matchCatchUpChaseAggressionBase
        )
        logRuntimePolicyDiff(
            "ranking.premiumPreserveChaseBonusBase",
            baseline: baseline.ranking.premiumPreserveChaseBonusBase,
            tuned: tuned.ranking.premiumPreserveChaseBonusBase
        )
        logRuntimePolicyDiff(
            "ranking.premiumDenyChaseBonus",
            baseline: baseline.ranking.premiumDenyChaseBonus,
            tuned: tuned.ranking.premiumDenyChaseBonus
        )
        logRuntimePolicyDiff(
            "ranking.penaltyAvoidOverbidPenalty",
            baseline: baseline.ranking.penaltyAvoidOverbidPenalty,
            tuned: tuned.ranking.penaltyAvoidOverbidPenalty
        )
        logRuntimePolicyDiff(
            "ranking.jokerDeclaration.goalChaseScaleBase",
            baseline: baseline.ranking.jokerDeclaration.goalChaseScaleBase,
            tuned: tuned.ranking.jokerDeclaration.goalChaseScaleBase
        )
        logRuntimePolicyDiff(
            "rollout.chaseUrgencyBase",
            baseline: baseline.rollout.chaseUrgencyBase,
            tuned: tuned.rollout.chaseUrgencyBase
        )
        logRuntimePolicyDiff(
            "rollout.adjustmentBase",
            baseline: baseline.rollout.adjustmentBase,
            tuned: tuned.rollout.adjustmentBase
        )
        logRuntimePolicyDiff(
            "endgame.weightBase",
            baseline: baseline.endgame.weightBase,
            tuned: tuned.endgame.weightBase
        )
        logRuntimePolicyDiff(
            "endgame.adjustmentCap",
            baseline: baseline.endgame.adjustmentCap,
            tuned: tuned.endgame.adjustmentCap
        )
        logRuntimePolicyDiff(
            "opponentModeling.opponentBidPressureChaseBase",
            baseline: baseline.opponentModeling.opponentBidPressureChaseBase,
            tuned: tuned.opponentModeling.opponentBidPressureChaseBase
        )
        logRuntimePolicyDiff(
            "opponentModeling.opponentIntentionChaseBase",
            baseline: baseline.opponentModeling.opponentIntentionChaseBase,
            tuned: tuned.opponentModeling.opponentIntentionChaseBase
        )
    }

    private static func logRuntimePolicyDiff(
        _ key: String,
        baseline: Double,
        tuned: Double
    ) {
        let delta = tuned - baseline
        print("\(key) baseline=\(fmt(baseline)) tuned=\(fmt(tuned)) delta=\(fmt(delta))")
        print("runtimePolicyDiff.\(key).baseline=\(fmt(baseline))")
        print("runtimePolicyDiff.\(key).tuned=\(fmt(tuned))")
        print("runtimePolicyDiff.\(key).delta=\(fmt(delta))")
    }

    private static func logProgress(
        seed: UInt64,
        event: BotTuning.SelfPlayEvolutionProgress,
        candidateStep: Int
    ) {
        switch event.stage {
        case .started:
            print(
                "[progress] seed=\(seed) started " +
                "work=\(event.totalWorkUnits) units"
            )
        case .baselineCompleted:
            print(
                "[progress] seed=\(seed) baseline " +
                "fitness=\(fmt(event.currentFitness ?? 0.0)) " +
                "elapsed=\(fmtDuration(event.elapsedSeconds)) " +
                "eta=\(fmtDuration(event.estimatedRemainingSeconds))"
            )
        case .generationStarted:
            let generation = (event.generationIndex ?? 0) + 1
            print(
                "[progress] seed=\(seed) generation " +
                "\(generation)/\(event.totalGenerations) started"
            )
        case .candidateEvaluated:
            let generation = (event.generationIndex ?? 0) + 1
            let candidate = event.evaluatedCandidatesInGeneration ?? 0
            let shouldPrint = candidate == 1 ||
                candidate == event.populationSize ||
                (candidate % candidateStep == 0)
            guard shouldPrint else { return }
            print(
                "[progress] seed=\(seed) g=\(generation)/\(event.totalGenerations) " +
                "candidate=\(candidate)/\(event.populationSize) " +
                "fitness=\(fmt(event.currentFitness ?? 0.0)) " +
                "genBest=\(fmt(event.generationBestFitness ?? 0.0)) " +
                "overallBest=\(fmt(event.overallBestFitness ?? 0.0)) " +
                "elapsed=\(fmtDuration(event.elapsedSeconds)) " +
                "eta=\(fmtDuration(event.estimatedRemainingSeconds))"
            )
        case .generationCompleted:
            let generation = (event.generationIndex ?? 0) + 1
            print(
                "[progress] seed=\(seed) generation " +
                "\(generation)/\(event.totalGenerations) done " +
                "genBest=\(fmt(event.generationBestFitness ?? 0.0)) " +
                "overallBest=\(fmt(event.overallBestFitness ?? 0.0)) " +
                "elapsed=\(fmtDuration(event.elapsedSeconds)) " +
                "eta=\(fmtDuration(event.estimatedRemainingSeconds))"
            )
        case .finished:
            print(
                "[progress] seed=\(seed) finished " +
                "overallBest=\(fmt(event.overallBestFitness ?? 0.0)) " +
                "elapsed=\(fmtDuration(event.elapsedSeconds))"
            )
        }
        fflush(stdout)
    }

    private static func aggregateTunings(
        _ tunings: [BotTuning],
        method: EnsembleMethod
    ) -> BotTuning {
        guard let template = tunings.first else {
            return BotTuning(difficulty: .hard)
        }

        var turn = template.turnStrategy
        turn.chaseWinProbabilityWeight = aggregate(tunings.map { $0.turnStrategy.chaseWinProbabilityWeight }, method: method)
        turn.chaseThreatPenaltyWeight = aggregate(tunings.map { $0.turnStrategy.chaseThreatPenaltyWeight }, method: method)
        turn.chaseSpendJokerPenalty = aggregate(tunings.map { $0.turnStrategy.chaseSpendJokerPenalty }, method: method)
        turn.chaseLeadWishBonus = aggregate(tunings.map { $0.turnStrategy.chaseLeadWishBonus }, method: method)
        turn.dumpAvoidWinWeight = aggregate(tunings.map { $0.turnStrategy.dumpAvoidWinWeight }, method: method)
        turn.dumpThreatRewardWeight = aggregate(tunings.map { $0.turnStrategy.dumpThreatRewardWeight }, method: method)
        turn.dumpSpendJokerPenalty = aggregate(tunings.map { $0.turnStrategy.dumpSpendJokerPenalty }, method: method)
        turn.dumpFaceUpNonLeadJokerPenalty = aggregate(tunings.map { $0.turnStrategy.dumpFaceUpNonLeadJokerPenalty }, method: method)
        turn.dumpLeadTakesNonTrumpBonus = aggregate(tunings.map { $0.turnStrategy.dumpLeadTakesNonTrumpBonus }, method: method)
        let holdWeight = clamp(
            aggregate(tunings.map { $0.turnStrategy.holdFromDistributionWeight }, method: method),
            to: 0.55...0.97
        )
        turn.holdFromDistributionWeight = holdWeight
        turn.powerConfidenceWeight = 1.0 - holdWeight
        turn.futureJokerPower = aggregate(tunings.map { $0.turnStrategy.futureJokerPower }, method: method)
        turn.futureRegularBasePower = aggregate(tunings.map { $0.turnStrategy.futureRegularBasePower }, method: method)
        turn.futureRegularRankWeight = aggregate(tunings.map { $0.turnStrategy.futureRegularRankWeight }, method: method)
        turn.futureTrumpBaseBonus = aggregate(tunings.map { $0.turnStrategy.futureTrumpBaseBonus }, method: method)
        turn.futureTrumpRankWeight = aggregate(tunings.map { $0.turnStrategy.futureTrumpRankWeight }, method: method)
        turn.futureHighRankBonus = aggregate(tunings.map { $0.turnStrategy.futureHighRankBonus }, method: method)
        turn.futureLongSuitBonusPerCard = aggregate(tunings.map { $0.turnStrategy.futureLongSuitBonusPerCard }, method: method)
        turn.futureTricksScale = aggregate(tunings.map { $0.turnStrategy.futureTricksScale }, method: method)
        turn.threatFaceDownLeadJoker = aggregate(tunings.map { $0.turnStrategy.threatFaceDownLeadJoker }, method: method)
        turn.threatFaceDownNonLeadJoker = aggregate(tunings.map { $0.turnStrategy.threatFaceDownNonLeadJoker }, method: method)
        turn.threatLeadTakesJoker = aggregate(tunings.map { $0.turnStrategy.threatLeadTakesJoker }, method: method)
        turn.threatLeadAboveJoker = aggregate(tunings.map { $0.turnStrategy.threatLeadAboveJoker }, method: method)
        turn.threatLeadWishJoker = aggregate(tunings.map { $0.turnStrategy.threatLeadWishJoker }, method: method)
        turn.threatNonLeadFaceUpJoker = aggregate(tunings.map { $0.turnStrategy.threatNonLeadFaceUpJoker }, method: method)
        turn.threatTrumpBonus = aggregate(tunings.map { $0.turnStrategy.threatTrumpBonus }, method: method)
        turn.threatHighRankBonus = aggregate(tunings.map { $0.turnStrategy.threatHighRankBonus }, method: method)
        turn.powerFaceDownJoker = aggregateInt(tunings.map { $0.turnStrategy.powerFaceDownJoker }, method: method)
        turn.powerLeadTakesJoker = aggregateInt(tunings.map { $0.turnStrategy.powerLeadTakesJoker }, method: method)
        turn.powerLeadAboveJoker = aggregateInt(tunings.map { $0.turnStrategy.powerLeadAboveJoker }, method: method)
        turn.powerLeadWishJoker = aggregateInt(tunings.map { $0.turnStrategy.powerLeadWishJoker }, method: method)
        turn.powerNonLeadFaceUpJoker = aggregateInt(tunings.map { $0.turnStrategy.powerNonLeadFaceUpJoker }, method: method)
        turn.powerTrumpBonus = aggregateInt(tunings.map { $0.turnStrategy.powerTrumpBonus }, method: method)
        turn.powerLeadSuitBonus = aggregateInt(tunings.map { $0.turnStrategy.powerLeadSuitBonus }, method: method)
        turn.powerNormalizationValue = aggregate(tunings.map { $0.turnStrategy.powerNormalizationValue }, method: method)

        var bidding = template.bidding
        bidding.expectedJokerPower = aggregate(tunings.map { $0.bidding.expectedJokerPower }, method: method)
        bidding.expectedRankWeight = aggregate(tunings.map { $0.bidding.expectedRankWeight }, method: method)
        bidding.expectedTrumpBaseBonus = aggregate(tunings.map { $0.bidding.expectedTrumpBaseBonus }, method: method)
        bidding.expectedTrumpRankWeight = aggregate(tunings.map { $0.bidding.expectedTrumpRankWeight }, method: method)
        bidding.expectedHighRankBonus = aggregate(tunings.map { $0.bidding.expectedHighRankBonus }, method: method)
        bidding.expectedLongSuitBonusPerCard = aggregate(tunings.map { $0.bidding.expectedLongSuitBonusPerCard }, method: method)
        bidding.expectedTrumpDensityBonus = aggregate(tunings.map { $0.bidding.expectedTrumpDensityBonus }, method: method)
        bidding.expectedNoTrumpHighCardBonus = aggregate(tunings.map { $0.bidding.expectedNoTrumpHighCardBonus }, method: method)
        bidding.expectedNoTrumpJokerSynergy = aggregate(tunings.map { $0.bidding.expectedNoTrumpJokerSynergy }, method: method)
        let desperateBehind = max(
            100,
            aggregateInt(tunings.map { $0.bidding.blindDesperateBehindThreshold }, method: method)
        )
        let catchUpBehind = max(
            60,
            aggregateInt(tunings.map { $0.bidding.blindCatchUpBehindThreshold }, method: method)
        )
        bidding.blindDesperateBehindThreshold = desperateBehind
        bidding.blindCatchUpBehindThreshold = min(desperateBehind, catchUpBehind)
        bidding.blindSafeLeadThreshold = max(
            80,
            aggregateInt(tunings.map { $0.bidding.blindSafeLeadThreshold }, method: method)
        )
        let catchUpTarget = clamp(
            aggregate(tunings.map { $0.bidding.blindCatchUpTargetShare }, method: method),
            to: 0.10...0.90
        )
        bidding.blindCatchUpTargetShare = catchUpTarget
        bidding.blindCatchUpConservativeTargetShare = min(
            catchUpTarget,
            clamp(
                aggregate(tunings.map { $0.bidding.blindCatchUpConservativeTargetShare }, method: method),
                to: 0.05...0.85
            )
        )
        bidding.blindDesperateTargetShare = max(
            catchUpTarget,
            clamp(
                aggregate(tunings.map { $0.bidding.blindDesperateTargetShare }, method: method),
                to: 0.15...0.95
            )
        )

        var trumpSelection = template.trumpSelection
        trumpSelection.cardBasePower = aggregate(tunings.map { $0.trumpSelection.cardBasePower }, method: method)
        trumpSelection.minimumPowerToDeclareTrump = aggregate(
            tunings.map { $0.trumpSelection.minimumPowerToDeclareTrump },
            method: method
        )
        trumpSelection.playerChosenPairBonus = aggregate(tunings.map { $0.trumpSelection.playerChosenPairBonus }, method: method)
        trumpSelection.lengthBonusPerExtraCard = aggregate(tunings.map { $0.trumpSelection.lengthBonusPerExtraCard }, method: method)
        trumpSelection.densityBonusWeight = aggregate(tunings.map { $0.trumpSelection.densityBonusWeight }, method: method)
        trumpSelection.sequenceBonusWeight = aggregate(tunings.map { $0.trumpSelection.sequenceBonusWeight }, method: method)
        trumpSelection.controlBonusWeight = aggregate(tunings.map { $0.trumpSelection.controlBonusWeight }, method: method)
        trumpSelection.jokerSynergyBase = aggregate(tunings.map { $0.trumpSelection.jokerSynergyBase }, method: method)
        trumpSelection.jokerSynergyControlWeight = aggregate(tunings.map { $0.trumpSelection.jokerSynergyControlWeight }, method: method)
        let runtimePolicy = aggregateRuntimePolicy(
            tunings.map(\.runtimePolicy),
            difficulty: template.difficulty,
            method: method
        )

        return BotTuning(
            difficulty: template.difficulty,
            turnStrategy: turn,
            bidding: bidding,
            trumpSelection: trumpSelection,
            runtimePolicy: runtimePolicy,
            timing: template.timing
        )
    }

    private static func aggregateRuntimePolicy(
        _ policies: [BotRuntimePolicy],
        difficulty: BotDifficulty,
        method: EnsembleMethod
    ) -> BotRuntimePolicy {
        guard !policies.isEmpty else {
            return BotRuntimePolicy.preset(for: difficulty)
        }
        let baseline = BotRuntimePolicy.preset(for: difficulty)
        let patches = policies.map {
            BotSelfPlayEvolutionEngine.runtimePolicyPatch(
                from: $0,
                relativeTo: baseline
            )
        }
        let aggregatedPatch = BotSelfPlayEvolutionEngine.RuntimePolicyEvolutionPatch(
            rankingMatchCatchUpScale: aggregate(
                patches.map(\.rankingMatchCatchUpScale),
                method: method
            ),
            rankingPremiumScale: aggregate(
                patches.map(\.rankingPremiumScale),
                method: method
            ),
            rankingPenaltyAvoidScale: aggregate(
                patches.map(\.rankingPenaltyAvoidScale),
                method: method
            ),
            jokerDeclarationScale: aggregate(
                patches.map(\.jokerDeclarationScale),
                method: method
            ),
            rolloutActivationScale: aggregate(
                patches.map(\.rolloutActivationScale),
                method: method
            ),
            rolloutAdjustmentScale: aggregate(
                patches.map(\.rolloutAdjustmentScale),
                method: method
            ),
            endgameActivationScale: aggregate(
                patches.map(\.endgameActivationScale),
                method: method
            ),
            endgameAdjustmentScale: aggregate(
                patches.map(\.endgameAdjustmentScale),
                method: method
            ),
            opponentPressureScale: aggregate(
                patches.map(\.opponentPressureScale),
                method: method
            ),
            phaseRankingScale: aggregate(
                patches.map(\.phaseRankingScale),
                method: method
            ),
            phaseRolloutScale: aggregate(
                patches.map(\.phaseRolloutScale),
                method: method
            ),
            phaseJokerScale: aggregate(
                patches.map(\.phaseJokerScale),
                method: method
            ),
            phaseBlindScale: aggregate(
                patches.map(\.phaseBlindScale),
                method: method
            )
        )
        return aggregatedPatch.apply(to: baseline)
    }

    private static func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0.0 }
        return values.reduce(0.0, +) / Double(values.count)
    }

    private static func median(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0.0 }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[mid - 1] + sorted[mid]) / 2.0
        }
        return sorted[mid]
    }

    private static func aggregate(_ values: [Double], method: EnsembleMethod) -> Double {
        switch method {
        case .mean:
            return average(values)
        case .median:
            return median(values)
        }
    }

    private static func aggregateInt(_ values: [Int], method: EnsembleMethod) -> Int {
        Int(aggregate(values.map(Double.init), method: method).rounded())
    }

    private static func fmt(_ value: Double) -> String {
        String(format: "%.6f", value)
    }

    private static func fmtDuration(_ seconds: Double?) -> String {
        guard let seconds else { return "--:--:--" }
        let clamped = max(0, Int(seconds.rounded()))
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        let secs = clamped % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }

    private static func value(
        after flag: String,
        in arguments: [String],
        at index: inout Int
    ) throws -> String {
        let nextIndex = index + 1
        guard arguments.indices.contains(nextIndex) else {
            throw RunnerError.message("Missing value for \(flag)")
        }
        index = nextIndex
        return arguments[nextIndex]
    }

    private static func parseDifficulty(_ rawValue: String) throws -> BotDifficulty {
        guard let difficulty = BotDifficulty(rawValue: rawValue) else {
            throw RunnerError.message("Invalid difficulty: \(rawValue) (use easy|normal|hard)")
        }
        return difficulty
    }

    private static func parseInt(
        _ rawValue: String,
        flag: String,
        minimum: Int
    ) throws -> Int {
        guard let value = Int(rawValue), value >= minimum else {
            throw RunnerError.message("Invalid integer for \(flag): \(rawValue)")
        }
        return value
    }

    private static func parseUInt64(
        _ rawValue: String,
        flag: String
    ) throws -> UInt64 {
        guard let value = UInt64(rawValue) else {
            throw RunnerError.message("Invalid uint64 for \(flag): \(rawValue)")
        }
        return value
    }

    private static func parseDouble(
        _ rawValue: String,
        flag: String,
        minimum: Double,
        maximum: Double? = nil
    ) throws -> Double {
        guard let value = Double(rawValue), value >= minimum else {
            throw RunnerError.message("Invalid decimal for \(flag): \(rawValue)")
        }
        if let maximum, value > maximum {
            throw RunnerError.message("Invalid decimal for \(flag): \(rawValue)")
        }
        return value
    }

    private static func parseBool(
        _ rawValue: String,
        flag: String
    ) throws -> Bool {
        switch rawValue {
        case "true":
            return true
        case "false":
            return false
        default:
            throw RunnerError.message("Invalid boolean for \(flag): \(rawValue) (use true|false)")
        }
    }

    private static func parseSeedList(
        _ rawValue: String,
        flag: String
    ) throws -> [UInt64] {
        let values = rawValue.split(separator: ",")
        guard !values.isEmpty else {
            throw RunnerError.message("Invalid seed list for \(flag): \(rawValue)")
        }
        let parsed = try values.map { seed in
            guard let value = UInt64(seed) else {
                throw RunnerError.message("Invalid seed list for \(flag): \(rawValue)")
            }
            return value
        }
        return parsed
    }

    private static func parseEnum<T: RawRepresentable>(
        _ type: T.Type,
        value rawValue: String,
        flag: String
    ) throws -> T where T.RawValue == String {
        guard let parsed = T(rawValue: rawValue) else {
            throw RunnerError.message("Invalid value for \(flag): \(rawValue)")
        }
        return parsed
    }

    private static func clamp(
        _ value: Double,
        to range: ClosedRange<Double>
    ) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }

    private static func writeToStderr(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        FileHandle.standardError.write(data)
    }
}
