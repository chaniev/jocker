//
//  BotSelfPlayEvolutionEngineTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest

#if canImport(JockerSelfPlayTools)
@testable import JockerSelfPlayTools

final class BotSelfPlayEvolutionEngineTests: XCTestCase {

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

        XCTAssertEqual(first.totalScores, second.totalScores)
        XCTAssertEqual(first.underbidLosses, second.underbidLosses)
        XCTAssertEqual(first.blindBidRatesBlock4, second.blindBidRatesBlock4)
        XCTAssertEqual(first.leftNeighborPremiumAssistRates, second.leftNeighborPremiumAssistRates)
    }

    func testSimulateGame_legacyModeProducesSeatAlignedMetrics() {
        let playerCount = 3
        let outcome = BotSelfPlayEvolutionEngine.simulateGame(
            tuningsBySeat: makeTunings(count: playerCount),
            rounds: 4,
            cardsPerRoundRange: 2...4,
            seed: 20260307,
            useFullMatchRules: false
        )

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
        let hands: [[Card]] = [
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

    private func makeBiddingServices(count: Int) -> [BotBiddingService] {
        return makeTunings(count: count).map { BotBiddingService(tuning: $0) }
    }

    private func makeTunings(count: Int) -> [BotTuning] {
        return (0..<count).map { _ in
            BotTuning(difficulty: .hard)
        }
    }

    // MARK: - Fitness / guardrail scoring semantics (plan 02)

    func testFitnessScoring_samePrimaryFitness_worseGuardrailLosesToBetterGuardrail() {
        let config = BotTuning.SelfPlayEvolutionConfig(
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
        let config = BotTuning.SelfPlayEvolutionConfig(
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
        let config = BotTuning.SelfPlayEvolutionConfig(guardrailBidAccuracyWeight: 1.0)
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
        let config = BotTuning.SelfPlayEvolutionConfig(
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
        let config = BotTuning.SelfPlayEvolutionConfig(
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
        let tuning = BotTuning(difficulty: .hard)
        let config = BotTuning.SelfPlayEvolutionConfig(
            runMode: .baselineOnly,
            gamesPerCandidate: 1,
            roundsPerGame: 2,
            playerCount: 3,
            cardsPerRoundRange: 1...2,
            useFullMatchRules: false,
            guardrailBlindSuccessWeight: 1.0,
            guardrailJokerWishWinWeight: 1.0
        )

        let result = BotTuning.evaluateHeadToHead(
            candidateTuning: tuning,
            opponentTuning: tuning,
            config: config,
            seed: 20260307
        )

        XCTAssertEqual(result.guardrailPenalty, 0.0, accuracy: 1e-6)
        XCTAssertEqual(result.finalFitness, result.primaryFitness, accuracy: 1e-6)
    }
}
#endif
