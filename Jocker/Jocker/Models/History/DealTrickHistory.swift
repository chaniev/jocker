//
//  DealTrickHistory.swift
//  Jocker
//
//  Created by Codex on 19.02.2026.
//

import Foundation

/// Полная информация об одной взятке.
struct DealTrickHistory: Equatable {
    let moves: [DealTrickMove]
    let winnerPlayerIndex: Int
}
