//
//  UserDefaultsGameStatisticsStore.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

final class UserDefaultsGameStatisticsStore: GameStatisticsStore {
    private struct StorageKey {
        static let snapshot = "Jocker.GameStatisticsSnapshot.v1"
        static let playerSlots = 4
    }

    private struct PerGamePlayerStats {
        let place: Int
        let totalScore: Double
        let premiumsByBlock: [Int]
        let blindBidCount: Int
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
        guard let rawData = userDefaults.data(forKey: StorageKey.snapshot) else {
            return GameStatisticsSnapshot.empty(playerSlots: StorageKey.playerSlots)
        }

        guard let decodedSnapshot = try? decoder.decode(GameStatisticsSnapshot.self, from: rawData) else {
            return GameStatisticsSnapshot.empty(playerSlots: StorageKey.playerSlots)
        }

        return decodedSnapshot.normalized(playerSlots: StorageKey.playerSlots)
    }

    func recordCompletedGame(
        playerCount: Int,
        playerSummaries: [GameFinalPlayerSummary],
        completedBlocks: [BlockResult]
    ) {
        guard playerCount > 0 else { return }
        guard !playerSummaries.isEmpty else { return }

        let perGameStats = mapPerGameStats(
            playerCount: playerCount,
            playerSummaries: playerSummaries,
            completedBlocks: completedBlocks
        )

        var snapshot = loadSnapshot().normalized(playerSlots: StorageKey.playerSlots)

        updateSnapshot(
            scope: .allGames,
            playerCount: playerCount,
            perGameStats: perGameStats,
            snapshot: &snapshot
        )

        if playerCount == 3 {
            updateSnapshot(
                scope: .threePlayers,
                playerCount: playerCount,
                perGameStats: perGameStats,
                snapshot: &snapshot
            )
        } else if playerCount == 4 {
            updateSnapshot(
                scope: .fourPlayers,
                playerCount: playerCount,
                perGameStats: perGameStats,
                snapshot: &snapshot
            )
        }

        persist(snapshot)
    }

    private func mapPerGameStats(
        playerCount: Int,
        playerSummaries: [GameFinalPlayerSummary],
        completedBlocks: [BlockResult]
    ) -> [Int: PerGamePlayerStats] {
        let summaryByPlayerIndex = Dictionary(
            uniqueKeysWithValues: playerSummaries.map { ($0.playerIndex, $0) }
        )

        var statsByPlayerIndex: [Int: PerGamePlayerStats] = [:]
        statsByPlayerIndex.reserveCapacity(playerCount)

        for playerIndex in 0..<playerCount {
            guard let summary = summaryByPlayerIndex[playerIndex] else { continue }

            let premiumsByBlock = (0..<GameConstants.totalBlocks).map { blockIndex in
                guard completedBlocks.indices.contains(blockIndex) else { return 0 }
                let block = completedBlocks[blockIndex]
                let hasPremium = block.premiumPlayerIndices.contains(playerIndex) ||
                    block.zeroPremiumPlayerIndices.contains(playerIndex)
                return hasPremium ? 1 : 0
            }

            let blindBidCount = completedBlocks.reduce(0) { partial, block in
                guard block.roundResults.indices.contains(playerIndex) else { return partial }
                return partial + block.roundResults[playerIndex].filter(\.isBlind).count
            }

            statsByPlayerIndex[playerIndex] = PerGamePlayerStats(
                place: summary.place,
                totalScore: normalizedStoredScore(from: summary.totalScore),
                premiumsByBlock: premiumsByBlock,
                blindBidCount: blindBidCount
            )
        }

        return statsByPlayerIndex
    }

    private func updateSnapshot(
        scope: GameStatisticsScope,
        playerCount: Int,
        perGameStats: [Int: PerGamePlayerStats],
        snapshot: inout GameStatisticsSnapshot
    ) {
        var scopeRecords = snapshot.records(for: scope)
        ensureRecordsCapacity(&scopeRecords)

        for playerIndex in 0..<playerCount {
            guard let gameStats = perGameStats[playerIndex] else { continue }
            var record = scopeRecords[playerIndex]

            record.gamesPlayed += 1
            incrementPlaceCounter(place: gameStats.place, playerCount: playerCount, record: &record)

            for blockIndex in 0..<GameConstants.totalBlocks {
                let premiumValue = gameStats.premiumsByBlock.indices.contains(blockIndex)
                    ? gameStats.premiumsByBlock[blockIndex]
                    : 0
                record.premiumsByBlock[blockIndex] += premiumValue
            }

            record.blindBidCount += gameStats.blindBidCount
            let normalizedScore = normalizedStoredScore(from: gameStats.totalScore)
            record.maxTotalScore = max(record.maxTotalScore ?? normalizedScore, normalizedScore)
            record.minTotalScore = min(record.minTotalScore ?? normalizedScore, normalizedScore)

            scopeRecords[playerIndex] = record
        }

        snapshot.setRecords(scopeRecords, for: scope)
    }

    private func incrementPlaceCounter(
        place: Int,
        playerCount: Int,
        record: inout GameStatisticsPlayerRecord
    ) {
        switch place {
        case 1:
            record.firstPlaceCount += 1
        case 2:
            record.secondPlaceCount += 1
        case 3:
            record.thirdPlaceCount += 1
        case 4 where playerCount >= 4:
            record.fourthPlaceCount += 1
        default:
            break
        }
    }

    private func ensureRecordsCapacity(_ records: inout [GameStatisticsPlayerRecord]) {
        var recordsByPlayer = Dictionary(uniqueKeysWithValues: records.map { ($0.playerIndex, $0.normalized()) })

        for playerIndex in 0..<StorageKey.playerSlots {
            if recordsByPlayer[playerIndex] == nil {
                recordsByPlayer[playerIndex] = GameStatisticsPlayerRecord.empty(playerIndex: playerIndex)
            }
        }

        records = recordsByPlayer
            .values
            .sorted { $0.playerIndex < $1.playerIndex }
    }

    private func persist(_ snapshot: GameStatisticsSnapshot) {
        let normalizedSnapshot = snapshot.normalized(playerSlots: StorageKey.playerSlots)
        guard let encodedData = try? encoder.encode(normalizedSnapshot) else { return }
        userDefaults.set(encodedData, forKey: StorageKey.snapshot)
    }

    private func normalizedStoredScore(from rawTotalScore: Int) -> Double {
        return normalizedStoredScore(from: Double(rawTotalScore) / 100.0)
    }

    private func normalizedStoredScore(from value: Double) -> Double {
        return (value * 10).rounded() / 10
    }
}
