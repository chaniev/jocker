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
        forbiddenBid: Int?,
        matchContext: BotMatchContext? = nil
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
        totalScores: [Int],
        matchContext: BotMatchContext? = nil
    ) -> Int? {
        guard canChooseBlind else { return nil }
        let bidding = tuning.bidding
        _ = matchContext // Этап 4a plumbing: поведение пока не меняется.

        let allowed = Array(Set(allowedBlindBids)).sorted()
        guard !allowed.isEmpty else { return nil }

        let clampedPlayerIndex = min(max(playerIndex, 0), max(0, totalScores.count - 1))
        let clampedDealerIndex = min(max(dealerIndex, 0), max(0, totalScores.count - 1))
        let playerScore = totalScores.indices.contains(clampedPlayerIndex) ? totalScores[clampedPlayerIndex] : 0
        let leaderScore = totalScores.max() ?? playerScore

        let scoresWithoutPlayer = totalScores.enumerated()
            .filter { $0.offset != clampedPlayerIndex }
            .map(\.element)
        let bestOpponentScore = scoresWithoutPlayer.max() ?? playerScore

        let behindByLeader = max(0, leaderScore - playerScore)
        let aheadOfOpponent = max(0, playerScore - bestOpponentScore)
        let cards = max(0, cardsInRound)
        let minAllowed = allowed.first ?? 0
        let maxAllowed = allowed.last ?? 0
        let allowedRange = max(0, maxAllowed - minAllowed)

        let catchUpThreshold = max(1, bidding.blindCatchUpBehindThreshold)
        let desperateThreshold = max(catchUpThreshold + 1, bidding.blindDesperateBehindThreshold)
        let safeLeadThreshold = max(1, bidding.blindSafeLeadThreshold)

        // Risk score: positive values push the bot towards blind, negative values keep it conservative.
        var blindRiskScore = -0.55

        if behindByLeader >= bidding.blindCatchUpBehindThreshold {
            blindRiskScore += 0.35
        }
        if behindByLeader >= bidding.blindDesperateBehindThreshold {
            blindRiskScore += 0.35
        }

        let catchUpPressure = Double(max(0, behindByLeader - catchUpThreshold)) / Double(catchUpThreshold)
        blindRiskScore += catchUpPressure * 1.2

        let desperatePressureDenominator = max(1, desperateThreshold - catchUpThreshold)
        let desperatePressure = Double(max(0, behindByLeader - desperateThreshold)) /
            Double(desperatePressureDenominator)
        blindRiskScore += desperatePressure * 0.95

        let safetyPenalty = Double(aheadOfOpponent) / Double(safeLeadThreshold)
        blindRiskScore -= safetyPenalty * 1.1
        if aheadOfOpponent >= bidding.blindSafeLeadThreshold &&
            behindByLeader < bidding.blindDesperateBehindThreshold {
            blindRiskScore -= 0.5
        }

        if playerScore >= leaderScore {
            blindRiskScore -= 0.35
        }

        if clampedPlayerIndex == clampedDealerIndex {
            blindRiskScore -= 0.2
        } else {
            blindRiskScore += 0.08
        }

        blindRiskScore += min(0.35, Double(max(0, cards - 4)) / 10.0)

        let effectiveRoundCapacity = max(1, max(cards, maxAllowed))
        blindRiskScore -= Double(minAllowed) / Double(effectiveRoundCapacity) * 0.35

        if allowedRange <= 2 {
            blindRiskScore -= 0.2
        } else if allowedRange <= 4 {
            blindRiskScore -= 0.1
        } else {
            blindRiskScore += 0.05
        }

        guard blindRiskScore > 0.05 else { return nil }

        let conservativeShare = min(
            bidding.blindCatchUpTargetShare,
            max(0.0, bidding.blindCatchUpConservativeTargetShare)
        )
        let catchUpShare = max(conservativeShare, bidding.blindCatchUpTargetShare)
        let desperateShare = max(catchUpShare, bidding.blindDesperateTargetShare)

        let modeTargetShare: Double
        if behindByLeader >= desperateThreshold || blindRiskScore >= 1.6 {
            // "Emergency" mode: strong catch-up pressure or very high risk appetite.
            let overflow = min(1.0, max(0.0, (blindRiskScore - 1.6) / 1.2))
            modeTargetShare = desperateShare + 0.08 * overflow
        } else if behindByLeader >= catchUpThreshold || blindRiskScore >= 0.85 {
            // "Catching-up" mode: willing to take mid/high blind bids.
            let modeProgress = min(1.0, max(0.0, (blindRiskScore - 0.85) / 0.75))
            modeTargetShare = catchUpShare + (desperateShare - catchUpShare) * 0.35 * modeProgress
        } else {
            // "Conservative" mode: only light blind pressure.
            let modeProgress = min(1.0, max(0.0, (blindRiskScore - 0.05) / 0.8))
            modeTargetShare = conservativeShare + (catchUpShare - conservativeShare) * 0.45 * modeProgress
        }

        let positionAdjustment = clampedPlayerIndex == clampedDealerIndex ? -0.03 : 0.02
        let longRoundAdjustment = cards >= 8 ? 0.03 : 0.0
        let safetyAdjustment = aheadOfOpponent >= bidding.blindSafeLeadThreshold ? -0.05 : 0.0
        let targetShare = min(
            0.95,
            max(0.0, modeTargetShare + positionAdjustment + longRoundAdjustment + safetyAdjustment)
        )

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
