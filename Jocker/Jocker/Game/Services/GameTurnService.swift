//
//  GameTurnService.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

/// Сервис логики хода и определения победителя взятки.
final class GameTurnService {
    func automaticCard(
        from handCards: [Card],
        trickNode: TrickNode,
        trump: Suit?,
        bid: Int?,
        tricksTaken: Int?
    ) -> Card? {
        guard !handCards.isEmpty else { return nil }

        let legalCards = handCards.filter { candidate in
            trickNode.canPlayCard(candidate, fromHand: handCards, trump: trump)
        }
        guard !legalCards.isEmpty else { return handCards[0] }

        let shouldChaseTrick: Bool
        if let bid, let tricksTaken {
            shouldChaseTrick = tricksTaken < bid
        } else {
            shouldChaseTrick = true
        }

        if shouldChaseTrick {
            let currentlyWinningCards = legalCards.filter { candidate in
                isCurrentlyWinning(
                    candidate,
                    on: trickNode,
                    trump: trump
                )
            }

            if !currentlyWinningCards.isEmpty {
                return currentlyWinningCards.min(by: { lhs, rhs in
                    cardPower(lhs, trickNode: trickNode, trump: trump) < cardPower(rhs, trickNode: trickNode, trump: trump)
                })
            }

            return legalCards.max(by: { lhs, rhs in
                cardPower(lhs, trickNode: trickNode, trump: trump) < cardPower(rhs, trickNode: trickNode, trump: trump)
            })
        }

        return legalCards.min(by: { lhs, rhs in
            cardPower(lhs, trickNode: trickNode, trump: trump) < cardPower(rhs, trickNode: trickNode, trump: trump)
        })
    }

    func trickWinnerIndex(trickNode: TrickNode, playerCount: Int, trump: Suit?) -> Int? {
        guard trickNode.playedCards.count == playerCount else { return nil }

        return TrickTakingResolver.winnerPlayerIndex(
            playedCards: trickNode.playedCards,
            trump: trump
        )
    }

    private func isCurrentlyWinning(_ card: Card, on trickNode: TrickNode, trump: Suit?) -> Bool {
        let declaration: JokerLeadDeclaration?
        if card.isJoker && trickNode.playedCards.isEmpty {
            declaration = .wish
        } else {
            declaration = nil
        }

        let simulatedTrick = trickNode.playedCards + [
            PlayedTrickCard(
                playerIndex: -1,
                card: card,
                jokerPlayStyle: .faceUp,
                jokerLeadDeclaration: declaration
            )
        ]

        return TrickTakingResolver.winnerPlayerIndex(
            playedCards: simulatedTrick,
            trump: trump
        ) == -1
    }

    private func cardPower(_ card: Card, trickNode: TrickNode, trump: Suit?) -> Int {
        if card.isJoker {
            return 1000
        }

        guard case .regular(let suit, let rank) = card else {
            return 0
        }

        var value = rank.rawValue

        if let trump, suit == trump {
            value += 100
        }

        if let leadSuit = effectiveLeadSuit(in: trickNode), suit == leadSuit {
            value += 40
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
