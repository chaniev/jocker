//
//  BotTurnCandidateEvaluatorService.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import Foundation

/// Оценка и выбор лучшего кандидата для runtime-хода бота.
/// Инкапсулирует цикл перебора карт/режимов джокера и расчёт utility.
struct BotTurnCandidateEvaluatorService {
    struct DecisionContext {
        let legalCards: [Card]
        let handCards: [Card]
        let trick: BotTurnCardHeuristicsService.TrickSnapshot
        let trump: Suit?
        let targetBid: Int
        let currentTricks: Int
        let cardsInRound: Int
        let playerCount: Int?
    }

    private let cardHeuristics: BotTurnCardHeuristicsService
    private let roundProjection: BotTurnRoundProjectionService
    private let candidateRanking: BotTurnCandidateRankingService

    private typealias CandidateMove = BotTurnCandidateRankingService.Move
    private typealias CandidateEvaluation = BotTurnCandidateRankingService.Evaluation

    init(
        cardHeuristics: BotTurnCardHeuristicsService,
        roundProjection: BotTurnRoundProjectionService,
        candidateRanking: BotTurnCandidateRankingService
    ) {
        self.cardHeuristics = cardHeuristics
        self.roundProjection = roundProjection
        self.candidateRanking = candidateRanking
    }

    func bestMove(
        legalCards: [Card],
        handCards: [Card],
        trickNode: TrickNode,
        trump: Suit?,
        targetBid: Int,
        currentTricks: Int,
        cardsInRound: Int,
        playerCount: Int?
    ) -> (card: Card, jokerDecision: JokerPlayDecision)? {
        return bestMove(
            context: .init(
                legalCards: legalCards,
                handCards: handCards,
                trick: .init(trickNode: trickNode),
                trump: trump,
                targetBid: targetBid,
                currentTricks: currentTricks,
                cardsInRound: cardsInRound,
                playerCount: playerCount
            )
        )
    }

    func bestMove(
        context: DecisionContext
    ) -> (card: Card, jokerDecision: JokerPlayDecision)? {
        guard !context.legalCards.isEmpty else { return nil }

        let shouldChaseTrick = context.currentTricks < context.targetBid
        let tricksNeededToMatchBid = max(0, context.targetBid - context.currentTricks)
        let tricksRemainingIncludingCurrent = max(1, context.handCards.count)
        let chasePressure = shouldChaseTrick
            ? min(
                1.0,
                max(
                    0.0,
                    Double(tricksNeededToMatchBid) / Double(tricksRemainingIncludingCurrent)
                )
            )
            : 0.0
        let opponentsRemaining = roundProjection.remainingOpponentsCount(
            playerCount: context.playerCount,
            cardsAlreadyOnTable: context.trick.playedCards.count
        )
        let unseen = cardHeuristics.unseenCards(
            excluding: context.handCards,
            and: context.trick.playedCards.map(\.card)
        )

        let hasWinningNonJoker = context.legalCards.contains { card in
            guard !card.isJoker else { return false }
            return cardHeuristics.winsTrickRightNow(
                with: card,
                decision: .defaultNonLead,
                trick: context.trick,
                trump: context.trump
            )
        }
        let hasLosingNonJoker = context.legalCards.contains { card in
            guard !card.isJoker else { return false }
            return !cardHeuristics.winsTrickRightNow(
                with: card,
                decision: .defaultNonLead,
                trick: context.trick,
                trump: context.trump
            )
        }
        let utilityContext = BotTurnCandidateRankingService.UtilityContext(
            trick: context.trick,
            trump: context.trump,
            shouldChaseTrick: shouldChaseTrick,
            hasWinningNonJoker: hasWinningNonJoker,
            hasLosingNonJoker: hasLosingNonJoker,
            tricksNeededToMatchBid: tricksNeededToMatchBid,
            tricksRemainingIncludingCurrent: tricksRemainingIncludingCurrent,
            chasePressure: chasePressure
        )

        var best: CandidateEvaluation?
        for card in context.legalCards {
            for decision in cardHeuristics.candidateDecisions(
                for: card,
                trick: context.trick,
                shouldChaseTrick: shouldChaseTrick
            ) {
                let move = CandidateMove(card: card, decision: decision)
                let immediateWinProbability = cardHeuristics.estimateImmediateWinProbability(
                    card: move.card,
                    decision: move.decision,
                    trick: context.trick,
                    trump: context.trump,
                    unseenCards: unseen,
                    opponentsRemaining: opponentsRemaining,
                    handSizeBeforeMove: context.handCards.count
                )
                let projectedFinalTricks = roundProjection.projectedFinalTricks(
                    currentTricks: context.currentTricks,
                    immediateWinProbability: immediateWinProbability,
                    remainingHand: roundProjection.remainingHand(afterPlaying: card, from: context.handCards),
                    trump: context.trump,
                    cardsInRound: context.cardsInRound
                )
                let projectedScore = roundProjection.expectedRoundScore(
                    cardsInRound: context.cardsInRound,
                    bid: context.targetBid,
                    expectedTricks: projectedFinalTricks
                )
                let threat = cardHeuristics.cardThreat(
                    card: card,
                    decision: decision,
                    trump: context.trump,
                    trick: context.trick
                )
                let utility = candidateRanking.moveUtility(
                    projectedScore: projectedScore,
                    immediateWinProbability: immediateWinProbability,
                    threat: threat,
                    move: move,
                    context: utilityContext
                )

                let evaluation = CandidateEvaluation(
                    move: move,
                    utility: utility,
                    immediateWinProbability: immediateWinProbability,
                    threat: threat
                )

                if let currentBest = best {
                    if candidateRanking.isBetterCandidate(
                        evaluation,
                        than: currentBest,
                        shouldChaseTrick: shouldChaseTrick
                    ) {
                        best = evaluation
                    }
                } else {
                    best = evaluation
                }
            }
        }

        guard let best else { return nil }
        return (card: best.move.card, jokerDecision: best.move.decision)
    }
}
