//
//  BotBlockPhaseTests.swift
//  JockerTests
//

import XCTest
@testable import Jocker

final class BotBlockPhaseTests: XCTestCase {

    func test_earlyPhase_boundaryStart() {
        XCTAssertEqual(BotBlockPhase.from(blockProgressFraction: 0.0), .early)
    }

    func test_earlyPhase_justBeforeMid() {
        let t = 1.0 / 3.0 - 1e-9
        XCTAssertEqual(BotBlockPhase.from(blockProgressFraction: t), .early)
    }

    func test_midPhase_boundaryStart() {
        XCTAssertEqual(BotBlockPhase.from(blockProgressFraction: 1.0 / 3.0), .mid)
    }

    func test_midPhase_middle() {
        XCTAssertEqual(BotBlockPhase.from(blockProgressFraction: 0.5), .mid)
    }

    func test_midPhase_justBeforeLate() {
        let t = 2.0 / 3.0 - 1e-9
        XCTAssertEqual(BotBlockPhase.from(blockProgressFraction: t), .mid)
    }

    func test_latePhase_boundaryStart() {
        XCTAssertEqual(BotBlockPhase.from(blockProgressFraction: 2.0 / 3.0), .late)
    }

    func test_latePhase_boundaryEnd() {
        XCTAssertEqual(BotBlockPhase.from(blockProgressFraction: 1.0), .late)
    }

    func test_clamping_belowZero() {
        XCTAssertEqual(BotBlockPhase.from(blockProgressFraction: -0.5), .early)
    }

    func test_clamping_aboveOne() {
        XCTAssertEqual(BotBlockPhase.from(blockProgressFraction: 1.5), .late)
    }

    func test_phaseMultipliers_neutral() {
        let m = PhaseMultipliers.neutral
        XCTAssertEqual(m.multiplier(for: .early), 1.0)
        XCTAssertEqual(m.multiplier(for: .mid), 1.0)
        XCTAssertEqual(m.multiplier(for: .late), 1.0)
    }

    func test_phaseMultipliers_custom() {
        let m = PhaseMultipliers(early: 0.8, mid: 1.0, late: 1.2)
        XCTAssertEqual(m.multiplier(for: .early), 0.8)
        XCTAssertEqual(m.multiplier(for: .mid), 1.0)
        XCTAssertEqual(m.multiplier(for: .late), 1.2)
    }

    /// Нейтральный baseline: при всех фазовых коэффициентах 1.0 поведение не меняется.
    /// Hard preset использует PhaseMultipliers.neutral для всех секций.
    func test_hardBaselinePolicy_hasNeutralPhaseMultipliers() {
        let ranking = BotRuntimePolicy.hardBaselineRanking
        XCTAssertEqual(ranking.phaseMatchCatchUp.early, 1.0)
        XCTAssertEqual(ranking.phaseMatchCatchUp.mid, 1.0)
        XCTAssertEqual(ranking.phaseMatchCatchUp.late, 1.0)
        XCTAssertEqual(ranking.phasePremiumPressure.early, 1.0)
        XCTAssertEqual(ranking.phasePremiumPressure.mid, 1.0)
        XCTAssertEqual(ranking.phasePremiumPressure.late, 1.0)
        XCTAssertEqual(ranking.phasePenaltyAvoid.early, 1.0)
        XCTAssertEqual(ranking.phasePenaltyAvoid.mid, 1.0)
        XCTAssertEqual(ranking.phasePenaltyAvoid.late, 1.0)
        XCTAssertEqual(ranking.jokerDeclaration.phaseEarlySpend.early, 1.0)
        XCTAssertEqual(ranking.jokerDeclaration.phaseDeclarationPressure.early, 1.0)

        let rollout = BotRuntimePolicy.hardBaselineRollout
        XCTAssertEqual(rollout.phaseActivation.early, 1.0)
        XCTAssertEqual(rollout.phaseUtilityAdjustment.early, 1.0)

        let blind = BotRuntimePolicy.hardBaselineBidding.blindPolicy
        XCTAssertEqual(blind.phaseBlock4.early, 1.0)
        XCTAssertEqual(blind.phaseBlock4.mid, 1.0)
        XCTAssertEqual(blind.phaseBlock4.late, 1.0)
    }
}
