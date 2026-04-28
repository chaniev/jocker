//
//  GameSceneInputConfiguration.swift
//  Jocker
//
//  Created by Codex on 04.03.2026.
//

import Foundation

/// External setup configuration for `GameScene` before the scene is presented.
struct GameSceneInputConfiguration {
    var playerCount: Int
    var gameMode: GameMode
    var playerNames: [String]
    var playerControlTypes: [PlayerControlType]
    var botDifficulty: BotDifficulty
    var botDifficultiesByPlayer: [BotDifficulty]

    init(
        playerCount: Int = 4,
        gameMode: GameMode = .freeForAll,
        playerNames: [String] = [],
        playerControlTypes: [PlayerControlType] = [],
        botDifficulty: BotDifficulty = .hard,
        botDifficultiesByPlayer: [BotDifficulty] = []
    ) {
        self.playerCount = playerCount
        self.gameMode = gameMode.normalized(for: playerCount)
        self.playerNames = playerNames
        self.playerControlTypes = playerControlTypes
        self.botDifficulty = botDifficulty
        self.botDifficultiesByPlayer = botDifficultiesByPlayer
    }
}
