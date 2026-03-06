//
//  GameStatisticsPresentationProviderTests.swift
//  JockerTests
//
//  Created by Codex on 06.03.2026.
//

import XCTest
@testable import Jocker

final class GameStatisticsPresentationProviderTests: XCTestCase {
    func testMakePresentation_buildsHeaderAndMetricsForThreePlayers() {
        let records = [
            GameStatisticsPlayerRecord(
                playerIndex: 0,
                gamesPlayed: 8,
                firstPlaceCount: 4,
                secondPlaceCount: 2,
                thirdPlaceCount: 2,
                fourthPlaceCount: 0,
                premiumsByBlock: [1, 0, 2, 1],
                blindBidCount: 3,
                maxTotalScore: 123.44,
                minTotalScore: -20.01
            ),
            GameStatisticsPlayerRecord.empty(playerIndex: 1),
            GameStatisticsPlayerRecord(
                playerIndex: 2,
                gamesPlayed: 5,
                firstPlaceCount: 1,
                secondPlaceCount: 2,
                thirdPlaceCount: 2,
                fourthPlaceCount: 0,
                premiumsByBlock: [0, 1, 0, 0],
                blindBidCount: 1,
                maxTotalScore: 50,
                minTotalScore: 10
            )
        ]

        let presentation = GameStatisticsPresentationProvider().makePresentation(
            records: records,
            visiblePlayerCount: 3,
            playerNames: ["Анна", "   ", "Бот Юг", "Бот Запад"]
        )

        XCTAssertEqual(presentation.visiblePlayerCount, 3)
        XCTAssertEqual(presentation.rows.first?.title, "Показатель")
        XCTAssertEqual(presentation.rows.first?.values, ["Анна", "Игрок 2", "Бот Юг"])
        XCTAssertFalse(presentation.rows.contains(where: { $0.title == "4 место" }))
        XCTAssertEqual(
            presentation.rows.first(where: { $0.title == "Премии блок 3" })?.values,
            ["2", "0", "0"]
        )
        XCTAssertEqual(
            presentation.rows.first(where: { $0.title == "Макс. очков за игру" })?.values,
            ["123,4", "-", "50,0"]
        )
        XCTAssertEqual(
            presentation.rows.first(where: { $0.title == "Мин. очков за игру" })?.values,
            ["-20,0", "-", "10,0"]
        )
    }

    func testMakePresentation_addsMissingRecordsAndFourthPlaceForFourPlayers() {
        let presentation = GameStatisticsPresentationProvider().makePresentation(
            records: [GameStatisticsPlayerRecord.empty(playerIndex: 0)],
            visiblePlayerCount: 4,
            playerNames: ["Игрок 1"]
        )

        XCTAssertEqual(presentation.rows.first?.values, ["Игрок 1", "Игрок 2", "Игрок 3", "Игрок 4"])
        XCTAssertTrue(presentation.rows.contains(where: { $0.title == "4 место" }))
    }

    func testMakePresentation_fillsMissingSeatIndicesInsteadOfDuplicatingLastRecord() {
        let records = [
            GameStatisticsPlayerRecord(
                playerIndex: 0,
                gamesPlayed: 3,
                firstPlaceCount: 1,
                secondPlaceCount: 1,
                thirdPlaceCount: 1,
                fourthPlaceCount: 0,
                premiumsByBlock: [0, 1, 0, 0],
                blindBidCount: 1,
                maxTotalScore: 80,
                minTotalScore: 10
            ),
            GameStatisticsPlayerRecord(
                playerIndex: 2,
                gamesPlayed: 5,
                firstPlaceCount: 2,
                secondPlaceCount: 2,
                thirdPlaceCount: 1,
                fourthPlaceCount: 0,
                premiumsByBlock: [1, 0, 0, 0],
                blindBidCount: 2,
                maxTotalScore: 120,
                minTotalScore: -5
            )
        ]

        let presentation = GameStatisticsPresentationProvider().makePresentation(
            records: records,
            visiblePlayerCount: 3,
            playerNames: ["Игрок 1", "Игрок 2", "Игрок 3"]
        )

        XCTAssertEqual(presentation.rows.first?.values, ["Игрок 1", "Игрок 2", "Игрок 3"])
        XCTAssertEqual(
            presentation.rows.first(where: { $0.title == "Количество игр" })?.values,
            ["3", "0", "5"]
        )
    }
}
