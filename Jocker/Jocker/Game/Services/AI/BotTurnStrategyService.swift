//
//  BotTurnStrategyService.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

/// Сервис выбора карты и режима розыгрыша джокера для хода бота.
final class BotTurnStrategyService {
    private let tuning: BotTuning
    private let cardHeuristics: BotTurnCardHeuristicsService
    private let roundProjection: BotTurnRoundProjectionService
    private let candidateRanking: BotTurnCandidateRankingService
    private let candidateEvaluator: BotTurnCandidateEvaluatorService

    init(tuning: BotTuning = BotTuning(difficulty: .hard)) {
        let cardHeuristics = BotTurnCardHeuristicsService(tuning: tuning)
        let roundProjection = BotTurnRoundProjectionService(tuning: tuning)
        let candidateRanking = BotTurnCandidateRankingService(tuning: tuning)
        self.tuning = tuning
        self.cardHeuristics = cardHeuristics
        self.roundProjection = roundProjection
        self.candidateRanking = candidateRanking
        self.candidateEvaluator = BotTurnCandidateEvaluatorService(
            cardHeuristics: cardHeuristics,
            roundProjection: roundProjection,
            candidateRanking: candidateRanking
        )
    }

    func makeTurnDecision(
        handCards: [Card],
        trickNode: TrickNode,
        trump: Suit?,
        bid: Int?,
        tricksTaken: Int?,
        cardsInRound: Int? = nil,
        playerCount: Int? = nil
    ) -> (card: Card, jokerDecision: JokerPlayDecision)? {
        guard !handCards.isEmpty else { return nil }

        let legalCards = handCards.filter { candidate in
            trickNode.canPlayCard(candidate, fromHand: handCards, trump: trump)
        }
        guard !legalCards.isEmpty else { return nil }

        let resolvedCardsInRound = max(handCards.count, cardsInRound ?? handCards.count)
        let currentTricks = max(0, tricksTaken ?? 0)
        let targetBid = roundProjection.normalizedBid(
            bid: bid,
            handCards: handCards,
            cardsInRound: resolvedCardsInRound,
            trump: trump
        )
        let shouldChaseTrick = currentTricks < targetBid
        if let bestMove = candidateEvaluator.bestMove(
            legalCards: legalCards,
            handCards: handCards,
            trickNode: trickNode,
            trump: trump,
            targetBid: targetBid,
            currentTricks: currentTricks,
            cardsInRound: resolvedCardsInRound,
            playerCount: playerCount
        ) {
            return bestMove
        }

        // Safety fallback: значение должно быть найдено всегда, но оставляем защиту.
        let fallbackCard = legalCards[0]
        let fallbackDecision = fallbackCard.isJoker
            ? cardHeuristics.candidateDecisions(
                for: fallbackCard,
                trickNode: trickNode,
                shouldChaseTrick: shouldChaseTrick
            ).first ?? .defaultNonLead
            : .defaultNonLead
        return (fallbackCard, fallbackDecision)
    }

}
