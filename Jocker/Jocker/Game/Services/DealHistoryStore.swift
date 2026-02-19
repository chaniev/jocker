//
//  DealHistoryStore.swift
//  Jocker
//
//  Created by Codex on 19.02.2026.
//

import Foundation

/// In-memory хранилище истории раздач текущей партии.
final class DealHistoryStore {
    private struct MutableDealHistory {
        var trump: Suit?
        var tricks: [DealTrickHistory]
    }

    private var historiesByDealKey: [DealHistoryKey: MutableDealHistory] = [:]

    func startDeal(blockIndex: Int, roundIndex: Int) {
        guard blockIndex >= 0, roundIndex >= 0 else { return }
        let key = DealHistoryKey(blockIndex: blockIndex, roundIndex: roundIndex)
        historiesByDealKey[key] = MutableDealHistory(trump: nil, tricks: [])
    }

    func setTrump(_ trump: Suit?, blockIndex: Int, roundIndex: Int) {
        guard blockIndex >= 0, roundIndex >= 0 else { return }
        let key = DealHistoryKey(blockIndex: blockIndex, roundIndex: roundIndex)
        var history = historiesByDealKey[key] ?? MutableDealHistory(trump: nil, tricks: [])
        history.trump = trump
        historiesByDealKey[key] = history
    }

    func appendTrick(
        blockIndex: Int,
        roundIndex: Int,
        playedCards: [PlayedTrickCard],
        winnerPlayerIndex: Int
    ) {
        guard blockIndex >= 0, roundIndex >= 0 else { return }
        guard winnerPlayerIndex >= 0 else { return }
        guard !playedCards.isEmpty else { return }

        let key = DealHistoryKey(blockIndex: blockIndex, roundIndex: roundIndex)
        var history = historiesByDealKey[key] ?? MutableDealHistory(trump: nil, tricks: [])

        let moves = playedCards.map { playedCard in
            DealTrickMove(
                playerIndex: playedCard.playerIndex,
                card: playedCard.card,
                jokerPlayStyle: playedCard.jokerPlayStyle,
                jokerLeadDeclaration: playedCard.jokerLeadDeclaration
            )
        }

        let trick = DealTrickHistory(
            moves: moves,
            winnerPlayerIndex: winnerPlayerIndex
        )
        history.tricks.append(trick)
        historiesByDealKey[key] = history
    }

    func history(for key: DealHistoryKey) -> DealHistory? {
        guard let history = historiesByDealKey[key] else { return nil }
        return DealHistory(
            key: key,
            trump: history.trump,
            tricks: history.tricks
        )
    }

    func history(blockIndex: Int, roundIndex: Int) -> DealHistory? {
        let key = DealHistoryKey(blockIndex: blockIndex, roundIndex: roundIndex)
        return history(for: key)
    }

    func reset() {
        historiesByDealKey.removeAll()
    }
}
