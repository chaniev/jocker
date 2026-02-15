//
//  GameStatisticsStoreTests.swift
//  JockerTests
//
//  Created by Codex on 15.02.2026.
//

import Foundation
import XCTest
@testable import Jocker

final class GameStatisticsStoreTests: XCTestCase {
    func testRecordCompletedGame_updatesAllAndThreePlayerScopes() {
        let (store, userDefaults, suiteName) = makeStore()
        defer { clear(userDefaults: userDefaults, suiteName: suiteName) }

        let summaries = [
            makeSummary(playerIndex: 0, place: 2, totalScore: 120),
            makeSummary(playerIndex: 1, place: 1, totalScore: 150),
            makeSummary(playerIndex: 2, place: 3, totalScore: 90)
        ]

        let blocks = [
            makeBlock(
                playerCount: 3,
                premiumPlayerIndices: [1],
                blindBidMap: [
                    [false],
                    [false],
                    [false]
                ]
            ),
            makeBlock(
                playerCount: 3,
                premiumPlayerIndices: [0],
                blindBidMap: [
                    [true, false],
                    [false, false],
                    [false, false]
                ]
            ),
            makeBlock(
                playerCount: 3,
                zeroPremiumPlayerIndices: [2],
                blindBidMap: [
                    [false],
                    [false],
                    [true]
                ]
            ),
            makeBlock(
                playerCount: 3,
                premiumPlayerIndices: [0],
                blindBidMap: [
                    [true, true],
                    [false, true],
                    [false, false]
                ]
            )
        ]

        store.recordCompletedGame(
            playerCount: 3,
            playerSummaries: summaries,
            completedBlocks: blocks
        )

        let snapshot = store.loadSnapshot()
        let allRecords = snapshot.records(for: .allGames)
        let threePlayersRecords = snapshot.records(for: .threePlayers)
        let fourPlayersRecords = snapshot.records(for: .fourPlayers)

        XCTAssertEqual(allRecords.count, 4)
        XCTAssertEqual(threePlayersRecords.count, 4)
        XCTAssertEqual(fourPlayersRecords.count, 4)

        XCTAssertEqual(allRecords[0].gamesPlayed, 1)
        XCTAssertEqual(allRecords[0].firstPlaceCount, 0)
        XCTAssertEqual(allRecords[0].secondPlaceCount, 1)
        XCTAssertEqual(allRecords[0].thirdPlaceCount, 0)
        XCTAssertEqual(allRecords[0].fourthPlaceCount, 0)
        XCTAssertEqual(allRecords[0].premiumsByBlock, [0, 1, 0, 1])
        XCTAssertEqual(allRecords[0].blindBidCount, 3)
        XCTAssertEqual(allRecords[0].maxTotalScore, 1.2)
        XCTAssertEqual(allRecords[0].minTotalScore, 1.2)

        XCTAssertEqual(threePlayersRecords[1].gamesPlayed, 1)
        XCTAssertEqual(threePlayersRecords[1].firstPlaceCount, 1)
        XCTAssertEqual(threePlayersRecords[1].premiumsByBlock, [1, 0, 0, 0])

        XCTAssertEqual(threePlayersRecords[2].gamesPlayed, 1)
        XCTAssertEqual(threePlayersRecords[2].thirdPlaceCount, 1)
        XCTAssertEqual(threePlayersRecords[2].premiumsByBlock, [0, 0, 1, 0])
        XCTAssertEqual(threePlayersRecords[2].blindBidCount, 1)

        XCTAssertEqual(threePlayersRecords[0].fourthPlaceCount, 0)
        XCTAssertEqual(allRecords[3].gamesPlayed, 0)
        XCTAssertNil(allRecords[3].maxTotalScore)
        XCTAssertNil(allRecords[3].minTotalScore)

        XCTAssertEqual(fourPlayersRecords[0].gamesPlayed, 0)
        XCTAssertNil(fourPlayersRecords[0].maxTotalScore)
        XCTAssertNil(fourPlayersRecords[0].minTotalScore)
    }

    func testRecordCompletedGame_updatesMaxMinAcrossMultipleFourPlayerGames() {
        let (store, userDefaults, suiteName) = makeStore()
        defer { clear(userDefaults: userDefaults, suiteName: suiteName) }

        store.recordCompletedGame(
            playerCount: 4,
            playerSummaries: [
                makeSummary(playerIndex: 0, place: 1, totalScore: 200),
                makeSummary(playerIndex: 1, place: 2, totalScore: 110),
                makeSummary(playerIndex: 2, place: 3, totalScore: 80),
                makeSummary(playerIndex: 3, place: 4, totalScore: 20)
            ],
            completedBlocks: [
                makeBlock(playerCount: 4, premiumPlayerIndices: [0])
            ]
        )

        store.recordCompletedGame(
            playerCount: 4,
            playerSummaries: [
                makeSummary(playerIndex: 0, place: 4, totalScore: -40),
                makeSummary(playerIndex: 1, place: 1, totalScore: 240),
                makeSummary(playerIndex: 2, place: 2, totalScore: 50),
                makeSummary(playerIndex: 3, place: 3, totalScore: -10)
            ],
            completedBlocks: [
                makeBlock(playerCount: 4, premiumPlayerIndices: [1])
            ]
        )

        let snapshot = store.loadSnapshot()
        let allRecords = snapshot.records(for: .allGames)
        let fourPlayersRecords = snapshot.records(for: .fourPlayers)
        let threePlayersRecords = snapshot.records(for: .threePlayers)

        XCTAssertEqual(allRecords[0].gamesPlayed, 2)
        XCTAssertEqual(allRecords[0].firstPlaceCount, 1)
        XCTAssertEqual(allRecords[0].fourthPlaceCount, 1)
        XCTAssertEqual(allRecords[0].maxTotalScore, 2.0)
        XCTAssertEqual(allRecords[0].minTotalScore, -0.4)

        XCTAssertEqual(fourPlayersRecords[0].gamesPlayed, 2)
        XCTAssertEqual(fourPlayersRecords[0].maxTotalScore, 2.0)
        XCTAssertEqual(fourPlayersRecords[0].minTotalScore, -0.4)

        XCTAssertEqual(threePlayersRecords[0].gamesPlayed, 0)
        XCTAssertNil(threePlayersRecords[0].maxTotalScore)
        XCTAssertNil(threePlayersRecords[0].minTotalScore)
    }

    func testRecordCompletedGame_doesNotIncrementFourthPlaceForThreePlayers() {
        let (store, userDefaults, suiteName) = makeStore()
        defer { clear(userDefaults: userDefaults, suiteName: suiteName) }

        store.recordCompletedGame(
            playerCount: 3,
            playerSummaries: [
                makeSummary(playerIndex: 0, place: 1, totalScore: 100),
                makeSummary(playerIndex: 1, place: 2, totalScore: 90),
                makeSummary(playerIndex: 2, place: 4, totalScore: -20)
            ],
            completedBlocks: [
                makeBlock(playerCount: 3)
            ]
        )

        let snapshot = store.loadSnapshot()
        let allRecords = snapshot.records(for: .allGames)
        let threePlayersRecords = snapshot.records(for: .threePlayers)

        XCTAssertEqual(allRecords[2].fourthPlaceCount, 0)
        XCTAssertEqual(threePlayersRecords[2].fourthPlaceCount, 0)
    }

    private func makeStore() -> (UserDefaultsGameStatisticsStore, UserDefaults, String) {
        let suiteName = "GameStatisticsStoreTests.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Failed to create UserDefaults suite: \(suiteName)")
        }
        clear(userDefaults: userDefaults, suiteName: suiteName)
        let store = UserDefaultsGameStatisticsStore(userDefaults: userDefaults)
        return (store, userDefaults, suiteName)
    }

    private func clear(userDefaults: UserDefaults, suiteName: String) {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults.synchronize()
    }

    private func makeSummary(
        playerIndex: Int,
        place: Int,
        totalScore: Int
    ) -> GameFinalPlayerSummary {
        return GameFinalPlayerSummary(
            playerIndex: playerIndex,
            playerName: "Игрок \(playerIndex + 1)",
            place: place,
            totalScore: totalScore,
            blockScores: Array(repeating: 0, count: GameConstants.totalBlocks),
            premiumTakenByBlock: Array(repeating: false, count: GameConstants.totalBlocks),
            totalPremiumsTaken: 0,
            fourthBlockBlindCount: 0
        )
    }

    private func makeBlock(
        playerCount: Int,
        premiumPlayerIndices: [Int] = [],
        zeroPremiumPlayerIndices: [Int] = [],
        blindBidMap: [[Bool]] = []
    ) -> BlockResult {
        let roundResults: [[RoundResult]] = (0..<playerCount).map { playerIndex in
            guard blindBidMap.indices.contains(playerIndex) else { return [RoundResult]() }
            return blindBidMap[playerIndex].map { isBlind in
                RoundResult(cardsInRound: 1, bid: 0, tricksTaken: 0, isBlind: isBlind)
            }
        }

        return BlockResult(
            roundResults: roundResults,
            baseScores: Array(repeating: 0, count: playerCount),
            premiumPlayerIndices: premiumPlayerIndices,
            premiumBonuses: Array(repeating: 0, count: playerCount),
            premiumPenalties: Array(repeating: 0, count: playerCount),
            zeroPremiumPlayerIndices: zeroPremiumPlayerIndices,
            zeroPremiumBonuses: Array(repeating: 0, count: playerCount),
            finalScores: Array(repeating: 0, count: playerCount)
        )
    }
}
