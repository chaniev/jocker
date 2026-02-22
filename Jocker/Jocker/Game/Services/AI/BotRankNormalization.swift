//
//  BotRankNormalization.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import Foundation

/// Централизованные преобразования ранга для bot AI.
/// Важно: разные режимы намеренно используют разные формулы.
enum BotRankNormalization {
    static func normalizedForBidding(_ rank: Rank) -> Double {
        let baseline = Rank.six.rawValue - 1
        let span = Rank.ace.rawValue - baseline
        return Double(rank.rawValue - baseline) / Double(max(1, span))
    }

    static func normalizedForFutureProjection(_ rank: Rank) -> Double {
        let span = Rank.ace.rawValue - Rank.six.rawValue
        return Double(rank.rawValue - Rank.six.rawValue) / Double(max(1, span))
    }

    static func normalizedForTrumpSelection(_ rank: Rank) -> Double {
        let span = Rank.ace.rawValue - Rank.six.rawValue
        return Double(rank.rawValue - Rank.six.rawValue) / Double(max(1, span))
    }

    static func isHighCard(_ rank: Rank) -> Bool {
        return rank.rawValue >= Rank.queen.rawValue
    }
}
