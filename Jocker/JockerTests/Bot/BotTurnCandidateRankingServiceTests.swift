//
//  BotTurnCandidateRankingServiceTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
@testable import Jocker

final class BotTurnCandidateRankingServiceTests: XCTestCase {
    private let service = BotTurnCandidateRankingService(tuning: BotTuning(difficulty: .hard))

    func testIsBetterCandidate_prefersHigherUtilityBeyondTolerance() {
        let current = evaluation(card: card(.hearts, .queen), utility: 10, immediateWinProbability: 0.5, threat: 5)
        let candidate = evaluation(card: card(.hearts, .king), utility: 25, immediateWinProbability: 0.1, threat: 20)

        XCTAssertTrue(service.isBetterCandidate(candidate, than: current, shouldChaseTrick: true))
        XCTAssertFalse(service.isBetterCandidate(current, than: candidate, shouldChaseTrick: true))
    }

    func testIsBetterCandidate_whenChasingUsesProbabilityThenThreatTieBreak() {
        let utility = 10.0
        let base = evaluation(card: card(.hearts, .queen), utility: utility, immediateWinProbability: 0.4, threat: 8)
        let betterWinChance = evaluation(card: card(.hearts, .king), utility: utility, immediateWinProbability: 0.8, threat: 20)
        let lowerThreat = evaluation(card: card(.spades, .ten), utility: utility, immediateWinProbability: 0.4, threat: 2)

        XCTAssertTrue(service.isBetterCandidate(betterWinChance, than: base, shouldChaseTrick: true))
        XCTAssertTrue(service.isBetterCandidate(lowerThreat, than: base, shouldChaseTrick: true))
    }

    func testIsBetterCandidate_whenDumpingUsesLowerWinChanceThenHigherThreatTieBreak() {
        let utility = 10.0
        let base = evaluation(card: card(.hearts, .queen), utility: utility, immediateWinProbability: 0.6, threat: 4)
        let betterDumpChance = evaluation(card: card(.hearts, .king), utility: utility, immediateWinProbability: 0.1, threat: 1)
        let higherThreat = evaluation(card: card(.spades, .ten), utility: utility, immediateWinProbability: 0.6, threat: 12)

        XCTAssertTrue(service.isBetterCandidate(betterDumpChance, than: base, shouldChaseTrick: false))
        XCTAssertTrue(service.isBetterCandidate(higherThreat, than: base, shouldChaseTrick: false))
    }

    func testIsBetterCandidate_whenFullyEqualUsesDeterministicCardThenDecisionTieBreak() {
        let cardA = card(.clubs, .ten)
        let cardB = card(.spades, .ten)
        let lower = cardA < cardB ? cardA : cardB
        let higher = cardA < cardB ? cardB : cardA

        let baseMetrics = (utility: 7.0, immediateWinProbability: 0.5, threat: 3.0)
        let lowerCardEval = evaluation(
            card: lower,
            decision: .defaultNonLead,
            utility: baseMetrics.utility,
            immediateWinProbability: baseMetrics.immediateWinProbability,
            threat: baseMetrics.threat
        )
        let higherCardEval = evaluation(
            card: higher,
            decision: .defaultNonLead,
            utility: baseMetrics.utility,
            immediateWinProbability: baseMetrics.immediateWinProbability,
            threat: baseMetrics.threat
        )

        XCTAssertTrue(service.isBetterCandidate(lowerCardEval, than: higherCardEval, shouldChaseTrick: true))

        let faceDown = evaluation(
            card: .joker,
            decision: JokerPlayDecision(style: .faceDown, leadDeclaration: nil),
            utility: baseMetrics.utility,
            immediateWinProbability: baseMetrics.immediateWinProbability,
            threat: baseMetrics.threat
        )
        let faceUp = evaluation(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: nil),
            utility: baseMetrics.utility,
            immediateWinProbability: baseMetrics.immediateWinProbability,
            threat: baseMetrics.threat
        )

        XCTAssertTrue(service.isBetterCandidate(faceDown, than: faceUp, shouldChaseTrick: false))
    }

    func testMoveUtility_whenChasingPenalizesSpendingJokerIfWinningNonJokerExists() {
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.hearts, .queen), fromPlayer: 1, animated: false)

        let commonParams = commonUtilityParams(
            trickNode: trickNode,
            trump: .clubs,
            shouldChaseTrick: true,
            hasWinningNonJoker: true,
            hasLosingNonJoker: false
        )

        let jokerUtility = service.moveUtility(
            projectedScore: commonParams.projectedScore,
            immediateWinProbability: commonParams.immediateWinProbability,
            threat: commonParams.threat,
            move: .init(card: .joker, decision: JokerPlayDecision(style: .faceUp, leadDeclaration: nil)),
            trickNode: commonParams.trickNode,
            trump: commonParams.trump,
            shouldChaseTrick: commonParams.shouldChaseTrick,
            hasWinningNonJoker: commonParams.hasWinningNonJoker,
            hasLosingNonJoker: commonParams.hasLosingNonJoker,
            tricksNeededToMatchBid: commonParams.tricksNeededToMatchBid,
            tricksRemainingIncludingCurrent: commonParams.tricksRemainingIncludingCurrent,
            chasePressure: commonParams.chasePressure
        )
        let nonJokerUtility = service.moveUtility(
            projectedScore: commonParams.projectedScore,
            immediateWinProbability: commonParams.immediateWinProbability,
            threat: commonParams.threat,
            move: .init(card: card(.hearts, .king), decision: .defaultNonLead),
            trickNode: commonParams.trickNode,
            trump: commonParams.trump,
            shouldChaseTrick: commonParams.shouldChaseTrick,
            hasWinningNonJoker: commonParams.hasWinningNonJoker,
            hasLosingNonJoker: commonParams.hasLosingNonJoker,
            tricksNeededToMatchBid: commonParams.tricksNeededToMatchBid,
            tricksRemainingIncludingCurrent: commonParams.tricksRemainingIncludingCurrent,
            chasePressure: commonParams.chasePressure
        )

        XCTAssertLessThan(jokerUtility, nonJokerUtility)
    }

    func testMoveUtility_whenDumpingPenalizesNonLeadFaceUpJokerComparedToFaceDown() {
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.clubs, .ace), fromPlayer: 1, animated: false)

        let commonParams = commonUtilityParams(
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false
        )

        let faceDown = service.moveUtility(
            projectedScore: commonParams.projectedScore,
            immediateWinProbability: commonParams.immediateWinProbability,
            threat: commonParams.threat,
            move: .init(card: .joker, decision: JokerPlayDecision(style: .faceDown, leadDeclaration: nil)),
            trickNode: commonParams.trickNode,
            trump: commonParams.trump,
            shouldChaseTrick: commonParams.shouldChaseTrick,
            hasWinningNonJoker: commonParams.hasWinningNonJoker,
            hasLosingNonJoker: commonParams.hasLosingNonJoker,
            tricksNeededToMatchBid: commonParams.tricksNeededToMatchBid,
            tricksRemainingIncludingCurrent: commonParams.tricksRemainingIncludingCurrent,
            chasePressure: commonParams.chasePressure
        )
        let faceUp = service.moveUtility(
            projectedScore: commonParams.projectedScore,
            immediateWinProbability: commonParams.immediateWinProbability,
            threat: commonParams.threat,
            move: .init(card: .joker, decision: JokerPlayDecision(style: .faceUp, leadDeclaration: nil)),
            trickNode: commonParams.trickNode,
            trump: commonParams.trump,
            shouldChaseTrick: commonParams.shouldChaseTrick,
            hasWinningNonJoker: commonParams.hasWinningNonJoker,
            hasLosingNonJoker: commonParams.hasLosingNonJoker,
            tricksNeededToMatchBid: commonParams.tricksNeededToMatchBid,
            tricksRemainingIncludingCurrent: commonParams.tricksRemainingIncludingCurrent,
            chasePressure: commonParams.chasePressure
        )

        XCTAssertGreaterThan(faceDown, faceUp)
    }

    private func evaluation(
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

    private func commonUtilityParams(
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

    private func card(_ suit: Suit, _ rank: Rank) -> Card {
        return .regular(suit: suit, rank: rank)
    }
}
