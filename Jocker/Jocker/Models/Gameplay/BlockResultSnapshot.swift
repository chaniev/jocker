import Foundation

struct BlockResultSnapshot: Codable {
    let roundResults: [[RoundResultSnapshot]]
    let baseScores: [Int]
    let premiumPlayerIndices: [Int]
    let premiumBonuses: [Int]
    let premiumPenalties: [Int]
    let premiumPenaltyRoundIndices: [Int?]
    let premiumPenaltyRoundScores: [Int]
    let zeroPremiumPlayerIndices: [Int]
    let zeroPremiumBonuses: [Int]
    let finalScores: [Int]

    init(_ value: BlockResult) {
        self.roundResults = value.roundResults.map { $0.map { RoundResultSnapshot($0) } }
        self.baseScores = value.baseScores
        self.premiumPlayerIndices = value.premiumPlayerIndices
        self.premiumBonuses = value.premiumBonuses
        self.premiumPenalties = value.premiumPenalties
        self.premiumPenaltyRoundIndices = value.premiumPenaltyRoundIndices
        self.premiumPenaltyRoundScores = value.premiumPenaltyRoundScores
        self.zeroPremiumPlayerIndices = value.zeroPremiumPlayerIndices
        self.zeroPremiumBonuses = value.zeroPremiumBonuses
        self.finalScores = value.finalScores
    }

    func restore() throws -> BlockResult {
        return BlockResult(
            roundResults: try self.roundResults.map { try $0.map { try $0.restore() } },
            baseScores: self.baseScores,
            premiumPlayerIndices: self.premiumPlayerIndices,
            premiumBonuses: self.premiumBonuses,
            premiumPenalties: self.premiumPenalties,
            premiumPenaltyRoundIndices: self.premiumPenaltyRoundIndices,
            premiumPenaltyRoundScores: self.premiumPenaltyRoundScores,
            zeroPremiumPlayerIndices: self.zeroPremiumPlayerIndices,
            zeroPremiumBonuses: self.zeroPremiumBonuses,
            finalScores: self.finalScores
        )
    }
}
