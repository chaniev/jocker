//
//  GameStatisticsSnapshot.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

struct GameStatisticsSnapshot: Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case allGamesRecords
        case fourPlayersRecords
        case threePlayersRecords
    }

    var allGamesRecords: [GameStatisticsPlayerRecord]
    var fourPlayersRecords: [GameStatisticsPlayerRecord]
    var threePlayersRecords: [GameStatisticsPlayerRecord]

    init(
        allGamesRecords: [GameStatisticsPlayerRecord],
        fourPlayersRecords: [GameStatisticsPlayerRecord],
        threePlayersRecords: [GameStatisticsPlayerRecord]
    ) {
        self.allGamesRecords = allGamesRecords
        self.fourPlayersRecords = fourPlayersRecords
        self.threePlayersRecords = threePlayersRecords
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        allGamesRecords = try container.decodeIfPresent([GameStatisticsPlayerRecord].self, forKey: .allGamesRecords) ?? []
        fourPlayersRecords = try container.decodeIfPresent([GameStatisticsPlayerRecord].self, forKey: .fourPlayersRecords) ?? []
        threePlayersRecords = try container.decodeIfPresent([GameStatisticsPlayerRecord].self, forKey: .threePlayersRecords) ?? []
    }

    static func empty(playerSlots: Int = 4) -> GameStatisticsSnapshot {
        let records = (0..<max(1, playerSlots)).map(GameStatisticsPlayerRecord.empty)
        return GameStatisticsSnapshot(
            allGamesRecords: records,
            fourPlayersRecords: records,
            threePlayersRecords: records
        )
    }

    func records(for scope: GameStatisticsScope) -> [GameStatisticsPlayerRecord] {
        switch scope {
        case .allGames:
            return allGamesRecords
        case .fourPlayers:
            return fourPlayersRecords
        case .threePlayers:
            return threePlayersRecords
        }
    }

    mutating func setRecords(_ records: [GameStatisticsPlayerRecord], for scope: GameStatisticsScope) {
        switch scope {
        case .allGames:
            allGamesRecords = records
        case .fourPlayers:
            fourPlayersRecords = records
        case .threePlayers:
            threePlayersRecords = records
        }
    }

    func normalized(playerSlots: Int = 4) -> GameStatisticsSnapshot {
        let normalizedSlots = max(1, playerSlots)

        return GameStatisticsSnapshot(
            allGamesRecords: normalize(records: allGamesRecords, playerSlots: normalizedSlots),
            fourPlayersRecords: normalize(records: fourPlayersRecords, playerSlots: normalizedSlots),
            threePlayersRecords: normalize(records: threePlayersRecords, playerSlots: normalizedSlots)
        )
    }

    private func normalize(
        records: [GameStatisticsPlayerRecord],
        playerSlots: Int
    ) -> [GameStatisticsPlayerRecord] {
        var normalizedRecords: [Int: GameStatisticsPlayerRecord] = [:]
        for record in records {
            normalizedRecords[record.playerIndex] = record.normalized()
        }

        for playerIndex in 0..<playerSlots {
            if normalizedRecords[playerIndex] == nil {
                normalizedRecords[playerIndex] = GameStatisticsPlayerRecord.empty(playerIndex: playerIndex)
            }
        }

        return normalizedRecords
            .values
            .sorted { $0.playerIndex < $1.playerIndex }
    }
}
