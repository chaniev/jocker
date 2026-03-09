//
//  BotTurnCandidateRankingServiceTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
@testable import Jocker

final class BotTurnCandidateRankingServiceTests: XCTestCase {
    typealias Fixture = BotTurnCandidateRankingServiceTestFixture

    let service = BotTurnCandidateRankingService(tuning: BotTuning(difficulty: .hard))

    func makeService(
        phaseRankingScale: Double = 1.0,
        phaseJokerScale: Double = 1.0
    ) -> BotTurnCandidateRankingService {
        let baseline = BotTuning(difficulty: .hard)
        let baselinePolicy = baseline.runtimePolicy
        var ranking = baselinePolicy.ranking

        if phaseRankingScale != 1.0 {
            let early = 1.0 / phaseRankingScale
            let ramp = PhaseMultipliers(early: early, mid: 1.0, late: phaseRankingScale)
            ranking.phaseMatchCatchUp = ramp
            ranking.phasePremiumPressure = ramp
            ranking.phasePenaltyAvoid = ramp
        }

        if phaseJokerScale != 1.0 {
            let earlyRamp = PhaseMultipliers(
                early: phaseJokerScale,
                mid: 1.0,
                late: 1.0 / phaseJokerScale
            )
            let lateRamp = PhaseMultipliers(
                early: 1.0 / phaseJokerScale,
                mid: 1.0,
                late: phaseJokerScale
            )
            ranking.jokerDeclaration.phaseEarlySpend = earlyRamp
            ranking.jokerDeclaration.phaseLateSpend = lateRamp
            ranking.jokerDeclaration.phaseDeclarationPressure = lateRamp
        }

        let runtimePolicy = BotRuntimePolicy.assembled(
            difficulty: baseline.difficulty,
            ranking: ranking,
            bidding: baselinePolicy.bidding,
            evaluator: baselinePolicy.evaluator,
            rollout: baselinePolicy.rollout,
            endgame: baselinePolicy.endgame,
            simulation: baselinePolicy.simulation,
            handStrength: baselinePolicy.handStrength,
            heuristics: baselinePolicy.heuristics,
            opponentModeling: baselinePolicy.opponentModeling
        )

        let tuned = BotTuning(
            difficulty: baseline.difficulty,
            turnStrategy: baseline.turnStrategy,
            bidding: baseline.bidding,
            trumpSelection: baseline.trumpSelection,
            runtimePolicy: runtimePolicy,
            timing: baseline.timing
        )
        return BotTurnCandidateRankingService(tuning: tuned)
    }

    func makeTrickNode() -> TrickNode {
        return Fixture.makeTrickNode()
    }

    func play(
        _ card: Card,
        fromPlayer playerNumber: Int = 1,
        into trickNode: TrickNode
    ) {
        Fixture.play(card, fromPlayer: playerNumber, into: trickNode)
    }

    func evaluation(
        card: Card,
        decision: JokerPlayDecision = .defaultNonLead,
        utility: Double,
        immediateWinProbability: Double,
        threat: Double
    ) -> BotTurnCandidateRankingService.Evaluation {
        return Fixture.evaluation(
            card: card,
            decision: decision,
            utility: utility,
            immediateWinProbability: immediateWinProbability,
            threat: threat
        )
    }

    func makeHand(_ cards: Card...) -> [Card] {
        return Fixture.makeHand(cards)
    }

    func makeContext(
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
        return Fixture.makeContext(
            block: block,
            roundIndexInBlock: roundIndexInBlock,
            totalRoundsInBlock: totalRoundsInBlock,
            totalScores: totalScores,
            playerIndex: playerIndex,
            dealerIndex: dealerIndex,
            playerCount: playerCount,
            premium: premium,
            opponents: opponents
        )
    }

    func commonUtilityParams(
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
        return Fixture.commonUtilityParams(
            trickNode: trickNode,
            trump: trump,
            shouldChaseTrick: shouldChaseTrick,
            hasWinningNonJoker: hasWinningNonJoker,
            hasLosingNonJoker: hasLosingNonJoker
        )
    }

    func card(_ suit: Suit, _ rank: Rank) -> Card {
        return Fixture.card(suit, rank)
    }

    func sampleMatchContext() -> BotMatchContext {
        return Fixture.sampleMatchContext()
    }

    func makeOpponentModel(
        leftNeighborIndex: Int?,
        leftNeighbor: BotOpponentModel.OpponentSnapshot?,
        others: [BotOpponentModel.OpponentSnapshot]
    ) -> BotOpponentModel {
        return Fixture.makeOpponentModel(
            leftNeighborIndex: leftNeighborIndex,
            leftNeighbor: leftNeighbor,
            others: others
        )
    }
}
