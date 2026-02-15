//
//  BotBiddingService.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

/// Сервис авто-заказа взяток для бота.
final class BotBiddingService {
    func makeBid(
        hand: [Card],
        cardsInRound: Int,
        trump: Suit?,
        forbiddenBid: Int?
    ) -> Int {
        let maxBid = max(0, cardsInRound)
        let expectedTricks = estimateExpectedTricks(
            in: hand,
            cardsInRound: maxBid,
            trump: trump
        )

        var bestBid = 0
        var bestProjectedScore = Int.min
        var bestDistance = Int.max

        for bid in 0...maxBid {
            if let forbiddenBid, bid == forbiddenBid {
                continue
            }

            let projectedScore = ScoreCalculator.calculateRoundScore(
                cardsInRound: maxBid,
                bid: bid,
                tricksTaken: expectedTricks,
                isBlind: false
            )
            let distance = abs(bid - expectedTricks)

            if projectedScore > bestProjectedScore ||
                (projectedScore == bestProjectedScore && distance < bestDistance) {
                bestProjectedScore = projectedScore
                bestDistance = distance
                bestBid = bid
            }
        }

        return bestBid
    }

    private func estimateExpectedTricks(
        in hand: [Card],
        cardsInRound: Int,
        trump: Suit?
    ) -> Int {
        guard cardsInRound > 0 else { return 0 }
        guard !hand.isEmpty else { return 0 }

        var power = 0.0

        for card in hand {
            if card.isJoker {
                power += 1.1
                continue
            }

            guard case .regular(let suit, let rank) = card else { continue }

            let normalizedRank = Double(rank.rawValue - 5) / 9.0
            var value = normalizedRank * 0.72

            if let trump, suit == trump {
                value += 0.55 + normalizedRank * 0.45
            } else if rank.rawValue >= Rank.queen.rawValue {
                value += 0.18
            }

            power += value
        }

        let rounded = Int(power.rounded())
        return max(0, min(cardsInRound, rounded))
    }
}
