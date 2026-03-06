//
//  BotBlindBidMonteCarloEstimator.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

struct BotBlindBidMonteCarloEstimator {
    struct Input {
        let cardsInRound: Int
        let allowedBlindBids: [Int]
        let targetBid: Int
        let riskBudget: Double
        let behindByLeader: Int
        let aheadOfOpponent: Int
        let catchUpThreshold: Int
        let desperateThreshold: Int
        let safeLeadThreshold: Int
        let playerIndex: Int
        let dealerIndex: Int
        let totalScores: [Int]
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
        private let multiplier: UInt64
        private let increment: UInt64
        private var state: UInt64

        init(
            seed: UInt64,
            defaultSeed: UInt64,
            multiplier: UInt64,
            increment: UInt64
        ) {
            self.multiplier = multiplier
            self.increment = increment
            self.state = seed == 0 ? defaultSeed : seed
        }

        mutating func nextUInt64() -> UInt64 {
            state = state &* multiplier &+ increment
            return state
        }

        mutating func nextInt(upperBound: Int) -> Int {
            guard upperBound > 0 else { return 0 }
            return Int(nextUInt64() % UInt64(upperBound))
        }
    }

    private let policy: BotRuntimePolicy.Bidding.BlindMonteCarlo
    private let handStrengthModel: BotHandStrengthModel

    init(
        policy: BotRuntimePolicy.Bidding.BlindMonteCarlo,
        handStrengthModel: BotHandStrengthModel
    ) {
        self.policy = policy
        self.handStrengthModel = handStrengthModel
    }

    func bestBlindBid(for input: Input) -> Int? {
        guard input.cardsInRound > 0 else { return nil }
        guard !input.allowedBlindBids.isEmpty else { return nil }

        let iterations = min(
            policy.maximumIterations,
            max(
                policy.minimumIterations,
                input.cardsInRound * policy.iterationsPerCard +
                    input.allowedBlindBids.count * policy.iterationsPerBid
            )
        )
        var rng = DeterministicRNG(
            seed: monteCarloSeed(for: input),
            defaultSeed: policy.defaultRNGSeed,
            multiplier: policy.rngMultiplier,
            increment: policy.rngIncrement
        )

        var statsByBid: [Int: BlindBidStats] = [:]
        for bid in input.allowedBlindBids {
            statsByBid[bid] = BlindBidStats()
        }

        for _ in 0..<iterations {
            let sampledHand = sampleRandomHand(
                cardsInRound: input.cardsInRound,
                rng: &rng
            )
            let expectedTricks = averageExpectedTricksAcrossTrumpSamples(hand: sampledHand)

            for bid in input.allowedBlindBids {
                let score = interpolatedRoundScore(
                    cardsInRound: input.cardsInRound,
                    bid: bid,
                    expectedTricks: expectedTricks,
                    isBlind: true
                )
                statsByBid[bid]?.add(score)
            }
        }

        let catchUpPressure = Double(max(0, input.behindByLeader - input.catchUpThreshold)) /
            Double(max(1, input.catchUpThreshold))
        let safeLeadPressure = Double(max(0, input.aheadOfOpponent - input.safeLeadThreshold)) /
            Double(max(1, input.safeLeadThreshold))
        var variancePenaltyWeight =
            policy.variancePenaltyBase +
            safeLeadPressure * policy.safeLeadPressureMax -
            Double(input.behindByLeader) / Double(max(1, input.desperateThreshold)) * policy.desperatePenaltyWeight
        variancePenaltyWeight = min(
            policy.variancePenaltyWeightMax,
            max(policy.variancePenaltyWeightMin, variancePenaltyWeight)
        )
        variancePenaltyWeight *= (1.0 - policy.varianceRiskBudgetModifier * input.riskBudget)

        let deviationPenaltyWeight = policy.deviationPenaltyBase +
            policy.deviationRiskBudgetMultiplier * (1.0 - input.riskBudget)
        let overshootPenaltyWeight = policy.overshootPenaltyBase +
            safeLeadPressure * policy.overshootSafeLeadMultiplier
        let catchUpAggressionWeight = policy.catchUpAggressionBase +
            catchUpPressure * policy.catchUpAggressionPressureMultiplier

        guard var bestBid = input.allowedBlindBids.first else { return nil }
        var bestUtility = -Double.greatestFiniteMagnitude

        for bid in input.allowedBlindBids {
            guard let stats = statsByBid[bid] else { continue }
            let volatility = sqrt(max(0.0, stats.variance))
            let distanceFromTarget = abs(bid - input.targetBid)
            let aggressiveDistance = max(0, bid - input.targetBid)

            var utility = stats.mean
            utility -= volatility * variancePenaltyWeight
            utility -= Double(distanceFromTarget) * deviationPenaltyWeight
            utility += Double(aggressiveDistance) * catchUpAggressionWeight * catchUpPressure
            if safeLeadPressure > 0 {
                utility -= Double(aggressiveDistance) * overshootPenaltyWeight
            }

            if utility > bestUtility + policy.utilityTieTolerance {
                bestUtility = utility
                bestBid = bid
                continue
            }
            if abs(utility - bestUtility) <= policy.utilityTieTolerance &&
                abs(bid - input.targetBid) < abs(bestBid - input.targetBid) {
                bestBid = bid
            }
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

    private func averageExpectedTricksAcrossTrumpSamples(hand: [Card]) -> Double {
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

    private func monteCarloSeed(for input: Input) -> UInt64 {
        var seed = policy.baseSeed

        func mix(_ value: Int) {
            seed = seed &* policy.rngMultiplier &+ UInt64(bitPattern: Int64(value))
            seed ^= seed >> policy.hashShiftRight1
            seed ^= seed << policy.hashShiftLeft
            seed ^= seed >> policy.hashShiftRight2
        }

        mix(input.cardsInRound)
        mix(input.targetBid)
        mix(Int((input.riskBudget * 1000.0).rounded()))
        mix(input.behindByLeader)
        mix(input.aheadOfOpponent)
        mix(input.playerIndex)
        mix(input.dealerIndex)
        for bid in input.allowedBlindBids {
            mix(bid)
        }
        for score in input.totalScores {
            mix(score)
        }

        return seed
    }
}
