import XCTest
@testable import Jocker

final class GameCompletionRecoveryTests: XCTestCase {
    private func result<T>(_ operation: (@escaping (Result<T, Error>) -> Void) -> Void) throws -> T {
        let done = self.expectation(description: "completion")
        var result: Result<T, Error>?
        operation { result = $0; done.fulfill() }
        self.wait(for: [done], timeout: 10)
        return try XCTUnwrap(result).get()
    }

    func testMultipleReceiptsSurviveNewSameSlotGamesDiscardAndStatisticsOutage() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let suite = "GameCompletionRecoveryTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { try? FileManager.default.removeItem(at: root); defaults.removePersistentDomain(forName: suite) }
        let statsURL = root.appendingPathComponent("stats.json")
        let stats = FileGameStatisticsStore(url: statsURL, legacy: defaults)
        let store = FileGameSessionStore(root: root, statistics: stats)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let damaged = Data("unavailable".utf8)
        try damaged.write(to: statsURL)
        for number in 1...3 {
            let id = UUID(uuidString: "00000000-0000-0000-0000-00000000000\(number)")!
            try self.result { store.markTerminal(GameSessionTestFixture.terminal(matchID: id), completion: $0) }
            XCTAssertThrowsError(try self.result { store.recover(completion: $0) })
            XCTAssertNil(try self.result { store.load(.fourPlayersFreeForAll, completion: $0) })
        }
        let newID = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
        let active = GameSessionTestFixture.snapshot(matchID: newID)
        try self.result { store.save(active, completion: $0) }
        try self.result { store.discard(active.slot, completion: $0) }
        let latestID = UUID(uuidString: "00000000-0000-0000-0000-000000000005")!
        try self.result { store.save(GameSessionTestFixture.snapshot(matchID: latestID), completion: $0) }
        XCTAssertEqual(try Data(contentsOf: statsURL), damaged)
        try FileManager.default.removeItem(at: statsURL)
        let restarted = FileGameSessionStore(root: root, statistics: stats)
        try self.result { restarted.recover(completion: $0) }
        try self.result { restarted.recover(completion: $0) }
        XCTAssertEqual(try stats.loadSnapshotResult().get().allGamesRecords[0].gamesPlayed, 3)
        XCTAssertEqual(try self.result { restarted.load(active.slot, completion: $0) }?.matchID, latestID)
    }

    func testCrashAfterAggregateBeforeCleanupReplaysWithoutDoubleCounting() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let suite = "InterruptedFinalization." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { try? FileManager.default.removeItem(at: root); defaults.removePersistentDomain(forName: suite) }
        let stats = FileGameStatisticsStore(url: root.appendingPathComponent("stats.json"), legacy: defaults)
        let store = FileGameSessionStore(root: root, statistics: stats) { data, url in
            if url.lastPathComponent == "fourPlayersFreeForAll.json", let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let retired = object["retired"] as? [String], !retired.isEmpty { throw CocoaError(.fileWriteOutOfSpace) }
            try data.write(to: url, options: .atomic)
        }
        try self.result { store.save(GameSessionTestFixture.snapshot(), completion: $0) }
        try self.result { store.markTerminal(GameSessionTestFixture.terminal(), completion: $0) }
        XCTAssertThrowsError(try self.result { store.recover(completion: $0) })
        XCTAssertEqual(try stats.loadSnapshotResult().get().allGamesRecords[0].gamesPlayed, 1)
        XCTAssertNil(try self.result { store.load(.fourPlayersFreeForAll, completion: $0) })
        let restarted = FileGameSessionStore(root: root, statistics: stats)
        try self.result { restarted.recover(completion: $0) }
        try self.result { restarted.recover(completion: $0) }
        XCTAssertEqual(try stats.loadSnapshotResult().get().allGamesRecords[0].gamesPlayed, 1)
    }

    func testTerminalWriteFailureLeavesActiveCheckpointAndNoStatistics() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let suite = "TerminalFailure." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { try? FileManager.default.removeItem(at: root); defaults.removePersistentDomain(forName: suite) }
        let stats = FileGameStatisticsStore(url: root.appendingPathComponent("stats.json"), legacy: defaults)
        let store = FileGameSessionStore(root: root, statistics: stats) { data, url in
            if url.deletingLastPathComponent().lastPathComponent == "receipts" { throw CocoaError(.fileWriteOutOfSpace) }
            try data.write(to: url, options: .atomic)
        }
        try self.result { store.save(GameSessionTestFixture.snapshot(revision: 7), completion: $0) }
        XCTAssertThrowsError(try self.result { store.markTerminal(GameSessionTestFixture.terminal(), completion: $0) })
        XCTAssertEqual(try self.result { store.load(.fourPlayersFreeForAll, completion: $0) }?.revision, 7)
        XCTAssertEqual(try stats.loadSnapshotResult().get().allGamesRecords[0].gamesPlayed, 0)
    }

    func testMigrationPreservesEveryScopeAndRunsOnlyOnceForBothLegacyVersions() throws {
        for version in [1, 2] {
            let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            let suite = "Migration." + UUID().uuidString
            let defaults = UserDefaults(suiteName: suite)!
            defer { try? FileManager.default.removeItem(at: root); defaults.removePersistentDomain(forName: suite) }
            var original = GameStatisticsSnapshot.empty()
            for scope in GameStatisticsScope.allCases {
                var records = original.records(for: scope)
                records[0].gamesPlayed = 17
                records[0].maxTotalScore = 123.4
                records[0].minTotalScore = -42.3
                records[0].premiumsByBlock = [1, 2, 3, 4]
                original.setRecords(records, for: scope)
            }
            let key = "Jocker.GameStatisticsSnapshot.v\(version)"
            let legacy = try JSONEncoder().encode(original)
            defaults.set(legacy, forKey: key)
            let url = root.appendingPathComponent("stats.json")
            let store = FileGameStatisticsStore(url: url, legacy: defaults)
            XCTAssertEqual(try store.loadSnapshotResult().get(), original)
            defaults.set(Data("invalid".utf8), forKey: key)
            XCTAssertEqual(try FileGameStatisticsStore(url: url, legacy: defaults).loadSnapshotResult().get(), original)
        }
    }

    func testMalformedLegacyDataDoesNotCreateCanonicalEmptyStatistics() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let suite = "InvalidMigration." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { try? FileManager.default.removeItem(at: root); defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("invalid".utf8), forKey: "Jocker.GameStatisticsSnapshot.v2")
        let url = root.appendingPathComponent("stats.json")
        XCTAssertThrowsError(try FileGameStatisticsStore(url: url, legacy: defaults).loadSnapshotResult().get())
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }
}
