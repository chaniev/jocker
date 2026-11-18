import Foundation

struct GameStatisticsAccumulator {
    private enum StorageKey { static let playerSlots = 4 }
    private struct PerGamePlayerStats {
        let place: Int
        let totalScore: Double
        let premiumsByBlock: [Int]
        let blindBidCount: Int
    }

    func applying(to initial: GameStatisticsSnapshot, playerCount: Int, gameMode: GameMode,
                  playerSummaries: [GameFinalPlayerSummary], completedBlocks: [BlockResult]) -> GameStatisticsSnapshot {
        guard playerCount > 0 else { return initial }
        guard !playerSummaries.isEmpty else { return initial }

        let perGameStats = self.mapPerGameStats(
            playerCount: playerCount,
            playerSummaries: playerSummaries,
            completedBlocks: completedBlocks
        )

        var snapshot = initial.normalized(playerSlots: StorageKey.playerSlots)

        self.updateSnapshot(
            scope: .allGames,
            playerCount: playerCount,
            perGameStats: perGameStats,
            snapshot: &snapshot
        )

        if playerCount == 3 {
            self.updateSnapshot(
                scope: .threePlayers,
                playerCount: playerCount,
                perGameStats: perGameStats,
                snapshot: &snapshot
            )
        } else if playerCount == 4 {
            let scope: GameStatisticsScope = gameMode == .pairs ? .fourPlayersPairs : .fourPlayers
            self.updateSnapshot(
                scope: scope,
                playerCount: playerCount,
                perGameStats: perGameStats,
                snapshot: &snapshot
            )
        }

        return snapshot
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
                totalScore: self.normalizedStoredScore(from: summary.totalScore),
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
        self.ensureRecordsCapacity(&scopeRecords)

        for playerIndex in 0..<playerCount {
            guard let gameStats = perGameStats[playerIndex] else { continue }
            var record = scopeRecords[playerIndex]

            record.gamesPlayed += 1
            self.incrementPlaceCounter(place: gameStats.place, playerCount: playerCount, record: &record)

            for blockIndex in 0..<GameConstants.totalBlocks {
                let premiumValue = gameStats.premiumsByBlock.indices.contains(blockIndex)
                    ? gameStats.premiumsByBlock[blockIndex]
                    : 0
                record.premiumsByBlock[blockIndex] += premiumValue
            }

            record.blindBidCount += gameStats.blindBidCount
            let normalizedScore = self.normalizedStoredScore(from: gameStats.totalScore)
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

    private func normalizedStoredScore(from rawTotalScore: Int) -> Double {
        return self.normalizedStoredScore(from: Double(rawTotalScore) / 100.0)
    }

    private func normalizedStoredScore(from value: Double) -> Double {
        return (value * 10).rounded() / 10
    }
}
