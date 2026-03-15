//
//  GameTurnService.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

/// Сервис логики хода и определения победителя взятки.
final class GameTurnService {
    typealias BotTurnDecisionContext = BotTurnStrategyService.BotTurnDecisionContext

    private let strategyService: BotTurnStrategyService

    init(strategyService: BotTurnStrategyService = BotTurnStrategyService()) {
        self.strategyService = strategyService
    }

    convenience init(tuning: BotTuning) {
        self.init(strategyService: BotTurnStrategyService(tuning: tuning))
    }

    func automaticTurnDecision(
        context: BotTurnDecisionContext
    ) -> (card: Card, jokerDecision: JokerPlayDecision)? {
        return strategyService.makeTurnDecision(context: context)
    }

    func automaticTurnDecision(
        from handCards: [Card],
        trickNode: TrickNode,
        trump: Suit?,
        bid: Int?,
        tricksTaken: Int?,
        cardsInRound: Int? = nil,
        playerCount: Int? = nil,
        isBlind: Bool = false,
        matchContext: BotMatchContext? = nil,
        roundState: BotMatchContext.RoundSnapshot? = nil,
        actingPlayerIndex: Int? = nil,
        completedTricksInRound: [[PlayedTrickCard]] = []
    ) -> (card: Card, jokerDecision: JokerPlayDecision)? {
        return automaticTurnDecision(
            context: .init(
                handCards: handCards,
                trick: .init(trickNode: trickNode),
                trump: trump,
                bid: bid,
                tricksTaken: tricksTaken,
                cardsInRound: cardsInRound,
                playerCount: playerCount,
                isBlind: isBlind,
                matchContext: matchContext,
                roundState: roundState,
                actingPlayerIndex: actingPlayerIndex,
                completedTricksInRound: completedTricksInRound
            )
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
