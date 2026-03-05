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
    private let handStrengthModel: BotHandStrengthModel

    init(tuning: BotTuning) {
        self.handStrengthModel = BotHandStrengthModel(tuning: tuning)
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
        return handStrengthModel.projectedFutureTricks(
            hand: handCards,
            trump: trump
        )
    }
}
