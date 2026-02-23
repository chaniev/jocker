//
//  BotOpponentModel.swift
//  Jocker
//
//  Created by Codex on 23.02.2026.
//

import Foundation

/// MVP-снимок наблюдаемых паттернов соперников внутри текущего блока.
/// Этап 6a: feature-plumbing без изменения поведения AI.
struct BotOpponentModel: Equatable {
    struct OpponentSnapshot: Equatable {
        let playerIndex: Int
        let observedRounds: Int
        let blindBidRate: Double
        let exactBidRate: Double
        let overbidRate: Double
        let underbidRate: Double
        let averageBidAggression: Double

        var hasEvidence: Bool {
            return observedRounds > 0
        }
    }

    let perspectivePlayerIndex: Int
    let leftNeighborIndex: Int?
    let snapshots: [OpponentSnapshot]

    func snapshot(for playerIndex: Int) -> OpponentSnapshot? {
        return snapshots.first(where: { $0.playerIndex == playerIndex })
    }
}
