//
//  RoundResult.swift
//  Jocker
//
//  Created by Чаниев Мурад on 08.02.2026.
//

import Foundation

/// Результат одного раунда (раздачи) для одного игрока
struct RoundResult {
    /// C — количество розданных карт каждому игроку
    let cardsInRound: Int
    /// V — количество объявленных взяток
    let bid: Int
    /// K — количество взятых взяток
    let tricksTaken: Int
    /// Была ли ставка сделана «в тёмную» (до раздачи карт)
    let isBlind: Bool
    /// Дополнительная корректировка очков раунда (например, вшитая премия).
    let scoreAdjustment: Int
    
    /// Совпала ли ставка с результатом
    var bidMatched: Bool {
        return tricksTaken == bid
    }
    
    /// Очки за этот раунд (с учётом «тёмной» ставки)
    var score: Int {
        return ScoreCalculator.calculateRoundScore(
            cardsInRound: cardsInRound,
            bid: bid,
            tricksTaken: tricksTaken,
            isBlind: isBlind
        ) + scoreAdjustment
    }

    init(
        cardsInRound: Int,
        bid: Int,
        tricksTaken: Int,
        isBlind: Bool,
        scoreAdjustment: Int = 0
    ) {
        self.cardsInRound = cardsInRound
        self.bid = bid
        self.tricksTaken = tricksTaken
        self.isBlind = isBlind
        self.scoreAdjustment = scoreAdjustment
    }

    func addingScoreAdjustment(_ delta: Int) -> RoundResult {
        return RoundResult(
            cardsInRound: cardsInRound,
            bid: bid,
            tricksTaken: tricksTaken,
            isBlind: isBlind,
            scoreAdjustment: scoreAdjustment + delta
        )
    }
}
