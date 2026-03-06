//
//  PlayerStatisticsModelsTests.swift
//  JockerTests
//
//  Created by Codex on 06.03.2026.
//

import XCTest
@testable import Jocker

final class PlayerStatisticsModelsTests: XCTestCase {
    func testGamePlayersSettings_initialization_normalizesNamesAndDifficulties() {
        let settings = GamePlayersSettings(
            playerNames: ["  Анна  ", "", "Борис", "  "],
            botDifficulties: [.easy, .normal, .hard, .easy]
        )

        XCTAssertEqual(settings.playerNames, ["Анна", "Игрок 2", "Борис", "Игрок 4"])
        XCTAssertEqual(settings.botDifficulties, [.hard, .normal, .hard, .easy])
        XCTAssertEqual(settings.displayName(for: 0), "Анна")
        XCTAssertEqual(settings.displayName(for: 99), "Игрок 100")
    }

    func testGamePlayersSettings_activeAccessors_clampToPlayerCount() {
        let settings = GamePlayersSettings.default

        XCTAssertEqual(settings.activePlayerNames(playerCount: 3).count, 3)
        XCTAssertEqual(settings.activeBotDifficulties(playerCount: 3).count, 3)
        XCTAssertEqual(settings.activePlayerNames(playerCount: 99).count, GamePlayersSettings.supportedPlayerSlots)
    }

    func testPlayerControlType_supportsHumanAndBotValues() {
        let values: [PlayerControlType] = [.human, .bot]

        XCTAssertEqual(values.count, 2)
    }

    func testPlayerInfo_initialization_storesValues() {
        let player = PlayerInfo(playerNumber: 2, name: "Игрок 2")

        XCTAssertEqual(player.playerNumber, 2)
        XCTAssertEqual(player.name, "Игрок 2")
        XCTAssertEqual(player.currentBid, 0)
    }

    func testPlayerInfo_resetForNewRound_resetsRoundFields() {
        var player = PlayerInfo(playerNumber: 1, name: "Игрок 1")
        player.currentBid = 3
        player.tricksTaken = 2
        player.isBlindBid = true
        player.isBidLockedBeforeDeal = true

        player.resetForNewRound()

        XCTAssertEqual(player.currentBid, 0)
        XCTAssertEqual(player.tricksTaken, 0)
        XCTAssertFalse(player.isBlindBid)
        XCTAssertFalse(player.isBidLockedBeforeDeal)
    }

    func testGameFinalPlayerSummary_build_assignsPlacesAndAggregatesValues() {
        let summaries = GameFinalPlayerSummary.build(
            playerNames: ["A", "B", "C", "D"],
            playerCount: 4,
            completedBlocks: [
                blockResult(
                    finalScores: [120, 90, 70, 40],
                    premiumPlayerIndices: [0],
                    zeroPremiumPlayerIndices: []
                ),
                blockResult(
                    finalScores: [0, 10, 20, 30],
                    premiumPlayerIndices: [],
                    zeroPremiumPlayerIndices: [2]
                )
            ]
        )

        XCTAssertEqual(summaries.map(\.playerName), ["A", "B", "C", "D"])
        XCTAssertEqual(summaries.map(\.place), [1, 2, 3, 4])
        XCTAssertEqual(summaries[0].totalScore, 120)
        XCTAssertEqual(summaries[2].totalPremiumsTaken, 1)
    }

    func testGameStatisticsPlayerRecord_initialization_normalizesPremiumsAndScores() {
        let record = GameStatisticsPlayerRecord(
            playerIndex: 0,
            gamesPlayed: 10,
            firstPlaceCount: 4,
            secondPlaceCount: 3,
            thirdPlaceCount: 2,
            fourthPlaceCount: 1,
            premiumsByBlock: [1, 2],
            blindBidCount: 5,
            maxTotalScore: 123.456,
            minTotalScore: 12.345
        )

        XCTAssertEqual(record.premiumsByBlock.count, GameConstants.totalBlocks)
        XCTAssertEqual(record.premiumsByBlock, [1, 2, 0, 0])
        XCTAssertEqual(record.maxTotalScore, 123.5)
        XCTAssertEqual(record.minTotalScore, 12.3)
    }

    func testGameStatisticsScope_allCases_andVisiblePlayerCount_areConsistent() {
        XCTAssertEqual(GameStatisticsScope.allCases.count, 3)
        XCTAssertEqual(GameStatisticsScope.allGames.visiblePlayerCount, 4)
        XCTAssertEqual(GameStatisticsScope.fourPlayers.visiblePlayerCount, 4)
        XCTAssertEqual(GameStatisticsScope.threePlayers.visiblePlayerCount, 3)
    }

    func testGameStatisticsSnapshot_initialization_andNormalization_fillMissingPlayerSlots() {
        var snapshot = GameStatisticsSnapshot(
            allGamesRecords: [GameStatisticsPlayerRecord.empty(playerIndex: 1)],
            fourPlayersRecords: [],
            threePlayersRecords: []
        )
        snapshot.setRecords([GameStatisticsPlayerRecord.empty(playerIndex: 2)], for: .threePlayers)

        let normalized = snapshot.normalized(playerSlots: 4)

        XCTAssertEqual(normalized.records(for: .allGames).count, 4)
        XCTAssertEqual(normalized.records(for: .threePlayers).count, 4)
        XCTAssertEqual(normalized.records(for: .allGames).map(\.playerIndex), [0, 1, 2, 3])
        XCTAssertEqual(normalized.records(for: .threePlayers)[2].playerIndex, 2)
    }

    private func blockResult(
        finalScores: [Int],
        premiumPlayerIndices: [Int],
        zeroPremiumPlayerIndices: [Int]
    ) -> BlockResult {
        let playerCount = finalScores.count
        return BlockResult(
            roundResults: Array(repeating: [], count: playerCount),
            baseScores: finalScores,
            premiumPlayerIndices: premiumPlayerIndices,
            premiumBonuses: Array(repeating: 0, count: playerCount),
            premiumPenalties: Array(repeating: 0, count: playerCount),
            zeroPremiumPlayerIndices: zeroPremiumPlayerIndices,
            zeroPremiumBonuses: Array(repeating: 0, count: playerCount),
            finalScores: finalScores
        )
    }
}
