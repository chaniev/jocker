//
//  GameSceneInteractionTransitionPolicy.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import Foundation

/// Pure transition rules for mutating `GameSceneInteractionBlockers`
/// through high-level `GameSceneInteractionState` flow/modal intents.
struct GameSceneInteractionTransitionPolicy {

    static func settingPrimaryFlow(
        _ flow: GameSceneInteractionState.PrimaryFlow,
        from blockers: GameSceneInteractionBlockers
    ) -> GameSceneInteractionBlockers {
        var updated = blockers
        updated.subtract(.primaryFlowStates)
        if let blocker = blocker(forPrimaryFlow: flow) {
            updated.insert(blocker)
        }
        return updated
    }

    static func clearingPrimaryFlow(
        _ flow: GameSceneInteractionState.PrimaryFlow,
        from blockers: GameSceneInteractionBlockers
    ) -> GameSceneInteractionBlockers {
        guard let blocker = blocker(forPrimaryFlow: flow) else { return blockers }
        var updated = blockers
        updated.remove(blocker)
        return updated
    }

    static func settingPendingModal(
        _ modal: GameSceneInteractionState.PendingModal,
        from blockers: GameSceneInteractionBlockers
    ) -> GameSceneInteractionBlockers {
        var updated = blockers
        updated.subtract(.pendingModalStates)
        if let blocker = blocker(forPendingModal: modal) {
            updated.insert(blocker)
        }
        return updated
    }

    static func clearingPendingModal(
        _ modal: GameSceneInteractionState.PendingModal,
        from blockers: GameSceneInteractionBlockers
    ) -> GameSceneInteractionBlockers {
        guard let blocker = blocker(forPendingModal: modal) else { return blockers }
        var updated = blockers
        updated.remove(blocker)
        return updated
    }

    static func blocker(
        forPrimaryFlow flow: GameSceneInteractionState.PrimaryFlow
    ) -> GameSceneInteractionBlockers? {
        switch flow {
        case .idle:
            return nil
        case .selectingFirstDealer:
            return .selectingFirstDealer
        case .bidding:
            return .runningBiddingFlow
        case .preDealBlind:
            return .runningPreDealBlindFlow
        case .trumpSelection:
            return .runningTrumpSelectionFlow
        }
    }

    static func blocker(
        forPendingModal modal: GameSceneInteractionState.PendingModal
    ) -> GameSceneInteractionBlockers? {
        switch modal {
        case .none:
            return nil
        case .jokerDecision:
            return .awaitingJokerDecision
        case .humanBidChoice:
            return .awaitingHumanBidChoice
        case .humanBlindChoice:
            return .awaitingHumanBlindChoice
        case .humanTrumpChoice:
            return .awaitingHumanTrumpChoice
        }
    }
}
