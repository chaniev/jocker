//
//  GameStatisticsStore.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

protocol GameStatisticsStore {
    func loadSnapshotResult() -> Result<GameStatisticsSnapshot, Error>
    func recordCompletedGame(matchID: UUID, playerCount: Int, gameMode: GameMode, playerSummaries: [GameFinalPlayerSummary], completedBlocks: [BlockResult]) -> Result<Void, Error>
    func loadSnapshot() -> GameStatisticsSnapshot

    func recordCompletedGame(
        playerCount: Int,
        gameMode: GameMode,
        playerSummaries: [GameFinalPlayerSummary],
        completedBlocks: [BlockResult]
    )
}

extension GameStatisticsStore {
    func loadSnapshotResult() -> Result<GameStatisticsSnapshot, Error> { .success(self.loadSnapshot()) }
    func recordCompletedGame(matchID: UUID, playerCount: Int, gameMode: GameMode, playerSummaries: [GameFinalPlayerSummary], completedBlocks: [BlockResult]) -> Result<Void, Error> {
        self.recordCompletedGame(playerCount: playerCount, gameMode: gameMode, playerSummaries: playerSummaries, completedBlocks: completedBlocks)
        return .success(())
    }
}
