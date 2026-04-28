//
//  BotMatchContextBuilderTestFixture.swift
//  JockerTests
//
//  Created by Codex on 06.03.2026.
//

@testable import Jocker

struct BotMatchContextBuilderTestFixture {
    static func makeGameState(
        playerCount: Int,
        gameMode: GameMode = .freeForAll,
        initialDealerIndex: Int = 0
    ) -> GameState {
        let gameState = GameState(
            playerCount: playerCount,
            gameMode: gameMode
        )
        gameState.startGame(initialDealerIndex: initialDealerIndex)
        return gameState
    }

    static func roundResult(
        cardsInRound: Int,
        bid: Int,
        tricksTaken: Int,
        isBlind: Bool = false
    ) -> RoundResult {
        return RoundResult(
            cardsInRound: cardsInRound,
            bid: bid,
            tricksTaken: tricksTaken,
            isBlind: isBlind
        )
    }
}
