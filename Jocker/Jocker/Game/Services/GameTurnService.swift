//
//  GameTurnService.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

/// Сервис логики хода и определения победителя взятки.
final class GameTurnService {
    func automaticCard(from handCards: [Card], trickNode: TrickNode, trump: Suit?) -> Card? {
        guard !handCards.isEmpty else { return nil }

        return handCards.first(where: { candidate in
            trickNode.canPlayCard(candidate, fromHand: handCards, trump: trump)
        }) ?? handCards[0]
    }

    func trickWinnerIndex(trickNode: TrickNode, playerCount: Int, trump: Suit?) -> Int? {
        guard trickNode.playedCards.count == playerCount else { return nil }

        return TrickTakingResolver.winnerPlayerIndex(
            playedCards: trickNode.playedCards,
            trump: trump
        )
    }
}
