//
//  GameFlowIntegrationTests.swift
//  JockerTests
//
//  Created by Codex on 15.02.2026.
//

import XCTest
@testable import Jocker

final class GameFlowIntegrationTests: XCTestCase {

    func testEndOfBlock_finalizesOnceAndMovesToNextBlockOnNextDeal() {
        let playerCount = 4
        let (gameState, scoreManager, roundService) = makeContext(playerCount: playerCount)

        let roundsInFirstBlock = GameConstants.deals(for: .first, playerCount: playerCount).count

        for roundIndex in 0..<roundsInFirstBlock {
            let canDeal = roundService.prepareForDealing(
                gameState: gameState,
                scoreManager: scoreManager,
                playerCount: playerCount
            )
            XCTAssertTrue(canDeal)

            if roundIndex == 0 {
                roundService.markDidDeal()
            }

            playDeterministicRound(
                gameState: gameState,
                scoreManager: scoreManager,
                roundService: roundService,
                playerCount: playerCount
            )
        }

        XCTAssertEqual(scoreManager.completedBlocks.count, 1)
        XCTAssertEqual(gameState.currentBlock, .first)
        XCTAssertEqual(gameState.phase, .roundEnd)

        let canDealNextBlock = roundService.prepareForDealing(
            gameState: gameState,
            scoreManager: scoreManager,
            playerCount: playerCount
        )

        XCTAssertTrue(canDealNextBlock)
        XCTAssertEqual(scoreManager.completedBlocks.count, 1, "Блок не должен финализироваться повторно")
        XCTAssertEqual(gameState.currentBlock, .second)
        XCTAssertEqual(gameState.currentRoundInBlock, 0)
        XCTAssertEqual(gameState.phase, .bidding)
    }

    func testEndOfGame_finalRoundStopsFurtherDealingAndAllBlocksAreFinalized() {
        let playerCount = 4
        let (gameState, scoreManager) = runGameToEnd(playerCount: playerCount)

        XCTAssertEqual(gameState.phase, .gameEnd)
        XCTAssertEqual(scoreManager.completedBlocks.count, GameConstants.totalBlocks)

        let expectedRoundCounts = GameConstants.allBlockDeals(playerCount: playerCount).map { $0.count }
        let actualRoundCounts = scoreManager.completedBlocks.map { block in
            block.roundResults.first?.count ?? 0
        }
        XCTAssertEqual(actualRoundCounts, expectedRoundCounts)
    }

    func testThreePlayers_modeFinishesGameAndKeepsExpectedBlockShape() {
        let playerCount = 3
        let (gameState, scoreManager) = runGameToEnd(playerCount: playerCount)

        XCTAssertEqual(gameState.phase, .gameEnd)
        XCTAssertEqual(scoreManager.completedBlocks.count, GameConstants.totalBlocks)
        XCTAssertEqual(scoreManager.totalScores.count, playerCount)

        let expectedRoundCounts = GameConstants.allBlockDeals(playerCount: playerCount).map { $0.count }
        let actualRoundCounts = scoreManager.completedBlocks.map { block in
            block.roundResults.first?.count ?? 0
        }
        XCTAssertEqual(actualRoundCounts, expectedRoundCounts)

        let maxCards = GameConstants.maxCardsPerPlayer(for: playerCount)
        let secondBlock = scoreManager.completedBlocks[1]
        let fourthBlock = scoreManager.completedBlocks[3]

        for roundResult in secondBlock.roundResults[0] {
            XCTAssertEqual(roundResult.cardsInRound, maxCards)
        }
        for roundResult in fourthBlock.roundResults[0] {
            XCTAssertEqual(roundResult.cardsInRound, maxCards)
        }

        for block in scoreManager.completedBlocks {
            XCTAssertEqual(block.roundResults.count, playerCount)
            XCTAssertEqual(block.baseScores.count, playerCount)
            XCTAssertEqual(block.finalScores.count, playerCount)
        }
    }

    // MARK: - Helpers

    private func makeContext(playerCount: Int) -> (GameState, ScoreManager, GameRoundService) {
        let gameState = GameState(playerCount: playerCount)
        gameState.startGame()

        let scoreManager = ScoreManager(gameState: gameState)
        let roundService = GameRoundService()

        return (gameState, scoreManager, roundService)
    }

    private func runGameToEnd(playerCount: Int) -> (GameState, ScoreManager) {
        let (gameState, scoreManager, roundService) = makeContext(playerCount: playerCount)

        var didMarkDeal = false
        var roundsPlayed = 0

        while roundService.prepareForDealing(
            gameState: gameState,
            scoreManager: scoreManager,
            playerCount: playerCount
        ) {
            if !didMarkDeal {
                roundService.markDidDeal()
                didMarkDeal = true
            }

            playDeterministicRound(
                gameState: gameState,
                scoreManager: scoreManager,
                roundService: roundService,
                playerCount: playerCount
            )

            roundsPlayed += 1
            XCTAssertLessThan(roundsPlayed, 200)
        }

        return (gameState, scoreManager)
    }

    private func playDeterministicRound(
        gameState: GameState,
        scoreManager: ScoreManager,
        roundService: GameRoundService,
        playerCount: Int
    ) {
        let cardsInRound = gameState.currentCardsPerPlayer
        XCTAssertGreaterThan(cardsInRound, 0)

        for playerIndex in 0..<playerCount {
            let bid = (playerIndex == 0) ? cardsInRound : 0
            gameState.setBid(bid, forPlayerAt: playerIndex)
        }

        gameState.beginPlayingAfterBids()
        XCTAssertEqual(gameState.phase, .playing)

        for _ in 0..<cardsInRound {
            gameState.completeTrick(winner: 0)
        }

        roundService.completeRoundIfNeeded(
            gameState: gameState,
            scoreManager: scoreManager,
            playerCount: playerCount
        )

        XCTAssertEqual(gameState.phase, .roundEnd)
    }
}
