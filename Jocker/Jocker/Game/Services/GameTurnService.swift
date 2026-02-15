//
//  GameTurnService.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

/// Сервис логики хода и определения победителя взятки.
final class GameTurnService {
    private let strategyService: BotTurnStrategyService

    init(strategyService: BotTurnStrategyService = BotTurnStrategyService()) {
        self.strategyService = strategyService
    }

    func automaticTurnDecision(
        from handCards: [Card],
        trickNode: TrickNode,
        trump: Suit?,
        bid: Int?,
        tricksTaken: Int?,
        cardsInRound: Int? = nil,
        playerCount: Int? = nil
    ) -> (card: Card, jokerDecision: JokerPlayDecision)? {
        return strategyService.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
            trump: trump,
            bid: bid,
            tricksTaken: tricksTaken,
            cardsInRound: cardsInRound,
            playerCount: playerCount
        )
    }

    func trickWinnerIndex(trickNode: TrickNode, playerCount: Int, trump: Suit?) -> Int? {
        guard trickNode.playedCards.count == playerCount else { return nil }

        return TrickTakingResolver.winnerPlayerIndex(
            playedCards: trickNode.playedCards,
            trump: trump
        )
    }
}
