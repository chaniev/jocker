//
//  GameStatisticsTableViewTests.swift
//  JockerTests
//
//  Created by Codex on 20.02.2026.
//

import XCTest
@testable import Jocker

final class GameStatisticsTableViewTests: XCTestCase {
    @MainActor
    func testUpdate_usesProvidedPlayerNamesInHeader() {
        let tableView = GameStatisticsTableView(frame: CGRect(x: 0, y: 0, width: 900, height: 500))
        tableView.layoutIfNeeded()

        let records = (0..<4).map(GameStatisticsPlayerRecord.empty)
        tableView.update(
            records: records,
            visiblePlayerCount: 4,
            playerNames: ["Человек", "Бот Север", "Бот Юг", "Бот Запад"]
        )

        let headerValues = headerRowValues(in: tableView)

        XCTAssertEqual(headerValues[0], "Показатель")
        XCTAssertEqual(headerValues[1], "Человек")
        XCTAssertEqual(headerValues[2], "Бот Север")
        XCTAssertEqual(headerValues[3], "Бот Юг")
        XCTAssertEqual(headerValues[4], "Бот Запад")
    }

    @MainActor
    func testUpdate_fallsBackToDefaultNameWhenProvidedNameIsEmpty() {
        let tableView = GameStatisticsTableView(frame: CGRect(x: 0, y: 0, width: 900, height: 500))
        tableView.layoutIfNeeded()

        let records = (0..<3).map(GameStatisticsPlayerRecord.empty)
        tableView.update(
            records: records,
            visiblePlayerCount: 3,
            playerNames: ["Игрок", "   ", "Бот 3", "Бот 4"]
        )

        let headerValues = headerRowValues(in: tableView)

        XCTAssertEqual(headerValues[1], "Игрок")
        XCTAssertEqual(headerValues[2], "Игрок 2")
        XCTAssertEqual(headerValues[3], "Бот 3")
    }

    @MainActor
    private func headerRowValues(in tableView: GameStatisticsTableView) -> [String] {
        guard let rowsStackView = Mirror(reflecting: tableView).descendant("rowsStackView") as? UIStackView else {
            XCTFail("Не удалось получить rowsStackView")
            return []
        }

        guard let headerRow = rowsStackView.arrangedSubviews.first as? UIStackView else {
            XCTFail("Не удалось получить заголовок таблицы")
            return []
        }

        return headerRow.arrangedSubviews.map { cell in
            let labels = cell.subviews.compactMap { $0 as? UILabel }
            return labels.first?.text ?? ""
        }
    }
}
