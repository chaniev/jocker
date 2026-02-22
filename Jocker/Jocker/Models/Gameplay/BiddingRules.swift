//
//  BiddingRules.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import Foundation

/// Чистые правила порядка торгов и ограничений ставок.
enum BiddingRules {
    static func allowedBids(
        forPlayer playerIndex: Int,
        dealer: Int,
        cardsInRound: Int,
        bids: [Int],
        playerCount: Int
    ) -> [Int] {
        guard playerCount > 0 else { return [] }
        guard playerIndex >= 0 && playerIndex < playerCount else { return [] }

        let maxBid = max(0, cardsInRound)
        var allowed = Array(0...maxBid)

        guard playerCount > 1, playerIndex == dealer else {
            return allowed
        }

        let totalWithoutDealer = (0..<playerCount).reduce(0) { partial, index in
            guard index != dealer else { return partial }
            let rawBid = bids.indices.contains(index) ? bids[index] : 0
            let clampedBid = min(max(rawBid, 0), maxBid)
            return partial + clampedBid
        }

        let forbiddenBid = cardsInRound - totalWithoutDealer
        if let forbiddenIndex = allowed.firstIndex(of: forbiddenBid) {
            allowed.remove(at: forbiddenIndex)
        }

        return allowed
    }

    static func dealerForbiddenBid(
        forPlayer playerIndex: Int,
        dealer: Int,
        cardsInRound: Int,
        bids: [Int],
        playerCount: Int
    ) -> Int? {
        guard playerCount > 1, playerIndex == dealer else { return nil }

        let totalWithoutDealer = (0..<playerCount).reduce(0) { partial, index in
            guard index != dealer else { return partial }
            let rawBid = bids.indices.contains(index) ? bids[index] : 0
            return partial + min(max(rawBid, 0), max(0, cardsInRound))
        }

        let forbidden = cardsInRound - totalWithoutDealer
        guard forbidden >= 0 && forbidden <= cardsInRound else { return nil }
        return forbidden
    }

    static func canChooseBlindBid(
        forPlayer playerIndex: Int,
        dealer: Int,
        blindSelections: [Bool],
        playerCount: Int
    ) -> Bool {
        guard playerCount > 0 else { return false }
        guard playerIndex >= 0 && playerIndex < playerCount else { return false }

        if playerIndex != dealer {
            return true
        }

        for index in 0..<playerCount where index != dealer {
            guard blindSelections.indices.contains(index), blindSelections[index] else {
                return false
            }
        }

        return true
    }

    static func biddingOrder(dealer: Int, playerCount: Int) -> [Int] {
        guard playerCount > 0 else { return [] }
        let start = normalizedPlayerIndex(dealer + 1, playerCount: playerCount)
        return (0..<playerCount).map { offset in
            normalizedPlayerIndex(start + offset, playerCount: playerCount)
        }
    }

    static func normalizedPlayerIndex(
        _ rawIndex: Int,
        playerCount: Int
    ) -> Int {
        guard playerCount > 0 else { return 0 }
        let remainder = rawIndex % playerCount
        return remainder >= 0 ? remainder : remainder + playerCount
    }
}
