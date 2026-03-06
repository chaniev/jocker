//
//  BotTurnSamplingService.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

struct BotTurnSamplingService {
    private struct StableSeedBuilder {
        private static let deterministicSalt: UInt64 = 0x2
        private var state: UInt64 = 0xcbf2_9ce4_8422_2325

        mutating func combine(_ value: UInt64) {
            var littleEndian = value.littleEndian
            withUnsafeBytes(of: &littleEndian) { bytes in
                for byte in bytes {
                    state ^= UInt64(byte)
                    state &*= 0x0000_0100_0000_01B3
                }
            }
        }

        mutating func combine(_ value: Int) {
            combine(UInt64(bitPattern: Int64(value)))
        }

        mutating func combine(_ value: Card) {
            switch value {
            case .joker:
                combine(0)
            case .regular(let suit, let rank):
                combine(1)
                combine(suit)
                combine(rank)
            }
        }

        mutating func combine(_ value: Suit) {
            switch value {
            case .diamonds:
                combine(0)
            case .hearts:
                combine(1)
            case .spades:
                combine(2)
            case .clubs:
                combine(3)
            }
        }

        mutating func combine(_ value: Rank) {
            combine(value.rawValue)
        }

        mutating func combine(_ value: JokerPlayStyle) {
            switch value {
            case .faceUp:
                combine(0)
            case .faceDown:
                combine(1)
            }
        }

        mutating func combine(_ value: JokerLeadDeclaration?) {
            switch value {
            case .wish:
                combine(1)
            case .above(let suit):
                combine(2)
                combine(suit)
            case .takes(let suit):
                combine(3)
                combine(suit)
            case .none:
                combine(0)
            }
        }

        func finalize() -> UInt64 {
            let resolvedState = state == 0 ? 0x9E37_79B9_7F4A_7C15 : state
            return resolvedState ^ Self.deterministicSalt
        }
    }

    struct DeterministicRNG {
        private var state: UInt64

        init(seed: UInt64) {
            self.state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
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

    func makeRolloutRNG(
        candidate: BotTurnCandidateEvaluatorService.CandidateScore,
        context: BotTurnCandidateEvaluatorService.DecisionContext,
        iteration: Int
    ) -> DeterministicRNG {
        DeterministicRNG(
            seed: rolloutSeed(
                candidate: candidate,
                context: context,
                iteration: iteration
            )
        )
    }

    func makeEndgameRNG(
        candidate: BotTurnCandidateEvaluatorService.CandidateScore,
        context: BotTurnCandidateEvaluatorService.DecisionContext,
        iteration: Int
    ) -> DeterministicRNG {
        DeterministicRNG(
            seed: endgameSeed(
                candidate: candidate,
                context: context,
                iteration: iteration
            )
        )
    }

    func sampleOpponentHands(
        opponentIndices: [Int],
        unseenCards: [Card],
        cardsPerOpponent: Int,
        beliefState: BotBeliefState?,
        rng: inout DeterministicRNG
    ) -> [Int: [Card]] {
        guard !opponentIndices.isEmpty else { return [:] }
        guard cardsPerOpponent > 0 else { return [:] }

        var cardPool = unseenCards.sorted()
        deterministicShuffle(&cardPool, rng: &rng)
        var result: [Int: [Card]] = [:]

        for opponentIndex in opponentIndices {
            guard !cardPool.isEmpty else {
                result[opponentIndex] = []
                continue
            }

            let drawCount = min(cardsPerOpponent, cardPool.count)
            let voidSuits = beliefState?.voidSuits(for: opponentIndex) ?? []
            var selectedIndices: [Int] = []
            var deferredIndices: [Int] = []

            for index in cardPool.indices {
                guard selectedIndices.count < drawCount else { break }
                if let suit = cardPool[index].suit, voidSuits.contains(suit) {
                    deferredIndices.append(index)
                    continue
                }
                selectedIndices.append(index)
            }

            if selectedIndices.count < drawCount {
                for index in deferredIndices where selectedIndices.count < drawCount {
                    selectedIndices.append(index)
                }
            }

            if selectedIndices.count < drawCount {
                for index in cardPool.indices where selectedIndices.count < drawCount {
                    guard !selectedIndices.contains(index) else { continue }
                    selectedIndices.append(index)
                }
            }

            selectedIndices.sort(by: >)
            var hand: [Card] = []
            hand.reserveCapacity(selectedIndices.count)
            for index in selectedIndices {
                hand.append(cardPool.remove(at: index))
            }
            hand.sort()
            result[opponentIndex] = hand
        }

        return result
    }

    func sampleOpponentHandsWithRequirements(
        opponentCardRequirements: [Int: Int],
        unseenCards: [Card],
        beliefState: BotBeliefState?,
        rng: inout DeterministicRNG
    ) -> [Int: [Card]] {
        guard !opponentCardRequirements.isEmpty else { return [:] }

        var cardPool = unseenCards.sorted()
        deterministicShuffle(&cardPool, rng: &rng)
        var result: [Int: [Card]] = [:]

        let orderedPlayers = opponentCardRequirements.keys.sorted()
        for opponentIndex in orderedPlayers {
            let requestedCards = max(0, opponentCardRequirements[opponentIndex] ?? 0)
            guard requestedCards > 0, !cardPool.isEmpty else {
                result[opponentIndex] = []
                continue
            }

            let drawCount = min(requestedCards, cardPool.count)
            let voidSuits = beliefState?.voidSuits(for: opponentIndex) ?? []
            var selectedIndices: [Int] = []
            var deferredIndices: [Int] = []

            for index in cardPool.indices {
                guard selectedIndices.count < drawCount else { break }
                if let suit = cardPool[index].suit, voidSuits.contains(suit) {
                    deferredIndices.append(index)
                    continue
                }
                selectedIndices.append(index)
            }

            if selectedIndices.count < drawCount {
                for index in deferredIndices where selectedIndices.count < drawCount {
                    selectedIndices.append(index)
                }
            }

            if selectedIndices.count < drawCount {
                for index in cardPool.indices where selectedIndices.count < drawCount {
                    guard !selectedIndices.contains(index) else { continue }
                    selectedIndices.append(index)
                }
            }

            selectedIndices.sort(by: >)
            var hand: [Card] = []
            hand.reserveCapacity(selectedIndices.count)
            for index in selectedIndices {
                hand.append(cardPool.remove(at: index))
            }
            hand.sort()
            result[opponentIndex] = hand
        }

        return result
    }

    private func rolloutSeed(
        candidate: BotTurnCandidateEvaluatorService.CandidateScore,
        context: BotTurnCandidateEvaluatorService.DecisionContext,
        iteration: Int
    ) -> UInt64 {
        var seedBuilder = StableSeedBuilder()
        seedBuilder.combine(candidate.evaluation.move.card)
        seedBuilder.combine(candidate.evaluation.move.decision.style)
        seedBuilder.combine(candidate.evaluation.move.decision.leadDeclaration)
        seedBuilder.combine(context.roundContext.currentTricks)
        seedBuilder.combine(context.roundContext.targetBid)
        seedBuilder.combine(context.handContext.handCards.count)
        seedBuilder.combine(context.tableContext.trick.playedCards.count)
        seedBuilder.combine(iteration)
        return seedBuilder.finalize()
    }

    private func endgameSeed(
        candidate: BotTurnCandidateEvaluatorService.CandidateScore,
        context: BotTurnCandidateEvaluatorService.DecisionContext,
        iteration: Int
    ) -> UInt64 {
        rolloutSeed(
            candidate: candidate,
            context: context,
            iteration: iteration ^ 0x9E37
        ) ^ 0xA24B_AED4_963E_E407
    }

    private func deterministicShuffle(
        _ cards: inout [Card],
        rng: inout DeterministicRNG
    ) {
        guard cards.count > 1 else { return }
        for index in stride(from: cards.count - 1, through: 1, by: -1) {
            let swapIndex = rng.nextInt(upperBound: index + 1)
            if swapIndex != index {
                cards.swapAt(index, swapIndex)
            }
        }
    }
}
