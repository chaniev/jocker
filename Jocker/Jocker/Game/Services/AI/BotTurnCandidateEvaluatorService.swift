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
    }

    private let cardHeuristics: BotTurnCardHeuristicsService
    private let roundProjection: BotTurnRoundProjectionService
    private let candidateRanking: BotTurnCandidateRankingService

    private typealias CandidateMove = BotTurnCandidateRankingService.Move
    private typealias CandidateEvaluation = BotTurnCandidateRankingService.Evaluation

    private struct CandidateScore {
        let evaluation: CandidateEvaluation
        let remainingHand: [Card]
        let baselineUtility: Double
    }

    private enum RolloutConfig {
        static let topCandidateCount = 2
        static let minimumIterations = 4
        static let maximumIterations = 8
        static let maxCardsPerOpponentSample = 2
        static let maxTrickHorizon = 2
    }

    private struct DeterministicRNG {
        private var state: UInt64

        init(seed: UInt64) {
            self.state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
        }

        mutating func nextUInt64() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }

        mutating func nextInt(upperBound: Int) -> Int {
            guard upperBound > 0 else { return 0 }
            return Int(nextUInt64() % UInt64(upperBound))
        }
    }

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
            matchContext: context.matchContext,
            roundState: context.roundState,
            actingPlayerIndex: context.actingPlayerIndex,
            remainingOpponentPlayerIndices: remainingOpponentPlayerIndices,
            opponentIntention: makeOpponentIntentionModel(
                context: context,
                beliefState: beliefState,
                remainingOpponentPlayerIndices: remainingOpponentPlayerIndices
            )
        )
        var scoredCandidates: [CandidateScore] = []
        scoredCandidates.reserveCapacity(context.legalCards.count * 3)
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
                scoredCandidates.append(
                    CandidateScore(
                        evaluation: evaluation,
                        remainingHand: remainingHand,
                        baselineUtility: utility
                    )
                )
            }
        }

        guard !scoredCandidates.isEmpty else { return nil }

        var finalEvaluations = scoredCandidates.map(\.evaluation)
        if shouldApplyRollout(
            context: context,
            scoredCandidates: scoredCandidates,
            tricksNeededToMatchBid: tricksNeededToMatchBid
        ) {
            finalEvaluations = applyRolloutAdjustments(
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

    private func makeOpponentIntentionModel(
        context: DecisionContext,
        beliefState: BotBeliefState?,
        remainingOpponentPlayerIndices: [Int]?
    ) -> BotTurnCandidateRankingService.OpponentIntentionModel? {
        guard let matchContext = context.matchContext else { return nil }
        guard let opponents = matchContext.opponents else { return nil }
        guard !opponents.snapshots.isEmpty else { return nil }

        let roundState = context.roundState ?? matchContext.round
        let leadSuit = effectiveLeadSuit(from: context.trick)
        let positionWeights = makePositionWeights(
            remainingOpponentPlayerIndices: remainingOpponentPlayerIndices
        )

        var signals: [BotTurnCandidateRankingService.OpponentIntentionModel.OpponentSignal] = []
        signals.reserveCapacity(opponents.snapshots.count)
        var hasEvidence = false

        for snapshot in opponents.snapshots {
            let observedRounds = max(0, snapshot.observedRounds)
            let evidenceWeight = min(1.0, Double(observedRounds) / 4.0)
            guard evidenceWeight > 0 else { continue }
            hasEvidence = true

            let needsTricks = roundState?.needsTricks(for: snapshot.playerIndex) ?? 0
            let exact = min(1.0, max(0.0, snapshot.exactBidRate))
            let over = min(1.0, max(0.0, snapshot.overbidRate))
            let under = min(1.0, max(0.0, snapshot.underbidRate))
            let aggression = min(1.0, max(0.0, snapshot.averageBidAggression))

            let disciplineSignal = min(1.0, max(0.0, 0.5 + 0.5 * (exact - 0.5 * (over + under))))
            let exactWindowSignal: Double = {
                switch needsTricks {
                case 1:
                    return 1.0
                case 2:
                    return 0.65
                case ...0:
                    return 0.18
                default:
                    return 0.42
                }
            }()
            let leadVoidSignal: Double = {
                guard let leadSuit else { return 0.0 }
                guard let beliefState else { return 0.0 }
                return beliefState.isVoid(leadSuit, for: snapshot.playerIndex) ? 1.0 : 0.0
            }()
            let positionWeight = positionWeights[snapshot.playerIndex] ?? 0.35
            let contestIntent = min(
                1.0,
                max(
                    0.0,
                    0.30 +
                        disciplineSignal * 0.35 +
                        aggression * 0.15 +
                        exactWindowSignal * 0.20 +
                        leadVoidSignal * 0.12
                )
            )
            let denyUrgency = exactWindowSignal * 0.8 + 0.2
            let denyPressure = contestIntent * positionWeight * evidenceWeight * denyUrgency

            signals.append(
                .init(
                    playerIndex: snapshot.playerIndex,
                    needsTricks: max(0, needsTricks),
                    likelyToContestCurrentTrick: contestIntent,
                    denyPressure: denyPressure,
                    evidenceWeight: evidenceWeight
                )
            )
        }

        let sortedSignals = signals.sorted { lhs, rhs in
            if abs(lhs.denyPressure - rhs.denyPressure) > 0.000_001 {
                return lhs.denyPressure > rhs.denyPressure
            }
            return lhs.playerIndex < rhs.playerIndex
        }
        let strongest = sortedSignals.first
        let totalPressure = sortedSignals.reduce(0.0) { $0 + $1.denyPressure }

        return BotTurnCandidateRankingService.OpponentIntentionModel(
            opponentSignals: sortedSignals,
            strongestTargetIndex: strongest?.playerIndex,
            strongestDenyPressure: strongest?.denyPressure ?? 0.0,
            totalDenyPressure: totalPressure,
            hasEvidence: hasEvidence
        )
    }

    private func makePositionWeights(
        remainingOpponentPlayerIndices: [Int]?
    ) -> [Int: Double] {
        guard let remainingOpponentPlayerIndices, !remainingOpponentPlayerIndices.isEmpty else {
            return [:]
        }

        var weights: [Int: Double] = [:]
        for (position, playerIndex) in remainingOpponentPlayerIndices.enumerated() {
            let base: Double
            switch position {
            case 0:
                base = 1.0
            case 1:
                base = 0.82
            case 2:
                base = 0.64
            default:
                base = 0.50
            }
            weights[playerIndex] = max(weights[playerIndex] ?? 0.0, base)
        }
        return weights
    }

    private func shouldApplyRollout(
        context: DecisionContext,
        scoredCandidates: [CandidateScore],
        tricksNeededToMatchBid: Int
    ) -> Bool {
        let handSize = context.handCards.count
        let handSizeGate = handSize <= 3
        let jokerGate = handSize <= 4 && scoredCandidates.contains { $0.evaluation.move.card.isJoker }
        let lateBlockUrgencyGate = handSize <= 4 &&
            (context.matchContext?.blockProgressFraction ?? 0.0) >= 0.90
        let criticalDeficitGate = handSize <= 4 &&
            tricksNeededToMatchBid >= max(2, context.handCards.count - 1)
        return handSizeGate || jokerGate || lateBlockUrgencyGate || criticalDeficitGate
    }

    private func applyRolloutAdjustments(
        to scoredCandidates: [CandidateScore],
        context: DecisionContext,
        shouldChaseTrick: Bool,
        beliefState: BotBeliefState?,
        unseenCards: [Card],
        remainingOpponentPlayerIndices: [Int]?
    ) -> [CandidateEvaluation] {
        guard !scoredCandidates.isEmpty else { return [] }

        let topIndices = scoredCandidates.indices.sorted { lhs, rhs in
            let left = scoredCandidates[lhs].evaluation
            let right = scoredCandidates[rhs].evaluation
            if abs(left.utility - right.utility) > 0.000_001 {
                return left.utility > right.utility
            }
            return candidateRanking.isBetterCandidate(left, than: right, shouldChaseTrick: shouldChaseTrick)
        }

        let selectedIndices = Set(topIndices.prefix(RolloutConfig.topCandidateCount))
        let rolloutIterations = min(
            RolloutConfig.maximumIterations,
            max(
                RolloutConfig.minimumIterations,
                unseenCards.isEmpty ? RolloutConfig.minimumIterations : unseenCards.count / 4
            )
        )
        let rolloutHorizon = min(
            RolloutConfig.maxTrickHorizon,
            max(1, context.handCards.count)
        )
        let urgencyWeight = rolloutUrgencyWeight(context: context, shouldChaseTrick: shouldChaseTrick)

        return scoredCandidates.enumerated().map { entry in
            let index = entry.offset
            let candidate = entry.element
            guard selectedIndices.contains(index) else {
                return candidate.evaluation
            }

            var averageBotWins = 0.0
            for iteration in 0..<rolloutIterations {
                var rng = DeterministicRNG(
                    seed: rolloutSeed(
                        candidate: candidate,
                        context: context,
                        iteration: iteration
                    )
                )
                let botWins = simulateRolloutBotTrickWins(
                    candidate: candidate,
                    context: context,
                    beliefState: beliefState,
                    unseenCards: unseenCards,
                    remainingOpponentPlayerIndices: remainingOpponentPlayerIndices,
                    rolloutHorizon: rolloutHorizon,
                    rng: &rng
                )
                averageBotWins += Double(botWins)
            }
            averageBotWins /= Double(max(1, rolloutIterations))

            let normalizedSuccess: Double
            if shouldChaseTrick {
                normalizedSuccess = averageBotWins / Double(max(1, rolloutHorizon))
            } else {
                normalizedSuccess = (Double(rolloutHorizon) - averageBotWins) /
                    Double(max(1, rolloutHorizon))
            }
            let centeredSuccess = min(1.0, max(0.0, normalizedSuccess)) - 0.5
            let rolloutAdjustment = centeredSuccess * (6.0 + 10.0 * urgencyWeight)

            return CandidateEvaluation(
                move: candidate.evaluation.move,
                utility: candidate.baselineUtility + rolloutAdjustment,
                immediateWinProbability: candidate.evaluation.immediateWinProbability,
                threat: candidate.evaluation.threat
            )
        }
    }

    private func rolloutUrgencyWeight(
        context: DecisionContext,
        shouldChaseTrick: Bool
    ) -> Double {
        let lateBlock = context.matchContext?.blockProgressFraction ?? 0.0
        let deficit = max(0, context.targetBid - context.currentTricks)
        let deficitPressure = min(
            1.0,
            Double(deficit) / Double(max(1, context.handCards.count))
        )
        if shouldChaseTrick {
            return min(1.0, max(0.0, 0.45 + 0.35 * deficitPressure + 0.20 * lateBlock))
        }
        return min(1.0, max(0.0, 0.35 + 0.45 * lateBlock + 0.20 * deficitPressure))
    }

    private func rolloutSeed(
        candidate: CandidateScore,
        context: DecisionContext,
        iteration: Int
    ) -> UInt64 {
        var hasher = Hasher()
        hasher.combine(candidate.evaluation.move.card)
        hasher.combine(candidate.evaluation.move.decision.style)
        switch candidate.evaluation.move.decision.leadDeclaration {
        case .wish:
            hasher.combine(1)
        case .above(let suit):
            hasher.combine(2)
            hasher.combine(suit.rawValue)
        case .takes(let suit):
            hasher.combine(3)
            hasher.combine(suit.rawValue)
        case .none:
            hasher.combine(0)
        }
        hasher.combine(context.currentTricks)
        hasher.combine(context.targetBid)
        hasher.combine(context.handCards.count)
        hasher.combine(context.trick.playedCards.count)
        hasher.combine(iteration)
        let hash = hasher.finalize()
        return UInt64(bitPattern: Int64(hash))
    }

    private func simulateRolloutBotTrickWins(
        candidate: CandidateScore,
        context: DecisionContext,
        beliefState: BotBeliefState?,
        unseenCards: [Card],
        remainingOpponentPlayerIndices: [Int]?,
        rolloutHorizon: Int,
        rng: inout DeterministicRNG
    ) -> Int {
        let fallbackPlayerCount = max(2, context.trick.playedCards.count + 1)
        let playerCount = max(
            fallbackPlayerCount,
            context.playerCount ?? context.matchContext?.playerCount ?? fallbackPlayerCount
        )
        let botIndex = normalizedPlayerIndex(
            context.actingPlayerIndex ?? context.matchContext?.playerIndex ?? 0,
            playerCount: playerCount
        )
        let opponentIndices = (0..<playerCount).filter { $0 != botIndex }
        let sampleCardsPerOpponent = min(
            RolloutConfig.maxCardsPerOpponentSample,
            max(1, rolloutHorizon)
        )
        var sampledHands = sampleOpponentHands(
            opponentIndices: opponentIndices,
            unseenCards: unseenCards,
            cardsPerOpponent: sampleCardsPerOpponent,
            beliefState: beliefState,
            rng: &rng
        )
        var botHand = candidate.remainingHand

        let roundSnapshot = context.roundState ?? context.matchContext?.round
        var simulatedBids = normalizedRoundValues(
            values: roundSnapshot?.bids,
            fallback: 0,
            playerCount: playerCount
        )
        simulatedBids[botIndex] = context.targetBid
        var simulatedTricks = normalizedRoundValues(
            values: roundSnapshot?.tricksTaken,
            fallback: 0,
            playerCount: playerCount
        )
        simulatedTricks[botIndex] = context.currentTricks

        var botWins = 0
        var currentTrick = context.trick.playedCards + [
            PlayedTrickCard(
                playerIndex: botIndex,
                card: candidate.evaluation.move.card,
                jokerPlayStyle: candidate.evaluation.move.decision.style,
                jokerLeadDeclaration: candidate.evaluation.move.decision.leadDeclaration
            )
        ]
        let currentTrickRemainingOrder = remainingOpponentPlayerIndices ??
            rolloutRemainingOpponentOrder(
                playedCardsCount: context.trick.playedCards.count,
                playerCount: playerCount,
                actingPlayerIndex: botIndex
            )

        for opponentIndex in currentTrickRemainingOrder {
            guard opponentIndex != botIndex else { continue }
            var opponentHand = sampledHands[opponentIndex] ?? []
            if let simulatedMove = simulatedMove(
                playerIndex: opponentIndex,
                hand: &opponentHand,
                trick: currentTrick,
                trump: context.trump,
                bid: simulatedBids[opponentIndex],
                tricksTaken: simulatedTricks[opponentIndex],
                shouldPreferControl: false
            ) {
                sampledHands[opponentIndex] = opponentHand
                currentTrick.append(simulatedMove)
            }
        }

        var leader = TrickTakingResolver.winnerPlayerIndex(
            playedCards: currentTrick,
            trump: context.trump
        ) ?? botIndex
        if leader == botIndex {
            botWins += 1
        }
        if simulatedTricks.indices.contains(leader) {
            simulatedTricks[leader] += 1
        }

        guard rolloutHorizon > 1 else { return botWins }

        for _ in 1..<rolloutHorizon {
            var trick: [PlayedTrickCard] = []
            for offset in 0..<playerCount {
                let currentPlayer = normalizedPlayerIndex(leader + offset, playerCount: playerCount)
                if currentPlayer == botIndex {
                    if let simulatedMove = simulatedMove(
                        playerIndex: botIndex,
                        hand: &botHand,
                        trick: trick,
                        trump: context.trump,
                        bid: simulatedBids[botIndex],
                        tricksTaken: simulatedTricks[botIndex],
                        shouldPreferControl: true
                    ) {
                        trick.append(simulatedMove)
                    }
                    continue
                }

                var opponentHand = sampledHands[currentPlayer] ?? []
                if let simulatedMove = simulatedMove(
                    playerIndex: currentPlayer,
                    hand: &opponentHand,
                    trick: trick,
                    trump: context.trump,
                    bid: simulatedBids[currentPlayer],
                    tricksTaken: simulatedTricks[currentPlayer],
                    shouldPreferControl: false
                ) {
                    sampledHands[currentPlayer] = opponentHand
                    trick.append(simulatedMove)
                }
            }

            guard trick.count >= 2 else { break }
            leader = TrickTakingResolver.winnerPlayerIndex(
                playedCards: trick,
                trump: context.trump
            ) ?? leader
            if leader == botIndex {
                botWins += 1
            }
            if simulatedTricks.indices.contains(leader) {
                simulatedTricks[leader] += 1
            }
        }

        return botWins
    }

    private func sampleOpponentHands(
        opponentIndices: [Int],
        unseenCards: [Card],
        cardsPerOpponent: Int,
        beliefState: BotBeliefState?,
        rng: inout DeterministicRNG
    ) -> [Int: [Card]] {
        guard !opponentIndices.isEmpty else { return [:] }
        guard cardsPerOpponent > 0 else { return [:] }

        var cardPool = unseenCards.sorted()
        deterministicShuffle(&cardPool, rng: &rng)
        var result: [Int: [Card]] = [:]

        for opponentIndex in opponentIndices {
            guard !cardPool.isEmpty else {
                result[opponentIndex] = []
                continue
            }

            let drawCount = min(cardsPerOpponent, cardPool.count)
            let voidSuits = beliefState?.voidSuits(for: opponentIndex) ?? []
            var selectedIndices: [Int] = []
            var deferredIndices: [Int] = []

            for index in cardPool.indices {
                guard selectedIndices.count < drawCount else { break }
                if let suit = cardPool[index].suit, voidSuits.contains(suit) {
                    deferredIndices.append(index)
                    continue
                }
                selectedIndices.append(index)
            }

            if selectedIndices.count < drawCount {
                for index in deferredIndices where selectedIndices.count < drawCount {
                    selectedIndices.append(index)
                }
            }

            if selectedIndices.count < drawCount {
                for index in cardPool.indices where selectedIndices.count < drawCount {
                    guard !selectedIndices.contains(index) else { continue }
                    selectedIndices.append(index)
                }
            }

            selectedIndices.sort(by: >)
            var hand: [Card] = []
            hand.reserveCapacity(selectedIndices.count)
            for index in selectedIndices {
                hand.append(cardPool.remove(at: index))
            }
            hand.sort()
            result[opponentIndex] = hand
        }

        return result
    }

    private func deterministicShuffle(
        _ cards: inout [Card],
        rng: inout DeterministicRNG
    ) {
        guard cards.count > 1 else { return }
        for index in stride(from: cards.count - 1, through: 1, by: -1) {
            let swapIndex = rng.nextInt(upperBound: index + 1)
            if swapIndex != index {
                cards.swapAt(index, swapIndex)
            }
        }
    }

    private func simulatedMove(
        playerIndex: Int,
        hand: inout [Card],
        trick: [PlayedTrickCard],
        trump: Suit?,
        bid: Int,
        tricksTaken: Int,
        shouldPreferControl: Bool
    ) -> PlayedTrickCard? {
        guard !hand.isEmpty else { return nil }
        let legalCards = simulatedLegalCards(for: hand, trick: trick, trump: trump)
        guard !legalCards.isEmpty else { return nil }

        let needsTricks = max(0, bid - tricksTaken)
        let shouldChase = needsTricks > 0
        let winningCards = legalCards.filter { candidate in
            let decision = simulatedJokerDecision(
                for: candidate,
                shouldChase: shouldChase,
                trickIsEmpty: trick.isEmpty,
                trump: trump
            )
            return simulatedWinsTrick(
                with: candidate,
                decision: decision,
                trick: trick,
                playerIndex: playerIndex,
                trump: trump
            )
        }

        let selectedCard: Card
        if shouldChase {
            if !winningCards.isEmpty {
                selectedCard = winningCards.min {
                    simulatedCardPower($0, trump: trump, trick: trick, preferControl: shouldPreferControl) <
                        simulatedCardPower($1, trump: trump, trick: trick, preferControl: shouldPreferControl)
                } ?? winningCards[0]
            } else {
                selectedCard = legalCards.min {
                    simulatedCardPower($0, trump: trump, trick: trick, preferControl: shouldPreferControl) <
                        simulatedCardPower($1, trump: trump, trick: trick, preferControl: shouldPreferControl)
                } ?? legalCards[0]
            }
        } else {
            let losingCards = legalCards.filter { candidate in
                let decision = simulatedJokerDecision(
                    for: candidate,
                    shouldChase: shouldChase,
                    trickIsEmpty: trick.isEmpty,
                    trump: trump
                )
                return !simulatedWinsTrick(
                    with: candidate,
                    decision: decision,
                    trick: trick,
                    playerIndex: playerIndex,
                    trump: trump
                )
            }
            if !losingCards.isEmpty {
                selectedCard = losingCards.max {
                    simulatedCardPower($0, trump: trump, trick: trick, preferControl: shouldPreferControl) <
                        simulatedCardPower($1, trump: trump, trick: trick, preferControl: shouldPreferControl)
                } ?? losingCards[0]
            } else {
                selectedCard = legalCards.min {
                    simulatedCardPower($0, trump: trump, trick: trick, preferControl: shouldPreferControl) <
                        simulatedCardPower($1, trump: trump, trick: trick, preferControl: shouldPreferControl)
                } ?? legalCards[0]
            }
        }

        let decision = simulatedJokerDecision(
            for: selectedCard,
            shouldChase: shouldChase,
            trickIsEmpty: trick.isEmpty,
            trump: trump
        )
        if let removeIndex = hand.firstIndex(of: selectedCard) {
            hand.remove(at: removeIndex)
        }
        return PlayedTrickCard(
            playerIndex: playerIndex,
            card: selectedCard,
            jokerPlayStyle: decision.style,
            jokerLeadDeclaration: decision.leadDeclaration
        )
    }

    private func simulatedLegalCards(
        for hand: [Card],
        trick: [PlayedTrickCard],
        trump: Suit?
    ) -> [Card] {
        guard !hand.isEmpty else { return [] }
        let trickNode = TrickNode(rendersCards: false)
        for played in trick {
            _ = trickNode.playCard(
                played.card,
                fromPlayer: played.playerIndex + 1,
                jokerPlayStyle: played.jokerPlayStyle,
                jokerLeadDeclaration: played.jokerLeadDeclaration,
                animated: false
            )
        }
        let legalCards = hand.filter { card in
            trickNode.canPlayCard(card, fromHand: hand, trump: trump)
        }
        return legalCards.isEmpty ? hand : legalCards
    }

    private func simulatedJokerDecision(
        for card: Card,
        shouldChase: Bool,
        trickIsEmpty: Bool,
        trump: Suit?
    ) -> JokerPlayDecision {
        guard card.isJoker else { return .defaultNonLead }
        if !trickIsEmpty {
            return shouldChase
                ? JokerPlayDecision(style: .faceUp, leadDeclaration: nil)
                : JokerPlayDecision(style: .faceDown, leadDeclaration: nil)
        }

        if shouldChase {
            let preferredSuit = trump ?? .spades
            return JokerPlayDecision(style: .faceUp, leadDeclaration: .above(suit: preferredSuit))
        }

        let takesSuit = Suit.allCases.first(where: { $0 != trump }) ?? .hearts
        return JokerPlayDecision(style: .faceUp, leadDeclaration: .takes(suit: takesSuit))
    }

    private func simulatedWinsTrick(
        with card: Card,
        decision: JokerPlayDecision,
        trick: [PlayedTrickCard],
        playerIndex: Int,
        trump: Suit?
    ) -> Bool {
        let simulated = trick + [
            PlayedTrickCard(
                playerIndex: playerIndex,
                card: card,
                jokerPlayStyle: decision.style,
                jokerLeadDeclaration: decision.leadDeclaration
            )
        ]
        return TrickTakingResolver.winnerPlayerIndex(
            playedCards: simulated,
            trump: trump
        ) == playerIndex
    }

    private func simulatedCardPower(
        _ card: Card,
        trump: Suit?,
        trick: [PlayedTrickCard],
        preferControl: Bool
    ) -> Double {
        if card.isJoker {
            return preferControl ? 20_000 : 12_000
        }

        guard case .regular(let suit, let rank) = card else { return 0.0 }
        var power = Double(rank.rawValue)
        if let trump, suit == trump {
            power += 18.0
        }
        if let leadSuit = effectiveLeadSuit(from: .init(playedCards: trick)), suit == leadSuit {
            power += 5.0
        }
        if rank.rawValue >= Rank.queen.rawValue {
            power += 4.0
        }
        return power
    }

    private func effectiveLeadSuit(
        from trick: BotTurnCardHeuristicsService.TrickSnapshot
    ) -> Suit? {
        guard let lead = trick.playedCards.first else { return nil }
        if !lead.card.isJoker {
            return lead.card.suit
        }
        switch lead.jokerLeadDeclaration {
        case .above(let suit), .takes(let suit):
            return suit
        case .wish, .none:
            return nil
        }
    }

    private func normalizedRoundValues(
        values: [Int]?,
        fallback: Int,
        playerCount: Int
    ) -> [Int] {
        guard playerCount > 0 else { return [] }
        guard let values else {
            return Array(repeating: fallback, count: playerCount)
        }
        if values.count >= playerCount {
            return Array(values.prefix(playerCount))
        }
        return values + Array(repeating: fallback, count: playerCount - values.count)
    }

    private func rolloutRemainingOpponentOrder(
        playedCardsCount: Int,
        playerCount: Int,
        actingPlayerIndex: Int
    ) -> [Int] {
        guard playerCount > 1 else { return [] }
        let remainingTurns = max(0, playerCount - playedCardsCount - 1)
        guard remainingTurns > 0 else { return [] }
        return (1...remainingTurns).map { offset in
            normalizedPlayerIndex(actingPlayerIndex + offset, playerCount: playerCount)
        }
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
