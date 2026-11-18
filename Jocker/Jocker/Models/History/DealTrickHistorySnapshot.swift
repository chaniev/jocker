import Foundation

struct DealTrickHistorySnapshot: Codable {
    let moves: [DealTrickMoveSnapshot]
    let winnerPlayerIndex: Int

    init(_ value: DealTrickHistory) {
        self.moves = value.moves.map { DealTrickMoveSnapshot($0) }
        self.winnerPlayerIndex = value.winnerPlayerIndex
    }

    func restore() throws -> DealTrickHistory {
        return DealTrickHistory(
            moves: try self.moves.map { try $0.restore() },
            winnerPlayerIndex: self.winnerPlayerIndex
        )
    }
}
