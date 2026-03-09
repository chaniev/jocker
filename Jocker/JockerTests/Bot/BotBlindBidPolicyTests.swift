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

    func testMakePreDealBlindBid_withNeutralPhaseBlindPolicy_preservesBlock4Behavior() {
        let baselineFixture = BotBlindBidPolicyTestFixture()
        let baselinePolicy = baselineFixture.tuning.runtimePolicy
        var blindPolicy = baselinePolicy.bidding.blindPolicy
        blindPolicy.phaseBlock4 = .neutral
        let neutralPolicy = BotRuntimePolicy.assembled(
            difficulty: baselineFixture.tuning.difficulty,
            ranking: baselinePolicy.ranking,
            bidding: {
                var bidding = baselinePolicy.bidding
                bidding.blindPolicy = blindPolicy
                return bidding
            }(),
            evaluator: baselinePolicy.evaluator,
            rollout: baselinePolicy.rollout,
            endgame: baselinePolicy.endgame,
            simulation: baselinePolicy.simulation,
            handStrength: baselinePolicy.handStrength,
            heuristics: baselinePolicy.heuristics,
            opponentModeling: baselinePolicy.opponentModeling
        )
        let neutralTuning = BotTuning(
            difficulty: baselineFixture.tuning.difficulty,
            turnStrategy: baselineFixture.tuning.turnStrategy,
            bidding: baselineFixture.tuning.bidding,
            trumpSelection: baselineFixture.tuning.trumpSelection,
            runtimePolicy: neutralPolicy,
            timing: baselineFixture.tuning.timing
        )
        let neutralFixture = BotBlindBidPolicyTestFixture(tuning: neutralTuning)

        let earlyContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 0,
            totalRoundsInBlock: 8,
            totalScores: [1210, 1033, 1033, 1025],
            playerIndex: 1,
            dealerIndex: 0,
            playerCount: 4
        )
        let lateContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [1210, 1033, 1033, 1025],
            playerIndex: 1,
            dealerIndex: 0,
            playerCount: 4
        )

        let baselineEarly = baselineFixture.makeBlindBid(
            playerIndex: 1,
            dealerIndex: 0,
            cardsInRound: 4,
            allowedBlindBids: Array(0...4),
            totalScores: [1210, 1033, 1033, 1025],
            matchContext: earlyContext
        )
        let neutralEarly = neutralFixture.makeBlindBid(
            playerIndex: 1,
            dealerIndex: 0,
            cardsInRound: 4,
            allowedBlindBids: Array(0...4),
            totalScores: [1210, 1033, 1033, 1025],
            matchContext: earlyContext
        )
        let baselineLate = baselineFixture.makeBlindBid(
            playerIndex: 1,
            dealerIndex: 0,
            cardsInRound: 4,
            allowedBlindBids: Array(0...4),
            totalScores: [1210, 1033, 1033, 1025],
            matchContext: lateContext
        )
        let neutralLate = neutralFixture.makeBlindBid(
            playerIndex: 1,
            dealerIndex: 0,
            cardsInRound: 4,
            allowedBlindBids: Array(0...4),
            totalScores: [1210, 1033, 1033, 1025],
            matchContext: lateContext
        )

        XCTAssertEqual(neutralEarly, baselineEarly)
        XCTAssertEqual(neutralLate, baselineLate)
    }

    func testMakePreDealBlindBid_withPhaseBlindTuning_isMoreAggressiveLateInBlock4() {
        let baselineFixture = BotBlindBidPolicyTestFixture()
        let baselinePolicy = baselineFixture.tuning.runtimePolicy
        var blindPolicy = baselinePolicy.bidding.blindPolicy
        blindPolicy.phaseBlock4 = PhaseMultipliers(
            early: 1.0 / 1.50,
            mid: 1.0,
            late: 1.50
        )
        let tunedPolicy = BotRuntimePolicy.assembled(
            difficulty: baselineFixture.tuning.difficulty,
            ranking: baselinePolicy.ranking,
            bidding: {
                var bidding = baselinePolicy.bidding
                bidding.blindPolicy = blindPolicy
                return bidding
            }(),
            evaluator: baselinePolicy.evaluator,
            rollout: baselinePolicy.rollout,
            endgame: baselinePolicy.endgame,
            simulation: baselinePolicy.simulation,
            handStrength: baselinePolicy.handStrength,
            heuristics: baselinePolicy.heuristics,
            opponentModeling: baselinePolicy.opponentModeling
        )
        let tunedTuning = BotTuning(
            difficulty: baselineFixture.tuning.difficulty,
            turnStrategy: baselineFixture.tuning.turnStrategy,
            bidding: baselineFixture.tuning.bidding,
            trumpSelection: baselineFixture.tuning.trumpSelection,
            runtimePolicy: tunedPolicy,
            timing: baselineFixture.tuning.timing
        )
        let tunedFixture = BotBlindBidPolicyTestFixture(tuning: tunedTuning)

        let earlyContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 0,
            totalRoundsInBlock: 8,
            totalScores: [1210, 1033, 1033, 1025],
            playerIndex: 1,
            dealerIndex: 0,
            playerCount: 4
        )
        let lateContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [1210, 1033, 1033, 1025],
            playerIndex: 1,
            dealerIndex: 0,
            playerCount: 4
        )

        let baselineEarly = baselineFixture.makeBlindBid(
            playerIndex: 1,
            dealerIndex: 0,
            cardsInRound: 4,
            allowedBlindBids: Array(0...4),
            totalScores: [1210, 1033, 1033, 1025],
            matchContext: earlyContext
        )
        let baselineLate = baselineFixture.makeBlindBid(
            playerIndex: 1,
            dealerIndex: 0,
            cardsInRound: 4,
            allowedBlindBids: Array(0...4),
            totalScores: [1210, 1033, 1033, 1025],
            matchContext: lateContext
        )
        let tunedEarly = tunedFixture.makeBlindBid(
            playerIndex: 1,
            dealerIndex: 0,
            cardsInRound: 4,
            allowedBlindBids: Array(0...4),
            totalScores: [1210, 1033, 1033, 1025],
            matchContext: earlyContext
        )
        let tunedLate = tunedFixture.makeBlindBid(
            playerIndex: 1,
            dealerIndex: 0,
            cardsInRound: 4,
            allowedBlindBids: Array(0...4),
            totalScores: [1210, 1033, 1033, 1025],
            matchContext: lateContext
        )

        XCTAssertEqual(baselineEarly, baselineLate)
        guard let tunedLate else {
            XCTFail(
                "baselineEarly=\(String(describing: baselineEarly)) " +
                    "baselineLate=\(String(describing: baselineLate)) " +
                    "tunedEarly=\(String(describing: tunedEarly)) " +
                    "tunedLate=\(String(describing: tunedLate))"
            )
            return
        }
        if let tunedEarly {
            XCTAssertGreaterThanOrEqual(tunedLate, tunedEarly)
        } else {
            XCTAssertNil(tunedEarly)
        }
    }
}
