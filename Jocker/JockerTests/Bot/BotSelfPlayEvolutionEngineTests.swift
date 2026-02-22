//
//  BotSelfPlayEvolutionEngineTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
@testable import Jocker

final class BotSelfPlayEvolutionEngineTests: XCTestCase {

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
        return (0..<count).map { _ in
            BotBiddingService(tuning: BotTuning(difficulty: .hard))
        }
    }
}
