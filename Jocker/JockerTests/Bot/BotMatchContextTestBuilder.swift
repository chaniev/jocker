//
//  BotMatchContextTestBuilder.swift
//  JockerTests
//
//  Created by Codex on 06.03.2026.
//

@testable import Jocker

struct BotMatchContextTestBuilder {
    var block: GameBlock = .fourth
    var roundIndexInBlock: Int = 7
    var totalRoundsInBlock: Int = 8
    var totalScores: [Int]
    var playerIndex: Int = 0
    var dealerIndex: Int = 2
    var playerCount: Int = 4
    var round: BotMatchContext.RoundSnapshot?
    var premium: BotMatchContext.PremiumSnapshot?
    var opponents: BotOpponentModel?

    init(
        block: GameBlock = .fourth,
        roundIndexInBlock: Int = 7,
        totalRoundsInBlock: Int = 8,
        totalScores: [Int]? = nil,
        playerIndex: Int = 0,
        dealerIndex: Int = 2,
        playerCount: Int = 4,
        round: BotMatchContext.RoundSnapshot? = nil,
        premium: BotMatchContext.PremiumSnapshot? = nil,
        opponents: BotOpponentModel? = nil
    ) {
        self.block = block
        self.roundIndexInBlock = roundIndexInBlock
        self.totalRoundsInBlock = totalRoundsInBlock
        self.totalScores = totalScores ?? Self.defaultScores(playerCount: playerCount)
        self.playerIndex = playerIndex
        self.dealerIndex = dealerIndex
        self.playerCount = playerCount
        self.round = round
        self.premium = premium
        self.opponents = opponents
    }

    func build() -> BotMatchContext {
        return BotMatchContext(
            block: block,
            roundIndexInBlock: roundIndexInBlock,
            totalRoundsInBlock: totalRoundsInBlock,
            totalScores: totalScores,
            playerIndex: playerIndex,
            dealerIndex: dealerIndex,
            playerCount: playerCount,
            round: round,
            premium: premium,
            opponents: opponents
        )
    }

    static func defaultScores(
        playerCount: Int = 4,
        score: Int = 100
    ) -> [Int] {
        return Array(repeating: score, count: playerCount)
    }

    static func roundSnapshot(
        bids: [Int],
        tricksTaken: [Int],
        isBlindBid: [Bool]
    ) -> BotMatchContext.RoundSnapshot {
        return BotMatchContext.RoundSnapshot(
            bids: bids,
            tricksTaken: tricksTaken,
            isBlindBid: isBlindBid
        )
    }

    static func premiumSnapshot(
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
    ) -> BotMatchContext.PremiumSnapshot {
        return BotMatchContext.PremiumSnapshot(
            completedRoundsInBlock: completedRoundsInBlock,
            remainingRoundsInBlock: remainingRoundsInBlock,
            isPremiumCandidateSoFar: isPremiumCandidateSoFar,
            isZeroPremiumRelevantInBlock: isZeroPremiumRelevantInBlock,
            isZeroPremiumCandidateSoFar: isZeroPremiumCandidateSoFar,
            leftNeighborIndex: leftNeighborIndex,
            leftNeighborIsPremiumCandidateSoFar: leftNeighborIsPremiumCandidateSoFar,
            isPenaltyTargetRiskSoFar: isPenaltyTargetRiskSoFar,
            premiumCandidatesThreateningPenaltyCount: premiumCandidatesThreateningPenaltyCount,
            opponentPremiumCandidatesSoFarCount: opponentPremiumCandidatesSoFarCount
        )
    }

    static func opponentSnapshot(
        playerIndex: Int,
        observedRounds: Int,
        blindBidRate: Double,
        exactBidRate: Double,
        overbidRate: Double,
        underbidRate: Double,
        averageBidAggression: Double
    ) -> BotOpponentModel.OpponentSnapshot {
        return BotOpponentModel.OpponentSnapshot(
            playerIndex: playerIndex,
            observedRounds: observedRounds,
            blindBidRate: blindBidRate,
            exactBidRate: exactBidRate,
            overbidRate: overbidRate,
            underbidRate: underbidRate,
            averageBidAggression: averageBidAggression
        )
    }

    static func opponentModel(
        perspectivePlayerIndex: Int = 0,
        leftNeighborIndex: Int?,
        leftNeighbor: BotOpponentModel.OpponentSnapshot?,
        others: [BotOpponentModel.OpponentSnapshot]
    ) -> BotOpponentModel {
        var snapshots = others
        if let leftNeighbor {
            snapshots.insert(leftNeighbor, at: 0)
        }

        return BotOpponentModel(
            perspectivePlayerIndex: perspectivePlayerIndex,
            leftNeighborIndex: leftNeighborIndex,
            snapshots: snapshots
        )
    }
}
