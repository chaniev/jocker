//
//  GameSceneInteractionState.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import Foundation

/// Явное высокоуровневое состояние интеракций `GameScene`, вычисляемое из low-level blockers.
struct GameSceneInteractionState: Equatable {
    enum PrimaryFlow: Equatable {
        case idle
        case selectingFirstDealer
        case bidding
        case preDealBlind
        case trumpSelection
    }

    enum PendingModal: Equatable {
        case none
        case jokerDecision
        case humanBidChoice
        case humanBlindChoice
        case humanTrumpChoice
    }

    let blockers: GameSceneInteractionBlockers
    let primaryFlow: PrimaryFlow
    let pendingModal: PendingModal

    init(blockers: GameSceneInteractionBlockers = []) {
        self.blockers = blockers
        self.primaryFlow = Self.resolvePrimaryFlow(from: blockers)
        self.pendingModal = Self.resolvePendingModal(from: blockers)
    }

    var isBlockingInteraction: Bool {
        return !blockers.isEmpty
    }

    var hasConflictingFlowBlockers: Bool {
        return Self.activeCount(
            in: blockers,
            candidates: [
                .selectingFirstDealer,
                .runningBiddingFlow,
                .runningPreDealBlindFlow,
                .runningTrumpSelectionFlow
            ]
        ) > 1
    }

    var hasConflictingModalBlockers: Bool {
        return Self.activeCount(
            in: blockers,
            candidates: [
                .awaitingJokerDecision,
                .awaitingHumanBidChoice,
                .awaitingHumanBlindChoice,
                .awaitingHumanTrumpChoice
            ]
        ) > 1
    }

    private static func resolvePrimaryFlow(from blockers: GameSceneInteractionBlockers) -> PrimaryFlow {
        if blockers.contains(.selectingFirstDealer) {
            return .selectingFirstDealer
        }
        if blockers.contains(.runningTrumpSelectionFlow) {
            return .trumpSelection
        }
        if blockers.contains(.runningPreDealBlindFlow) {
            return .preDealBlind
        }
        if blockers.contains(.runningBiddingFlow) {
            return .bidding
        }
        return .idle
    }

    private static func resolvePendingModal(from blockers: GameSceneInteractionBlockers) -> PendingModal {
        if blockers.contains(.awaitingJokerDecision) {
            return .jokerDecision
        }
        if blockers.contains(.awaitingHumanTrumpChoice) {
            return .humanTrumpChoice
        }
        if blockers.contains(.awaitingHumanBlindChoice) {
            return .humanBlindChoice
        }
        if blockers.contains(.awaitingHumanBidChoice) {
            return .humanBidChoice
        }
        return .none
    }

    private static func activeCount(
        in blockers: GameSceneInteractionBlockers,
        candidates: [GameSceneInteractionBlockers]
    ) -> Int {
        var count = 0
        for candidate in candidates where blockers.contains(candidate) {
            count += 1
        }
        return count
    }
}
