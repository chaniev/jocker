//
//  BotMatchContext.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import Foundation

/// Базовый матчевый/блоковый контекст для runtime-решений бота.
///
/// Этап 4a: plumbing-поле. На первом шаге может только прокидываться по стеку
/// без изменения итогового utility/эвристик.
struct BotMatchContext: Equatable {
    struct RoundSnapshot: Equatable {
        let bids: [Int]
        let tricksTaken: [Int]
        let isBlindBid: [Bool]

        init(
            bids: [Int],
            tricksTaken: [Int],
            isBlindBid: [Bool]
        ) {
            self.bids = bids
            self.tricksTaken = tricksTaken
            self.isBlindBid = isBlindBid
        }

        func bid(for playerIndex: Int) -> Int? {
            guard bids.indices.contains(playerIndex) else { return nil }
            return bids[playerIndex]
        }

        func tricks(for playerIndex: Int) -> Int? {
            guard tricksTaken.indices.contains(playerIndex) else { return nil }
            return tricksTaken[playerIndex]
        }

        func needsTricks(for playerIndex: Int) -> Int? {
            guard let bid = bid(for: playerIndex), let tricks = tricks(for: playerIndex) else {
                return nil
            }
            return max(0, bid - tricks)
        }
    }

    struct PremiumSnapshot: Equatable {
        let completedRoundsInBlock: Int
        let remainingRoundsInBlock: Int
        let isPremiumCandidateSoFar: Bool
        let isZeroPremiumRelevantInBlock: Bool
        let isZeroPremiumCandidateSoFar: Bool
        let leftNeighborIndex: Int?
        let leftNeighborIsPremiumCandidateSoFar: Bool
        let isPenaltyTargetRiskSoFar: Bool
        let premiumCandidatesThreateningPenaltyCount: Int
        let opponentPremiumCandidatesSoFarCount: Int

        init(
            completedRoundsInBlock: Int,
            remainingRoundsInBlock: Int,
            isPremiumCandidateSoFar: Bool,
            isZeroPremiumRelevantInBlock: Bool,
            isZeroPremiumCandidateSoFar: Bool,
            leftNeighborIndex: Int? = nil,
            leftNeighborIsPremiumCandidateSoFar: Bool = false,
            isPenaltyTargetRiskSoFar: Bool = false,
            premiumCandidatesThreateningPenaltyCount: Int = 0,
            opponentPremiumCandidatesSoFarCount: Int = 0
        ) {
            self.completedRoundsInBlock = completedRoundsInBlock
            self.remainingRoundsInBlock = remainingRoundsInBlock
            self.isPremiumCandidateSoFar = isPremiumCandidateSoFar
            self.isZeroPremiumRelevantInBlock = isZeroPremiumRelevantInBlock
            self.isZeroPremiumCandidateSoFar = isZeroPremiumCandidateSoFar
            self.leftNeighborIndex = leftNeighborIndex
            self.leftNeighborIsPremiumCandidateSoFar = leftNeighborIsPremiumCandidateSoFar
            self.isPenaltyTargetRiskSoFar = isPenaltyTargetRiskSoFar
            self.premiumCandidatesThreateningPenaltyCount = max(0, premiumCandidatesThreateningPenaltyCount)
            self.opponentPremiumCandidatesSoFarCount = max(0, opponentPremiumCandidatesSoFarCount)
        }
    }

    let block: GameBlock
    let roundIndexInBlock: Int
    let totalRoundsInBlock: Int
    let totalScores: [Int]
    let playerIndex: Int
    let dealerIndex: Int
    let playerCount: Int
    let round: RoundSnapshot?
    let premium: PremiumSnapshot?
    let opponents: BotOpponentModel?

    init(
        block: GameBlock,
        roundIndexInBlock: Int,
        totalRoundsInBlock: Int,
        totalScores: [Int],
        playerIndex: Int,
        dealerIndex: Int,
        playerCount: Int,
        round: RoundSnapshot? = nil,
        premium: PremiumSnapshot? = nil,
        opponents: BotOpponentModel? = nil
    ) {
        self.block = block
        self.roundIndexInBlock = roundIndexInBlock
        self.totalRoundsInBlock = totalRoundsInBlock
        self.totalScores = totalScores
        self.playerIndex = playerIndex
        self.dealerIndex = dealerIndex
        self.playerCount = playerCount
        self.round = round
        self.premium = premium
        self.opponents = opponents
    }

    var blockNumber: Int {
        return block.rawValue
    }

    /// Прогресс блока в диапазоне `[0, 1]`.
    /// `0` — начало блока, `1` — последняя раздача блока.
    var blockProgressFraction: Double {
        let rounds = max(1, totalRoundsInBlock)
        guard rounds > 1 else { return 1.0 }
        let clampedRound = min(max(0, roundIndexInBlock), rounds - 1)
        return Double(clampedRound) / Double(rounds - 1)
    }

    /// Позиция игрока относительно дилера по часовой стрелке.
    /// `0` — сам дилер, `1` — следующий после дилера и т.д.
    var relativeSeatOffsetFromDealer: Int {
        let seats = max(1, playerCount)
        let normalizedPlayer = ((playerIndex % seats) + seats) % seats
        let normalizedDealer = ((dealerIndex % seats) + seats) % seats
        return (normalizedPlayer - normalizedDealer + seats) % seats
    }
}
