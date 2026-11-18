import Foundation

struct RoundResultSnapshot: Codable {
    let cardsInRound: Int
    let bid: Int
    let tricksTaken: Int
    let isBlind: Bool
    let scoreAdjustment: Int
    let recordedScore: Int

    init(_ value: RoundResult) {
        self.cardsInRound = value.cardsInRound
        self.bid = value.bid
        self.tricksTaken = value.tricksTaken
        self.isBlind = value.isBlind
        self.scoreAdjustment = value.scoreAdjustment
        self.recordedScore = value.score
    }

    func restore() throws -> RoundResult {
        let base = ScoreCalculator.calculateRoundScore(cardsInRound: self.cardsInRound, bid: self.bid, tricksTaken: self.tricksTaken, isBlind: self.isBlind)
        return RoundResult(
            cardsInRound: self.cardsInRound,
            bid: self.bid,
            tricksTaken: self.tricksTaken,
            isBlind: self.isBlind,
            scoreAdjustment: self.recordedScore - base
        )
    }
}
