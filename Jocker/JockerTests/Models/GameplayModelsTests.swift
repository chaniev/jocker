//
//  GameplayModelsTests.swift
//  JockerTests
//
//  Created by Codex on 06.03.2026.
//

import XCTest
@testable import Jocker

final class GameplayModelsTests: XCTestCase {
    func testGameStateInit_createsExpectedPlayerCount() {
        let gameState = GameState(playerCount: 4)

        XCTAssertEqual(gameState.players.count, 4)
        XCTAssertEqual(gameState.phase, .notStarted)
    }

    func testGameStateStartGame_setsInitialPhaseAndTurnOrder() {
        let gameState = GameState(playerCount: 4)

        gameState.startGame(initialDealerIndex: 2)

        XCTAssertEqual(gameState.phase, .bidding)
        XCTAssertEqual(gameState.currentDealer, 2)
        XCTAssertEqual(gameState.currentPlayer, 3)
        XCTAssertEqual(gameState.currentCardsPerPlayer, 1)
    }

    func testGameStateStartNewRound_resetsPlayerRuntimeRoundData() {
        let gameState = GameState(playerCount: 4)
        gameState.startGame(initialDealerIndex: 0)
        gameState.setBid(2, forPlayerAt: 0, isBlind: true, lockBeforeDeal: true)
        gameState.beginPlayingAfterBids()
        gameState.completeTrick(winner: 0)

        gameState.startNewRound()

        XCTAssertEqual(gameState.currentRoundInBlock, 1)
        XCTAssertTrue(gameState.players.allSatisfy { $0.currentBid == 0 })
        XCTAssertTrue(gameState.players.allSatisfy { $0.tricksTaken == 0 })
        XCTAssertTrue(gameState.players.allSatisfy { !$0.isBlindBid })
        XCTAssertTrue(gameState.players.allSatisfy { !$0.isBidLockedBeforeDeal })
    }

    func testGameStateSetPlayerNames_appliesTrimmingAndFallbacks() {
        let gameState = GameState(playerCount: 4)

        gameState.setPlayerNames(["  Анна ", "", "Борис"])

        XCTAssertEqual(gameState.players[0].name, "Анна")
        XCTAssertEqual(gameState.players[1].name, "Игрок 2")
        XCTAssertEqual(gameState.players[2].name, "Борис")
        XCTAssertEqual(gameState.players[3].name, "Игрок 4")
    }

    func testGameBlock_allCases_hasFourBlocks() {
        XCTAssertEqual(GameBlock.allCases, [.first, .second, .third, .fourth])
    }

    func testGameBlockFormatter_shortTitle_forFirstBlock_containsExpectedRange() {
        let title = GameBlockFormatter.shortTitle(for: .first, playerCount: 4)

        XCTAssertEqual(title, "Блок 1 (1-8 карт)")
    }

    func testGameBlockFormatter_detailedDescription_forSecondBlock_containsExpectedText() {
        let description = GameBlockFormatter.detailedDescription(for: .second, playerCount: 4)

        XCTAssertEqual(description, "Блок 2: фиксированное количество карт (9 карт)")
    }

    func testGameConstants_deals_forPlayerCount_returnsExpectedDeals() {
        XCTAssertEqual(GameConstants.deals(for: .first, playerCount: 4), Array(1...8))
        XCTAssertEqual(GameConstants.deals(for: .second, playerCount: 4), Array(repeating: 9, count: 4))
        XCTAssertEqual(GameConstants.deals(for: .third, playerCount: 4), Array((1...8).reversed()))
        XCTAssertEqual(GameConstants.deals(for: .fourth, playerCount: 4), Array(repeating: 9, count: 4))
    }

    func testGameConstants_cardsPerPlayer_forBlockRound_returnsExpectedValueAndNilForOutOfRange() {
        XCTAssertEqual(GameConstants.cardsPerPlayer(for: .third, roundIndex: 0, playerCount: 4), 8)
        XCTAssertEqual(GameConstants.cardsPerPlayer(for: .third, roundIndex: 7, playerCount: 4), 1)
        XCTAssertNil(GameConstants.cardsPerPlayer(for: .third, roundIndex: 8, playerCount: 4))
    }

    func testBlockResult_initialization_storesValues() {
        let result = BlockResult(
            roundResults: [[roundResult(cardsInRound: 1, bid: 1, tricksTaken: 1, isBlind: false)]],
            baseScores: [100],
            premiumPlayerIndices: [0],
            premiumBonuses: [100],
            premiumPenalties: [0],
            premiumPenaltyRoundIndices: [nil],
            premiumPenaltyRoundScores: [0],
            zeroPremiumPlayerIndices: [],
            zeroPremiumBonuses: [0],
            finalScores: [200]
        )

        XCTAssertEqual(result.baseScores, [100])
        XCTAssertEqual(result.premiumPlayerIndices, [0])
        XCTAssertEqual(result.finalScores, [200])
    }

    func testRoundResult_initialization_storesValues() {
        let result = roundResult(cardsInRound: 5, bid: 2, tricksTaken: 2, isBlind: true)

        XCTAssertEqual(result.cardsInRound, 5)
        XCTAssertEqual(result.bid, 2)
        XCTAssertEqual(result.tricksTaken, 2)
        XCTAssertTrue(result.isBlind)
        XCTAssertTrue(result.bidMatched)
    }

    func testRoundResult_addingScoreAdjustment_accumulatesAdjustment() {
        let base = roundResult(cardsInRound: 3, bid: 1, tricksTaken: 1, isBlind: false)
        let adjusted = base.addingScoreAdjustment(50).addingScoreAdjustment(20)

        XCTAssertEqual(adjusted.scoreAdjustment, 70)
        XCTAssertEqual(adjusted.score, base.score + 70)
    }

    private func roundResult(
        cardsInRound: Int,
        bid: Int,
        tricksTaken: Int,
        isBlind: Bool
    ) -> RoundResult {
        return RoundResult(
            cardsInRound: cardsInRound,
            bid: bid,
            tricksTaken: tricksTaken,
            isBlind: isBlind
        )
    }
}
