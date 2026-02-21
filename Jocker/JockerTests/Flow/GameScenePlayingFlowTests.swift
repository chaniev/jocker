//
//  GameScenePlayingFlowTests.swift
//  JockerTests
//
//  Created by Codex on 15.02.2026.
//

import XCTest
import SpriteKit
import UIKit
@testable import Jocker

final class GameScenePlayingFlowTests: XCTestCase {
    func testResetForNewGameSession_resetsResultPresentationAndScores() {
        let scene = GameScene(size: CGSize(width: 1366, height: 768))
        scene.playerCount = 4
        scene.gameState.startGame()
        scene.currentTrump = .hearts
        scene.trumpIndicator.setTrumpSuit(.hearts, animated: false)
        _ = scene.trickNode.playCard(
            .regular(suit: .spades, rank: .ace),
            fromPlayer: 1,
            to: .zero,
            animated: false
        )
        scene.hasPresentedGameResultsModal = true
        scene.lastPresentedBlockResultsCount = 2
        scene.hasSavedGameStatistics = true
        scene.hasDealtAtLeastOnce = true
        scene.isSelectingFirstDealer = true
        scene.isAwaitingJokerDecision = true
        scene.isAwaitingHumanBidChoice = true
        scene.isAwaitingHumanBlindChoice = true
        scene.isAwaitingHumanTrumpChoice = true
        scene.isRunningBiddingFlow = true
        scene.isRunningPreDealBlindFlow = true
        scene.isRunningTrumpSelectionFlow = true
        scene.pendingBids = [1, 0, 2, 0]
        scene.pendingBlindSelections = [true, false, false, true]

        let playerNode = PlayerNode(
            playerNumber: 1,
            playerName: "Игрок 1",
            avatar: "👨‍💼",
            position: CGPoint(x: 200, y: 200),
            seatDirection: CGVector(dx: 0, dy: -1),
            isLocalPlayer: true,
            shouldRevealCards: false,
            totalPlayers: 4
        )
        playerNode.hand.addCard(.regular(suit: .clubs, rank: .king), animated: false)
        playerNode.setBid(2, isBlind: true, animated: false)
        playerNode.incrementTricks()
        scene.players = [playerNode]

        scene.scoreManager.recordRoundResults([
            RoundResult(cardsInRound: 1, bid: 1, tricksTaken: 1, isBlind: false),
            RoundResult(cardsInRound: 1, bid: 0, tricksTaken: 0, isBlind: false),
            RoundResult(cardsInRound: 1, bid: 0, tricksTaken: 0, isBlind: false),
            RoundResult(cardsInRound: 1, bid: 0, tricksTaken: 0, isBlind: false)
        ])
        _ = scene.scoreManager.finalizeBlock()
        XCTAssertEqual(scene.scoreManager.completedBlocks.count, 1)

        scene.resetForNewGameSession()

        XCTAssertFalse(scene.hasPresentedGameResultsModal)
        XCTAssertEqual(scene.lastPresentedBlockResultsCount, 0)
        XCTAssertFalse(scene.hasSavedGameStatistics)
        XCTAssertFalse(scene.hasDealtAtLeastOnce)
        XCTAssertFalse(scene.isSelectingFirstDealer)
        XCTAssertFalse(scene.isAwaitingJokerDecision)
        XCTAssertFalse(scene.isAwaitingHumanBidChoice)
        XCTAssertFalse(scene.isAwaitingHumanBlindChoice)
        XCTAssertFalse(scene.isAwaitingHumanTrumpChoice)
        XCTAssertFalse(scene.isRunningBiddingFlow)
        XCTAssertFalse(scene.isRunningPreDealBlindFlow)
        XCTAssertFalse(scene.isRunningTrumpSelectionFlow)
        XCTAssertTrue(scene.pendingBids.isEmpty)
        XCTAssertTrue(scene.pendingBlindSelections.isEmpty)
        XCTAssertNil(scene.currentTrump)
        XCTAssertEqual(scene.trickNode.playedCards.count, 0)
        XCTAssertEqual(trumpHeaderText(in: scene.trumpIndicator), "Козырь")
        XCTAssertEqual(scene.scoreManager.completedBlocks.count, 0)
        XCTAssertEqual(scene.scoreManager.totalScores, [0, 0, 0, 0])
        XCTAssertEqual(playerNode.hand.cards.count, 0)
        XCTAssertEqual(playerNode.bid, 0)
        XCTAssertEqual(playerNode.tricksTaken, 0)
        XCTAssertFalse(playerNode.isBlindBid)
    }

    func testResetForNewGameSession_resetsCoordinatorDealingState() {
        let scene = GameScene(size: CGSize(width: 1366, height: 768))
        scene.playerCount = 4
        scene.gameState.startGame()

        scene.coordinator.markDidDeal()
        scene.resetForNewGameSession()
        scene.gameState.startGame()

        let initialRound = scene.gameState.currentRoundInBlock
        let canDeal = scene.coordinator.prepareForDealing(
            gameState: scene.gameState,
            scoreManager: scene.scoreManager,
            playerCount: scene.playerCount
        )

        XCTAssertTrue(canDeal)
        XCTAssertEqual(scene.gameState.currentRoundInBlock, initialRound)
    }

    func testScoreTableView_whenLatestBlockHasPremium_showsTrophyInPremiumMarkerArea() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        manager.recordRoundResults([
            RoundResult(cardsInRound: 1, bid: 1, tricksTaken: 1, isBlind: false),
            RoundResult(cardsInRound: 1, bid: 1, tricksTaken: 0, isBlind: false),
            RoundResult(cardsInRound: 1, bid: 0, tricksTaken: 1, isBlind: false),
            RoundResult(cardsInRound: 1, bid: 0, tricksTaken: 1, isBlind: false)
        ])
        _ = manager.finalizeBlock(blockNumber: 1)

        let tableView = ScoreTableView(
            playerCount: 4,
            displayStartPlayerIndex: 0,
            playerNames: ["Анна", "Борис", "Вика", "Глеб"]
        )
        tableView.frame = CGRect(x: 0, y: 0, width: 1366, height: 768)
        tableView.update(with: manager)
        tableView.layoutIfNeeded()

        let labelTexts = allLabelTexts(in: tableView)
        XCTAssertTrue(labelTexts.contains("Анна"))
        XCTAssertFalse(labelTexts.contains("Анна 🏆"))
        XCTAssertTrue(labelTexts.contains("🏆"))
    }

    func testBidSelectionTrumpDisplayText_whenTrumpSet_showsSuitOnly() {
        let viewController = BidSelectionViewController(
            playerName: "Игрок 1",
            handCards: [],
            allowedBids: [0, 1],
            maxBid: 1,
            playerNames: ["Игрок 1"],
            displayedBidsByPlayer: [nil],
            biddingOrder: [0],
            currentPlayerIndex: 0,
            forbiddenBid: nil,
            trumpSuit: .hearts
        ) { _ in }

        XCTAssertEqual(viewController.trumpDisplayText(), "Козырь: \(Suit.hearts.name)")
    }

    func testBidSelectionTrumpDisplayText_whenNoTrump_showsNoTrumpLabel() {
        let viewController = BidSelectionViewController(
            playerName: "Игрок 1",
            handCards: [],
            allowedBids: [0, 1],
            maxBid: 1,
            playerNames: ["Игрок 1"],
            displayedBidsByPlayer: [nil],
            biddingOrder: [0],
            currentPlayerIndex: 0,
            forbiddenBid: nil,
            trumpSuit: nil
        ) { _ in }

        XCTAssertEqual(viewController.trumpDisplayText(), "Без козыря")
    }

    func testTrumpIndicator_whenNoTrump_displaysJokerCard() {
        let indicator = TrumpIndicator()

        indicator.setTrumpSuit(nil, animated: false)

        XCTAssertEqual(trumpHeaderText(in: indicator), "Без козыря")
        XCTAssertTrue(containsJokerCard(in: indicator))
    }

    func testRoundBidInfoText_forHumanIncludesBidAndTakenTricks() {
        let scene = GameScene(size: CGSize(width: 1366, height: 768))
        scene.playerCount = 4
        scene.playerControlTypes = [.human, .bot, .bot, .bot]
        scene.gameState.startGame()
        scene.gameState.setBid(2, forPlayerAt: 0)
        scene.gameState.beginPlayingAfterBids()
        scene.gameState.completeTrick(winner: 0)

        XCTAssertEqual(scene.roundBidInfoText(for: 0), "Игрок 1: 2 / 1")
    }

    func testRoundBidInfoText_forBotShowsOnlyBid() {
        let scene = GameScene(size: CGSize(width: 1366, height: 768))
        scene.playerCount = 4
        scene.playerControlTypes = [.human, .bot, .bot, .bot]
        scene.gameState.startGame()
        scene.gameState.setBid(1, forPlayerAt: 1)

        XCTAssertEqual(scene.roundBidInfoText(for: 1), "Игрок 2: 1")
    }

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
            ?? indicator
                .children
                .compactMap { $0 as? SKLabelNode }
                .compactMap(\.text)
                .first { $0 == "Без козыря" }
    }

    private func containsJokerCard(in indicator: TrumpIndicator) -> Bool {
        return indicator
            .children
            .compactMap { $0 as? CardNode }
            .contains { $0.card.isJoker }
    }

    private func allLabelTexts(in view: UIView) -> [String] {
        var texts: [String] = []
        if let label = view as? UILabel, let text = label.text {
            texts.append(text)
        }
        for subview in view.subviews {
            texts.append(contentsOf: allLabelTexts(in: subview))
        }
        return texts
    }
}
