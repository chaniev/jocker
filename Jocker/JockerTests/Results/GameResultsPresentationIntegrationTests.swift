//
//  GameResultsPresentationIntegrationTests.swift
//  JockerTests
//
//  Created by Codex on 20.02.2026.
//

import XCTest
import CoreGraphics
@testable import Jocker

final class GameResultsPresentationIntegrationTests: XCTestCase {

    func testRepeatedFullGameCycle_requestsGameResultsModalAgainAfterReset() {
        let scene = GameScene(size: CGSize(width: 1366, height: 768))
        scene.playerCount = 4

        var presentedGameResultsCount = 0
        scene.gameResultsModalPresenter = { playerSummaries in
            presentedGameResultsCount += 1
            XCTAssertEqual(playerSummaries.count, 4)
            return true
        }

        runDeterministicGameToEnd(on: scene, initialDealerIndex: 0)
        XCTAssertTrue(scene.tryPresentGameResultsIfNeeded())
        XCTAssertEqual(presentedGameResultsCount, 1)
        XCTAssertTrue(scene.hasPresentedGameResultsModal)

        scene.resetForNewGameSession()

        runDeterministicGameToEnd(on: scene, initialDealerIndex: 1)
        XCTAssertTrue(scene.tryPresentGameResultsIfNeeded())
        XCTAssertEqual(presentedGameResultsCount, 2)
        XCTAssertTrue(scene.hasPresentedGameResultsModal)
    }

    private func runDeterministicGameToEnd(on scene: GameScene, initialDealerIndex: Int) {
        let roundService = GameRoundService()
        scene.gameState.startGame(initialDealerIndex: initialDealerIndex)

        var didMarkDeal = false
        var roundsPlayed = 0

        while roundService.prepareForDealing(
            gameState: scene.gameState,
            scoreManager: scene.scoreManager,
            playerCount: scene.playerCount
        ) {
            if !didMarkDeal {
                roundService.markDidDeal()
                didMarkDeal = true
            }

            playDeterministicRound(on: scene, roundService: roundService)

            roundsPlayed += 1
            XCTAssertLessThan(roundsPlayed, 200)
        }

        XCTAssertEqual(scene.gameState.phase, .gameEnd)
        XCTAssertEqual(scene.scoreManager.completedBlocks.count, GameConstants.totalBlocks)
    }

    private func playDeterministicRound(on scene: GameScene, roundService: GameRoundService) {
        let cardsInRound = scene.gameState.currentCardsPerPlayer
        XCTAssertGreaterThan(cardsInRound, 0)

        for playerIndex in 0..<scene.playerCount {
            let bid = (playerIndex == 0) ? cardsInRound : 0
            scene.gameState.setBid(bid, forPlayerAt: playerIndex)
        }

        scene.gameState.beginPlayingAfterBids()
        XCTAssertEqual(scene.gameState.phase, .playing)

        for _ in 0..<cardsInRound {
            scene.gameState.completeTrick(winner: 0)
        }

        roundService.completeRoundIfNeeded(
            gameState: scene.gameState,
            scoreManager: scene.scoreManager,
            playerCount: scene.playerCount
        )

        XCTAssertEqual(scene.gameState.phase, .roundEnd)
    }
}
