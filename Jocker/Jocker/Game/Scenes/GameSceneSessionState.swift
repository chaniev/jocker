//
//  GameSceneSessionState.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

/// Transient runtime state owned by `GameScene`, excluding domain game rules/state.
struct GameSceneSessionState {
    var pendingBids: [Int] = []
    var pendingBlindSelections: [Bool] = []
    var hasPresentedGameResultsModal = false
    var lastPresentedBlockResultsCount = 0
    var hasSavedGameStatistics = false
    var exportedBlockIndices: Set<Int> = []
    var hasExportedFinalGameHistory = false
    var hasDealtAtLeastOnce = false

    mutating func markDidDealAtLeastOnce() {
        hasDealtAtLeastOnce = true
    }

    mutating func markGameStatisticsSaved() {
        hasSavedGameStatistics = true
    }

    mutating func resetTransientDealFlowState() {
        pendingBids.removeAll()
        pendingBlindSelections.removeAll()
    }

    mutating func resetForNewGameSession() {
        self = GameSceneSessionState()
    }

    mutating func seedForTesting(
        hasPresentedGameResultsModal: Bool,
        lastPresentedBlockResultsCount: Int,
        hasSavedGameStatistics: Bool,
        hasDealtAtLeastOnce: Bool,
        pendingBids: [Int],
        pendingBlindSelections: [Bool]
    ) {
        self.hasPresentedGameResultsModal = hasPresentedGameResultsModal
        self.lastPresentedBlockResultsCount = lastPresentedBlockResultsCount
        self.hasSavedGameStatistics = hasSavedGameStatistics
        self.hasDealtAtLeastOnce = hasDealtAtLeastOnce
        self.pendingBids = pendingBids
        self.pendingBlindSelections = pendingBlindSelections
    }
}
