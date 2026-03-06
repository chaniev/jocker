//
//  BotSelfPlayEvolutionEngine+SimulationOrchestration.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

extension BotSelfPlayEvolutionEngine {
    struct FullMatchRoundDeal {
        let hands: [[Card]]
        let trump: Suit?
    }

    static func makeSeatServices(
        for tuningsBySeat: [BotTuning]
    ) -> SeatServiceBundle {
        return SeatServiceBundle(
            turnServices: tuningsBySeat.map { BotTurnStrategyService(tuning: $0) },
            biddingServices: tuningsBySeat.map { BotBiddingService(tuning: $0) },
            trumpServices: tuningsBySeat.map { BotTrumpSelectionService(tuning: $0) }
        )
    }

    static func simulateLegacyGame(
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

    static func simulateFullMatch(
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

    static func appendRoundResultsToBlock(
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

    static func dealRoundForFullMatch(
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

    static func dealHands(
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

    static func dealHandsFromDeckCards(
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

    static func trumpSuit(from trumpCard: Card?) -> Suit? {
        guard let trumpCard else { return nil }
        guard case .regular(let suit, _) = trumpCard else { return nil }
        return suit
    }

    static func sortedHands(_ hands: [[Card]]) -> [[Card]] {
        return hands.map { hand in
            hand.sorted()
        }
    }
}
