//
//  UserDefaultsGameStatisticsStore.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

final class UserDefaultsGameStatisticsStore: GameStatisticsStore {
    private struct StorageKey {
        static let snapshot = "Jocker.GameStatisticsSnapshot.v2"
        static let legacySnapshot = "Jocker.GameStatisticsSnapshot.v1"
        static let playerSlots = 4
    }

    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    func loadSnapshot() -> GameStatisticsSnapshot {
        if let rawData = userDefaults.data(forKey: StorageKey.snapshot),
           let decodedSnapshot = try? decoder.decode(GameStatisticsSnapshot.self, from: rawData) {
            return decodedSnapshot.normalized(playerSlots: StorageKey.playerSlots)
        }

        if let rawData = userDefaults.data(forKey: StorageKey.legacySnapshot),
           let decodedSnapshot = try? decoder.decode(GameStatisticsSnapshot.self, from: rawData) {
            return decodedSnapshot.normalized(playerSlots: StorageKey.playerSlots)
        }

        return GameStatisticsSnapshot.empty(playerSlots: StorageKey.playerSlots)
    }

    func recordCompletedGame(
        playerCount: Int,
        gameMode: GameMode,
        playerSummaries: [GameFinalPlayerSummary],
        completedBlocks: [BlockResult]
    ) {
        let snapshot = GameStatisticsAccumulator().applying(to: self.loadSnapshot(), playerCount: playerCount,
            gameMode: gameMode, playerSummaries: playerSummaries, completedBlocks: completedBlocks)
        self.persist(snapshot)
    }

    private func persist(_ snapshot: GameStatisticsSnapshot) {
        let normalizedSnapshot = snapshot.normalized(playerSlots: StorageKey.playerSlots)
        guard let encodedData = try? encoder.encode(normalizedSnapshot) else { return }
        userDefaults.set(encodedData, forKey: StorageKey.snapshot)
    }

}
