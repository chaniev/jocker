//
//  DealHistoryExportServiceTests.swift
//  JockerTests
//
//  Created by Codex on 19.02.2026.
//

import XCTest
@testable import Jocker

final class DealHistoryExportServiceTests: XCTestCase {
    func testExport_whenHistoriesProvided_writesJsonFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DealHistoryExportServiceTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let fixedDate = Date(timeIntervalSince1970: 1_739_000_000)
        let service = DealHistoryExportService(
            exportRootURL: tempDirectory,
            dateProvider: { fixedDate }
        )

        let move = DealTrickMove(
            playerIndex: 0,
            card: .regular(suit: .hearts, rank: .ace)
        )
        let sample = DealTrainingMoveSample(
            blockIndex: 0,
            roundIndex: 0,
            trickIndex: 0,
            moveIndexInTrick: 0,
            playerIndex: 0,
            playerCount: 4,
            cardsInRound: 2,
            trump: .hearts,
            playerBid: 1,
            playerTricksTakenBeforeMove: 0,
            handBeforeMove: [.regular(suit: .hearts, rank: .ace), .regular(suit: .clubs, rank: .six)],
            legalCards: [.regular(suit: .hearts, rank: .ace), .regular(suit: .clubs, rank: .six)],
            playedCardsInTrickBeforeMove: [],
            selectedCard: .regular(suit: .hearts, rank: .ace),
            selectedJokerPlayStyle: .faceUp,
            selectedJokerLeadDeclaration: nil,
            trickWinnerPlayerIndex: 0,
            didPlayerWinTrick: true
        )
        let history = DealHistory(
            key: DealHistoryKey(blockIndex: 0, roundIndex: 0),
            trump: .hearts,
            initialHands: [
                [.regular(suit: .hearts, rank: .ace), .joker],
                [.regular(suit: .clubs, rank: .six)]
            ],
            tricks: [DealTrickHistory(moves: [move], winnerPlayerIndex: 0)],
            trainingSamples: [sample]
        )

        let result = service.export(
            histories: [history],
            playerCount: 4,
            playerNames: ["Игрок 1", "Игрок 2", "Игрок 3", "Игрок 4"],
            playerControlTypes: [.human, .bot, .bot, .bot],
            reason: .blockCompleted(blockIndex: 0)
        )

        guard let result else {
            XCTFail("Expected non-nil export result")
            return
        }

        XCTAssertTrue(FileManager.default.fileExists(atPath: result.fileURL.path))
        XCTAssertEqual(result.dealCount, 1)
        XCTAssertEqual(result.trainingSampleCount, 1)

        let rawData = try Data(contentsOf: result.fileURL)
        let jsonObject = try JSONSerialization.jsonObject(with: rawData)
        guard let payload = jsonObject as? [String: Any] else {
            XCTFail("Expected top-level JSON object")
            return
        }

        XCTAssertEqual(payload["schemaVersion"] as? Int, 1)
        XCTAssertEqual(payload["exportReason"] as? String, "block_0")
        XCTAssertEqual(payload["playerCount"] as? Int, 4)
        guard let deals = payload["deals"] as? [[String: Any]], let firstDeal = deals.first else {
            XCTFail("Expected deals payload")
            return
        }
        XCTAssertEqual(deals.count, 1)
        let initialHands = firstDeal["initialHands"] as? [[String: Any]]
        XCTAssertEqual(initialHands?.count, 2)
        XCTAssertEqual(initialHands?.first?["playerIndex"] as? Int, 0)
        XCTAssertEqual((initialHands?.first?["cards"] as? [[String: Any]])?.count, 2)
        XCTAssertEqual((payload["trainingSamples"] as? [[String: Any]])?.count, 1)
    }

    func testExport_whenHistoriesEmpty_returnsNil() {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DealHistoryExportServiceTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let service = DealHistoryExportService(exportRootURL: tempDirectory)
        let result = service.export(
            histories: [],
            playerCount: 4,
            playerNames: [],
            playerControlTypes: [],
            reason: .gameCompleted
        )

        XCTAssertNil(result)
    }
}
