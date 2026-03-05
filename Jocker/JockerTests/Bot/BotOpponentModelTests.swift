//
//  BotOpponentModelTests.swift
//  JockerTests
//
//  Created by Codex on 05.03.2026.
//

import XCTest
@testable import Jocker

final class BotOpponentModelTests: XCTestCase {
    /// Тестирует, что hasEvidence возвращает true когда observedRounds > 0.
    /// Проверяет:
    /// - observedRounds = 2 → hasEvidence = true
    func testOpponentSnapshot_hasEvidence_returnsTrueWhenObservedRoundsGreaterThanZero() {
        let snapshot = makeSnapshot(playerIndex: 1, observedRounds: 2)

        XCTAssertTrue(snapshot.hasEvidence)
    }

    /// Тестирует, что hasEvidence возвращает false когда observedRounds = 0.
    /// Проверяет:
    /// - observedRounds = 0 → hasEvidence = false
    func testOpponentSnapshot_hasEvidence_returnsFalseWhenObservedRoundsIsZero() {
        let snapshot = makeSnapshot(playerIndex: 1, observedRounds: 0)

        XCTAssertFalse(snapshot.hasEvidence)
    }

    /// Тестирует, что snapshot(for:) возвращает правильный snapshot по индексу игрока.
    /// Проверяет:
    /// - snapshot для playerIndex = 2 имеет observedRounds = 3
    func testSnapshot_for_returnsCorrectSnapshotByPlayerIndex() {
        let model = BotOpponentModel(
            perspectivePlayerIndex: 0,
            leftNeighborIndex: 1,
            snapshots: [
                makeSnapshot(playerIndex: 1, observedRounds: 2),
                makeSnapshot(playerIndex: 2, observedRounds: 3),
                makeSnapshot(playerIndex: 3, observedRounds: 1)
            ]
        )

        let snapshot = model.snapshot(for: 2)

        XCTAssertEqual(snapshot?.playerIndex, 2)
        XCTAssertEqual(snapshot?.observedRounds, 3)
    }

    /// Тестирует, что snapshot(for:) возвращает nil для неизвестного индекса игрока.
    /// Проверяет:
    /// - snapshot для playerIndex = 9 возвращает nil
    func testSnapshot_for_returnsNilForUnknownPlayerIndex() {
        let model = BotOpponentModel(
            perspectivePlayerIndex: 0,
            leftNeighborIndex: 1,
            snapshots: [makeSnapshot(playerIndex: 1, observedRounds: 1)]
        )

        XCTAssertNil(model.snapshot(for: 9))
    }

    /// Тестирует, что leftNeighborIndex правильно хранится для 4 игроков.
    /// Проверяет:
    /// - perspective = 3 → expectedLeftNeighbor = 0
    func testLeftNeighborIndex_isStoredCorrectlyForFourPlayers() {
        let perspective = 3
        let expectedLeftNeighbor = PremiumRules.leftNeighbor(of: perspective, playerCount: 4)
        let model = BotOpponentModel(
            perspectivePlayerIndex: perspective,
            leftNeighborIndex: expectedLeftNeighbor,
            snapshots: [makeSnapshot(playerIndex: 0, observedRounds: 1)]
        )

        XCTAssertEqual(model.leftNeighborIndex, 0)
    }

    /// Тестирует, что leftNeighborIndex может быть nil когда нет соседей.
    /// Проверяет:
    /// - leftNeighborIndex = nil
    /// - snapshots = []
    func testLeftNeighborIndex_canBeNilWhenNoNeighborsAvailable() {
        let model = BotOpponentModel(
            perspectivePlayerIndex: 0,
            leftNeighborIndex: nil,
            snapshots: []
        )

        XCTAssertNil(model.leftNeighborIndex)
        XCTAssertTrue(model.snapshots.isEmpty)
    }

    /// Тестирует, что blindBidRate находится в диапазоне [0, 1].
    /// Проверяет:
    /// - blindBidRate = 0.75 → в допустимом диапазоне
    func testOpponentSnapshot_blindBidRate_isWithinZeroToOne() {
        let snapshot = makeSnapshot(playerIndex: 1, observedRounds: 4, blindBidRate: 0.75)

        XCTAssertGreaterThanOrEqual(snapshot.blindBidRate, 0.0)
        XCTAssertLessThanOrEqual(snapshot.blindBidRate, 1.0)
    }

    /// Тестирует, что averageBidAggression находится в допустимом диапазоне.
    /// Проверяет:
    /// - averageBidAggression = 0.82 → в диапазоне [0, 1]
    func testOpponentSnapshot_averageBidAggression_isWithinExpectedRange() {
        let snapshot = makeSnapshot(playerIndex: 2, observedRounds: 3, averageBidAggression: 0.82)

        XCTAssertGreaterThanOrEqual(snapshot.averageBidAggression, 0.0)
        XCTAssertLessThanOrEqual(snapshot.averageBidAggression, 1.0)
    }

    /// Тестирует, что snapshots иммутабельны после инициализации.
    /// Проверяет:
    /// - Копия массива не изменяет оригинал
    /// - model.snapshots.count остаётся 2
    func testSnapshots_isImmutableAfterInitialization() {
        let model = BotOpponentModel(
            perspectivePlayerIndex: 0,
            leftNeighborIndex: 1,
            snapshots: [
                makeSnapshot(playerIndex: 1, observedRounds: 1),
                makeSnapshot(playerIndex: 2, observedRounds: 1)
            ]
        )

        var detachedCopy = model.snapshots
        detachedCopy.removeAll()

        XCTAssertEqual(model.snapshots.count, 2)
    }

    /// Тестирует, что Equatable conformance работает корректно.
    /// Проверяет:
    /// - lhs == rhs (одинаковые snapshots)
    /// - lhs != different (разные snapshots)
    func testEquatable_conformance_worksCorrectly() {
        let lhs = BotOpponentModel(
            perspectivePlayerIndex: 0,
            leftNeighborIndex: 1,
            snapshots: [
                makeSnapshot(playerIndex: 1, observedRounds: 2),
                makeSnapshot(playerIndex: 2, observedRounds: 1)
            ]
        )
        let rhs = BotOpponentModel(
            perspectivePlayerIndex: 0,
            leftNeighborIndex: 1,
            snapshots: [
                makeSnapshot(playerIndex: 1, observedRounds: 2),
                makeSnapshot(playerIndex: 2, observedRounds: 1)
            ]
        )
        let different = BotOpponentModel(
            perspectivePlayerIndex: 0,
            leftNeighborIndex: 1,
            snapshots: [makeSnapshot(playerIndex: 1, observedRounds: 99)]
        )

        XCTAssertEqual(lhs, rhs)
        XCTAssertNotEqual(lhs, different)
    }

    private func makeSnapshot(
        playerIndex: Int,
        observedRounds: Int,
        blindBidRate: Double = 0.5,
        exactBidRate: Double = 0.5,
        overbidRate: Double = 0.25,
        underbidRate: Double = 0.25,
        averageBidAggression: Double = 0.5
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
}
