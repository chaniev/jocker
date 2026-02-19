//
//  DealHistoryStore.swift
//  Jocker
//
//  Created by Codex on 19.02.2026.
//

import Foundation

/// In-memory хранилище истории раздач текущей партии.
final class DealHistoryStore {
    private struct PendingTrainingMoveSample {
        let trickIndex: Int
        let moveIndexInTrick: Int
        let playerIndex: Int
        let playerCount: Int
        let cardsInRound: Int
        let trump: Suit?
        let playerBid: Int?
        let playerTricksTakenBeforeMove: Int?
        let handBeforeMove: [Card]
        let legalCards: [Card]
        let playedCardsInTrickBeforeMove: [DealTrickMove]
        let selectedCard: Card
        let selectedJokerPlayStyle: JokerPlayStyle
        let selectedJokerLeadDeclaration: JokerLeadDeclaration?
    }

    private struct MutableDealHistory {
        var trump: Suit?
        var tricks: [DealTrickHistory]
        var trainingSamples: [DealTrainingMoveSample]
        var pendingTrickMoveSamples: [PendingTrainingMoveSample]
    }

    private var historiesByDealKey: [DealHistoryKey: MutableDealHistory] = [:]

    func startDeal(blockIndex: Int, roundIndex: Int) {
        guard blockIndex >= 0, roundIndex >= 0 else { return }
        let key = DealHistoryKey(blockIndex: blockIndex, roundIndex: roundIndex)
        historiesByDealKey[key] = MutableDealHistory(
            trump: nil,
            tricks: [],
            trainingSamples: [],
            pendingTrickMoveSamples: []
        )
    }

    func setTrump(_ trump: Suit?, blockIndex: Int, roundIndex: Int) {
        guard blockIndex >= 0, roundIndex >= 0 else { return }
        let key = DealHistoryKey(blockIndex: blockIndex, roundIndex: roundIndex)
        var history = historiesByDealKey[key] ?? MutableDealHistory(
            trump: nil,
            tricks: [],
            trainingSamples: [],
            pendingTrickMoveSamples: []
        )
        history.trump = trump
        historiesByDealKey[key] = history
    }

    func appendMoveSample(
        blockIndex: Int,
        roundIndex: Int,
        trickIndex: Int,
        moveIndexInTrick: Int,
        playerIndex: Int,
        playerCount: Int,
        cardsInRound: Int,
        trump: Suit?,
        playerBid: Int?,
        playerTricksTakenBeforeMove: Int?,
        handBeforeMove: [Card],
        legalCards: [Card],
        playedCardsInTrickBeforeMove: [PlayedTrickCard],
        selectedCard: Card,
        selectedJokerPlayStyle: JokerPlayStyle,
        selectedJokerLeadDeclaration: JokerLeadDeclaration?
    ) {
        guard blockIndex >= 0, roundIndex >= 0 else { return }
        guard trickIndex >= 0, moveIndexInTrick >= 0 else { return }
        guard playerIndex >= 0, playerCount > 0 else { return }
        guard cardsInRound > 0 else { return }

        let key = DealHistoryKey(blockIndex: blockIndex, roundIndex: roundIndex)
        var history = historiesByDealKey[key] ?? MutableDealHistory(
            trump: nil,
            tricks: [],
            trainingSamples: [],
            pendingTrickMoveSamples: []
        )

        let trickMoves = playedCardsInTrickBeforeMove.map { playedCard in
            DealTrickMove(
                playerIndex: playedCard.playerIndex,
                card: playedCard.card,
                jokerPlayStyle: playedCard.jokerPlayStyle,
                jokerLeadDeclaration: playedCard.jokerLeadDeclaration
            )
        }

        let sample = PendingTrainingMoveSample(
            trickIndex: trickIndex,
            moveIndexInTrick: moveIndexInTrick,
            playerIndex: playerIndex,
            playerCount: playerCount,
            cardsInRound: cardsInRound,
            trump: trump,
            playerBid: playerBid,
            playerTricksTakenBeforeMove: playerTricksTakenBeforeMove,
            handBeforeMove: handBeforeMove,
            legalCards: legalCards,
            playedCardsInTrickBeforeMove: trickMoves,
            selectedCard: selectedCard,
            selectedJokerPlayStyle: selectedJokerPlayStyle,
            selectedJokerLeadDeclaration: selectedJokerLeadDeclaration
        )
        history.pendingTrickMoveSamples.append(sample)
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
        var history = historiesByDealKey[key] ?? MutableDealHistory(
            trump: nil,
            tricks: [],
            trainingSamples: [],
            pendingTrickMoveSamples: []
        )

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

        if !history.pendingTrickMoveSamples.isEmpty {
            let finalizedSamples = history.pendingTrickMoveSamples.map { pendingSample in
                DealTrainingMoveSample(
                    blockIndex: blockIndex,
                    roundIndex: roundIndex,
                    trickIndex: pendingSample.trickIndex,
                    moveIndexInTrick: pendingSample.moveIndexInTrick,
                    playerIndex: pendingSample.playerIndex,
                    playerCount: pendingSample.playerCount,
                    cardsInRound: pendingSample.cardsInRound,
                    trump: pendingSample.trump,
                    playerBid: pendingSample.playerBid,
                    playerTricksTakenBeforeMove: pendingSample.playerTricksTakenBeforeMove,
                    handBeforeMove: pendingSample.handBeforeMove,
                    legalCards: pendingSample.legalCards,
                    playedCardsInTrickBeforeMove: pendingSample.playedCardsInTrickBeforeMove,
                    selectedCard: pendingSample.selectedCard,
                    selectedJokerPlayStyle: pendingSample.selectedJokerPlayStyle,
                    selectedJokerLeadDeclaration: pendingSample.selectedJokerLeadDeclaration,
                    trickWinnerPlayerIndex: winnerPlayerIndex,
                    didPlayerWinTrick: pendingSample.playerIndex == winnerPlayerIndex
                )
            }
            history.trainingSamples.append(contentsOf: finalizedSamples)
            history.pendingTrickMoveSamples.removeAll()
        }

        historiesByDealKey[key] = history
    }

    func history(for key: DealHistoryKey) -> DealHistory? {
        guard let history = historiesByDealKey[key] else { return nil }
        return DealHistory(
            key: key,
            trump: history.trump,
            tricks: history.tricks,
            trainingSamples: history.trainingSamples
        )
    }

    func history(blockIndex: Int, roundIndex: Int) -> DealHistory? {
        let key = DealHistoryKey(blockIndex: blockIndex, roundIndex: roundIndex)
        return history(for: key)
    }

    func allHistories() -> [DealHistory] {
        return historiesByDealKey
            .keys
            .sorted { lhs, rhs in
                if lhs.blockIndex == rhs.blockIndex {
                    return lhs.roundIndex < rhs.roundIndex
                }
                return lhs.blockIndex < rhs.blockIndex
            }
            .compactMap { history(for: $0) }
    }

    func reset() {
        historiesByDealKey.removeAll()
    }
}
