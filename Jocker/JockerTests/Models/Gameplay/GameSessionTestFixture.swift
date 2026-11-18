import Foundation
import SpriteKit
@testable import Jocker

enum GameSessionTestFixture {
    static let matchID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    static func snapshot(slot: GameSessionSlot = .fourPlayersFreeForAll, revision: Int = 1, matchID: UUID = matchID) -> GameSessionSnapshot {
        let state = GameState(playerCount: slot.playerCount, gameMode: slot.gameMode)
        state.startGame()
        return GameSessionSnapshot(matchID: matchID, revision: revision, slot: slot,
            controls: Array(repeating: "human", count: slot.playerCount), difficulties: Array(repeating: "hard", count: slot.playerCount),
            firstDealer: 0, state: GameStateSnapshot(state), scores: ScoreManagerSnapshot(ScoreManager(gameState: state)),
            roundService: GameRoundService().snapshot, history: DealHistoryStore().snapshot(), flow: GameFlowResumeState(),
            hands: Array(repeating: [], count: slot.playerCount), deck: Deck().cards.map(CardSnapshot.init), trick: [], trump: nil, lastPresentedBlock: 0)
    }

    static func terminal(slot: GameSessionSlot = .fourPlayersFreeForAll, matchID: UUID = matchID) -> GameSessionSnapshot {
        var snapshot = self.snapshot(slot: slot, revision: 100, matchID: matchID)
        let scores = ScoreManager(playerCount: slot.playerCount, gameMode: slot.gameMode)
        for block in GameBlock.allCases {
            for cards in GameConstants.deals(for: block, playerCount: slot.playerCount) {
                scores.recordRoundResults((0..<slot.playerCount).map { RoundResult(cardsInRound: cards, bid: $0 == 0 ? cards : 0,
                    tricksTaken: $0 == 0 ? cards : 0, isBlind: block == .fourth) })
            }
            scores.finalizeBlock(blockNumber: block.rawValue)
        }
        snapshot.scores = ScoreManagerSnapshot(scores)
        snapshot.flow.stage = .terminal
        snapshot.state.phase = "gameEnd"
        return snapshot
    }

    static func scene(slot: GameSessionSlot = .fourPlayersFreeForAll) -> GameScene {
        let scene = GameScene(size: CGSize(width: 1200, height: 800), inputConfiguration: self.snapshot(slot: slot).configuration)
        scene.gameState.startGame()
        scene.trickNode = TrickNode(rendersCards: false)
        scene.players = (0..<slot.playerCount).map { index in
            PlayerNode(playerNumber: index + 1, playerName: "Игрок \(index + 1)", avatar: "", position: .zero,
                seatDirection: CGVector(dx: 0, dy: -1), isLocalPlayer: index == 0, shouldRevealCards: false, totalPlayers: slot.playerCount)
        }
        scene.gameResultsModalPresenter = { _ in true }
        return scene
    }
}
