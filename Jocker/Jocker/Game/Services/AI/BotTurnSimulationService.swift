//
//  BotTurnSimulationService.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

struct BotTurnSimulationService {
    private let policy: BotRuntimePolicy.Simulation
    private let opponentOrderResolver: BotTurnOpponentOrderResolver

    init(
        policy: BotRuntimePolicy.Simulation,
        opponentOrderResolver: BotTurnOpponentOrderResolver
    ) {
        self.policy = policy
        self.opponentOrderResolver = opponentOrderResolver
    }

    func simulatedMove(
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
                    simulatedCardPower(
                        $0,
                        trump: trump,
                        trick: trick,
                        preferControl: shouldPreferControl
                    ) < simulatedCardPower(
                        $1,
                        trump: trump,
                        trick: trick,
                        preferControl: shouldPreferControl
                    )
                } ?? winningCards[0]
            } else {
                selectedCard = legalCards.min {
                    simulatedCardPower(
                        $0,
                        trump: trump,
                        trick: trick,
                        preferControl: shouldPreferControl
                    ) < simulatedCardPower(
                        $1,
                        trump: trump,
                        trick: trick,
                        preferControl: shouldPreferControl
                    )
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
                    simulatedCardPower(
                        $0,
                        trump: trump,
                        trick: trick,
                        preferControl: shouldPreferControl
                    ) < simulatedCardPower(
                        $1,
                        trump: trump,
                        trick: trick,
                        preferControl: shouldPreferControl
                    )
                } ?? losingCards[0]
            } else {
                selectedCard = legalCards.min {
                    simulatedCardPower(
                        $0,
                        trump: trump,
                        trick: trick,
                        preferControl: shouldPreferControl
                    ) < simulatedCardPower(
                        $1,
                        trump: trump,
                        trick: trick,
                        preferControl: shouldPreferControl
                    )
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

    func simulatedLegalCards(
        for hand: [Card],
        trick: [PlayedTrickCard],
        trump: Suit?
    ) -> [Card] {
        guard !hand.isEmpty else { return [] }
        let trickSnapshot = BotTurnCardHeuristicsService.TrickSnapshot(playedCards: trick)
        let legalCards = hand.filter { card in
            trickSnapshot.canPlayCard(card, fromHand: hand, trump: trump)
        }
        return legalCards.isEmpty ? hand : legalCards
    }

    func simulatedJokerDecision(
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

    func simulatedWinsTrick(
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

    func simulatedCardPower(
        _ card: Card,
        trump: Suit?,
        trick: [PlayedTrickCard],
        preferControl: Bool
    ) -> Double {
        if card.isJoker {
            return preferControl ? policy.chaseJokerPower : policy.dumpJokerPower
        }

        guard case .regular(let suit, let rank) = card else { return 0.0 }
        var power = Double(rank.rawValue)
        if let trump, suit == trump {
            power += policy.trumpBonus
        }
        if let leadSuit = opponentOrderResolver.effectiveLeadSuit(from: trick), suit == leadSuit {
            power += policy.leadSuitBonus
        }
        if rank.rawValue >= policy.highRankThreshold.rawValue {
            power += policy.highRankBonus
        }
        return power
    }
}
