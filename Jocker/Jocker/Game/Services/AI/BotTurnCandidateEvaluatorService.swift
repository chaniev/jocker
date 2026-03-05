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
        let actingPlayerIndex: Int?
        let completedTricksInRound: [[PlayedTrickCard]]

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
            matchContext: BotMatchContext? = nil,
            actingPlayerIndex: Int? = nil,
            completedTricksInRound: [[PlayedTrickCard]] = []
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
            self.actingPlayerIndex = actingPlayerIndex
            self.completedTricksInRound = completedTricksInRound
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
        matchContext: BotMatchContext? = nil,
        actingPlayerIndex: Int? = nil,
        completedTricksInRound: [[PlayedTrickCard]] = []
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
                matchContext: matchContext,
                actingPlayerIndex: actingPlayerIndex,
                completedTricksInRound: completedTricksInRound
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
        let remainingOpponentPlayerIndices = remainingOpponentOrder(
            trick: context.trick,
            playerCount: context.playerCount,
            actingPlayerIndex: context.actingPlayerIndex
        )
        let resolvedOpponentsRemaining = remainingOpponentPlayerIndices?.count ?? opponentsRemaining
        let beliefState = makeBeliefState(
            context: context
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
                let preferredControlSuitSignal = leadPreferredControlSuitSignal(
                    afterPlaying: move.card,
                    decision: move.decision,
                    remainingHand: remainingHand,
                    trump: context.trump,
                    trick: context.trick
                )
                let immediateWinProbability = cardHeuristics.estimateImmediateWinProbability(
                    card: move.card,
                    decision: move.decision,
                    trick: context.trick,
                    trump: context.trump,
                    unseenCards: unseen,
                    opponentsRemaining: resolvedOpponentsRemaining,
                    handSizeBeforeMove: context.handCards.count,
                    beliefState: beliefState,
                    remainingOpponentPlayerIndices: remainingOpponentPlayerIndices
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
                    leadPreferredControlSuitAfterMove: preferredControlSuitSignal.suit,
                    leadPreferredControlSuitStrengthAfterMove: preferredControlSuitSignal.strength,
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

    private func makeBeliefState(
        context: DecisionContext
    ) -> BotBeliefState? {
        guard let playerCount = context.playerCount, playerCount > 1 else {
            return nil
        }
        return BotBeliefState.infer(
            playerCount: playerCount,
            completedTricks: context.completedTricksInRound,
            currentTrick: context.trick.playedCards,
            trump: context.trump
        )
    }

    private func remainingOpponentOrder(
        trick: BotTurnCardHeuristicsService.TrickSnapshot,
        playerCount: Int?,
        actingPlayerIndex: Int?
    ) -> [Int]? {
        guard let playerCount, playerCount > 1 else { return nil }
        let cardsAlreadyOnTable = trick.playedCards.count
        guard cardsAlreadyOnTable < playerCount else { return [] }

        let resolvedCurrentPlayer: Int
        if let actingPlayerIndex {
            resolvedCurrentPlayer = normalizedPlayerIndex(
                actingPlayerIndex,
                playerCount: playerCount
            )
        } else if let leadPlayer = trick.playedCards.first?.playerIndex {
            resolvedCurrentPlayer = normalizedPlayerIndex(
                leadPlayer + cardsAlreadyOnTable,
                playerCount: playerCount
            )
        } else {
            return nil
        }

        let remainingTurns = max(0, playerCount - cardsAlreadyOnTable - 1)
        guard remainingTurns > 0 else { return [] }
        return (1...remainingTurns).map { offset in
            normalizedPlayerIndex(resolvedCurrentPlayer + offset, playerCount: playerCount)
        }
    }

    private func normalizedPlayerIndex(
        _ index: Int,
        playerCount: Int
    ) -> Int {
        guard playerCount > 0 else { return 0 }
        return ((index % playerCount) + playerCount) % playerCount
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

    /// Этап 5: оценка "какую масть полезно контролировать после lead-джокера".
    /// Возвращает масть с наибольшим post-joker control potential и нормализованную силу сигнала.
    private func leadPreferredControlSuitSignal(
        afterPlaying card: Card,
        decision: JokerPlayDecision,
        remainingHand: [Card],
        trump: Suit?,
        trick: BotTurnCardHeuristicsService.TrickSnapshot
    ) -> (suit: Suit?, strength: Double) {
        guard card.isJoker else { return (nil, 0.0) }
        guard trick.playedCards.isEmpty else { return (nil, 0.0) }
        guard decision.style == .faceUp else { return (nil, 0.0) }
        guard decision.leadDeclaration != nil else { return (nil, 0.0) }
        guard !remainingHand.isEmpty else { return (nil, 0.0) }

        var suitScores: [Suit: Double] = [:]
        for remainingCard in remainingHand {
            guard case .regular(let suit, let rank) = remainingCard else { continue }

            var score = 0.2
            switch rank {
            case .ace:
                score += 1.20
            case .king:
                score += 0.95
            case .queen:
                score += 0.75
            case .jack:
                score += 0.50
            case .ten:
                score += 0.35
            default:
                score += 0.12
            }
            if let trump, suit == trump {
                score += 0.45
            }

            suitScores[suit, default: 0.0] += score
        }

        guard let best = suitScores.max(by: { lhs, rhs in
            if abs(lhs.value - rhs.value) > 0.000_001 {
                return lhs.value < rhs.value
            }
            return lhs.key.rawValue < rhs.key.rawValue
        }) else {
            return (nil, 0.0)
        }

        let totalScore = suitScores.values.reduce(0.0, +)
        guard totalScore > 0 else { return (best.key, 0.0) }
        let share = best.value / totalScore
        let concentration = min(1.0, max(0.0, (share - 0.25) / 0.55))
        return (best.key, concentration)
    }
}
