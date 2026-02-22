//
//  HandFeatureExtractor.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import Foundation

/// Общий extractor признаков руки для bot AI (bidding/projection/trump).
/// Собирает разбор руки в одном месте без изменения формул отдельных сервисов.
struct HandFeatureExtractor {
    struct RegularCardInfo {
        let suit: Suit
        let rank: Rank
    }

    struct Features {
        let regularCards: [RegularCardInfo]
        let suitCounts: [Suit: Int]
        let jokerCount: Int
        let highCardCount: Int

        var regularCardsCount: Int {
            return regularCards.count
        }

        var longestSuitCount: Int {
            return suitCounts.values.max() ?? 0
        }
    }

    func extract(from hand: [Card]) -> Features {
        var regularCards: [RegularCardInfo] = []
        regularCards.reserveCapacity(hand.count)

        var suitCounts: [Suit: Int] = [:]
        var jokerCount = 0
        var highCardCount = 0

        for card in hand {
            guard case .regular(let suit, let rank) = card else {
                if card.isJoker {
                    jokerCount += 1
                }
                continue
            }

            regularCards.append(RegularCardInfo(suit: suit, rank: rank))
            suitCounts[suit, default: 0] += 1

            if BotRankNormalization.isHighCard(rank) {
                highCardCount += 1
            }
        }

        return Features(
            regularCards: regularCards,
            suitCounts: suitCounts,
            jokerCount: jokerCount,
            highCardCount: highCardCount
        )
    }
}
