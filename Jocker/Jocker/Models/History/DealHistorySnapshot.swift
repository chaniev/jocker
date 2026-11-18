import Foundation

struct DealHistorySnapshot: Codable {
    let key: DealHistoryKeySnapshot
    let trump: String?
    let initialHands: [[CardSnapshot]]
    let tricks: [DealTrickHistorySnapshot]
    let trainingSamples: [DealTrainingMoveSampleSnapshot]

    init(_ value: DealHistory) {
        self.key = DealHistoryKeySnapshot(value.key)
        self.trump = value.trump.map { CardSnapshot.identifier($0) }
        self.initialHands = value.initialHands.map { $0.map { CardSnapshot($0) } }
        self.tricks = value.tricks.map { DealTrickHistorySnapshot($0) }
        self.trainingSamples = value.trainingSamples.map { DealTrainingMoveSampleSnapshot($0) }
    }

    func restore() throws -> DealHistory {
        return DealHistory(
            key: try self.key.restore(),
            trump: try self.trump.map { try GameSessionSnapshot.decodeSuit($0) },
            initialHands: try self.initialHands.map { try $0.map { try $0.restore() } },
            tricks: try self.tricks.map { try $0.restore() },
            trainingSamples: try self.trainingSamples.map { try $0.restore() }
        )
    }
}
