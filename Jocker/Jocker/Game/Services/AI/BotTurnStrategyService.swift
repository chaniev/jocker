//
//  BotTurnStrategyService.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

/// Сервис выбора карты и режима розыгрыша джокера для хода бота.
final class BotTurnStrategyService {
    struct BotTurnDecisionContext {
        let handCards: [Card]
        let trickNode: TrickNode
        let trump: Suit?
        let bid: Int?
        let tricksTaken: Int?
        let cardsInRound: Int?
        let playerCount: Int?
        let isBlind: Bool
        let matchContext: BotMatchContext?
        let actingPlayerIndex: Int?
        let completedTricksInRound: [[PlayedTrickCard]]

        init(
            handCards: [Card],
            trickNode: TrickNode,
            trump: Suit?,
            bid: Int?,
            tricksTaken: Int?,
            cardsInRound: Int?,
            playerCount: Int?,
            isBlind: Bool = false,
            matchContext: BotMatchContext? = nil,
            actingPlayerIndex: Int? = nil,
            completedTricksInRound: [[PlayedTrickCard]] = []
        ) {
            self.handCards = handCards
            self.trickNode = trickNode
            self.trump = trump
            self.bid = bid
            self.tricksTaken = tricksTaken
            self.cardsInRound = cardsInRound
            self.playerCount = playerCount
            self.isBlind = isBlind
            self.matchContext = matchContext
            self.actingPlayerIndex = actingPlayerIndex
            self.completedTricksInRound = completedTricksInRound
        }
    }

    private struct ResolvedDecisionContext {
        let request: BotTurnDecisionContext
        let trick: BotTurnCardHeuristicsService.TrickSnapshot
        let legalCards: [Card]
        let resolvedCardsInRound: Int
        let currentTricks: Int
        let targetBid: Int

        var shouldChaseTrick: Bool {
            return currentTricks < targetBid
        }
    }

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
        playerCount: Int? = nil,
        isBlind: Bool = false,
        matchContext: BotMatchContext? = nil,
        actingPlayerIndex: Int? = nil,
        completedTricksInRound: [[PlayedTrickCard]] = []
    ) -> (card: Card, jokerDecision: JokerPlayDecision)? {
        return makeTurnDecision(
            context: .init(
                handCards: handCards,
                trickNode: trickNode,
                trump: trump,
                bid: bid,
                tricksTaken: tricksTaken,
                cardsInRound: cardsInRound,
                playerCount: playerCount,
                isBlind: isBlind,
                matchContext: matchContext,
                actingPlayerIndex: actingPlayerIndex,
                completedTricksInRound: completedTricksInRound
            )
        )
    }

    func makeTurnDecision(
        context: BotTurnDecisionContext
    ) -> (card: Card, jokerDecision: JokerPlayDecision)? {
        guard let resolvedContext = resolveDecisionContext(context) else { return nil }

        if let bestMove = candidateEvaluator.bestMove(
            context: .init(
                legalCards: resolvedContext.legalCards,
                handCards: resolvedContext.request.handCards,
                trick: resolvedContext.trick,
                trump: resolvedContext.request.trump,
                targetBid: resolvedContext.targetBid,
                currentTricks: resolvedContext.currentTricks,
                cardsInRound: resolvedContext.resolvedCardsInRound,
                playerCount: resolvedContext.request.playerCount,
                isBlind: resolvedContext.request.isBlind,
                matchContext: resolvedContext.request.matchContext,
                actingPlayerIndex: resolvedContext.request.actingPlayerIndex,
                completedTricksInRound: resolvedContext.request.completedTricksInRound
            )
        ) {
            return bestMove
        }

        // Safety fallback: значение должно быть найдено всегда, но оставляем защиту.
        let fallbackCard = resolvedContext.legalCards[0]
        let fallbackDecision = fallbackCard.isJoker
            ? cardHeuristics.candidateDecisions(
                for: fallbackCard,
                trick: resolvedContext.trick,
                shouldChaseTrick: resolvedContext.shouldChaseTrick
            ).first ?? .defaultNonLead
            : .defaultNonLead
        return (fallbackCard, fallbackDecision)
    }

    private func resolveDecisionContext(
        _ context: BotTurnDecisionContext
    ) -> ResolvedDecisionContext? {
        guard !context.handCards.isEmpty else { return nil }

        let legalCards = context.handCards.filter { candidate in
            context.trickNode.canPlayCard(
                candidate,
                fromHand: context.handCards,
                trump: context.trump
            )
        }
        guard !legalCards.isEmpty else { return nil }

        let resolvedCardsInRound = max(
            context.handCards.count,
            context.cardsInRound ?? context.handCards.count
        )
        let currentTricks = max(0, context.tricksTaken ?? 0)
        let targetBid = roundProjection.normalizedBid(
            bid: context.bid,
            handCards: context.handCards,
            cardsInRound: resolvedCardsInRound,
            trump: context.trump
        )

        return ResolvedDecisionContext(
            request: context,
            trick: .init(trickNode: context.trickNode),
            legalCards: legalCards,
            resolvedCardsInRound: resolvedCardsInRound,
            currentTricks: currentTricks,
            targetBid: targetBid
        )
    }
}
