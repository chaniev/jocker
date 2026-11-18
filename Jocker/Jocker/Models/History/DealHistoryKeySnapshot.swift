import Foundation

struct DealHistoryKeySnapshot: Codable {
    let blockIndex: Int
    let roundIndex: Int

    init(_ value: DealHistoryKey) {
        self.blockIndex = value.blockIndex
        self.roundIndex = value.roundIndex
    }

    func restore() throws -> DealHistoryKey {
        return DealHistoryKey(
            blockIndex: self.blockIndex,
            roundIndex: self.roundIndex
        )
    }
}
