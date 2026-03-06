//
//  BotSelfPlayEvolutionEngine+SimulationMetrics.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

extension BotSelfPlayEvolutionEngine {
    struct SimulationMetricsAccumulator {
        private(set) var totalScores: [Int]
        private(set) var underbidLosses: [Double]
        private(set) var trumpDensityUnderbidLosses: [Double]
        private(set) var noTrumpControlUnderbidLosses: [Double]
        private(set) var premiumAssistLosses: [Double]
        private(set) var premiumPenaltyTargetLosses: [Double]
        private var totalRoundsCount: [Int]
        private var exactBidRoundsCount: [Int]
        private var overbidRoundsCount: [Int]
        private var totalBlindRoundsCount: [Int]
        private var successfulBlindRoundsCount: [Int]
        private var totalBlocksCount: [Int]
        private var premiumCapturedBlocksCount: [Int]
        private var penaltyTargetBlocksCount: [Int]
        private var totalWishLeadDeclarationCounts: [Int]
        private var winningWishLeadDeclarationCounts: [Int]
        private var totalJokerPlayCounts: [Int]
        private var earlyJokerPlayCounts: [Int]
        private var totalEarlyLeadWishCounts: [Int]
        private var totalDealsBlock4Count: [Int]
        private var blindDealsBlock4Count: [Int]
        private var totalBlindBidAmount: [Int]
        private var blindOpportunitiesWhenBehindCount: [Int]
        private var blindChosenWhenBehindCount: [Int]
        private var blindOpportunitiesWhenLeadingCount: [Int]
        private var blindChosenWhenLeadingCount: [Int]
        private var leftNeighborPremiumEventsCount: [Int]
        private var assistedLeftNeighborPremiumCount: [Int]

        init(playerCount: Int) {
            self.totalScores = Array(repeating: 0, count: playerCount)
            self.underbidLosses = Array(repeating: 0.0, count: playerCount)
            self.trumpDensityUnderbidLosses = Array(repeating: 0.0, count: playerCount)
            self.noTrumpControlUnderbidLosses = Array(repeating: 0.0, count: playerCount)
            self.premiumAssistLosses = Array(repeating: 0.0, count: playerCount)
            self.premiumPenaltyTargetLosses = Array(repeating: 0.0, count: playerCount)
            self.totalRoundsCount = Array(repeating: 0, count: playerCount)
            self.exactBidRoundsCount = Array(repeating: 0, count: playerCount)
            self.overbidRoundsCount = Array(repeating: 0, count: playerCount)
            self.totalBlindRoundsCount = Array(repeating: 0, count: playerCount)
            self.successfulBlindRoundsCount = Array(repeating: 0, count: playerCount)
            self.totalBlocksCount = Array(repeating: 0, count: playerCount)
            self.premiumCapturedBlocksCount = Array(repeating: 0, count: playerCount)
            self.penaltyTargetBlocksCount = Array(repeating: 0, count: playerCount)
            self.totalWishLeadDeclarationCounts = Array(repeating: 0, count: playerCount)
            self.winningWishLeadDeclarationCounts = Array(repeating: 0, count: playerCount)
            self.totalJokerPlayCounts = Array(repeating: 0, count: playerCount)
            self.earlyJokerPlayCounts = Array(repeating: 0, count: playerCount)
            self.totalEarlyLeadWishCounts = Array(repeating: 0, count: playerCount)
            self.totalDealsBlock4Count = Array(repeating: 0, count: playerCount)
            self.blindDealsBlock4Count = Array(repeating: 0, count: playerCount)
            self.totalBlindBidAmount = Array(repeating: 0, count: playerCount)
            self.blindOpportunitiesWhenBehindCount = Array(repeating: 0, count: playerCount)
            self.blindChosenWhenBehindCount = Array(repeating: 0, count: playerCount)
            self.blindOpportunitiesWhenLeadingCount = Array(repeating: 0, count: playerCount)
            self.blindChosenWhenLeadingCount = Array(repeating: 0, count: playerCount)
            self.leftNeighborPremiumEventsCount = Array(repeating: 0, count: playerCount)
            self.assistedLeftNeighborPremiumCount = Array(repeating: 0, count: playerCount)
        }

        mutating func evaluateRound(
            hands: [[Card]],
            biddingOutcome: BiddingRoundOutcome,
            playOutcome: RoundPlayOutcome,
            cardsInRound: Int,
            trump: Suit?,
            blindSelections: [Bool]?,
            noTrumpControlEmphasisMultiplier: Double
        ) -> [RoundResult] {
            let playerCount = hands.count
            var roundResults: [RoundResult] = []
            roundResults.reserveCapacity(playerCount)

            for playerIndex in 0..<playerCount {
                let isBlind: Bool
                if let blindSelections, blindSelections.indices.contains(playerIndex) {
                    isBlind = blindSelections[playerIndex]
                } else {
                    isBlind = false
                }

                let roundResult = RoundResult(
                    cardsInRound: cardsInRound,
                    bid: biddingOutcome.bids[playerIndex],
                    tricksTaken: playOutcome.tricksTaken[playerIndex],
                    isBlind: isBlind
                )
                roundResults.append(roundResult)

                totalRoundsCount[playerIndex] += 1
                if roundResult.bidMatched {
                    exactBidRoundsCount[playerIndex] += 1
                } else if roundResult.tricksTaken > roundResult.bid {
                    overbidRoundsCount[playerIndex] += 1
                }
                if isBlind {
                    totalBlindRoundsCount[playerIndex] += 1
                    totalBlindBidAmount[playerIndex] += roundResult.bid
                    if roundResult.bidMatched {
                        successfulBlindRoundsCount[playerIndex] += 1
                    }
                }
                if playOutcome.totalWishLeadDeclarationCounts.indices.contains(playerIndex) {
                    totalWishLeadDeclarationCounts[playerIndex] += playOutcome.totalWishLeadDeclarationCounts[playerIndex]
                }
                if playOutcome.winningWishLeadDeclarationCounts.indices.contains(playerIndex) {
                    winningWishLeadDeclarationCounts[playerIndex] += playOutcome.winningWishLeadDeclarationCounts[playerIndex]
                }
                if playOutcome.totalJokerPlayCounts.indices.contains(playerIndex) {
                    totalJokerPlayCounts[playerIndex] += playOutcome.totalJokerPlayCounts[playerIndex]
                }
                if playOutcome.earlyJokerPlayCounts.indices.contains(playerIndex) {
                    earlyJokerPlayCounts[playerIndex] += playOutcome.earlyJokerPlayCounts[playerIndex]
                }
                if playOutcome.nonFinalLeadWishCounts.indices.contains(playerIndex) {
                    totalEarlyLeadWishCounts[playerIndex] += playOutcome.nonFinalLeadWishCounts[playerIndex]
                }

                underbidLosses[playerIndex] += BotSelfPlayEvolutionEngine.underbidLoss(
                    cardsInRound: cardsInRound,
                    bid: biddingOutcome.bids[playerIndex],
                    tricksTaken: playOutcome.tricksTaken[playerIndex],
                    isBlind: isBlind
                )
                underbidLosses[playerIndex] += BotSelfPlayEvolutionEngine.jokerBidFloorUnderbidPenalty(
                    hand: hands[playerIndex],
                    bid: biddingOutcome.bids[playerIndex],
                    maxAllowedBid: biddingOutcome.maxAllowedBids[playerIndex]
                )
                underbidLosses[playerIndex] += BotSelfPlayEvolutionEngine.jokerAllInEdgeMaxBidPenalty(
                    hand: hands[playerIndex],
                    bid: biddingOutcome.bids[playerIndex],
                    cardsInRound: cardsInRound,
                    maxAllowedBid: biddingOutcome.maxAllowedBids[playerIndex]
                )
                underbidLosses[playerIndex] += BotSelfPlayEvolutionEngine.nonFinalLeadWishWithoutAbovePenalty(
                    nonFinalLeadWishCount: playOutcome.nonFinalLeadWishCounts[playerIndex],
                    cardsInRound: cardsInRound
                )
                trumpDensityUnderbidLosses[playerIndex] += BotSelfPlayEvolutionEngine.trumpDensityUnderbidPenalty(
                    hand: hands[playerIndex],
                    bid: biddingOutcome.bids[playerIndex],
                    cardsInRound: cardsInRound,
                    trump: trump
                )
                noTrumpControlUnderbidLosses[playerIndex] += BotSelfPlayEvolutionEngine.noTrumpControlUnderbidPenalty(
                    hand: hands[playerIndex],
                    bid: biddingOutcome.bids[playerIndex],
                    cardsInRound: cardsInRound,
                    trump: trump,
                    emphasisMultiplier: noTrumpControlEmphasisMultiplier
                )
            }

            return roundResults
        }

        mutating func addRoundScores(_ roundResults: [RoundResult]) {
            for (playerIndex, roundResult) in roundResults.enumerated() {
                guard totalScores.indices.contains(playerIndex) else { continue }
                totalScores[playerIndex] += roundResult.score
            }
        }

        mutating func addFinalScores(_ finalScores: [Int]) {
            for (playerIndex, score) in finalScores.enumerated() {
                guard totalScores.indices.contains(playerIndex) else { continue }
                totalScores[playerIndex] += score
            }
        }

        mutating func recordBlock4BlindExposure(
            blindSelections: [Bool]
        ) {
            let playerCount = min(blindSelections.count, totalDealsBlock4Count.count)
            for playerIndex in 0..<playerCount {
                totalDealsBlock4Count[playerIndex] += 1
                if blindSelections[playerIndex] {
                    blindDealsBlock4Count[playerIndex] += 1
                }
            }
        }

        mutating func recordBlindChoiceContext(
            eligibleWhenBehind: [Bool],
            chosenWhenBehind: [Bool],
            eligibleWhenLeading: [Bool],
            chosenWhenLeading: [Bool]
        ) {
            let counts = [
                eligibleWhenBehind.count,
                chosenWhenBehind.count,
                eligibleWhenLeading.count,
                chosenWhenLeading.count,
                blindOpportunitiesWhenBehindCount.count
            ]
            let playerCount = counts.min() ?? 0
            guard playerCount > 0 else { return }

            for playerIndex in 0..<playerCount {
                if eligibleWhenBehind[playerIndex] {
                    blindOpportunitiesWhenBehindCount[playerIndex] += 1
                }
                if chosenWhenBehind[playerIndex] {
                    blindChosenWhenBehindCount[playerIndex] += 1
                }
                if eligibleWhenLeading[playerIndex] {
                    blindOpportunitiesWhenLeadingCount[playerIndex] += 1
                }
                if chosenWhenLeading[playerIndex] {
                    blindChosenWhenLeadingCount[playerIndex] += 1
                }
            }
        }

        mutating func accumulatePremiumSupportLosses(
            blockOutcome: PremiumRules.BlockFinalizationOutcome,
            playerCount: Int
        ) {
            let boundedPlayerCount = min(playerCount, totalBlocksCount.count)
            let premiumPlayersSet = Set(blockOutcome.allPremiumPlayers)
            for playerIndex in 0..<boundedPlayerCount {
                totalBlocksCount[playerIndex] += 1
                if premiumPlayersSet.contains(playerIndex) {
                    premiumCapturedBlocksCount[playerIndex] += 1
                }
                let penalty = blockOutcome.premiumPenalties.indices.contains(playerIndex)
                    ? blockOutcome.premiumPenalties[playerIndex]
                    : 0
                if penalty > 0 {
                    penaltyTargetBlocksCount[playerIndex] += 1
                }

                let leftNeighbor = PremiumRules.leftNeighbor(of: playerIndex, playerCount: boundedPlayerCount)
                if premiumPlayersSet.contains(leftNeighbor) {
                    leftNeighborPremiumEventsCount[playerIndex] += 1
                    if !premiumPlayersSet.contains(playerIndex) {
                        assistedLeftNeighborPremiumCount[playerIndex] += 1
                    }
                }
            }
            BotSelfPlayEvolutionEngine.accumulatePremiumSupportLosses(
                premiumAssistLosses: &premiumAssistLosses,
                premiumPenaltyTargetLosses: &premiumPenaltyTargetLosses,
                blockOutcome: blockOutcome,
                playerCount: playerCount
            )
        }

        func makeOutcome() -> SimulatedGameOutcome {
            let playerCount = totalScores.count
            let premiumCaptureRates = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(premiumCapturedBlocksCount[playerIndex]),
                    Double(totalBlocksCount[playerIndex])
                )
            }
            let blindSuccessRates = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(successfulBlindRoundsCount[playerIndex]),
                    Double(totalBlindRoundsCount[playerIndex])
                )
            }
            let jokerWishWinRates = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(winningWishLeadDeclarationCounts[playerIndex]),
                    Double(totalWishLeadDeclarationCounts[playerIndex])
                )
            }
            let earlyJokerSpendRates = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(earlyJokerPlayCounts[playerIndex]),
                    Double(totalJokerPlayCounts[playerIndex])
                )
            }
            let penaltyTargetRates = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(penaltyTargetBlocksCount[playerIndex]),
                    Double(totalBlocksCount[playerIndex])
                )
            }
            let bidAccuracyRates = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(exactBidRoundsCount[playerIndex]),
                    Double(totalRoundsCount[playerIndex])
                )
            }
            let overbidRates = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(overbidRoundsCount[playerIndex]),
                    Double(totalRoundsCount[playerIndex])
                )
            }
            let blindBidRatesBlock4 = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(blindDealsBlock4Count[playerIndex]),
                    Double(totalDealsBlock4Count[playerIndex])
                )
            }
            let averageBlindBidSizes = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(totalBlindBidAmount[playerIndex]),
                    Double(totalBlindRoundsCount[playerIndex])
                )
            }
            let blindBidWhenBehindRates = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(blindChosenWhenBehindCount[playerIndex]),
                    Double(blindOpportunitiesWhenBehindCount[playerIndex])
                )
            }
            let blindBidWhenLeadingRates = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(blindChosenWhenLeadingCount[playerIndex]),
                    Double(blindOpportunitiesWhenLeadingCount[playerIndex])
                )
            }
            let earlyLeadWishJokerRates = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(totalEarlyLeadWishCounts[playerIndex]),
                    Double(totalRoundsCount[playerIndex])
                )
            }
            let leftNeighborPremiumAssistRates = (0..<playerCount).map { playerIndex in
                BotSelfPlayEvolutionEngine.ratio(
                    Double(assistedLeftNeighborPremiumCount[playerIndex]),
                    Double(leftNeighborPremiumEventsCount[playerIndex])
                )
            }

            return SimulatedGameOutcome(
                totalScores: totalScores,
                underbidLosses: underbidLosses,
                trumpDensityUnderbidLosses: trumpDensityUnderbidLosses,
                noTrumpControlUnderbidLosses: noTrumpControlUnderbidLosses,
                premiumAssistLosses: premiumAssistLosses,
                premiumPenaltyTargetLosses: premiumPenaltyTargetLosses,
                premiumCaptureRates: premiumCaptureRates,
                blindSuccessRates: blindSuccessRates,
                jokerWishWinRates: jokerWishWinRates,
                earlyJokerSpendRates: earlyJokerSpendRates,
                penaltyTargetRates: penaltyTargetRates,
                bidAccuracyRates: bidAccuracyRates,
                overbidRates: overbidRates,
                blindBidRatesBlock4: blindBidRatesBlock4,
                averageBlindBidSizes: averageBlindBidSizes,
                blindBidWhenBehindRates: blindBidWhenBehindRates,
                blindBidWhenLeadingRates: blindBidWhenLeadingRates,
                earlyLeadWishJokerRates: earlyLeadWishJokerRates,
                leftNeighborPremiumAssistRates: leftNeighborPremiumAssistRates
            )
        }
    }

    typealias BlockFinalizationOutcome = PremiumRules.BlockFinalizationOutcome

    static func finalizeBlockScores(
        blockRoundResults: [[RoundResult]],
        blockNumber: Int,
        playerCount: Int
    ) -> BlockFinalizationOutcome {
        return PremiumRules.finalizeBlockScores(
            blockRoundResults: blockRoundResults,
            blockNumber: blockNumber,
            playerCount: playerCount
        )
    }

    static func accumulatePremiumSupportLosses(
        premiumAssistLosses: inout [Double],
        premiumPenaltyTargetLosses: inout [Double],
        blockOutcome: BlockFinalizationOutcome,
        playerCount: Int
    ) {
        guard playerCount > 0 else { return }
        guard !blockOutcome.allPremiumPlayers.isEmpty else { return }

        let premiumPlayersSet = Set(blockOutcome.allPremiumPlayers)
        let premiumGains = (0..<playerCount).map { playerIndex in
            let regularBonus = blockOutcome.premiumBonuses.indices.contains(playerIndex)
                ? blockOutcome.premiumBonuses[playerIndex]
                : 0
            let zeroBonus = blockOutcome.zeroPremiumBonuses.indices.contains(playerIndex)
                ? blockOutcome.zeroPremiumBonuses[playerIndex]
                : 0
            return regularBonus + zeroBonus
        }

        for playerIndex in 0..<playerCount {
            let penalty = blockOutcome.premiumPenalties.indices.contains(playerIndex)
                ? blockOutcome.premiumPenalties[playerIndex]
                : 0
            premiumPenaltyTargetLosses[playerIndex] += Double(max(0, penalty))

            guard !premiumPlayersSet.contains(playerIndex) else { continue }
            let opponentPremiumPlayers = blockOutcome.allPremiumPlayers.filter { $0 != playerIndex }
            guard !opponentPremiumPlayers.isEmpty else { continue }

            let opponentsPremiumGain = opponentPremiumPlayers.reduce(0) { partial, opponentIndex in
                partial + (premiumGains.indices.contains(opponentIndex) ? premiumGains[opponentIndex] : 0)
            }
            let structureLoss = Double(opponentPremiumPlayers.count) * 120.0
            let gainLoss = Double(max(0, opponentsPremiumGain)) * 0.45
            premiumAssistLosses[playerIndex] += structureLoss + gainLoss
        }
    }
}
