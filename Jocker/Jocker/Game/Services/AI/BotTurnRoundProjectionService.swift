//
//  BotTurnRoundProjectionService.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import Foundation

/// Прогнозы по текущей раздаче для runtime-хода бота:
/// нормализация ставки, оценка будущих взяток и ожидаемого очкового исхода.
struct BotTurnRoundProjectionService {
    private let tuning: BotTuning
    private let handFeatureExtractor = HandFeatureExtractor()

    init(tuning: BotTuning) {
        self.tuning = tuning
    }

    func normalizedBid(
        bid: Int?,
        handCards: [Card],
        cardsInRound: Int,
        trump: Suit?
    ) -> Int {
        if let bid {
            return min(max(0, bid), cardsInRound)
        }

        let estimated = Int(estimateFutureTricks(in: handCards, trump: trump).rounded())
        return min(max(0, estimated), cardsInRound)
    }

    func remainingOpponentsCount(
        playerCount: Int?,
        cardsAlreadyOnTable: Int
    ) -> Int {
        let totalPlayers = max(2, playerCount ?? 4)
        return max(0, totalPlayers - cardsAlreadyOnTable - 1)
    }

    func projectedFinalTricks(
        currentTricks: Int,
        immediateWinProbability: Double,
        remainingHand: [Card],
        trump: Suit?,
        cardsInRound: Int
    ) -> Double {
        let futureTricks = estimateFutureTricks(in: remainingHand, trump: trump)
        let projected = Double(currentTricks) + immediateWinProbability + futureTricks
        return min(Double(cardsInRound), max(0.0, projected))
    }

    func expectedRoundScore(
        cardsInRound: Int,
        bid: Int,
        expectedTricks: Double,
        isBlind: Bool = false,
        matchContext: BotMatchContext? = nil
    ) -> Double {
        _ = matchContext // Этап 4a plumbing: контекст будет использоваться в premium-aware projection.
        let boundedExpected = min(Double(cardsInRound), max(0.0, expectedTricks))
        let floorValue = Int(floor(boundedExpected))
        let ceilValue = min(cardsInRound, floorValue + 1)

        if floorValue == ceilValue {
            return Double(
                ScoreCalculator.calculateRoundScore(
                    cardsInRound: cardsInRound,
                    bid: bid,
                    tricksTaken: floorValue,
                    isBlind: isBlind
                )
            )
        }

        let lowerScore = Double(
            ScoreCalculator.calculateRoundScore(
                cardsInRound: cardsInRound,
                bid: bid,
                tricksTaken: floorValue,
                isBlind: isBlind
            )
        )
        let upperScore = Double(
            ScoreCalculator.calculateRoundScore(
                cardsInRound: cardsInRound,
                bid: bid,
                tricksTaken: ceilValue,
                isBlind: isBlind
            )
        )

        let upperWeight = boundedExpected - Double(floorValue)
        let lowerWeight = 1.0 - upperWeight
        return lowerScore * lowerWeight + upperScore * upperWeight
    }

    func remainingHand(afterPlaying playedCard: Card, from handCards: [Card]) -> [Card] {
        var remaining = handCards
        if let index = remaining.firstIndex(of: playedCard) {
            remaining.remove(at: index)
        }
        return remaining
    }

    func estimateFutureTricks(in handCards: [Card], trump: Suit?) -> Double {
        guard !handCards.isEmpty else { return 0.0 }
        let strategy = tuning.turnStrategy
        let handFeatures = handFeatureExtractor.extract(from: handCards)
        let suitCounts = handFeatures.suitCounts

        var totalPower = 0.0
        for card in handCards {
            if card.isJoker {
                totalPower += strategy.futureJokerPower
                continue
            }

            guard case .regular(let suit, let rank) = card else { continue }

            let normalizedRank = BotRankNormalization.normalizedForFutureProjection(rank)
            var cardPower = strategy.futureRegularBasePower + normalizedRank * strategy.futureRegularRankWeight

            if let trump, suit == trump {
                cardPower += strategy.futureTrumpBaseBonus + normalizedRank * strategy.futureTrumpRankWeight
            } else if BotRankNormalization.isHighCard(rank) {
                cardPower += strategy.futureHighRankBonus
            }

            let suitLength = suitCounts[suit] ?? 0
            if suitLength >= 3 {
                cardPower += strategy.futureLongSuitBonusPerCard * Double(suitLength - 2)
            }

            totalPower += cardPower
        }

        let expected = totalPower * strategy.futureTricksScale
        return min(Double(handCards.count), max(0.0, expected))
    }
}
