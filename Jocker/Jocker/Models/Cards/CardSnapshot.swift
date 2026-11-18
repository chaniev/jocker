import Foundation

/// Stable identifiers independent of localized display symbols.
struct CardSnapshot: Codable, Equatable {
    let suit: String?
    let rank: Int?

    init(_ card: Card) {
        self.suit = card.suit.map(Self.identifier)
        self.rank = card.rank?.rawValue
    }

    func restore() throws -> Card {
        if self.suit == nil && self.rank == nil { return .joker }
        guard let suit = self.suit.flatMap(Self.suit), let rank = self.rank.flatMap(Rank.init(rawValue:)),
              !(rank == .six && (suit == .spades || suit == .clubs)) else {
            throw GameSessionError.invalidSnapshot
        }
        return .regular(suit: suit, rank: rank)
    }

    static func identifier(_ suit: Suit) -> String {
        switch suit {
        case .diamonds: return "diamonds"
        case .hearts: return "hearts"
        case .spades: return "spades"
        case .clubs: return "clubs"
        }
    }

    static func suit(_ identifier: String) -> Suit? {
        switch identifier {
        case "diamonds": return .diamonds
        case "hearts": return .hearts
        case "spades": return .spades
        case "clubs": return .clubs
        default: return nil
        }
    }
}
