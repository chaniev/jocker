import Foundation

struct ScoreManagerSnapshot: Codable {
    var completedBlocks: [BlockResultSnapshot]
    var currentRounds: [[RoundResultSnapshot]]
    var inProgress: [RoundResultSnapshot]?
    var inProgressBlock: Int?
    var inProgressRound: Int?

    init(_ manager: ScoreManager) {
        self.completedBlocks = manager.completedBlocks.map(BlockResultSnapshot.init)
        self.currentRounds = manager.currentBlockRoundResults.map { $0.map(RoundResultSnapshot.init) }
        self.inProgress = manager.inProgressRoundResults?.map(RoundResultSnapshot.init)
        self.inProgressBlock = manager.inProgressRoundBlockIndex
        self.inProgressRound = manager.inProgressRoundIndex
    }
    func restore(into manager: ScoreManager) throws {
        manager.restore(completedBlocks: try self.completedBlocks.map { try $0.restore() },
            currentRounds: try self.currentRounds.map { try $0.map { try $0.restore() } },
            inProgress: try self.inProgress?.map { try $0.restore() },
            inProgressBlock: self.inProgressBlock, inProgressRound: self.inProgressRound)
    }
}
