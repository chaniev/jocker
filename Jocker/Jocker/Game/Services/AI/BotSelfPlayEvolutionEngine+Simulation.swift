//
//  BotSelfPlayEvolutionEngine+Simulation.swift
//  Jocker
//
//  Created by Codex on 04.03.2026.
//

import Foundation

extension BotSelfPlayEvolutionEngine {
    static func ratio(_ numerator: Double, _ denominator: Double) -> Double {
        guard denominator > 0 else { return 0.0 }
        return numerator / denominator
    }

    struct PreDealBlindContext {
        let lockedBids: [Int]
        let blindSelections: [Bool]
        let eligibleWhenBehind: [Bool]
        let chosenWhenBehind: [Bool]
        let eligibleWhenLeading: [Bool]
        let chosenWhenLeading: [Bool]
    }

    struct SimulatedGameOutcome {
        let totalScores: [Int]
        let underbidLosses: [Double]
        let trumpDensityUnderbidLosses: [Double]
        let noTrumpControlUnderbidLosses: [Double]
        let premiumAssistLosses: [Double]
        let premiumPenaltyTargetLosses: [Double]
        let premiumCaptureRates: [Double]
        let blindSuccessRates: [Double]
        let jokerWishWinRates: [Double]
        let earlyJokerSpendRates: [Double]
        let penaltyTargetRates: [Double]
        let bidAccuracyRates: [Double]
        let overbidRates: [Double]
        let blindBidRatesBlock4: [Double]
        let averageBlindBidSizes: [Double]
        let blindBidWhenBehindRates: [Double]
        let blindBidWhenLeadingRates: [Double]
        let earlyLeadWishJokerRates: [Double]
        let leftNeighborPremiumAssistRates: [Double]
    }

    struct SeatServiceBundle {
        let turnServices: [BotTurnStrategyService]
        let biddingServices: [BotBiddingService]
        let trumpServices: [BotTrumpSelectionService]
    }

    struct DebugPreDealBlindContext {
        let lockedBids: [Int]
        let blindSelections: [Bool]
    }

    struct DebugBiddingRoundOutcome {
        let bids: [Int]
        let maxAllowedBids: [Int]
    }

    static func debugBiddingOrder(dealer: Int, playerCount: Int) -> [Int] {
        return biddingOrder(dealer: dealer, playerCount: playerCount)
    }

    static func debugCanChooseBlindBid(
        forPlayer playerIndex: Int,
        dealer: Int,
        blindSelections: [Bool]
    ) -> Bool {
        return canChooseBlindBid(
            forPlayer: playerIndex,
            dealer: dealer,
            blindSelections: blindSelections
        )
    }

    static func debugResolvePreDealBlindContext(
        dealer: Int,
        cardsInRound: Int,
        playerCount: Int,
        biddingServices: [BotBiddingService],
        totalScoresIncludingCurrentBlock: [Int]
    ) -> DebugPreDealBlindContext {
        let context = resolvePreDealBlindContext(
            dealer: dealer,
            cardsInRound: cardsInRound,
            playerCount: playerCount,
            biddingServices: biddingServices,
            totalScoresIncludingCurrentBlock: totalScoresIncludingCurrentBlock
        )
        return DebugPreDealBlindContext(
            lockedBids: context.lockedBids,
            blindSelections: context.blindSelections
        )
    }

    static func debugMakeBids(
        hands: [[Card]],
        dealer: Int,
        cardsInRound: Int,
        trump: Suit?,
        biddingServices: [BotBiddingService],
        preLockedBids: [Int]? = nil,
        blindSelections: [Bool]? = nil
    ) -> DebugBiddingRoundOutcome {
        let outcome = makeBids(
            hands: hands,
            dealer: dealer,
            cardsInRound: cardsInRound,
            trump: trump,
            biddingServices: biddingServices,
            preLockedBids: preLockedBids,
            blindSelections: blindSelections
        )
        return DebugBiddingRoundOutcome(
            bids: outcome.bids,
            maxAllowedBids: outcome.maxAllowedBids
        )
    }

    static func simulateGame(
        tuningsBySeat: [BotTuning],
        rounds: Int,
        cardsPerRoundRange: ClosedRange<Int>,
        seed: UInt64,
        useFullMatchRules: Bool
    ) -> SimulatedGameOutcome {
        if useFullMatchRules {
            return simulateFullMatch(
                tuningsBySeat: tuningsBySeat,
                seed: seed
            )
        }

        return simulateLegacyGame(
            tuningsBySeat: tuningsBySeat,
            rounds: rounds,
            cardsPerRoundRange: cardsPerRoundRange,
            seed: seed
        )
    }
}
