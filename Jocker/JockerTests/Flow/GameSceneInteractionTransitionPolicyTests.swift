//
//  GameSceneInteractionTransitionPolicyTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
@testable import Jocker

final class GameSceneInteractionTransitionPolicyTests: XCTestCase {

    func testSettingPrimaryFlow_replacesOnlyPrimaryFlowBlockersAndPreservesPendingModal() {
        let initial: GameSceneInteractionBlockers = [
            .runningBiddingFlow,
            .awaitingHumanBidChoice
        ]

        let updated = GameSceneInteractionTransitionPolicy.settingPrimaryFlow(
            .trumpSelection,
            from: initial
        )

        XCTAssertTrue(updated.contains(.runningTrumpSelectionFlow))
        XCTAssertFalse(updated.contains(.runningBiddingFlow))
        XCTAssertTrue(updated.contains(.awaitingHumanBidChoice), "Pending modal blockers must be preserved")
    }

    func testClearingPrimaryFlow_removesOnlyTargetedPrimaryBlocker() {
        let initial: GameSceneInteractionBlockers = [
            .runningTrumpSelectionFlow,
            .awaitingJokerDecision
        ]

        let updated = GameSceneInteractionTransitionPolicy.clearingPrimaryFlow(
            .trumpSelection,
            from: initial
        )

        XCTAssertFalse(updated.contains(.runningTrumpSelectionFlow))
        XCTAssertTrue(updated.contains(.awaitingJokerDecision))
    }

    func testSettingPendingModal_replacesOnlyPendingModalBlockersAndPreservesPrimaryFlow() {
        let initial: GameSceneInteractionBlockers = [
            .runningPreDealBlindFlow,
            .awaitingHumanBidChoice
        ]

        let updated = GameSceneInteractionTransitionPolicy.settingPendingModal(
            .humanTrumpChoice,
            from: initial
        )

        XCTAssertTrue(updated.contains(.runningPreDealBlindFlow))
        XCTAssertFalse(updated.contains(.awaitingHumanBidChoice))
        XCTAssertTrue(updated.contains(.awaitingHumanTrumpChoice))
    }

    func testClearingPendingModal_noneIsNoOp() {
        let initial: GameSceneInteractionBlockers = [
            .runningBiddingFlow,
            .awaitingHumanBlindChoice
        ]

        let updated = GameSceneInteractionTransitionPolicy.clearingPendingModal(
            .none,
            from: initial
        )

        XCTAssertEqual(updated, initial)
    }

    func testBlockerMappings_coverIdleAndNoneAsNilAndKnownCases() {
        XCTAssertNil(GameSceneInteractionTransitionPolicy.blocker(forPrimaryFlow: .idle))
        XCTAssertEqual(
            GameSceneInteractionTransitionPolicy.blocker(forPrimaryFlow: .selectingFirstDealer),
            .selectingFirstDealer
        )
        XCTAssertEqual(
            GameSceneInteractionTransitionPolicy.blocker(forPrimaryFlow: .bidding),
            .runningBiddingFlow
        )
        XCTAssertEqual(
            GameSceneInteractionTransitionPolicy.blocker(forPrimaryFlow: .preDealBlind),
            .runningPreDealBlindFlow
        )
        XCTAssertEqual(
            GameSceneInteractionTransitionPolicy.blocker(forPrimaryFlow: .trumpSelection),
            .runningTrumpSelectionFlow
        )

        XCTAssertNil(GameSceneInteractionTransitionPolicy.blocker(forPendingModal: .none))
        XCTAssertEqual(
            GameSceneInteractionTransitionPolicy.blocker(forPendingModal: .jokerDecision),
            .awaitingJokerDecision
        )
        XCTAssertEqual(
            GameSceneInteractionTransitionPolicy.blocker(forPendingModal: .humanBidChoice),
            .awaitingHumanBidChoice
        )
        XCTAssertEqual(
            GameSceneInteractionTransitionPolicy.blocker(forPendingModal: .humanBlindChoice),
            .awaitingHumanBlindChoice
        )
        XCTAssertEqual(
            GameSceneInteractionTransitionPolicy.blocker(forPendingModal: .humanTrumpChoice),
            .awaitingHumanTrumpChoice
        )
    }
}
