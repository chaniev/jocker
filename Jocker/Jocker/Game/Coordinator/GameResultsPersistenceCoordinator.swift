//
//  GameResultsPersistenceCoordinator.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

/// Handles post-game persistence/export side effects for `GameScene`.
struct GameResultsPersistenceCoordinator {
    func persistGameStatisticsIfNeeded(
        sessionState: GameSceneSessionState,
        playerSummaries: [GameFinalPlayerSummary],
        playerCount: Int,
        gameMode: GameMode,
        completedBlocks: [BlockResult],
        statisticsStore: GameStatisticsStore
    ) -> GameSceneSessionState {
        guard !sessionState.hasSavedGameStatistics else { return sessionState }
        guard !playerSummaries.isEmpty else { return sessionState }
        guard !completedBlocks.isEmpty else { return sessionState }

        var updatedState = sessionState
        updatedState.markGameStatisticsSaved()
        statisticsStore.recordCompletedGame(
            playerCount: playerCount,
            gameMode: gameMode,
            playerSummaries: playerSummaries,
            completedBlocks: completedBlocks
        )
        return updatedState
    }

    func exportCompletedBlockHistoryIfNeeded(
        sessionState: GameSceneSessionState,
        completedBlockCount: Int,
        histories: [DealHistory],
        playerCount: Int,
        gameMode: GameMode,
        playerNames: [String],
        playerControlTypes: [PlayerControlType],
        exportService: DealHistoryExportService
    ) -> GameSceneSessionState {
        let blockIndex = completedBlockCount - 1
        guard blockIndex >= 0 else { return sessionState }
        guard !sessionState.exportedBlockIndices.contains(blockIndex) else { return sessionState }

        var updatedState = sessionState
        updatedState.exportedBlockIndices.insert(blockIndex)
        exportDealHistorySnapshot(
            histories: histories,
            playerCount: playerCount,
            gameMode: gameMode,
            playerNames: playerNames,
            playerControlTypes: playerControlTypes,
            reason: .blockCompleted(blockIndex: blockIndex),
            exportService: exportService
        )
        return updatedState
    }

    func exportFinalGameHistoryIfNeeded(
        sessionState: GameSceneSessionState,
        histories: [DealHistory],
        playerCount: Int,
        gameMode: GameMode,
        playerNames: [String],
        playerControlTypes: [PlayerControlType],
        exportService: DealHistoryExportService
    ) -> GameSceneSessionState {
        guard !sessionState.hasExportedFinalGameHistory else { return sessionState }

        var updatedState = sessionState
        updatedState.hasExportedFinalGameHistory = true
        exportDealHistorySnapshot(
            histories: histories,
            playerCount: playerCount,
            gameMode: gameMode,
            playerNames: playerNames,
            playerControlTypes: playerControlTypes,
            reason: .gameCompleted,
            exportService: exportService
        )
        return updatedState
    }

    private func exportDealHistorySnapshot(
        histories: [DealHistory],
        playerCount: Int,
        gameMode: GameMode,
        playerNames: [String],
        playerControlTypes: [PlayerControlType],
        reason: DealHistoryExportService.ExportReason,
        exportService: DealHistoryExportService
    ) {
        guard !histories.isEmpty else { return }

        _ = exportService.export(
            histories: histories,
            playerCount: playerCount,
            gameMode: gameMode,
            playerNames: playerNames,
            playerControlTypes: playerControlTypes,
            reason: reason
        )
    }
}
