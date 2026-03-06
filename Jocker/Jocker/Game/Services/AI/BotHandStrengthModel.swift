//
//  BotHandStrengthModel.swift
//  Jocker
//
//  Created by Codex on 05.03.2026.
//

import Foundation

/// Единая pure-модель силы руки для bidding/projection/trump-selection.
/// Объединяет вычисления в одном месте, сохраняя mode-aware параметры.
struct BotHandStrengthModel {
    struct SuitProfile: Equatable {
        let suit: Suit
        let count: Int
        let density: Double
        let basePower: Double
        let normalizedRankSum: Double
        let topRankStrength: Double
        let sequenceStrength: Double
        let controlPotential: Double
    }

    struct TrumpHandSummary: Equatable {
        let suitProfiles: [Suit: SuitProfile]
        let jokerCount: Int
        let regularCardsCount: Int
    }

    private enum EvaluationMode {
        case bidding
        case projection
        case trumpSelection
    }

    private struct EvaluationSnapshot {
        let totalPower: Double
        let features: HandFeatureExtractor.Features
        let suitPower: [Suit: Double]
        let suitRanks: [Suit: [Rank]]
    }

    private let tuning: BotTuning
    private let handFeatureExtractor = HandFeatureExtractor()

    init(tuning: BotTuning) {
        self.tuning = tuning
    }

    func biddingExpectedTricks(
        hand: [Card],
        cardsInRound: Int,
        trump: Suit?
    ) -> Int {
        guard cardsInRound > 0 else { return 0 }
        guard !hand.isEmpty else { return 0 }

        let snapshot = evaluate(
            hand: hand,
            trump: trump,
            mode: .bidding
        )
        let rounded = Int(snapshot.totalPower.rounded())
        return max(0, min(cardsInRound, rounded))
    }

    func projectedFutureTricks(
        hand: [Card],
        trump: Suit?
    ) -> Double {
        guard !hand.isEmpty else { return 0.0 }

        let snapshot = evaluate(
            hand: hand,
            trump: trump,
            mode: .projection
        )
        let expected = snapshot.totalPower * tuning.turnStrategy.futureTricksScale
        return min(Double(hand.count), max(0.0, expected))
    }

    func trumpHandSummary(hand: [Card]) -> TrumpHandSummary {
        guard !hand.isEmpty else {
            return TrumpHandSummary(
                suitProfiles: [:],
                jokerCount: 0,
                regularCardsCount: 0
            )
        }

        let snapshot = evaluate(
            hand: hand,
            trump: nil,
            mode: .trumpSelection
        )
        let regularCardsCount = snapshot.features.regularCardsCount
        guard regularCardsCount > 0 else {
            return TrumpHandSummary(
                suitProfiles: [:],
                jokerCount: snapshot.features.jokerCount,
                regularCardsCount: 0
            )
        }

        let handStrengthPolicy = tuning.runtimePolicy.handStrength
        var profiles: [Suit: SuitProfile] = [:]
        for suit in Suit.allCases {
            let count = snapshot.features.suitCounts[suit] ?? 0
            guard count > 0 else { continue }
            let ranks = snapshot.suitRanks[suit] ?? []
            let normalizedRankSum = ranks.reduce(0.0) { partial, rank in
                partial + BotRankNormalization.normalizedForTrumpSelection(rank)
            }
            let topRankStrength = ranks.map(BotRankNormalization.normalizedForTrumpSelection).max() ?? 0.0
            let sequenceStrength = sequenceStrength(for: ranks)
            let controlPotential = min(
                1.0,
                max(
                    0.0,
                    topRankStrength * handStrengthPolicy.trumpSelectionControlTopRankWeight +
                        sequenceStrength * handStrengthPolicy.trumpSelectionControlSequenceWeight
                )
            )
            profiles[suit] = SuitProfile(
                suit: suit,
                count: count,
                density: Double(count) / Double(max(1, regularCardsCount)),
                basePower: snapshot.suitPower[suit] ?? 0.0,
                normalizedRankSum: normalizedRankSum,
                topRankStrength: topRankStrength,
                sequenceStrength: sequenceStrength,
                controlPotential: controlPotential
            )
        }

        return TrumpHandSummary(
            suitProfiles: profiles,
            jokerCount: snapshot.features.jokerCount,
            regularCardsCount: regularCardsCount
        )
    }

    private func evaluate(
        hand: [Card],
        trump: Suit?,
        mode: EvaluationMode
    ) -> EvaluationSnapshot {
        let features = handFeatureExtractor.extract(from: hand)
        let suitCounts = features.suitCounts

        var totalPower = 0.0
        var suitPower: [Suit: Double] = [:]
        var suitRanks: [Suit: [Rank]] = [:]

        for card in features.regularCards {
            let cardPower = regularCardPower(
                suit: card.suit,
                rank: card.rank,
                trump: trump,
                mode: mode
            )
            totalPower += cardPower
            suitPower[card.suit, default: 0.0] += cardPower
            suitRanks[card.suit, default: []].append(card.rank)
        }

        switch mode {
        case .bidding:
            totalPower += biddingContextBonus(
                features: features,
                cardsInRound: max(1, hand.count),
                trump: trump
            )
        case .projection:
            totalPower += projectionContextBonus(
                suitCounts: suitCounts
            )
            totalPower += Double(features.jokerCount) * tuning.turnStrategy.futureJokerPower
        case .trumpSelection:
            break
        }

        return EvaluationSnapshot(
            totalPower: totalPower,
            features: features,
            suitPower: suitPower,
            suitRanks: suitRanks
        )
    }

    private func regularCardPower(
        suit: Suit,
        rank: Rank,
        trump: Suit?,
        mode: EvaluationMode
    ) -> Double {
        switch mode {
        case .bidding:
            let bidding = tuning.bidding
            let normalized = BotRankNormalization.normalizedForBidding(rank)
            var value = normalized * bidding.expectedRankWeight

            if let trump, suit == trump {
                value += bidding.expectedTrumpBaseBonus + normalized * bidding.expectedTrumpRankWeight
            } else if BotRankNormalization.isHighCard(rank) {
                value += bidding.expectedHighRankBonus
            }
            return value

        case .projection:
            let strategy = tuning.turnStrategy
            let normalized = BotRankNormalization.normalizedForFutureProjection(rank)
            var value = strategy.futureRegularBasePower + normalized * strategy.futureRegularRankWeight

            if let trump, suit == trump {
                value += strategy.futureTrumpBaseBonus + normalized * strategy.futureTrumpRankWeight
            } else if BotRankNormalization.isHighCard(rank) {
                value += strategy.futureHighRankBonus
            }
            return value

        case .trumpSelection:
            let normalized = BotRankNormalization.normalizedForTrumpSelection(rank)
            return tuning.trumpSelection.cardBasePower + normalized
        }
    }

    private func biddingContextBonus(
        features: HandFeatureExtractor.Features,
        cardsInRound: Int,
        trump: Suit?
    ) -> Double {
        let bidding = tuning.bidding
        let longestSuit = features.longestSuitCount
        var bonus = Double(features.jokerCount) * bidding.expectedJokerPower

        if longestSuit >= 3 {
            bonus += Double(longestSuit - 2) * bidding.expectedLongSuitBonusPerCard
        }

        if let trump {
            let trumpCount = features.suitCounts[trump] ?? 0
            let trumpDensity = Double(trumpCount) / Double(max(1, cardsInRound))
            bonus += Double(trumpCount) * trumpDensity * bidding.expectedTrumpDensityBonus
        } else {
            bonus += Double(features.highCardCount) * bidding.expectedNoTrumpHighCardBonus
            if features.jokerCount > 0 {
                let handStrengthPolicy = tuning.runtimePolicy.handStrength
                let controlSupport =
                    Double(features.highCardCount) * handStrengthPolicy.noTrumpJokerSupportHighCardWeight +
                    Double(max(0, longestSuit - 2)) * handStrengthPolicy.noTrumpJokerSupportLongSuitWeight
                bonus += Double(features.jokerCount) * controlSupport * bidding.expectedNoTrumpJokerSynergy
            }
        }

        return bonus
    }

    private func projectionContextBonus(
        suitCounts: [Suit: Int]
    ) -> Double {
        let strategy = tuning.turnStrategy
        var bonus = 0.0
        for count in suitCounts.values where count >= 3 {
            // В projection-режиме это эквивалентно per-card бонусу в legacy формуле:
            // каждая карта масти получала +longSuitBonus*(count - 2).
            bonus += Double(count * (count - 2)) * strategy.futureLongSuitBonusPerCard
        }
        return bonus
    }

    private func sequenceStrength(for ranks: [Rank]) -> Double {
        guard !ranks.isEmpty else { return 0.0 }
        let handStrengthPolicy = tuning.runtimePolicy.handStrength
        let uniqueValues = Array(Set(ranks.map(\.rawValue))).sorted(by: >)
        guard !uniqueValues.isEmpty else { return 0.0 }

        var longestRun = 1
        var currentRun = 1
        for index in 1..<uniqueValues.count {
            if uniqueValues[index - 1] - uniqueValues[index] == 1 {
                currentRun += 1
                longestRun = max(longestRun, currentRun)
            } else {
                currentRun = 1
            }
        }

        return min(
            1.0,
            max(
                0.0,
                Double(max(0, longestRun - 1)) / handStrengthPolicy.sequenceStrengthNormalizationDivisor
            )
        )
    }
}
