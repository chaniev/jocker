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
        let scene = makeScene(playerCount: 4)
        scene.gameState.startGame()
        scene.currentTrump = .hearts
        scene.trumpIndicator.setTrumpSuit(.hearts, animated: false)
        _ = scene.trickNode.playCard(
            .regular(suit: .spades, rank: .ace),
            fromPlayer: 1,
            to: .zero,
            animated: false
        )
        scene.seedSessionRuntimeStateForTesting(
            hasPresentedGameResultsModal: true,
            lastPresentedBlockResultsCount: 2,
            hasSavedGameStatistics: true,
            hasDealtAtLeastOnce: true,
            pendingBids: [1, 0, 2, 0],
            pendingBlindSelections: [true, false, false, true]
        )
        scene.setPrimaryInteractionFlow(.trumpSelection)
        scene.setPendingInteractionModal(.humanTrumpChoice)

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
        let scene = makeScene(playerCount: 4)
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

        XCTAssertEqual(viewController.trumpDisplayText(), "Козырь: \(Suit.hearts.rawValue) \(Suit.hearts.name)")
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

        XCTAssertEqual(viewController.trumpDisplayText(), "Козырь: без козыря")
    }

    func testTrumpIndicator_whenNoTrump_displaysJokerCard() {
        let indicator = TrumpIndicator()

        indicator.setTrumpSuit(nil, animated: false)

        XCTAssertEqual(trumpHeaderText(in: indicator), "Без козыря")
        XCTAssertTrue(containsJokerCard(in: indicator))
    }

    func testRoundBidInfoText_forHumanIncludesBidAndTakenTricks() {
        let scene = makeScene(
            playerCount: 4,
            playerControlTypes: [.human, .bot, .bot, .bot]
        )
        scene.gameState.startGame()
        scene.gameState.setBid(2, forPlayerAt: 0)
        scene.gameState.beginPlayingAfterBids()
        scene.gameState.completeTrick(winner: 0)

        XCTAssertEqual(scene.roundBidInfoText(for: 0), "Игрок 1: 2 / 1")
    }

    func testRoundBidInfoText_forBotShowsOnlyBid() {
        let scene = makeScene(
            playerCount: 4,
            playerControlTypes: [.human, .bot, .bot, .bot]
        )
        scene.gameState.startGame()
        scene.gameState.setBid(1, forPlayerAt: 1)

        XCTAssertEqual(scene.roundBidInfoText(for: 1), "Игрок 2: 1")
    }

    func testCanDealCards_whenRoundInProgress_returnsFalse() {
        let scene = makeSceneInPlayingPhase(playerCount: 4)
        scene.markDidDealAtLeastOnce()

        XCTAssertFalse(scene.canDealCards)
    }

    func testCanDealCards_whenRoundEnded_returnsTrue() {
        let scene = makeSceneInPlayingPhase(playerCount: 4)
        scene.markDidDealAtLeastOnce()
        scene.gameState.completeRound()

        XCTAssertTrue(scene.canDealCards)
    }

    func testCanDealCards_beforeFirstDealInBidding_returnsTrue() {
        let scene = makeScene(playerCount: 4)
        scene.gameState.startGame()

        XCTAssertTrue(scene.canDealCards)
    }

    func testBotMatchContext_buildsBlockRoundScoreAndRelativeSeatData() {
        let scene = makeScene(playerCount: 4)
        scene.gameState.startGame(initialDealerIndex: 2)

        scene.scoreManager.recordRoundResults([
            RoundResult(cardsInRound: 1, bid: 1, tricksTaken: 1, isBlind: false),
            RoundResult(cardsInRound: 1, bid: 0, tricksTaken: 1, isBlind: false),
            RoundResult(cardsInRound: 1, bid: 0, tricksTaken: 0, isBlind: false),
            RoundResult(cardsInRound: 1, bid: 0, tricksTaken: 0, isBlind: false)
        ])

        guard let context = scene.botMatchContext(for: 0) else {
            XCTFail("Ожидался матчевый контекст для валидного игрока")
            return
        }

        XCTAssertEqual(context.block, scene.gameState.currentBlock)
        XCTAssertEqual(context.roundIndexInBlock, scene.gameState.currentRoundInBlock)
        XCTAssertEqual(context.totalRoundsInBlock, scene.gameState.totalRoundsInBlock)
        XCTAssertEqual(context.totalScores, scene.scoreManager.totalScoresIncludingCurrentBlock)
        XCTAssertEqual(context.playerIndex, 0)
        XCTAssertEqual(context.dealerIndex, scene.gameState.currentDealer)
        XCTAssertEqual(context.playerCount, scene.playerCount)
        XCTAssertEqual(context.relativeSeatOffsetFromDealer, 2)
        XCTAssertGreaterThanOrEqual(context.blockProgressFraction, 0)
        XCTAssertLessThanOrEqual(context.blockProgressFraction, 1)
        XCTAssertEqual(context.round?.bids.count, scene.playerCount)
        XCTAssertEqual(context.round?.tricksTaken.count, scene.playerCount)
        XCTAssertEqual(context.round?.isBlindBid.count, scene.playerCount)
        XCTAssertEqual(context.premium?.completedRoundsInBlock, 1)
        XCTAssertEqual(context.premium?.remainingRoundsInBlock, scene.gameState.totalRoundsInBlock - 1)
        XCTAssertEqual(context.premium?.isPremiumCandidateSoFar, true)
        XCTAssertEqual(context.premium?.isZeroPremiumRelevantInBlock, true)
        XCTAssertEqual(context.premium?.isZeroPremiumCandidateSoFar, false)
        XCTAssertEqual(context.premium?.opponentPremiumCandidatesSoFarCount, 2)
    }

    func testBotMatchContext_buildsPremiumSnapshot_forZeroPremiumCandidateAtBlockStart() {
        let scene = makeScene(playerCount: 4)
        scene.gameState.startGame(initialDealerIndex: 0)

        guard let context = scene.botMatchContext(for: 0) else {
            XCTFail("Ожидался матчевый контекст")
            return
        }

        XCTAssertEqual(context.block, .first)
        XCTAssertEqual(context.premium?.completedRoundsInBlock, 0)
        XCTAssertEqual(context.premium?.isPremiumCandidateSoFar, true)
        XCTAssertEqual(context.premium?.isZeroPremiumRelevantInBlock, true)
        XCTAssertEqual(context.premium?.isZeroPremiumCandidateSoFar, true)
    }

    func testBotMatchContext_premiumSnapshot_marksBrokenPremiumAndZeroPremiumCandidates() {
        let scene = makeScene(playerCount: 4)
        scene.gameState.startGame(initialDealerIndex: 0)

        scene.scoreManager.recordRoundResults([
            RoundResult(cardsInRound: 1, bid: 1, tricksTaken: 0, isBlind: false), // player 0 breaks premium
            RoundResult(cardsInRound: 1, bid: 0, tricksTaken: 0, isBlind: false),
            RoundResult(cardsInRound: 1, bid: 0, tricksTaken: 0, isBlind: false),
            RoundResult(cardsInRound: 1, bid: 0, tricksTaken: 0, isBlind: false)
        ])

        guard let context = scene.botMatchContext(for: 0) else {
            XCTFail("Ожидался матчевый контекст")
            return
        }

        XCTAssertEqual(context.premium?.completedRoundsInBlock, 1)
        XCTAssertEqual(context.premium?.isPremiumCandidateSoFar, false)
        XCTAssertEqual(context.premium?.isZeroPremiumRelevantInBlock, true)
        XCTAssertEqual(context.premium?.isZeroPremiumCandidateSoFar, false)
    }

    func testBotMatchContext_premiumSnapshot_marksPenaltyTargetRiskFromOpponentPremiumCandidate() {
        let scene = makeScene(playerCount: 4)
        scene.gameState.startGame(initialDealerIndex: 0)

        // Делаем premium-кандидатом только игрока 3.
        // Для игрока 3 левый сосед — игрок 0, значит игрок 0 должен стать penalty-target risk.
        scene.scoreManager.recordRoundResults([
            RoundResult(cardsInRound: 1, bid: 1, tricksTaken: 0, isBlind: false), // p0 not candidate
            RoundResult(cardsInRound: 1, bid: 1, tricksTaken: 0, isBlind: false), // p1 not candidate
            RoundResult(cardsInRound: 1, bid: 1, tricksTaken: 0, isBlind: false), // p2 not candidate
            RoundResult(cardsInRound: 1, bid: 0, tricksTaken: 0, isBlind: false)  // p3 candidate
        ])

        guard let context = scene.botMatchContext(for: 0) else {
            XCTFail("Ожидался матчевый контекст")
            return
        }

        XCTAssertEqual(context.premium?.completedRoundsInBlock, 1)
        XCTAssertEqual(context.premium?.leftNeighborIndex, 1)
        XCTAssertEqual(context.premium?.leftNeighborIsPremiumCandidateSoFar, false)
        XCTAssertEqual(context.premium?.isPenaltyTargetRiskSoFar, true)
        XCTAssertEqual(context.premium?.premiumCandidatesThreateningPenaltyCount, 1)
        XCTAssertEqual(context.premium?.opponentPremiumCandidatesSoFarCount, 1)
    }

    func testBotMatchContext_buildsOpponentModelSnapshotFromObservedRounds() {
        let scene = makeScene(playerCount: 4)
        scene.gameState.startGame(initialDealerIndex: 0)

        scene.scoreManager.recordRoundResults([
            RoundResult(cardsInRound: 2, bid: 1, tricksTaken: 1, isBlind: false), // p0 (self for context)
            RoundResult(cardsInRound: 2, bid: 2, tricksTaken: 1, isBlind: true),  // p1 underbid + blind
            RoundResult(cardsInRound: 2, bid: 0, tricksTaken: 0, isBlind: false), // p2 exact
            RoundResult(cardsInRound: 2, bid: 1, tricksTaken: 2, isBlind: false)  // p3 overbid
        ])
        scene.scoreManager.recordRoundResults([
            RoundResult(cardsInRound: 4, bid: 2, tricksTaken: 2, isBlind: false), // p0
            RoundResult(cardsInRound: 4, bid: 3, tricksTaken: 4, isBlind: false), // p1 overbid
            RoundResult(cardsInRound: 4, bid: 2, tricksTaken: 2, isBlind: false), // p2 exact
            RoundResult(cardsInRound: 4, bid: 1, tricksTaken: 0, isBlind: false)  // p3 underbid
        ])

        guard let context = scene.botMatchContext(for: 0) else {
            XCTFail("Ожидался матчевый контекст")
            return
        }
        guard let opponents = context.opponents else {
            XCTFail("Ожидалась opponent model snapshot в match context")
            return
        }

        XCTAssertEqual(opponents.perspectivePlayerIndex, 0)
        XCTAssertEqual(opponents.leftNeighborIndex, 1)
        XCTAssertEqual(opponents.snapshots.count, 3)

        guard let p1 = opponents.snapshot(for: 1) else {
            XCTFail("Ожидался snapshot для игрока 1")
            return
        }
        XCTAssertEqual(p1.observedRounds, 2)
        XCTAssertEqual(p1.blindBidRate, 0.5, accuracy: 0.000_1)
        XCTAssertEqual(p1.exactBidRate, 0.0, accuracy: 0.000_1)
        XCTAssertEqual(p1.overbidRate, 0.5, accuracy: 0.000_1)
        XCTAssertEqual(p1.underbidRate, 0.5, accuracy: 0.000_1)
        XCTAssertEqual(p1.averageBidAggression, 0.875, accuracy: 0.000_1)

        guard let p2 = opponents.snapshot(for: 2) else {
            XCTFail("Ожидался snapshot для игрока 2")
            return
        }
        XCTAssertEqual(p2.exactBidRate, 1.0, accuracy: 0.000_1)
        XCTAssertEqual(p2.averageBidAggression, 0.25, accuracy: 0.000_1)
    }

    func testBotMatchContext_buildsOpponentModelWithZeroEvidenceAtBlockStart() {
        let scene = makeScene(playerCount: 4)
        scene.gameState.startGame(initialDealerIndex: 0)

        guard let context = scene.botMatchContext(for: 0) else {
            XCTFail("Ожидался матчевый контекст")
            return
        }
        guard let opponents = context.opponents else {
            XCTFail("Ожидалась opponent model snapshot в match context")
            return
        }

        XCTAssertEqual(opponents.snapshots.count, 3)
        XCTAssertTrue(opponents.snapshots.allSatisfy { !$0.hasEvidence })
        XCTAssertTrue(opponents.snapshots.allSatisfy { $0.observedRounds == 0 })
        XCTAssertTrue(opponents.snapshots.allSatisfy { $0.blindBidRate == 0 })
        XCTAssertTrue(opponents.snapshots.allSatisfy { $0.averageBidAggression == 0 })
    }

    func testBotMatchContext_invalidPlayer_returnsNil() {
        let scene = makeScene(playerCount: 4)
        scene.gameState.startGame()

        XCTAssertNil(scene.botMatchContext(for: -1))
        XCTAssertNil(scene.botMatchContext(for: 99))
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
        let scene = makeScene(playerCount: playerCount)
        scene.gameState.startGame()
        for playerIndex in 0..<playerCount {
            scene.gameState.setBid(0, forPlayerAt: playerIndex)
        }
        scene.gameState.beginPlayingAfterBids()
        XCTAssertEqual(scene.gameState.phase, .playing)
        return scene
    }

    private func makeScene(
        playerCount: Int,
        playerControlTypes: [PlayerControlType] = []
    ) -> GameScene {
        return GameScene(
            size: CGSize(width: 1366, height: 768),
            inputConfiguration: GameSceneInputConfiguration(
                playerCount: playerCount,
                playerControlTypes: playerControlTypes
            )
        )
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
