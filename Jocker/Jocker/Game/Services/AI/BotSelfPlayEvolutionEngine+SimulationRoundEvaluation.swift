//
//  BotSelfPlayEvolutionEngine+SimulationRoundEvaluation.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

extension BotSelfPlayEvolutionEngine {
    static func underbidLoss(
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

    static func jokerBidFloorUnderbidPenalty(
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

        if jokerCount >= 2 {
            penalty += Double(deficit) * 25_000.0
        }

        return penalty
    }

    static func jokerAllInEdgeMaxBidPenalty(
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

    static func nonFinalLeadWishWithoutAbovePenalty(
        nonFinalLeadWishCount: Int,
        cardsInRound: Int
    ) -> Double {
        guard nonFinalLeadWishCount > 0 else { return 0.0 }
        let depthMultiplier = cardsInRound >= 5 ? 1.20 : 1.0
        return Double(nonFinalLeadWishCount) * 2_400.0 * depthMultiplier
    }

    static func trumpDensityUnderbidPenalty(
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

    static func noTrumpControlUnderbidPenalty(
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

    struct RoundPlayOutcome {
        let tricksTaken: [Int]
        let nonFinalLeadWishCounts: [Int]
        let totalWishLeadDeclarationCounts: [Int]
        let winningWishLeadDeclarationCounts: [Int]
        let totalJokerPlayCounts: [Int]
        let earlyJokerPlayCounts: [Int]
    }

    struct RoundSimulationInput {
        let hands: [[Card]]
        let dealer: Int
        let cardsInRound: Int
        let trump: Suit?
        let preLockedBids: [Int]?
        let blindSelections: [Bool]?
        let noTrumpControlEmphasisMultiplier: Double
    }

    struct RoundSimulationOutputs {
        let biddingOutcome: BiddingRoundOutcome
        let playOutcome: RoundPlayOutcome
        let roundResults: [RoundResult]
    }

    static func playRound(
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
            autoreleasepool {
                var trick = BotTurnCardHeuristicsService.TrickSnapshot(playedCards: [])

                for offset in 0..<playerCount {
                    let player = normalizedPlayerIndex(trickLeader + offset, playerCount: playerCount)
                    let playerHand = mutableHands[player]

                    guard !playerHand.isEmpty else { continue }

                    let strategyMove = turnServices[player].makeTurnDecision(
                        context: .init(
                            handCards: playerHand,
                            trick: trick,
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
                        trick: trick,
                        trump: trump
                    ) {
                        move = fallbackMove
                    } else {
                        continue
                    }

                    if isNonFinalLeadWishJokerMove(
                        move: move,
                        trick: trick,
                        trickIndex: trickIndex,
                        cardsInRound: cardsInRound
                    ) {
                        nonFinalLeadWishCounts[player] += 1
                    }

                    let isLeadMove = trick.playedCards.isEmpty
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
                        let isLeadFallback = trick.playedCards.isEmpty
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
                        trick = trick.appendingPlayedCard(
                            fallbackCard,
                            fromPlayer: player + 1,
                            jokerPlayStyle: .faceUp,
                            jokerLeadDeclaration: fallbackCard.isJoker && trick.playedCards.isEmpty
                                ? .wish
                                : nil
                        )
                        continue
                    } else {
                        continue
                    }

                    trick = trick.appendingPlayedCard(
                        move.card,
                        fromPlayer: player + 1,
                        jokerPlayStyle: move.decision.style,
                        jokerLeadDeclaration: move.decision.leadDeclaration
                    )
                }

                let winner = TrickTakingResolver.winnerPlayerIndex(
                    playedCards: trick.playedCards,
                    trump: trump
                ) ?? trickLeader

                tricksTaken[winner] += 1
                completedTricksInRound.append(trick.playedCards)
                if
                    let winnerMove = trick.playedCards.first(where: { $0.playerIndex == winner + 1 }),
                    winnerMove.card.isJoker,
                    winnerMove.jokerLeadDeclaration == .wish,
                    trick.playedCards.first?.playerIndex == winner + 1
                {
                    winningWishLeadDeclarationCounts[winner] += 1
                }
                trickLeader = winner
            }
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

    static func simulateScoredRound(
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
        trick: BotTurnCardHeuristicsService.TrickSnapshot,
        trickIndex: Int,
        cardsInRound: Int
    ) -> Bool {
        guard move.card.isJoker else { return false }
        guard move.decision.style == .faceUp else { return false }
        guard trick.playedCards.isEmpty else { return false }
        guard trickIndex < cardsInRound - 1 else { return false }
        guard case .some(.wish) = move.decision.leadDeclaration else { return false }
        return true
    }

    private static func fallbackMove(
        hand: [Card],
        trick: BotTurnCardHeuristicsService.TrickSnapshot,
        trump: Suit?
    ) -> (card: Card, decision: JokerPlayDecision)? {
        guard !hand.isEmpty else { return nil }

        let legalCard = hand.first { card in
            trick.canPlayCard(card, fromHand: hand, trump: trump)
        } ?? hand[0]

        let decision: JokerPlayDecision
        if legalCard.isJoker {
            decision = trick.playedCards.isEmpty ? .defaultLead : .defaultNonLead
        } else {
            decision = .defaultNonLead
        }

        return (legalCard, decision)
    }
}
