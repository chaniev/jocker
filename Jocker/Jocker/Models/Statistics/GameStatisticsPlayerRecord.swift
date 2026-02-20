//
//  GameStatisticsPlayerRecord.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

struct GameStatisticsPlayerRecord: Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case playerIndex
        case gamesPlayed
        case firstPlaceCount
        case secondPlaceCount
        case thirdPlaceCount
        case fourthPlaceCount
        case premiumsByBlock
        case blindBidCount
        case maxTotalScore
        case minTotalScore
    }

    let playerIndex: Int
    var gamesPlayed: Int
    var firstPlaceCount: Int
    var secondPlaceCount: Int
    var thirdPlaceCount: Int
    var fourthPlaceCount: Int
    var premiumsByBlock: [Int]
    var blindBidCount: Int
    var maxTotalScore: Double?
    var minTotalScore: Double?

    init(
        playerIndex: Int,
        gamesPlayed: Int,
        firstPlaceCount: Int,
        secondPlaceCount: Int,
        thirdPlaceCount: Int,
        fourthPlaceCount: Int,
        premiumsByBlock: [Int],
        blindBidCount: Int,
        maxTotalScore: Double?,
        minTotalScore: Double?
    ) {
        self.playerIndex = playerIndex
        self.gamesPlayed = gamesPlayed
        self.firstPlaceCount = firstPlaceCount
        self.secondPlaceCount = secondPlaceCount
        self.thirdPlaceCount = thirdPlaceCount
        self.fourthPlaceCount = fourthPlaceCount
        self.premiumsByBlock = GameStatisticsPlayerRecord.normalizedPremiums(premiumsByBlock)
        self.blindBidCount = blindBidCount
        self.maxTotalScore = maxTotalScore.map(Self.normalizedScoreValue)
        self.minTotalScore = minTotalScore.map(Self.normalizedScoreValue)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        playerIndex = try container.decode(Int.self, forKey: .playerIndex)
        gamesPlayed = try container.decodeIfPresent(Int.self, forKey: .gamesPlayed) ?? 0
        firstPlaceCount = try container.decodeIfPresent(Int.self, forKey: .firstPlaceCount) ?? 0
        secondPlaceCount = try container.decodeIfPresent(Int.self, forKey: .secondPlaceCount) ?? 0
        thirdPlaceCount = try container.decodeIfPresent(Int.self, forKey: .thirdPlaceCount) ?? 0
        fourthPlaceCount = try container.decodeIfPresent(Int.self, forKey: .fourthPlaceCount) ?? 0
        let decodedPremiums = try container.decodeIfPresent([Int].self, forKey: .premiumsByBlock) ?? []
        premiumsByBlock = GameStatisticsPlayerRecord.normalizedPremiums(decodedPremiums)
        blindBidCount = try container.decodeIfPresent(Int.self, forKey: .blindBidCount) ?? 0
        maxTotalScore = try container.decodeIfPresent(Double.self, forKey: .maxTotalScore).map(Self.normalizedScoreValue)
        minTotalScore = try container.decodeIfPresent(Double.self, forKey: .minTotalScore).map(Self.normalizedScoreValue)
    }

    static func empty(playerIndex: Int) -> GameStatisticsPlayerRecord {
        return GameStatisticsPlayerRecord(
            playerIndex: playerIndex,
            gamesPlayed: 0,
            firstPlaceCount: 0,
            secondPlaceCount: 0,
            thirdPlaceCount: 0,
            fourthPlaceCount: 0,
            premiumsByBlock: Array(repeating: 0, count: GameConstants.totalBlocks),
            blindBidCount: 0,
            maxTotalScore: nil,
            minTotalScore: nil
        )
    }

    func normalized() -> GameStatisticsPlayerRecord {
        var copy = self
        copy.premiumsByBlock = Self.normalizedPremiums(premiumsByBlock)
        return copy
    }

    private static func normalizedPremiums(_ premiums: [Int]) -> [Int] {
        if premiums.count == GameConstants.totalBlocks {
            return premiums
        }

        var normalized = Array(premiums.prefix(GameConstants.totalBlocks))
        if normalized.count < GameConstants.totalBlocks {
            normalized.append(contentsOf: Array(repeating: 0, count: GameConstants.totalBlocks - normalized.count))
        }
        return normalized
    }

    private static func normalizedScoreValue(_ value: Double) -> Double {
        return (value * 10).rounded() / 10
    }
}
