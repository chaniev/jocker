//
//  BotTuningTests.swift
//  JockerTests
//
//  Created by Codex on 15.02.2026.
//

import XCTest
@testable import Jocker

final class BotTuningTests: XCTestCase {
    func testNormalPreset_matchesLegacyReferenceValues() {
        let tuning = BotTuning(difficulty: .normal)

        XCTAssertEqual(tuning.turnStrategy.chaseWinProbabilityWeight, 50.0, accuracy: 0.000_1)
        XCTAssertEqual(tuning.turnStrategy.dumpSpendJokerPenalty, 70.0, accuracy: 0.000_1)
        XCTAssertEqual(tuning.bidding.blindDesperateBehindThreshold, 250)
        XCTAssertEqual(tuning.trumpSelection.minimumPowerToDeclareTrump, 1.55, accuracy: 0.000_1)
        XCTAssertEqual(tuning.timing.playingBotTurnDelay, 0.35, accuracy: 0.000_1)
    }

    func testDifficultyPresets_changeAggressivenessAndTempo() {
        let easy = BotTuning(difficulty: .easy)
        let normal = BotTuning(difficulty: .normal)
        let hard = BotTuning(difficulty: .hard)

        XCTAssertLessThan(easy.bidding.expectedJokerPower, normal.bidding.expectedJokerPower)
        XCTAssertLessThan(normal.bidding.expectedJokerPower, hard.bidding.expectedJokerPower)

        XCTAssertGreaterThan(easy.trumpSelection.minimumPowerToDeclareTrump, normal.trumpSelection.minimumPowerToDeclareTrump)
        XCTAssertGreaterThan(normal.trumpSelection.minimumPowerToDeclareTrump, hard.trumpSelection.minimumPowerToDeclareTrump)

        XCTAssertGreaterThan(easy.timing.playingBotTurnDelay, normal.timing.playingBotTurnDelay)
        XCTAssertGreaterThan(normal.timing.playingBotTurnDelay, hard.timing.playingBotTurnDelay)
    }
}
