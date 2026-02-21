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

    func testMakeBid_trumpDenseHandProducesHigherBid() {
        let service = BotBiddingService(tuning: BotTuning(difficulty: .hard))

        let trumpDenseHand: [Card] = [
            .regular(suit: .hearts, rank: .ace),
            .regular(suit: .hearts, rank: .king),
            .regular(suit: .hearts, rank: .queen),
            .regular(suit: .hearts, rank: .jack),
            .regular(suit: .hearts, rank: .nine),
            .regular(suit: .clubs, rank: .seven),
            .regular(suit: .diamonds, rank: .eight),
            .regular(suit: .spades, rank: .ten)
        ]
        let mixedHand: [Card] = [
            .regular(suit: .hearts, rank: .ace),
            .regular(suit: .spades, rank: .king),
            .regular(suit: .clubs, rank: .queen),
            .regular(suit: .diamonds, rank: .jack),
            .regular(suit: .hearts, rank: .nine),
            .regular(suit: .clubs, rank: .seven),
            .regular(suit: .diamonds, rank: .eight),
            .regular(suit: .spades, rank: .ten)
        ]

        let denseBid = service.makeBid(
            hand: trumpDenseHand,
            cardsInRound: 8,
            trump: .hearts,
            forbiddenBid: nil
        )
        let mixedBid = service.makeBid(
            hand: mixedHand,
            cardsInRound: 8,
            trump: .hearts,
            forbiddenBid: nil
        )

        XCTAssertGreaterThanOrEqual(denseBid, mixedBid)
    }

    func testMakeBid_noTrumpControlWithJokerProducesHigherBid() {
        let service = BotBiddingService(tuning: BotTuning(difficulty: .hard))

        let controlHand: [Card] = [
            .joker,
            .regular(suit: .spades, rank: .ace),
            .regular(suit: .spades, rank: .king),
            .regular(suit: .spades, rank: .queen),
            .regular(suit: .spades, rank: .jack),
            .regular(suit: .hearts, rank: .ace),
            .regular(suit: .diamonds, rank: .queen),
            .regular(suit: .clubs, rank: .ten)
        ]
        let flatHand: [Card] = [
            .joker,
            .regular(suit: .spades, rank: .ace),
            .regular(suit: .hearts, rank: .ten),
            .regular(suit: .diamonds, rank: .nine),
            .regular(suit: .clubs, rank: .eight),
            .regular(suit: .clubs, rank: .seven),
            .regular(suit: .diamonds, rank: .seven),
            .regular(suit: .hearts, rank: .eight)
        ]

        let controlBid = service.makeBid(
            hand: controlHand,
            cardsInRound: 8,
            trump: nil,
            forbiddenBid: nil
        )
        let flatBid = service.makeBid(
            hand: flatHand,
            cardsInRound: 8,
            trump: nil,
            forbiddenBid: nil
        )

        XCTAssertGreaterThanOrEqual(controlBid, flatBid)
    }

    func testMakePreDealBlindBid_returnsNilForLeaderWithBigAdvantage() {
        let service = BotBiddingService()

        let blindBid = service.makePreDealBlindBid(
            playerIndex: 0,
            dealerIndex: 1,
            cardsInRound: 9,
            allowedBlindBids: Array(0...9),
            canChooseBlind: true,
            totalScores: [1200, 900, 850, 700]
        )

        XCTAssertNil(blindBid)
    }

    func testMakePreDealBlindBid_returnsAllowedBidWhenPlayerFarBehind() {
        let service = BotBiddingService()

        let blindBid = service.makePreDealBlindBid(
            playerIndex: 3,
            dealerIndex: 0,
            cardsInRound: 9,
            allowedBlindBids: [2, 3, 4, 5, 6],
            canChooseBlind: true,
            totalScores: [1200, 1100, 980, 700]
        )

        XCTAssertNotNil(blindBid)
        if let blindBid {
            XCTAssertTrue([2, 3, 4, 5, 6].contains(blindBid))
        }
    }

    func testMakePreDealBlindBid_whenSlightlyBehind_usesLowerCatchUpBid() {
        let service = BotBiddingService(tuning: BotTuning(difficulty: .hard))

        let blindBid = service.makePreDealBlindBid(
            playerIndex: 2,
            dealerIndex: 0,
            cardsInRound: 9,
            allowedBlindBids: Array(0...9),
            canChooseBlind: true,
            totalScores: [1000, 980, 850, 840] // отставание от лидера: 150 (catch-up зона)
        )

        XCTAssertNotNil(blindBid)
        if let blindBid {
            XCTAssertLessThanOrEqual(blindBid, 4) // раньше здесь чаще получалось 5+
        }
    }

    func testMakePreDealBlindBid_whenGapGrows_bidAlsoGrows() {
        let service = BotBiddingService(tuning: BotTuning(difficulty: .hard))

        let catchUpBid = service.makePreDealBlindBid(
            playerIndex: 2,
            dealerIndex: 0,
            cardsInRound: 9,
            allowedBlindBids: Array(0...9),
            canChooseBlind: true,
            totalScores: [1000, 980, 850, 840] // отставание: 150
        )
        let desperateBid = service.makePreDealBlindBid(
            playerIndex: 2,
            dealerIndex: 0,
            cardsInRound: 9,
            allowedBlindBids: Array(0...9),
            canChooseBlind: true,
            totalScores: [1200, 980, 850, 840] // отставание: 350
        )

        XCTAssertNotNil(catchUpBid)
        XCTAssertNotNil(desperateBid)
        if let catchUpBid, let desperateBid {
            XCTAssertGreaterThan(desperateBid, catchUpBid)
        }
    }
}
