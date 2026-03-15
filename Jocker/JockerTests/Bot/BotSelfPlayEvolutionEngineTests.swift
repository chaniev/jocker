//
//  BotSelfPlayEvolutionEngineTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest

#if canImport(JockerSelfPlayTools)
@testable import JockerSelfPlayTools
@testable import Jocker

private typealias ToolBotBiddingService = JockerSelfPlayTools.BotBiddingService
private typealias ToolBotDifficulty = JockerSelfPlayTools.BotDifficulty
private typealias ToolBotRuntimePolicy = JockerSelfPlayTools.BotRuntimePolicy
private typealias ToolBotTuning = JockerSelfPlayTools.BotTuning
private typealias ToolCard = JockerSelfPlayTools.Card

final class BotSelfPlayEvolutionEngineTests: XCTestCase {

    func testDeriveEvaluationSeed_sameInputs_producesSameSeed() {
        let baseSeed: UInt64 = 0x5EED
        let s1 = BotSelfPlayEvolutionEngine.deriveEvaluationSeed(
            baseSeed: baseSeed,
            generationIndex: 2,
            candidateIndex: 1,
            gameIndex: 0,
            seatRotationIndex: 3
        )
        let s2 = BotSelfPlayEvolutionEngine.deriveEvaluationSeed(
            baseSeed: baseSeed,
            generationIndex: 2,
            candidateIndex: 1,
            gameIndex: 0,
            seatRotationIndex: 3
        )
        XCTAssertEqual(s1, s2, "Same inputs must yield same derived seed")
    }

    func testDeriveEvaluationSeed_differentInputs_produceDifferentSeeds() {
        let baseSeed: UInt64 = 0x5EED
        let s0 = BotSelfPlayEvolutionEngine.deriveEvaluationSeed(
            baseSeed: baseSeed,
            generationIndex: 0,
            candidateIndex: 0,
            gameIndex: 0,
            seatRotationIndex: 0
        )
        let s1 = BotSelfPlayEvolutionEngine.deriveEvaluationSeed(
            baseSeed: baseSeed,
            generationIndex: 1,
            candidateIndex: 0,
            gameIndex: 0,
            seatRotationIndex: 0
        )
        let s2 = BotSelfPlayEvolutionEngine.deriveEvaluationSeed(
            baseSeed: baseSeed,
            generationIndex: 0,
            candidateIndex: 1,
            gameIndex: 0,
            seatRotationIndex: 0
        )
        let s3 = BotSelfPlayEvolutionEngine.deriveEvaluationSeed(
            baseSeed: baseSeed,
            generationIndex: 0,
            candidateIndex: 0,
            gameIndex: 1,
            seatRotationIndex: 0
        )
        let s4 = BotSelfPlayEvolutionEngine.deriveEvaluationSeed(
            baseSeed: baseSeed,
            generationIndex: 0,
            candidateIndex: 0,
            gameIndex: 0,
            seatRotationIndex: 1
        )
        XCTAssertNotEqual(s0, s1)
        XCTAssertNotEqual(s0, s2)
        XCTAssertNotEqual(s0, s3)
        XCTAssertNotEqual(s0, s4)
        XCTAssertNotEqual(s1, s2)
    }

    func testSimulateGame_fullMatchWithSameSeed_isDeterministic() {
        let tunings = makeTunings(count: 4)

        let first = BotSelfPlayEvolutionEngine.simulateGame(
            tuningsBySeat: tunings,
            rounds: 8,
            cardsPerRoundRange: 1...9,
            seed: 20260306,
            useFullMatchRules: true
        )
        let second = BotSelfPlayEvolutionEngine.simulateGame(
            tuningsBySeat: tunings,
            rounds: 8,
            cardsPerRoundRange: 1...9,
            seed: 20260306,
            useFullMatchRules: true
        )

        let o1 = first.outcome
        let o2 = second.outcome
        XCTAssertEqual(o1.totalScores, o2.totalScores)
        XCTAssertEqual(o1.underbidLosses, o2.underbidLosses)
        XCTAssertEqual(o1.blindBidRatesBlock4, o2.blindBidRatesBlock4)
        XCTAssertEqual(o1.leftNeighborPremiumAssistRates, o2.leftNeighborPremiumAssistRates)
    }

    func testSimulateGame_legacyModeProducesSeatAlignedMetrics() {
        let playerCount = 3
        let run = BotSelfPlayEvolutionEngine.simulateGame(
            tuningsBySeat: makeTunings(count: playerCount),
            rounds: 4,
            cardsPerRoundRange: 2...4,
            seed: 20260307,
            useFullMatchRules: false
        )
        let outcome = run.outcome

        XCTAssertEqual(outcome.totalScores.count, playerCount)
        XCTAssertEqual(outcome.underbidLosses.count, playerCount)
        XCTAssertEqual(outcome.trumpDensityUnderbidLosses.count, playerCount)
        XCTAssertEqual(outcome.noTrumpControlUnderbidLosses.count, playerCount)
        XCTAssertEqual(outcome.premiumAssistLosses.count, playerCount)
        XCTAssertEqual(outcome.premiumPenaltyTargetLosses.count, playerCount)
        XCTAssertEqual(outcome.premiumCaptureRates.count, playerCount)
        XCTAssertEqual(outcome.blindSuccessRates.count, playerCount)
        XCTAssertEqual(outcome.jokerWishWinRates.count, playerCount)
        XCTAssertEqual(outcome.earlyJokerSpendRates.count, playerCount)
        XCTAssertEqual(outcome.penaltyTargetRates.count, playerCount)
        XCTAssertEqual(outcome.bidAccuracyRates.count, playerCount)
        XCTAssertEqual(outcome.overbidRates.count, playerCount)
        XCTAssertEqual(outcome.blindBidRatesBlock4.count, playerCount)
        XCTAssertEqual(outcome.averageBlindBidSizes.count, playerCount)
        XCTAssertEqual(outcome.blindBidWhenBehindRates.count, playerCount)
        XCTAssertEqual(outcome.blindBidWhenLeadingRates.count, playerCount)
        XCTAssertEqual(outcome.earlyLeadWishJokerRates.count, playerCount)
        XCTAssertEqual(outcome.leftNeighborPremiumAssistRates.count, playerCount)
    }

    func testDebugBiddingOrder_startsAfterDealerAndWraps() {
        let order = BotSelfPlayEvolutionEngine.debugBiddingOrder(
            dealer: 2,
            playerCount: 4
        )

        XCTAssertEqual(order, [3, 0, 1, 2])
    }

    func testDebugCanChooseBlindBid_dealerRequiresAllOtherPlayersBlind() {
        let dealer = 1

        XCTAssertFalse(
            BotSelfPlayEvolutionEngine.debugCanChooseBlindBid(
                forPlayer: dealer,
                dealer: dealer,
                blindSelections: [false, false, false, false]
            )
        )

        XCTAssertFalse(
            BotSelfPlayEvolutionEngine.debugCanChooseBlindBid(
                forPlayer: dealer,
                dealer: dealer,
                blindSelections: [true, false, false, true]
            )
        )

        XCTAssertTrue(
            BotSelfPlayEvolutionEngine.debugCanChooseBlindBid(
                forPlayer: dealer,
                dealer: dealer,
                blindSelections: [true, false, true, true]
            )
        )
    }

    func testDebugResolvePreDealBlindContext_keepsDealerBlockedWhenAnyNonDealerDeclinesBlind() {
        let services = makeBiddingServices(count: 4)

        let context = BotSelfPlayEvolutionEngine.debugResolvePreDealBlindContext(
            dealer: 3,
            cardsInRound: 9,
            playerCount: 4,
            biddingServices: services,
            totalScoresIncludingCurrentBlock: [1_000, 0, 0, 0]
        )

        XCTAssertEqual(
            BotSelfPlayEvolutionEngine.debugBiddingOrder(dealer: 3, playerCount: 4),
            [0, 1, 2, 3]
        )

        XCTAssertEqual(context.blindSelections[0], false, "Leader should not risk blind")
        XCTAssertTrue(context.blindSelections[1], "Trailing non-dealer should choose blind")
        XCTAssertTrue(context.blindSelections[2], "Trailing non-dealer should choose blind")
        XCTAssertFalse(context.blindSelections[3], "Dealer is blocked until all others chose blind")

        XCTAssertEqual(context.lockedBids[0], 0)
        XCTAssertEqual(context.lockedBids[3], 0)
        XCTAssertTrue((0...9).contains(context.lockedBids[1]))
        XCTAssertTrue((0...9).contains(context.lockedBids[2]))
    }

    func testDebugMakeBids_preservesPreLockedBlindBidsAndForcesDealerIntoAllowedRange() {
        let services = makeBiddingServices(count: 4)
        let hands: [[ToolCard]] = [
            [.regular(suit: .diamonds, rank: .six)],
            [.regular(suit: .hearts, rank: .ace)],
            [.regular(suit: .clubs, rank: .king)],
            [.regular(suit: .spades, rank: .queen)]
        ]

        let outcome = BotSelfPlayEvolutionEngine.debugMakeBids(
            hands: hands,
            dealer: 0,
            cardsInRound: 1,
            trump: nil,
            biddingServices: services,
            preLockedBids: [0, 1, 0, 0],
            blindSelections: [false, true, true, true]
        )

        XCTAssertEqual(outcome.bids[1], 1)
        XCTAssertEqual(outcome.bids[2], 0)
        XCTAssertEqual(outcome.bids[3], 0)
        XCTAssertEqual(outcome.bids[0], 1, "Dealer cannot keep 0 when others already sum to cardsInRound")
        XCTAssertEqual(outcome.maxAllowedBids.count, 4)
        XCTAssertEqual(outcome.maxAllowedBids[0], 1)
    }

    private func makeBiddingServices(count: Int) -> [ToolBotBiddingService] {
        return makeTunings(count: count).map { ToolBotBiddingService(tuning: $0) }
    }

    private func makeTunings(count: Int) -> [ToolBotTuning] {
        return (0..<count).map { _ in
            ToolBotTuning(difficulty: .hard)
        }
    }

    // MARK: - Identity and scope semantics (plan 03)

    func testIdentityGenome_doesNotChangeBotRuntimePolicy() {
        let baseTuning = ToolBotTuning(difficulty: .hard)
        let baselinePolicy = baseTuning.runtimePolicy

        let tuned = BotSelfPlayEvolutionEngine.tuning(
            byApplying: .identity,
            to: baseTuning
        )
        let patchedPolicy = tuned.runtimePolicy

        XCTAssertEqual(
            patchedPolicy.ranking.matchCatchUpChaseAggressionBase,
            baselinePolicy.ranking.matchCatchUpChaseAggressionBase,
            accuracy: 1e-9
        )
        XCTAssertEqual(
            patchedPolicy.ranking.premiumPreserveChaseBonusBase,
            baselinePolicy.ranking.premiumPreserveChaseBonusBase,
            accuracy: 1e-9
        )
        XCTAssertEqual(
            patchedPolicy.ranking.penaltyAvoidOverbidPenalty,
            baselinePolicy.ranking.penaltyAvoidOverbidPenalty,
            accuracy: 1e-9
        )
        XCTAssertEqual(
            patchedPolicy.ranking.jokerDeclaration.goalChaseScaleBase,
            baselinePolicy.ranking.jokerDeclaration.goalChaseScaleBase,
            accuracy: 1e-9
        )
        XCTAssertEqual(
            patchedPolicy.rollout.chaseUrgencyBase,
            baselinePolicy.rollout.chaseUrgencyBase,
            accuracy: 1e-9
        )
        XCTAssertEqual(
            patchedPolicy.rollout.adjustmentBase,
            baselinePolicy.rollout.adjustmentBase,
            accuracy: 1e-9
        )
        XCTAssertEqual(
            patchedPolicy.endgame.weightBase,
            baselinePolicy.endgame.weightBase,
            accuracy: 1e-9
        )
        XCTAssertEqual(
            patchedPolicy.endgame.adjustmentCap,
            baselinePolicy.endgame.adjustmentCap,
            accuracy: 1e-9
        )
        XCTAssertEqual(
            patchedPolicy.opponentModeling.opponentBidPressureChaseBase,
            baselinePolicy.opponentModeling.opponentBidPressureChaseBase,
            accuracy: 1e-9
        )
        XCTAssertEqual(
            patchedPolicy.bidding.bidSelection.utilityTieTolerance,
            baselinePolicy.bidding.bidSelection.utilityTieTolerance,
            accuracy: 1e-9
        )
        XCTAssertEqual(
            patchedPolicy.evaluator.leadControlReserve.trumpAceValue,
            baselinePolicy.evaluator.leadControlReserve.trumpAceValue,
            accuracy: 1e-9
        )
        XCTAssertEqual(
            patchedPolicy.simulation.trumpBonus,
            baselinePolicy.simulation.trumpBonus,
            accuracy: 1e-9
        )
        XCTAssertEqual(
            patchedPolicy.heuristics.holdBlend.legalAwareSimulationWeight,
            baselinePolicy.heuristics.holdBlend.legalAwareSimulationWeight,
            accuracy: 1e-9
        )
        XCTAssertEqual(
            patchedPolicy.handStrength.trumpSelectionControlTopRankWeight,
            baselinePolicy.handStrength.trumpSelectionControlTopRankWeight,
            accuracy: 1e-9
        )
    }

    func testSingleRankingGeneMutation_onlyChangesRankingPolicyGroup() {
        let baseTuning = ToolBotTuning(difficulty: .hard)
        let baselinePolicy = baseTuning.runtimePolicy

        var genome = BotSelfPlayEvolutionEngine.EvolutionGenome.identity
        genome.rankingMatchCatchUpScale = 1.3

        let tuned = BotSelfPlayEvolutionEngine.tuning(
            byApplying: genome,
            to: baseTuning
        )
        let patched = tuned.runtimePolicy

        XCTAssertNotEqual(
            patched.ranking.matchCatchUpChaseAggressionBase,
            baselinePolicy.ranking.matchCatchUpChaseAggressionBase,
            accuracy: 1e-9
        )
        XCTAssertEqual(
            patched.rollout.chaseUrgencyBase,
            baselinePolicy.rollout.chaseUrgencyBase,
            accuracy: 1e-9
        )
        XCTAssertEqual(
            patched.endgame.weightBase,
            baselinePolicy.endgame.weightBase,
            accuracy: 1e-9
        )
        XCTAssertEqual(
            patched.opponentModeling.opponentBidPressureChaseBase,
            baselinePolicy.opponentModeling.opponentBidPressureChaseBase,
            accuracy: 1e-9
        )
        XCTAssertEqual(
            patched.bidding.bidSelection.utilityTieTolerance,
            baselinePolicy.bidding.bidSelection.utilityTieTolerance,
            accuracy: 1e-9
        )
    }

    func testScopeMask_disabledGroups_remainNeutral() {
        var genome = BotSelfPlayEvolutionEngine.EvolutionGenome.identity
        genome.rankingMatchCatchUpScale = 1.5
        genome.rankingPremiumScale = 0.8
        genome.rolloutActivationScale = 1.4
        genome.endgameActivationScale = 0.7
        genome.opponentPressureScale = 1.3
        genome.jokerDeclarationScale = 0.9
        genome.phaseRankingScale = 1.2
        genome.phaseRolloutScale = 0.9
        genome.phaseJokerScale = 1.1
        genome.phaseBlindScale = 0.8

        let config = ToolBotTuning.SelfPlayEvolutionConfig(
            tuneRankingPolicy: false,
            tuneRolloutPolicy: false,
            tuneEndgamePolicy: false,
            tuneOpponentModelingPolicy: false,
            tuneJokerDeclarationPolicy: false,
            tunePhasePolicy: false
        )

        let masked = BotSelfPlayEvolutionEngine.applyingEvolutionScopeMask(
            genome,
            config: config
        )

        XCTAssertEqual(masked.rankingMatchCatchUpScale, 1.0, accuracy: 1e-9)
        XCTAssertEqual(masked.rankingPremiumScale, 1.0, accuracy: 1e-9)
        XCTAssertEqual(masked.rankingPenaltyAvoidScale, 1.0, accuracy: 1e-9)
        XCTAssertEqual(masked.rolloutActivationScale, 1.0, accuracy: 1e-9)
        XCTAssertEqual(masked.rolloutAdjustmentScale, 1.0, accuracy: 1e-9)
        XCTAssertEqual(masked.endgameActivationScale, 1.0, accuracy: 1e-9)
        XCTAssertEqual(masked.endgameAdjustmentScale, 1.0, accuracy: 1e-9)
        XCTAssertEqual(masked.opponentPressureScale, 1.0, accuracy: 1e-9)
        XCTAssertEqual(masked.jokerDeclarationScale, 1.0, accuracy: 1e-9)
        XCTAssertEqual(masked.phaseRankingScale, 1.0, accuracy: 1e-9)
        XCTAssertEqual(masked.phaseRolloutScale, 1.0, accuracy: 1e-9)
        XCTAssertEqual(masked.phaseJokerScale, 1.0, accuracy: 1e-9)
        XCTAssertEqual(masked.phaseBlindScale, 1.0, accuracy: 1e-9)
    }

    func testScopeMask_enabledGroups_preserveValues() {
        var genome = BotSelfPlayEvolutionEngine.EvolutionGenome.identity
        genome.rankingMatchCatchUpScale = 1.3
        genome.rolloutActivationScale = 1.2
        genome.opponentPressureScale = 0.9
        genome.phaseRankingScale = 1.25

        let config = ToolBotTuning.SelfPlayEvolutionConfig(
            tuneRankingPolicy: true,
            tuneRolloutPolicy: true,
            tuneEndgamePolicy: false,
            tuneOpponentModelingPolicy: true,
            tuneJokerDeclarationPolicy: false,
            tunePhasePolicy: true
        )

        let masked = BotSelfPlayEvolutionEngine.applyingEvolutionScopeMask(
            genome,
            config: config
        )

        XCTAssertEqual(masked.rankingMatchCatchUpScale, 1.3, accuracy: 1e-9)
        XCTAssertEqual(masked.rolloutActivationScale, 1.2, accuracy: 1e-9)
        XCTAssertEqual(masked.opponentPressureScale, 0.9, accuracy: 1e-9)
        XCTAssertEqual(masked.phaseRankingScale, 1.25, accuracy: 1e-9)
        XCTAssertEqual(masked.endgameActivationScale, 1.0, accuracy: 1e-9)
        XCTAssertEqual(masked.jokerDeclarationScale, 1.0, accuracy: 1e-9)
    }

    func testMutationAndCrossover_respectBounds() {
        var rng = BotSelfPlayEvolutionEngine.SelfPlayRandomGenerator(seed: 42)
        let runtimeBounds: [(ClosedRange<Double>, KeyPath<BotSelfPlayEvolutionEngine.EvolutionGenome, Double>)] = [
            (0.60...1.60, \.rankingMatchCatchUpScale),
            (0.60...1.60, \.rankingPremiumScale),
            (0.60...1.60, \.rankingPenaltyAvoidScale),
            (0.60...1.60, \.jokerDeclarationScale),
            (0.65...1.50, \.rolloutActivationScale),
            (0.60...1.60, \.rolloutAdjustmentScale),
            (0.65...1.50, \.endgameActivationScale),
            (0.60...1.60, \.endgameAdjustmentScale),
            (0.60...1.60, \.opponentPressureScale),
            (0.60...1.60, \.phaseRankingScale),
            (0.60...1.60, \.phaseRolloutScale),
            (0.60...1.60, \.phaseJokerScale),
            (0.60...1.60, \.phaseBlindScale)
        ]

        for _ in 0..<20 {
            let randomized = BotSelfPlayEvolutionEngine.randomGenome(
                around: .identity,
                magnitude: 0.30,
                using: &rng
            )
            for (range, keyPath) in runtimeBounds {
                let value = randomized[keyPath: keyPath]
                XCTAssertGreaterThanOrEqual(value, range.lowerBound, "\(keyPath) = \(value) < \(range.lowerBound)")
                XCTAssertLessThanOrEqual(value, range.upperBound, "\(keyPath) = \(value) > \(range.upperBound)")
            }
        }

        let parent1 = BotSelfPlayEvolutionEngine.randomGenome(around: .identity, magnitude: 0.25, using: &rng)
        let parent2 = BotSelfPlayEvolutionEngine.randomGenome(around: .identity, magnitude: 0.25, using: &rng)
        for _ in 0..<20 {
            let child = BotSelfPlayEvolutionEngine.crossover(parent1, parent2, using: &rng)
            for (range, keyPath) in runtimeBounds {
                let value = child[keyPath: keyPath]
                XCTAssertGreaterThanOrEqual(value, range.lowerBound, "crossover \(keyPath) = \(value) < \(range.lowerBound)")
                XCTAssertLessThanOrEqual(value, range.upperBound, "crossover \(keyPath) = \(value) > \(range.upperBound)")
            }
        }
    }

    func testRuntimePolicyEvolutionPatch_identityPreservesPolicy() {
        let baseline = ToolBotRuntimePolicy.preset(for: ToolBotDifficulty.hard)
        let patched = BotSelfPlayEvolutionEngine.RuntimePolicyEvolutionPatch.identity.apply(to: baseline)

        XCTAssertEqual(
            patched.ranking.matchCatchUpChaseAggressionBase,
            baseline.ranking.matchCatchUpChaseAggressionBase,
            accuracy: 1e-9
        )
        XCTAssertEqual(
            patched.rollout.adjustmentBase,
            baseline.rollout.adjustmentBase,
            accuracy: 1e-9
        )
        XCTAssertEqual(
            patched.endgame.adjustmentCap,
            baseline.endgame.adjustmentCap,
            accuracy: 1e-9
        )
        XCTAssertEqual(
            patched.opponentModeling.opponentBidPressureChaseBase,
            baseline.opponentModeling.opponentBidPressureChaseBase,
            accuracy: 1e-9
        )
        XCTAssertEqual(patched.ranking.phaseMatchCatchUp, baseline.ranking.phaseMatchCatchUp)
        XCTAssertEqual(patched.rollout.phaseActivation, baseline.rollout.phaseActivation)
        XCTAssertEqual(
            patched.ranking.jokerDeclaration.phaseLateSpend,
            baseline.ranking.jokerDeclaration.phaseLateSpend
        )
        XCTAssertEqual(patched.bidding.blindPolicy.phaseBlock4, baseline.bidding.blindPolicy.phaseBlock4)
    }

    func testRuntimePolicyEvolutionPatch_extractRecoversAppliedScales() {
        let baseline = ToolBotRuntimePolicy.preset(for: ToolBotDifficulty.hard)
        let patch = BotSelfPlayEvolutionEngine.RuntimePolicyEvolutionPatch(
            rankingMatchCatchUpScale: 1.22,
            rankingPremiumScale: 0.91,
            rankingPenaltyAvoidScale: 1.14,
            jokerDeclarationScale: 0.95,
            rolloutActivationScale: 1.18,
            rolloutAdjustmentScale: 0.88,
            endgameActivationScale: 1.10,
            endgameAdjustmentScale: 0.93,
            opponentPressureScale: 1.16,
            phaseRankingScale: 1.24,
            phaseRolloutScale: 0.82,
            phaseJokerScale: 1.18,
            phaseBlindScale: 0.86
        )
        let patched = patch.apply(to: baseline)

        let extracted = BotSelfPlayEvolutionEngine.runtimePolicyPatch(
            from: patched,
            relativeTo: baseline
        )

        XCTAssertEqual(extracted.rankingMatchCatchUpScale, patch.rankingMatchCatchUpScale, accuracy: 1e-9)
        XCTAssertEqual(extracted.rankingPremiumScale, patch.rankingPremiumScale, accuracy: 1e-9)
        XCTAssertEqual(extracted.rankingPenaltyAvoidScale, patch.rankingPenaltyAvoidScale, accuracy: 1e-9)
        XCTAssertEqual(extracted.jokerDeclarationScale, patch.jokerDeclarationScale, accuracy: 1e-9)
        XCTAssertEqual(extracted.rolloutActivationScale, patch.rolloutActivationScale, accuracy: 1e-9)
        XCTAssertEqual(extracted.rolloutAdjustmentScale, patch.rolloutAdjustmentScale, accuracy: 1e-9)
        XCTAssertEqual(extracted.endgameActivationScale, patch.endgameActivationScale, accuracy: 1e-9)
        XCTAssertEqual(extracted.endgameAdjustmentScale, patch.endgameAdjustmentScale, accuracy: 1e-9)
        XCTAssertEqual(extracted.opponentPressureScale, patch.opponentPressureScale, accuracy: 1e-9)
        XCTAssertEqual(extracted.phaseRankingScale, patch.phaseRankingScale, accuracy: 1e-9)
        XCTAssertEqual(extracted.phaseRolloutScale, patch.phaseRolloutScale, accuracy: 1e-9)
        XCTAssertEqual(extracted.phaseJokerScale, patch.phaseJokerScale, accuracy: 1e-9)
        XCTAssertEqual(extracted.phaseBlindScale, patch.phaseBlindScale, accuracy: 1e-9)
    }

    func testRuntimePolicyEvolutionPatch_phaseScalesCreateDirectionalPhaseRamps() {
        let baseline = ToolBotRuntimePolicy.preset(for: ToolBotDifficulty.hard)
        let patch = BotSelfPlayEvolutionEngine.RuntimePolicyEvolutionPatch(
            rankingMatchCatchUpScale: 1.0,
            rankingPremiumScale: 1.0,
            rankingPenaltyAvoidScale: 1.0,
            jokerDeclarationScale: 1.0,
            rolloutActivationScale: 1.0,
            rolloutAdjustmentScale: 1.0,
            endgameActivationScale: 1.0,
            endgameAdjustmentScale: 1.0,
            opponentPressureScale: 1.0,
            phaseRankingScale: 1.25,
            phaseRolloutScale: 1.20,
            phaseJokerScale: 1.10,
            phaseBlindScale: 1.15
        )
        let patched = patch.apply(to: baseline)

        XCTAssertLessThan(patched.ranking.phaseMatchCatchUp.early, 1.0)
        XCTAssertEqual(patched.ranking.phaseMatchCatchUp.mid, 1.0, accuracy: 1e-9)
        XCTAssertGreaterThan(patched.ranking.phaseMatchCatchUp.late, 1.0)

        XCTAssertLessThan(patched.rollout.phaseActivation.early, 1.0)
        XCTAssertGreaterThan(patched.rollout.phaseActivation.late, 1.0)

        XCTAssertGreaterThan(patched.ranking.jokerDeclaration.phaseEarlySpend.early, 1.0)
        XCTAssertLessThan(patched.ranking.jokerDeclaration.phaseEarlySpend.late, 1.0)
        XCTAssertLessThan(patched.ranking.jokerDeclaration.phaseLateSpend.early, 1.0)
        XCTAssertGreaterThan(patched.ranking.jokerDeclaration.phaseLateSpend.late, 1.0)
        XCTAssertLessThan(patched.ranking.jokerDeclaration.phaseDeclarationPressure.early, 1.0)
        XCTAssertGreaterThan(patched.ranking.jokerDeclaration.phaseDeclarationPressure.late, 1.0)

        XCTAssertLessThan(patched.bidding.blindPolicy.phaseBlock4.early, 1.0)
        XCTAssertGreaterThan(patched.bidding.blindPolicy.phaseBlock4.late, 1.0)
    }

    // MARK: - Fitness / guardrail scoring semantics (plan 02)

    func testFitnessScoring_samePrimaryFitness_worseGuardrailLosesToBetterGuardrail() {
        let config = ToolBotTuning.SelfPlayEvolutionConfig(
            guardrailBidAccuracyWeight: 0.5,
            guardrailOverbidWeight: 0.3
        )
        let scoring = BotSelfPlayEvolutionEngine.FitnessScoringConfig(config: config)
        let primary = 1.0
        let worseGuardrail = scoring.guardrailPenalty(
            bidAccuracyRate: 0.5,
            overbidRate: 0.4,
            blindSuccessRate: nil,
            penaltyTargetRate: nil,
            earlyJokerSpendRate: nil,
            leftNeighborPremiumAssistRate: nil,
            jokerWishWinRate: nil
        )
        let betterGuardrail = scoring.guardrailPenalty(
            bidAccuracyRate: 0.9,
            overbidRate: 0.1,
            blindSuccessRate: nil,
            penaltyTargetRate: nil,
            earlyJokerSpendRate: nil,
            leftNeighborPremiumAssistRate: nil,
            jokerWishWinRate: nil
        )
        let finalWorse = primary - worseGuardrail
        let finalBetter = primary - betterGuardrail
        XCTAssertGreaterThan(finalBetter, finalWorse, "Better guardrail profile must yield higher final fitness")
    }

    func testFitnessScoring_strongWinRateDrop_notCompensatedBySecondaryMetrics() {
        let config = ToolBotTuning.SelfPlayEvolutionConfig(
            fitnessWinRateWeight: 1.0,
            fitnessScoreDiffWeight: 0.5
        )
        let scoring = BotSelfPlayEvolutionEngine.FitnessScoringConfig(config: config)
        let primaryLowWinRate = scoring.primaryFitness(
            winRate: 0.2,
            averageScoreDiff: 100,
            averageUnderbidLoss: 0,
            averagePremiumAssistLoss: 0,
            averagePremiumPenaltyTargetLoss: 0
        )
        let primaryHighWinRate = scoring.primaryFitness(
            winRate: 0.8,
            averageScoreDiff: 0,
            averageUnderbidLoss: 0,
            averagePremiumAssistLoss: 0,
            averagePremiumPenaltyTargetLoss: 0
        )
        XCTAssertGreaterThan(primaryHighWinRate, primaryLowWinRate, "High winRate must dominate over scoreDiff")
    }

    func testFitnessScoring_missingGuardrailData_givesZeroPenaltyForThatMetric() {
        let config = ToolBotTuning.SelfPlayEvolutionConfig(guardrailBidAccuracyWeight: 1.0)
        let scoring = BotSelfPlayEvolutionEngine.FitnessScoringConfig(config: config)
        let penaltyWithData = scoring.guardrailPenalty(
            bidAccuracyRate: 0.5,
            overbidRate: nil,
            blindSuccessRate: nil,
            penaltyTargetRate: nil,
            earlyJokerSpendRate: nil,
            leftNeighborPremiumAssistRate: nil,
            jokerWishWinRate: nil
        )
        let penaltyWithoutData = scoring.guardrailPenalty(
            bidAccuracyRate: nil,
            overbidRate: nil,
            blindSuccessRate: nil,
            penaltyTargetRate: nil,
            earlyJokerSpendRate: nil,
            leftNeighborPremiumAssistRate: nil,
            jokerWishWinRate: nil
        )
        XCTAssertEqual(penaltyWithData, 0.5, accuracy: 1e-6, "With data: (1 - 0.5) * 1 = 0.5")
        XCTAssertEqual(penaltyWithoutData, 0.0, accuracy: 1e-6, "Missing data must contribute 0")
    }

    func testFitnessScoring_baselineConfig_zeroGuardrailReproducesFinalEqualsPrimary() {
        let config = ToolBotTuning.SelfPlayEvolutionConfig(
            guardrailBidAccuracyWeight: 0,
            guardrailOverbidWeight: 0,
            guardrailBlindSuccessWeight: 0,
            guardrailPenaltyTargetWeight: 0,
            guardrailEarlyJokerSpendWeight: 0,
            guardrailLeftNeighborPremiumAssistWeight: 0,
            guardrailJokerWishWinWeight: 0
        )
        let scoring = BotSelfPlayEvolutionEngine.FitnessScoringConfig(config: config)
        let primary = scoring.primaryFitness(
            winRate: 0.5,
            averageScoreDiff: 0,
            averageUnderbidLoss: 0,
            averagePremiumAssistLoss: 0,
            averagePremiumPenaltyTargetLoss: 0
        )
        let guardrail = scoring.guardrailPenalty(
            bidAccuracyRate: 0.7,
            overbidRate: 0.2,
            blindSuccessRate: 0.8,
            penaltyTargetRate: 0.1,
            earlyJokerSpendRate: 0.3,
            leftNeighborPremiumAssistRate: 0.1,
            jokerWishWinRate: 0.6
        )
        XCTAssertEqual(guardrail, 0.0, accuracy: 1e-6, "Zero weights => no guardrail penalty")
        XCTAssertEqual(primary - guardrail, primary, accuracy: 1e-6, "finalFitness equals primary when guardrail is 0")
    }

    func testFitnessScoring_guardrailThresholds_onlyPenalizeOutsideAcceptedBand() {
        let config = ToolBotTuning.SelfPlayEvolutionConfig(
            guardrailBidAccuracyWeight: 1.0,
            guardrailOverbidWeight: 1.0,
            guardrailBidAccuracyMinimum: 0.60,
            guardrailOverbidMaximum: 0.40
        )
        let scoring = BotSelfPlayEvolutionEngine.FitnessScoringConfig(config: config)

        let withinThreshold = scoring.guardrailPenalty(
            bidAccuracyRate: 0.75,
            overbidRate: 0.30,
            blindSuccessRate: nil,
            penaltyTargetRate: nil,
            earlyJokerSpendRate: nil,
            leftNeighborPremiumAssistRate: nil,
            jokerWishWinRate: nil
        )
        let outsideThreshold = scoring.guardrailPenalty(
            bidAccuracyRate: 0.30,
            overbidRate: 0.70,
            blindSuccessRate: nil,
            penaltyTargetRate: nil,
            earlyJokerSpendRate: nil,
            leftNeighborPremiumAssistRate: nil,
            jokerWishWinRate: nil
        )

        XCTAssertEqual(withinThreshold, 0.0, accuracy: 1e-6)
        XCTAssertGreaterThan(outsideThreshold, 0.0)
    }

    func testEvaluateHeadToHead_missingGuardrailCoverageDoesNotApplyPenalty() {
        let tuning = ToolBotTuning(difficulty: .hard)
        let config = ToolBotTuning.SelfPlayEvolutionConfig(
            runMode: .baselineOnly,
            gamesPerCandidate: 1,
            roundsPerGame: 2,
            playerCount: 3,
            cardsPerRoundRange: 1...2,
            useFullMatchRules: false,
            guardrailBlindSuccessWeight: 1.0,
            guardrailJokerWishWinWeight: 1.0
        )

        let result = ToolBotTuning.evaluateHeadToHead(
            candidateTuning: tuning,
            opponentTuning: tuning,
            config: config,
            seed: 20260307
        )

        XCTAssertEqual(result.guardrailPenalty, 0.0, accuracy: 1e-6)
        XCTAssertEqual(result.finalFitness, result.primaryFitness, accuracy: 1e-6)
    }

    // MARK: - Candidate result contract (PR1)

    func testEvaluateCandidate_sameInputs_returnsIdenticalCompositeResult() {
        let tuning = ToolBotTuning(difficulty: .hard)
        let config = ToolBotTuning.SelfPlayEvolutionConfig(
            gamesPerCandidate: 2,
            roundsPerGame: 2,
            playerCount: 3,
            cardsPerRoundRange: 1...2,
            useFullMatchRules: false
        )
        let fitnessScoring = BotSelfPlayEvolutionEngine.FitnessScoringConfig(config: config)
        let executionConfig = BotSelfPlayEvolutionEngine.EvolutionExecutionConfig(
            playerCount: 3,
            roundsPerGame: 2,
            cardsPerRoundRange: 1...2,
            useFullMatchRules: false,
            rotateCandidateAcrossSeats: false,
            fitnessScoring: fitnessScoring
        )
        let baseSeeds: [UInt64] = [0x5EED, 0x6EED]

        let result1 = BotSelfPlayEvolutionEngine.evaluateCandidate(
            candidateTuning: tuning,
            opponentTuning: tuning,
            config: executionConfig,
            baseSeeds: baseSeeds,
            generationIndex: 0,
            candidateIndex: 0
        )
        let result2 = BotSelfPlayEvolutionEngine.evaluateCandidate(
            candidateTuning: tuning,
            opponentTuning: tuning,
            config: executionConfig,
            baseSeeds: baseSeeds,
            generationIndex: 0,
            candidateIndex: 0
        )

        XCTAssertEqual(result1.fitnessBreakdown.finalFitness, result2.fitnessBreakdown.finalFitness, accuracy: 1e-9)
        XCTAssertEqual(result1.fitnessBreakdown.winRate, result2.fitnessBreakdown.winRate, accuracy: 1e-9)
        XCTAssertEqual(result1.candidateSummary.gamesCount, result2.candidateSummary.gamesCount)
        XCTAssertEqual(result1.candidateSummary.seatRotationsCount, result2.candidateSummary.seatRotationsCount)
        XCTAssertEqual(result1.aggregatedMetrics.totalScores, result2.aggregatedMetrics.totalScores)
        XCTAssertEqual(result1.aggregatedMetrics.underbidLosses, result2.aggregatedMetrics.underbidLosses)
    }

    func testEvaluateCandidate_noSharedMutableState_sameInputsSameResult() {
        let tuning = ToolBotTuning(difficulty: .hard)
        let config = ToolBotTuning.SelfPlayEvolutionConfig(
            gamesPerCandidate: 1,
            roundsPerGame: 2,
            playerCount: 3,
            cardsPerRoundRange: 1...2,
            useFullMatchRules: false
        )
        let fitnessScoring = BotSelfPlayEvolutionEngine.FitnessScoringConfig(config: config)
        let executionConfig = BotSelfPlayEvolutionEngine.EvolutionExecutionConfig(
            playerCount: 3,
            roundsPerGame: 2,
            cardsPerRoundRange: 1...2,
            useFullMatchRules: false,
            rotateCandidateAcrossSeats: false,
            fitnessScoring: fitnessScoring
        )
        let baseSeeds: [UInt64] = [0x7EED]

        let a = BotSelfPlayEvolutionEngine.evaluateCandidate(
            candidateTuning: tuning,
            opponentTuning: tuning,
            config: executionConfig,
            baseSeeds: baseSeeds,
            generationIndex: 1,
            candidateIndex: 2
        )
        let b = BotSelfPlayEvolutionEngine.evaluateCandidate(
            candidateTuning: tuning,
            opponentTuning: tuning,
            config: executionConfig,
            baseSeeds: baseSeeds,
            generationIndex: 1,
            candidateIndex: 2
        )

        XCTAssertEqual(a.fitnessBreakdown.fitness, b.fitnessBreakdown.fitness, accuracy: 1e-9)
        XCTAssertEqual(a.aggregatedMetrics.totalScores, b.aggregatedMetrics.totalScores)
    }

    func testMaxParallelEvaluations_auto_resolvesAndCaps() {
        let auto = BotSelfPlayEvolutionEngine.SelfPlayEvolutionConfig.MaxParallelEvaluations.auto
        let resolved = auto.resolved(availableProcessors: 16)
        XCTAssertGreaterThanOrEqual(resolved, 1)
        XCTAssertLessThanOrEqual(resolved, 8)
        XCTAssertEqual(resolved, 8, "With 16 processors auto should cap at 8")

        let resolvedOne = auto.resolved(availableProcessors: 1)
        XCTAssertEqual(resolvedOne, 1)

        let resolvedFour = auto.resolved(availableProcessors: 4)
        XCTAssertEqual(resolvedFour, 4)
    }

    func testEvaluateCandidate_seedRepeatability_fullResultContract() {
        let tuning = ToolBotTuning(difficulty: .hard)
        let config = ToolBotTuning.SelfPlayEvolutionConfig(
            gamesPerCandidate: 2,
            roundsPerGame: 2,
            playerCount: 3,
            cardsPerRoundRange: 1...2,
            useFullMatchRules: false
        )
        let fitnessScoring = BotSelfPlayEvolutionEngine.FitnessScoringConfig(config: config)
        let executionConfig = BotSelfPlayEvolutionEngine.EvolutionExecutionConfig(
            playerCount: 3,
            roundsPerGame: 2,
            cardsPerRoundRange: 1...2,
            useFullMatchRules: false,
            rotateCandidateAcrossSeats: false,
            fitnessScoring: fitnessScoring
        )
        let baseSeeds: [UInt64] = [0x8EED, 0x9EED]

        let r1 = BotSelfPlayEvolutionEngine.evaluateCandidate(
            candidateTuning: tuning,
            opponentTuning: tuning,
            config: executionConfig,
            baseSeeds: baseSeeds,
            generationIndex: 0,
            candidateIndex: 0
        )
        let r2 = BotSelfPlayEvolutionEngine.evaluateCandidate(
            candidateTuning: tuning,
            opponentTuning: tuning,
            config: executionConfig,
            baseSeeds: baseSeeds,
            generationIndex: 0,
            candidateIndex: 0
        )

        XCTAssertEqual(r1.fitnessBreakdown.finalFitness, r2.fitnessBreakdown.finalFitness, accuracy: 1e-9)
        XCTAssertEqual(r1.fitnessBreakdown.legacyFitness, r2.fitnessBreakdown.legacyFitness, accuracy: 1e-9)
        XCTAssertEqual(r1.fitnessBreakdown.winRate, r2.fitnessBreakdown.winRate, accuracy: 1e-9)
        XCTAssertEqual(r1.aggregatedMetrics.totalScores, r2.aggregatedMetrics.totalScores)
        XCTAssertEqual(r1.aggregatedMetrics.underbidLosses, r2.aggregatedMetrics.underbidLosses)
        XCTAssertEqual(r1.aggregatedMetrics.premiumCaptureRates, r2.aggregatedMetrics.premiumCaptureRates)
        XCTAssertEqual(r1.candidateSummary.gamesCount, 2)
        XCTAssertEqual(r1.candidateSummary.seatRotationsCount, 1)
        XCTAssertEqual(r1.candidateSummary.evaluationsCount, 2)
    }

    // MARK: - Progress and summary determinism (PR3)

    /// Progress events in parallel mode must match the same logical order as sequential (by stage, generationIndex, candidateIndex).
    func testProgressEvents_parallelMode_sameLogicalOrderAsSequential() async {
        let baseTuning = ToolBotTuning(difficulty: .hard)
        let seed: UInt64 = 0x0A03
        let configSequential = ToolBotTuning.SelfPlayEvolutionConfig(
            runMode: .evolution,
            maxParallelEvaluations: .one,
            populationSize: 4,
            generations: 2,
            gamesPerCandidate: 2,
            roundsPerGame: 2,
            playerCount: 3,
            cardsPerRoundRange: 1...2,
            useFullMatchRules: false
        )
        let configParallel = ToolBotTuning.SelfPlayEvolutionConfig(
            runMode: .evolution,
            maxParallelEvaluations: .two,
            populationSize: 4,
            generations: 2,
            gamesPerCandidate: 2,
            roundsPerGame: 2,
            playerCount: 3,
            cardsPerRoundRange: 1...2,
            useFullMatchRules: false
        )

        var sequentialTuples: [(String, Int?, Int?)] = []
        var parallelTuples: [(String, Int?, Int?)] = []

        _ = ToolBotTuning.evolveViaSelfPlay(
            baseTuning: baseTuning,
            config: configSequential,
            seed: seed,
            progress: { event in
                let key = (String(describing: event.stage), event.generationIndex, event.candidateIndex)
                sequentialTuples.append(key)
            }
        )

        let resultParallel = await BotSelfPlayEvolutionEngine.evolveViaSelfPlayAsync(
            baseTuning: baseTuning,
            config: configParallel,
            seed: seed,
            progress: { event in
                let key = (String(describing: event.stage), event.generationIndex, event.candidateIndex)
                parallelTuples.append(key)
            }
        )
        _ = resultParallel

        XCTAssertEqual(
            sequentialTuples.count,
            parallelTuples.count,
            "Same config (except maxParallel) must produce same number of progress events"
        )
        for (idx, seq) in sequentialTuples.enumerated() {
            let par = parallelTuples[idx]
            XCTAssertEqual(seq.0, par.0, "Event \(idx): stage")
            XCTAssertEqual(seq.1, par.1, "Event \(idx): generationIndex")
            XCTAssertEqual(seq.2, par.2, "Event \(idx): candidateIndex")
        }
    }

    /// Formatter produces identical run-result summary lines for the same run result (determinism).
    func testFormatter_runResultSummaryLines_sameResultSameOutput() {
        let result = ToolBotTuning.evolveViaSelfPlay(
            baseTuning: ToolBotTuning(difficulty: .hard),
            config: ToolBotTuning.SelfPlayEvolutionConfig(
                runMode: .baselineOnly,
                gamesPerCandidate: 1,
                roundsPerGame: 2,
                playerCount: 3,
                cardsPerRoundRange: 1...2,
                useFullMatchRules: false
            ),
            seed: 0xF07A77E
        )
        let snapshot = makeSummarySnapshot(from: result)
        let lines1 = TrainingRunResultFormatter.formatRunResultSummaryLines(selectedSeed: 0xF07A77E, result: snapshot)
        let lines2 = TrainingRunResultFormatter.formatRunResultSummaryLines(selectedSeed: 0xF07A77E, result: snapshot)
        XCTAssertEqual(lines1, lines2, "Same run result must yield identical summary lines")
        XCTAssertFalse(lines1.isEmpty)
        let lastLine = lines1.last ?? ""
        XCTAssertTrue(lastLine.hasPrefix("generationBestFitness="), "Summary must end with generationBestFitness line (ordered by generation index)")
    }

    /// Candidate-evaluated progress events in one generation are emitted strictly by candidateIndex order (no interleaved noise).
    func testProgress_candidateEvaluatedEvents_orderedByCandidateIndex() async {
        let baseTuning = ToolBotTuning(difficulty: .hard)
        let config = ToolBotTuning.SelfPlayEvolutionConfig(
            runMode: .evolution,
            maxParallelEvaluations: .four,
            populationSize: 6,
            generations: 1,
            gamesPerCandidate: 1,
            roundsPerGame: 2,
            playerCount: 3,
            cardsPerRoundRange: 1...2,
            useFullMatchRules: false
        )
        var candidateIndicesInOrder: [Int] = []
        _ = await BotSelfPlayEvolutionEngine.evolveViaSelfPlayAsync(
            baseTuning: baseTuning,
            config: config,
            seed: 0xCAAD1D,
            progress: { event in
                if case .candidateEvaluated = event.stage, let c = event.candidateIndex {
                    candidateIndicesInOrder.append(c)
                }
            }
        )
        let expected = [0, 1, 2, 3, 4, 5]
        XCTAssertEqual(candidateIndicesInOrder, expected, "candidateEvaluated events must be flushed in candidateIndex order")
    }

    func testOutputCandidateSelectionDecision_fallsBackToSelectedSeedWhenMarginBelowThreshold() {
        let tuning = ToolBotTuning(difficulty: .hard)
        let selected = BotTrainingRunner.OutputCandidateSelectionScore(
            option: BotTrainingRunner.OutputCandidateOption(
                label: "selected_seed_20260222",
                runtimeGeneSource: "selectedSeed",
                tuning: tuning
            ),
            primaryFinalFitnessEffectSize: 0.020,
            primaryWinRateEffectSize: 0.000,
            primaryScoreDiffEffectSize: 0.000,
            primaryUnderbidEffectSize: 0.000
        )
        let preferred = BotTrainingRunner.OutputCandidateSelectionScore(
            option: BotTrainingRunner.OutputCandidateOption(
                label: "seed_20260220",
                runtimeGeneSource: "primaryValidatedSeed_20260220",
                tuning: tuning
            ),
            primaryFinalFitnessEffectSize: 0.035,
            primaryWinRateEffectSize: 0.000,
            primaryScoreDiffEffectSize: 0.000,
            primaryUnderbidEffectSize: -10.0
        )
        let aggregate = BotTrainingRunner.OutputCandidateSelectionScore(
            option: BotTrainingRunner.OutputCandidateOption(
                label: "ensemble_aggregate",
                runtimeGeneSource: "ensembleAggregate",
                tuning: tuning
            ),
            primaryFinalFitnessEffectSize: -0.010,
            primaryWinRateEffectSize: 0.000,
            primaryScoreDiffEffectSize: 0.000,
            primaryUnderbidEffectSize: 5.0
        )

        let decision = BotTrainingRunner.resolveOutputCandidateSelectionDecision(
            scores: [selected, preferred, aggregate],
            selectedSeedLabel: selected.option.label,
            minimumPrimaryEffectMargin: 0.03
        )

        XCTAssertEqual(decision.preferred.option.label, preferred.option.label)
        XCTAssertEqual(decision.chosen.option.label, selected.option.label)
        XCTAssertEqual(
            decision.fallbackReason,
            "preferredPrimaryEffectDidNotBeatSelectedSeedByMinimumMargin"
        )
        XCTAssertEqual(decision.selectionMargin, 0.015, accuracy: 0.000_001)
    }

    func testOutputCandidateSelectionDecision_keepsPreferredCandidateWhenMarginClearsThreshold() {
        let tuning = ToolBotTuning(difficulty: .hard)
        let selected = BotTrainingRunner.OutputCandidateSelectionScore(
            option: BotTrainingRunner.OutputCandidateOption(
                label: "selected_seed_20260222",
                runtimeGeneSource: "selectedSeed",
                tuning: tuning
            ),
            primaryFinalFitnessEffectSize: 0.010,
            primaryWinRateEffectSize: 0.000,
            primaryScoreDiffEffectSize: 0.000,
            primaryUnderbidEffectSize: 0.000
        )
        let preferred = BotTrainingRunner.OutputCandidateSelectionScore(
            option: BotTrainingRunner.OutputCandidateOption(
                label: "seed_20260220",
                runtimeGeneSource: "primaryValidatedSeed_20260220",
                tuning: tuning
            ),
            primaryFinalFitnessEffectSize: 0.055,
            primaryWinRateEffectSize: 0.010,
            primaryScoreDiffEffectSize: 1.000,
            primaryUnderbidEffectSize: -10.0
        )

        let decision = BotTrainingRunner.resolveOutputCandidateSelectionDecision(
            scores: [selected, preferred],
            selectedSeedLabel: selected.option.label,
            minimumPrimaryEffectMargin: 0.03
        )

        XCTAssertEqual(decision.preferred.option.label, preferred.option.label)
        XCTAssertEqual(decision.chosen.option.label, preferred.option.label)
        XCTAssertEqual(decision.fallbackReason, "none")
        XCTAssertEqual(decision.selectionMargin, 0.045, accuracy: 0.000_001)
        XCTAssertEqual(decision.rankedScores.first?.option.label, preferred.option.label)
    }

    func testOutputCandidateSelectionDecision_prefersLowerStrengthVariantWhenMetricsTie() {
        let tuning = ToolBotTuning(difficulty: .hard)
        let selected = BotTrainingRunner.OutputCandidateSelectionScore(
            option: BotTrainingRunner.OutputCandidateOption(
                label: "selected_seed_20260222",
                runtimeGeneSource: "selectedSeed",
                tuning: tuning
            ),
            primaryFinalFitnessEffectSize: 0.000,
            primaryWinRateEffectSize: 0.000,
            primaryScoreDiffEffectSize: 0.000,
            primaryUnderbidEffectSize: 0.000
        )
        let fullStrength = BotTrainingRunner.OutputCandidateSelectionScore(
            option: BotTrainingRunner.OutputCandidateOption(
                label: "seed_20260220",
                runtimeGeneSource: "primaryValidatedSeed_20260220",
                tuning: tuning,
                runtimePolicyStrength: 1.0
            ),
            primaryFinalFitnessEffectSize: 0.060,
            primaryWinRateEffectSize: 0.010,
            primaryScoreDiffEffectSize: 5.000,
            primaryUnderbidEffectSize: -10.0
        )
        let reducedStrength = BotTrainingRunner.OutputCandidateSelectionScore(
            option: BotTrainingRunner.OutputCandidateOption(
                label: "seed_20260220_patch75",
                runtimeGeneSource: "primaryValidatedSeed_20260220_patch75",
                tuning: tuning,
                runtimePolicyStrength: 0.75
            ),
            primaryFinalFitnessEffectSize: 0.060,
            primaryWinRateEffectSize: 0.010,
            primaryScoreDiffEffectSize: 5.000,
            primaryUnderbidEffectSize: -10.0
        )

        let decision = BotTrainingRunner.resolveOutputCandidateSelectionDecision(
            scores: [selected, fullStrength, reducedStrength],
            selectedSeedLabel: selected.option.label,
            minimumPrimaryEffectMargin: 0.03
        )

        XCTAssertEqual(decision.chosen.option.label, reducedStrength.option.label)
        XCTAssertEqual(decision.rankedScores.first?.option.label, reducedStrength.option.label)
    }

    func testOutputCandidateSelectionDecision_prefersNarrowerScopeVariantWhenMetricsTie() {
        let tuning = ToolBotTuning(difficulty: .hard)
        let selected = BotTrainingRunner.OutputCandidateSelectionScore(
            option: BotTrainingRunner.OutputCandidateOption(
                label: "selected_seed_20260222",
                runtimeGeneSource: "selectedSeed",
                tuning: tuning
            ),
            primaryFinalFitnessEffectSize: 0.000,
            primaryWinRateEffectSize: 0.000,
            primaryScoreDiffEffectSize: 0.000,
            primaryUnderbidEffectSize: 0.000
        )
        let fullScope = BotTrainingRunner.OutputCandidateSelectionScore(
            option: BotTrainingRunner.OutputCandidateOption(
                label: "seed_20260220",
                runtimeGeneSource: "primaryValidatedSeed_20260220",
                tuning: tuning,
                runtimePolicyScopeVariant: "full",
                runtimePolicyActiveGroupCount: 3
            ),
            primaryFinalFitnessEffectSize: 0.060,
            primaryWinRateEffectSize: 0.010,
            primaryScoreDiffEffectSize: 5.000,
            primaryUnderbidEffectSize: -10.0
        )
        let narrowerScope = BotTrainingRunner.OutputCandidateSelectionScore(
            option: BotTrainingRunner.OutputCandidateOption(
                label: "seed_20260220_ranking_rollout",
                runtimeGeneSource: "primaryValidatedSeed_20260220_rankingRollout",
                tuning: tuning,
                runtimePolicyScopeVariant: "ranking_rollout",
                runtimePolicyActiveGroupCount: 2
            ),
            primaryFinalFitnessEffectSize: 0.060,
            primaryWinRateEffectSize: 0.010,
            primaryScoreDiffEffectSize: 5.000,
            primaryUnderbidEffectSize: -10.0
        )

        let decision = BotTrainingRunner.resolveOutputCandidateSelectionDecision(
            scores: [selected, fullScope, narrowerScope],
            selectedSeedLabel: selected.option.label,
            minimumPrimaryEffectMargin: 0.03
        )

        XCTAssertEqual(decision.chosen.option.label, narrowerScope.option.label)
        XCTAssertEqual(decision.rankedScores.first?.option.label, narrowerScope.option.label)
    }

    func testRuntimePolicyEvolutionPatch_scaledTowardIdentityReducesPatchMagnitude() {
        let patch = BotSelfPlayEvolutionEngine.RuntimePolicyEvolutionPatch(
            rankingMatchCatchUpScale: 1.20,
            rankingPremiumScale: 0.80,
            rankingPenaltyAvoidScale: 1.10,
            jokerDeclarationScale: 1.00,
            rolloutActivationScale: 0.90,
            rolloutAdjustmentScale: 1.25,
            endgameActivationScale: 1.00,
            endgameAdjustmentScale: 1.00,
            opponentPressureScale: 1.30,
            phaseRankingScale: 0.85,
            phaseRolloutScale: 1.15,
            phaseJokerScale: 1.00,
            phaseBlindScale: 1.00
        )

        let scaled = patch.scaledTowardIdentity(strength: 0.5)

        XCTAssertEqual(scaled.rankingMatchCatchUpScale, 1.10, accuracy: 0.000_001)
        XCTAssertEqual(scaled.rankingPremiumScale, 0.90, accuracy: 0.000_001)
        XCTAssertEqual(scaled.rolloutAdjustmentScale, 1.125, accuracy: 0.000_001)
        XCTAssertEqual(scaled.opponentPressureScale, 1.15, accuracy: 0.000_001)
        XCTAssertEqual(scaled.phaseRankingScale, 0.925, accuracy: 0.000_001)
    }

    func testRuntimePolicyEvolutionPatch_maskingGroupsRevertsExcludedScalesToIdentity() {
        let patch = BotSelfPlayEvolutionEngine.RuntimePolicyEvolutionPatch(
            rankingMatchCatchUpScale: 1.20,
            rankingPremiumScale: 0.80,
            rankingPenaltyAvoidScale: 1.10,
            jokerDeclarationScale: 1.00,
            rolloutActivationScale: 0.90,
            rolloutAdjustmentScale: 1.25,
            endgameActivationScale: 1.00,
            endgameAdjustmentScale: 1.00,
            opponentPressureScale: 1.30,
            phaseRankingScale: 0.85,
            phaseRolloutScale: 1.15,
            phaseJokerScale: 1.00,
            phaseBlindScale: 1.00
        )

        let masked = patch.maskingRuntimePolicyGroups(
            keepRanking: true,
            keepRollout: false,
            keepOpponentModeling: false
        )

        XCTAssertEqual(masked.rankingMatchCatchUpScale, 1.20, accuracy: 0.000_001)
        XCTAssertEqual(masked.rankingPremiumScale, 0.80, accuracy: 0.000_001)
        XCTAssertEqual(masked.rolloutActivationScale, 1.00, accuracy: 0.000_001)
        XCTAssertEqual(masked.rolloutAdjustmentScale, 1.00, accuracy: 0.000_001)
        XCTAssertEqual(masked.phaseRolloutScale, 1.00, accuracy: 0.000_001)
        XCTAssertEqual(masked.opponentPressureScale, 1.00, accuracy: 0.000_001)
        XCTAssertEqual(masked.phaseRankingScale, 0.85, accuracy: 0.000_001)
    }

    func testSelfPlayEvolution_reportsDiversityTelemetryPerGeneration() {
        let result = ToolBotTuning.evolveViaSelfPlay(
            baseTuning: ToolBotTuning(difficulty: .hard),
            config: ToolBotTuning.SelfPlayEvolutionConfig(
                populationSize: 4,
                generations: 2,
                gamesPerCandidate: 1,
                roundsPerGame: 2,
                playerCount: 3,
                cardsPerRoundRange: 1...2,
                eliteCount: 1,
                mutationChance: 0.25,
                mutationMagnitude: 0.12,
                selectionPoolRatio: 0.5,
                useFullMatchRules: false,
                stagnationWindow: 3,
                minimumMeaningfulImprovement: 0.02
            ),
            seed: 2026_0315
        )

        XCTAssertEqual(result.generationAverageDistanceToElite.count, result.completedGenerations)
        XCTAssertEqual(result.generationAveragePairwiseDistance.count, result.completedGenerations)
        XCTAssertEqual(result.generationUniqueGenomeRatio.count, result.completedGenerations)
        XCTAssertEqual(result.generationGenerationsWithoutImprovement.count, result.completedGenerations)
        XCTAssertEqual(
            result.finalAverageDistanceToElite,
            result.generationAverageDistanceToElite.last ?? 0.0,
            accuracy: 0.000_001
        )
        XCTAssertEqual(
            result.finalAveragePairwiseDistance,
            result.generationAveragePairwiseDistance.last ?? 0.0,
            accuracy: 0.000_001
        )
        XCTAssertEqual(
            result.finalUniqueGenomeRatio,
            result.generationUniqueGenomeRatio.last ?? 1.0,
            accuracy: 0.000_001
        )
        XCTAssertEqual(
            result.finalGenerationsWithoutImprovement,
            result.generationGenerationsWithoutImprovement.last ?? 0
        )
        XCTAssertTrue(result.generationAverageDistanceToElite.allSatisfy { $0.isFinite && $0 >= 0.0 })
        XCTAssertTrue(result.generationAveragePairwiseDistance.allSatisfy { $0.isFinite && $0 >= 0.0 })
        XCTAssertTrue(result.generationUniqueGenomeRatio.allSatisfy { $0.isFinite && $0 > 0.0 && $0 <= 1.0 })
        XCTAssertGreaterThanOrEqual(result.lastMeaningfulImprovementGeneration, 0)
        XCTAssertLessThanOrEqual(result.lastMeaningfulImprovementGeneration, result.completedGenerations)
    }

    func testSelfPlayEvolution_stagnationDetectionFlagsWhenMeaningfulImprovementNeverClearsThreshold() {
        let result = ToolBotTuning.evolveViaSelfPlay(
            baseTuning: ToolBotTuning(difficulty: .hard),
            config: ToolBotTuning.SelfPlayEvolutionConfig(
                populationSize: 4,
                generations: 2,
                gamesPerCandidate: 1,
                roundsPerGame: 2,
                playerCount: 3,
                cardsPerRoundRange: 1...2,
                eliteCount: 1,
                mutationChance: 0.25,
                mutationMagnitude: 0.12,
                selectionPoolRatio: 0.5,
                useFullMatchRules: false,
                stagnationWindow: 1,
                minimumMeaningfulImprovement: 10.0
            ),
            seed: 2026_0316
        )

        XCTAssertTrue(result.isStagnating)
        XCTAssertEqual(result.lastMeaningfulImprovementGeneration, 0)
        XCTAssertEqual(result.finalGenerationsWithoutImprovement, result.completedGenerations)
        XCTAssertEqual(
            result.generationGenerationsWithoutImprovement,
            Array(1...result.completedGenerations)
        )
    }

    private func makeSummarySnapshot(
        from result: ToolBotTuning.SelfPlayEvolutionResult
    ) -> TrainingRunResultSummarySnapshot {
        return TrainingRunResultSummarySnapshot(
            baselineFitness: result.baselineFitness,
            bestFitness: result.bestFitness,
            baselineLegacyFitness: result.baselineLegacyFitness,
            bestLegacyFitness: result.bestLegacyFitness,
            baselinePrimaryFitness: result.baselinePrimaryFitness,
            bestPrimaryFitness: result.bestPrimaryFitness,
            baselineGuardrailPenalty: result.baselineGuardrailPenalty,
            bestGuardrailPenalty: result.bestGuardrailPenalty,
            baselineFinalFitness: result.baselineFinalFitness,
            bestFinalFitness: result.bestFinalFitness,
            improvement: result.improvement,
            completedGenerations: result.completedGenerations,
            stoppedEarly: result.stoppedEarly,
            generationBestFitness: result.generationBestFitness
        )
    }
}
#endif
