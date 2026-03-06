//
//  BotTurnEndgameSolver.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

struct BotTurnEndgameSolver {
    private let policy: BotRuntimePolicy.Endgame
    private let samplingService: BotTurnSamplingService
    private let simulationService: BotTurnSimulationService
    private let opponentOrderResolver: BotTurnOpponentOrderResolver

    init(
        policy: BotRuntimePolicy.Endgame,
        samplingService: BotTurnSamplingService,
        simulationService: BotTurnSimulationService,
        opponentOrderResolver: BotTurnOpponentOrderResolver
    ) {
        self.policy = policy
        self.samplingService = samplingService
        self.simulationService = simulationService
        self.opponentOrderResolver = opponentOrderResolver
    }

    func shouldApplySolver(
        context: BotTurnCandidateEvaluatorService.DecisionContext,
        scoredCandidates: [BotTurnCandidateEvaluatorService.CandidateScore]
    ) -> Bool {
        guard context.handContext.handCards.count <= policy.solverHandSizeThreshold else { return false }
        guard scoredCandidates.count >= policy.minimumCandidateCount else { return false }
        if let premium = context.tableContext.matchContext?.premium {
            let antiPremiumPressure = premium.leftNeighborIsPremiumCandidateSoFar ||
                premium.opponentPremiumCandidatesSoFarCount > 0 ||
                premium.isPenaltyTargetRiskSoFar
            if antiPremiumPressure {
                let tricksNeeded = max(0, context.roundContext.targetBid - context.roundContext.currentTricks)
                let allInChase = tricksNeeded >= max(1, context.handContext.handCards.count - 1)
                if !allInChase {
                    return false
                }
            }
        }
        return true
    }

    func applyAdjustments(
        to scoredCandidates: [BotTurnCandidateEvaluatorService.CandidateScore],
        context: BotTurnCandidateEvaluatorService.DecisionContext,
        shouldChaseTrick: Bool,
        beliefState: BotBeliefState?,
        unseenCards: [Card],
        remainingOpponentPlayerIndices: [Int]?,
        urgencyWeight: Double
    ) -> [BotTurnCandidateRankingService.Evaluation] {
        guard !scoredCandidates.isEmpty else { return [] }

        let iterations = min(
            policy.maximumIterations,
            max(
                policy.minimumIterations,
                unseenCards.isEmpty
                    ? policy.minimumIterations
                    : unseenCards.count / max(1, policy.unseenCardsIterationsDivisor)
            )
        )
        let endgameWeight = policy.weightBase + policy.weightUrgencyMultiplier * urgencyWeight

        return scoredCandidates.map { candidate in
            var expectedEndgameScore = 0.0
            for iteration in 0..<iterations {
                var rng = samplingService.makeEndgameRNG(
                    candidate: candidate,
                    context: context,
                    iteration: iteration
                )
                expectedEndgameScore += Double(
                    simulateEndgameRoundScore(
                        candidate: candidate,
                        context: context,
                        beliefState: beliefState,
                        unseenCards: unseenCards,
                        remainingOpponentPlayerIndices: remainingOpponentPlayerIndices,
                        shouldChaseTrick: shouldChaseTrick,
                        rng: &rng
                    )
                )
            }
            expectedEndgameScore /= Double(max(1, iterations))

            let scoreDelta = expectedEndgameScore - candidate.projectedScore
            let endgameAdjustment = max(
                -policy.adjustmentCap,
                min(policy.adjustmentCap, scoreDelta * endgameWeight)
            )

            return BotTurnCandidateRankingService.Evaluation(
                move: candidate.evaluation.move,
                utility: candidate.baselineUtility + endgameAdjustment,
                immediateWinProbability: candidate.evaluation.immediateWinProbability,
                threat: candidate.evaluation.threat
            )
        }
    }

    private func simulateEndgameRoundScore(
        candidate: BotTurnCandidateEvaluatorService.CandidateScore,
        context: BotTurnCandidateEvaluatorService.DecisionContext,
        beliefState: BotBeliefState?,
        unseenCards: [Card],
        remainingOpponentPlayerIndices: [Int]?,
        shouldChaseTrick: Bool,
        rng: inout BotTurnSamplingService.DeterministicRNG
    ) -> Int {
        let seatContext = opponentOrderResolver.simulationSeatContext(
            for: context,
            remainingOpponentPlayerIndices: remainingOpponentPlayerIndices
        )

        var opponentCardRequirements: [Int: Int] = [:]
        let cardsAfterCurrentMove = max(0, candidate.remainingHand.count)
        for opponentIndex in seatContext.opponentIndices {
            let playsInCurrentTrick = seatContext.currentTrickRemainingOrder.contains(opponentIndex)
            opponentCardRequirements[opponentIndex] =
                cardsAfterCurrentMove + (playsInCurrentTrick ? 1 : 0)
        }
        var sampledHands = samplingService.sampleOpponentHandsWithRequirements(
            opponentCardRequirements: opponentCardRequirements,
            unseenCards: unseenCards,
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
        if simulatedTricks.indices.contains(leader) {
            simulatedTricks[leader] += 1
        }

        while !botHand.isEmpty {
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
                        shouldPreferControl: shouldChaseTrick
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
            if simulatedTricks.indices.contains(leader) {
                simulatedTricks[leader] += 1
            }
        }

        let finalTricks = simulatedTricks.indices.contains(seatContext.botIndex)
            ? simulatedTricks[seatContext.botIndex]
            : context.roundContext.currentTricks
        return ScoreCalculator.calculateRoundScore(
            cardsInRound: context.roundContext.cardsInRound,
            bid: context.roundContext.targetBid,
            tricksTaken: finalTricks,
            isBlind: context.roundContext.isBlind
        )
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
