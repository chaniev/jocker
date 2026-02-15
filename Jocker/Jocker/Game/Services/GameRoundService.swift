//
//  GameRoundService.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

/// Сервис раундовой логики: переходы между раундами/блоками и запись очков.
final class GameRoundService {
    private struct RoundRecordKey: Equatable {
        let block: Int
        let round: Int
    }

    private var hasDealtAtLeastOnce = false
    private var lastRecordedRoundKey: RoundRecordKey?

    func markDidDeal() {
        hasDealtAtLeastOnce = true
    }

    func prepareForDealing(
        gameState: GameState,
        scoreManager: ScoreManager?,
        playerCount: Int
    ) -> Bool {
        guard gameState.phase != .gameEnd else { return false }
        guard hasDealtAtLeastOnce else { return true }

        recordCurrentRoundIfNeeded(
            gameState: gameState,
            scoreManager: scoreManager,
            playerCount: playerCount
        )

        let currentRoundKey = RoundRecordKey(
            block: gameState.currentBlock.rawValue,
            round: gameState.currentRoundInBlock
        )
        let isFinalRoundOfFinalBlock =
            currentRoundKey.block >= GameConstants.totalBlocks &&
            gameState.currentRoundInBlock + 1 >= gameState.totalRoundsInBlock

        if isFinalRoundOfFinalBlock, lastRecordedRoundKey == currentRoundKey {
            gameState.markGameEnded()
            return false
        }

        gameState.startNewRound()
        return true
    }

    func completeRoundIfNeeded(
        gameState: GameState,
        scoreManager: ScoreManager?,
        playerCount: Int
    ) {
        let totalTricks = gameState.players.reduce(0) { $0 + $1.tricksTaken }
        guard totalTricks >= gameState.currentCardsPerPlayer else { return }

        gameState.completeRound()
        recordCurrentRoundIfNeeded(
            gameState: gameState,
            scoreManager: scoreManager,
            playerCount: playerCount
        )
    }

    private func recordCurrentRoundIfNeeded(
        gameState: GameState,
        scoreManager: ScoreManager?,
        playerCount: Int
    ) {
        guard hasDealtAtLeastOnce, let scoreManager = scoreManager else { return }
        guard gameState.phase == .roundEnd || gameState.phase == .gameEnd else { return }

        let roundKey = RoundRecordKey(
            block: gameState.currentBlock.rawValue,
            round: gameState.currentRoundInBlock
        )
        guard lastRecordedRoundKey != roundKey else { return }

        let cardsInRound = gameState.currentCardsPerPlayer
        var results: [RoundResult] = []
        results.reserveCapacity(playerCount)

        for playerIndex in 0..<playerCount {
            let player = gameState.players[playerIndex]
            let result = RoundResult(
                cardsInRound: cardsInRound,
                bid: player.currentBid,
                tricksTaken: player.tricksTaken,
                isBlind: player.isBlindBid
            )
            results.append(result)
        }

        scoreManager.recordRoundResults(results)

        if gameState.currentRoundInBlock + 1 >= gameState.totalRoundsInBlock {
            _ = scoreManager.finalizeBlock(blockNumber: gameState.currentBlock.rawValue)
        }

        lastRecordedRoundKey = roundKey
    }
}
