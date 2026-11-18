import Foundation

/// One app-owned writer. Every mutation is serialized, including recovery and retirement.
final class FileGameSessionStore: GameSessionStore {
    private struct Container: Codable {
        var schemaVersion = 1
        var active: GameSessionSnapshot?
        var retired: Set<UUID> = []
        var discardPending = false
    }
    private let root: URL
    private let queue = DispatchQueue(label: "Jocker.sessions", qos: .utility)
    private let statistics: FileGameStatisticsStore
    private let write: (Data, URL) throws -> Void
    private let codec = GameSessionCodec()
    private var observedMatches: [GameSessionSlot: Set<UUID>] = [:]

    init(root: URL, statistics: FileGameStatisticsStore, write: @escaping (Data, URL) throws -> Void = { try $0.write(to: $1, options: .atomic) }) {
        self.root = root
        self.statistics = statistics
        self.write = write
    }

    private func perform<T>(_ completion: @escaping (Result<T, Error>) -> Void, work: @escaping () throws -> T) {
        self.queue.async {
            let result = Result { try work() }
            DispatchQueue.main.async { completion(result) }
        }
    }
    private func slotURL(_ slot: GameSessionSlot) -> URL { self.root.appendingPathComponent(slot.rawValue + ".json") }
    private var receiptsURL: URL { self.root.appendingPathComponent("receipts", isDirectory: true) }
    private func receiptURL(_ id: UUID) -> URL { self.receiptsURL.appendingPathComponent(id.uuidString + ".json") }
    private func materialsURL(_ slot: GameSessionSlot) -> URL { self.root.appendingPathComponent("staging-" + slot.rawValue, isDirectory: true) }

    private func read(_ slot: GameSessionSlot) throws -> Container {
        let url = self.slotURL(slot)
        guard FileManager.default.fileExists(atPath: url.path) else { return Container() }
        let container = try JSONDecoder().decode(Container.self, from: Data(contentsOf: url))
        guard container.schemaVersion == 1 else { throw GameSessionError.unsupportedVersion }
        return container
    }
    private func persist(_ container: Container, slot: GameSessionSlot) throws {
        try FileManager.default.createDirectory(at: self.root, withIntermediateDirectories: true)
        try self.write(JSONEncoder().encode(container), self.slotURL(slot))
    }
    private func finishDiscard(_ container: Container, slot: GameSessionSlot) throws -> Container {
        guard container.discardPending else { return container }
        let materials = self.materialsURL(slot)
        if FileManager.default.fileExists(atPath: materials.path) { try FileManager.default.removeItem(at: materials) }
        var cleaned = container
        cleaned.discardPending = false
        try self.persist(cleaned, slot: slot)
        return cleaned
    }
    func load(_ slot: GameSessionSlot, completion: @escaping (Result<GameSessionSnapshot?, Error>) -> Void) {
        self.perform(completion) {
            let container = try self.finishDiscard(self.read(slot), slot: slot)
            guard let active = container.active else { return nil }
            if FileManager.default.fileExists(atPath: self.receiptURL(active.matchID).path) { return nil }
            self.observedMatches[slot, default: []].insert(active.matchID)
            try active.validate()
            guard active.slot == slot, !container.retired.contains(active.matchID) else { throw GameSessionError.invalidSnapshot }
            return active
        }
    }
    func save(_ snapshot: GameSessionSnapshot, completion: @escaping (Result<Void, Error>) -> Void) {
        self.perform(completion) {
            self.observedMatches[snapshot.slot, default: []].insert(snapshot.matchID)
            try snapshot.validate()
            guard snapshot.flow.stage != .terminal, snapshot.scores.completedBlocks.count < GameConstants.totalBlocks else { throw GameSessionError.invalidSnapshot }
            var container = try self.read(snapshot.slot)
            guard !container.discardPending, !container.retired.contains(snapshot.matchID),
                  !FileManager.default.fileExists(atPath: self.receiptURL(snapshot.matchID).path) else { throw GameSessionError.retiredMatch }
            if let active = container.active {
                if active.matchID != snapshot.matchID {
                    guard FileManager.default.fileExists(atPath: self.receiptURL(active.matchID).path) else { throw GameSessionError.occupiedSlot }
                    container.retired.insert(active.matchID)
                } else if active.revision > snapshot.revision { throw GameSessionError.staleRevision }
                else if active.revision == snapshot.revision { return }
            }
            container.active = snapshot
            try self.persist(container, slot: snapshot.slot)
            // Block exports are owned, private staging data. Their failure is an ordinary autosave failure.
            try? self.stageCompletedBlocks(snapshot)
        }
    }
    func discard(_ slot: GameSessionSlot, completion: @escaping (Result<Void, Error>) -> Void) {
        self.perform(completion) {
            // A damaged payload must not prevent retirement or cleanup of its slot namespace.
            var container: Container
            do { container = try self.read(slot) } catch { container = Container() }
            container.retired.formUnion(self.observedMatches[slot] ?? [])
            if let active = container.active { container.retired.insert(active.matchID) }
            container.active = nil
            container.discardPending = true
            try self.persist(container, slot: slot)
            _ = try self.finishDiscard(container, slot: slot)
        }
    }
    func markTerminal(_ snapshot: GameSessionSnapshot, completion: @escaping (Result<Void, Error>) -> Void) {
        self.perform(completion) {
            guard snapshot.flow.stage == .terminal else { throw GameSessionError.invalidSnapshot }
            let data = try self.codec.encode(snapshot)
            let container = try self.read(snapshot.slot)
            guard !container.retired.contains(snapshot.matchID), !container.discardPending else { throw GameSessionError.retiredMatch }
            if let active = container.active {
                guard active.matchID == snapshot.matchID else { throw GameSessionError.occupiedSlot }
                guard active.revision <= snapshot.revision else { throw GameSessionError.staleRevision }
            }
            if FileManager.default.fileExists(atPath: self.receiptURL(snapshot.matchID).path) {
                _ = try self.codec.decode(Data(contentsOf: self.receiptURL(snapshot.matchID)))
                return
            }
            try FileManager.default.createDirectory(at: self.receiptsURL, withIntermediateDirectories: true)
            // Receipt is the commit point. Its lifetime is independent of the active slot.
            try self.write(data, self.receiptURL(snapshot.matchID))
        }
    }
    func recover(completion: @escaping (Result<Void, Error>) -> Void) {
        self.perform(completion) {
            var failure: Error?
            for slot in GameSessionSlot.allCases {
                do { _ = try self.finishDiscard(self.read(slot), slot: slot) } catch { /* Report active-slot errors only when that variant is selected. */ }
            }
            if FileManager.default.fileExists(atPath: self.receiptsURL.path) {
                for url in try FileManager.default.contentsOfDirectory(at: self.receiptsURL, includingPropertiesForKeys: nil) where url.pathExtension == "json" {
                    do {
                        let receipt = try self.codec.decode(Data(contentsOf: url))
                        try self.finalize(receipt)
                        try FileManager.default.removeItem(at: url)
                    } catch { failure = error }
                }
            }
            if let failure { throw failure }
        }
    }
    private func stageCompletedBlocks(_ snapshot: GameSessionSnapshot) throws {
        guard !snapshot.scores.completedBlocks.isEmpty else { return }
        let directory = self.materialsURL(snapshot.slot).appendingPathComponent(snapshot.matchID.uuidString, isDirectory: true)
        let exporter = DealHistoryExportService(exportRootURL: directory, dateProvider: { Date(timeIntervalSince1970: 0) })
        for block in 0..<min(3, snapshot.scores.completedBlocks.count) {
            let name = "deal_history_block_\(block)_19700101_000000.json"
            if FileManager.default.fileExists(atPath: directory.appendingPathComponent(name).path) { continue }
            let histories = try snapshot.history.histories.map { try $0.restore() }.filter { $0.key.blockIndex <= block }
            guard !histories.isEmpty else { continue }
            guard exporter.export(histories: histories, playerCount: snapshot.slot.playerCount, gameMode: snapshot.slot.gameMode,
                playerNames: snapshot.state.players.map(\.name), playerControlTypes: snapshot.configuration.playerControlTypes,
                reason: .blockCompleted(blockIndex: block)) != nil else { throw CocoaError(.fileWriteUnknown) }
        }
    }

    private func finalize(_ receipt: GameSessionSnapshot) throws {
        guard receipt.flow.stage == .terminal else { throw GameSessionError.invalidSnapshot }
        let blocks = try receipt.scores.completedBlocks.map { try $0.restore() }
        let summaries = GameFinalPlayerSummary.build(playerNames: receipt.state.players.map(\.name), playerCount: receipt.slot.playerCount, gameMode: receipt.slot.gameMode, completedBlocks: blocks)
        try self.statistics.record(matchID: receipt.matchID, playerCount: receipt.slot.playerCount, gameMode: receipt.slot.gameMode, playerSummaries: summaries, completedBlocks: blocks)
        let histories = try receipt.history.histories.map { try $0.restore() }
        if !histories.isEmpty {
            let exports = self.root.appendingPathComponent("completed", isDirectory: true).appendingPathComponent(receipt.matchID.uuidString, isDirectory: true)
            let exporter = DealHistoryExportService(exportRootURL: exports, dateProvider: { Date(timeIntervalSince1970: 0) })
            guard exporter.export(histories: histories, playerCount: receipt.slot.playerCount, gameMode: receipt.slot.gameMode,
                playerNames: receipt.state.players.map(\.name), playerControlTypes: receipt.configuration.playerControlTypes, reason: .gameCompleted) != nil else { throw CocoaError(.fileWriteUnknown) }
        }
        var container = try self.read(receipt.slot)
        container.retired.insert(receipt.matchID)
        if container.active?.matchID == receipt.matchID { container.active = nil }
        try self.persist(container, slot: receipt.slot)
        let materials = self.materialsURL(receipt.slot).appendingPathComponent(receipt.matchID.uuidString, isDirectory: true)
        if FileManager.default.fileExists(atPath: materials.path) { try FileManager.default.removeItem(at: materials) }
    }
}
