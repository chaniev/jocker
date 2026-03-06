//
//  BotTurnBeliefStateBuilder.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

struct BotTurnBeliefStateBuilder {
    func build(
        tableContext: BotTurnCandidateEvaluatorService.DecisionContext.TableContext,
        roundContext: BotTurnCandidateEvaluatorService.DecisionContext.RoundContext
    ) -> BotBeliefState? {
        guard let playerCount = tableContext.playerCount, playerCount > 1 else {
            return nil
        }

        return BotBeliefState.infer(
            playerCount: playerCount,
            completedTricks: roundContext.completedTricksInRound,
            currentTrick: tableContext.trick.playedCards,
            trump: tableContext.trump
        )
    }
}
