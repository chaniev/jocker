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
        let targetBid = normalizedBid(
            bid: bid,
            handCards: handCards,
            cardsInRound: resolvedCardsInRound,
            trump: trump
        )
        let shouldChaseTrick = currentTricks < targetBid
        let opponentsRemaining = remainingOpponentsCount(
            playerCount: playerCount,
            cardsAlreadyOnTable: trickNode.playedCards.count
        )
        let unseen = unseenCards(
            excluding: handCards,
            and: trickNode.playedCards.map(\.card)
        )

        let hasWinningNonJoker = legalCards.contains { card in
            guard !card.isJoker else { return false }
            return winsTrickRightNow(
                with: card,
                decision: .defaultNonLead,
                trickNode: trickNode,
                trump: trump
            )
        }
        let hasLosingNonJoker = legalCards.contains { card in
            guard !card.isJoker else { return false }
            return !winsTrickRightNow(
                with: card,
                decision: .defaultNonLead,
                trickNode: trickNode,
                trump: trump
            )
        }

        var best: CandidateEvaluation?
        for card in legalCards {
            for decision in candidateDecisions(
                for: card,
                trickNode: trickNode,
                shouldChaseTrick: shouldChaseTrick
            ) {
                let move = CandidateMove(card: card, decision: decision)
                let immediateWinProbability = estimateImmediateWinProbability(
                    move: move,
                    trickNode: trickNode,
                    trump: trump,
                    unseenCards: unseen,
                    opponentsRemaining: opponentsRemaining,
                    handSizeBeforeMove: handCards.count
                )
                let projectedFinalTricks = projectedFinalTricks(
                    currentTricks: currentTricks,
                    immediateWinProbability: immediateWinProbability,
                    remainingHand: remainingHand(afterPlaying: card, from: handCards),
                    trump: trump,
                    cardsInRound: resolvedCardsInRound
                )
                let projectedScore = expectedRoundScore(
                    cardsInRound: resolvedCardsInRound,
                    bid: targetBid,
                    expectedTricks: projectedFinalTricks
                )
                let threat = cardThreat(
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
                    hasLosingNonJoker: hasLosingNonJoker
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
            ? candidateDecisions(
                for: fallbackCard,
                trickNode: trickNode,
                shouldChaseTrick: shouldChaseTrick
            ).first ?? .defaultNonLead
            : .defaultNonLead
        return (fallbackCard, fallbackDecision)
    }

    private func normalizedBid(
        bid: Int?,
        handCards: [Card],
        cardsInRound: Int,
        trump: Suit?
    ) -> Int {
        if let bid {
            return min(max(0, bid), cardsInRound)
        }

        let estimated = Int(estimateFutureTricks(in: handCards, trump: trump).rounded())
        return min(max(0, estimated), cardsInRound)
    }

    private func remainingOpponentsCount(
        playerCount: Int?,
        cardsAlreadyOnTable: Int
    ) -> Int {
        let totalPlayers = max(2, playerCount ?? 4)
        return max(0, totalPlayers - cardsAlreadyOnTable - 1)
    }

    private func candidateDecisions(
        for card: Card,
        trickNode: TrickNode,
        shouldChaseTrick: Bool
    ) -> [JokerPlayDecision] {
        guard card.isJoker else { return [.defaultNonLead] }

        let isLead = trickNode.playedCards.isEmpty
        if !isLead {
            if shouldChaseTrick {
                return [
                    JokerPlayDecision(style: .faceUp, leadDeclaration: nil),
                    JokerPlayDecision(style: .faceDown, leadDeclaration: nil)
                ]
            }
            return [
                JokerPlayDecision(style: .faceDown, leadDeclaration: nil),
                JokerPlayDecision(style: .faceUp, leadDeclaration: nil)
            ]
        }

        var decisions: [JokerPlayDecision] = [
            JokerPlayDecision(style: .faceUp, leadDeclaration: .wish)
        ]
        for suit in Suit.allCases {
            decisions.append(JokerPlayDecision(style: .faceUp, leadDeclaration: .above(suit: suit)))
            decisions.append(JokerPlayDecision(style: .faceUp, leadDeclaration: .takes(suit: suit)))
        }
        return decisions
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
        hasLosingNonJoker: Bool
    ) -> Double {
        let strategy = tuning.turnStrategy
        var utility = projectedScore
        let isLeadJoker = move.card.isJoker && trickNode.playedCards.isEmpty

        if shouldChaseTrick {
            utility += immediateWinProbability * strategy.chaseWinProbabilityWeight
            utility -= threat * strategy.chaseThreatPenaltyWeight

            if move.card.isJoker && hasWinningNonJoker {
                utility -= strategy.chaseSpendJokerPenalty
            }

            if isLeadJoker {
                if case .some(.wish) = move.decision.leadDeclaration {
                    utility += strategy.chaseLeadWishBonus
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

    private func estimateImmediateWinProbability(
        move: CandidateMove,
        trickNode: TrickNode,
        trump: Suit?,
        unseenCards: [Card],
        opponentsRemaining: Int,
        handSizeBeforeMove: Int
    ) -> Double {
        guard winsTrickRightNow(
            with: move.card,
            decision: move.decision,
            trickNode: trickNode,
            trump: trump
        ) else {
            return 0.0
        }

        if opponentsRemaining == 0 {
            return 1.0
        }

        guard !unseenCards.isEmpty else {
            return 1.0
        }

        let trickAfterMove = trickNode.playedCards + [
            PlayedTrickCard(
                playerIndex: -1,
                card: move.card,
                jokerPlayStyle: move.decision.style,
                jokerLeadDeclaration: move.decision.leadDeclaration
            )
        ]

        let beatersCount = unseenCards.reduce(0) { partial, card in
            let simulated = trickAfterMove + [
                PlayedTrickCard(
                    playerIndex: -2,
                    card: card,
                    jokerPlayStyle: .faceUp,
                    jokerLeadDeclaration: nil
                )
            ]

            let canBeat = TrickTakingResolver.winnerPlayerIndex(
                playedCards: simulated,
                trump: trump
            ) == -2

            return partial + (canBeat ? 1 : 0)
        }

        let beaterRatio = Double(beatersCount) / Double(unseenCards.count)
        let estimatedDraws = max(1, opponentsRemaining * max(1, handSizeBeforeMove))
        let holdFromDistribution = pow(max(0.0, 1.0 - beaterRatio), Double(estimatedDraws))

        let strategy = tuning.turnStrategy
        let powerConfidence = min(
            1.0,
            max(
                0.0,
                Double(cardPower(move.card, decision: move.decision, trickNode: trickNode, trump: trump)) /
                    max(1.0, strategy.powerNormalizationValue)
            )
        )

        return min(
            1.0,
            max(
                0.0,
                holdFromDistribution * strategy.holdFromDistributionWeight +
                    powerConfidence * strategy.powerConfidenceWeight
            )
        )
    }

    private func projectedFinalTricks(
        currentTricks: Int,
        immediateWinProbability: Double,
        remainingHand: [Card],
        trump: Suit?,
        cardsInRound: Int
    ) -> Double {
        let futureTricks = estimateFutureTricks(in: remainingHand, trump: trump)
        let projected = Double(currentTricks) + immediateWinProbability + futureTricks
        return min(Double(cardsInRound), max(0.0, projected))
    }

    private func estimateFutureTricks(in handCards: [Card], trump: Suit?) -> Double {
        guard !handCards.isEmpty else { return 0.0 }
        let strategy = tuning.turnStrategy

        let regularCards = handCards.compactMap { card -> (suit: Suit, rank: Rank)? in
            guard case .regular(let suit, let rank) = card else { return nil }
            return (suit, rank)
        }
        let suitCounts = Dictionary(grouping: regularCards, by: \.suit).mapValues(\.count)

        var totalPower = 0.0
        for card in handCards {
            if card.isJoker {
                totalPower += strategy.futureJokerPower
                continue
            }

            guard case .regular(let suit, let rank) = card else { continue }

            let rankSpan = Double(Rank.ace.rawValue - Rank.six.rawValue)
            let normalizedRank = Double(rank.rawValue - Rank.six.rawValue) / max(1.0, rankSpan)
            var cardPower = strategy.futureRegularBasePower + normalizedRank * strategy.futureRegularRankWeight

            if let trump, suit == trump {
                cardPower += strategy.futureTrumpBaseBonus + normalizedRank * strategy.futureTrumpRankWeight
            } else if rank.rawValue >= Rank.queen.rawValue {
                cardPower += strategy.futureHighRankBonus
            }

            let suitLength = suitCounts[suit] ?? 0
            if suitLength >= 3 {
                cardPower += strategy.futureLongSuitBonusPerCard * Double(suitLength - 2)
            }

            totalPower += cardPower
        }

        let expected = totalPower * strategy.futureTricksScale
        return min(Double(handCards.count), max(0.0, expected))
    }

    private func expectedRoundScore(
        cardsInRound: Int,
        bid: Int,
        expectedTricks: Double
    ) -> Double {
        let boundedExpected = min(Double(cardsInRound), max(0.0, expectedTricks))
        let floorValue = Int(floor(boundedExpected))
        let ceilValue = min(cardsInRound, floorValue + 1)

        if floorValue == ceilValue {
            return Double(
                ScoreCalculator.calculateRoundScore(
                    cardsInRound: cardsInRound,
                    bid: bid,
                    tricksTaken: floorValue,
                    isBlind: false
                )
            )
        }

        let lowerScore = Double(
            ScoreCalculator.calculateRoundScore(
                cardsInRound: cardsInRound,
                bid: bid,
                tricksTaken: floorValue,
                isBlind: false
            )
        )
        let upperScore = Double(
            ScoreCalculator.calculateRoundScore(
                cardsInRound: cardsInRound,
                bid: bid,
                tricksTaken: ceilValue,
                isBlind: false
            )
        )

        let upperWeight = boundedExpected - Double(floorValue)
        let lowerWeight = 1.0 - upperWeight
        return lowerScore * lowerWeight + upperScore * upperWeight
    }

    private func remainingHand(afterPlaying playedCard: Card, from handCards: [Card]) -> [Card] {
        var remaining = handCards
        if let index = remaining.firstIndex(of: playedCard) {
            remaining.remove(at: index)
        }
        return remaining
    }

    private func unseenCards(excluding handCards: [Card], and playedCards: [Card]) -> [Card] {
        var knownCounts: [Card: Int] = [:]
        for card in handCards + playedCards {
            knownCounts[card, default: 0] += 1
        }

        var unseen: [Card] = []
        for card in Deck().cards {
            let count = knownCounts[card, default: 0]
            if count > 0 {
                knownCounts[card] = count - 1
            } else {
                unseen.append(card)
            }
        }

        return unseen
    }

    private func cardThreat(
        card: Card,
        decision: JokerPlayDecision,
        trump: Suit?,
        trickNode: TrickNode
    ) -> Double {
        let strategy = tuning.turnStrategy
        if card.isJoker {
            if decision.style == .faceDown {
                return trickNode.playedCards.isEmpty
                    ? strategy.threatFaceDownLeadJoker
                    : strategy.threatFaceDownNonLeadJoker
            }

            if trickNode.playedCards.isEmpty {
                switch decision.leadDeclaration {
                case .takes:
                    return strategy.threatLeadTakesJoker
                case .above:
                    return strategy.threatLeadAboveJoker
                case .wish, .none:
                    return strategy.threatLeadWishJoker
                }
            }

            return strategy.threatNonLeadFaceUpJoker
        }

        guard case .regular(let suit, let rank) = card else { return 0.0 }
        var threat = Double(rank.rawValue)
        if let trump, suit == trump {
            threat += strategy.threatTrumpBonus
        }
        if rank.rawValue >= Rank.queen.rawValue {
            threat += strategy.threatHighRankBonus
        }
        return threat
    }

    private func winsTrickRightNow(
        with card: Card,
        decision: JokerPlayDecision,
        trickNode: TrickNode,
        trump: Suit?
    ) -> Bool {
        let simulatedTrick = trickNode.playedCards + [
            PlayedTrickCard(
                playerIndex: -1,
                card: card,
                jokerPlayStyle: decision.style,
                jokerLeadDeclaration: decision.leadDeclaration
            )
        ]

        return TrickTakingResolver.winnerPlayerIndex(
            playedCards: simulatedTrick,
            trump: trump
        ) == -1
    }

    private func cardPower(
        _ card: Card,
        decision: JokerPlayDecision,
        trickNode: TrickNode,
        trump: Suit?
    ) -> Int {
        let strategy = tuning.turnStrategy
        if card.isJoker {
            if decision.style == .faceDown {
                return strategy.powerFaceDownJoker
            }

            if trickNode.playedCards.isEmpty {
                switch decision.leadDeclaration {
                case .takes:
                    return strategy.powerLeadTakesJoker
                case .above:
                    return strategy.powerLeadAboveJoker
                case .wish, .none:
                    return strategy.powerLeadWishJoker
                }
            }

            return strategy.powerNonLeadFaceUpJoker
        }

        guard case .regular(let suit, let rank) = card else { return 0 }
        var value = rank.rawValue

        if let trump, suit == trump {
            value += strategy.powerTrumpBonus
        }
        if let leadSuit = effectiveLeadSuit(in: trickNode), suit == leadSuit {
            value += strategy.powerLeadSuitBonus
        }

        return value
    }

    private func effectiveLeadSuit(in trickNode: TrickNode) -> Suit? {
        guard let leadCard = trickNode.playedCards.first else { return nil }
        if let suit = leadCard.card.suit {
            return suit
        }

        switch leadCard.jokerLeadDeclaration {
        case .above(let suit), .takes(let suit):
            return suit
        case .wish, .none:
            return nil
        }
    }
}
