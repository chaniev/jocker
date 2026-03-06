//
//  GameRoundResultsBuilder.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

/// Builds `RoundResult` snapshots from the current runtime round state.
///
/// This keeps `GameState` focused on turn/phase state while allowing scoring,
/// score-table snapshots, and export flows to share the same mapping logic.
struct GameRoundResultsBuilder {
    static func build(
        from gameState: GameState,
        playerCount: Int
    ) -> [RoundResult]? {
        guard playerCount > 0 else { return nil }
        guard gameState.players.count >= playerCount else { return nil }

        let cardsInRound = gameState.currentCardsPerPlayer
        return (0..<playerCount).map { playerIndex in
            let player = gameState.players[playerIndex]
            return RoundResult(
                cardsInRound: cardsInRound,
                bid: player.currentBid,
                tricksTaken: player.tricksTaken,
                isBlind: player.isBlindBid
            )
        }
    }
}
