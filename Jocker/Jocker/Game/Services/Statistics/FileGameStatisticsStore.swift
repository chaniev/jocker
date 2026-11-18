import Foundation

final class FileGameStatisticsStore: GameStatisticsStore {
    private struct Container: Codable {
        var schemaVersion = 1
        var snapshot: GameStatisticsSnapshot
        var appliedMatchIDs: Set<UUID> = []
        var legacyImportVersion = 2
    }
    private let url: URL
    private let legacy: UserDefaults
    private let lock = NSRecursiveLock()
    private let write: (Data, URL) throws -> Void

    init(url: URL, legacy: UserDefaults = .standard, write: @escaping (Data, URL) throws -> Void = { try $0.write(to: $1, options: .atomic) }) {
        self.url = url
        self.legacy = legacy
        self.write = write
    }

    func loadSnapshotResult() -> Result<GameStatisticsSnapshot, Error> {
        self.lock.lock()
        defer { self.lock.unlock() }
        return Result { try self.read().snapshot }
    }
    // Compatibility for existing presentation providers; live screens check the Result first.
    func loadSnapshot() -> GameStatisticsSnapshot {
        (try? self.loadSnapshotResult().get()) ?? .empty(playerSlots: 4)
    }
    func recordCompletedGame(playerCount: Int, gameMode: GameMode, playerSummaries: [GameFinalPlayerSummary], completedBlocks: [BlockResult]) {
        // Legacy call sites cannot identify a match; only the receipt path writes the live repository.
    }
    func recordCompletedGame(matchID: UUID, playerCount: Int, gameMode: GameMode, playerSummaries: [GameFinalPlayerSummary], completedBlocks: [BlockResult]) -> Result<Void, Error> {
        Result { try self.record(matchID: matchID, playerCount: playerCount, gameMode: gameMode, playerSummaries: playerSummaries, completedBlocks: completedBlocks) }
    }
    func record(matchID: UUID, playerCount: Int, gameMode: GameMode, playerSummaries: [GameFinalPlayerSummary], completedBlocks: [BlockResult]) throws {
        self.lock.lock()
        defer { self.lock.unlock() }
        var container = try self.read()
        guard !container.appliedMatchIDs.contains(matchID) else { return }
        container.snapshot = GameStatisticsAccumulator().applying(to: container.snapshot, playerCount: playerCount,
            gameMode: gameMode, playerSummaries: playerSummaries, completedBlocks: completedBlocks)
        container.appliedMatchIDs.insert(matchID)
        try self.persist(container)
    }
    private func read() throws -> Container {
        if FileManager.default.fileExists(atPath: self.url.path) {
            let data = try Data(contentsOf: self.url)
            guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let snapshot = object["snapshot"] as? [String: Any], snapshot["allGamesRecords"] is [Any] else { throw GameSessionError.invalidSnapshot }
            let container = try JSONDecoder().decode(Container.self, from: data)
            guard container.schemaVersion == 1 else { throw GameSessionError.unsupportedVersion }
            try self.validate(container.snapshot)
            return container
        }
        var snapshot = GameStatisticsSnapshot.empty(playerSlots: 4)
        for version in [2, 1] {
            let key = "Jocker.GameStatisticsSnapshot.v\(version)"
            if self.legacy.object(forKey: key) != nil {
                guard let data = self.legacy.data(forKey: key) else { throw GameSessionError.invalidSnapshot }
                guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      object["allGamesRecords"] is [Any] else { throw GameSessionError.invalidSnapshot }
                let decoded = try JSONDecoder().decode(GameStatisticsSnapshot.self, from: data)
                try self.validate(decoded)
                snapshot = try JSONDecoder().decode(GameStatisticsSnapshot.self, from: data).normalized(playerSlots: 4)
                break
            }
        }
        let container = Container(snapshot: snapshot)
        try self.persist(container)
        return container
    }
    private func validate(_ snapshot: GameStatisticsSnapshot) throws {
        for scope in GameStatisticsScope.allCases {
            let records = snapshot.records(for: scope)
            guard Set(records.map(\.playerIndex)).count == records.count,
                  records.allSatisfy({ (0..<4).contains($0.playerIndex) && $0.gamesPlayed >= 0
                    && $0.premiumsByBlock.allSatisfy({ $0 >= 0 })
                    && ($0.maxTotalScore?.isFinite ?? true) && ($0.minTotalScore?.isFinite ?? true) }) else { throw GameSessionError.invalidSnapshot }
        }
    }

    private func persist(_ container: Container) throws {
        try FileManager.default.createDirectory(at: self.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try self.write(JSONEncoder().encode(container), self.url)
    }
}
