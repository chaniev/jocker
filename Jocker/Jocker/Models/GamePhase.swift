//
//  GamePhase.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import Foundation

/// Состояние игры
enum GamePhase {
    case notStarted      // Игра не начата
    case bidding         // Фаза ставок
    case playing         // Фаза игры (разыгрывание карт)
    case roundEnd        // Конец раунда
    case gameEnd         // Конец игры
}
