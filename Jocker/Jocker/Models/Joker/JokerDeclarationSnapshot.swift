import Foundation

struct JokerDeclarationSnapshot: Codable {
    let kind: String
    let suit: String?

    init(_ declaration: JokerLeadDeclaration) {
        switch declaration {
        case .wish: self.kind = "wish"; self.suit = nil
        case .above(let suit): self.kind = "above"; self.suit = CardSnapshot.identifier(suit)
        case .takes(let suit): self.kind = "takes"; self.suit = CardSnapshot.identifier(suit)
        }
    }

    func restore() throws -> JokerLeadDeclaration {
        if self.kind == "wish", self.suit == nil { return .wish }
        guard let suit = self.suit.flatMap(CardSnapshot.suit) else { throw GameSessionError.invalidSnapshot }
        switch self.kind {
        case "above": return .above(suit: suit)
        case "takes": return .takes(suit: suit)
        default: throw GameSessionError.invalidSnapshot
        }
    }
}
