//
//  GamePlayersSettings.swift
//  Jocker
//
//  Created by Codex on 20.02.2026.
//

import Foundation

struct GamePlayersSettings: Codable, Equatable {
    static let supportedPlayerSlots = 4

    var playerNames: [String]
    var botDifficulties: [BotDifficulty]

    init(playerNames: [String], botDifficulties: [BotDifficulty]) {
        self.playerNames = Self.normalizedNames(playerNames)
        self.botDifficulties = Self.normalizedBotDifficulties(botDifficulties)
    }

    static var `default`: GamePlayersSettings {
        return GamePlayersSettings(
            playerNames: (0..<supportedPlayerSlots).map { "Игрок \($0 + 1)" },
            botDifficulties: Array(repeating: .hard, count: supportedPlayerSlots)
        )
    }

    func activePlayerNames(playerCount: Int) -> [String] {
        let safeCount = min(max(playerCount, 0), Self.supportedPlayerSlots)
        return Array(playerNames.prefix(safeCount))
    }

    func activeBotDifficulties(playerCount: Int) -> [BotDifficulty] {
        let safeCount = min(max(playerCount, 0), Self.supportedPlayerSlots)
        return Array(botDifficulties.prefix(safeCount))
    }

    func displayName(for playerIndex: Int) -> String {
        guard playerNames.indices.contains(playerIndex) else {
            return "Игрок \(playerIndex + 1)"
        }

        let trimmed = playerNames[playerIndex].trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Игрок \(playerIndex + 1)" : trimmed
    }

    private static func normalizedNames(_ names: [String]) -> [String] {
        var normalized = names
            .prefix(supportedPlayerSlots)
            .enumerated()
            .map { index, name in
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? "Игрок \(index + 1)" : trimmed
            }

        if normalized.count < supportedPlayerSlots {
            for index in normalized.count..<supportedPlayerSlots {
                normalized.append("Игрок \(index + 1)")
            }
        }

        return normalized
    }

    private static func normalizedBotDifficulties(_ difficulties: [BotDifficulty]) -> [BotDifficulty] {
        var normalized = Array(difficulties.prefix(supportedPlayerSlots))

        if normalized.count < supportedPlayerSlots {
            normalized.append(contentsOf: Array(repeating: .hard, count: supportedPlayerSlots - normalized.count))
        }

        if !normalized.isEmpty {
            normalized[0] = .hard
        }

        return normalized
    }
}
