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
    private let handFeatureExtractor = HandFeatureExtractor()
    private let handStrengthModel: BotHandStrengthModel

    init(tuning: BotTuning = BotTuning(difficulty: .hard)) {
        self.tuning = tuning
        self.handStrengthModel = BotHandStrengthModel(tuning: tuning)
    }

    func selectTrump(
        from hand: [Card],
        isPlayerChosenTrumpStage: Bool = false
    ) -> Suit? {
        guard !hand.isEmpty else { return nil }
        let trumpTuning = tuning.trumpSelection
        let handFeatures = handFeatureExtractor.extract(from: hand)
        let handSummary = handStrengthModel.trumpHandSummary(hand: hand)
        let pairBonusBySuit = twoOfThreeSameSuitBonus(
            in: hand,
            isPlayerChosenTrumpStage: isPlayerChosenTrumpStage
        )

        var suitPower: [Suit: Double] = [:]
        let regularCardsCount = handFeatures.regularCardsCount
        let jokerCount = handSummary.jokerCount

        for (suit, profile) in handSummary.suitProfiles {
            // Low-card short suits should not clear declaration threshold
            // without explicit stage bonus or high-card support.
            let qualityMultiplier = max(0.0, profile.topRankStrength)
            let lengthBonus = profile.count >= 2
                ? Double(profile.count - 1) * trumpTuning.lengthBonusPerExtraCard
                : 0.0
            let densityBonus = profile.density * Double(profile.count) * trumpTuning.densityBonusWeight
            let sequenceBonus = profile.sequenceStrength * trumpTuning.sequenceBonusWeight
            let controlBonus = profile.controlPotential * trumpTuning.controlBonusWeight
            let jokerSynergyBonus = Double(jokerCount) *
                (
                    trumpTuning.jokerSynergyBase +
                        profile.controlPotential * trumpTuning.jokerSynergyControlWeight
                ) *
                qualityMultiplier

            suitPower[suit, default: 0.0] +=
                profile.basePower +
                lengthBonus * qualityMultiplier +
                densityBonus * qualityMultiplier +
                sequenceBonus * qualityMultiplier +
                controlBonus * qualityMultiplier +
                jokerSynergyBonus
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
        let handFeatures = handFeatureExtractor.extract(from: hand)
        guard handFeatures.regularCardsCount == 3 else { return [:] } // В сценарии учитываем только 3 обычные карты.

        let suitCounts = handFeatures.suitCounts
        guard suitCounts.count == 2 else { return [:] } // Ровно 2+1, а не 3 одинаковых.

        guard let targetSuit = suitCounts.first(where: { $0.value == 2 })?.key else {
            return [:]
        }

        return [targetSuit: tuning.trumpSelection.playerChosenPairBonus]
    }
}
