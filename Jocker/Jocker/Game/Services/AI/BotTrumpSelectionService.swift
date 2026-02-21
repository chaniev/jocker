//
//  BotTrumpSelectionService.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

/// Сервис выбора козыря ботом по открытым картам этапа выбора.
final class BotTrumpSelectionService {
    private let tuning: BotTuning
    private enum BonusPower {
        // Явный приоритет для блока выбора козыря (2/4):
        // если из 3 открытых карт 2 одной масти, усиливаем эту масть.
        static let twoOfThreeSameSuitInPlayerChoiceStage = 1.40
    }

    init(tuning: BotTuning = BotTuning(difficulty: .hard)) {
        self.tuning = tuning
    }

    func selectTrump(
        from hand: [Card],
        isPlayerChosenTrumpStage: Bool = false
    ) -> Suit? {
        guard !hand.isEmpty else { return nil }
        let trumpTuning = tuning.trumpSelection
        let pairBonusBySuit = twoOfThreeSameSuitBonus(
            in: hand,
            isPlayerChosenTrumpStage: isPlayerChosenTrumpStage
        )

        var suitPower: [Suit: Double] = [:]
        var regularCardsCount = 0

        for card in hand {
            guard case .regular(let suit, let rank) = card else { continue }
            regularCardsCount += 1

            let normalizedRank = Double(rank.rawValue - Rank.six.rawValue) / 8.0
            let cardPower = trumpTuning.cardBasePower + normalizedRank
            suitPower[suit, default: 0.0] += cardPower
        }

        for (suit, bonus) in pairBonusBySuit {
            suitPower[suit, default: 0.0] += bonus
        }

        guard regularCardsCount > 0 else { return nil }

        let sortedCandidates = suitPower
            .map { (suit: $0.key, power: $0.value) }
            .sorted { lhs, rhs in
                if lhs.power == rhs.power {
                    return lhs.suit < rhs.suit
                }
                return lhs.power > rhs.power
            }

        guard let best = sortedCandidates.first else { return nil }

        // Слабая/разрозненная рука: бот предпочитает играть без козыря.
        guard best.power >= trumpTuning.minimumPowerToDeclareTrump else { return nil }

        return best.suit
    }

    private func twoOfThreeSameSuitBonus(
        in hand: [Card],
        isPlayerChosenTrumpStage: Bool
    ) -> [Suit: Double] {
        guard isPlayerChosenTrumpStage else { return [:] }
        guard hand.count == 3 else { return [:] }

        let suits = hand.compactMap(\.suit)
        guard suits.count == 3 else { return [:] } // В сценарии учитываем только 3 обычные карты.

        let suitCounts = Dictionary(grouping: suits, by: { $0 }).mapValues(\.count)
        guard suitCounts.count == 2 else { return [:] } // Ровно 2+1, а не 3 одинаковых.

        guard let targetSuit = suitCounts.first(where: { $0.value == 2 })?.key else {
            return [:]
        }

        return [targetSuit: BonusPower.twoOfThreeSameSuitInPlayerChoiceStage]
    }
}
