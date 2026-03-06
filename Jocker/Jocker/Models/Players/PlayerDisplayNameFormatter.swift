//
//  PlayerDisplayNameFormatter.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

enum PlayerDisplayNameFormatter {
    static func fallbackName(for playerIndex: Int) -> String {
        return "Игрок \(playerIndex + 1)"
    }

    static func normalizedName(
        _ rawName: String?,
        playerIndex: Int
    ) -> String {
        let trimmedName = rawName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedName.isEmpty ? fallbackName(for: playerIndex) : trimmedName
    }

    static func displayName(
        for playerIndex: Int,
        in playerNames: [String]
    ) -> String {
        guard playerNames.indices.contains(playerIndex) else {
            return fallbackName(for: playerIndex)
        }

        return normalizedName(playerNames[playerIndex], playerIndex: playerIndex)
    }

    static func normalizedNames(
        _ playerNames: [String],
        playerCount: Int
    ) -> [String] {
        let safeCount = max(playerCount, 0)
        return (0..<safeCount).map { playerIndex in
            displayName(for: playerIndex, in: playerNames)
        }
    }
}
