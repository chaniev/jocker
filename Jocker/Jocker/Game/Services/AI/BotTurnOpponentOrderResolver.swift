//
//  BotTurnOpponentOrderResolver.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

struct BotTurnOpponentOrderResolver {
    struct SimulationSeatContext {
        let playerCount: Int
        let botIndex: Int
        let opponentIndices: [Int]
        let currentTrickRemainingOrder: [Int]
    }

    func effectiveLeadSuit(
        from trick: BotTurnCardHeuristicsService.TrickSnapshot
    ) -> Suit? {
        effectiveLeadSuit(from: trick.playedCards)
    }

    func effectiveLeadSuit(from playedCards: [PlayedTrickCard]) -> Suit? {
        guard let lead = playedCards.first else { return nil }
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

    func remainingOpponentOrder(
        for tableContext: BotTurnCandidateEvaluatorService.DecisionContext.TableContext
    ) -> [Int]? {
        guard let playerCount = tableContext.playerCount, playerCount > 1 else { return nil }
        let cardsAlreadyOnTable = tableContext.trick.playedCards.count
        guard cardsAlreadyOnTable < playerCount else { return [] }

        let resolvedCurrentPlayer: Int
        if let actingPlayerIndex = tableContext.actingPlayerIndex {
            resolvedCurrentPlayer = normalizedPlayerIndex(
                actingPlayerIndex,
                playerCount: playerCount
            )
        } else if let leadPlayer = tableContext.trick.playedCards.first?.playerIndex {
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

    func rolloutRemainingOpponentOrder(
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

    func normalizedPlayerIndex(
        _ index: Int,
        playerCount: Int
    ) -> Int {
        guard playerCount > 0 else { return 0 }
        return ((index % playerCount) + playerCount) % playerCount
    }

    func simulationSeatContext(
        for context: BotTurnCandidateEvaluatorService.DecisionContext,
        remainingOpponentPlayerIndices: [Int]?
    ) -> SimulationSeatContext {
        let fallbackPlayerCount = max(2, context.tableContext.trick.playedCards.count + 1)
        let playerCount = max(
            fallbackPlayerCount,
            context.tableContext.playerCount ??
                context.tableContext.matchContext?.playerCount ??
                fallbackPlayerCount
        )
        let botIndex = normalizedPlayerIndex(
            context.tableContext.actingPlayerIndex ??
                context.tableContext.matchContext?.playerIndex ??
                0,
            playerCount: playerCount
        )
        let opponentIndices = (0..<playerCount).filter { $0 != botIndex }
        let currentTrickRemainingOrder = remainingOpponentPlayerIndices ??
            rolloutRemainingOpponentOrder(
                playedCardsCount: context.tableContext.trick.playedCards.count,
                playerCount: playerCount,
                actingPlayerIndex: botIndex
            )

        return SimulationSeatContext(
            playerCount: playerCount,
            botIndex: botIndex,
            opponentIndices: opponentIndices,
            currentTrickRemainingOrder: currentTrickRemainingOrder
        )
    }

    func makeOpponentIntentionModel(
        tableContext: BotTurnCandidateEvaluatorService.DecisionContext.TableContext,
        roundContext: BotTurnCandidateEvaluatorService.DecisionContext.RoundContext,
        beliefState: BotBeliefState?,
        remainingOpponentPlayerIndices: [Int]?
    ) -> BotTurnCandidateRankingService.OpponentIntentionModel? {
        guard let matchContext = tableContext.matchContext else { return nil }
        guard let opponents = matchContext.opponents else { return nil }
        guard !opponents.snapshots.isEmpty else { return nil }

        let roundState = roundContext.roundState ?? matchContext.round
        let leadSuit = effectiveLeadSuit(from: tableContext.trick)
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
}
