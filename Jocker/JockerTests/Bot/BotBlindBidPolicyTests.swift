//
//  BotBlindBidPolicyTests.swift
//  JockerTests
//
//  Created by Codex on 06.03.2026.
//

import XCTest
@testable import Jocker

final class BotBlindBidPolicyTests: XCTestCase {
    func testMakePreDealBlindBid_returnsNilForLeaderWithBigAdvantage() {
        let fixture = BotBlindBidPolicyTestFixture()

        let blindBid = fixture.makeBlindBid(
            playerIndex: 0,
            dealerIndex: 1,
            cardsInRound: 9,
            allowedBlindBids: Array(0...9),
            totalScores: [1200, 900, 850, 700]
        )

        XCTAssertNil(blindBid)
    }

    func testMakePreDealBlindBid_returnsAllowedBidWhenPlayerFarBehind() {
        let fixture = BotBlindBidPolicyTestFixture()

        let blindBid = fixture.makeBlindBid(
            playerIndex: 3,
            dealerIndex: 0,
            cardsInRound: 9,
            allowedBlindBids: [2, 3, 4, 5, 6],
            totalScores: [1200, 1100, 980, 700]
        )

        XCTAssertNotNil(blindBid)
        if let blindBid {
            XCTAssertTrue([2, 3, 4, 5, 6].contains(blindBid))
        }
    }

    func testMakePreDealBlindBid_inSameCatchUpScenario_dealerIsMoreConservativeThanNonDealer() {
        let fixture = BotBlindBidPolicyTestFixture()

        let nonDealerBlindBid = fixture.makeBlindBid(
            playerIndex: 1,
            dealerIndex: 0,
            cardsInRound: 4,
            allowedBlindBids: Array(0...4),
            totalScores: [1210, 1000, 980, 960]
        )
        let dealerBlindBid = fixture.makeBlindBid(
            playerIndex: 1,
            dealerIndex: 1,
            cardsInRound: 4,
            allowedBlindBids: Array(0...4),
            totalScores: [1210, 1000, 980, 960]
        )

        XCTAssertNotNil(nonDealerBlindBid)
        XCTAssertNil(dealerBlindBid)
    }

    func testMakePreDealBlindBid_isDeterministicForSameInputsWithMonteCarloLayer() {
        let fixture = BotBlindBidPolicyTestFixture()

        let first = fixture.makeBlindBid(
            playerIndex: 3,
            dealerIndex: 0,
            cardsInRound: 9,
            allowedBlindBids: [2, 3, 4, 5, 6],
            totalScores: [1200, 1100, 980, 700]
        )
        let second = fixture.makeBlindBid(
            playerIndex: 3,
            dealerIndex: 0,
            cardsInRound: 9,
            allowedBlindBids: [2, 3, 4, 5, 6],
            totalScores: [1200, 1100, 980, 700]
        )

        XCTAssertEqual(first, second)
    }
}
