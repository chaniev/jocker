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
    private let tuning: BotTuning

    init(tuning: BotTuning) {
        self.tuning = tuning
    }

    func candidateDecisions(
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

    func winsTrickRightNow(
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

    func estimateImmediateWinProbability(
        card: Card,
        decision: JokerPlayDecision,
        trickNode: TrickNode,
        trump: Suit?,
        unseenCards: [Card],
        opponentsRemaining: Int,
        handSizeBeforeMove: Int
    ) -> Double {
        guard winsTrickRightNow(
            with: card,
            decision: decision,
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
                Double(cardPower(card, decision: decision, trickNode: trickNode, trump: trump)) /
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
