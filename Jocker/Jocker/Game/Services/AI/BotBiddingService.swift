//
//  BotBiddingService.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

/// Сервис авто-заказа взяток для бота.
final class BotBiddingService {
    private struct BidCandidate {
        let bid: Int
        let projectedScore: Int
        let distanceToExpected: Int
    }

    private struct BlindBidStats {
        private(set) var count = 0
        private(set) var mean = 0.0
        private(set) var m2 = 0.0

        mutating func add(_ value: Double) {
            count += 1
            let delta = value - mean
            mean += delta / Double(count)
            let delta2 = value - mean
            m2 += delta * delta2
        }

        var variance: Double {
            guard count > 1 else { return 0.0 }
            return m2 / Double(count - 1)
        }
    }

    private struct DeterministicRNG {
        private var state: UInt64

        init(seed: UInt64) {
            self.state = seed == 0 ? 0xA24B_AED4_963E_E407 : seed
        }

        mutating func nextUInt64() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }

        mutating func nextInt(upperBound: Int) -> Int {
            guard upperBound > 0 else { return 0 }
            return Int(nextUInt64() % UInt64(upperBound))
        }
    }

    private enum BlindMonteCarloConfig {
        static let minimumIterations = 24
        static let maximumIterations = 56
    }

    private let tuning: BotTuning
    private let handStrengthModel: BotHandStrengthModel

    init(tuning: BotTuning = BotTuning(difficulty: .hard)) {
        self.tuning = tuning
        self.handStrengthModel = BotHandStrengthModel(tuning: tuning)
    }

    func makeBid(
        hand: [Card],
        cardsInRound: Int,
        trump: Suit?,
        forbiddenBid: Int?,
        matchContext: BotMatchContext? = nil
    ) -> Int {
        let maxBid = max(0, cardsInRound)
        let expectedTricks = handStrengthModel.biddingExpectedTricks(
            hand: hand,
            cardsInRound: maxBid,
            trump: trump
        )

        let candidates = (0...maxBid).map { bid in
            BidCandidate(
                bid: bid,
                projectedScore: ScoreCalculator.calculateRoundScore(
                    cardsInRound: maxBid,
                    bid: bid,
                    tricksTaken: expectedTricks,
                    isBlind: false
                ),
                distanceToExpected: abs(bid - expectedTricks)
            )
        }
        guard let unconstrainedBest = bestProjectedBid(in: candidates) else { return 0 }

        let legalCandidates = candidates.filter { candidate in
            if let forbiddenBid {
                return candidate.bid != forbiddenBid
            }
            return true
        }
        guard !legalCandidates.isEmpty else {
            return unconstrainedBest.bid
        }

        let forbiddenTouchesOptimum = forbiddenBid == unconstrainedBest.bid
        var bestCandidate = legalCandidates[0]
        var bestUtility = bidUtility(
            candidate: bestCandidate,
            unconstrainedBest: unconstrainedBest,
            expectedTricks: expectedTricks,
            forbiddenTouchesOptimum: forbiddenTouchesOptimum,
            matchContext: matchContext
        )

        for candidate in legalCandidates.dropFirst() {
            let candidateUtility = bidUtility(
                candidate: candidate,
                unconstrainedBest: unconstrainedBest,
                expectedTricks: expectedTricks,
                forbiddenTouchesOptimum: forbiddenTouchesOptimum,
                matchContext: matchContext
            )
            if candidateUtility > bestUtility + 0.000_001 {
                bestUtility = candidateUtility
                bestCandidate = candidate
                continue
            }
            if abs(candidateUtility - bestUtility) <= 0.000_001 {
                if candidate.projectedScore > bestCandidate.projectedScore {
                    bestCandidate = candidate
                    continue
                }
                if candidate.projectedScore == bestCandidate.projectedScore {
                    let candidateDistanceToOptimum = abs(candidate.bid - unconstrainedBest.bid)
                    let bestDistanceToOptimum = abs(bestCandidate.bid - unconstrainedBest.bid)
                    if candidateDistanceToOptimum < bestDistanceToOptimum {
                        bestCandidate = candidate
                        continue
                    }
                    if candidateDistanceToOptimum == bestDistanceToOptimum &&
                        candidate.distanceToExpected < bestCandidate.distanceToExpected {
                        bestCandidate = candidate
                    }
                }
            }
        }

        return bestCandidate.bid
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
        _ = matchContext // Runtime context is forwarded for future phase-specific shaping.

        let allowed = Array(Set(allowedBlindBids)).sorted()
        guard !allowed.isEmpty else { return nil }

        let clampedPlayerIndex = min(max(playerIndex, 0), max(0, totalScores.count - 1))
        let clampedDealerIndex = min(max(dealerIndex, 0), max(0, totalScores.count - 1))
        let playerScore = totalScores.indices.contains(clampedPlayerIndex) ? totalScores[clampedPlayerIndex] : 0
        let leaderScore = totalScores.max() ?? playerScore

        let scoresWithoutPlayer = totalScores.enumerated()
            .filter { $0.offset != clampedPlayerIndex }
            .map(\.element)
        // Safety gap is measured against the closest chasing opponent,
        // not against the current table leader.
        let closestChaserScore = scoresWithoutPlayer
            .filter { $0 <= playerScore }
            .max() ?? playerScore

        let behindByLeader = max(0, leaderScore - playerScore)
        let aheadOfOpponent = max(0, playerScore - closestChaserScore)
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
            let overflow = min(1.0, max(0.0, (blindRiskScore - 1.6) / 1.2))
            modeTargetShare = desperateShare + 0.08 * overflow
        } else if behindByLeader >= catchUpThreshold || blindRiskScore >= 0.85 {
            let modeProgress = min(1.0, max(0.0, (blindRiskScore - 0.85) / 0.75))
            modeTargetShare = catchUpShare + (desperateShare - catchUpShare) * 0.35 * modeProgress
        } else {
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
        let targetBid = nearestAllowedBid(
            to: Int((Double(cards) * targetShare).rounded()),
            allowed: allowed
        )

        return bestBlindBidViaMonteCarlo(
            cardsInRound: cards,
            allowedBlindBids: allowed,
            targetBid: targetBid,
            blindRiskScore: blindRiskScore,
            behindByLeader: behindByLeader,
            aheadOfOpponent: aheadOfOpponent,
            catchUpThreshold: catchUpThreshold,
            desperateThreshold: desperateThreshold,
            safeLeadThreshold: safeLeadThreshold,
            playerIndex: clampedPlayerIndex,
            dealerIndex: clampedDealerIndex,
            totalScores: totalScores
        ) ?? targetBid
    }

    private func bestProjectedBid(in candidates: [BidCandidate]) -> BidCandidate? {
        guard let first = candidates.first else { return nil }
        var best = first
        for candidate in candidates.dropFirst() {
            if candidate.projectedScore > best.projectedScore {
                best = candidate
            } else if candidate.projectedScore == best.projectedScore &&
                candidate.distanceToExpected < best.distanceToExpected {
                best = candidate
            }
        }
        return best
    }

    private func bidUtility(
        candidate: BidCandidate,
        unconstrainedBest: BidCandidate,
        expectedTricks: Int,
        forbiddenTouchesOptimum: Bool,
        matchContext: BotMatchContext?
    ) -> Double {
        let projectedGap = Double(max(0, unconstrainedBest.projectedScore - candidate.projectedScore))
        let distanceToOptimum = abs(candidate.bid - unconstrainedBest.bid)
        let distanceToExpected = abs(candidate.bid - expectedTricks)

        let blockProgress = matchContext?.blockProgressFraction ?? 0.0
        let optimalityPenaltyWeight = forbiddenTouchesOptimum
            ? (7.4 + 2.8 * blockProgress)
            : (3.0 + 1.2 * blockProgress)
        let expectedPenaltyWeight = 1.7 + 0.9 * blockProgress
        let scoreGapPenaltyWeight = forbiddenTouchesOptimum ? 0.70 : 0.38

        return Double(candidate.projectedScore) -
            projectedGap * scoreGapPenaltyWeight -
            Double(distanceToOptimum) * optimalityPenaltyWeight -
            Double(distanceToExpected) * expectedPenaltyWeight
    }

    private func bestBlindBidViaMonteCarlo(
        cardsInRound: Int,
        allowedBlindBids: [Int],
        targetBid: Int,
        blindRiskScore: Double,
        behindByLeader: Int,
        aheadOfOpponent: Int,
        catchUpThreshold: Int,
        desperateThreshold: Int,
        safeLeadThreshold: Int,
        playerIndex: Int,
        dealerIndex: Int,
        totalScores: [Int]
    ) -> Int? {
        guard cardsInRound > 0 else { return nil }
        guard !allowedBlindBids.isEmpty else { return nil }

        let iterations = min(
            BlindMonteCarloConfig.maximumIterations,
            max(
                BlindMonteCarloConfig.minimumIterations,
                cardsInRound * 5 + allowedBlindBids.count * 2
            )
        )
        var rng = DeterministicRNG(
            seed: blindMonteCarloSeed(
                cardsInRound: cardsInRound,
                allowedBlindBids: allowedBlindBids,
                targetBid: targetBid,
                blindRiskScore: blindRiskScore,
                behindByLeader: behindByLeader,
                aheadOfOpponent: aheadOfOpponent,
                playerIndex: playerIndex,
                dealerIndex: dealerIndex,
                totalScores: totalScores
            )
        )

        var statsByBid: [Int: BlindBidStats] = [:]
        for bid in allowedBlindBids {
            statsByBid[bid] = BlindBidStats()
        }

        for _ in 0..<iterations {
            let sampledHand = sampleRandomHand(
                cardsInRound: cardsInRound,
                rng: &rng
            )
            let expectedTricks = averageExpectedTricksAcrossTrumpSamples(
                hand: sampledHand
            )

            for bid in allowedBlindBids {
                let score = interpolatedRoundScore(
                    cardsInRound: cardsInRound,
                    bid: bid,
                    expectedTricks: expectedTricks,
                    isBlind: true
                )
                statsByBid[bid]?.add(score)
            }
        }

        let riskBudget = min(1.0, max(0.0, (blindRiskScore - 0.05) / 2.0))
        let catchUpPressure = Double(max(0, behindByLeader - catchUpThreshold)) / Double(max(1, catchUpThreshold))
        let safeLeadPressure = Double(max(0, aheadOfOpponent - safeLeadThreshold)) / Double(max(1, safeLeadThreshold))
        var variancePenaltyWeight =
            0.50 +
            safeLeadPressure * 0.55 -
            Double(behindByLeader) / Double(max(1, desperateThreshold)) * 0.35
        variancePenaltyWeight = min(1.35, max(0.08, variancePenaltyWeight))
        variancePenaltyWeight *= (1.0 - 0.55 * riskBudget)

        let deviationPenaltyWeight = 1.2 + 3.6 * (1.0 - riskBudget)
        let overshootPenaltyWeight = 1.4 + safeLeadPressure * 1.1
        let catchUpAggressionWeight = 1.7 + catchUpPressure * 1.1

        guard var bestBid = allowedBlindBids.first else { return nil }
        var bestUtility = -Double.greatestFiniteMagnitude

        for bid in allowedBlindBids {
            guard let stats = statsByBid[bid] else { continue }
            let volatility = sqrt(max(0.0, stats.variance))
            let distanceFromTarget = abs(bid - targetBid)
            let aggressiveDistance = max(0, bid - targetBid)

            var utility = stats.mean
            utility -= volatility * variancePenaltyWeight
            utility -= Double(distanceFromTarget) * deviationPenaltyWeight
            utility += Double(aggressiveDistance) * catchUpAggressionWeight * catchUpPressure
            if safeLeadPressure > 0 {
                utility -= Double(aggressiveDistance) * overshootPenaltyWeight
            }

            if utility > bestUtility + 0.000_001 {
                bestUtility = utility
                bestBid = bid
                continue
            }
            if abs(utility - bestUtility) <= 0.000_001 &&
                abs(bid - targetBid) < abs(bestBid - targetBid) {
                bestBid = bid
            }
        }

        let minimumAggressiveBid = minimumBlindBidFloor(
            targetBid: targetBid,
            behindByLeader: behindByLeader,
            catchUpThreshold: catchUpThreshold,
            desperateThreshold: desperateThreshold,
            blindRiskScore: blindRiskScore,
            riskBudget: riskBudget
        )
        if let flooredBid = firstAllowedBid(
            atLeast: minimumAggressiveBid,
            in: allowedBlindBids
        ), bestBid < flooredBid {
            bestBid = flooredBid
        }

        return bestBid
    }

    private func sampleRandomHand(
        cardsInRound: Int,
        rng: inout DeterministicRNG
    ) -> [Card] {
        var deck = Deck().cards
        deterministicShuffle(&deck, rng: &rng)
        let drawCount = min(max(0, cardsInRound), deck.count)
        return Array(deck.prefix(drawCount))
    }

    private func averageExpectedTricksAcrossTrumpSamples(
        hand: [Card]
    ) -> Double {
        guard !hand.isEmpty else { return 0.0 }
        let trumpOptions: [Suit?] = [nil] + Suit.allCases.map(Optional.some)
        let total = trumpOptions.reduce(0.0) { partial, trump in
            let expected = handStrengthModel.biddingExpectedTricks(
                hand: hand,
                cardsInRound: hand.count,
                trump: trump
            )
            return partial + Double(expected)
        }
        return total / Double(max(1, trumpOptions.count))
    }

    private func interpolatedRoundScore(
        cardsInRound: Int,
        bid: Int,
        expectedTricks: Double,
        isBlind: Bool
    ) -> Double {
        let boundedExpected = min(Double(cardsInRound), max(0.0, expectedTricks))
        let lowerTricks = Int(floor(boundedExpected))
        let upperTricks = min(cardsInRound, lowerTricks + 1)
        if lowerTricks == upperTricks {
            return Double(
                ScoreCalculator.calculateRoundScore(
                    cardsInRound: cardsInRound,
                    bid: bid,
                    tricksTaken: lowerTricks,
                    isBlind: isBlind
                )
            )
        }

        let lowerScore = Double(
            ScoreCalculator.calculateRoundScore(
                cardsInRound: cardsInRound,
                bid: bid,
                tricksTaken: lowerTricks,
                isBlind: isBlind
            )
        )
        let upperScore = Double(
            ScoreCalculator.calculateRoundScore(
                cardsInRound: cardsInRound,
                bid: bid,
                tricksTaken: upperTricks,
                isBlind: isBlind
            )
        )
        let upperWeight = boundedExpected - Double(lowerTricks)
        let lowerWeight = 1.0 - upperWeight
        return lowerScore * lowerWeight + upperScore * upperWeight
    }

    private func deterministicShuffle(
        _ cards: inout [Card],
        rng: inout DeterministicRNG
    ) {
        guard cards.count > 1 else { return }
        for index in stride(from: cards.count - 1, through: 1, by: -1) {
            let swapIndex = rng.nextInt(upperBound: index + 1)
            if index != swapIndex {
                cards.swapAt(index, swapIndex)
            }
        }
    }

    private func blindMonteCarloSeed(
        cardsInRound: Int,
        allowedBlindBids: [Int],
        targetBid: Int,
        blindRiskScore: Double,
        behindByLeader: Int,
        aheadOfOpponent: Int,
        playerIndex: Int,
        dealerIndex: Int,
        totalScores: [Int]
    ) -> UInt64 {
        var seed = UInt64(0x9E37_79B9_7F4A_7C15)

        func mix(_ value: Int) {
            seed = seed &* 6364136223846793005 &+ UInt64(bitPattern: Int64(value))
            seed ^= seed >> 21
            seed ^= seed << 37
            seed ^= seed >> 4
        }

        mix(cardsInRound)
        mix(targetBid)
        mix(Int((blindRiskScore * 1000.0).rounded()))
        mix(behindByLeader)
        mix(aheadOfOpponent)
        mix(playerIndex)
        mix(dealerIndex)
        for bid in allowedBlindBids {
            mix(bid)
        }
        for score in totalScores {
            mix(score)
        }

        return seed
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

    private func minimumBlindBidFloor(
        targetBid: Int,
        behindByLeader: Int,
        catchUpThreshold: Int,
        desperateThreshold: Int,
        blindRiskScore: Double,
        riskBudget: Double
    ) -> Int {
        guard targetBid > 0 else { return 0 }
        let isDesperateMode = behindByLeader >= desperateThreshold || blindRiskScore >= 1.6
        if isDesperateMode {
            return max(2, Int((Double(targetBid) * 0.62).rounded(.down)))
        }
        guard behindByLeader >= catchUpThreshold else { return 0 }
        let catchUpShare = 0.28 + 0.20 * riskBudget
        return max(1, Int((Double(targetBid) * catchUpShare).rounded(.down)))
    }

    private func firstAllowedBid(atLeast minimumBid: Int, in allowed: [Int]) -> Int? {
        guard !allowed.isEmpty else { return nil }
        if minimumBid <= allowed[0] {
            return allowed[0]
        }
        return allowed.first(where: { $0 >= minimumBid }) ?? allowed.last
    }
}
