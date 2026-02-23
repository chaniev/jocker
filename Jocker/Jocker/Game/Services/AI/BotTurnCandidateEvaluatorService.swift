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
        let isBlind: Bool
        let matchContext: BotMatchContext?

        init(
            legalCards: [Card],
            handCards: [Card],
            trick: BotTurnCardHeuristicsService.TrickSnapshot,
            trump: Suit?,
            targetBid: Int,
            currentTricks: Int,
            cardsInRound: Int,
            playerCount: Int?,
            isBlind: Bool = false,
            matchContext: BotMatchContext? = nil
        ) {
            self.legalCards = legalCards
            self.handCards = handCards
            self.trick = trick
            self.trump = trump
            self.targetBid = targetBid
            self.currentTricks = currentTricks
            self.cardsInRound = cardsInRound
            self.playerCount = playerCount
            self.isBlind = isBlind
            self.matchContext = matchContext
        }
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
        playerCount: Int?,
        isBlind: Bool = false,
        matchContext: BotMatchContext? = nil
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
                playerCount: playerCount,
                isBlind: isBlind,
                matchContext: matchContext
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
            trickDeltaToBidBeforeMove: context.currentTricks - context.targetBid,
            chasePressure: chasePressure,
            isBlindRound: context.isBlind,
            matchContext: context.matchContext
        )

        var best: CandidateEvaluation?
        for card in context.legalCards {
            for decision in cardHeuristics.candidateDecisions(
                for: card,
                trick: context.trick,
                shouldChaseTrick: shouldChaseTrick
            ) {
                let move = CandidateMove(card: card, decision: decision)
                let remainingHand = roundProjection.remainingHand(afterPlaying: card, from: context.handCards)
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
                    remainingHand: remainingHand,
                    trump: context.trump,
                    cardsInRound: context.cardsInRound
                )
                let projectedScore = roundProjection.expectedRoundScore(
                    cardsInRound: context.cardsInRound,
                    bid: context.targetBid,
                    expectedTricks: projectedFinalTricks,
                    isBlind: context.isBlind,
                    matchContext: context.matchContext
                )
                let threat = cardHeuristics.cardThreat(
                    card: card,
                    decision: decision,
                    trump: context.trump,
                    trick: context.trick,
                    cardsRemainingInHandBeforeMove: context.handCards.count,
                    cardsInRound: context.cardsInRound
                )
                let utility = candidateRanking.moveUtility(
                    projectedScore: projectedScore,
                    immediateWinProbability: immediateWinProbability,
                    threat: threat,
                    move: move,
                    leadControlReserveAfterMove: leadControlReserveSignal(
                        afterPlaying: move.card,
                        decision: move.decision,
                        remainingHand: remainingHand,
                        trump: context.trump,
                        trick: context.trick
                    ),
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

    /// Этап 5: грубый сигнал "сколько контроля остаётся в руке после текущего хода".
    /// Используется только для lead-joker declaration scoring (`wish/above/takes`).
    private func leadControlReserveSignal(
        afterPlaying card: Card,
        decision: JokerPlayDecision,
        remainingHand: [Card],
        trump: Suit?,
        trick: BotTurnCardHeuristicsService.TrickSnapshot
    ) -> Double {
        guard card.isJoker else { return 0.0 }
        guard trick.playedCards.isEmpty else { return 0.0 }
        guard decision.style == .faceUp else { return 0.0 }
        guard decision.leadDeclaration != nil else { return 0.0 }
        guard !remainingHand.isEmpty else { return 0.0 }

        var rawControl = 0.0
        var trumpCount = 0

        for remainingCard in remainingHand {
            guard case .regular(let suit, let rank) = remainingCard else {
                rawControl += 1.0
                continue
            }

            if let trump, suit == trump {
                trumpCount += 1
                switch rank {
                case .ace:
                    rawControl += 1.20
                case .king:
                    rawControl += 1.00
                case .queen:
                    rawControl += 0.85
                case .jack:
                    rawControl += 0.65
                default:
                    rawControl += 0.35
                }
            } else {
                switch rank {
                case .ace:
                    rawControl += 0.70
                case .king:
                    rawControl += 0.55
                case .queen:
                    rawControl += 0.40
                case .jack:
                    rawControl += 0.22
                default:
                    break
                }
            }
        }

        if trumpCount >= 2 {
            rawControl += 0.20 * Double(trumpCount - 1)
        }

        let normalizedByHandSize = rawControl / Double(max(1, remainingHand.count))
        return min(1.0, max(0.0, normalizedByHandSize))
    }
}
