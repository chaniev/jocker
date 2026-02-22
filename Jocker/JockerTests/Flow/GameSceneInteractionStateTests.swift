//
//  GameSceneInteractionStateTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
@testable import Jocker

final class GameSceneInteractionStateTests: XCTestCase {

    func testInit_emptyBlockersProducesIdleNonBlockingState() {
        let state = GameSceneInteractionState()

        XCTAssertEqual(state.primaryFlow, .idle)
        XCTAssertEqual(state.pendingModal, .none)
        XCTAssertFalse(state.isBlockingInteraction)
        XCTAssertFalse(state.hasConflictingFlowBlockers)
        XCTAssertFalse(state.hasConflictingModalBlockers)
    }

    func testPrimaryFlowPriority_prefersSelectingFirstDealerOverRoundFlows() {
        let state = GameSceneInteractionState(
            blockers: [.selectingFirstDealer, .runningBiddingFlow, .runningTrumpSelectionFlow]
        )

        XCTAssertEqual(state.primaryFlow, .selectingFirstDealer)
        XCTAssertTrue(state.hasConflictingFlowBlockers)
        XCTAssertTrue(state.isBlockingInteraction)
    }

    func testPrimaryFlowPriority_prefersTrumpSelectionOverPreDealBlindAndBidding() {
        let state = GameSceneInteractionState(
            blockers: [.runningBiddingFlow, .runningPreDealBlindFlow, .runningTrumpSelectionFlow]
        )

        XCTAssertEqual(state.primaryFlow, .trumpSelection)
        XCTAssertTrue(state.hasConflictingFlowBlockers)
    }

    func testPendingModalPriority_prefersJokerDecisionOverHumanChoiceModals() {
        let state = GameSceneInteractionState(
            blockers: [.awaitingHumanBidChoice, .awaitingHumanTrumpChoice, .awaitingJokerDecision]
        )

        XCTAssertEqual(state.pendingModal, .jokerDecision)
        XCTAssertTrue(state.hasConflictingModalBlockers)
    }

    func testPendingModalPriority_prefersHumanTrumpOverBlindOverBid() {
        let state = GameSceneInteractionState(
            blockers: [.awaitingHumanBidChoice, .awaitingHumanBlindChoice, .awaitingHumanTrumpChoice]
        )

        XCTAssertEqual(state.pendingModal, .humanTrumpChoice)
        XCTAssertTrue(state.hasConflictingModalBlockers)
    }

    func testSingleFlowAndModalBlockers_doNotFlagConflicts() {
        let state = GameSceneInteractionState(
            blockers: [.runningBiddingFlow, .awaitingHumanBidChoice]
        )

        XCTAssertEqual(state.primaryFlow, .bidding)
        XCTAssertEqual(state.pendingModal, .humanBidChoice)
        XCTAssertFalse(state.hasConflictingFlowBlockers)
        XCTAssertFalse(state.hasConflictingModalBlockers)
        XCTAssertTrue(state.isBlockingInteraction)
    }
}
