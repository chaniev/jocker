import Foundation

struct DealTrickMoveSnapshot: Codable {
    let playerIndex: Int
    let card: CardSnapshot
    let jokerPlayStyle: String
    let jokerLeadDeclaration: JokerDeclarationSnapshot?

    init(_ value: DealTrickMove) {
        self.playerIndex = value.playerIndex
        self.card = CardSnapshot(value.card)
        self.jokerPlayStyle = (value.jokerPlayStyle == .faceUp ? "faceUp" : "faceDown")
        self.jokerLeadDeclaration = value.jokerLeadDeclaration.map { JokerDeclarationSnapshot($0) }
    }

    func restore() throws -> DealTrickMove {
        return DealTrickMove(
            playerIndex: self.playerIndex,
            card: try self.card.restore(),
            jokerPlayStyle: try GameSessionSnapshot.decodeStyle(self.jokerPlayStyle),
            jokerLeadDeclaration: try self.jokerLeadDeclaration.map { try $0.restore() }
        )
    }
}
