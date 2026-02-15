//
//  PlayerInfo.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import Foundation

/// Информация об игроке (value type)
struct PlayerInfo {
    let playerNumber: Int
    var name: String
    var score: Int = 0
    var currentBid: Int = 0
    var tricksTaken: Int = 0
    var isBlindBid: Bool = false
    var isBidLockedBeforeDeal: Bool = false
    
    init(playerNumber: Int, name: String) {
        self.playerNumber = playerNumber
        self.name = name
    }
    
    /// Сброс для нового раунда
    mutating func resetForNewRound() {
        currentBid = 0
        tricksTaken = 0
        isBlindBid = false
        isBidLockedBeforeDeal = false
    }
}
