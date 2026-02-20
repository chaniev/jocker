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

    init(tuning: BotTuning = BotTuning(difficulty: .hard)) {
        self.tuning = tuning
    }

    func selectTrump(from hand: [Card]) -> Suit? {
        guard !hand.isEmpty else { return nil }
        let trumpTuning = tuning.trumpSelection

        var suitPower: [Suit: Double] = [:]
        var regularCardsCount = 0

        for card in hand {
            guard case .regular(let suit, let rank) = card else { continue }
            regularCardsCount += 1

            let normalizedRank = Double(rank.rawValue - Rank.six.rawValue) / 8.0
            let cardPower = trumpTuning.cardBasePower + normalizedRank
            suitPower[suit, default: 0.0] += cardPower
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
}
