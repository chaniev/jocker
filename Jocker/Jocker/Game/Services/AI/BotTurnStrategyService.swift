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

    private struct CandidateMove {
        let card: Card
        let decision: JokerPlayDecision
    }

    private struct CandidateEvaluation {
        let move: CandidateMove
        let utility: Double
        let immediateWinProbability: Double
        let threat: Double
    }

    init(tuning: BotTuning = BotTuning(difficulty: .hard)) {
        self.tuning = tuning
        self.cardHeuristics = BotTurnCardHeuristicsService(tuning: tuning)
        self.roundProjection = BotTurnRoundProjectionService(tuning: tuning)
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
        let tricksNeededToMatchBid = max(0, targetBid - currentTricks)
        let tricksRemainingIncludingCurrent = max(1, handCards.count)
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
            playerCount: playerCount,
            cardsAlreadyOnTable: trickNode.playedCards.count
        )
        let unseen = cardHeuristics.unseenCards(
            excluding: handCards,
            and: trickNode.playedCards.map(\.card)
        )

        let hasWinningNonJoker = legalCards.contains { card in
            guard !card.isJoker else { return false }
            return cardHeuristics.winsTrickRightNow(
                with: card,
                decision: .defaultNonLead,
                trickNode: trickNode,
                trump: trump
            )
        }
        let hasLosingNonJoker = legalCards.contains { card in
            guard !card.isJoker else { return false }
            return !cardHeuristics.winsTrickRightNow(
                with: card,
                decision: .defaultNonLead,
                trickNode: trickNode,
                trump: trump
            )
        }

        var best: CandidateEvaluation?
        for card in legalCards {
            for decision in cardHeuristics.candidateDecisions(
                for: card,
                trickNode: trickNode,
                shouldChaseTrick: shouldChaseTrick
            ) {
                let move = CandidateMove(card: card, decision: decision)
                let immediateWinProbability = cardHeuristics.estimateImmediateWinProbability(
                    card: move.card,
                    decision: move.decision,
                    trickNode: trickNode,
                    trump: trump,
                    unseenCards: unseen,
                    opponentsRemaining: opponentsRemaining,
                    handSizeBeforeMove: handCards.count
                )
                let projectedFinalTricks = roundProjection.projectedFinalTricks(
                    currentTricks: currentTricks,
                    immediateWinProbability: immediateWinProbability,
                    remainingHand: roundProjection.remainingHand(afterPlaying: card, from: handCards),
                    trump: trump,
                    cardsInRound: resolvedCardsInRound
                )
                let projectedScore = roundProjection.expectedRoundScore(
                    cardsInRound: resolvedCardsInRound,
                    bid: targetBid,
                    expectedTricks: projectedFinalTricks
                )
                let threat = cardHeuristics.cardThreat(
                    card: card,
                    decision: decision,
                    trump: trump,
                    trickNode: trickNode
                )
                let utility = moveUtility(
                    projectedScore: projectedScore,
                    immediateWinProbability: immediateWinProbability,
                    threat: threat,
                    move: move,
                    trickNode: trickNode,
                    trump: trump,
                    shouldChaseTrick: shouldChaseTrick,
                    hasWinningNonJoker: hasWinningNonJoker,
                    hasLosingNonJoker: hasLosingNonJoker,
                    tricksNeededToMatchBid: tricksNeededToMatchBid,
                    tricksRemainingIncludingCurrent: tricksRemainingIncludingCurrent,
                    chasePressure: chasePressure
                )

                let evaluation = CandidateEvaluation(
                    move: move,
                    utility: utility,
                    immediateWinProbability: immediateWinProbability,
                    threat: threat
                )

                if let currentBest = best {
                    if isBetterCandidate(evaluation, than: currentBest, shouldChaseTrick: shouldChaseTrick) {
                        best = evaluation
                    }
                } else {
                    best = evaluation
                }
            }
        }

        if let best {
            return (best.move.card, best.move.decision)
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

    private func isBetterCandidate(
        _ candidate: CandidateEvaluation,
        than current: CandidateEvaluation,
        shouldChaseTrick: Bool
    ) -> Bool {
        let tolerance = tuning.turnStrategy.utilityTieTolerance

        if candidate.utility > current.utility + tolerance {
            return true
        }
        if current.utility > candidate.utility + tolerance {
            return false
        }

        if shouldChaseTrick {
            if candidate.immediateWinProbability > current.immediateWinProbability + tolerance {
                return true
            }
            if current.immediateWinProbability > candidate.immediateWinProbability + tolerance {
                return false
            }
            if candidate.threat < current.threat - tolerance {
                return true
            }
            if current.threat < candidate.threat - tolerance {
                return false
            }
        } else {
            if candidate.immediateWinProbability < current.immediateWinProbability - tolerance {
                return true
            }
            if current.immediateWinProbability < candidate.immediateWinProbability - tolerance {
                return false
            }
            if candidate.threat > current.threat + tolerance {
                return true
            }
            if current.threat > candidate.threat + tolerance {
                return false
            }
        }

        // Детерминизм выбора при полном равенстве.
        if candidate.move.card != current.move.card {
            return candidate.move.card < current.move.card
        }
        return candidate.move.decision.style == .faceDown && current.move.decision.style == .faceUp
    }

    private func moveUtility(
        projectedScore: Double,
        immediateWinProbability: Double,
        threat: Double,
        move: CandidateMove,
        trickNode: TrickNode,
        trump: Suit?,
        shouldChaseTrick: Bool,
        hasWinningNonJoker: Bool,
        hasLosingNonJoker: Bool,
        tricksNeededToMatchBid: Int,
        tricksRemainingIncludingCurrent: Int,
        chasePressure: Double
    ) -> Double {
        let strategy = tuning.turnStrategy
        var utility = projectedScore
        let isLeadJoker = move.card.isJoker && trickNode.playedCards.isEmpty
        let isNonFinalLeadWishJoker: Bool
        if isLeadJoker,
           move.decision.style == .faceUp,
           tricksRemainingIncludingCurrent > 1,
           case .some(.wish) = move.decision.leadDeclaration {
            isNonFinalLeadWishJoker = true
        } else {
            isNonFinalLeadWishJoker = false
        }

        if isNonFinalLeadWishJoker {
            // "wish" без заказа масти в ранних взятках ограничивает контроль стола.
            // В self-play и боевой логике смещаем выбор к "above"/"takes".
            let tricksAfterCurrent = max(1, tricksRemainingIncludingCurrent - 1)
            let basePenalty = 24.0 + Double(tricksAfterCurrent) * 6.0
            let chaseMultiplier = shouldChaseTrick ? (1.0 + chasePressure * 0.25) : 1.0
            utility -= basePenalty * chaseMultiplier
        }

        if shouldChaseTrick {
            let conservatism = max(0.0, 1.0 - chasePressure)
            utility += immediateWinProbability * strategy.chaseWinProbabilityWeight * (1.0 + chasePressure)
            utility -= threat * strategy.chaseThreatPenaltyWeight * conservatism

            if move.card.isJoker && hasWinningNonJoker {
                utility -= strategy.chaseSpendJokerPenalty * conservatism
            }

            if tricksNeededToMatchBid >= tricksRemainingIncludingCurrent {
                utility -= (1.0 - immediateWinProbability) * strategy.chaseSpendJokerPenalty
            }

            if isLeadJoker {
                if case .some(.wish) = move.decision.leadDeclaration {
                    utility += strategy.chaseLeadWishBonus * (0.5 + chasePressure * 0.5)
                }
            }
        } else {
            utility += (1.0 - immediateWinProbability) * strategy.dumpAvoidWinWeight
            utility += threat * strategy.dumpThreatRewardWeight

            if move.card.isJoker && hasLosingNonJoker {
                utility -= strategy.dumpSpendJokerPenalty
            }
            if move.card.isJoker && move.decision.style == .faceUp && !trickNode.playedCards.isEmpty {
                utility -= strategy.dumpFaceUpNonLeadJokerPenalty
            }

            if isLeadJoker, case .some(.takes(let suit)) = move.decision.leadDeclaration {
                if let trump, suit != trump {
                    utility += strategy.dumpLeadTakesNonTrumpBonus
                }
            }
        }

        return utility
    }

}

