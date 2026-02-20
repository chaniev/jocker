//
//  GamePlayersSettingsStore.swift
//  Jocker
//
//  Created by Codex on 20.02.2026.
//

import Foundation

final class GamePlayersSettingsStore {
    private enum StorageKey {
        static let settings = "Jocker.GamePlayersSettings.v1"
    }

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadSettings() -> GamePlayersSettings {
        guard let data = userDefaults.data(forKey: StorageKey.settings) else {
            return .default
        }

        guard let decoded = try? decoder.decode(GamePlayersSettings.self, from: data) else {
            return .default
        }

        return decoded
    }

    func saveSettings(_ settings: GamePlayersSettings) {
        guard let data = try? encoder.encode(settings) else { return }
        userDefaults.set(data, forKey: StorageKey.settings)
    }
}
