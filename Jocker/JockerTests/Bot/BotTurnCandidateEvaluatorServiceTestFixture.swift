//
//  BotTurnCandidateEvaluatorServiceTestFixture.swift
//  JockerTests
//
//  Created by Codex on 06.03.2026.
//

@testable import Jocker

struct BotTurnCandidateEvaluatorServiceTestFixture {
    let tuning: BotTuning
    let evaluator: BotTurnCandidateEvaluatorService

    init(difficulty: BotDifficulty = .hard) {
        self.init(tuning: BotTuning(difficulty: difficulty))
    }

    init(tuning: BotTuning) {
        let cardHeuristics = BotTurnCardHeuristicsService(tuning: tuning)
        let roundProjection = BotTurnRoundProjectionService(tuning: tuning)
        let candidateRanking = BotTurnCandidateRankingService(tuning: tuning)

        self.tuning = tuning
        self.evaluator = BotTurnCandidateEvaluatorService(
            runtimePolicy: tuning.runtimePolicy,
            cardHeuristics: cardHeuristics,
            roundProjection: roundProjection,
            candidateRanking: candidateRanking
        )
    }

    func bestMove(
        legalCards: [Card],
        handCards: [Card],
        trickNode: TrickNode,
        trump: Suit?,
        targetBid: Int,
        currentTricks: Int,
        cardsInRound: Int,
        playerCount: Int?,
        isBlind: Bool = false,
        matchContext: BotMatchContext? = nil,
        roundState: BotMatchContext.RoundSnapshot? = nil,
        actingPlayerIndex: Int? = nil,
        completedTricksInRound: [[PlayedTrickCard]] = []
    ) -> (card: Card, jokerDecision: JokerPlayDecision)? {
        return evaluator.bestMove(
            legalCards: legalCards,
            handCards: handCards,
            trickNode: trickNode,
            trump: trump,
            targetBid: targetBid,
            currentTricks: currentTricks,
            cardsInRound: cardsInRound,
            playerCount: playerCount,
            isBlind: isBlind,
            matchContext: matchContext,
            roundState: roundState,
            actingPlayerIndex: actingPlayerIndex,
            completedTricksInRound: completedTricksInRound
        )
    }

    func bestMove(
        context: BotTurnCandidateEvaluatorService.DecisionContext
    ) -> (card: Card, jokerDecision: JokerPlayDecision)? {
        return evaluator.bestMove(context: context)
    }

    func bestMove(
        decisionContext builder: BotTurnDecisionContextBuilder
    ) -> (card: Card, jokerDecision: JokerPlayDecision)? {
        return evaluator.bestMove(context: builder.buildEvaluatorContext())
    }
}
