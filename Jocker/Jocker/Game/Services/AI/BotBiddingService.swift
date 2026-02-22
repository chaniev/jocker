//
//  BotBiddingService.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

/// Сервис авто-заказа взяток для бота.
final class BotBiddingService {
    private let tuning: BotTuning
    private let handFeatureExtractor = HandFeatureExtractor()

    init(tuning: BotTuning = BotTuning(difficulty: .hard)) {
        self.tuning = tuning
    }

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

    /// Решение бота о ставке «в тёмную» до раздачи.
    ///
    /// - Returns: значение blind-ставки или `nil`, если бот выбирает открытую ставку.
    func makePreDealBlindBid(
        playerIndex: Int,
        dealerIndex: Int,
        cardsInRound: Int,
        allowedBlindBids: [Int],
        canChooseBlind: Bool,
        totalScores: [Int]
    ) -> Int? {
        guard canChooseBlind else { return nil }
        let bidding = tuning.bidding

        let allowed = Array(Set(allowedBlindBids)).sorted()
        guard !allowed.isEmpty else { return nil }

        let clampedPlayerIndex = min(max(playerIndex, 0), max(0, totalScores.count - 1))
        let playerScore = totalScores.indices.contains(clampedPlayerIndex) ? totalScores[clampedPlayerIndex] : 0
        let leaderScore = totalScores.max() ?? playerScore

        let scoresWithoutPlayer = totalScores.enumerated()
            .filter { $0.offset != clampedPlayerIndex }
            .map(\.element)
        let bestOpponentScore = scoresWithoutPlayer.max() ?? playerScore

        let behindByLeader = max(0, leaderScore - playerScore)
        let aheadOfOpponent = max(0, playerScore - bestOpponentScore)

        let shouldRiskBlind: Bool
        if behindByLeader >= bidding.blindDesperateBehindThreshold {
            shouldRiskBlind = true
        } else if behindByLeader >= bidding.blindCatchUpBehindThreshold && playerIndex != dealerIndex {
            shouldRiskBlind = true
        } else if aheadOfOpponent >= bidding.blindSafeLeadThreshold {
            shouldRiskBlind = false
        } else {
            shouldRiskBlind = false
        }

        guard shouldRiskBlind else { return nil }

        let cards = max(0, cardsInRound)
        let targetShare: Double
        if behindByLeader >= bidding.blindDesperateBehindThreshold {
            targetShare = bidding.blindDesperateTargetShare
        } else {
            let pressureDenominator = max(
                1,
                bidding.blindDesperateBehindThreshold - bidding.blindCatchUpBehindThreshold
            )
            let pressure = Double(max(0, behindByLeader - bidding.blindCatchUpBehindThreshold)) /
                Double(pressureDenominator)
            let normalizedPressure = min(max(pressure, 0.0), 1.0)
            let conservativeShare = min(
                bidding.blindCatchUpTargetShare,
                max(0.0, bidding.blindCatchUpConservativeTargetShare)
            )
            targetShare = conservativeShare +
                (bidding.blindCatchUpTargetShare - conservativeShare) * normalizedPressure
        }
        let targetBid = Int((Double(cards) * targetShare).rounded())
        return nearestAllowedBid(to: targetBid, allowed: allowed)
    }

    private func estimateExpectedTricks(
        in hand: [Card],
        cardsInRound: Int,
        trump: Suit?
    ) -> Int {
        guard cardsInRound > 0 else { return 0 }
        guard !hand.isEmpty else { return 0 }
        let bidding = tuning.bidding
        let handFeatures = handFeatureExtractor.extract(from: hand)
        let suitCounts = handFeatures.suitCounts
        let jokerCount = handFeatures.jokerCount
        let highCardCount = handFeatures.highCardCount
        let longestSuit = handFeatures.longestSuitCount

        var power = 0.0

        for card in hand {
            if card.isJoker {
                power += bidding.expectedJokerPower
                continue
            }

            guard case .regular(let suit, let rank) = card else { continue }

            let normalizedRank = BotRankNormalization.normalizedForBidding(rank)
            var value = normalizedRank * bidding.expectedRankWeight

            if let trump, suit == trump {
                value += bidding.expectedTrumpBaseBonus + normalizedRank * bidding.expectedTrumpRankWeight
            } else if BotRankNormalization.isHighCard(rank) {
                value += bidding.expectedHighRankBonus
            }

            power += value
        }

        if longestSuit >= 3 {
            power += Double(longestSuit - 2) * bidding.expectedLongSuitBonusPerCard
        }

        if let trump {
            let trumpCount = suitCounts[trump] ?? 0
            let trumpDensity = Double(trumpCount) / Double(max(1, cardsInRound))
            power += Double(trumpCount) * trumpDensity * bidding.expectedTrumpDensityBonus
        } else {
            power += Double(highCardCount) * bidding.expectedNoTrumpHighCardBonus
            if jokerCount > 0 {
                let controlSupport = Double(highCardCount) * 0.35 +
                    Double(max(0, longestSuit - 2)) * 0.65
                power += Double(jokerCount) * controlSupport * bidding.expectedNoTrumpJokerSynergy
            }
        }

        let rounded = Int(power.rounded())
        return max(0, min(cardsInRound, rounded))
    }

    private func nearestAllowedBid(to target: Int, allowed: [Int]) -> Int {
        guard let first = allowed.first else { return 0 }
        var best = first
        var bestDistance = abs(first - target)

        for bid in allowed.dropFirst() {
            let distance = abs(bid - target)
            if distance < bestDistance || (distance == bestDistance && bid < best) {
                best = bid
                bestDistance = distance
            }
        }

        return best
    }
}
