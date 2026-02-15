//
//  GameStatisticsScope.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

enum GameStatisticsScope: String, CaseIterable, Codable {
    case allGames
    case fourPlayers
    case threePlayers

    var title: String {
        switch self {
        case .allGames:
            return "Все игры"
        case .fourPlayers:
            return "4 игрока"
        case .threePlayers:
            return "3 игрока"
        }
    }

    var visiblePlayerCount: Int {
        switch self {
        case .threePlayers:
            return 3
        case .allGames, .fourPlayers:
            return 4
        }
    }
}
