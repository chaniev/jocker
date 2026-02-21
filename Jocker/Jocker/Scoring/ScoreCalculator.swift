//
//  ScoreCalculator.swift
//  Jocker
//
//  Created by Чаниев Мурад on 08.02.2026.
//

import Foundation

/// Калькулятор очков — чистые статические функции для расчёта очков
///
/// Используется как namespace (caseless enum) — экземпляры не создаются
enum ScoreCalculator {
    
    // MARK: - Расчёт очков за раунд
    
    /// Рассчитать очки за один раунд
    ///
    /// Правила:
    /// - K = V и V ≠ C → K×50 + 50
    /// - K = V и V = C → K×100
    /// - K > V → K×10
    /// - K < V → -(V-K)×50 - 50
    /// - K = 0 и V = C → -V×100
    /// - Если ставка «в тёмную», очки удваиваются
    ///
    /// - Parameters:
    ///   - cardsInRound: C — количество розданных карт
    ///   - bid: V — объявленные взятки
    ///   - tricksTaken: K — взятые взятки
    ///   - isBlind: ставка сделана «в тёмную»
    /// - Returns: количество очков за раунд
    static func calculateRoundScore(cardsInRound: Int, bid: Int, tricksTaken: Int, isBlind: Bool) -> Int {
        let baseScore: Int
        
        if tricksTaken == bid {
            if bid == cardsInRound {
                // K = V = C → K×100
                baseScore = bid * 100
            } else {
                // K = V, V ≠ C → K×50 + 50
                baseScore = bid * 50 + 50
            }
        } else if tricksTaken > bid {
            // K > V → K×10
            baseScore = tricksTaken * 10
        } else {
            // tricksTaken < bid
            if bid == cardsInRound && tricksTaken == 0 {
                // K = 0 и V = C → -V×100
                baseScore = -bid * 100
            } else {
                // K < V → -(V-K)×50 - 50
                let deficit = bid - tricksTaken
                baseScore = -(deficit * 50 + 50)
            }
        }
        
        // Если ставка «в тёмную», очки удваиваются
        return isBlind ? baseScore * 2 : baseScore
    }
    
    // MARK: - Расчёт премии
    
    /// Рассчитать премиальный бонус для игрока
    ///
    /// К очкам внутри блока добавляется максимальное значение очков,
    /// полученных игроком с первой раздачи до предпоследней включительно.
    /// Если раунд был заказан «в тёмную», в премию попадает уже удвоенный
    /// очковый результат этого раунда.
    ///
    /// - Parameter roundScores: очки за каждый раунд блока
    /// - Returns: бонус премии
    static func calculatePremiumBonus(roundScores: [Int]) -> Int {
        guard roundScores.count >= 2 else { return 0 }
        let scoresExcludingLast = Array(roundScores.dropLast())
        return scoresExcludingLast.max() ?? 0
    }
    
    // MARK: - Нулевая премия
    
    /// Количество очков за нулевую премию
    static let zeroPremiumAmount: Int = 500
    
    /// Проверить, заслужил ли игрок нулевую премию
    ///
    /// Игрок получает нулевую премию в блоках 1 и 3, если во всех раздачах
    /// заказывал 0 взяток и взял 0 взяток
    ///
    /// - Parameter roundResults: результаты раундов игрока в блоке
    /// - Returns: true если игрок заслужил нулевую премию
    static func isZeroPremiumEligible(roundResults: [RoundResult]) -> Bool {
        guard !roundResults.isEmpty else { return false }
        return roundResults.allSatisfy { $0.bid == 0 && $0.tricksTaken == 0 }
    }
    
    /// Рассчитать штраф за премию другого игрока
    ///
    /// С игрока сидящего слева снимается максимальное положительное
    /// количество очков, набранных им внутри блока за исключением последней раздачи
    ///
    /// - Parameter roundScores: очки за каждый раунд блока (игрока-соседа)
    /// - Returns: штраф (неотрицательное число)
    static func calculatePremiumPenalty(roundScores: [Int]) -> Int {
        return selectPremiumPenaltyRound(roundScores: roundScores).penalty
    }

    /// Выбрать штрафную раздачу за премию другого игрока
    ///
    /// Берётся максимальное положительное значение очков среди раздач блока
    /// кроме последней. Если таких раздач несколько — выбирается самая ранняя.
    ///
    /// - Parameter roundScores: очки за каждый раунд блока (игрока-соседа)
    /// - Returns: размер штрафа и индекс выбранной раздачи внутри блока
    static func selectPremiumPenaltyRound(roundScores: [Int]) -> (penalty: Int, roundIndex: Int?) {
        guard roundScores.count >= 2 else { return (0, nil) }

        let scoresExcludingLast = Array(roundScores.dropLast())
        var maxPositive = 0
        var selectedRoundIndex: Int?

        for (roundIndex, score) in scoresExcludingLast.enumerated() where score > 0 {
            if score > maxPositive {
                maxPositive = score
                selectedRoundIndex = roundIndex
            }
        }

        return (maxPositive, selectedRoundIndex)
    }
}
