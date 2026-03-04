//
//  BotTurnCandidateRankingServiceTests_TieBreak.swift
//  JockerTests
//
//  Created by Codex on 04.03.2026.
//

import XCTest
@testable import Jocker

extension BotTurnCandidateRankingServiceTests {
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
}
