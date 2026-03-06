//
//  BotTurnCandidateRankingServiceTestFixture.swift
//  JockerTests
//
//  Created by Codex on 04.03.2026.
//

import XCTest
@testable import Jocker

enum BotTurnCandidateRankingServiceTestFixture {
    static func makeTrickNode() -> TrickNode {
        return BotTrickNodeBuilder.make()
    }

    static func play(
        _ card: Card,
        fromPlayer playerNumber: Int = 1,
        into trickNode: TrickNode
    ) {
        BotTrickNodeBuilder.play(
            card,
            fromPlayer: playerNumber,
            into: trickNode
        )
    }

    static func evaluation(
        card: Card,
        decision: JokerPlayDecision = .defaultNonLead,
        utility: Double,
        immediateWinProbability: Double,
        threat: Double
    ) -> BotTurnCandidateRankingService.Evaluation {
        return .init(
            move: .init(card: card, decision: decision),
            utility: utility,
            immediateWinProbability: immediateWinProbability,
            threat: threat
        )
    }

    static func makeHand(_ cards: Card...) -> [Card] {
        return BotTestCards.hand(cards)
    }

    static func makeHand(_ cards: [Card]) -> [Card] {
        return BotTestCards.hand(cards)
    }

    static func makeContext(
        block: GameBlock,
        roundIndexInBlock: Int,
        totalRoundsInBlock: Int,
        totalScores: [Int],
        playerIndex: Int,
        dealerIndex: Int,
        playerCount: Int,
        premium: BotMatchContext.PremiumSnapshot? = nil,
        opponents: BotOpponentModel? = nil
    ) -> BotMatchContext {
        return BotMatchContextTestBuilder(
            block: block,
            roundIndexInBlock: roundIndexInBlock,
            totalRoundsInBlock: totalRoundsInBlock,
            totalScores: totalScores,
            playerIndex: playerIndex,
            dealerIndex: dealerIndex,
            playerCount: playerCount,
            premium: premium,
            opponents: opponents
        ).build()
    }

    static func commonUtilityParams(
        trickNode: TrickNode,
        trump: Suit?,
        shouldChaseTrick: Bool,
        hasWinningNonJoker: Bool,
        hasLosingNonJoker: Bool
    ) -> (
        projectedScore: Double,
        immediateWinProbability: Double,
        threat: Double,
        trickNode: TrickNode,
        trump: Suit?,
        shouldChaseTrick: Bool,
        hasWinningNonJoker: Bool,
        hasLosingNonJoker: Bool,
        tricksNeededToMatchBid: Int,
        tricksRemainingIncludingCurrent: Int,
        chasePressure: Double
    ) {
        return (
            projectedScore: 10,
            immediateWinProbability: shouldChaseTrick ? 0.85 : 0.15,
            threat: 5,
            trickNode: trickNode,
            trump: trump,
            shouldChaseTrick: shouldChaseTrick,
            hasWinningNonJoker: hasWinningNonJoker,
            hasLosingNonJoker: hasLosingNonJoker,
            tricksNeededToMatchBid: 1,
            tricksRemainingIncludingCurrent: 2,
            chasePressure: shouldChaseTrick ? 0.5 : 0.0
        )
    }

    static func card(_ suit: Suit, _ rank: Rank) -> Card {
        return BotTestCards.card(suit, rank)
    }

    static func sampleMatchContext() -> BotMatchContext {
        return BotMatchContextTestBuilder(
            block: .second,
            roundIndexInBlock: 1,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4,
            premium: nil,
            opponents: nil
        ).build()
    }

    static func makeOpponentModel(
        leftNeighborIndex: Int?,
        leftNeighbor: BotOpponentModel.OpponentSnapshot?,
        others: [BotOpponentModel.OpponentSnapshot]
    ) -> BotOpponentModel {
        return BotMatchContextTestBuilder.opponentModel(
            perspectivePlayerIndex: 0,
            leftNeighborIndex: leftNeighborIndex,
            leftNeighbor: leftNeighbor,
            others: others
        )
    }
}
