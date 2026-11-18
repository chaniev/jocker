import Foundation

enum GameSessionSlot: String, Codable, CaseIterable {
    case threePlayers, fourPlayersFreeForAll, fourPlayersPairs

    init(playerCount: Int, gameMode: GameMode) {
        self = playerCount == 3 ? .threePlayers : (gameMode == .pairs ? .fourPlayersPairs : .fourPlayersFreeForAll)
    }
    var playerCount: Int { self == .threePlayers ? 3 : 4 }
    var gameMode: GameMode { self == .fourPlayersPairs ? .pairs : .freeForAll }
}
