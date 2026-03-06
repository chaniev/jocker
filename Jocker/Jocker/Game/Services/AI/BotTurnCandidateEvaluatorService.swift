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
        struct HandContext {
            let legalCards: [Card]
            let handCards: [Card]
        }

        struct TableContext {
            let trick: BotTurnCardHeuristicsService.TrickSnapshot
            let trump: Suit?
            let playerCount: Int?
            let actingPlayerIndex: Int?
            let matchContext: BotMatchContext?
        }

        struct RoundContext {
            let targetBid: Int
            let currentTricks: Int
            let cardsInRound: Int
            let isBlind: Bool
            let roundState: BotMatchContext.RoundSnapshot?
            let completedTricksInRound: [[PlayedTrickCard]]
        }

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
        let roundState: BotMatchContext.RoundSnapshot?
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
            roundState: BotMatchContext.RoundSnapshot? = nil,
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
            self.roundState = roundState
            self.actingPlayerIndex = actingPlayerIndex
            self.completedTricksInRound = completedTricksInRound
        }

        var handContext: HandContext {
            HandContext(
                legalCards: legalCards,
                handCards: handCards
            )
        }

        var tableContext: TableContext {
            TableContext(
                trick: trick,
                trump: trump,
                playerCount: playerCount,
                actingPlayerIndex: actingPlayerIndex,
                matchContext: matchContext
            )
        }

        var roundContext: RoundContext {
            RoundContext(
                targetBid: targetBid,
                currentTricks: currentTricks,
                cardsInRound: cardsInRound,
                isBlind: isBlind,
                roundState: roundState,
                completedTricksInRound: completedTricksInRound
            )
        }
    }

    private let cardHeuristics: BotTurnCardHeuristicsService
    private let roundProjection: BotTurnRoundProjectionService
    private let candidateRanking: BotTurnCandidateRankingService
    private let beliefStateBuilder: BotTurnBeliefStateBuilder
    private let opponentOrderResolver: BotTurnOpponentOrderResolver
    private let rolloutService: BotTurnRolloutService
    private let endgameSolver: BotTurnEndgameSolver

    typealias CandidateMove = BotTurnCandidateRankingService.Move
    typealias CandidateEvaluation = BotTurnCandidateRankingService.Evaluation

    struct CandidateScore {
        let evaluation: CandidateEvaluation
        let remainingHand: [Card]
        let projectedScore: Double
        let baselineUtility: Double
    }

    init(
        cardHeuristics: BotTurnCardHeuristicsService,
        roundProjection: BotTurnRoundProjectionService,
        candidateRanking: BotTurnCandidateRankingService
    ) {
        let beliefStateBuilder = BotTurnBeliefStateBuilder()
        let opponentOrderResolver = BotTurnOpponentOrderResolver()
        let samplingService = BotTurnSamplingService()
        let simulationService = BotTurnSimulationService(
            opponentOrderResolver: opponentOrderResolver
        )
        self.cardHeuristics = cardHeuristics
        self.roundProjection = roundProjection
        self.candidateRanking = candidateRanking
        self.beliefStateBuilder = beliefStateBuilder
        self.opponentOrderResolver = opponentOrderResolver
        self.rolloutService = BotTurnRolloutService(
            candidateRanking: candidateRanking,
            samplingService: samplingService,
            simulationService: simulationService,
            opponentOrderResolver: opponentOrderResolver
        )
        self.endgameSolver = BotTurnEndgameSolver(
            samplingService: samplingService,
            simulationService: simulationService,
            opponentOrderResolver: opponentOrderResolver
        )
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
        roundState: BotMatchContext.RoundSnapshot? = nil,
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
                roundState: roundState,
                actingPlayerIndex: actingPlayerIndex,
                completedTricksInRound: completedTricksInRound
            )
        )
    }

    func bestMove(
        context: DecisionContext
    ) -> (card: Card, jokerDecision: JokerPlayDecision)? {
        guard !context.handContext.legalCards.isEmpty else { return nil }

        let shouldChaseTrick = context.roundContext.currentTricks < context.roundContext.targetBid
        let tricksNeededToMatchBid = max(0, context.roundContext.targetBid - context.roundContext.currentTricks)
        let tricksRemainingIncludingCurrent = max(1, context.handContext.handCards.count)
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
            playerCount: context.tableContext.playerCount,
            cardsAlreadyOnTable: context.tableContext.trick.playedCards.count
        )
        let remainingOpponentPlayerIndices = opponentOrderResolver.remainingOpponentOrder(
            for: context.tableContext
        )
        let resolvedOpponentsRemaining = remainingOpponentPlayerIndices?.count ?? opponentsRemaining
        let beliefState = beliefStateBuilder.build(
            tableContext: context.tableContext,
            roundContext: context.roundContext
        )
        let unseen = cardHeuristics.unseenCards(
            excluding: context.handContext.handCards,
            and: context.tableContext.trick.playedCards.map(\.card)
        )

        let hasWinningNonJoker = context.handContext.legalCards.contains { card in
            guard !card.isJoker else { return false }
            return cardHeuristics.winsTrickRightNow(
                with: card,
                decision: .defaultNonLead,
                trick: context.tableContext.trick,
                trump: context.tableContext.trump
            )
        }
        let hasLosingNonJoker = context.handContext.legalCards.contains { card in
            guard !card.isJoker else { return false }
            return !cardHeuristics.winsTrickRightNow(
                with: card,
                decision: .defaultNonLead,
                trick: context.tableContext.trick,
                trump: context.tableContext.trump
            )
        }
        let utilityContext = BotTurnCandidateRankingService.UtilityContext(
            trick: context.tableContext.trick,
            trump: context.tableContext.trump,
            shouldChaseTrick: shouldChaseTrick,
            hasWinningNonJoker: hasWinningNonJoker,
            hasLosingNonJoker: hasLosingNonJoker,
            tricksNeededToMatchBid: tricksNeededToMatchBid,
            tricksRemainingIncludingCurrent: tricksRemainingIncludingCurrent,
            trickDeltaToBidBeforeMove: context.roundContext.currentTricks - context.roundContext.targetBid,
            chasePressure: chasePressure,
            isBlindRound: context.roundContext.isBlind,
            matchContext: context.tableContext.matchContext,
            roundState: context.roundContext.roundState,
            actingPlayerIndex: context.tableContext.actingPlayerIndex,
            remainingOpponentPlayerIndices: remainingOpponentPlayerIndices,
            opponentIntention: opponentOrderResolver.makeOpponentIntentionModel(
                tableContext: context.tableContext,
                roundContext: context.roundContext,
                beliefState: beliefState,
                remainingOpponentPlayerIndices: remainingOpponentPlayerIndices
            )
        )
        var scoredCandidates: [CandidateScore] = []
        scoredCandidates.reserveCapacity(context.handContext.legalCards.count * 3)
        for card in context.handContext.legalCards {
            for decision in cardHeuristics.candidateDecisions(
                for: card,
                trick: context.tableContext.trick,
                shouldChaseTrick: shouldChaseTrick
            ) {
                let move = CandidateMove(card: card, decision: decision)
                let remainingHand = roundProjection.remainingHand(
                    afterPlaying: card,
                    from: context.handContext.handCards
                )
                let preferredControlSuitSignal = leadPreferredControlSuitSignal(
                    afterPlaying: move.card,
                    decision: move.decision,
                    remainingHand: remainingHand,
                    trump: context.tableContext.trump,
                    trick: context.tableContext.trick
                )
                let immediateWinProbability = cardHeuristics.estimateImmediateWinProbability(
                    card: move.card,
                    decision: move.decision,
                    trick: context.tableContext.trick,
                    trump: context.tableContext.trump,
                    unseenCards: unseen,
                    opponentsRemaining: resolvedOpponentsRemaining,
                    handSizeBeforeMove: context.handContext.handCards.count,
                    beliefState: beliefState,
                    remainingOpponentPlayerIndices: remainingOpponentPlayerIndices
                )
                let projectedFinalTricks = roundProjection.projectedFinalTricks(
                    currentTricks: context.roundContext.currentTricks,
                    immediateWinProbability: immediateWinProbability,
                    remainingHand: remainingHand,
                    trump: context.tableContext.trump,
                    cardsInRound: context.roundContext.cardsInRound
                )
                let projectedScore = roundProjection.expectedRoundScore(
                    cardsInRound: context.roundContext.cardsInRound,
                    bid: context.roundContext.targetBid,
                    expectedTricks: projectedFinalTricks,
                    isBlind: context.roundContext.isBlind,
                    matchContext: context.tableContext.matchContext
                )
                let threat = cardHeuristics.cardThreat(
                    card: card,
                    decision: decision,
                    trump: context.tableContext.trump,
                    trick: context.tableContext.trick,
                    cardsRemainingInHandBeforeMove: context.handContext.handCards.count,
                    cardsInRound: context.roundContext.cardsInRound,
                    completedTricksInRound: context.roundContext.completedTricksInRound,
                    playerCount: context.tableContext.playerCount
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
                        trump: context.tableContext.trump,
                        trick: context.tableContext.trick
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
                scoredCandidates.append(
                    CandidateScore(
                        evaluation: evaluation,
                        remainingHand: remainingHand,
                        projectedScore: projectedScore,
                        baselineUtility: utility
                    )
                )
            }
        }

        guard !scoredCandidates.isEmpty else { return nil }

        var finalEvaluations = scoredCandidates.map(\.evaluation)
        let rolloutUrgencyWeight = rolloutService.urgencyWeight(
            context: context,
            shouldChaseTrick: shouldChaseTrick
        )
        if endgameSolver.shouldApplySolver(
            context: context,
            scoredCandidates: scoredCandidates
        ) {
            finalEvaluations = endgameSolver.applyAdjustments(
                to: scoredCandidates,
                context: context,
                shouldChaseTrick: shouldChaseTrick,
                beliefState: beliefState,
                unseenCards: unseen,
                remainingOpponentPlayerIndices: remainingOpponentPlayerIndices,
                urgencyWeight: rolloutUrgencyWeight
            )
        } else if rolloutService.shouldApplyRollout(
            context: context,
            scoredCandidates: scoredCandidates,
            tricksNeededToMatchBid: tricksNeededToMatchBid
        ) {
            finalEvaluations = rolloutService.applyAdjustments(
                to: scoredCandidates,
                context: context,
                shouldChaseTrick: shouldChaseTrick,
                beliefState: beliefState,
                unseenCards: unseen,
                remainingOpponentPlayerIndices: remainingOpponentPlayerIndices
            )
        }

        var best = finalEvaluations[0]
        for candidate in finalEvaluations.dropFirst() {
            if candidateRanking.isBetterCandidate(
                candidate,
                than: best,
                shouldChaseTrick: shouldChaseTrick
            ) {
                best = candidate
            }
        }

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
