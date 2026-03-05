//
//  BotSelfPlayEvolutionEngine+Simulation.swift
//  Jocker
//
//  Created by Codex on 04.03.2026.
//

import Foundation

extension BotSelfPlayEvolutionEngine {
    private static func ratio(_ numerator: Double, _ denominator: Double) -> Double {
        guard denominator > 0 else { return 0.0 }
        return numerator / denominator
    }

    private struct PreDealBlindContext {
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

    private struct SeatServiceBundle {
        let turnServices: [BotTurnStrategyService]
        let biddingServices: [BotBiddingService]
        let trumpServices: [BotTrumpSelectionService]
    }

    private struct SimulationMetricsAccumulator {
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

    private static func makeSeatServices(
        for tuningsBySeat: [BotTuning]
    ) -> SeatServiceBundle {
        return SeatServiceBundle(
            turnServices: tuningsBySeat.map { BotTurnStrategyService(tuning: $0) },
            biddingServices: tuningsBySeat.map { BotBiddingService(tuning: $0) },
            trumpServices: tuningsBySeat.map { BotTrumpSelectionService(tuning: $0) }
        )
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

    private static func simulateLegacyGame(
        tuningsBySeat: [BotTuning],
        rounds: Int,
        cardsPerRoundRange: ClosedRange<Int>,
        seed: UInt64
    ) -> SimulatedGameOutcome {
        let playerCount = tuningsBySeat.count
        var rng = SelfPlayRandomGenerator(seed: seed)

        let services = makeSeatServices(for: tuningsBySeat)
        var metrics = SimulationMetricsAccumulator(playerCount: playerCount)
        var dealer = Int.random(in: 0..<playerCount, using: &rng)

        for _ in 0..<rounds {
            let cardsInRound = Int.random(in: cardsPerRoundRange, using: &rng)
            let hands = dealHands(
                cardsPerPlayer: cardsInRound,
                playerCount: playerCount,
                dealer: dealer,
                using: &rng
            )

            let trumpChooser = normalizedPlayerIndex(dealer + 1, playerCount: playerCount)
            let trump = services.trumpServices[trumpChooser].selectTrump(from: hands[trumpChooser])
            let roundSimulation = simulateScoredRound(
                RoundSimulationInput(
                    hands: hands,
                    dealer: dealer,
                    cardsInRound: cardsInRound,
                    trump: trump,
                    preLockedBids: nil,
                    blindSelections: nil,
                    noTrumpControlEmphasisMultiplier: 0.75
                ),
                services: services,
                metrics: &metrics
            )
            metrics.addRoundScores(roundSimulation.roundResults)

            dealer = normalizedPlayerIndex(dealer + 1, playerCount: playerCount)
        }

        return metrics.makeOutcome()
    }

    private static func simulateFullMatch(
        tuningsBySeat: [BotTuning],
        seed: UInt64
    ) -> SimulatedGameOutcome {
        let playerCount = tuningsBySeat.count
        var rng = SelfPlayRandomGenerator(seed: seed)

        let services = makeSeatServices(for: tuningsBySeat)

        let blockDeals = GameConstants.allBlockDeals(playerCount: playerCount)

        var metrics = SimulationMetricsAccumulator(playerCount: playerCount)
        var dealer = Int.random(in: 0..<playerCount, using: &rng)

        for (blockIndex, dealsInBlock) in blockDeals.enumerated() {
            let blockNumber = blockIndex + 1
            var blockRoundResults = Array(repeating: [RoundResult](), count: playerCount)
            var blockBaseScores = Array(repeating: 0, count: playerCount)

            for cardsInRound in dealsInBlock {
                let roundDeal = dealRoundForFullMatch(
                    cardsPerPlayer: cardsInRound,
                    playerCount: playerCount,
                    dealer: dealer,
                    blockNumber: blockNumber,
                    trumpServices: services.trumpServices,
                    using: &rng
                )
                let hands = roundDeal.hands
                let trump = roundDeal.trump

                let totalsIncludingCurrentBlock = (0..<playerCount).map { index in
                    metrics.totalScores[index] + blockBaseScores[index]
                }

                let blindContext: PreDealBlindContext
                if blockNumber == GameBlock.fourth.rawValue {
                    blindContext = resolvePreDealBlindContext(
                        dealer: dealer,
                        cardsInRound: cardsInRound,
                        playerCount: playerCount,
                        biddingServices: services.biddingServices,
                        totalScoresIncludingCurrentBlock: totalsIncludingCurrentBlock
                    )
                } else {
                    blindContext = PreDealBlindContext(
                        lockedBids: Array(repeating: 0, count: playerCount),
                        blindSelections: Array(repeating: false, count: playerCount),
                        eligibleWhenBehind: Array(repeating: false, count: playerCount),
                        chosenWhenBehind: Array(repeating: false, count: playerCount),
                        eligibleWhenLeading: Array(repeating: false, count: playerCount),
                        chosenWhenLeading: Array(repeating: false, count: playerCount)
                    )
                }

                let noTrumpControlEmphasisMultiplier =
                    (blockNumber == GameBlock.first.rawValue ||
                     blockNumber == GameBlock.third.rawValue) ? 1.0 : 0.55
                if blockNumber == GameBlock.fourth.rawValue {
                    metrics.recordBlindChoiceContext(
                        eligibleWhenBehind: blindContext.eligibleWhenBehind,
                        chosenWhenBehind: blindContext.chosenWhenBehind,
                        eligibleWhenLeading: blindContext.eligibleWhenLeading,
                        chosenWhenLeading: blindContext.chosenWhenLeading
                    )
                    metrics.recordBlock4BlindExposure(
                        blindSelections: blindContext.blindSelections
                    )
                }
                let roundSimulation = simulateScoredRound(
                    RoundSimulationInput(
                        hands: hands,
                        dealer: dealer,
                        cardsInRound: cardsInRound,
                        trump: trump,
                        preLockedBids: blindContext.lockedBids,
                        blindSelections: blindContext.blindSelections,
                        noTrumpControlEmphasisMultiplier: noTrumpControlEmphasisMultiplier
                    ),
                    services: services,
                    metrics: &metrics
                )
                let roundResults = roundSimulation.roundResults

                appendRoundResultsToBlock(
                    roundResults,
                    blockRoundResults: &blockRoundResults,
                    blockBaseScores: &blockBaseScores
                )

                dealer = normalizedPlayerIndex(dealer + 1, playerCount: playerCount)
            }

            let finalizedBlockOutcome = finalizeBlockScores(
                blockRoundResults: blockRoundResults,
                blockNumber: blockNumber,
                playerCount: playerCount
            )
            metrics.accumulatePremiumSupportLosses(
                blockOutcome: finalizedBlockOutcome,
                playerCount: playerCount
            )
            metrics.addFinalScores(finalizedBlockOutcome.finalScores)
        }

        return metrics.makeOutcome()
    }

    private static func appendRoundResultsToBlock(
        _ roundResults: [RoundResult],
        blockRoundResults: inout [[RoundResult]],
        blockBaseScores: inout [Int]
    ) {
        for (playerIndex, roundResult) in roundResults.enumerated() {
            guard blockRoundResults.indices.contains(playerIndex) else { continue }
            blockRoundResults[playerIndex].append(roundResult)
            if blockBaseScores.indices.contains(playerIndex) {
                blockBaseScores[playerIndex] += roundResult.score
            }
        }
    }

    private static func resolvePreDealBlindContext(
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

    /// Потери очков из-за недозаказа: сколько очков не добрал игрок,
    /// если фактические взятки были бы заказаны точно.
    private static func underbidLoss(
        cardsInRound: Int,
        bid: Int,
        tricksTaken: Int,
        isBlind: Bool
    ) -> Double {
        guard tricksTaken > bid else { return 0.0 }
        let idealBid = min(max(0, tricksTaken), max(0, cardsInRound))
        let idealScore = ScoreCalculator.calculateRoundScore(
            cardsInRound: cardsInRound,
            bid: idealBid,
            tricksTaken: tricksTaken,
            isBlind: isBlind
        )
        let actualScore = ScoreCalculator.calculateRoundScore(
            cardsInRound: cardsInRound,
            bid: bid,
            tricksTaken: tricksTaken,
            isBlind: isBlind
        )
        return Double(max(0, idealScore - actualScore))
    }

    /// Жесткий штраф за заказ ниже количества джокеров на руке.
    /// Каждый джокер в большинстве сценариев является контролируемым ресурсом взятки,
    /// поэтому такое занижение рассматривается как потеря потенциальных очков.
    private static func jokerBidFloorUnderbidPenalty(
        hand: [Card],
        bid: Int,
        maxAllowedBid: Int
    ) -> Double {
        let jokerCount = hand.reduce(0) { partial, card in
            partial + (card.isJoker ? 1 : 0)
        }
        let reachableJokerFloor = min(jokerCount, max(0, maxAllowedBid))
        let deficit = max(0, reachableJokerFloor - max(0, bid))
        guard deficit > 0 else { return 0.0 }
        let penaltyPerMissingTrick = 10_000.0
        var penalty = Double(deficit) * penaltyPerMissingTrick

        // Отдельно усиливаем штраф при двух джокерах:
        // такие руки должны заметно поднимать заказ.
        if jokerCount >= 2 {
            penalty += Double(deficit) * 25_000.0
        }

        return penalty
    }

    /// Граничный сценарий для self-play: если на руке ровно 2 джокера при раздаче 2 карт,
    /// бот должен стремиться к максимально допустимому заказу.
    private static func jokerAllInEdgeMaxBidPenalty(
        hand: [Card],
        bid: Int,
        cardsInRound: Int,
        maxAllowedBid: Int
    ) -> Double {
        guard cardsInRound == 2 else { return 0.0 }
        guard hand.count == 2 else { return 0.0 }
        let jokerCount = hand.reduce(0) { partial, card in
            partial + (card.isJoker ? 1 : 0)
        }
        guard jokerCount == 2 else { return 0.0 }

        let targetBid = min(max(0, maxAllowedBid), cardsInRound)
        let resolvedBid = min(max(0, bid), cardsInRound)
        let deficit = max(0, targetBid - resolvedBid)
        guard deficit > 0 else { return 0.0 }

        let penaltyPerMissingTrick = 65_000.0
        let certaintyBonus = targetBid == cardsInRound ? 25_000.0 : 10_000.0
        return Double(deficit) * penaltyPerMissingTrick + certaintyBonus
    }

    /// Штраф за ранний заход джокером в режиме "wish":
    /// без заказа масти бот хуже контролирует последующие взятки.
    private static func nonFinalLeadWishWithoutAbovePenalty(
        nonFinalLeadWishCount: Int,
        cardsInRound: Int
    ) -> Double {
        guard nonFinalLeadWishCount > 0 else { return 0.0 }
        let depthMultiplier = cardsInRound >= 5 ? 1.20 : 1.0
        return Double(nonFinalLeadWishCount) * 2_400.0 * depthMultiplier
    }

    /// Дополнительный штраф за недозаказ в руках с высокой плотностью козырей.
    private static func trumpDensityUnderbidPenalty(
        hand: [Card],
        bid: Int,
        cardsInRound: Int,
        trump: Suit?
    ) -> Double {
        guard let trump else { return 0.0 }
        guard cardsInRound > 0 else { return 0.0 }

        let trumpCount = hand.reduce(0) { partial, card in
            partial + ((card.suit == trump) ? 1 : 0)
        }
        let jokerCount = hand.reduce(0) { partial, card in
            partial + (card.isJoker ? 1 : 0)
        }
        let effectiveControl = Double(trumpCount) + Double(jokerCount) * 0.85
        let trumpDensity = effectiveControl / Double(cardsInRound)
        guard trumpDensity >= 0.45 else { return 0.0 }

        let suggestedFloor = min(
            cardsInRound,
            max(1, Int((effectiveControl * 0.75).rounded(.down)))
        )
        let deficit = max(0, suggestedFloor - max(0, bid))
        guard deficit > 0 else { return 0.0 }

        let densityMultiplier = 1.0 + max(0.0, trumpDensity - 0.45) * 2.5
        return Double(deficit) * 2_400.0 * densityMultiplier
    }

    /// Штраф за недозаказ в no-trump руках контроля:
    /// много старших карт и/или длина масти, особенно с джокером.
    private static func noTrumpControlUnderbidPenalty(
        hand: [Card],
        bid: Int,
        cardsInRound: Int,
        trump: Suit?,
        emphasisMultiplier: Double
    ) -> Double {
        guard trump == nil else { return 0.0 }
        guard cardsInRound > 0 else { return 0.0 }

        let regularCards = hand.compactMap { card -> (suit: Suit, rank: Rank)? in
            guard case .regular(let suit, let rank) = card else { return nil }
            return (suit, rank)
        }
        let suitCounts = Dictionary(grouping: regularCards, by: \.suit).mapValues(\.count)
        let longestSuit = suitCounts.values.max() ?? 0
        let highCards = regularCards.reduce(0) { partial, card in
            partial + (card.rank.rawValue >= Rank.queen.rawValue ? 1 : 0)
        }
        let jokerCount = hand.reduce(0) { partial, card in
            partial + (card.isJoker ? 1 : 0)
        }

        let hasControlPattern = highCards >= 4 || (jokerCount >= 1 && (highCards >= 3 || longestSuit >= 4))
        guard hasControlPattern else { return 0.0 }

        let controlScore = Double(highCards) * 0.70 +
            Double(max(0, longestSuit - 2)) * 1.00 +
            Double(jokerCount) * 1.20
        let suggestedFloor = min(
            cardsInRound,
            max(1, Int((controlScore * 0.42).rounded()))
        )
        let deficit = max(0, suggestedFloor - max(0, bid))
        guard deficit > 0 else { return 0.0 }

        let jokerMultiplier = jokerCount > 0 ? 1.35 : 1.0
        return Double(deficit) * 1_900.0 * jokerMultiplier * max(0.0, emphasisMultiplier)
    }

    private typealias BlockFinalizationOutcome = PremiumRules.BlockFinalizationOutcome

    private static func finalizeBlockScores(
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

    private static func accumulatePremiumSupportLosses(
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

            // Если игрок сам не взял премию, но соперники взяли,
            // считаем это "подарком премии" и штрафуем в self-play.
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

    private struct BiddingRoundOutcome {
        let bids: [Int]
        let maxAllowedBids: [Int]
    }

    private static func makeBids(
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

    private static func playRound(
        hands: [[Card]],
        bids: [Int],
        dealer: Int,
        cardsInRound: Int,
        trump: Suit?,
        turnServices: [BotTurnStrategyService]
    ) -> RoundPlayOutcome {
        let playerCount = hands.count
        var tricksTaken = Array(repeating: 0, count: playerCount)
        var nonFinalLeadWishCounts = Array(repeating: 0, count: playerCount)
        var totalWishLeadDeclarationCounts = Array(repeating: 0, count: playerCount)
        var winningWishLeadDeclarationCounts = Array(repeating: 0, count: playerCount)
        var totalJokerPlayCounts = Array(repeating: 0, count: playerCount)
        var earlyJokerPlayCounts = Array(repeating: 0, count: playerCount)
        var completedTricksInRound: [[PlayedTrickCard]] = []
        var mutableHands = hands
        var trickLeader = normalizedPlayerIndex(dealer + 1, playerCount: playerCount)

        for trickIndex in 0..<cardsInRound {
            let trickNode = TrickNode(rendersCards: false)

            for offset in 0..<playerCount {
                let player = normalizedPlayerIndex(trickLeader + offset, playerCount: playerCount)
                let playerHand = mutableHands[player]

                guard !playerHand.isEmpty else { continue }

                let strategyMove = turnServices[player].makeTurnDecision(
                    context: .init(
                        handCards: playerHand,
                        trickNode: trickNode,
                        trump: trump,
                        bid: bids[player],
                        tricksTaken: tricksTaken[player],
                        cardsInRound: cardsInRound,
                        playerCount: playerCount,
                        roundState: .init(
                            bids: bids,
                            tricksTaken: tricksTaken,
                            isBlindBid: Array(repeating: false, count: playerCount)
                        ),
                        actingPlayerIndex: player,
                        completedTricksInRound: completedTricksInRound
                    )
                )

                let move: (card: Card, decision: JokerPlayDecision)
                if let strategyMove {
                    move = (strategyMove.card, strategyMove.jokerDecision)
                } else if let fallbackMove = fallbackMove(
                    hand: playerHand,
                    trickNode: trickNode,
                    trump: trump
                ) {
                    move = fallbackMove
                } else {
                    continue
                }

                if isNonFinalLeadWishJokerMove(
                    move: move,
                    trickNode: trickNode,
                    trickIndex: trickIndex,
                    cardsInRound: cardsInRound
                ) {
                    nonFinalLeadWishCounts[player] += 1
                }

                let isLeadMove = trickNode.playedCards.isEmpty
                if move.card.isJoker {
                    totalJokerPlayCounts[player] += 1
                    if trickIndex + 1 < cardsInRound {
                        earlyJokerPlayCounts[player] += 1
                    }
                    if isLeadMove, move.decision.leadDeclaration == .wish {
                        totalWishLeadDeclarationCounts[player] += 1
                    }
                }

                if let removeIndex = mutableHands[player].firstIndex(of: move.card) {
                    mutableHands[player].remove(at: removeIndex)
                } else if let fallbackCard = mutableHands[player].first {
                    let isLeadFallback = trickNode.playedCards.isEmpty
                    if fallbackCard.isJoker {
                        totalJokerPlayCounts[player] += 1
                        if trickIndex + 1 < cardsInRound {
                            earlyJokerPlayCounts[player] += 1
                        }
                        if isLeadFallback {
                            totalWishLeadDeclarationCounts[player] += 1
                        }
                    }
                    mutableHands[player].removeFirst()
                    _ = trickNode.playCard(
                        fallbackCard,
                        fromPlayer: player + 1,
                        jokerPlayStyle: .faceUp,
                        jokerLeadDeclaration: fallbackCard.isJoker && trickNode.playedCards.isEmpty
                            ? .wish
                            : nil,
                        animated: false
                    )
                    continue
                } else {
                    continue
                }

                _ = trickNode.playCard(
                    move.card,
                    fromPlayer: player + 1,
                    jokerPlayStyle: move.decision.style,
                    jokerLeadDeclaration: move.decision.leadDeclaration,
                    animated: false
                )
            }

            let winner = TrickTakingResolver.winnerPlayerIndex(
                playedCards: trickNode.playedCards,
                trump: trump
            ) ?? trickLeader

            tricksTaken[winner] += 1
            completedTricksInRound.append(trickNode.playedCards)
            if
                let winnerMove = trickNode.playedCards.first(where: { $0.playerIndex == winner + 1 }),
                winnerMove.card.isJoker,
                winnerMove.jokerLeadDeclaration == .wish,
                trickNode.playedCards.first?.playerIndex == winner + 1
            {
                winningWishLeadDeclarationCounts[winner] += 1
            }
            trickLeader = winner
        }

        return RoundPlayOutcome(
            tricksTaken: tricksTaken,
            nonFinalLeadWishCounts: nonFinalLeadWishCounts,
            totalWishLeadDeclarationCounts: totalWishLeadDeclarationCounts,
            winningWishLeadDeclarationCounts: winningWishLeadDeclarationCounts,
            totalJokerPlayCounts: totalJokerPlayCounts,
            earlyJokerPlayCounts: earlyJokerPlayCounts
        )
    }

    private struct RoundPlayOutcome {
        let tricksTaken: [Int]
        let nonFinalLeadWishCounts: [Int]
        let totalWishLeadDeclarationCounts: [Int]
        let winningWishLeadDeclarationCounts: [Int]
        let totalJokerPlayCounts: [Int]
        let earlyJokerPlayCounts: [Int]
    }

    private struct RoundSimulationInput {
        let hands: [[Card]]
        let dealer: Int
        let cardsInRound: Int
        let trump: Suit?
        let preLockedBids: [Int]?
        let blindSelections: [Bool]?
        let noTrumpControlEmphasisMultiplier: Double
    }

    private struct RoundSimulationOutputs {
        let biddingOutcome: BiddingRoundOutcome
        let playOutcome: RoundPlayOutcome
        let roundResults: [RoundResult]
    }

    private static func simulateScoredRound(
        _ input: RoundSimulationInput,
        services: SeatServiceBundle,
        metrics: inout SimulationMetricsAccumulator
    ) -> RoundSimulationOutputs {
        let biddingOutcome = makeBids(
            hands: input.hands,
            dealer: input.dealer,
            cardsInRound: input.cardsInRound,
            trump: input.trump,
            biddingServices: services.biddingServices,
            preLockedBids: input.preLockedBids,
            blindSelections: input.blindSelections
        )
        let playOutcome = playRound(
            hands: input.hands,
            bids: biddingOutcome.bids,
            dealer: input.dealer,
            cardsInRound: input.cardsInRound,
            trump: input.trump,
            turnServices: services.turnServices
        )
        let roundResults = metrics.evaluateRound(
            hands: input.hands,
            biddingOutcome: biddingOutcome,
            playOutcome: playOutcome,
            cardsInRound: input.cardsInRound,
            trump: input.trump,
            blindSelections: input.blindSelections,
            noTrumpControlEmphasisMultiplier: input.noTrumpControlEmphasisMultiplier
        )
        return RoundSimulationOutputs(
            biddingOutcome: biddingOutcome,
            playOutcome: playOutcome,
            roundResults: roundResults
        )
    }

    private static func isNonFinalLeadWishJokerMove(
        move: (card: Card, decision: JokerPlayDecision),
        trickNode: TrickNode,
        trickIndex: Int,
        cardsInRound: Int
    ) -> Bool {
        guard move.card.isJoker else { return false }
        guard move.decision.style == .faceUp else { return false }
        guard trickNode.playedCards.isEmpty else { return false }
        guard trickIndex < cardsInRound - 1 else { return false }
        guard case .some(.wish) = move.decision.leadDeclaration else { return false }
        return true
    }

    private static func fallbackMove(
        hand: [Card],
        trickNode: TrickNode,
        trump: Suit?
    ) -> (card: Card, decision: JokerPlayDecision)? {
        guard !hand.isEmpty else { return nil }

        let legalCard = hand.first { card in
            trickNode.canPlayCard(card, fromHand: hand, trump: trump)
        } ?? hand[0]

        let decision: JokerPlayDecision
        if legalCard.isJoker {
            decision = trickNode.playedCards.isEmpty ? .defaultLead : .defaultNonLead
        } else {
            decision = .defaultNonLead
        }

        return (legalCard, decision)
    }

    private struct FullMatchRoundDeal {
        let hands: [[Card]]
        let trump: Suit?
    }

    private static func dealRoundForFullMatch(
        cardsPerPlayer: Int,
        playerCount: Int,
        dealer: Int,
        blockNumber: Int,
        trumpServices: [BotTrumpSelectionService],
        using rng: inout SelfPlayRandomGenerator
    ) -> FullMatchRoundDeal {
        var deckCards = Deck().cards
        deckCards.shuffle(using: &rng)
        let startingPlayer = normalizedPlayerIndex(dealer + 1, playerCount: playerCount)

        if blockNumber == GameBlock.first.rawValue || blockNumber == GameBlock.third.rawValue {
            let dealResult = dealHandsFromDeckCards(
                cardsPerPlayer: cardsPerPlayer,
                playerCount: playerCount,
                startingPlayer: startingPlayer,
                deckCards: deckCards,
                startingDeckIndex: 0
            )
            let topDeckCard = dealResult.nextDeckIndex < deckCards.count
                ? deckCards[dealResult.nextDeckIndex]
                : nil
            return FullMatchRoundDeal(
                hands: sortedHands(dealResult.hands),
                trump: trumpSuit(from: topDeckCard)
            )
        }

        let cardsBeforeChoice = min(cardsPerPlayer, max(1, cardsPerPlayer / 3))
        let initialDeal = dealHandsFromDeckCards(
            cardsPerPlayer: cardsBeforeChoice,
            playerCount: playerCount,
            startingPlayer: startingPlayer,
            deckCards: deckCards,
            startingDeckIndex: 0
        )
        let trumpChooser = normalizedPlayerIndex(dealer + 1, playerCount: playerCount)
        let trump = trumpServices[trumpChooser].selectTrump(
            from: initialDeal.hands[trumpChooser],
            isPlayerChosenTrumpStage: true
        )

        let remainingCards = max(0, cardsPerPlayer - cardsBeforeChoice)
        var fullHands = initialDeal.hands
        if remainingCards > 0 {
            let remainingDeal = dealHandsFromDeckCards(
                cardsPerPlayer: remainingCards,
                playerCount: playerCount,
                startingPlayer: startingPlayer,
                deckCards: deckCards,
                startingDeckIndex: initialDeal.nextDeckIndex
            )
            for index in 0..<playerCount {
                fullHands[index].append(contentsOf: remainingDeal.hands[index])
            }
        }

        return FullMatchRoundDeal(
            hands: sortedHands(fullHands),
            trump: trump
        )
    }

    private static func dealHands(
        cardsPerPlayer: Int,
        playerCount: Int,
        dealer: Int,
        using rng: inout SelfPlayRandomGenerator
    ) -> [[Card]] {
        var deckCards = Deck().cards
        deckCards.shuffle(using: &rng)

        let startingPlayer = normalizedPlayerIndex(dealer + 1, playerCount: playerCount)
        let dealResult = dealHandsFromDeckCards(
            cardsPerPlayer: cardsPerPlayer,
            playerCount: playerCount,
            startingPlayer: startingPlayer,
            deckCards: deckCards,
            startingDeckIndex: 0
        )
        return sortedHands(dealResult.hands)
    }

    private static func dealHandsFromDeckCards(
        cardsPerPlayer: Int,
        playerCount: Int,
        startingPlayer: Int,
        deckCards: [Card],
        startingDeckIndex: Int
    ) -> (hands: [[Card]], nextDeckIndex: Int) {
        var hands = Array(repeating: [Card](), count: playerCount)
        var deckIndex = max(0, startingDeckIndex)

        for _ in 0..<cardsPerPlayer {
            for offset in 0..<playerCount where deckIndex < deckCards.count {
                let player = normalizedPlayerIndex(startingPlayer + offset, playerCount: playerCount)
                hands[player].append(deckCards[deckIndex])
                deckIndex += 1
            }
        }

        return (hands: hands, nextDeckIndex: deckIndex)
    }

    private static func trumpSuit(from trumpCard: Card?) -> Suit? {
        guard let trumpCard else { return nil }
        guard case .regular(let suit, _) = trumpCard else { return nil }
        return suit
    }

    private static func sortedHands(_ hands: [[Card]]) -> [[Card]] {
        return hands.map { hand in
            hand.sorted()
        }
    }

    private static func allowedBids(
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

    private static func dealerForbiddenBid(
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

    private static func canChooseBlindBid(
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

    private static func biddingOrder(dealer: Int, playerCount: Int) -> [Int] {
        return BiddingRules.biddingOrder(
            dealer: dealer,
            playerCount: playerCount
        )
    }

    private static func normalizedPlayerIndex(
        _ rawIndex: Int,
        playerCount: Int
    ) -> Int {
        guard playerCount > 0 else { return 0 }
        let remainder = rawIndex % playerCount
        return remainder >= 0 ? remainder : remainder + playerCount
    }
}
