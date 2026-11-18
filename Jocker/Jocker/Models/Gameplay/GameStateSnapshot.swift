import Foundation

struct GameStateSnapshot: Codable {
    struct Player: Codable {
        var name: String
        var bid: Int
        var tricks: Int
        var blind: Bool
        var locked: Bool
    }
    var players: [Player]
    var block: Int
    var round: Int
    var dealer: Int
    var currentPlayer: Int
    var phase: String

    init(_ state: GameState) {
        self.players = state.players.map { Player(name: $0.name, bid: $0.currentBid, tricks: $0.tricksTaken, blind: $0.isBlindBid, locked: $0.isBidLockedBeforeDeal) }
        self.block = state.currentBlock.rawValue
        self.round = state.currentRoundInBlock
        self.dealer = state.currentDealer
        self.currentPlayer = state.currentPlayer
        switch state.phase {
        case .notStarted: self.phase = "notStarted"
        case .bidding: self.phase = "bidding"
        case .playing: self.phase = "playing"
        case .roundEnd: self.phase = "roundEnd"
        case .gameEnd: self.phase = "gameEnd"
        }
    }
    func restore(into state: GameState) throws {
        guard let block = GameBlock(rawValue: self.block),
              GameConstants.cardsPerPlayer(for: block, roundIndex: self.round, playerCount: state.playerCount) != nil,
              self.players.count == state.playerCount,
              (0..<state.playerCount).contains(self.dealer),
              (0..<state.playerCount).contains(self.currentPlayer) else { throw GameSessionError.invalidSnapshot }
        let phases: [String: GamePhase] = ["notStarted": .notStarted, "bidding": .bidding, "playing": .playing, "roundEnd": .roundEnd, "gameEnd": .gameEnd]
        guard let phase = phases[self.phase] else { throw GameSessionError.invalidSnapshot }
        let players = self.players.enumerated().map { index, saved in
            var player = PlayerInfo(playerNumber: index + 1, name: saved.name)
            player.currentBid = saved.bid
            player.tricksTaken = saved.tricks
            player.isBlindBid = saved.blind
            player.isBidLockedBeforeDeal = saved.locked
            return player
        }
        state.restore(players: players, block: block, round: self.round, dealer: self.dealer, currentPlayer: self.currentPlayer, phase: phase)
    }
}
