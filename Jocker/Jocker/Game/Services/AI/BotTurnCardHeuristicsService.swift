//
//  BotTurnCardHeuristicsService.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import Foundation

/// Легковесное belief-state представление для legal-aware оценки вероятности удержания взятки.
/// На текущем этапе хранит только "void suits" по наблюдаемым игрокам.
struct BotBeliefState: Equatable {
    private let voidSuitsByPlayerIndex: [Int: Set<Suit>]

    init(voidSuitsByPlayerIndex: [Int: Set<Suit>] = [:]) {
        var normalized: [Int: Set<Suit>] = [:]
        for (playerIndex, voidSuits) in voidSuitsByPlayerIndex {
            guard playerIndex >= 0 else { continue }
            guard !voidSuits.isEmpty else { continue }
            normalized[playerIndex] = voidSuits
        }
        self.voidSuitsByPlayerIndex = normalized
    }

    func voidSuits(for playerIndex: Int) -> Set<Suit> {
        return voidSuitsByPlayerIndex[playerIndex] ?? []
    }

    func isVoid(_ suit: Suit, for playerIndex: Int) -> Bool {
        return voidSuits(for: playerIndex).contains(suit)
    }

    static func infer(
        playerCount: Int,
        completedTricks: [[PlayedTrickCard]],
        currentTrick: [PlayedTrickCard],
        trump: Suit?
    ) -> BotBeliefState {
        guard playerCount > 0 else { return BotBeliefState() }

        var voidSuitsByPlayerIndex: [Int: Set<Suit>] = [:]

        for trick in completedTricks where !trick.isEmpty {
            inferVoidSuits(
                from: trick,
                playerCount: playerCount,
                trump: trump,
                into: &voidSuitsByPlayerIndex
            )
        }

        if !currentTrick.isEmpty {
            inferVoidSuits(
                from: currentTrick,
                playerCount: playerCount,
                trump: trump,
                into: &voidSuitsByPlayerIndex
            )
        }

        return BotBeliefState(voidSuitsByPlayerIndex: voidSuitsByPlayerIndex)
    }

    private static func inferVoidSuits(
        from trick: [PlayedTrickCard],
        playerCount: Int,
        trump: Suit?,
        into voidSuitsByPlayerIndex: inout [Int: Set<Suit>]
    ) {
        guard let leadCard = trick.first else { return }
        guard !isWishLeadMode(leadCard) else { return }
        guard let leadSuit = effectiveLeadSuit(from: leadCard) else { return }

        for playedCard in trick.dropFirst() {
            let playerIndex = playedCard.playerIndex
            guard playerIndex >= 0, playerIndex < playerCount else { continue }
            guard !playedCard.card.isJoker else { continue }
            guard let playedSuit = playedCard.card.suit else { continue }
            guard playedSuit != leadSuit else { continue }

            voidSuitsByPlayerIndex[playerIndex, default: []].insert(leadSuit)
            if let trump, playedSuit != trump {
                voidSuitsByPlayerIndex[playerIndex, default: []].insert(trump)
            }
        }
    }

    private static func effectiveLeadSuit(from leadCard: PlayedTrickCard) -> Suit? {
        if !leadCard.card.isJoker {
            return leadCard.card.suit
        }

        switch leadCard.jokerLeadDeclaration {
        case .above(let suit), .takes(let suit):
            return suit
        case .wish, .none:
            return nil
        }
    }

    private static func isWishLeadMode(_ leadCard: PlayedTrickCard) -> Bool {
        guard leadCard.card.isJoker else { return false }
        switch leadCard.jokerLeadDeclaration {
        case .wish, .none:
            return true
        case .above, .takes:
            return false
        }
    }
}

/// Низкоуровневые эвристики runtime-хода бота:
/// генерация joker-вариантов, оценка угрозы карты и вероятности мгновенного взятия.
struct BotTurnCardHeuristicsService {
    private enum LegalAwareSampling {
        static let minimumIterations = 20
        static let maximumIterations = 48
        static let reducedMinimumIterations = 8
        static let reducedMaximumIterations = 20
        static let rotationStride = 7
        static let reducedMaxCardsPerOpponentSample = 3
        static let endgameHandSizeThreshold = 4
    }

    struct TrickSnapshot {
        let playedCards: [PlayedTrickCard]

        init(playedCards: [PlayedTrickCard]) {
            self.playedCards = playedCards
        }

        init(trickNode: TrickNode) {
            self.playedCards = trickNode.playedCards
        }
    }

    private let tuning: BotTuning

    init(tuning: BotTuning) {
        self.tuning = tuning
    }

    func candidateDecisions(
        for card: Card,
        trick: TrickSnapshot,
        shouldChaseTrick: Bool
    ) -> [JokerPlayDecision] {
        guard card.isJoker else { return [.defaultNonLead] }

        let isLead = trick.playedCards.isEmpty
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

    func candidateDecisions(
        for card: Card,
        trickNode: TrickNode,
        shouldChaseTrick: Bool
    ) -> [JokerPlayDecision] {
        return candidateDecisions(
            for: card,
            trick: TrickSnapshot(trickNode: trickNode),
            shouldChaseTrick: shouldChaseTrick
        )
    }

    func unseenCards(excluding handCards: [Card], and playedCards: [Card]) -> [Card] {
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

    func cardThreat(
        card: Card,
        decision: JokerPlayDecision,
        trump: Suit?,
        trick: TrickSnapshot,
        cardsRemainingInHandBeforeMove: Int? = nil,
        cardsInRound: Int? = nil
    ) -> Double {
        let strategy = tuning.turnStrategy
        let phaseMultiplier = threatPhaseMultiplier(
            for: card,
            trump: trump,
            cardsRemainingInHandBeforeMove: cardsRemainingInHandBeforeMove,
            cardsInRound: cardsInRound
        )
        if card.isJoker {
            if decision.style == .faceDown {
                let baseThreat = trick.playedCards.isEmpty
                    ? strategy.threatFaceDownLeadJoker
                    : strategy.threatFaceDownNonLeadJoker
                return baseThreat * phaseMultiplier
            }

            if trick.playedCards.isEmpty {
                let baseThreat: Double
                switch decision.leadDeclaration {
                case .takes:
                    baseThreat = strategy.threatLeadTakesJoker
                case .above:
                    baseThreat = strategy.threatLeadAboveJoker
                case .wish, .none:
                    baseThreat = strategy.threatLeadWishJoker
                }
                return baseThreat * phaseMultiplier
            }

            return strategy.threatNonLeadFaceUpJoker * phaseMultiplier
        }

        guard case .regular(let suit, let rank) = card else { return 0.0 }
        var threat = Double(rank.rawValue)
        if let trump, suit == trump {
            threat += strategy.threatTrumpBonus
        }
        if rank.rawValue >= Rank.queen.rawValue {
            threat += strategy.threatHighRankBonus
        }
        return threat * phaseMultiplier
    }

    func cardThreat(
        card: Card,
        decision: JokerPlayDecision,
        trump: Suit?,
        trickNode: TrickNode,
        cardsRemainingInHandBeforeMove: Int? = nil,
        cardsInRound: Int? = nil
    ) -> Double {
        return cardThreat(
            card: card,
            decision: decision,
            trump: trump,
            trick: TrickSnapshot(trickNode: trickNode),
            cardsRemainingInHandBeforeMove: cardsRemainingInHandBeforeMove,
            cardsInRound: cardsInRound
        )
    }

    func winsTrickRightNow(
        with card: Card,
        decision: JokerPlayDecision,
        trick: TrickSnapshot,
        trump: Suit?
    ) -> Bool {
        let simulatedTrick = trick.playedCards + [
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

    func winsTrickRightNow(
        with card: Card,
        decision: JokerPlayDecision,
        trickNode: TrickNode,
        trump: Suit?
    ) -> Bool {
        return winsTrickRightNow(
            with: card,
            decision: decision,
            trick: TrickSnapshot(trickNode: trickNode),
            trump: trump
        )
    }

    func estimateImmediateWinProbability(
        card: Card,
        decision: JokerPlayDecision,
        trick: TrickSnapshot,
        trump: Suit?,
        unseenCards: [Card],
        opponentsRemaining: Int,
        handSizeBeforeMove: Int,
        beliefState: BotBeliefState? = nil,
        remainingOpponentPlayerIndices: [Int]? = nil
    ) -> Double {
        guard winsTrickRightNow(
            with: card,
            decision: decision,
            trick: trick,
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

        let trickAfterMove = trick.playedCards + [
            PlayedTrickCard(
                playerIndex: -1,
                card: card,
                jokerPlayStyle: decision.style,
                jokerLeadDeclaration: decision.leadDeclaration
            )
        ]

        let beatersCount = unseenCards.reduce(0) { partial, candidateCard in
            let simulated = trickAfterMove + [
                PlayedTrickCard(
                    playerIndex: -2,
                    card: candidateCard,
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
        let legalAwareHoldFromSimulation: Double?
        if shouldUseLegalAwareSimulation(
            card: card,
            decision: decision,
            handSizeBeforeMove: handSizeBeforeMove,
            opponentsRemaining: opponentsRemaining
        ) {
            legalAwareHoldFromSimulation = estimateLegalAwareHoldProbability(
                trickAfterMove: trickAfterMove,
                trump: trump,
                unseenCards: unseenCards,
                opponentsRemaining: opponentsRemaining,
                handSizeBeforeMove: handSizeBeforeMove,
                beliefState: beliefState,
                remainingOpponentPlayerIndices: remainingOpponentPlayerIndices
            )
        } else {
            legalAwareHoldFromSimulation = nil
        }
        let holdProbability = legalAwareHoldFromSimulation.map {
            // Сохраняем частичное влияние legacy-компоненты, чтобы переход к legal-aware был плавным.
            $0 * 0.72 + holdFromDistribution * 0.28
        } ?? holdFromDistribution

        let strategy = tuning.turnStrategy
        let powerConfidence = min(
            1.0,
            max(
                0.0,
                Double(cardPower(card, decision: decision, trick: trick, trump: trump)) /
                    max(1.0, strategy.powerNormalizationValue)
            )
        )

        return min(
            1.0,
            max(
                0.0,
                holdProbability * strategy.holdFromDistributionWeight +
                    powerConfidence * strategy.powerConfidenceWeight
            )
        )
    }

    func estimateImmediateWinProbability(
        card: Card,
        decision: JokerPlayDecision,
        trickNode: TrickNode,
        trump: Suit?,
        unseenCards: [Card],
        opponentsRemaining: Int,
        handSizeBeforeMove: Int,
        beliefState: BotBeliefState? = nil,
        remainingOpponentPlayerIndices: [Int]? = nil
    ) -> Double {
        return estimateImmediateWinProbability(
            card: card,
            decision: decision,
            trick: TrickSnapshot(trickNode: trickNode),
            trump: trump,
            unseenCards: unseenCards,
            opponentsRemaining: opponentsRemaining,
            handSizeBeforeMove: handSizeBeforeMove,
            beliefState: beliefState,
            remainingOpponentPlayerIndices: remainingOpponentPlayerIndices
        )
    }

    private func estimateLegalAwareHoldProbability(
        trickAfterMove: [PlayedTrickCard],
        trump: Suit?,
        unseenCards: [Card],
        opponentsRemaining: Int,
        handSizeBeforeMove: Int,
        beliefState: BotBeliefState?,
        remainingOpponentPlayerIndices: [Int]?
    ) -> Double? {
        guard opponentsRemaining > 0 else { return 1.0 }
        guard !unseenCards.isEmpty else { return 1.0 }

        let opponentOrder = resolvedOpponentOrder(
            opponentsRemaining: opponentsRemaining,
            remainingOpponentPlayerIndices: remainingOpponentPlayerIndices
        )
        guard !opponentOrder.isEmpty else { return 1.0 }

        let sortedUnseen = unseenCards.sorted()
        let useReducedBudget = handSizeBeforeMove > LegalAwareSampling.endgameHandSizeThreshold
        let minimumIterations = useReducedBudget
            ? LegalAwareSampling.reducedMinimumIterations
            : LegalAwareSampling.minimumIterations
        let maximumIterations = useReducedBudget
            ? LegalAwareSampling.reducedMaximumIterations
            : LegalAwareSampling.maximumIterations
        let sampleIterations = min(
            maximumIterations,
            max(minimumIterations, sortedUnseen.count)
        )
        guard sampleIterations > 0 else { return nil }

        var holdSuccessCount = 0
        for iteration in 0..<sampleIterations {
            let offset = (iteration * LegalAwareSampling.rotationStride) % max(1, sortedUnseen.count)
            var cardPool = rotatedCards(sortedUnseen, by: offset)
            var simulatedTrick = trickAfterMove
            var isBeaten = false

            for opponentIndex in opponentOrder {
                let maxCardsPerOpponent = useReducedBudget
                    ? LegalAwareSampling.reducedMaxCardsPerOpponentSample
                    : max(1, handSizeBeforeMove)
                let cardsToDraw = min(
                    max(
                        1,
                        min(handSizeBeforeMove, maxCardsPerOpponent)
                    ),
                    cardPool.count
                )
                guard cardsToDraw > 0 else { break }

                let voidSuits = beliefState?.voidSuits(for: opponentIndex) ?? []
                let simulatedHand = drawSimulatedHand(
                    drawCount: cardsToDraw,
                    from: &cardPool,
                    avoidingSuits: voidSuits
                )
                guard !simulatedHand.isEmpty else { continue }

                let simulatedMove = pickMoveForSimulatedOpponent(
                    hand: simulatedHand,
                    playerIndex: opponentIndex,
                    trick: simulatedTrick,
                    trump: trump
                )
                simulatedTrick.append(simulatedMove)

                if TrickTakingResolver.winnerPlayerIndex(
                    playedCards: simulatedTrick,
                    trump: trump
                ) == opponentIndex {
                    isBeaten = true
                    break
                }
            }

            if !isBeaten {
                holdSuccessCount += 1
            }
        }

        return Double(holdSuccessCount) / Double(sampleIterations)
    }

    private func shouldUseLegalAwareSimulation(
        card: Card,
        decision: JokerPlayDecision,
        handSizeBeforeMove: Int,
        opponentsRemaining: Int
    ) -> Bool {
        guard opponentsRemaining > 0 else { return false }
        if card.isJoker || decision.leadDeclaration != nil {
            return true
        }
        return handSizeBeforeMove <= LegalAwareSampling.endgameHandSizeThreshold
    }

    private func resolvedOpponentOrder(
        opponentsRemaining: Int,
        remainingOpponentPlayerIndices: [Int]?
    ) -> [Int] {
        guard opponentsRemaining > 0 else { return [] }
        guard let remainingOpponentPlayerIndices, !remainingOpponentPlayerIndices.isEmpty else {
            return Array(0..<opponentsRemaining)
        }
        if remainingOpponentPlayerIndices.count >= opponentsRemaining {
            return Array(remainingOpponentPlayerIndices.prefix(opponentsRemaining))
        }
        let fallbackSuffix = Array(0..<(opponentsRemaining - remainingOpponentPlayerIndices.count))
        return remainingOpponentPlayerIndices + fallbackSuffix
    }

    private func rotatedCards(_ cards: [Card], by offset: Int) -> [Card] {
        guard !cards.isEmpty else { return [] }
        let normalizedOffset = ((offset % cards.count) + cards.count) % cards.count
        guard normalizedOffset != 0 else { return cards }
        return Array(cards[normalizedOffset...]) + Array(cards[..<normalizedOffset])
    }

    private func drawSimulatedHand(
        drawCount: Int,
        from cardPool: inout [Card],
        avoidingSuits: Set<Suit>
    ) -> [Card] {
        guard drawCount > 0 else { return [] }
        guard !cardPool.isEmpty else { return [] }

        var selected: [Card] = []
        selected.reserveCapacity(drawCount)

        if !avoidingSuits.isEmpty {
            var retained: [Card] = []
            retained.reserveCapacity(cardPool.count)
            for candidate in cardPool {
                if selected.count < drawCount,
                   let suit = candidate.suit,
                   avoidingSuits.contains(suit) {
                    retained.append(candidate)
                    continue
                }
                if selected.count < drawCount {
                    selected.append(candidate)
                } else {
                    retained.append(candidate)
                }
            }
            cardPool = retained
        }

        if selected.count < drawCount && !cardPool.isEmpty {
            let topUpCount = min(drawCount - selected.count, cardPool.count)
            selected.append(contentsOf: cardPool.prefix(topUpCount))
            cardPool.removeFirst(topUpCount)
        }

        return selected
    }

    private func pickMoveForSimulatedOpponent(
        hand: [Card],
        playerIndex: Int,
        trick: [PlayedTrickCard],
        trump: Suit?
    ) -> PlayedTrickCard {
        let legalCards = legalMoves(for: hand, trick: trick, trump: trump)
        guard !legalCards.isEmpty else {
            return PlayedTrickCard(
                playerIndex: playerIndex,
                card: hand[0],
                jokerPlayStyle: .faceUp,
                jokerLeadDeclaration: nil
            )
        }

        let winningCards = legalCards.filter { candidate in
            let simulated = trick + [
                PlayedTrickCard(
                    playerIndex: playerIndex,
                    card: candidate,
                    jokerPlayStyle: candidate.isJoker ? .faceUp : .faceUp,
                    jokerLeadDeclaration: nil
                )
            ]
            return TrickTakingResolver.winnerPlayerIndex(
                playedCards: simulated,
                trump: trump
            ) == playerIndex
        }

        let selectedCard: Card
        if !winningCards.isEmpty {
            selectedCard = winningCards.max {
                simulatedCardPower($0, trump: trump, trick: trick) <
                    simulatedCardPower($1, trump: trump, trick: trick)
            } ?? winningCards[0]
        } else {
            selectedCard = legalCards[0]
        }

        return PlayedTrickCard(
            playerIndex: playerIndex,
            card: selectedCard,
            jokerPlayStyle: .faceUp,
            jokerLeadDeclaration: nil
        )
    }

    private func legalMoves(
        for hand: [Card],
        trick: [PlayedTrickCard],
        trump: Suit?
    ) -> [Card] {
        guard !hand.isEmpty else { return [] }
        return hand.filter { canPlayCard($0, fromHand: hand, trick: trick, trump: trump) }
    }

    private func canPlayCard(
        _ card: Card,
        fromHand hand: [Card],
        trick: [PlayedTrickCard],
        trump: Suit?
    ) -> Bool {
        guard !trick.isEmpty else { return true }

        if card.isJoker {
            return true
        }

        guard let cardSuit = card.suit else {
            return true
        }

        if isWishLeadMode(in: trick) {
            return true
        }

        let forceHighestForRequiredSuit = isLeadJokerAboveMode(in: trick)
        guard let leadSuit = effectiveLeadSuit(in: trick) else {
            return true
        }

        if cardSuit == leadSuit {
            if forceHighestForRequiredSuit {
                return isHighestCard(card, of: leadSuit, in: hand)
            }
            return true
        }

        if hasSuit(leadSuit, in: hand) {
            return false
        }

        if let trump, hasSuit(trump, in: hand) {
            return cardSuit == trump
        }

        return true
    }

    private func effectiveLeadSuit(in trick: [PlayedTrickCard]) -> Suit? {
        guard let leadCard = trick.first else { return nil }
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

    private func isWishLeadMode(in trick: [PlayedTrickCard]) -> Bool {
        guard let leadCard = trick.first else { return false }
        guard leadCard.card.isJoker else { return false }

        switch leadCard.jokerLeadDeclaration {
        case .wish, .none:
            return true
        case .above, .takes:
            return false
        }
    }

    private func isLeadJokerAboveMode(in trick: [PlayedTrickCard]) -> Bool {
        guard let leadCard = trick.first else { return false }
        guard leadCard.card.isJoker else { return false }

        switch leadCard.jokerLeadDeclaration {
        case .above:
            return true
        case .wish, .takes, .none:
            return false
        }
    }

    private func isHighestCard(_ card: Card, of suit: Suit, in hand: [Card]) -> Bool {
        guard case .regular(_, let cardRank) = card else { return false }

        let highestRank = hand
            .compactMap { handCard -> Rank? in
                guard case .regular(let handSuit, let handRank) = handCard, handSuit == suit else {
                    return nil
                }
                return handRank
            }
            .max()

        guard let highestRank else { return false }
        return cardRank == highestRank
    }

    private func hasSuit(_ suit: Suit, in hand: [Card]) -> Bool {
        return hand.contains { $0.suit == suit }
    }

    private func simulatedCardPower(
        _ card: Card,
        trump: Suit?,
        trick: [PlayedTrickCard]
    ) -> Double {
        if card.isJoker {
            return 10_000
        }

        guard case .regular(let suit, let rank) = card else { return 0.0 }
        var value = Double(rank.rawValue)
        if let trump, suit == trump {
            value += 100.0
        } else if let leadSuit = effectiveLeadSuit(in: trick), suit == leadSuit {
            value += 40.0
        }
        return value
    }

    private func cardPower(
        _ card: Card,
        decision: JokerPlayDecision,
        trick: TrickSnapshot,
        trump: Suit?
    ) -> Int {
        let strategy = tuning.turnStrategy
        if card.isJoker {
            if decision.style == .faceDown {
                return strategy.powerFaceDownJoker
            }

            if trick.playedCards.isEmpty {
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
        if let leadSuit = effectiveLeadSuit(in: trick), suit == leadSuit {
            value += strategy.powerLeadSuitBonus
        }

        return value
    }

    private func effectiveLeadSuit(in trick: TrickSnapshot) -> Suit? {
        guard let leadCard = trick.playedCards.first else { return nil }
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

    private func threatPhaseMultiplier(
        for card: Card,
        trump: Suit?,
        cardsRemainingInHandBeforeMove: Int?,
        cardsInRound: Int?
    ) -> Double {
        guard let cardsInRound,
              cardsInRound > 1,
              let cardsRemainingInHandBeforeMove else {
            return 1.0
        }

        let clampedCardsInRound = max(1, cardsInRound)
        let clampedHandSize = min(max(1, cardsRemainingInHandBeforeMove), clampedCardsInRound)
        let completedTricks = max(0, clampedCardsInRound - clampedHandSize)
        let phaseProgress = Double(completedTricks) / Double(max(1, clampedCardsInRound - 1))

        let resourceWeight: Double
        if card.isJoker {
            resourceWeight = 1.0
        } else if let suit = card.suit, suit == trump {
            resourceWeight = 0.8
        } else if let rank = card.rank, rank.rawValue >= Rank.queen.rawValue {
            resourceWeight = 0.65
        } else if let rank = card.rank, rank.rawValue >= Rank.jack.rawValue {
            resourceWeight = 0.35
        } else {
            resourceWeight = 0.15
        }

        // Early in the hand, preserve high-value resources longer.
        let earlyPreservationBonus = 0.28 * resourceWeight
        // Late in the hand, convert resources into result instead of over-preserving.
        let lateConversionDiscount = 0.38 * resourceWeight

        var multiplier = 1.0 +
            (1.0 - phaseProgress) * earlyPreservationBonus -
            phaseProgress * lateConversionDiscount

        if clampedHandSize == 1 {
            multiplier -= 0.05 * resourceWeight
        }

        return min(1.35, max(0.55, multiplier))
    }
}
