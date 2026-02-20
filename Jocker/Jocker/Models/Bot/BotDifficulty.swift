//
//  BotDifficulty.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

/// Difficulty presets for bot behavior.
enum BotDifficulty: String, CaseIterable, Codable {
    case easy
    case normal
    case hard

    var settingsDisplayTitle: String {
        switch self {
        case .easy:
            return "И с двумя джокерами отнимусь"
        case .normal:
            return "Главное свое взял"
        case .hard:
            return "Гранд мастер бит"
        }
    }
}
