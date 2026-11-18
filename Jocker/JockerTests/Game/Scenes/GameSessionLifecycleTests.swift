import XCTest
import SpriteKit
@testable import Jocker

final class GameSessionLifecycleTests: XCTestCase {
    private final class Store: GameSessionStore {
        var snapshots: [GameSessionSnapshot] = []
        var failWrites = false
        var saved: GameSessionSnapshot?
        func load(_ slot: GameSessionSlot, completion: @escaping (Result<GameSessionSnapshot?, Error>) -> Void) { completion(.success(self.saved)) }
        func save(_ snapshot: GameSessionSnapshot, completion: @escaping (Result<Void, Error>) -> Void) {
            self.snapshots.append(snapshot)
            if self.failWrites { completion(.failure(CocoaError(.fileWriteOutOfSpace))) }
            else { self.saved = snapshot; completion(.success(())) }
        }
        func discard(_ slot: GameSessionSlot, completion: @escaping (Result<Void, Error>) -> Void) { self.saved = nil; completion(.success(())) }
        func markTerminal(_ snapshot: GameSessionSnapshot, completion: @escaping (Result<Void, Error>) -> Void) { completion(.failure(CocoaError(.fileWriteOutOfSpace))) }
        func recover(completion: @escaping (Result<Void, Error>) -> Void) { completion(.success(())) }
    }

    func testDeferredLayoutPreservesRestoredHandsAndPendingCardIdentity() throws {
        let store = Store()
        let original = self.scene(store: store, jokerFirst: true)
        original.checkpoint()
        let snapshot = try XCTUnwrap(store.saved)
        var environment = GameEnvironment.live
        environment.sessionStore = store
        let restored = GameScene(size: CGSize(width: 1200, height: 800), inputConfiguration: snapshot.configuration, environment: environment)
        restored.resumeSnapshot = snapshot
        restored.didMove(to: SKView(frame: CGRect(x: 0, y: 0, width: 1200, height: 800)))
        let cardNode = try XCTUnwrap(restored.players[0].hand.cardNodes.first)
        restored.refreshLayout()
        XCTAssertTrue(restored.players[0].hand.cardNodes.first === cardNode)
        XCTAssertEqual(restored.players.map { $0.hand.cards }, original.players.map { $0.hand.cards })
    }

    func testAutosaveFailuresKeepAcceptingMovesAndSuccessfulSnapshotIncludesAllMoves() throws {
        let store = Store()
        let scene = self.scene(store: store)
        scene.checkpoint()
        let saved = try XCTUnwrap(store.saved)
        store.failWrites = true
        for _ in 0..<2 {
            let player = scene.gameState.currentPlayer
            let card = scene.players[player].hand.cards[0]
            _ = scene.players[player].hand.removeCard(card, animated: false)
            scene.playCardOnTable(card, by: player)
        }
        XCTAssertEqual(scene.trickNode.playedCards.count, 2)
        XCTAssertFalse(scene.isInteractionBlocked)
        XCTAssertEqual(store.saved?.revision, saved.revision)
        XCTAssertEqual(scene.persistence?.persistedRevision, saved.revision)
        store.failWrites = false
        scene.checkpoint()
        let latest = try XCTUnwrap(store.saved)
        XCTAssertEqual(latest.trick.count, 2)
        XCTAssertEqual(latest.history.pending.count, 2)
        XCTAssertEqual(scene.persistence?.persistedRevision, latest.revision)
        let restored = GameSessionTestFixture.scene()
        try restored.restoreSession(latest)
        XCTAssertEqual(restored.gameState.currentPlayer, scene.gameState.currentPlayer)
        XCTAssertEqual(restored.trickNode.playedCards, scene.trickNode.playedCards)
    }

    func testBackgroundInvalidatesOldJokerCallbackAndDoubleForegroundRequestsOnlyOnce() throws {
        let store = Store()
        let scene = self.scene(store: store, jokerFirst: true)
        var callbacks: [(JokerPlayDecision?) -> Void] = []
        scene.onJokerDecisionRequested = { _, callback in callbacks.append(callback) }
        let card = try XCTUnwrap(scene.players[0].hand.cardNodes.first)
        scene.requestJokerDecisionAndPlay(cardNode: card, playerIndex: 0)
        XCTAssertEqual(callbacks.count, 1)
        scene.pauseSession()
        callbacks[0](.defaultLead)
        XCTAssertTrue(scene.trickNode.playedCards.isEmpty)
        scene.foregroundSession()
        scene.foregroundSession()
        XCTAssertEqual(callbacks.count, 2)
        callbacks[0](.defaultLead)
        XCTAssertTrue(scene.trickNode.playedCards.isEmpty)
        callbacks[1](.defaultLead)
        callbacks[1](.defaultLead)
        XCTAssertEqual(scene.trickNode.playedCards.count, 1)
        XCTAssertEqual(scene.gameState.currentPlayer, 1)
        XCTAssertEqual(store.saved?.trick.count, 1)
    }

    func testFailedTerminalCommitDoesNotPresentSuccessAndExitDoesNotSaveTerminalAsActive() throws {
        let store = Store()
        let scene = self.scene(store: store)
        scene.checkpoint()
        let previous = try XCTUnwrap(store.saved)
        var terminal = GameSessionTestFixture.terminal(matchID: scene.persistence!.matchID)
        terminal.revision = previous.revision + 1
        try scene.restoreSession(terminal)
        scene.commitTerminalSession()
        XCTAssertFalse(scene.terminalCommitted)
        XCTAssertFalse(scene.hasPresentedGameResultsModal)
        let writesBeforeExit = store.snapshots.count
        var exitResult: Result<Void, Error>?
        scene.exitSession { exitResult = $0 }
        XCTAssertThrowsError(try XCTUnwrap(exitResult).get())
        XCTAssertEqual(store.snapshots.count, writesBeforeExit)
        XCTAssertEqual(store.saved?.revision, previous.revision)
    }

    func testExplicitExitRetriesCurrentLiveStateAndReportsOnlyExitFailure() throws {
        let store = Store()
        let scene = self.scene(store: store)
        store.failWrites = true
        scene.checkpoint()
        XCTAssertNil(scene.persistence?.persistedRevision)
        XCTAssertFalse(scene.isInteractionBlocked)
        store.failWrites = false
        var exitResult: Result<Void, Error>?
        scene.exitSession { exitResult = $0 }
        XCTAssertNoThrow(try XCTUnwrap(exitResult).get())
        XCTAssertNotNil(store.saved)
        XCTAssertTrue(scene.isExitingSession)
    }

    private func scene(store: Store, jokerFirst: Bool = false) -> GameScene {
        let scene = GameSessionTestFixture.scene()
        scene.persistence = GameSessionPersistenceCoordinator(store: store)
        scene.gameState.startGame(initialDealerIndex: 3)
        scene.firstDealerIndex = 3
        scene.coordinator.markDidDeal()
        scene.markDidDealAtLeastOnce()
        if jokerFirst {
            var cards = scene.deck.cards
            cards.remove(at: cards.firstIndex(of: .joker)!)
            cards.insert(.joker, at: 0)
            scene.deck.restore(cards: cards)
        }
        let hands = scene.deck.dealCards(playerCount: 4, cardsPerPlayer: 1).hands
        scene.dealHistoryStore.startDeal(blockIndex: 0, roundIndex: 0)
        scene.dealHistoryStore.setInitialHands(hands, blockIndex: 0, roundIndex: 0)
        for index in 0..<4 {
            scene.players[index].hand.addCards(hands[index], animated: false)
            _ = scene.gameState.placeBid(index == 0 ? 1 : 0, forPlayer: index)
        }
        scene.flow.stage = .playing
        return scene
    }
}
