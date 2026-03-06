//
//  BotMatchContextBuilderTests.swift
//  JockerTests
//
//  Created by Codex on 05.03.2026.
//

import XCTest
@testable import Jocker

final class BotMatchContextBuilderTests: XCTestCase {
    /// Тестирует создание контекста с невалидными параметрами игрока.
    /// Проверяет:
    /// - playerIndex = -1 возвращает nil
    /// - playerIndex за пределами диапазона возвращает nil
    /// - playerCount = 0 возвращает nil
    func testBuildContext_invalidPlayer_returnsNil() {
        let gameState = BotMatchContextBuilderTestFixture.makeGameState(playerCount: 4)
        let scoreManager = ScoreManager(playerCount: 4)

        XCTAssertNil(
            BotMatchContextBuilder.build(
                gameState: gameState,
                scoreManager: scoreManager,
                playerIndex: -1,
                playerCount: 4
            )
        )
        XCTAssertNil(
            BotMatchContextBuilder.build(
                gameState: gameState,
                scoreManager: scoreManager,
                playerIndex: 4,
                playerCount: 4
            )
        )
        XCTAssertNil(
            BotMatchContextBuilder.build(
                gameState: gameState,
                scoreManager: scoreManager,
                playerIndex: 0,
                playerCount: 0
            )
        )
    }

    /// Тестирует, что totalScores дополняется нулями когда в scoreManager меньше игроков.
    /// Проверяет:
    /// - Контекст имеет totalScores.count = playerCount
    /// - Первые два игрока имеют реальные очки
    /// - Последние два игрока имеют нулевые очки (дополнены)
    func testBuildContext_totalScores_whenScoreManagerHasFewerPlayers_padsZerosToPlayerCount() {
        let gameState = BotMatchContextBuilderTestFixture.makeGameState(playerCount: 4)
        let scoreManager = ScoreManager(playerCount: 2)
        scoreManager.recordRoundResults([
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 1, bid: 1, tricksTaken: 1),
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 1, bid: 0, tricksTaken: 0)
        ])

        let context = BotMatchContextBuilder.build(
            gameState: gameState,
            scoreManager: scoreManager,
            playerIndex: 1,
            playerCount: 4
        )

        XCTAssertEqual(context?.totalScores.count, 4)
        XCTAssertEqual(context?.totalScores[0], 100)
        XCTAssertEqual(context?.totalScores[1], 50)
        XCTAssertEqual(context?.totalScores[2], 0)
        XCTAssertEqual(context?.totalScores[3], 0)
    }

    /// Тестирует, что round snapshot правильно захватывает ставки, взятки и blind флаги.
    /// Проверяет:
    /// - bids массив со ставками всех игроков
    /// - tricksTaken массив со взятыми взятками
    /// - isBlindBid массив с флагами blind ставок
    func testBuildContext_roundSnapshot_capturesBidsTricksAndBlindFlags() {
        let gameState = BotMatchContextBuilderTestFixture.makeGameState(playerCount: 4)
        let scoreManager = ScoreManager(playerCount: 4)

        gameState.setBid(2, forPlayerAt: 0, isBlind: true, lockBeforeDeal: true)
        gameState.setBid(1, forPlayerAt: 1)
        gameState.setBid(0, forPlayerAt: 2)
        gameState.setBid(3, forPlayerAt: 3)
        gameState.beginPlayingAfterBids()
        gameState.completeTrick(winner: 0)
        gameState.completeTrick(winner: 0)
        gameState.completeTrick(winner: 3)

        let context = BotMatchContextBuilder.build(
            gameState: gameState,
            scoreManager: scoreManager,
            playerIndex: 0,
            playerCount: 4
        )

        XCTAssertEqual(context?.round?.bids, [2, 1, 0, 3])
        XCTAssertEqual(context?.round?.tricksTaken, [2, 0, 0, 1])
        XCTAssertEqual(context?.round?.isBlindBid, [true, false, false, false])
    }

    /// Тестирует premium snapshot в начале блока.
    /// Проверяет:
    /// - completedRoundsInBlock = 0
    /// - isPremiumCandidateSoFar = true (по умолчанию)
    /// - isZeroPremiumRelevantInBlock = true (блок 1 или 3)
    /// - isPenaltyTargetRiskSoFar = false
    func testBuildContext_premiumSnapshot_atBlockStart_hasNoPenaltyRiskAndZeroPremiumCandidate() {
        let gameState = BotMatchContextBuilderTestFixture.makeGameState(playerCount: 4)
        let scoreManager = ScoreManager(playerCount: 4)

        let context = BotMatchContextBuilder.build(
            gameState: gameState,
            scoreManager: scoreManager,
            playerIndex: 0,
            playerCount: 4
        )

        XCTAssertEqual(context?.premium?.completedRoundsInBlock, 0)
        XCTAssertEqual(context?.premium?.remainingRoundsInBlock, gameState.totalRoundsInBlock)
        XCTAssertEqual(context?.premium?.isPremiumCandidateSoFar, true)
        XCTAssertEqual(context?.premium?.isZeroPremiumRelevantInBlock, true)
        XCTAssertEqual(context?.premium?.isZeroPremiumCandidateSoFar, true)
        XCTAssertEqual(context?.premium?.isPenaltyTargetRiskSoFar, false)
        XCTAssertEqual(context?.premium?.premiumCandidatesThreateningPenaltyCount, 0)
    }

    /// Тестирует, что premium и zero premium кандидаты правильно определяются.
    /// Проверяет:
    /// - completedRoundsInBlock = 1
    /// - isPremiumCandidateSoFar = true (все bid matched)
    /// - isZeroPremiumCandidateSoFar = true (все нулевые ставки)
    func testBuildContext_premiumSnapshot_detectsPremiumAndZeroPremiumCandidateCorrectly() {
        let gameState = BotMatchContextBuilderTestFixture.makeGameState(playerCount: 4)
        let scoreManager = ScoreManager(playerCount: 4)
        scoreManager.recordRoundResults([
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 1, bid: 0, tricksTaken: 0),
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 1, bid: 1, tricksTaken: 0),
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 1, bid: 0, tricksTaken: 0),
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 1, bid: 1, tricksTaken: 0)
        ])

        let context = BotMatchContextBuilder.build(
            gameState: gameState,
            scoreManager: scoreManager,
            playerIndex: 0,
            playerCount: 4
        )

        XCTAssertEqual(context?.premium?.completedRoundsInBlock, 1)
        XCTAssertEqual(context?.premium?.isPremiumCandidateSoFar, true)
        XCTAssertEqual(context?.premium?.isZeroPremiumCandidateSoFar, true)
        XCTAssertEqual(context?.premium?.opponentPremiumCandidatesSoFarCount, 1)
    }

    /// Тестирует, что penalty target risk определяется от opponent premium кандидата.
    /// Проверяет:
    /// - leftNeighborIndex = 1
    /// - leftNeighborIsPremiumCandidateSoFar = false
    /// - isPenaltyTargetRiskSoFar = true (p3 кандидат → target p0)
    /// - premiumCandidatesThreateningPenaltyCount = 1
    func testBuildContext_premiumSnapshot_marksPenaltyTargetRiskFromOpponentPremiumCandidate() {
        let gameState = BotMatchContextBuilderTestFixture.makeGameState(playerCount: 4)
        let scoreManager = ScoreManager(playerCount: 4)
        scoreManager.recordRoundResults([
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 1, bid: 1, tricksTaken: 0), // p0 not candidate
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 1, bid: 1, tricksTaken: 0), // p1 not candidate
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 1, bid: 1, tricksTaken: 0), // p2 not candidate
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 1, bid: 0, tricksTaken: 0)  // p3 candidate -> target p0
        ])

        let context = BotMatchContextBuilder.build(
            gameState: gameState,
            scoreManager: scoreManager,
            playerIndex: 0,
            playerCount: 4
        )

        XCTAssertEqual(context?.premium?.leftNeighborIndex, 1)
        XCTAssertEqual(context?.premium?.leftNeighborIsPremiumCandidateSoFar, false)
        XCTAssertEqual(context?.premium?.isPenaltyTargetRiskSoFar, true)
        XCTAssertEqual(context?.premium?.premiumCandidatesThreateningPenaltyCount, 1)
        XCTAssertEqual(context?.premium?.opponentPremiumCandidatesSoFarCount, 1)
    }

    /// Тестирует, что флаг left neighbor premium кандидата правильно установлен.
    /// Проверяет:
    /// - leftNeighborIndex = 1
    /// - leftNeighborIsPremiumCandidateSoFar = true (p1 кандидат)
    /// - isPenaltyTargetRiskSoFar = false
    func testBuildContext_premiumSnapshot_leftNeighborPremiumCandidateFlagSetCorrectly() {
        let gameState = BotMatchContextBuilderTestFixture.makeGameState(playerCount: 4)
        let scoreManager = ScoreManager(playerCount: 4)
        scoreManager.recordRoundResults([
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 1, bid: 1, tricksTaken: 0), // p0 not candidate
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 1, bid: 0, tricksTaken: 0), // p1 candidate (left neighbor for p0)
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 1, bid: 1, tricksTaken: 0), // p2 not candidate
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 1, bid: 1, tricksTaken: 0)  // p3 not candidate
        ])

        let context = BotMatchContextBuilder.build(
            gameState: gameState,
            scoreManager: scoreManager,
            playerIndex: 0,
            playerCount: 4
        )

        XCTAssertEqual(context?.premium?.leftNeighborIndex, 1)
        XCTAssertEqual(context?.premium?.leftNeighborIsPremiumCandidateSoFar, true)
        XCTAssertEqual(context?.premium?.isPenaltyTargetRiskSoFar, false)
    }

    /// Тестирует, что opponentPremiumCandidatesCount исключает себя.
    /// Проверяет:
    /// - isPremiumCandidateSoFar = true (p0 кандидат)
    /// - opponentPremiumCandidatesSoFarCount = 1 (только p2, исключая p0)
    func testBuildContext_premiumSnapshot_opponentPremiumCandidatesCount_excludesSelf() {
        let gameState = BotMatchContextBuilderTestFixture.makeGameState(playerCount: 4)
        let scoreManager = ScoreManager(playerCount: 4)
        scoreManager.recordRoundResults([
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 1, bid: 0, tricksTaken: 0), // p0 self candidate
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 1, bid: 1, tricksTaken: 0), // p1 not candidate
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 1, bid: 0, tricksTaken: 0), // p2 opponent candidate
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 1, bid: 1, tricksTaken: 0)  // p3 not candidate
        ])

        let context = BotMatchContextBuilder.build(
            gameState: gameState,
            scoreManager: scoreManager,
            playerIndex: 0,
            playerCount: 4
        )

        XCTAssertEqual(context?.premium?.isPremiumCandidateSoFar, true)
        XCTAssertEqual(context?.premium?.opponentPremiumCandidatesSoFarCount, 1)
    }

    /// Тестирует, что opponent model snapshots строятся из round results.
    /// Проверяет:
    /// - perspectivePlayerIndex = 0
    /// - leftNeighborIndex = 1
    /// - snapshots.count = 3 (для 3 оппонентов)
    /// - p1: blindBidRate = 0.5, overbidRate = 0.5, underbidRate = 0.5
    func testBuildContext_opponentModel_snapshotsBuiltFromRoundResults() {
        let gameState = BotMatchContextBuilderTestFixture.makeGameState(playerCount: 4)
        let scoreManager = ScoreManager(playerCount: 4)

        scoreManager.recordRoundResults([
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 2, bid: 1, tricksTaken: 1, isBlind: false), // p0
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 2, bid: 2, tricksTaken: 1, isBlind: true),  // p1 underbid + blind
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 2, bid: 0, tricksTaken: 0, isBlind: false), // p2 exact
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 2, bid: 1, tricksTaken: 2, isBlind: false)  // p3 overbid
        ])
        scoreManager.recordRoundResults([
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 4, bid: 2, tricksTaken: 2, isBlind: false), // p0
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 4, bid: 3, tricksTaken: 4, isBlind: false), // p1 overbid
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 4, bid: 2, tricksTaken: 2, isBlind: false), // p2 exact
            BotMatchContextBuilderTestFixture.roundResult(cardsInRound: 4, bid: 1, tricksTaken: 0, isBlind: false)  // p3 underbid
        ])

        let context = BotMatchContextBuilder.build(
            gameState: gameState,
            scoreManager: scoreManager,
            playerIndex: 0,
            playerCount: 4
        )

        XCTAssertEqual(context?.opponents?.perspectivePlayerIndex, 0)
        XCTAssertEqual(context?.opponents?.leftNeighborIndex, 1)
        XCTAssertEqual(context?.opponents?.snapshots.count, 3)

        let p1 = context?.opponents?.snapshot(for: 1)
        XCTAssertEqual(p1?.observedRounds, 2)
        XCTAssertEqual(p1?.blindBidRate ?? -1, 0.5, accuracy: 0.000_1)
        XCTAssertEqual(p1?.exactBidRate ?? -1, 0.0, accuracy: 0.000_1)
        XCTAssertEqual(p1?.overbidRate ?? -1, 0.5, accuracy: 0.000_1)
        XCTAssertEqual(p1?.underbidRate ?? -1, 0.5, accuracy: 0.000_1)
        XCTAssertEqual(p1?.averageBidAggression ?? -1, 0.875, accuracy: 0.000_1)
    }

    /// Тестирует, что opponent model без evidence возвращает нейтральные snapshots.
    /// Проверяет:
    /// - snapshots.count = 3
    /// - Все snapshots: hasEvidence = false, observedRounds = 0
    /// - Все rates = 0 (neutral)
    func testBuildContext_opponentModel_zeroEvidenceAtBlockStart_returnsNeutralSnapshots() {
        let gameState = BotMatchContextBuilderTestFixture.makeGameState(playerCount: 4)
        let scoreManager = ScoreManager(playerCount: 4)

        let context = BotMatchContextBuilder.build(
            gameState: gameState,
            scoreManager: scoreManager,
            playerIndex: 0,
            playerCount: 4
        )

        let snapshots = context?.opponents?.snapshots ?? []
        XCTAssertEqual(snapshots.count, 3)
        XCTAssertTrue(snapshots.allSatisfy { !$0.hasEvidence })
        XCTAssertTrue(snapshots.allSatisfy { $0.observedRounds == 0 })
        XCTAssertTrue(snapshots.allSatisfy { $0.blindBidRate == 0 })
        XCTAssertTrue(snapshots.allSatisfy { $0.exactBidRate == 0 })
        XCTAssertTrue(snapshots.allSatisfy { $0.overbidRate == 0 })
        XCTAssertTrue(snapshots.allSatisfy { $0.underbidRate == 0 })
        XCTAssertTrue(snapshots.allSatisfy { $0.averageBidAggression == 0 })
    }
}
