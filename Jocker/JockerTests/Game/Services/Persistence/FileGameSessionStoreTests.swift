import XCTest
@testable import Jocker

final class FileGameSessionStoreTests: XCTestCase {
    private var directory: URL!
    private var defaults: UserDefaults!
    private var suite: String!

    override func setUp() {
        super.setUp()
        self.directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        self.suite = "FileGameSessionStoreTests." + UUID().uuidString
        self.defaults = UserDefaults(suiteName: self.suite)!
    }
    override func tearDown() {
        try? FileManager.default.removeItem(at: self.directory)
        self.defaults.removePersistentDomain(forName: self.suite)
        super.tearDown()
    }
    private func store(write: @escaping (Data, URL) throws -> Void = { try $0.write(to: $1, options: .atomic) }) -> FileGameSessionStore {
        FileGameSessionStore(root: self.directory, statistics: FileGameStatisticsStore(url: self.directory.appendingPathComponent("stats.json"), legacy: self.defaults), write: write)
    }
    private func result<T>(_ operation: (@escaping (Result<T, Error>) -> Void) -> Void) throws -> T {
        let done = self.expectation(description: "serialized operation")
        var result: Result<T, Error>?
        operation { result = $0; done.fulfill() }
        self.wait(for: [done], timeout: 10)
        return try XCTUnwrap(result).get()
    }

    func testIndependentSlotsPersistAcrossRepositoryRecreation() throws {
        for slot in GameSessionSlot.allCases {
            let snapshot = GameSessionTestFixture.snapshot(slot: slot)
            try self.result { self.store().save(snapshot, completion: $0) }
        }
        for slot in GameSessionSlot.allCases {
            let loaded = try self.result { self.store().load(slot, completion: $0) }
            XCTAssertEqual(loaded?.slot, slot)
        }
        try self.result { self.store().discard(.threePlayers, completion: $0) }
        XCTAssertNil(try self.result { self.store().load(.threePlayers, completion: $0) })
        XCTAssertNotNil(try self.result { self.store().load(.fourPlayersPairs, completion: $0) })
    }

    func testFailedWritesKeepLastCheckpointAndLaterRevisionMaySkipFailures() throws {
        var failures: Set<Int> = [8, 9]
        let store = self.store { data, url in
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let active = object?["active"] as? [String: Any]
            if let revision = active?["revision"] as? Int, failures.contains(revision) { throw CocoaError(.fileWriteOutOfSpace) }
            try data.write(to: url, options: .atomic)
        }
        try self.result { store.save(GameSessionTestFixture.snapshot(revision: 7), completion: $0) }
        for revision in [8, 9] { XCTAssertThrowsError(try self.result { store.save(GameSessionTestFixture.snapshot(revision: revision), completion: $0) }) }
        XCTAssertEqual(try self.result { store.load(.fourPlayersFreeForAll, completion: $0) }?.revision, 7)
        try self.result { store.save(GameSessionTestFixture.snapshot(revision: 10), completion: $0) }
        failures = []
        XCTAssertThrowsError(try self.result { store.save(GameSessionTestFixture.snapshot(revision: 8), completion: $0) })
        XCTAssertEqual(try self.result { self.store().load(.fourPlayersFreeForAll, completion: $0) }?.revision, 10)
    }

    func testDiscardRejectsStaleSaveAfterRestart() throws {
        let snapshot = GameSessionTestFixture.snapshot()
        let store = self.store()
        try self.result { store.save(snapshot, completion: $0) }
        try self.result { store.discard(snapshot.slot, completion: $0) }
        XCTAssertThrowsError(try self.result { self.store().save(snapshot, completion: $0) })
        XCTAssertNil(try self.result { self.store().load(snapshot.slot, completion: $0) })
    }

    func testDiscardDamagedSnapshotCleansSlotNamespace() throws {
        let store = self.store()
        let snapshot = GameSessionTestFixture.snapshot()
        try self.result { store.save(snapshot, completion: $0) }
        try Data("broken".utf8).write(to: self.directory.appendingPathComponent(snapshot.slot.rawValue + ".json"))
        let staging = self.directory.appendingPathComponent("staging-" + snapshot.slot.rawValue)
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
        try Data("owned".utf8).write(to: staging.appendingPathComponent("block.json"))
        XCTAssertThrowsError(try self.result { store.load(snapshot.slot, completion: $0) })
        try self.result { store.discard(snapshot.slot, completion: $0) }
        XCTAssertFalse(FileManager.default.fileExists(atPath: staging.path))
        XCTAssertNil(try self.result { store.load(snapshot.slot, completion: $0) })
    }

    func testDiscardTombstoneSurvivesFailureBeforeRetirement() throws {
        var failRetirement = true
        let store = self.store { data, url in
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if failRetirement, object?["discardPending"] as? Bool == false, object?["active"] == nil { throw CocoaError(.fileWriteOutOfSpace) }
            try data.write(to: url, options: .atomic)
        }
        let snapshot = GameSessionTestFixture.snapshot()
        try self.result { store.save(snapshot, completion: $0) }
        XCTAssertThrowsError(try self.result { store.discard(snapshot.slot, completion: $0) })
        failRetirement = false
        XCTAssertNil(try self.result { self.store().load(snapshot.slot, completion: $0) })
        XCTAssertThrowsError(try self.result { self.store().save(snapshot, completion: $0) })
    }

    func testFirstSaveFailureDoesNotInventSavedGame() throws {
        let store = self.store { _, _ in throw CocoaError(.fileWriteOutOfSpace) }
        XCTAssertThrowsError(try self.result { store.save(GameSessionTestFixture.snapshot(), completion: $0) })
        XCTAssertNil(try self.result { self.store().load(.fourPlayersFreeForAll, completion: $0) })
    }
}
