//
//  BotSelfPlayEvolutionEngine+SimulationBlindBidding.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

extension BotSelfPlayEvolutionEngine {
    struct BiddingRoundOutcome {
        let bids: [Int]
        let maxAllowedBids: [Int]
    }

    static func resolvePreDealBlindContext(
        dealer: Int,
        cardsInRound: Int,
        playerCount: Int,
        biddingServices: [BotBiddingService],
        totalScoresIncludingCurrentBlock: [Int]
    ) -> PreDealBlindContext {
        var lockedBids = Array(repeating: 0, count: playerCount)
        var blindSelections = Array(repeating: false, count: playerCount)
        var eligibleWhenBehind = Array(repeating: false, count: playerCount)
        var chosenWhenBehind = Array(repeating: false, count: playerCount)
        var eligibleWhenLeading = Array(repeating: false, count: playerCount)
        var chosenWhenLeading = Array(repeating: false, count: playerCount)
        let maxScore = totalScoresIncludingCurrentBlock.max() ?? 0

        for playerIndex in biddingOrder(dealer: dealer, playerCount: playerCount) {
            guard canChooseBlindBid(
                forPlayer: playerIndex,
                dealer: dealer,
                blindSelections: blindSelections
            ) else {
                continue
            }

            let allowedBlindBids = allowedBids(
                forPlayer: playerIndex,
                dealer: dealer,
                cardsInRound: cardsInRound,
                bids: lockedBids,
                playerCount: playerCount
            )
            guard !allowedBlindBids.isEmpty else { continue }

            let playerScore = totalScoresIncludingCurrentBlock.indices.contains(playerIndex)
                ? totalScoresIncludingCurrentBlock[playerIndex]
                : 0
            let isLeading = playerScore == maxScore
            let isBehind = playerScore < maxScore
            if isLeading {
                eligibleWhenLeading[playerIndex] = true
            } else if isBehind {
                eligibleWhenBehind[playerIndex] = true
            }

            let blindBid = biddingServices[playerIndex].makePreDealBlindBid(
                playerIndex: playerIndex,
                dealerIndex: dealer,
                cardsInRound: cardsInRound,
                allowedBlindBids: allowedBlindBids,
                canChooseBlind: true,
                totalScores: totalScoresIncludingCurrentBlock
            )

            guard let blindBid else { continue }
            let resolvedBlindBid = allowedBlindBids.contains(blindBid)
                ? blindBid
                : (allowedBlindBids.first ?? 0)
            blindSelections[playerIndex] = true
            lockedBids[playerIndex] = resolvedBlindBid
            if isLeading {
                chosenWhenLeading[playerIndex] = true
            } else if isBehind {
                chosenWhenBehind[playerIndex] = true
            }
        }

        return PreDealBlindContext(
            lockedBids: lockedBids,
            blindSelections: blindSelections,
            eligibleWhenBehind: eligibleWhenBehind,
            chosenWhenBehind: chosenWhenBehind,
            eligibleWhenLeading: eligibleWhenLeading,
            chosenWhenLeading: chosenWhenLeading
        )
    }

    static func makeBids(
        hands: [[Card]],
        dealer: Int,
        cardsInRound: Int,
        trump: Suit?,
        biddingServices: [BotBiddingService],
        preLockedBids: [Int]? = nil,
        blindSelections: [Bool]? = nil
    ) -> BiddingRoundOutcome {
        let playerCount = hands.count
        let firstBidder = normalizedPlayerIndex(dealer + 1, playerCount: playerCount)

        let resolvedLockedBids: [Int]
        if let preLockedBids, preLockedBids.count == playerCount {
            resolvedLockedBids = preLockedBids
        } else {
            resolvedLockedBids = Array(repeating: 0, count: playerCount)
        }

        let resolvedBlindSelections: [Bool]
        if let blindSelections, blindSelections.count == playerCount {
            resolvedBlindSelections = blindSelections
        } else {
            resolvedBlindSelections = Array(repeating: false, count: playerCount)
        }

        var bids = resolvedLockedBids
        var maxAllowedBids = Array(repeating: 0, count: playerCount)

        for step in 0..<playerCount {
            let player = normalizedPlayerIndex(firstBidder + step, playerCount: playerCount)
            let allowed = allowedBids(
                forPlayer: player,
                dealer: dealer,
                cardsInRound: cardsInRound,
                bids: bids,
                playerCount: playerCount
            )
            maxAllowedBids[player] = allowed.max() ?? 0

            if resolvedBlindSelections[player] {
                continue
            }

            let fallbackBid = allowed.first ?? 0
            let forbiddenBid = dealerForbiddenBid(
                forPlayer: player,
                dealer: dealer,
                cardsInRound: cardsInRound,
                bids: bids,
                playerCount: playerCount
            )

            let candidateBid = biddingServices[player].makeBid(
                hand: hands[player],
                cardsInRound: cardsInRound,
                trump: trump,
                forbiddenBid: forbiddenBid
            )

            bids[player] = allowed.contains(candidateBid)
                ? candidateBid
                : fallbackBid
        }

        return BiddingRoundOutcome(
            bids: bids,
            maxAllowedBids: maxAllowedBids
        )
    }

    static func allowedBids(
        forPlayer playerIndex: Int,
        dealer: Int,
        cardsInRound: Int,
        bids: [Int],
        playerCount: Int
    ) -> [Int] {
        return BiddingRules.allowedBids(
            forPlayer: playerIndex,
            dealer: dealer,
            cardsInRound: cardsInRound,
            bids: bids,
            playerCount: playerCount
        )
    }

    static func dealerForbiddenBid(
        forPlayer playerIndex: Int,
        dealer: Int,
        cardsInRound: Int,
        bids: [Int],
        playerCount: Int
    ) -> Int? {
        return BiddingRules.dealerForbiddenBid(
            forPlayer: playerIndex,
            dealer: dealer,
            cardsInRound: cardsInRound,
            bids: bids,
            playerCount: playerCount
        )
    }

    static func canChooseBlindBid(
        forPlayer playerIndex: Int,
        dealer: Int,
        blindSelections: [Bool]
    ) -> Bool {
        return BiddingRules.canChooseBlindBid(
            forPlayer: playerIndex,
            dealer: dealer,
            blindSelections: blindSelections,
            playerCount: blindSelections.count
        )
    }

    static func biddingOrder(dealer: Int, playerCount: Int) -> [Int] {
        return BiddingRules.biddingOrder(
            dealer: dealer,
            playerCount: playerCount
        )
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
