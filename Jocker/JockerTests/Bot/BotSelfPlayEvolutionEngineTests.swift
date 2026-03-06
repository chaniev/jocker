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
}
#endif
