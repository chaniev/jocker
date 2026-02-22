//
//  BotTurnCardHeuristicsService.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import Foundation

/// Низкоуровневые эвристики runtime-хода бота:
/// генерация joker-вариантов, оценка угрозы карты и вероятности мгновенного взятия.
struct BotTurnCardHeuristicsService {
    struct TrickSnapshot {
        let playedCards: [PlayedTrickCard]

        init(playedCards: [PlayedTrickCard]) {
            self.playedCards = playedCards
        }

        init(trickNode: TrickNode) {
            self.playedCards = trickNode.playedCards
        }
    }

    private let tuning: BotTuning

    init(tuning: BotTuning) {
        self.tuning = tuning
    }

    func candidateDecisions(
        for card: Card,
        trick: TrickSnapshot,
        shouldChaseTrick: Bool
    ) -> [JokerPlayDecision] {
        guard card.isJoker else { return [.defaultNonLead] }

        let isLead = trick.playedCards.isEmpty
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

    func candidateDecisions(
        for card: Card,
        trickNode: TrickNode,
        shouldChaseTrick: Bool
    ) -> [JokerPlayDecision] {
        return candidateDecisions(
            for: card,
            trick: TrickSnapshot(trickNode: trickNode),
            shouldChaseTrick: shouldChaseTrick
        )
    }

    func unseenCards(excluding handCards: [Card], and playedCards: [Card]) -> [Card] {
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

    func cardThreat(
        card: Card,
        decision: JokerPlayDecision,
        trump: Suit?,
        trick: TrickSnapshot,
        cardsRemainingInHandBeforeMove: Int? = nil,
        cardsInRound: Int? = nil
    ) -> Double {
        let strategy = tuning.turnStrategy
        let phaseMultiplier = threatPhaseMultiplier(
            for: card,
            trump: trump,
            cardsRemainingInHandBeforeMove: cardsRemainingInHandBeforeMove,
            cardsInRound: cardsInRound
        )
        if card.isJoker {
            if decision.style == .faceDown {
                let baseThreat = trick.playedCards.isEmpty
                    ? strategy.threatFaceDownLeadJoker
                    : strategy.threatFaceDownNonLeadJoker
                return baseThreat * phaseMultiplier
            }

            if trick.playedCards.isEmpty {
                let baseThreat: Double
                switch decision.leadDeclaration {
                case .takes:
                    baseThreat = strategy.threatLeadTakesJoker
                case .above:
                    baseThreat = strategy.threatLeadAboveJoker
                case .wish, .none:
                    baseThreat = strategy.threatLeadWishJoker
                }
                return baseThreat * phaseMultiplier
            }

            return strategy.threatNonLeadFaceUpJoker * phaseMultiplier
        }

        guard case .regular(let suit, let rank) = card else { return 0.0 }
        var threat = Double(rank.rawValue)
        if let trump, suit == trump {
            threat += strategy.threatTrumpBonus
        }
        if rank.rawValue >= Rank.queen.rawValue {
            threat += strategy.threatHighRankBonus
        }
        return threat * phaseMultiplier
    }

    func cardThreat(
        card: Card,
        decision: JokerPlayDecision,
        trump: Suit?,
        trickNode: TrickNode,
        cardsRemainingInHandBeforeMove: Int? = nil,
        cardsInRound: Int? = nil
    ) -> Double {
        return cardThreat(
            card: card,
            decision: decision,
            trump: trump,
            trick: TrickSnapshot(trickNode: trickNode),
            cardsRemainingInHandBeforeMove: cardsRemainingInHandBeforeMove,
            cardsInRound: cardsInRound
        )
    }

    func winsTrickRightNow(
        with card: Card,
        decision: JokerPlayDecision,
        trick: TrickSnapshot,
        trump: Suit?
    ) -> Bool {
        let simulatedTrick = trick.playedCards + [
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

    func winsTrickRightNow(
        with card: Card,
        decision: JokerPlayDecision,
        trickNode: TrickNode,
        trump: Suit?
    ) -> Bool {
        return winsTrickRightNow(
            with: card,
            decision: decision,
            trick: TrickSnapshot(trickNode: trickNode),
            trump: trump
        )
    }

    func estimateImmediateWinProbability(
        card: Card,
        decision: JokerPlayDecision,
        trick: TrickSnapshot,
        trump: Suit?,
        unseenCards: [Card],
        opponentsRemaining: Int,
        handSizeBeforeMove: Int
    ) -> Double {
        guard winsTrickRightNow(
            with: card,
            decision: decision,
            trick: trick,
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

        let trickAfterMove = trick.playedCards + [
            PlayedTrickCard(
                playerIndex: -1,
                card: card,
                jokerPlayStyle: decision.style,
                jokerLeadDeclaration: decision.leadDeclaration
            )
        ]

        let beatersCount = unseenCards.reduce(0) { partial, candidateCard in
            let simulated = trickAfterMove + [
                PlayedTrickCard(
                    playerIndex: -2,
                    card: candidateCard,
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
                Double(cardPower(card, decision: decision, trick: trick, trump: trump)) /
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

    func estimateImmediateWinProbability(
        card: Card,
        decision: JokerPlayDecision,
        trickNode: TrickNode,
        trump: Suit?,
        unseenCards: [Card],
        opponentsRemaining: Int,
        handSizeBeforeMove: Int
    ) -> Double {
        return estimateImmediateWinProbability(
            card: card,
            decision: decision,
            trick: TrickSnapshot(trickNode: trickNode),
            trump: trump,
            unseenCards: unseenCards,
            opponentsRemaining: opponentsRemaining,
            handSizeBeforeMove: handSizeBeforeMove
        )
    }

    private func cardPower(
        _ card: Card,
        decision: JokerPlayDecision,
        trick: TrickSnapshot,
        trump: Suit?
    ) -> Int {
        let strategy = tuning.turnStrategy
        if card.isJoker {
            if decision.style == .faceDown {
                return strategy.powerFaceDownJoker
            }

            if trick.playedCards.isEmpty {
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
        if let leadSuit = effectiveLeadSuit(in: trick), suit == leadSuit {
            value += strategy.powerLeadSuitBonus
        }

        return value
    }

    private func effectiveLeadSuit(in trick: TrickSnapshot) -> Suit? {
        guard let leadCard = trick.playedCards.first else { return nil }
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

    private func threatPhaseMultiplier(
        for card: Card,
        trump: Suit?,
        cardsRemainingInHandBeforeMove: Int?,
        cardsInRound: Int?
    ) -> Double {
        guard let cardsInRound,
              cardsInRound > 1,
              let cardsRemainingInHandBeforeMove else {
            return 1.0
        }

        let clampedCardsInRound = max(1, cardsInRound)
        let clampedHandSize = min(max(1, cardsRemainingInHandBeforeMove), clampedCardsInRound)
        let completedTricks = max(0, clampedCardsInRound - clampedHandSize)
        let phaseProgress = Double(completedTricks) / Double(max(1, clampedCardsInRound - 1))

        let resourceWeight: Double
        if card.isJoker {
            resourceWeight = 1.0
        } else if let suit = card.suit, suit == trump {
            resourceWeight = 0.8
        } else if let rank = card.rank, rank.rawValue >= Rank.queen.rawValue {
            resourceWeight = 0.65
        } else if let rank = card.rank, rank.rawValue >= Rank.jack.rawValue {
            resourceWeight = 0.35
        } else {
            resourceWeight = 0.15
        }

        // Early in the hand, preserve high-value resources longer.
        let earlyPreservationBonus = 0.28 * resourceWeight
        // Late in the hand, convert resources into result instead of over-preserving.
        let lateConversionDiscount = 0.38 * resourceWeight

        var multiplier = 1.0 +
            (1.0 - phaseProgress) * earlyPreservationBonus -
            phaseProgress * lateConversionDiscount

        if clampedHandSize == 1 {
            multiplier -= 0.05 * resourceWeight
        }

        return min(1.35, max(0.55, multiplier))
    }
}
