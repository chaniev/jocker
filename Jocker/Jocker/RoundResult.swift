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
        )
    }
}
