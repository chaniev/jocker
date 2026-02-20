//
//  GamePlayersSettingsStoreTests.swift
//  JockerTests
//
//  Created by Codex on 20.02.2026.
//

import XCTest
@testable import Jocker

final class GamePlayersSettingsStoreTests: XCTestCase {
    func testLoadSettings_returnsDefaultWhenStorageIsEmpty() {
        let (store, userDefaults, suiteName) = makeStore()
        defer { clear(userDefaults: userDefaults, suiteName: suiteName) }

        let settings = store.loadSettings()

        XCTAssertEqual(
            settings.playerNames,
            ["Игрок 1", "Игрок 2", "Игрок 3", "Игрок 4"]
        )
        XCTAssertEqual(settings.botDifficulties, [.hard, .hard, .hard, .hard])
    }

    func testSaveSettings_persistsNamesAndBotDifficulties() {
        let (store, userDefaults, suiteName) = makeStore()
        defer { clear(userDefaults: userDefaults, suiteName: suiteName) }

        let savedSettings = GamePlayersSettings(
            playerNames: ["  ", "Бот А", "Бот Б", "Бот В"],
            botDifficulties: [.easy, .easy, .normal, .hard]
        )

        store.saveSettings(savedSettings)
        let loaded = store.loadSettings()

        XCTAssertEqual(loaded.playerNames[0], "Игрок 1")
        XCTAssertEqual(loaded.playerNames[1], "Бот А")
        XCTAssertEqual(loaded.playerNames[2], "Бот Б")
        XCTAssertEqual(loaded.playerNames[3], "Бот В")

        // Сложность первого слота не используется и всегда нормализуется в hard.
        XCTAssertEqual(loaded.botDifficulties, [.hard, .easy, .normal, .hard])
    }

    func testActivePlayerSlices_useConfiguredOrderForSelectedPlayerCount() {
        let settings = GamePlayersSettings(
            playerNames: ["Человек", "Бот 2", "Бот 3", "Бот 4"],
            botDifficulties: [.hard, .easy, .normal, .hard]
        )

        XCTAssertEqual(settings.activePlayerNames(playerCount: 3), ["Человек", "Бот 2", "Бот 3"])
        XCTAssertEqual(settings.activeBotDifficulties(playerCount: 3), [.hard, .easy, .normal])
    }

    private func makeStore() -> (GamePlayersSettingsStore, UserDefaults, String) {
        let suiteName = "GamePlayersSettingsStoreTests.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Failed to create UserDefaults suite: \(suiteName)")
        }
        clear(userDefaults: userDefaults, suiteName: suiteName)
        return (GamePlayersSettingsStore(userDefaults: userDefaults), userDefaults, suiteName)
    }

    private func clear(userDefaults: UserDefaults, suiteName: String) {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults.synchronize()
    }
}
