//
//  BlockResult.swift
//  Jocker
//
//  Created by Чаниев Мурад on 08.02.2026.
//

import Foundation

/// Результат одного блока игры
struct BlockResult {
    /// Результаты каждого раунда для каждого игрока: [playerIndex][roundIndex]
    let roundResults: [[RoundResult]]
    /// Очки каждого игрока за блок как сумма очков раздач (премия вшивается в последнюю раздачу).
    let baseScores: [Int]
    /// Индексы игроков, получивших премию
    let premiumPlayerIndices: [Int]
    /// Бонусы премий для каждого игрока (0 если нет премии)
    let premiumBonuses: [Int]
    /// Штрафы за премии других игроков (0 если нет штрафа)
    let premiumPenalties: [Int]
    /// Индексы игроков, получивших нулевую премию (500 очков за 0 взяток во всех раздачах блоков 1/3)
    let zeroPremiumPlayerIndices: [Int]
    /// Бонусы нулевой премии для каждого игрока (0 или 500)
    let zeroPremiumBonuses: [Int]
    /// Итоговые очки за блок: baseScores - premiumPenalties
    let finalScores: [Int]
}
