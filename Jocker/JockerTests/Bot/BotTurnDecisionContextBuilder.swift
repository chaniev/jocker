//
//  BotTurnDecisionContextBuilder.swift
//  JockerTests
//
//  Created by Codex on 06.03.2026.
//

@testable import Jocker

struct BotTurnDecisionContextBuilder {
    var handCards: [Card]
    var legalCards: [Card]?
    var trickNode: TrickNode
    var trump: Suit?
    var bid: Int?
    var tricksTaken: Int?
    var cardsInRound: Int?
    var playerCount: Int?
    var isBlind: Bool
    var matchContext: BotMatchContext?
    var roundState: BotMatchContext.RoundSnapshot?
    var actingPlayerIndex: Int?
    var completedTricksInRound: [[PlayedTrickCard]]
    var targetBid: Int?
    var currentTricks: Int?

    init(
        handCards: [Card],
        legalCards: [Card]? = nil,
        trickNode: TrickNode = BotTrickNodeBuilder.make(),
        trump: Suit? = nil,
        bid: Int? = 0,
        tricksTaken: Int? = 0,
        cardsInRound: Int? = nil,
        playerCount: Int? = 4,
        isBlind: Bool = false,
        matchContext: BotMatchContext? = nil,
        roundState: BotMatchContext.RoundSnapshot? = nil,
        actingPlayerIndex: Int? = nil,
        completedTricksInRound: [[PlayedTrickCard]] = [],
        targetBid: Int? = nil,
        currentTricks: Int? = nil
    ) {
        self.handCards = handCards
        self.legalCards = legalCards
        self.trickNode = trickNode
        self.trump = trump
        self.bid = bid
        self.tricksTaken = tricksTaken
        self.cardsInRound = cardsInRound
        self.playerCount = playerCount
        self.isBlind = isBlind
        self.matchContext = matchContext
        self.roundState = roundState
        self.actingPlayerIndex = actingPlayerIndex
        self.completedTricksInRound = completedTricksInRound
        self.targetBid = targetBid
        self.currentTricks = currentTricks
    }

    func buildStrategyContext() -> BotTurnStrategyService.BotTurnDecisionContext {
        return BotTurnStrategyService.BotTurnDecisionContext(
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

    func buildEvaluatorContext() -> BotTurnCandidateEvaluatorService.DecisionContext {
        return BotTurnCandidateEvaluatorService.DecisionContext(
            legalCards: legalCards ?? handCards,
            handCards: handCards,
            trick: .init(trickNode: trickNode),
            trump: trump,
            targetBid: targetBid ?? bid ?? 0,
            currentTricks: currentTricks ?? tricksTaken ?? 0,
            cardsInRound: max(1, cardsInRound ?? handCards.count),
            playerCount: playerCount,
            isBlind: isBlind,
            matchContext: matchContext,
            roundState: roundState,
            actingPlayerIndex: actingPlayerIndex,
            completedTricksInRound: completedTricksInRound
        )
    }
}
