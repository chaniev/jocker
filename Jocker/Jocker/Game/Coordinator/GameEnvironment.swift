//
//  GameEnvironment.swift
//  Jocker
//
//  Created by Codex on 04.03.2026.
//

import Foundation

/// Dependency container for `GameScene` infrastructure and service factories.
struct GameEnvironment {
    let makeCoordinator: () -> GameSceneCoordinator
    let makeGameStatisticsStore: () -> GameStatisticsStore
    let makeDealHistoryStore: () -> DealHistoryStore
    let makeDealHistoryExportService: () -> DealHistoryExportService
    let makeBotTuning: (BotDifficulty) -> BotTuning
    let makeBotBiddingService: (BotTuning) -> BotBiddingService
    let makeBotTrumpSelectionService: (BotTuning) -> BotTrumpSelectionService
    let makeBotTurnService: (BotTuning) -> GameTurnService

    static let live = GameEnvironment(
        makeCoordinator: { GameSceneCoordinator() },
        makeGameStatisticsStore: { UserDefaultsGameStatisticsStore() },
        makeDealHistoryStore: { DealHistoryStore() },
        makeDealHistoryExportService: { DealHistoryExportService() },
        makeBotTuning: { BotTuning(difficulty: $0) },
        makeBotBiddingService: { BotBiddingService(tuning: $0) },
        makeBotTrumpSelectionService: { BotTrumpSelectionService(tuning: $0) },
        makeBotTurnService: { GameTurnService(tuning: $0) }
    )
}

