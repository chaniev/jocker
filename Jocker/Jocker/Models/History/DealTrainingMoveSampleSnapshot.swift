import Foundation

struct DealTrainingMoveSampleSnapshot: Codable {
    let blockIndex: Int
    let roundIndex: Int
    let trickIndex: Int
    let moveIndexInTrick: Int
    let playerIndex: Int
    let playerCount: Int
    let cardsInRound: Int
    let trump: String?
    let playerBid: Int?
    let playerTricksTakenBeforeMove: Int?
    let handBeforeMove: [CardSnapshot]
    let legalCards: [CardSnapshot]
    let playedCardsInTrickBeforeMove: [DealTrickMoveSnapshot]
    let selectedCard: CardSnapshot
    let selectedJokerPlayStyle: String
    let selectedJokerLeadDeclaration: JokerDeclarationSnapshot?
    let trickWinnerPlayerIndex: Int
    let didPlayerWinTrick: Bool

    init(_ value: DealTrainingMoveSample) {
        self.blockIndex = value.blockIndex
        self.roundIndex = value.roundIndex
        self.trickIndex = value.trickIndex
        self.moveIndexInTrick = value.moveIndexInTrick
        self.playerIndex = value.playerIndex
        self.playerCount = value.playerCount
        self.cardsInRound = value.cardsInRound
        self.trump = value.trump.map { CardSnapshot.identifier($0) }
        self.playerBid = value.playerBid.map { $0 }
        self.playerTricksTakenBeforeMove = value.playerTricksTakenBeforeMove.map { $0 }
        self.handBeforeMove = value.handBeforeMove.map { CardSnapshot($0) }
        self.legalCards = value.legalCards.map { CardSnapshot($0) }
        self.playedCardsInTrickBeforeMove = value.playedCardsInTrickBeforeMove.map { DealTrickMoveSnapshot($0) }
        self.selectedCard = CardSnapshot(value.selectedCard)
        self.selectedJokerPlayStyle = (value.selectedJokerPlayStyle == .faceUp ? "faceUp" : "faceDown")
        self.selectedJokerLeadDeclaration = value.selectedJokerLeadDeclaration.map { JokerDeclarationSnapshot($0) }
        self.trickWinnerPlayerIndex = value.trickWinnerPlayerIndex
        self.didPlayerWinTrick = value.didPlayerWinTrick
    }

    func restore() throws -> DealTrainingMoveSample {
        return DealTrainingMoveSample(
            blockIndex: self.blockIndex,
            roundIndex: self.roundIndex,
            trickIndex: self.trickIndex,
            moveIndexInTrick: self.moveIndexInTrick,
            playerIndex: self.playerIndex,
            playerCount: self.playerCount,
            cardsInRound: self.cardsInRound,
            trump: try self.trump.map { try GameSessionSnapshot.decodeSuit($0) },
            playerBid: self.playerBid.map { $0 },
            playerTricksTakenBeforeMove: self.playerTricksTakenBeforeMove.map { $0 },
            handBeforeMove: try self.handBeforeMove.map { try $0.restore() },
            legalCards: try self.legalCards.map { try $0.restore() },
            playedCardsInTrickBeforeMove: try self.playedCardsInTrickBeforeMove.map { try $0.restore() },
            selectedCard: try self.selectedCard.restore(),
            selectedJokerPlayStyle: try GameSessionSnapshot.decodeStyle(self.selectedJokerPlayStyle),
            selectedJokerLeadDeclaration: try self.selectedJokerLeadDeclaration.map { try $0.restore() },
            trickWinnerPlayerIndex: self.trickWinnerPlayerIndex,
            didPlayerWinTrick: self.didPlayerWinTrick
        )
    }
}
