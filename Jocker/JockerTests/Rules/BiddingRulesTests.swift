//
//  BiddingRulesTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
@testable import Jocker

final class BiddingRulesTests: XCTestCase {

    func testAllowedBids_nonDealerKeepsFullRange() {
        let allowed = BiddingRules.allowedBids(
            forPlayer: 2,
            dealer: 0,
            cardsInRound: 3,
            bids: [0, 1, 0, 0],
            playerCount: 4
        )

        XCTAssertEqual(allowed, [0, 1, 2, 3])
    }

    func testAllowedBids_dealerExcludesForbiddenBidInsideRange() {
        let allowed = BiddingRules.allowedBids(
            forPlayer: 1,
            dealer: 1,
            cardsInRound: 3,
            bids: [1, 0, 1, 0],
            playerCount: 4
        )

        // Other bids sum to 2, so dealer cannot bid 1.
        XCTAssertEqual(allowed, [0, 2, 3])
    }

    func testAllowedBids_dealerClampsIncomingBidsBeforeComputingForbiddenBid() {
        let allowed = BiddingRules.allowedBids(
            forPlayer: 0,
            dealer: 0,
            cardsInRound: 2,
            bids: [0, 99, -3, 1],
            playerCount: 4
        )

        // Clamped non-dealer bids become [2, 0, 1], sum=3, forbidden=-1 -> nothing removed.
        XCTAssertEqual(allowed, [0, 1, 2])
    }

    func testDealerForbiddenBid_returnsNilForNonDealerAndOutOfRange() {
        let nonDealerForbidden = BiddingRules.dealerForbiddenBid(
            forPlayer: 2,
            dealer: 1,
            cardsInRound: 3,
            bids: [0, 0, 0, 0],
            playerCount: 4
        )
        XCTAssertNil(nonDealerForbidden)

        let outOfRangeForbidden = BiddingRules.dealerForbiddenBid(
            forPlayer: 0,
            dealer: 0,
            cardsInRound: 2,
            bids: [0, 2, 2, 2],
            playerCount: 4
        )
        XCTAssertNil(outOfRangeForbidden)
    }

    func testCanChooseBlindBid_nonDealerCanChooseWithoutDependencies() {
        let canChoose = BiddingRules.canChooseBlindBid(
            forPlayer: 2,
            dealer: 0,
            blindSelections: [false, false, false, false],
            playerCount: 4
        )

        XCTAssertTrue(canChoose)
    }

    func testCanChooseBlindBid_dealerRequiresAllOtherPlayersToChooseBlind() {
        let dealer = 1

        XCTAssertFalse(
            BiddingRules.canChooseBlindBid(
                forPlayer: dealer,
                dealer: dealer,
                blindSelections: [false, false, false, false],
                playerCount: 4
            )
        )

        XCTAssertFalse(
            BiddingRules.canChooseBlindBid(
                forPlayer: dealer,
                dealer: dealer,
                blindSelections: [true, false, false, true],
                playerCount: 4
            )
        )

        XCTAssertTrue(
            BiddingRules.canChooseBlindBid(
                forPlayer: dealer,
                dealer: dealer,
                blindSelections: [true, false, true, true],
                playerCount: 4
            )
        )
    }

    func testBiddingOrder_startsFromDealerPlusOneAndWraps() {
        let order = BiddingRules.biddingOrder(dealer: 2, playerCount: 4)

        XCTAssertEqual(order, [3, 0, 1, 2])
    }

    func testNormalizedPlayerIndex_wrapsNegativeAndOverflowIndexes() {
        XCTAssertEqual(BiddingRules.normalizedPlayerIndex(-1, playerCount: 4), 3)
        XCTAssertEqual(BiddingRules.normalizedPlayerIndex(5, playerCount: 4), 1)
        XCTAssertEqual(BiddingRules.normalizedPlayerIndex(0, playerCount: 0), 0)
    }
}
