//
//  BotBiddingServiceTests.swift
//  JockerTests
//
//  Created by Codex on 15.02.2026.
//

import XCTest
@testable import Jocker

final class BotBiddingServiceTests: XCTestCase {
    func testMakeBid_respectsForbiddenDealerBid() {
        let service = BotBiddingService()
        let hand: [Card] = [
            .regular(suit: .hearts, rank: .ace),
            .regular(suit: .hearts, rank: .king),
            .regular(suit: .spades, rank: .queen)
        ]

        let bid = service.makeBid(
            hand: hand,
            cardsInRound: 3,
            trump: .hearts,
            forbiddenBid: 2
        )

        XCTAssertNotEqual(bid, 2)
        XCTAssertGreaterThanOrEqual(bid, 0)
        XCTAssertLessThanOrEqual(bid, 3)
    }

    func testMakeBid_strongerHandProducesHigherBidThanWeakHand() {
        let service = BotBiddingService()

        let weakHand: [Card] = [
            .regular(suit: .diamonds, rank: .seven),
            .regular(suit: .clubs, rank: .eight),
            .regular(suit: .spades, rank: .nine),
            .regular(suit: .diamonds, rank: .ten)
        ]

        let strongHand: [Card] = [
            .joker,
            .joker,
            .regular(suit: .hearts, rank: .ace),
            .regular(suit: .hearts, rank: .king)
        ]

        let weakBid = service.makeBid(
            hand: weakHand,
            cardsInRound: 4,
            trump: .hearts,
            forbiddenBid: nil
        )
        let strongBid = service.makeBid(
            hand: strongHand,
            cardsInRound: 4,
            trump: .hearts,
            forbiddenBid: nil
        )

        XCTAssertGreaterThan(strongBid, weakBid)
    }
}
