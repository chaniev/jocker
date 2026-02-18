//
//  GameScenePlayingFlowTests.swift
//  JockerTests
//
//  Created by Codex on 15.02.2026.
//

import XCTest
import SpriteKit
@testable import Jocker

final class GameScenePlayingFlowTests: XCTestCase {
    func testCanDealCards_whenRoundInProgress_returnsFalse() {
        let scene = makeSceneInPlayingPhase(playerCount: 4)
        scene.hasDealtAtLeastOnce = true

        XCTAssertFalse(scene.canDealCards)
    }

    func testCanDealCards_whenRoundEnded_returnsTrue() {
        let scene = makeSceneInPlayingPhase(playerCount: 4)
        scene.hasDealtAtLeastOnce = true
        scene.gameState.completeRound()

        XCTAssertTrue(scene.canDealCards)
    }

    func testCanDealCards_beforeFirstDealInBidding_returnsTrue() {
        let scene = GameScene(size: CGSize(width: 1366, height: 768))
        scene.playerCount = 4
        scene.gameState.startGame()

        XCTAssertTrue(scene.canDealCards)
    }

    func testResetTrumpStateIfRoundFinished_whenRoundEnded_clearsCurrentTrumpAndIndicator() {
        let scene = makeSceneInPlayingPhase(playerCount: 4)
        scene.currentTrump = .hearts
        scene.trumpIndicator.setTrumpSuit(.hearts, animated: false)
        scene.gameState.completeRound()

        scene.resetTrumpStateIfRoundFinished(animated: false)

        XCTAssertNil(scene.currentTrump)
        XCTAssertEqual(trumpHeaderText(in: scene.trumpIndicator), "Козырь")
    }

    func testResetTrumpStateIfRoundFinished_whenRoundNotFinished_preservesCurrentTrumpAndIndicator() {
        let scene = makeSceneInPlayingPhase(playerCount: 4)
        scene.currentTrump = .spades
        scene.trumpIndicator.setTrumpSuit(.spades, animated: false)

        scene.resetTrumpStateIfRoundFinished(animated: false)

        XCTAssertEqual(scene.currentTrump, .spades)
        XCTAssertEqual(trumpHeaderText(in: scene.trumpIndicator), "Козырь: Пики")
    }

    private func makeSceneInPlayingPhase(playerCount: Int) -> GameScene {
        let scene = GameScene(size: CGSize(width: 1366, height: 768))
        scene.playerCount = playerCount
        scene.gameState.startGame()
        for playerIndex in 0..<playerCount {
            scene.gameState.setBid(0, forPlayerAt: playerIndex)
        }
        scene.gameState.beginPlayingAfterBids()
        XCTAssertEqual(scene.gameState.phase, .playing)
        return scene
    }

    private func trumpHeaderText(in indicator: TrumpIndicator) -> String? {
        return indicator
            .children
            .compactMap { $0 as? SKLabelNode }
            .compactMap(\.text)
            .first { $0.hasPrefix("Козырь") }
    }
}
