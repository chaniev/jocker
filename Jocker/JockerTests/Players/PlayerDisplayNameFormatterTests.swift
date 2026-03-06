//
//  PlayerDisplayNameFormatterTests.swift
//  JockerTests
//
//  Created by Codex on 06.03.2026.
//

import XCTest
@testable import Jocker

final class PlayerDisplayNameFormatterTests: XCTestCase {
    func testDisplayName_trimsInputAndFallsBackForMissingPlayer() {
        let playerNames = ["  Анна  ", "", "Борис"]

        XCTAssertEqual(
            PlayerDisplayNameFormatter.displayName(for: 0, in: playerNames),
            "Анна"
        )
        XCTAssertEqual(
            PlayerDisplayNameFormatter.displayName(for: 1, in: playerNames),
            "Игрок 2"
        )
        XCTAssertEqual(
            PlayerDisplayNameFormatter.displayName(for: 3, in: playerNames),
            "Игрок 4"
        )
    }

    func testNormalizedNames_fillsMissingSlotsWithDefaultNames() {
        let normalized = PlayerDisplayNameFormatter.normalizedNames(
            ["Игрок 1", "   ", "Бот Север"],
            playerCount: 4
        )

        XCTAssertEqual(
            normalized,
            ["Игрок 1", "Игрок 2", "Бот Север", "Игрок 4"]
        )
    }
}
