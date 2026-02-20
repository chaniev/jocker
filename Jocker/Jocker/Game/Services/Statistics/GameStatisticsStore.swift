//
//  GameStatisticsStore.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

protocol GameStatisticsStore {
    func loadSnapshot() -> GameStatisticsSnapshot

    func recordCompletedGame(
        playerCount: Int,
        playerSummaries: [GameFinalPlayerSummary],
        completedBlocks: [BlockResult]
    )
}
