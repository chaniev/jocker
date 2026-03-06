//
//  BotTurnStrategyServiceTestFixture.swift
//  JockerTests
//
//  Created by Codex on 06.03.2026.
//

@testable import Jocker

struct BotTurnStrategyServiceTestFixture {
    let tuning: BotTuning
    let service: BotTurnStrategyService

    init(difficulty: BotDifficulty = .hard) {
        let tuning = BotTuning(difficulty: difficulty)
        self.tuning = tuning
        self.service = BotTurnStrategyService(tuning: tuning)
    }

    func makeTurnDecision(
        handCards: [Card],
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
        return service.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
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
    }

    func makeTurnDecision(
        context: BotTurnStrategyService.BotTurnDecisionContext
    ) -> (card: Card, jokerDecision: JokerPlayDecision)? {
        return service.makeTurnDecision(context: context)
    }

    func makeTurnDecision(
        decisionContext builder: BotTurnDecisionContextBuilder
    ) -> (card: Card, jokerDecision: JokerPlayDecision)? {
        return service.makeTurnDecision(context: builder.buildStrategyContext())
    }
}
