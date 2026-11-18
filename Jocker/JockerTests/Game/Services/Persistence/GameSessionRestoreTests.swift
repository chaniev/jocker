import XCTest
import SpriteKit
@testable import Jocker

final class GameSessionRestoreTests: XCTestCase {
    func testContinuousAndRecreatedAfterEveryMoveProduceIdenticalFullMatches() throws {
        for slot in GameSessionSlot.allCases {
            let continuous = GameSessionTestFixture.scene(slot: slot)
            var recreated = GameSessionTestFixture.scene(slot: slot)
            var moves = 0
            for block in GameBlock.allCases {
                for _ in GameConstants.deals(for: block, playerCount: slot.playerCount) {
                    self.prepareRound(continuous)
                    self.prepareRound(recreated)
                    try self.assertEquivalent(continuous, recreated)
                    while continuous.gameState.phase == .playing {
                        let player = continuous.gameState.currentPlayer
                        let hand = continuous.players[player].hand.cards
                        let card = try XCTUnwrap(hand.first { continuous.trickNode.canPlayCard($0, fromHand: hand, trump: continuous.currentTrump) })
                        for scene in [continuous, recreated] {
                            XCTAssertEqual(scene.gameState.currentPlayer, player)
                            XCTAssertNotNil(scene.players[player].hand.removeCard(card, animated: false))
                            scene.playCardOnTable(card, by: player, jokerPlayStyle: moves.isMultiple(of: 2) ? .faceUp : .faceDown,
                                jokerLeadDeclaration: card.isJoker && scene.trickNode.playedCards.isEmpty ? .takes(suit: .hearts) : nil)
                        }
                        moves += 1
                        let saved = recreated.makeSessionSnapshot(revision: moves)
                        let encoded = try GameSessionCodec().encode(saved)
                        let restored = try GameSessionCodec().decode(encoded)
                        recreated = GameSessionTestFixture.scene(slot: slot)
                        try recreated.restoreSession(restored)
                        try self.assertEquivalent(continuous, recreated)
                    }
                }
            }
            XCTAssertEqual(continuous.scoreManager.completedBlocks.count, 4)
            XCTAssertEqual(recreated.scoreManager.totalScores, continuous.scoreManager.totalScores)
            XCTAssertEqual(recreated.dealHistoryStore.allHistories(), continuous.dealHistoryStore.allHistories())
            XCTAssertGreaterThan(moves, 500)
            let captureStart = DispatchTime.now().uptimeNanoseconds
            let snapshot = recreated.makeSessionSnapshot(revision: moves)
            let captureMilliseconds = Double(DispatchTime.now().uptimeNanoseconds - captureStart) / 1_000_000
            let done = self.expectation(description: "off-main full snapshot encoding and atomic write")
            DispatchQueue(label: "JCR001.performance").async {
                XCTAssertFalse(Thread.isMainThread)
                let start = DispatchTime.now().uptimeNanoseconds
                do {
                    let data = try GameSessionCodec().encode(snapshot)
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent("JCR001-measure-" + slot.rawValue)
                    try data.write(to: url, options: .atomic)
                    try FileManager.default.removeItem(at: url)
                    let milliseconds = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000
                    print("JCR001 full snapshot \(slot.rawValue): capture=\(captureMilliseconds)ms encode+validate+write=\(milliseconds)ms bytes=\(data.count)")
                } catch { XCTFail("Full snapshot persistence failed: \(error)") }
                done.fulfill()
            }
            self.wait(for: [done], timeout: 10)
        }
    }

    func testPartialTrumpHandsAndPendingSamplesRestorePassively() throws {
        let scene = GameSessionTestFixture.scene()
        self.prepareRound(scene)
        let player = scene.gameState.currentPlayer
        let card = scene.players[player].hand.cards[0]
        _ = scene.players[player].hand.removeCard(card, animated: false)
        scene.playCardOnTable(card, by: player)
        let before = scene.makeSessionSnapshot(revision: 1)
        XCTAssertEqual(before.history.pending.count, 1)
        let restored = GameSessionTestFixture.scene()
        try restored.restoreSession(GameSessionCodec().decode(GameSessionCodec().encode(before)))
        XCTAssertEqual(restored.makeSessionSnapshot(revision: 1).history.pending.count, 1)
        XCTAssertEqual(restored.trickNode.playedCards, scene.trickNode.playedCards)
        XCTAssertEqual(restored.scoreManager.completedBlocks.count, 0)
        XCTAssertEqual(restored.gameState.currentPlayer, scene.gameState.currentPlayer)
    }

    private func prepareRound(_ scene: GameScene) {
        XCTAssertTrue(scene.coordinator.prepareForDealing(gameState: scene.gameState, scoreManager: scene.scoreManager, playerCount: scene.playerCount))
        scene.coordinator.markDidDeal()
        scene.markDidDealAtLeastOnce()
        scene.deck.reset()
        let dealt = scene.deck.dealCards(playerCount: scene.playerCount, cardsPerPlayer: scene.gameState.currentCardsPerPlayer,
            startingPlayerIndex: (scene.gameState.currentDealer + 1) % scene.playerCount)
        for index in scene.players.indices {
            scene.players[index].hand.removeAllCards(animated: false)
            scene.players[index].hand.addCards(dealt.hands[index], animated: false)
            scene.players[index].resetForNewRound()
        }
        scene.currentTrump = dealt.trump?.suit
        scene.dealHistoryStore.startDeal(blockIndex: scene.gameState.currentBlock.rawValue - 1, roundIndex: scene.gameState.currentRoundInBlock)
        scene.dealHistoryStore.setInitialHands(dealt.hands, blockIndex: scene.gameState.currentBlock.rawValue - 1, roundIndex: scene.gameState.currentRoundInBlock)
        scene.dealHistoryStore.setTrump(scene.currentTrump, blockIndex: scene.gameState.currentBlock.rawValue - 1, roundIndex: scene.gameState.currentRoundInBlock)
        let order = scene.biddingOrder()
        var bids = Array(repeating: 0, count: scene.playerCount)
        for player in order {
            let bid = scene.gameState.allowedBids(forPlayer: player, bids: bids).first!
            bids[player] = bid
            _ = scene.gameState.placeBid(bid, forPlayer: player, isBlind: scene.gameState.currentBlock == .fourth && player != scene.gameState.currentDealer)
            scene.players[player].setBid(bid, isBlind: scene.gameState.players[player].isBlindBid, animated: false)
        }
        scene.flow = GameFlowResumeState()
        scene.flow.stage = .playing
    }

    private func assertEquivalent(_ first: GameScene, _ second: GameScene, file: StaticString = #filePath, line: UInt = #line) throws {
        XCTAssertEqual(first.players.map { $0.hand.cards }, second.players.map { $0.hand.cards }, file: file, line: line)
        XCTAssertEqual(first.deck.cards, second.deck.cards, file: file, line: line)
        XCTAssertEqual(first.trickNode.playedCards, second.trickNode.playedCards, file: file, line: line)
        XCTAssertEqual(first.gameState.currentPlayer, second.gameState.currentPlayer, file: file, line: line)
        XCTAssertEqual(first.gameState.players.map(\.tricksTaken), second.gameState.players.map(\.tricksTaken), file: file, line: line)
        XCTAssertEqual(first.scoreManager.totalScoresIncludingCurrentBlock, second.scoreManager.totalScoresIncludingCurrentBlock, file: file, line: line)
        XCTAssertEqual(first.dealHistoryStore.allHistories(), second.dealHistoryStore.allHistories(), file: file, line: line)
    }
}
