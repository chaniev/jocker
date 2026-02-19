//
//  DealHistory.swift
//  Jocker
//
//  Created by Codex on 19.02.2026.
//

import Foundation

/// История одной раздачи.
struct DealHistory: Equatable {
    let key: DealHistoryKey
    let trump: Suit?
    let tricks: [DealTrickHistory]
}
