//
//  BotTurnStrategyService.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

/// Сервис выбора карты и режима розыгрыша джокера для хода бота.
final class BotTurnStrategyService {
    private let tuning: BotTuning

    private struct CandidateMove {
        let card: Card
        let decision: JokerPlayDecision
    }

    private struct CandidateEvaluation {
        let move: CandidateMove
        let utility: Double
        let immediateWinProbability: Double
        let threat: Double
    }

    init(tuning: BotTuning = BotTuning(difficulty: .hard)) {
        self.tuning = tuning
    }

    func makeTurnDecision(
        handCards: [Card],
        trickNode: TrickNode,
        trump: Suit?,
        bid: Int?,
        tricksTaken: Int?,
        cardsInRound: Int? = nil,
        playerCount: Int? = nil
    ) -> (card: Card, jokerDecision: JokerPlayDecision)? {
        guard !handCards.isEmpty else { return nil }

        let legalCards = handCards.filter { candidate in
            trickNode.canPlayCard(candidate, fromHand: handCards, trump: trump)
        }
        guard !legalCards.isEmpty else { return nil }

        let resolvedCardsInRound = max(handCards.count, cardsInRound ?? handCards.count)
        let currentTricks = max(0, tricksTaken ?? 0)
        let targetBid = normalizedBid(
            bid: bid,
            handCards: handCards,
            cardsInRound: resolvedCardsInRound,
            trump: trump
        )
        let shouldChaseTrick = currentTricks < targetBid
        let tricksNeededToMatchBid = max(0, targetBid - currentTricks)
        let tricksRemainingIncludingCurrent = max(1, handCards.count)
        let chasePressure = shouldChaseTrick
            ? min(
                1.0,
                max(
                    0.0,
                    Double(tricksNeededToMatchBid) / Double(tricksRemainingIncludingCurrent)
                )
            )
            : 0.0
        let opponentsRemaining = remainingOpponentsCount(
            playerCount: playerCount,
            cardsAlreadyOnTable: trickNode.playedCards.count
        )
        let unseen = unseenCards(
            excluding: handCards,
            and: trickNode.playedCards.map(\.card)
        )

        let hasWinningNonJoker = legalCards.contains { card in
            guard !card.isJoker else { return false }
            return winsTrickRightNow(
                with: card,
                decision: .defaultNonLead,
                trickNode: trickNode,
                trump: trump
            )
        }
        let hasLosingNonJoker = legalCards.contains { card in
            guard !card.isJoker else { return false }
            return !winsTrickRightNow(
                with: card,
                decision: .defaultNonLead,
                trickNode: trickNode,
                trump: trump
            )
        }

        var best: CandidateEvaluation?
        for card in legalCards {
            for decision in candidateDecisions(
                for: card,
                trickNode: trickNode,
                shouldChaseTrick: shouldChaseTrick
            ) {
                let move = CandidateMove(card: card, decision: decision)
                let immediateWinProbability = estimateImmediateWinProbability(
                    move: move,
                    trickNode: trickNode,
                    trump: trump,
                    unseenCards: unseen,
                    opponentsRemaining: opponentsRemaining,
                    handSizeBeforeMove: handCards.count
                )
                let projectedFinalTricks = projectedFinalTricks(
                    currentTricks: currentTricks,
                    immediateWinProbability: immediateWinProbability,
                    remainingHand: remainingHand(afterPlaying: card, from: handCards),
                    trump: trump,
                    cardsInRound: resolvedCardsInRound
                )
                let projectedScore = expectedRoundScore(
                    cardsInRound: resolvedCardsInRound,
                    bid: targetBid,
                    expectedTricks: projectedFinalTricks
                )
                let threat = cardThreat(
                    card: card,
                    decision: decision,
                    trump: trump,
                    trickNode: trickNode
                )
                let utility = moveUtility(
                    projectedScore: projectedScore,
                    immediateWinProbability: immediateWinProbability,
                    threat: threat,
                    move: move,
                    trickNode: trickNode,
                    trump: trump,
                    shouldChaseTrick: shouldChaseTrick,
                    hasWinningNonJoker: hasWinningNonJoker,
                    hasLosingNonJoker: hasLosingNonJoker,
                    tricksNeededToMatchBid: tricksNeededToMatchBid,
                    tricksRemainingIncludingCurrent: tricksRemainingIncludingCurrent,
                    chasePressure: chasePressure
                )

                let evaluation = CandidateEvaluation(
                    move: move,
                    utility: utility,
                    immediateWinProbability: immediateWinProbability,
                    threat: threat
                )

                if let currentBest = best {
                    if isBetterCandidate(evaluation, than: currentBest, shouldChaseTrick: shouldChaseTrick) {
                        best = evaluation
                    }
                } else {
                    best = evaluation
                }
            }
        }

        if let best {
            return (best.move.card, best.move.decision)
        }

        // Safety fallback: значение должно быть найдено всегда, но оставляем защиту.
        let fallbackCard = legalCards[0]
        let fallbackDecision = fallbackCard.isJoker
            ? candidateDecisions(
                for: fallbackCard,
                trickNode: trickNode,
                shouldChaseTrick: shouldChaseTrick
            ).first ?? .defaultNonLead
            : .defaultNonLead
        return (fallbackCard, fallbackDecision)
    }

    private func normalizedBid(
        bid: Int?,
        handCards: [Card],
        cardsInRound: Int,
        trump: Suit?
    ) -> Int {
        if let bid {
            return min(max(0, bid), cardsInRound)
        }

        let estimated = Int(estimateFutureTricks(in: handCards, trump: trump).rounded())
        return min(max(0, estimated), cardsInRound)
    }

    private func remainingOpponentsCount(
        playerCount: Int?,
        cardsAlreadyOnTable: Int
    ) -> Int {
        let totalPlayers = max(2, playerCount ?? 4)
        return max(0, totalPlayers - cardsAlreadyOnTable - 1)
    }

    private func candidateDecisions(
        for card: Card,
        trickNode: TrickNode,
        shouldChaseTrick: Bool
    ) -> [JokerPlayDecision] {
        guard card.isJoker else { return [.defaultNonLead] }

        let isLead = trickNode.playedCards.isEmpty
        if !isLead {
            if shouldChaseTrick {
                return [
                    JokerPlayDecision(style: .faceUp, leadDeclaration: nil),
                    JokerPlayDecision(style: .faceDown, leadDeclaration: nil)
                ]
            }
            return [
                JokerPlayDecision(style: .faceDown, leadDeclaration: nil),
                JokerPlayDecision(style: .faceUp, leadDeclaration: nil)
            ]
        }

        var decisions: [JokerPlayDecision] = [
            JokerPlayDecision(style: .faceUp, leadDeclaration: .wish)
        ]
        for suit in Suit.allCases {
            decisions.append(JokerPlayDecision(style: .faceUp, leadDeclaration: .above(suit: suit)))
            decisions.append(JokerPlayDecision(style: .faceUp, leadDeclaration: .takes(suit: suit)))
        }
        return decisions
    }

    private func isBetterCandidate(
        _ candidate: CandidateEvaluation,
        than current: CandidateEvaluation,
        shouldChaseTrick: Bool
    ) -> Bool {
        let tolerance = tuning.turnStrategy.utilityTieTolerance

        if candidate.utility > current.utility + tolerance {
            return true
        }
        if current.utility > candidate.utility + tolerance {
            return false
        }

        if shouldChaseTrick {
            if candidate.immediateWinProbability > current.immediateWinProbability + tolerance {
                return true
            }
            if current.immediateWinProbability > candidate.immediateWinProbability + tolerance {
                return false
            }
            if candidate.threat < current.threat - tolerance {
                return true
            }
            if current.threat < candidate.threat - tolerance {
                return false
            }
        } else {
            if candidate.immediateWinProbability < current.immediateWinProbability - tolerance {
                return true
            }
            if current.immediateWinProbability < candidate.immediateWinProbability - tolerance {
                return false
            }
            if candidate.threat > current.threat + tolerance {
                return true
            }
            if current.threat > candidate.threat + tolerance {
                return false
            }
        }

        // Детерминизм выбора при полном равенстве.
        if candidate.move.card != current.move.card {
            return candidate.move.card < current.move.card
        }
        return candidate.move.decision.style == .faceDown && current.move.decision.style == .faceUp
    }

    private func moveUtility(
        projectedScore: Double,
        immediateWinProbability: Double,
        threat: Double,
        move: CandidateMove,
        trickNode: TrickNode,
        trump: Suit?,
        shouldChaseTrick: Bool,
        hasWinningNonJoker: Bool,
        hasLosingNonJoker: Bool,
        tricksNeededToMatchBid: Int,
        tricksRemainingIncludingCurrent: Int,
        chasePressure: Double
    ) -> Double {
        let strategy = tuning.turnStrategy
        var utility = projectedScore
        let isLeadJoker = move.card.isJoker && trickNode.playedCards.isEmpty

        if shouldChaseTrick {
            let conservatism = max(0.0, 1.0 - chasePressure)
            utility += immediateWinProbability * strategy.chaseWinProbabilityWeight * (1.0 + chasePressure)
            utility -= threat * strategy.chaseThreatPenaltyWeight * conservatism

            if move.card.isJoker && hasWinningNonJoker {
                utility -= strategy.chaseSpendJokerPenalty * conservatism
            }

            if tricksNeededToMatchBid >= tricksRemainingIncludingCurrent {
                utility -= (1.0 - immediateWinProbability) * strategy.chaseSpendJokerPenalty
            }

            if isLeadJoker {
                if case .some(.wish) = move.decision.leadDeclaration {
                    utility += strategy.chaseLeadWishBonus * (0.5 + chasePressure * 0.5)
                }
            }
        } else {
            utility += (1.0 - immediateWinProbability) * strategy.dumpAvoidWinWeight
            utility += threat * strategy.dumpThreatRewardWeight

            if move.card.isJoker && hasLosingNonJoker {
                utility -= strategy.dumpSpendJokerPenalty
            }
            if move.card.isJoker && move.decision.style == .faceUp && !trickNode.playedCards.isEmpty {
                utility -= strategy.dumpFaceUpNonLeadJokerPenalty
            }

            if isLeadJoker, case .some(.takes(let suit)) = move.decision.leadDeclaration {
                if let trump, suit != trump {
                    utility += strategy.dumpLeadTakesNonTrumpBonus
                }
            }
        }

        return utility
    }

    private func estimateImmediateWinProbability(
        move: CandidateMove,
        trickNode: TrickNode,
        trump: Suit?,
        unseenCards: [Card],
        opponentsRemaining: Int,
        handSizeBeforeMove: Int
    ) -> Double {
        guard winsTrickRightNow(
            with: move.card,
            decision: move.decision,
            trickNode: trickNode,
            trump: trump
        ) else {
            return 0.0
        }

        if opponentsRemaining == 0 {
            return 1.0
        }

        guard !unseenCards.isEmpty else {
            return 1.0
        }

        let trickAfterMove = trickNode.playedCards + [
            PlayedTrickCard(
                playerIndex: -1,
                card: move.card,
                jokerPlayStyle: move.decision.style,
                jokerLeadDeclaration: move.decision.leadDeclaration
            )
        ]

        let beatersCount = unseenCards.reduce(0) { partial, card in
            let simulated = trickAfterMove + [
                PlayedTrickCard(
                    playerIndex: -2,
                    card: card,
                    jokerPlayStyle: .faceUp,
                    jokerLeadDeclaration: nil
                )
            ]

            let canBeat = TrickTakingResolver.winnerPlayerIndex(
                playedCards: simulated,
                trump: trump
            ) == -2

            return partial + (canBeat ? 1 : 0)
        }

        let beaterRatio = Double(beatersCount) / Double(unseenCards.count)
        let estimatedDraws = max(1, opponentsRemaining * max(1, handSizeBeforeMove))
        let holdFromDistribution = pow(max(0.0, 1.0 - beaterRatio), Double(estimatedDraws))

        let strategy = tuning.turnStrategy
        let powerConfidence = min(
            1.0,
            max(
                0.0,
                Double(cardPower(move.card, decision: move.decision, trickNode: trickNode, trump: trump)) /
                    max(1.0, strategy.powerNormalizationValue)
            )
        )

        return min(
            1.0,
            max(
                0.0,
                holdFromDistribution * strategy.holdFromDistributionWeight +
                    powerConfidence * strategy.powerConfidenceWeight
            )
        )
    }

    private func projectedFinalTricks(
        currentTricks: Int,
        immediateWinProbability: Double,
        remainingHand: [Card],
        trump: Suit?,
        cardsInRound: Int
    ) -> Double {
        let futureTricks = estimateFutureTricks(in: remainingHand, trump: trump)
        let projected = Double(currentTricks) + immediateWinProbability + futureTricks
        return min(Double(cardsInRound), max(0.0, projected))
    }

    private func estimateFutureTricks(in handCards: [Card], trump: Suit?) -> Double {
        guard !handCards.isEmpty else { return 0.0 }
        let strategy = tuning.turnStrategy

        let regularCards = handCards.compactMap { card -> (suit: Suit, rank: Rank)? in
            guard case .regular(let suit, let rank) = card else { return nil }
            return (suit, rank)
        }
        let suitCounts = Dictionary(grouping: regularCards, by: \.suit).mapValues(\.count)

        var totalPower = 0.0
        for card in handCards {
            if card.isJoker {
                totalPower += strategy.futureJokerPower
                continue
            }

            guard case .regular(let suit, let rank) = card else { continue }

            let rankSpan = Double(Rank.ace.rawValue - Rank.six.rawValue)
            let normalizedRank = Double(rank.rawValue - Rank.six.rawValue) / max(1.0, rankSpan)
            var cardPower = strategy.futureRegularBasePower + normalizedRank * strategy.futureRegularRankWeight

            if let trump, suit == trump {
                cardPower += strategy.futureTrumpBaseBonus + normalizedRank * strategy.futureTrumpRankWeight
            } else if rank.rawValue >= Rank.queen.rawValue {
                cardPower += strategy.futureHighRankBonus
            }

            let suitLength = suitCounts[suit] ?? 0
            if suitLength >= 3 {
                cardPower += strategy.futureLongSuitBonusPerCard * Double(suitLength - 2)
            }

            totalPower += cardPower
        }

        let expected = totalPower * strategy.futureTricksScale
        return min(Double(handCards.count), max(0.0, expected))
    }

    private func expectedRoundScore(
        cardsInRound: Int,
        bid: Int,
        expectedTricks: Double
    ) -> Double {
        let boundedExpected = min(Double(cardsInRound), max(0.0, expectedTricks))
        let floorValue = Int(floor(boundedExpected))
        let ceilValue = min(cardsInRound, floorValue + 1)

        if floorValue == ceilValue {
            return Double(
                ScoreCalculator.calculateRoundScore(
                    cardsInRound: cardsInRound,
                    bid: bid,
                    tricksTaken: floorValue,
                    isBlind: false
                )
            )
        }

        let lowerScore = Double(
            ScoreCalculator.calculateRoundScore(
                cardsInRound: cardsInRound,
                bid: bid,
                tricksTaken: floorValue,
                isBlind: false
            )
        )
        let upperScore = Double(
            ScoreCalculator.calculateRoundScore(
                cardsInRound: cardsInRound,
                bid: bid,
                tricksTaken: ceilValue,
                isBlind: false
            )
        )

        let upperWeight = boundedExpected - Double(floorValue)
        let lowerWeight = 1.0 - upperWeight
        return lowerScore * lowerWeight + upperScore * upperWeight
    }

    private func remainingHand(afterPlaying playedCard: Card, from handCards: [Card]) -> [Card] {
        var remaining = handCards
        if let index = remaining.firstIndex(of: playedCard) {
            remaining.remove(at: index)
        }
        return remaining
    }

    private func unseenCards(excluding handCards: [Card], and playedCards: [Card]) -> [Card] {
        var knownCounts: [Card: Int] = [:]
        for card in handCards + playedCards {
            knownCounts[card, default: 0] += 1
        }

        var unseen: [Card] = []
        for card in Deck().cards {
            let count = knownCounts[card, default: 0]
            if count > 0 {
                knownCounts[card] = count - 1
            } else {
                unseen.append(card)
            }
        }

        return unseen
    }

    private func cardThreat(
        card: Card,
        decision: JokerPlayDecision,
        trump: Suit?,
        trickNode: TrickNode
    ) -> Double {
        let strategy = tuning.turnStrategy
        if card.isJoker {
            if decision.style == .faceDown {
                return trickNode.playedCards.isEmpty
                    ? strategy.threatFaceDownLeadJoker
                    : strategy.threatFaceDownNonLeadJoker
            }

            if trickNode.playedCards.isEmpty {
                switch decision.leadDeclaration {
                case .takes:
                    return strategy.threatLeadTakesJoker
                case .above:
                    return strategy.threatLeadAboveJoker
                case .wish, .none:
                    return strategy.threatLeadWishJoker
                }
            }

            return strategy.threatNonLeadFaceUpJoker
        }

        guard case .regular(let suit, let rank) = card else { return 0.0 }
        var threat = Double(rank.rawValue)
        if let trump, suit == trump {
            threat += strategy.threatTrumpBonus
        }
        if rank.rawValue >= Rank.queen.rawValue {
            threat += strategy.threatHighRankBonus
        }
        return threat
    }

    private func winsTrickRightNow(
        with card: Card,
        decision: JokerPlayDecision,
        trickNode: TrickNode,
        trump: Suit?
    ) -> Bool {
        let simulatedTrick = trickNode.playedCards + [
            PlayedTrickCard(
                playerIndex: -1,
                card: card,
                jokerPlayStyle: decision.style,
                jokerLeadDeclaration: decision.leadDeclaration
            )
        ]

        return TrickTakingResolver.winnerPlayerIndex(
            playedCards: simulatedTrick,
            trump: trump
        ) == -1
    }

    private func cardPower(
        _ card: Card,
        decision: JokerPlayDecision,
        trickNode: TrickNode,
        trump: Suit?
    ) -> Int {
        let strategy = tuning.turnStrategy
        if card.isJoker {
            if decision.style == .faceDown {
                return strategy.powerFaceDownJoker
            }

            if trickNode.playedCards.isEmpty {
                switch decision.leadDeclaration {
                case .takes:
                    return strategy.powerLeadTakesJoker
                case .above:
                    return strategy.powerLeadAboveJoker
                case .wish, .none:
                    return strategy.powerLeadWishJoker
                }
            }

            return strategy.powerNonLeadFaceUpJoker
        }

        guard case .regular(let suit, let rank) = card else { return 0 }
        var value = rank.rawValue

        if let trump, suit == trump {
            value += strategy.powerTrumpBonus
        }
        if let leadSuit = effectiveLeadSuit(in: trickNode), suit == leadSuit {
            value += strategy.powerLeadSuitBonus
        }

        return value
    }

    private func effectiveLeadSuit(in trickNode: TrickNode) -> Suit? {
        guard let leadCard = trickNode.playedCards.first else { return nil }
        if let suit = leadCard.card.suit {
            return suit
        }

        switch leadCard.jokerLeadDeclaration {
        case .above(let suit), .takes(let suit):
            return suit
        case .wish, .none:
            return nil
        }
    }
}


extension BotTuning {
    /// Конфигурация эволюции параметров бота через self-play.
    struct SelfPlayEvolutionConfig {
        let populationSize: Int
        /// Количество seed-сценариев для оценки одного кандидата.
        let gamesPerCandidate: Int
        let generations: Int
        /// Используется только в legacy-режиме (`useFullMatchRules = false`).
        let roundsPerGame: Int
        let playerCount: Int
        /// Используется только в legacy-режиме (`useFullMatchRules = false`).
        let cardsPerRoundRange: ClosedRange<Int>
        let eliteCount: Int
        let mutationChance: Double
        let mutationMagnitude: Double
        let selectionPoolRatio: Double

        /// Включает симуляцию полной партии по блокам (1..4) с премиями и blind.
        let useFullMatchRules: Bool
        /// Для каждого seed кандидат оценивается на всех местах за столом.
        let rotateCandidateAcrossSeats: Bool

        /// Вес win-rate компоненты в fitness.
        let fitnessWinRateWeight: Double
        /// Вес компоненты разницы очков относительно оппонентов.
        let fitnessScoreDiffWeight: Double
        /// Вес компоненты минимизации потерь от недозаказа.
        let fitnessUnderbidLossWeight: Double
        /// Вес компоненты минимизации недозаказа в "козырной плотности".
        let fitnessTrumpDensityUnderbidWeight: Double
        /// Вес компоненты минимизации недозаказа в no-trump контрольных руках.
        let fitnessNoTrumpControlUnderbidWeight: Double
        /// Нормализация score-diff компоненты (чем больше, тем слабее вклад).
        let scoreDiffNormalization: Double
        /// Нормализация underbid-loss компоненты (чем больше, тем слабее вклад).
        let underbidLossNormalization: Double
        /// Нормализация компоненты недозаказа в "козырной плотности".
        let trumpDensityUnderbidNormalization: Double
        /// Нормализация компоненты недозаказа в no-trump контрольных руках.
        let noTrumpControlUnderbidNormalization: Double

        init(
            populationSize: Int = 16,
            generations: Int = 10,
            gamesPerCandidate: Int = 32,
            roundsPerGame: Int = 8,
            playerCount: Int = 4,
            cardsPerRoundRange: ClosedRange<Int> = 3...9,
            eliteCount: Int = 2,
            mutationChance: Double = 0.35,
            mutationMagnitude: Double = 0.18,
            selectionPoolRatio: Double = 0.5,
            useFullMatchRules: Bool = true,
            rotateCandidateAcrossSeats: Bool = true,
            fitnessWinRateWeight: Double = 1.0,
            fitnessScoreDiffWeight: Double = 1.0,
            fitnessUnderbidLossWeight: Double = 0.85,
            fitnessTrumpDensityUnderbidWeight: Double = 0.60,
            fitnessNoTrumpControlUnderbidWeight: Double = 0.70,
            scoreDiffNormalization: Double = 450.0,
            underbidLossNormalization: Double = 6000.0,
            trumpDensityUnderbidNormalization: Double = 2800.0,
            noTrumpControlUnderbidNormalization: Double = 2200.0
        ) {
            let normalizedLowerBound = max(
                1,
                min(cardsPerRoundRange.lowerBound, cardsPerRoundRange.upperBound)
            )
            let normalizedUpperBound = max(
                normalizedLowerBound,
                cardsPerRoundRange.upperBound
            )

            self.populationSize = max(2, populationSize)
            self.generations = max(1, generations)
            self.gamesPerCandidate = max(1, gamesPerCandidate)
            self.roundsPerGame = max(1, roundsPerGame)
            self.playerCount = min(4, max(3, playerCount))
            self.cardsPerRoundRange = normalizedLowerBound...normalizedUpperBound
            self.eliteCount = max(1, eliteCount)
            self.mutationChance = SelfPlayEvolutionConfig.clamp(
                mutationChance,
                to: 0.0...1.0
            )
            self.mutationMagnitude = max(0.0, mutationMagnitude)
            self.selectionPoolRatio = SelfPlayEvolutionConfig.clamp(
                selectionPoolRatio,
                to: 0.2...1.0
            )
            self.useFullMatchRules = useFullMatchRules
            self.rotateCandidateAcrossSeats = rotateCandidateAcrossSeats
            self.fitnessWinRateWeight = max(0.0, fitnessWinRateWeight)
            self.fitnessScoreDiffWeight = max(0.0, fitnessScoreDiffWeight)
            self.fitnessUnderbidLossWeight = max(0.0, fitnessUnderbidLossWeight)
            self.fitnessTrumpDensityUnderbidWeight = max(0.0, fitnessTrumpDensityUnderbidWeight)
            self.fitnessNoTrumpControlUnderbidWeight = max(0.0, fitnessNoTrumpControlUnderbidWeight)
            self.scoreDiffNormalization = max(1.0, scoreDiffNormalization)
            self.underbidLossNormalization = max(1.0, underbidLossNormalization)
            self.trumpDensityUnderbidNormalization = max(1.0, trumpDensityUnderbidNormalization)
            self.noTrumpControlUnderbidNormalization = max(1.0, noTrumpControlUnderbidNormalization)
        }

        private static func clamp(
            _ value: Double,
            to range: ClosedRange<Double>
        ) -> Double {
            return min(max(value, range.lowerBound), range.upperBound)
        }
    }

    /// Результат запуска self-play эволюции.
    struct SelfPlayEvolutionResult {
        let bestTuning: BotTuning
        let baselineFitness: Double
        let bestFitness: Double
        let generationBestFitness: [Double]
        let baselineWinRate: Double
        let bestWinRate: Double
        let baselineAverageScoreDiff: Double
        let bestAverageScoreDiff: Double
        let baselineAverageUnderbidLoss: Double
        let bestAverageUnderbidLoss: Double
        let baselineAverageTrumpDensityUnderbidLoss: Double
        let bestAverageTrumpDensityUnderbidLoss: Double
        let baselineAverageNoTrumpControlUnderbidLoss: Double
        let bestAverageNoTrumpControlUnderbidLoss: Double

        var improvement: Double {
            return bestFitness - baselineFitness
        }
    }

    /// Событие прогресса эволюции self-play.
    struct SelfPlayEvolutionProgress {
        enum Stage {
            case started
            case baselineCompleted
            case generationStarted
            case candidateEvaluated
            case generationCompleted
            case finished
        }

        let stage: Stage
        let generationIndex: Int?
        let totalGenerations: Int
        let evaluatedCandidatesInGeneration: Int?
        let populationSize: Int
        let currentFitness: Double?
        let generationBestFitness: Double?
        let overallBestFitness: Double?
        let completedWorkUnits: Int
        let totalWorkUnits: Int
        let elapsedSeconds: Double
        let estimatedRemainingSeconds: Double?
    }

    /// Запускает эволюционный поиск параметров бота на серии self-play матчей.
    static func evolveViaSelfPlay(
        baseTuning: BotTuning,
        config: SelfPlayEvolutionConfig = SelfPlayEvolutionConfig(),
        seed: UInt64 = 0x5EED,
        progress: ((SelfPlayEvolutionProgress) -> Void)? = nil
    ) -> SelfPlayEvolutionResult {
        let playerCount = min(4, max(3, config.playerCount))
        let deckLimit = max(1, Deck().cards.count / playerCount)
        let lowerCards = min(max(1, config.cardsPerRoundRange.lowerBound), deckLimit)
        let upperCards = min(max(lowerCards, config.cardsPerRoundRange.upperBound), deckLimit)
        let cardsRange = lowerCards...upperCards
        let populationSize = max(config.populationSize, config.eliteCount)
        let eliteCount = min(max(1, config.eliteCount), populationSize)
        let selectionPoolSize = min(
            populationSize,
            max(2, Int((Double(populationSize) * config.selectionPoolRatio).rounded(.up)))
        )

        var rng = SelfPlayRandomGenerator(seed: seed)
        var evaluationSeeds: [UInt64] = []
        evaluationSeeds.reserveCapacity(config.gamesPerCandidate)
        for _ in 0..<config.gamesPerCandidate {
            evaluationSeeds.append(rng.next())
        }

        var population: [EvolutionGenome] = [.identity]
        while population.count < populationSize {
            let randomGenome = randomGenome(
                around: .identity,
                magnitude: max(config.mutationMagnitude, 0.08),
                using: &rng
            )
            population.append(randomGenome)
        }

        let runStartedAt = Date()
        let totalWorkUnits = 1 + config.generations * populationSize
        var completedWorkUnits = 0

        func notifyProgress(
            stage: SelfPlayEvolutionProgress.Stage,
            generationIndex: Int? = nil,
            evaluatedCandidatesInGeneration: Int? = nil,
            currentFitness: Double? = nil,
            generationBestFitness: Double? = nil,
            overallBestFitness: Double? = nil
        ) {
            guard let progress else { return }
            let elapsed = Date().timeIntervalSince(runStartedAt)
            let estimatedRemaining: Double?
            if completedWorkUnits > 0 {
                let averagePerUnit = elapsed / Double(completedWorkUnits)
                let unitsLeft = max(0, totalWorkUnits - completedWorkUnits)
                estimatedRemaining = averagePerUnit * Double(unitsLeft)
            } else {
                estimatedRemaining = nil
            }

            progress(
                SelfPlayEvolutionProgress(
                    stage: stage,
                    generationIndex: generationIndex,
                    totalGenerations: config.generations,
                    evaluatedCandidatesInGeneration: evaluatedCandidatesInGeneration,
                    populationSize: populationSize,
                    currentFitness: currentFitness,
                    generationBestFitness: generationBestFitness,
                    overallBestFitness: overallBestFitness,
                    completedWorkUnits: completedWorkUnits,
                    totalWorkUnits: totalWorkUnits,
                    elapsedSeconds: elapsed,
                    estimatedRemainingSeconds: estimatedRemaining
                )
            )
        }

        notifyProgress(stage: .started)

        let baselineBreakdown = evaluateGenome(
            .identity,
            baseTuning: baseTuning,
            playerCount: playerCount,
            roundsPerGame: config.roundsPerGame,
            cardsPerRoundRange: cardsRange,
            evaluationSeeds: evaluationSeeds,
            useFullMatchRules: config.useFullMatchRules,
            rotateCandidateAcrossSeats: config.rotateCandidateAcrossSeats,
            fitnessWinRateWeight: config.fitnessWinRateWeight,
            fitnessScoreDiffWeight: config.fitnessScoreDiffWeight,
            fitnessUnderbidLossWeight: config.fitnessUnderbidLossWeight,
            fitnessTrumpDensityUnderbidWeight: config.fitnessTrumpDensityUnderbidWeight,
            fitnessNoTrumpControlUnderbidWeight: config.fitnessNoTrumpControlUnderbidWeight,
            scoreDiffNormalization: config.scoreDiffNormalization,
            underbidLossNormalization: config.underbidLossNormalization,
            trumpDensityUnderbidNormalization: config.trumpDensityUnderbidNormalization,
            noTrumpControlUnderbidNormalization: config.noTrumpControlUnderbidNormalization
        )
        completedWorkUnits += 1
        notifyProgress(
            stage: .baselineCompleted,
            currentFitness: baselineBreakdown.fitness,
            generationBestFitness: baselineBreakdown.fitness,
            overallBestFitness: baselineBreakdown.fitness
        )

        var bestGenome = EvolutionGenome.identity
        var bestBreakdown = baselineBreakdown
        var generationBestFitness: [Double] = []
        generationBestFitness.reserveCapacity(config.generations)

        for generation in 0..<config.generations {
            notifyProgress(
                stage: .generationStarted,
                generationIndex: generation,
                overallBestFitness: bestBreakdown.fitness
            )
            let generationSeedMask = UInt64(generation + 1) &* 0x9E37_79B9_7F4A_7C15
            let generationSeeds = evaluationSeeds.map { $0 ^ generationSeedMask }

            var scoredPopulation: [ScoredGenome] = []
            scoredPopulation.reserveCapacity(populationSize)
            var generationBestFitnessSoFar: Double?

            for (candidateOffset, genome) in population.enumerated() {
                let breakdown = evaluateGenome(
                    genome,
                    baseTuning: baseTuning,
                    playerCount: playerCount,
                    roundsPerGame: config.roundsPerGame,
                    cardsPerRoundRange: cardsRange,
                    evaluationSeeds: generationSeeds,
                    useFullMatchRules: config.useFullMatchRules,
                    rotateCandidateAcrossSeats: config.rotateCandidateAcrossSeats,
                    fitnessWinRateWeight: config.fitnessWinRateWeight,
                    fitnessScoreDiffWeight: config.fitnessScoreDiffWeight,
                    fitnessUnderbidLossWeight: config.fitnessUnderbidLossWeight,
                    fitnessTrumpDensityUnderbidWeight: config.fitnessTrumpDensityUnderbidWeight,
                    fitnessNoTrumpControlUnderbidWeight: config.fitnessNoTrumpControlUnderbidWeight,
                    scoreDiffNormalization: config.scoreDiffNormalization,
                    underbidLossNormalization: config.underbidLossNormalization,
                    trumpDensityUnderbidNormalization: config.trumpDensityUnderbidNormalization,
                    noTrumpControlUnderbidNormalization: config.noTrumpControlUnderbidNormalization
                )
                scoredPopulation.append(
                    ScoredGenome(
                        genome: genome,
                        breakdown: breakdown
                    )
                )

                completedWorkUnits += 1
                generationBestFitnessSoFar = max(generationBestFitnessSoFar ?? breakdown.fitness, breakdown.fitness)
                let overallBestSoFar = max(bestBreakdown.fitness, generationBestFitnessSoFar ?? breakdown.fitness)
                notifyProgress(
                    stage: .candidateEvaluated,
                    generationIndex: generation,
                    evaluatedCandidatesInGeneration: candidateOffset + 1,
                    currentFitness: breakdown.fitness,
                    generationBestFitness: generationBestFitnessSoFar,
                    overallBestFitness: overallBestSoFar
                )
            }

            scoredPopulation.sort(by: { (lhs: ScoredGenome, rhs: ScoredGenome) -> Bool in
                    if lhs.breakdown.fitness == rhs.breakdown.fitness {
                        return isLexicographicallySmaller(
                            lhs.genome.lexicographicKey,
                            than: rhs.genome.lexicographicKey
                        )
                    }
                    return lhs.breakdown.fitness > rhs.breakdown.fitness
                })

            guard let generationBest = scoredPopulation.first else { continue }
            generationBestFitness.append(generationBest.breakdown.fitness)

            if generationBest.breakdown.fitness > bestBreakdown.fitness {
                bestBreakdown = generationBest.breakdown
                bestGenome = generationBest.genome
            }
            notifyProgress(
                stage: .generationCompleted,
                generationIndex: generation,
                generationBestFitness: generationBest.breakdown.fitness,
                overallBestFitness: bestBreakdown.fitness
            )

            guard generation + 1 < config.generations else { continue }

            var nextPopulation: [EvolutionGenome] = scoredPopulation
                .prefix(eliteCount)
                .map { $0.genome }

            while nextPopulation.count < populationSize {
                let firstParent = scoredPopulation[
                    Int.random(in: 0..<selectionPoolSize, using: &rng)
                ].genome
                let secondParent = scoredPopulation[
                    Int.random(in: 0..<selectionPoolSize, using: &rng)
                ].genome

                let crossoverChild = crossover(firstParent, secondParent, using: &rng)
                let mutatedChild = mutateGenome(
                    crossoverChild,
                    chance: config.mutationChance,
                    magnitude: config.mutationMagnitude,
                    using: &rng
                )
                nextPopulation.append(mutatedChild)
            }

            population = nextPopulation
        }

        let bestTuning = tuning(byApplying: bestGenome, to: baseTuning)
        notifyProgress(
            stage: .finished,
            overallBestFitness: bestBreakdown.fitness
        )
        return SelfPlayEvolutionResult(
            bestTuning: bestTuning,
            baselineFitness: baselineBreakdown.fitness,
            bestFitness: bestBreakdown.fitness,
            generationBestFitness: generationBestFitness,
            baselineWinRate: baselineBreakdown.winRate,
            bestWinRate: bestBreakdown.winRate,
            baselineAverageScoreDiff: baselineBreakdown.averageScoreDiff,
            bestAverageScoreDiff: bestBreakdown.averageScoreDiff,
            baselineAverageUnderbidLoss: baselineBreakdown.averageUnderbidLoss,
            bestAverageUnderbidLoss: bestBreakdown.averageUnderbidLoss,
            baselineAverageTrumpDensityUnderbidLoss: baselineBreakdown.averageTrumpDensityUnderbidLoss,
            bestAverageTrumpDensityUnderbidLoss: bestBreakdown.averageTrumpDensityUnderbidLoss,
            baselineAverageNoTrumpControlUnderbidLoss: baselineBreakdown.averageNoTrumpControlUnderbidLoss,
            bestAverageNoTrumpControlUnderbidLoss: bestBreakdown.averageNoTrumpControlUnderbidLoss
        )
    }

    private struct ScoredGenome {
        let genome: EvolutionGenome
        let breakdown: FitnessBreakdown
    }

    private struct FitnessBreakdown {
        let fitness: Double
        let winRate: Double
        let averageScoreDiff: Double
        let averageUnderbidLoss: Double
        let averageTrumpDensityUnderbidLoss: Double
        let averageNoTrumpControlUnderbidLoss: Double

        static let zero = FitnessBreakdown(
            fitness: 0.0,
            winRate: 0.0,
            averageScoreDiff: 0.0,
            averageUnderbidLoss: 0.0,
            averageTrumpDensityUnderbidLoss: 0.0,
            averageNoTrumpControlUnderbidLoss: 0.0
        )
    }

    private struct EvolutionGenome {
        var chaseWinProbabilityScale: Double
        var chaseThreatPenaltyScale: Double
        var chaseSpendJokerPenaltyScale: Double
        var dumpAvoidWinScale: Double
        var dumpThreatRewardScale: Double
        var dumpSpendJokerPenaltyScale: Double
        var holdDistributionScale: Double
        var futureTricksScale: Double
        var futureJokerPowerScale: Double
        var threatPreservationScale: Double

        var biddingJokerPowerScale: Double
        var biddingRankWeightScale: Double
        var biddingTrumpBaseBonusScale: Double
        var biddingTrumpRankWeightScale: Double
        var biddingHighRankBonusScale: Double
        var biddingLongSuitBonusScale: Double
        var biddingTrumpDensityBonusScale: Double
        var biddingNoTrumpHighCardBonusScale: Double
        var biddingNoTrumpJokerSynergyScale: Double

        var trumpCardBasePowerScale: Double
        var trumpThresholdScale: Double

        static let identity = EvolutionGenome(
            chaseWinProbabilityScale: 1.0,
            chaseThreatPenaltyScale: 1.0,
            chaseSpendJokerPenaltyScale: 1.0,
            dumpAvoidWinScale: 1.0,
            dumpThreatRewardScale: 1.0,
            dumpSpendJokerPenaltyScale: 1.0,
            holdDistributionScale: 1.0,
            futureTricksScale: 1.0,
            futureJokerPowerScale: 1.0,
            threatPreservationScale: 1.0,
            biddingJokerPowerScale: 1.0,
            biddingRankWeightScale: 1.0,
            biddingTrumpBaseBonusScale: 1.0,
            biddingTrumpRankWeightScale: 1.0,
            biddingHighRankBonusScale: 1.0,
            biddingLongSuitBonusScale: 1.0,
            biddingTrumpDensityBonusScale: 1.0,
            biddingNoTrumpHighCardBonusScale: 1.0,
            biddingNoTrumpJokerSynergyScale: 1.0,
            trumpCardBasePowerScale: 1.0,
            trumpThresholdScale: 1.0
        )

        var lexicographicKey: [Double] {
            return [
                chaseWinProbabilityScale,
                chaseThreatPenaltyScale,
                chaseSpendJokerPenaltyScale,
                dumpAvoidWinScale,
                dumpThreatRewardScale,
                dumpSpendJokerPenaltyScale,
                holdDistributionScale,
                futureTricksScale,
                futureJokerPowerScale,
                threatPreservationScale,
                biddingJokerPowerScale,
                biddingRankWeightScale,
                biddingTrumpBaseBonusScale,
                biddingTrumpRankWeightScale,
                biddingHighRankBonusScale,
                biddingLongSuitBonusScale,
                biddingTrumpDensityBonusScale,
                biddingNoTrumpHighCardBonusScale,
                biddingNoTrumpJokerSynergyScale,
                trumpCardBasePowerScale,
                trumpThresholdScale
            ]
        }
    }

    private struct SelfPlayRandomGenerator: RandomNumberGenerator {
        private var state: UInt64

        init(seed: UInt64) {
            state = seed == 0 ? 0xA409_3822_299F_31D0 : seed
        }

        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15

            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }

        mutating func nextUnit() -> Double {
            let bits = next() >> 11
            let max53 = Double(1 << 53)
            return Double(bits) / max53
        }
    }

    private struct PreDealBlindContext {
        let lockedBids: [Int]
        let blindSelections: [Bool]
    }

    private struct SimulatedGameOutcome {
        let totalScores: [Int]
        let underbidLosses: [Double]
        let trumpDensityUnderbidLosses: [Double]
        let noTrumpControlUnderbidLosses: [Double]
    }

    private static func randomGenome(
        around base: EvolutionGenome,
        magnitude: Double,
        using rng: inout SelfPlayRandomGenerator
    ) -> EvolutionGenome {
        return EvolutionGenome(
            chaseWinProbabilityScale: randomizedScale(
                base.chaseWinProbabilityScale,
                magnitude: magnitude,
                range: 0.50...1.80,
                using: &rng
            ),
            chaseThreatPenaltyScale: randomizedScale(
                base.chaseThreatPenaltyScale,
                magnitude: magnitude,
                range: 0.45...1.90,
                using: &rng
            ),
            chaseSpendJokerPenaltyScale: randomizedScale(
                base.chaseSpendJokerPenaltyScale,
                magnitude: magnitude,
                range: 0.45...1.90,
                using: &rng
            ),
            dumpAvoidWinScale: randomizedScale(
                base.dumpAvoidWinScale,
                magnitude: magnitude,
                range: 0.50...1.80,
                using: &rng
            ),
            dumpThreatRewardScale: randomizedScale(
                base.dumpThreatRewardScale,
                magnitude: magnitude,
                range: 0.50...1.90,
                using: &rng
            ),
            dumpSpendJokerPenaltyScale: randomizedScale(
                base.dumpSpendJokerPenaltyScale,
                magnitude: magnitude,
                range: 0.45...1.90,
                using: &rng
            ),
            holdDistributionScale: randomizedScale(
                base.holdDistributionScale,
                magnitude: magnitude,
                range: 0.70...1.20,
                using: &rng
            ),
            futureTricksScale: randomizedScale(
                base.futureTricksScale,
                magnitude: magnitude,
                range: 0.55...1.60,
                using: &rng
            ),
            futureJokerPowerScale: randomizedScale(
                base.futureJokerPowerScale,
                magnitude: magnitude,
                range: 0.55...1.70,
                using: &rng
            ),
            threatPreservationScale: randomizedScale(
                base.threatPreservationScale,
                magnitude: magnitude,
                range: 0.55...1.70,
                using: &rng
            ),
            biddingJokerPowerScale: randomizedScale(
                base.biddingJokerPowerScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...4.00,
                using: &rng
            ),
            biddingRankWeightScale: randomizedScale(
                base.biddingRankWeightScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...12.00,
                using: &rng
            ),
            biddingTrumpBaseBonusScale: randomizedScale(
                base.biddingTrumpBaseBonusScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...12.00,
                using: &rng
            ),
            biddingTrumpRankWeightScale: randomizedScale(
                base.biddingTrumpRankWeightScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...12.00,
                using: &rng
            ),
            biddingHighRankBonusScale: randomizedScale(
                base.biddingHighRankBonusScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...15.00,
                using: &rng
            ),
            biddingLongSuitBonusScale: randomizedScale(
                base.biddingLongSuitBonusScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...15.00,
                using: &rng
            ),
            biddingTrumpDensityBonusScale: randomizedScale(
                base.biddingTrumpDensityBonusScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...15.00,
                using: &rng
            ),
            biddingNoTrumpHighCardBonusScale: randomizedScale(
                base.biddingNoTrumpHighCardBonusScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...15.00,
                using: &rng
            ),
            biddingNoTrumpJokerSynergyScale: randomizedScale(
                base.biddingNoTrumpJokerSynergyScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...15.00,
                using: &rng
            ),
            trumpCardBasePowerScale: randomizedScale(
                base.trumpCardBasePowerScale,
                magnitude: magnitude,
                range: 0.50...1.65,
                using: &rng
            ),
            trumpThresholdScale: randomizedScale(
                base.trumpThresholdScale,
                magnitude: magnitude,
                range: 0.55...1.65,
                using: &rng
            )
        )
    }

    private static func crossover(
        _ first: EvolutionGenome,
        _ second: EvolutionGenome,
        using rng: inout SelfPlayRandomGenerator
    ) -> EvolutionGenome {
        return EvolutionGenome(
            chaseWinProbabilityScale: mixedScale(
                first.chaseWinProbabilityScale,
                second.chaseWinProbabilityScale,
                range: 0.50...1.80,
                using: &rng
            ),
            chaseThreatPenaltyScale: mixedScale(
                first.chaseThreatPenaltyScale,
                second.chaseThreatPenaltyScale,
                range: 0.45...1.90,
                using: &rng
            ),
            chaseSpendJokerPenaltyScale: mixedScale(
                first.chaseSpendJokerPenaltyScale,
                second.chaseSpendJokerPenaltyScale,
                range: 0.45...1.90,
                using: &rng
            ),
            dumpAvoidWinScale: mixedScale(
                first.dumpAvoidWinScale,
                second.dumpAvoidWinScale,
                range: 0.50...1.80,
                using: &rng
            ),
            dumpThreatRewardScale: mixedScale(
                first.dumpThreatRewardScale,
                second.dumpThreatRewardScale,
                range: 0.50...1.90,
                using: &rng
            ),
            dumpSpendJokerPenaltyScale: mixedScale(
                first.dumpSpendJokerPenaltyScale,
                second.dumpSpendJokerPenaltyScale,
                range: 0.45...1.90,
                using: &rng
            ),
            holdDistributionScale: mixedScale(
                first.holdDistributionScale,
                second.holdDistributionScale,
                range: 0.70...1.20,
                using: &rng
            ),
            futureTricksScale: mixedScale(
                first.futureTricksScale,
                second.futureTricksScale,
                range: 0.55...1.60,
                using: &rng
            ),
            futureJokerPowerScale: mixedScale(
                first.futureJokerPowerScale,
                second.futureJokerPowerScale,
                range: 0.55...1.70,
                using: &rng
            ),
            threatPreservationScale: mixedScale(
                first.threatPreservationScale,
                second.threatPreservationScale,
                range: 0.55...1.70,
                using: &rng
            ),
            biddingJokerPowerScale: mixedScale(
                first.biddingJokerPowerScale,
                second.biddingJokerPowerScale,
                range: 0.35...4.00,
                using: &rng
            ),
            biddingRankWeightScale: mixedScale(
                first.biddingRankWeightScale,
                second.biddingRankWeightScale,
                range: 0.35...12.00,
                using: &rng
            ),
            biddingTrumpBaseBonusScale: mixedScale(
                first.biddingTrumpBaseBonusScale,
                second.biddingTrumpBaseBonusScale,
                range: 0.35...12.00,
                using: &rng
            ),
            biddingTrumpRankWeightScale: mixedScale(
                first.biddingTrumpRankWeightScale,
                second.biddingTrumpRankWeightScale,
                range: 0.35...12.00,
                using: &rng
            ),
            biddingHighRankBonusScale: mixedScale(
                first.biddingHighRankBonusScale,
                second.biddingHighRankBonusScale,
                range: 0.35...15.00,
                using: &rng
            ),
            biddingLongSuitBonusScale: mixedScale(
                first.biddingLongSuitBonusScale,
                second.biddingLongSuitBonusScale,
                range: 0.35...15.00,
                using: &rng
            ),
            biddingTrumpDensityBonusScale: mixedScale(
                first.biddingTrumpDensityBonusScale,
                second.biddingTrumpDensityBonusScale,
                range: 0.35...15.00,
                using: &rng
            ),
            biddingNoTrumpHighCardBonusScale: mixedScale(
                first.biddingNoTrumpHighCardBonusScale,
                second.biddingNoTrumpHighCardBonusScale,
                range: 0.35...15.00,
                using: &rng
            ),
            biddingNoTrumpJokerSynergyScale: mixedScale(
                first.biddingNoTrumpJokerSynergyScale,
                second.biddingNoTrumpJokerSynergyScale,
                range: 0.35...15.00,
                using: &rng
            ),
            trumpCardBasePowerScale: mixedScale(
                first.trumpCardBasePowerScale,
                second.trumpCardBasePowerScale,
                range: 0.50...1.65,
                using: &rng
            ),
            trumpThresholdScale: mixedScale(
                first.trumpThresholdScale,
                second.trumpThresholdScale,
                range: 0.55...1.65,
                using: &rng
            )
        )
    }

    private static func mutateGenome(
        _ genome: EvolutionGenome,
        chance: Double,
        magnitude: Double,
        using rng: inout SelfPlayRandomGenerator
    ) -> EvolutionGenome {
        var mutated = genome
        mutateScale(
            &mutated.chaseWinProbabilityScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.50...1.80,
            using: &rng
        )
        mutateScale(
            &mutated.chaseThreatPenaltyScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.45...1.90,
            using: &rng
        )
        mutateScale(
            &mutated.chaseSpendJokerPenaltyScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.45...1.90,
            using: &rng
        )
        mutateScale(
            &mutated.dumpAvoidWinScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.50...1.80,
            using: &rng
        )
        mutateScale(
            &mutated.dumpThreatRewardScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.50...1.90,
            using: &rng
        )
        mutateScale(
            &mutated.dumpSpendJokerPenaltyScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.45...1.90,
            using: &rng
        )
        mutateScale(
            &mutated.holdDistributionScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.70...1.20,
            using: &rng
        )
        mutateScale(
            &mutated.futureTricksScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.55...1.60,
            using: &rng
        )
        mutateScale(
            &mutated.futureJokerPowerScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.55...1.70,
            using: &rng
        )
        mutateScale(
            &mutated.threatPreservationScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.55...1.70,
            using: &rng
        )
        mutateScale(
            &mutated.biddingJokerPowerScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...4.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingRankWeightScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...12.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingTrumpBaseBonusScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...12.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingTrumpRankWeightScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...12.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingHighRankBonusScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...15.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingLongSuitBonusScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...15.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingTrumpDensityBonusScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...15.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingNoTrumpHighCardBonusScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...15.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingNoTrumpJokerSynergyScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...15.00,
            using: &rng
        )
        mutateScale(
            &mutated.trumpCardBasePowerScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.50...1.65,
            using: &rng
        )
        mutateScale(
            &mutated.trumpThresholdScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.55...1.65,
            using: &rng
        )

        return mutated
    }

    private static func evaluateGenome(
        _ genome: EvolutionGenome,
        baseTuning: BotTuning,
        playerCount: Int,
        roundsPerGame: Int,
        cardsPerRoundRange: ClosedRange<Int>,
        evaluationSeeds: [UInt64],
        useFullMatchRules: Bool,
        rotateCandidateAcrossSeats: Bool,
        fitnessWinRateWeight: Double,
        fitnessScoreDiffWeight: Double,
        fitnessUnderbidLossWeight: Double,
        fitnessTrumpDensityUnderbidWeight: Double,
        fitnessNoTrumpControlUnderbidWeight: Double,
        scoreDiffNormalization: Double,
        underbidLossNormalization: Double,
        trumpDensityUnderbidNormalization: Double,
        noTrumpControlUnderbidNormalization: Double
    ) -> FitnessBreakdown {
        guard !evaluationSeeds.isEmpty else { return .zero }

        let candidateTuning = tuning(byApplying: genome, to: baseTuning)
        let candidateSeats: [Int] = rotateCandidateAcrossSeats
            ? Array(0..<playerCount)
            : [0]

        var totalWinRate = 0.0
        var totalScoreDiff = 0.0
        var totalCandidateUnderbidLoss = 0.0
        var totalCandidateTrumpDensityUnderbidLoss = 0.0
        var totalCandidateNoTrumpControlUnderbidLoss = 0.0
        var simulationsCount = 0

        for evaluationSeed in evaluationSeeds {
            for candidateSeat in candidateSeats {
                var tuningsBySeat = Array(repeating: baseTuning, count: playerCount)
                tuningsBySeat[candidateSeat] = candidateTuning

                let gameOutcome = simulateGame(
                    tuningsBySeat: tuningsBySeat,
                    rounds: roundsPerGame,
                    cardsPerRoundRange: cardsPerRoundRange,
                    seed: evaluationSeed,
                    useFullMatchRules: useFullMatchRules
                )

                let totalScores = gameOutcome.totalScores
                guard totalScores.indices.contains(candidateSeat) else { continue }
                let candidateScore = totalScores[candidateSeat]
                let opponentsTotal = totalScores.reduce(0, +) - candidateScore
                let opponentsAverage = Double(opponentsTotal) / Double(max(1, playerCount - 1))
                let candidateUnderbidLoss = gameOutcome.underbidLosses.indices.contains(candidateSeat)
                    ? gameOutcome.underbidLosses[candidateSeat]
                    : 0.0
                let candidateTrumpDensityUnderbidLoss = gameOutcome.trumpDensityUnderbidLosses.indices.contains(candidateSeat)
                    ? gameOutcome.trumpDensityUnderbidLosses[candidateSeat]
                    : 0.0
                let candidateNoTrumpControlUnderbidLoss = gameOutcome.noTrumpControlUnderbidLosses.indices.contains(candidateSeat)
                    ? gameOutcome.noTrumpControlUnderbidLosses[candidateSeat]
                    : 0.0

                let maxScore = totalScores.max() ?? candidateScore
                let winnersCount = max(1, totalScores.filter { $0 == maxScore }.count)
                let winShare = candidateScore == maxScore ? 1.0 / Double(winnersCount) : 0.0

                totalWinRate += winShare
                totalScoreDiff += Double(candidateScore) - opponentsAverage
                totalCandidateUnderbidLoss += candidateUnderbidLoss
                totalCandidateTrumpDensityUnderbidLoss += candidateTrumpDensityUnderbidLoss
                totalCandidateNoTrumpControlUnderbidLoss += candidateNoTrumpControlUnderbidLoss
                simulationsCount += 1
            }
        }

        guard simulationsCount > 0 else { return .zero }

        let averageWinRate = totalWinRate / Double(simulationsCount)
        let averageScoreDiff = totalScoreDiff / Double(simulationsCount)
        let averageUnderbidLoss = totalCandidateUnderbidLoss / Double(simulationsCount)
        let averageTrumpDensityUnderbidLoss = totalCandidateTrumpDensityUnderbidLoss / Double(simulationsCount)
        let averageNoTrumpControlUnderbidLoss = totalCandidateNoTrumpControlUnderbidLoss / Double(simulationsCount)
        let fitness = averageWinRate * fitnessWinRateWeight +
            (averageScoreDiff / scoreDiffNormalization) * fitnessScoreDiffWeight +
            -(averageUnderbidLoss / underbidLossNormalization) * fitnessUnderbidLossWeight +
            -(averageTrumpDensityUnderbidLoss / trumpDensityUnderbidNormalization) * fitnessTrumpDensityUnderbidWeight +
            -(averageNoTrumpControlUnderbidLoss / noTrumpControlUnderbidNormalization) * fitnessNoTrumpControlUnderbidWeight

        return FitnessBreakdown(
            fitness: fitness,
            winRate: averageWinRate,
            averageScoreDiff: averageScoreDiff,
            averageUnderbidLoss: averageUnderbidLoss,
            averageTrumpDensityUnderbidLoss: averageTrumpDensityUnderbidLoss,
            averageNoTrumpControlUnderbidLoss: averageNoTrumpControlUnderbidLoss
        )
    }

    private static func simulateGame(
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

        let turnServices = tuningsBySeat.map { BotTurnStrategyService(tuning: $0) }
        let biddingServices = tuningsBySeat.map { BotBiddingService(tuning: $0) }
        let trumpServices = tuningsBySeat.map { BotTrumpSelectionService(tuning: $0) }

        var totalScores = Array(repeating: 0, count: playerCount)
        var underbidLosses = Array(repeating: 0.0, count: playerCount)
        var trumpDensityUnderbidLosses = Array(repeating: 0.0, count: playerCount)
        var noTrumpControlUnderbidLosses = Array(repeating: 0.0, count: playerCount)
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
            let trump = trumpServices[trumpChooser].selectTrump(from: hands[trumpChooser])
            let bids = makeBids(
                hands: hands,
                dealer: dealer,
                cardsInRound: cardsInRound,
                trump: trump,
                biddingServices: biddingServices
            )
            let tricksTaken = playRound(
                hands: hands,
                bids: bids,
                dealer: dealer,
                cardsInRound: cardsInRound,
                trump: trump,
                turnServices: turnServices
            )

            for playerIndex in 0..<playerCount {
                let roundScore = ScoreCalculator.calculateRoundScore(
                    cardsInRound: cardsInRound,
                    bid: bids[playerIndex],
                    tricksTaken: tricksTaken[playerIndex],
                    isBlind: false
                )
                totalScores[playerIndex] += roundScore
                underbidLosses[playerIndex] += underbidLoss(
                    cardsInRound: cardsInRound,
                    bid: bids[playerIndex],
                    tricksTaken: tricksTaken[playerIndex],
                    isBlind: false
                )
                underbidLosses[playerIndex] += jokerBidFloorUnderbidPenalty(
                    hand: hands[playerIndex],
                    bid: bids[playerIndex]
                )
                trumpDensityUnderbidLosses[playerIndex] += trumpDensityUnderbidPenalty(
                    hand: hands[playerIndex],
                    bid: bids[playerIndex],
                    cardsInRound: cardsInRound,
                    trump: trump
                )
                noTrumpControlUnderbidLosses[playerIndex] += noTrumpControlUnderbidPenalty(
                    hand: hands[playerIndex],
                    bid: bids[playerIndex],
                    cardsInRound: cardsInRound,
                    trump: trump,
                    emphasisMultiplier: 0.75
                )
            }

            dealer = normalizedPlayerIndex(dealer + 1, playerCount: playerCount)
        }

        return SimulatedGameOutcome(
            totalScores: totalScores,
            underbidLosses: underbidLosses,
            trumpDensityUnderbidLosses: trumpDensityUnderbidLosses,
            noTrumpControlUnderbidLosses: noTrumpControlUnderbidLosses
        )
    }

    private static func simulateFullMatch(
        tuningsBySeat: [BotTuning],
        seed: UInt64
    ) -> SimulatedGameOutcome {
        let playerCount = tuningsBySeat.count
        var rng = SelfPlayRandomGenerator(seed: seed)

        let turnServices = tuningsBySeat.map { BotTurnStrategyService(tuning: $0) }
        let biddingServices = tuningsBySeat.map { BotBiddingService(tuning: $0) }
        let trumpServices = tuningsBySeat.map { BotTrumpSelectionService(tuning: $0) }

        let blockDeals = GameConstants.allBlockDeals(playerCount: playerCount)

        var totalScores = Array(repeating: 0, count: playerCount)
        var underbidLosses = Array(repeating: 0.0, count: playerCount)
        var trumpDensityUnderbidLosses = Array(repeating: 0.0, count: playerCount)
        var noTrumpControlUnderbidLosses = Array(repeating: 0.0, count: playerCount)
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
                    trumpServices: trumpServices,
                    using: &rng
                )
                let hands = roundDeal.hands
                let trump = roundDeal.trump

                let totalsIncludingCurrentBlock = (0..<playerCount).map { index in
                    totalScores[index] + blockBaseScores[index]
                }

                let blindContext: PreDealBlindContext
                if blockNumber == GameBlock.fourth.rawValue {
                    blindContext = resolvePreDealBlindContext(
                        dealer: dealer,
                        cardsInRound: cardsInRound,
                        playerCount: playerCount,
                        biddingServices: biddingServices,
                        totalScoresIncludingCurrentBlock: totalsIncludingCurrentBlock
                    )
                } else {
                    blindContext = PreDealBlindContext(
                        lockedBids: Array(repeating: 0, count: playerCount),
                        blindSelections: Array(repeating: false, count: playerCount)
                    )
                }

                let bids = makeBids(
                    hands: hands,
                    dealer: dealer,
                    cardsInRound: cardsInRound,
                    trump: trump,
                    biddingServices: biddingServices,
                    preLockedBids: blindContext.lockedBids,
                    blindSelections: blindContext.blindSelections
                )
                let tricksTaken = playRound(
                    hands: hands,
                    bids: bids,
                    dealer: dealer,
                    cardsInRound: cardsInRound,
                    trump: trump,
                    turnServices: turnServices
                )

                for playerIndex in 0..<playerCount {
                    let isBlind = blindContext.blindSelections.indices.contains(playerIndex)
                        ? blindContext.blindSelections[playerIndex]
                        : false
                    let roundResult = RoundResult(
                        cardsInRound: cardsInRound,
                        bid: bids[playerIndex],
                        tricksTaken: tricksTaken[playerIndex],
                        isBlind: isBlind
                    )
                    blockRoundResults[playerIndex].append(roundResult)
                    blockBaseScores[playerIndex] += roundResult.score
                    underbidLosses[playerIndex] += underbidLoss(
                        cardsInRound: cardsInRound,
                        bid: bids[playerIndex],
                        tricksTaken: tricksTaken[playerIndex],
                        isBlind: isBlind
                    )
                    underbidLosses[playerIndex] += jokerBidFloorUnderbidPenalty(
                        hand: hands[playerIndex],
                        bid: bids[playerIndex]
                    )
                    trumpDensityUnderbidLosses[playerIndex] += trumpDensityUnderbidPenalty(
                        hand: hands[playerIndex],
                        bid: bids[playerIndex],
                        cardsInRound: cardsInRound,
                        trump: trump
                    )
                    noTrumpControlUnderbidLosses[playerIndex] += noTrumpControlUnderbidPenalty(
                        hand: hands[playerIndex],
                        bid: bids[playerIndex],
                        cardsInRound: cardsInRound,
                        trump: trump,
                        emphasisMultiplier: (blockNumber == GameBlock.first.rawValue ||
                            blockNumber == GameBlock.third.rawValue) ? 1.0 : 0.55
                    )
                }

                dealer = normalizedPlayerIndex(dealer + 1, playerCount: playerCount)
            }

            let finalizedBlockScores = finalizeBlockScores(
                blockRoundResults: blockRoundResults,
                blockNumber: blockNumber,
                playerCount: playerCount
            )
            for playerIndex in 0..<playerCount {
                totalScores[playerIndex] += finalizedBlockScores[playerIndex]
            }
        }

        return SimulatedGameOutcome(
            totalScores: totalScores,
            underbidLosses: underbidLosses,
            trumpDensityUnderbidLosses: trumpDensityUnderbidLosses,
            noTrumpControlUnderbidLosses: noTrumpControlUnderbidLosses
        )
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
        }

        return PreDealBlindContext(
            lockedBids: lockedBids,
            blindSelections: blindSelections
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
        bid: Int
    ) -> Double {
        let jokerCount = hand.reduce(0) { partial, card in
            partial + (card.isJoker ? 1 : 0)
        }
        let deficit = max(0, jokerCount - max(0, bid))
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

    private static func finalizeBlockScores(
        blockRoundResults: [[RoundResult]],
        blockNumber: Int,
        playerCount: Int
    ) -> [Int] {
        guard playerCount > 0 else { return [] }

        let allPremiumPlayers = (0..<playerCount).filter { playerIndex in
            let results = blockRoundResults.indices.contains(playerIndex)
                ? blockRoundResults[playerIndex]
                : []
            guard !results.isEmpty else { return false }
            return results.allSatisfy(\.bidMatched)
        }

        let zeroPremiumPlayers: [Int]
        if blockNumber == GameBlock.first.rawValue || blockNumber == GameBlock.third.rawValue {
            zeroPremiumPlayers = allPremiumPlayers.filter { playerIndex in
                let results = blockRoundResults.indices.contains(playerIndex)
                    ? blockRoundResults[playerIndex]
                    : []
                return ScoreCalculator.isZeroPremiumEligible(roundResults: results)
            }
        } else {
            zeroPremiumPlayers = []
        }

        let zeroPremiumSet = Set(zeroPremiumPlayers)
        let regularPremiumPlayers = allPremiumPlayers.filter { !zeroPremiumSet.contains($0) }

        var premiumBonuses = Array(repeating: 0, count: playerCount)
        var zeroPremiumBonuses = Array(repeating: 0, count: playerCount)
        var premiumPenalties = Array(repeating: 0, count: playerCount)

        for playerIndex in regularPremiumPlayers {
            let roundScores = blockRoundResults[playerIndex].map(\.score)
            premiumBonuses[playerIndex] = ScoreCalculator.calculatePremiumBonus(roundScores: roundScores)
        }

        for playerIndex in zeroPremiumPlayers {
            zeroPremiumBonuses[playerIndex] = ScoreCalculator.zeroPremiumAmount
        }

        let premiumSet = Set(allPremiumPlayers)
        for playerIndex in allPremiumPlayers {
            guard let penaltyTarget = findPenaltyTarget(
                for: playerIndex,
                premiumPlayers: premiumSet,
                playerCount: playerCount
            ) else {
                continue
            }
            let targetRoundScores = blockRoundResults[penaltyTarget].map(\.score)
            premiumPenalties[penaltyTarget] += ScoreCalculator.calculatePremiumPenalty(
                roundScores: targetRoundScores
            )
        }

        var roundsWithPremiums = blockRoundResults
        for playerIndex in 0..<playerCount {
            guard roundsWithPremiums.indices.contains(playerIndex) else { continue }
            guard !roundsWithPremiums[playerIndex].isEmpty else { continue }

            let bonus = premiumBonuses[playerIndex] + zeroPremiumBonuses[playerIndex]
            guard bonus != 0 else { continue }

            let lastRoundIndex = roundsWithPremiums[playerIndex].count - 1
            let lastRound = roundsWithPremiums[playerIndex][lastRoundIndex]
            roundsWithPremiums[playerIndex][lastRoundIndex] = lastRound.addingScoreAdjustment(bonus)
        }

        let baseBlockScores = (0..<playerCount).map { playerIndex in
            guard roundsWithPremiums.indices.contains(playerIndex) else { return 0 }
            return roundsWithPremiums[playerIndex].reduce(0) { $0 + $1.score }
        }

        return (0..<playerCount).map { playerIndex in
            baseBlockScores[playerIndex] - premiumPenalties[playerIndex]
        }
    }

    private static func findPenaltyTarget(
        for playerIndex: Int,
        premiumPlayers: Set<Int>,
        playerCount: Int
    ) -> Int? {
        guard playerCount > 1 else { return nil }

        var candidate = leftNeighbor(of: playerIndex, playerCount: playerCount)
        var checked = 0

        while checked < playerCount - 1 {
            if !premiumPlayers.contains(candidate) {
                return candidate
            }
            candidate = leftNeighbor(of: candidate, playerCount: playerCount)
            checked += 1
        }

        return nil
    }

    private static func leftNeighbor(of playerIndex: Int, playerCount: Int) -> Int {
        guard playerCount > 0 else { return 0 }
        return (playerIndex + 1) % playerCount
    }

    private static func makeBids(
        hands: [[Card]],
        dealer: Int,
        cardsInRound: Int,
        trump: Suit?,
        biddingServices: [BotBiddingService],
        preLockedBids: [Int]? = nil,
        blindSelections: [Bool]? = nil
    ) -> [Int] {
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

        for step in 0..<playerCount {
            let player = normalizedPlayerIndex(firstBidder + step, playerCount: playerCount)
            if resolvedBlindSelections[player] {
                continue
            }

            let allowed = allowedBids(
                forPlayer: player,
                dealer: dealer,
                cardsInRound: cardsInRound,
                bids: bids,
                playerCount: playerCount
            )
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

        return bids
    }

    private static func playRound(
        hands: [[Card]],
        bids: [Int],
        dealer: Int,
        cardsInRound: Int,
        trump: Suit?,
        turnServices: [BotTurnStrategyService]
    ) -> [Int] {
        let playerCount = hands.count
        var tricksTaken = Array(repeating: 0, count: playerCount)
        var mutableHands = hands
        var trickLeader = normalizedPlayerIndex(dealer + 1, playerCount: playerCount)

        for _ in 0..<cardsInRound {
            let trickNode = TrickNode(rendersCards: false)

            for offset in 0..<playerCount {
                let player = normalizedPlayerIndex(trickLeader + offset, playerCount: playerCount)
                let playerHand = mutableHands[player]

                guard !playerHand.isEmpty else { continue }

                let strategyMove = turnServices[player].makeTurnDecision(
                    handCards: playerHand,
                    trickNode: trickNode,
                    trump: trump,
                    bid: bids[player],
                    tricksTaken: tricksTaken[player],
                    cardsInRound: cardsInRound,
                    playerCount: playerCount
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

                if let removeIndex = mutableHands[player].firstIndex(of: move.card) {
                    mutableHands[player].remove(at: removeIndex)
                } else if let fallbackCard = mutableHands[player].first {
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
            trickLeader = winner
        }

        return tricksTaken
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
        let trump = trumpServices[trumpChooser].selectTrump(from: initialDeal.hands[trumpChooser])

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
        guard playerCount > 0 else { return [] }
        guard playerIndex >= 0 && playerIndex < playerCount else { return [] }

        let maxBid = max(0, cardsInRound)
        var allowed = Array(0...maxBid)

        guard playerCount > 1, playerIndex == dealer else {
            return allowed
        }

        let totalWithoutDealer = (0..<playerCount).reduce(0) { partial, index in
            guard index != dealer else { return partial }
            let rawBid = bids.indices.contains(index) ? bids[index] : 0
            let clampedBid = min(max(rawBid, 0), maxBid)
            return partial + clampedBid
        }

        let forbiddenBid = cardsInRound - totalWithoutDealer
        if let forbiddenIndex = allowed.firstIndex(of: forbiddenBid) {
            allowed.remove(at: forbiddenIndex)
        }

        return allowed
    }

    private static func dealerForbiddenBid(
        forPlayer playerIndex: Int,
        dealer: Int,
        cardsInRound: Int,
        bids: [Int],
        playerCount: Int
    ) -> Int? {
        guard playerCount > 1, playerIndex == dealer else { return nil }

        let totalWithoutDealer = (0..<playerCount).reduce(0) { partial, index in
            guard index != dealer else { return partial }
            let rawBid = bids.indices.contains(index) ? bids[index] : 0
            return partial + min(max(rawBid, 0), max(0, cardsInRound))
        }

        let forbidden = cardsInRound - totalWithoutDealer
        guard forbidden >= 0 && forbidden <= cardsInRound else { return nil }
        return forbidden
    }

    private static func canChooseBlindBid(
        forPlayer playerIndex: Int,
        dealer: Int,
        blindSelections: [Bool]
    ) -> Bool {
        guard playerIndex >= 0 && playerIndex < blindSelections.count else { return false }

        if playerIndex != dealer {
            return true
        }

        for index in blindSelections.indices where index != dealer {
            guard blindSelections[index] else {
                return false
            }
        }

        return true
    }

    private static func biddingOrder(dealer: Int, playerCount: Int) -> [Int] {
        guard playerCount > 0 else { return [] }
        let start = normalizedPlayerIndex(dealer + 1, playerCount: playerCount)
        return (0..<playerCount).map { offset in
            normalizedPlayerIndex(start + offset, playerCount: playerCount)
        }
    }

    private static func tuning(
        byApplying genome: EvolutionGenome,
        to base: BotTuning
    ) -> BotTuning {
        let baseTurn = base.turnStrategy
        let holdWeight = clamp(
            baseTurn.holdFromDistributionWeight * genome.holdDistributionScale,
            to: 0.55...0.97
        )
        let powerWeight = 1.0 - holdWeight

        let turnStrategy = BotTuning.TurnStrategy(
            utilityTieTolerance: baseTurn.utilityTieTolerance,

            chaseWinProbabilityWeight: clamp(
                baseTurn.chaseWinProbabilityWeight * genome.chaseWinProbabilityScale,
                to: 15.0...140.0
            ),
            chaseThreatPenaltyWeight: clamp(
                baseTurn.chaseThreatPenaltyWeight * genome.chaseThreatPenaltyScale,
                to: 0.02...1.20
            ),
            chaseSpendJokerPenalty: clamp(
                baseTurn.chaseSpendJokerPenalty * genome.chaseSpendJokerPenaltyScale,
                to: 5.0...220.0
            ),
            chaseLeadWishBonus: baseTurn.chaseLeadWishBonus,

            dumpAvoidWinWeight: clamp(
                baseTurn.dumpAvoidWinWeight * genome.dumpAvoidWinScale,
                to: 15.0...140.0
            ),
            dumpThreatRewardWeight: clamp(
                baseTurn.dumpThreatRewardWeight * genome.dumpThreatRewardScale,
                to: 0.01...1.50
            ),
            dumpSpendJokerPenalty: clamp(
                baseTurn.dumpSpendJokerPenalty * genome.dumpSpendJokerPenaltyScale,
                to: 5.0...220.0
            ),
            dumpFaceUpNonLeadJokerPenalty: baseTurn.dumpFaceUpNonLeadJokerPenalty,
            dumpLeadTakesNonTrumpBonus: baseTurn.dumpLeadTakesNonTrumpBonus,

            holdFromDistributionWeight: holdWeight,
            powerConfidenceWeight: powerWeight,

            futureJokerPower: clamp(
                baseTurn.futureJokerPower * genome.futureJokerPowerScale,
                to: 0.40...2.60
            ),
            futureRegularBasePower: baseTurn.futureRegularBasePower,
            futureRegularRankWeight: baseTurn.futureRegularRankWeight,
            futureTrumpBaseBonus: baseTurn.futureTrumpBaseBonus,
            futureTrumpRankWeight: baseTurn.futureTrumpRankWeight,
            futureHighRankBonus: baseTurn.futureHighRankBonus,
            futureLongSuitBonusPerCard: baseTurn.futureLongSuitBonusPerCard,
            futureTricksScale: clamp(
                baseTurn.futureTricksScale * genome.futureTricksScale,
                to: 0.20...1.35
            ),

            threatFaceDownLeadJoker: baseTurn.threatFaceDownLeadJoker,
            threatFaceDownNonLeadJoker: baseTurn.threatFaceDownNonLeadJoker,
            threatLeadTakesJoker: baseTurn.threatLeadTakesJoker,
            threatLeadAboveJoker: baseTurn.threatLeadAboveJoker,
            threatLeadWishJoker: baseTurn.threatLeadWishJoker,
            threatNonLeadFaceUpJoker: baseTurn.threatNonLeadFaceUpJoker,
            threatTrumpBonus: clamp(
                baseTurn.threatTrumpBonus * genome.threatPreservationScale,
                to: 1.0...24.0
            ),
            threatHighRankBonus: clamp(
                baseTurn.threatHighRankBonus * genome.threatPreservationScale,
                to: 0.5...12.0
            ),

            powerFaceDownJoker: baseTurn.powerFaceDownJoker,
            powerLeadTakesJoker: baseTurn.powerLeadTakesJoker,
            powerLeadAboveJoker: baseTurn.powerLeadAboveJoker,
            powerLeadWishJoker: baseTurn.powerLeadWishJoker,
            powerNonLeadFaceUpJoker: baseTurn.powerNonLeadFaceUpJoker,
            powerTrumpBonus: baseTurn.powerTrumpBonus,
            powerLeadSuitBonus: baseTurn.powerLeadSuitBonus,
            powerNormalizationValue: baseTurn.powerNormalizationValue
        )

        let baseBidding = base.bidding
        let bidding = BotTuning.Bidding(
            expectedJokerPower: clamp(
                baseBidding.expectedJokerPower * genome.biddingJokerPowerScale,
                to: 0.40...2.60
            ),
            expectedRankWeight: clamp(
                baseBidding.expectedRankWeight * genome.biddingRankWeightScale,
                to: 0.10...1.80
            ),
            expectedTrumpBaseBonus: clamp(
                baseBidding.expectedTrumpBaseBonus * genome.biddingTrumpBaseBonusScale,
                to: 0.05...2.20
            ),
            expectedTrumpRankWeight: clamp(
                baseBidding.expectedTrumpRankWeight * genome.biddingTrumpRankWeightScale,
                to: 0.05...2.20
            ),
            expectedHighRankBonus: clamp(
                baseBidding.expectedHighRankBonus * genome.biddingHighRankBonusScale,
                to: 0.02...1.20
            ),
            expectedLongSuitBonusPerCard: clamp(
                baseBidding.expectedLongSuitBonusPerCard * genome.biddingLongSuitBonusScale,
                to: 0.02...0.95
            ),
            expectedTrumpDensityBonus: clamp(
                baseBidding.expectedTrumpDensityBonus * genome.biddingTrumpDensityBonusScale,
                to: 0.05...1.80
            ),
            expectedNoTrumpHighCardBonus: clamp(
                baseBidding.expectedNoTrumpHighCardBonus * genome.biddingNoTrumpHighCardBonusScale,
                to: 0.02...1.20
            ),
            expectedNoTrumpJokerSynergy: clamp(
                baseBidding.expectedNoTrumpJokerSynergy * genome.biddingNoTrumpJokerSynergyScale,
                to: 0.05...2.20
            ),

            blindDesperateBehindThreshold: baseBidding.blindDesperateBehindThreshold,
            blindCatchUpBehindThreshold: baseBidding.blindCatchUpBehindThreshold,
            blindSafeLeadThreshold: baseBidding.blindSafeLeadThreshold,
            blindDesperateTargetShare: baseBidding.blindDesperateTargetShare,
            blindCatchUpTargetShare: baseBidding.blindCatchUpTargetShare
        )

        let baseTrump = base.trumpSelection
        let trumpSelection = BotTuning.TrumpSelection(
            cardBasePower: clamp(
                baseTrump.cardBasePower * genome.trumpCardBasePowerScale,
                to: 0.10...1.80
            ),
            minimumPowerToDeclareTrump: clamp(
                baseTrump.minimumPowerToDeclareTrump * genome.trumpThresholdScale,
                to: 0.35...3.20
            )
        )

        return BotTuning(
            difficulty: base.difficulty,
            turnStrategy: turnStrategy,
            bidding: bidding,
            trumpSelection: trumpSelection,
            timing: base.timing
        )
    }

    private static func randomizedScale(
        _ value: Double,
        magnitude: Double,
        range: ClosedRange<Double>,
        using rng: inout SelfPlayRandomGenerator
    ) -> Double {
        let offset = (rng.nextUnit() * 2.0 - 1.0) * magnitude
        return clamp(value * (1.0 + offset), to: range)
    }

    private static func mixedScale(
        _ first: Double,
        _ second: Double,
        range: ClosedRange<Double>,
        using rng: inout SelfPlayRandomGenerator
    ) -> Double {
        let alpha = rng.nextUnit()
        let mixed = first * (1.0 - alpha) + second * alpha
        return clamp(mixed, to: range)
    }

    private static func mutateScale(
        _ value: inout Double,
        chance: Double,
        magnitude: Double,
        range: ClosedRange<Double>,
        using rng: inout SelfPlayRandomGenerator
    ) {
        guard chance > 0.0 else { return }
        guard rng.nextUnit() < chance else { return }
        value = randomizedScale(value, magnitude: magnitude, range: range, using: &rng)
    }

    private static func normalizedPlayerIndex(
        _ rawIndex: Int,
        playerCount: Int
    ) -> Int {
        guard playerCount > 0 else { return 0 }
        let remainder = rawIndex % playerCount
        return remainder >= 0 ? remainder : remainder + playerCount
    }

    private static func clamp(
        _ value: Double,
        to range: ClosedRange<Double>
    ) -> Double {
        return min(max(value, range.lowerBound), range.upperBound)
    }

    private static func isLexicographicallySmaller(
        _ lhs: [Double],
        than rhs: [Double]
    ) -> Bool {
        let comparedCount = min(lhs.count, rhs.count)
        for index in 0..<comparedCount {
            if lhs[index] == rhs[index] {
                continue
            }
            return lhs[index] < rhs[index]
        }
        return lhs.count < rhs.count
    }
}
