//
//  GameSceneInteractionBlockers.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import Foundation

/// Централизованный набор флагов, блокирующих интеракции в `GameScene`.
struct GameSceneInteractionBlockers: OptionSet {
    let rawValue: UInt16

    static let selectingFirstDealer = GameSceneInteractionBlockers(rawValue: 1 << 0)
    static let awaitingJokerDecision = GameSceneInteractionBlockers(rawValue: 1 << 1)
    static let awaitingHumanBidChoice = GameSceneInteractionBlockers(rawValue: 1 << 2)
    static let awaitingHumanBlindChoice = GameSceneInteractionBlockers(rawValue: 1 << 3)
    static let awaitingHumanTrumpChoice = GameSceneInteractionBlockers(rawValue: 1 << 4)
    static let runningBiddingFlow = GameSceneInteractionBlockers(rawValue: 1 << 5)
    static let runningPreDealBlindFlow = GameSceneInteractionBlockers(rawValue: 1 << 6)
    static let runningTrumpSelectionFlow = GameSceneInteractionBlockers(rawValue: 1 << 7)

    static let primaryFlowStates: GameSceneInteractionBlockers = [
        .selectingFirstDealer,
        .runningBiddingFlow,
        .runningPreDealBlindFlow,
        .runningTrumpSelectionFlow
    ]

    static let pendingModalStates: GameSceneInteractionBlockers = [
        .awaitingJokerDecision,
        .awaitingHumanBidChoice,
        .awaitingHumanBlindChoice,
        .awaitingHumanTrumpChoice
    ]

    static let humanInputModals: GameSceneInteractionBlockers = [
        .awaitingHumanBidChoice,
        .awaitingHumanBlindChoice,
        .awaitingHumanTrumpChoice
    ]

    static let roundFlowExecution: GameSceneInteractionBlockers = [
        .runningBiddingFlow,
        .runningPreDealBlindFlow,
        .runningTrumpSelectionFlow
    ]

    /// Состояния, которые сбрасываются при старте новой раздачи.
    static let dealStartResettable: GameSceneInteractionBlockers = [
        .humanInputModals,
        .roundFlowExecution
    ]

    static let allInteractionBlockers: GameSceneInteractionBlockers = [
        .selectingFirstDealer,
        .awaitingJokerDecision,
        .awaitingHumanBidChoice,
        .awaitingHumanBlindChoice,
        .awaitingHumanTrumpChoice,
        .runningBiddingFlow,
        .runningPreDealBlindFlow,
        .runningTrumpSelectionFlow
    ]
}
