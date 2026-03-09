//
//  BotTurnRolloutService.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

struct BotTurnRolloutService {
    private let policy: BotRuntimePolicy.Rollout
    private let candidateRanking: BotTurnCandidateRankingService
    private let samplingService: BotTurnSamplingService
    private let simulationService: BotTurnSimulationService
    private let opponentOrderResolver: BotTurnOpponentOrderResolver

    init(
        policy: BotRuntimePolicy.Rollout,
        candidateRanking: BotTurnCandidateRankingService,
        samplingService: BotTurnSamplingService,
        simulationService: BotTurnSimulationService,
        opponentOrderResolver: BotTurnOpponentOrderResolver
    ) {
        self.policy = policy
        self.candidateRanking = candidateRanking
        self.samplingService = samplingService
        self.simulationService = simulationService
        self.opponentOrderResolver = opponentOrderResolver
    }

    private func phase(from matchContext: BotMatchContext?) -> BotBlockPhase {
        matchContext.map { BotBlockPhase.from(blockProgressFraction: $0.blockProgressFraction) } ?? .mid
    }

    private func activationThreshold(
        from baseThreshold: Int,
        phase: BotBlockPhase
    ) -> Int {
        let normalizedBase = max(0, baseThreshold)
        guard normalizedBase > 0 else { return 0 }

        let scaled = Double(normalizedBase) * max(0.0, policy.phaseActivation.multiplier(for: phase))
        if scaled >= Double(normalizedBase) {
            return max(1, Int(ceil(scaled)))
        }
        return max(1, Int(floor(scaled)))
    }

    func shouldApplyRollout(
        context: BotTurnCandidateEvaluatorService.DecisionContext,
        scoredCandidates: [BotTurnCandidateEvaluatorService.CandidateScore],
        tricksNeededToMatchBid: Int
    ) -> Bool {
        let handSize = context.handContext.handCards.count
        let phase = phase(from: context.tableContext.matchContext)
        let handSizeGateThreshold = activationThreshold(
            from: policy.handSizeGateThreshold,
            phase: phase
        )
        let jokerGateThreshold = activationThreshold(
            from: policy.jokerGateHandSizeThreshold,
            phase: phase
        )
        let lateBlockUrgencyGateThreshold = activationThreshold(
            from: policy.lateBlockUrgencyHandSizeThreshold,
            phase: phase
        )
        let criticalDeficitGateThreshold = activationThreshold(
            from: policy.criticalDeficitHandSizeThreshold,
            phase: phase
        )

        let handSizeGate = handSizeGateThreshold > 0 && handSize <= handSizeGateThreshold
        let jokerGate = jokerGateThreshold > 0 &&
            handSize <= jokerGateThreshold &&
            scoredCandidates.contains { $0.evaluation.move.card.isJoker }
        let lateBlockUrgencyGate = lateBlockUrgencyGateThreshold > 0 &&
            handSize <= lateBlockUrgencyGateThreshold &&
            (context.tableContext.matchContext?.blockProgressFraction ?? 0.0) >= policy.lateBlockProgressThreshold
        let criticalDeficitGate = criticalDeficitGateThreshold > 0 &&
            handSize <= criticalDeficitGateThreshold &&
            tricksNeededToMatchBid >= max(policy.criticalDeficitMinimumFloor, context.handContext.handCards.count - 1)
        return handSizeGate || jokerGate || lateBlockUrgencyGate || criticalDeficitGate
    }

    func urgencyWeight(
        context: BotTurnCandidateEvaluatorService.DecisionContext,
        shouldChaseTrick: Bool
    ) -> Double {
        let lateBlock = context.tableContext.matchContext?.blockProgressFraction ?? 0.0
        let deficit = max(0, context.roundContext.targetBid - context.roundContext.currentTricks)
        let deficitPressure = min(
            1.0,
            Double(deficit) / Double(max(1, context.handContext.handCards.count))
        )
        if shouldChaseTrick {
            return min(
                1.0,
                max(
                    0.0,
                    policy.chaseUrgencyBase +
                        policy.chaseUrgencyDeficitWeight * deficitPressure +
                        policy.chaseUrgencyLateBlockWeight * lateBlock
                )
            )
        }
        return min(
            1.0,
            max(
                0.0,
                policy.dumpUrgencyBase +
                    policy.dumpUrgencyLateBlockWeight * lateBlock +
                    policy.dumpUrgencyDeficitWeight * deficitPressure
            )
        )
    }

    func applyAdjustments(
        to scoredCandidates: [BotTurnCandidateEvaluatorService.CandidateScore],
        context: BotTurnCandidateEvaluatorService.DecisionContext,
        shouldChaseTrick: Bool,
        beliefState: BotBeliefState?,
        unseenCards: [Card],
        remainingOpponentPlayerIndices: [Int]?
    ) -> [BotTurnCandidateRankingService.Evaluation] {
        guard !scoredCandidates.isEmpty else { return [] }

        let topIndices = scoredCandidates.indices.sorted { lhs, rhs in
            let left = scoredCandidates[lhs].evaluation
            let right = scoredCandidates[rhs].evaluation
            if abs(left.utility - right.utility) > policy.utilityTieTolerance {
                return left.utility > right.utility
            }
            return candidateRanking.isBetterCandidate(left, than: right, shouldChaseTrick: shouldChaseTrick)
        }

        let selectedIndices = Set(topIndices.prefix(policy.topCandidateCount))
        let rolloutIterations = min(
            policy.maximumIterations,
            max(
                policy.minimumIterations,
                unseenCards.isEmpty
                    ? policy.minimumIterations
                    : unseenCards.count / max(1, policy.unseenCardsIterationsDivisor)
            )
        )
        let rolloutHorizon = min(
            policy.maxTrickHorizon,
            max(1, context.handContext.handCards.count)
        )
        let urgencyWeight = urgencyWeight(
            context: context,
            shouldChaseTrick: shouldChaseTrick
        )
        let phase = phase(from: context.tableContext.matchContext)
        let phaseUtilityMult = policy.phaseUtilityAdjustment.multiplier(for: phase)

        return scoredCandidates.enumerated().map { entry in
            let index = entry.offset
            let candidate = entry.element
            guard selectedIndices.contains(index) else {
                return candidate.evaluation
            }

            var averageBotWins = 0.0
            for iteration in 0..<rolloutIterations {
                var rng = samplingService.makeRolloutRNG(
                    candidate: candidate,
                    context: context,
                    iteration: iteration
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
            let rolloutAdjustment = centeredSuccess *
                (policy.adjustmentBase + policy.adjustmentUrgencyWeight * urgencyWeight) *
                phaseUtilityMult

            return BotTurnCandidateRankingService.Evaluation(
                move: candidate.evaluation.move,
                utility: candidate.baselineUtility + rolloutAdjustment,
                immediateWinProbability: candidate.evaluation.immediateWinProbability,
                threat: candidate.evaluation.threat
            )
        }
    }

    private func simulateRolloutBotTrickWins(
        candidate: BotTurnCandidateEvaluatorService.CandidateScore,
        context: BotTurnCandidateEvaluatorService.DecisionContext,
        beliefState: BotBeliefState?,
        unseenCards: [Card],
        remainingOpponentPlayerIndices: [Int]?,
        rolloutHorizon: Int,
        rng: inout BotTurnSamplingService.DeterministicRNG
    ) -> Int {
        let seatContext = opponentOrderResolver.simulationSeatContext(
            for: context,
            remainingOpponentPlayerIndices: remainingOpponentPlayerIndices
        )
        let sampleCardsPerOpponent = min(
            policy.maxCardsPerOpponentSample,
            max(1, rolloutHorizon)
        )
        var sampledHands = samplingService.sampleOpponentHands(
            opponentIndices: seatContext.opponentIndices,
            unseenCards: unseenCards,
            cardsPerOpponent: sampleCardsPerOpponent,
            beliefState: beliefState,
            rng: &rng
        )
        var botHand = candidate.remainingHand

        let roundSnapshot = context.roundContext.roundState ?? context.tableContext.matchContext?.round
        var simulatedBids = normalizedRoundValues(
            values: roundSnapshot?.bids,
            fallback: 0,
            playerCount: seatContext.playerCount
        )
        simulatedBids[seatContext.botIndex] = context.roundContext.targetBid
        var simulatedTricks = normalizedRoundValues(
            values: roundSnapshot?.tricksTaken,
            fallback: 0,
            playerCount: seatContext.playerCount
        )
        simulatedTricks[seatContext.botIndex] = context.roundContext.currentTricks

        var botWins = 0
        var currentTrick = context.tableContext.trick.playedCards + [
            PlayedTrickCard(
                playerIndex: seatContext.botIndex,
                card: candidate.evaluation.move.card,
                jokerPlayStyle: candidate.evaluation.move.decision.style,
                jokerLeadDeclaration: candidate.evaluation.move.decision.leadDeclaration
            )
        ]

        for opponentIndex in seatContext.currentTrickRemainingOrder {
            guard opponentIndex != seatContext.botIndex else { continue }
            var opponentHand = sampledHands[opponentIndex] ?? []
            if let simulatedMove = simulationService.simulatedMove(
                playerIndex: opponentIndex,
                hand: &opponentHand,
                trick: currentTrick,
                trump: context.tableContext.trump,
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
            trump: context.tableContext.trump
        ) ?? seatContext.botIndex
        if leader == seatContext.botIndex {
            botWins += 1
        }
        if simulatedTricks.indices.contains(leader) {
            simulatedTricks[leader] += 1
        }

        guard rolloutHorizon > 1 else { return botWins }

        for _ in 1..<rolloutHorizon {
            var trick: [PlayedTrickCard] = []
            for offset in 0..<seatContext.playerCount {
                let currentPlayer = opponentOrderResolver.normalizedPlayerIndex(
                    leader + offset,
                    playerCount: seatContext.playerCount
                )
                if currentPlayer == seatContext.botIndex {
                    if let simulatedMove = simulationService.simulatedMove(
                        playerIndex: seatContext.botIndex,
                        hand: &botHand,
                        trick: trick,
                        trump: context.tableContext.trump,
                        bid: simulatedBids[seatContext.botIndex],
                        tricksTaken: simulatedTricks[seatContext.botIndex],
                        shouldPreferControl: true
                    ) {
                        trick.append(simulatedMove)
                    }
                    continue
                }

                var opponentHand = sampledHands[currentPlayer] ?? []
                if let simulatedMove = simulationService.simulatedMove(
                    playerIndex: currentPlayer,
                    hand: &opponentHand,
                    trick: trick,
                    trump: context.tableContext.trump,
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
                trump: context.tableContext.trump
            ) ?? leader
            if leader == seatContext.botIndex {
                botWins += 1
            }
            if simulatedTricks.indices.contains(leader) {
                simulatedTricks[leader] += 1
            }
        }

        return botWins
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
}
