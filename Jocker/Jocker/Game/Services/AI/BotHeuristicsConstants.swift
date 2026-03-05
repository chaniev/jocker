//
//  BotHeuristicsConstants.swift
//  Jocker
//
//  Created by Qwen Code on 05.03.2026.
//

import Foundation

/// Константы для AI heuristics-логики
///
/// Все константы вынесены для:
/// - Упрощения тестирования
/// - Возможности внешней настройки
/// - Улучшения читаемости кода
enum BotHeuristicsConstants {
    
    // MARK: - Legal-aware sampling
    
    /// Минимальное количество итераций
    static let legalAwareMinIterations: Int = 20
    
    /// Максимальное количество итераций
    static let legalAwareMaxIterations: Int = 48
    
    /// Минимальное reduced количество
    static let legalAwareReducedMinIterations: Int = 8
    
    /// Максимальное reduced количество
    static let legalAwareReducedMaxIterations: Int = 20
    
    /// Rotation stride
    static let legalAwareRotationStride: Int = 7
    
    /// Максимум карт на sample (reduced)
    static let legalAwareReducedMaxCardsPerOpponentSample: Int = 3
    
    /// Порог endgame размера руки
    static let legalAwareEndgameHandSizeThreshold: Int = 4
}
