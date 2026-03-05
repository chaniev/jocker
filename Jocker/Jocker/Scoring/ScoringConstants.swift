//
//  ScoringConstants.swift
//  Jocker
//
//  Created by Qwen Code on 05.03.2026.
//

import Foundation

/// Константы для расчёта очков
///
/// Все константы вынесены для:
/// - Упрощения тестирования
/// - Возможности внешней настройки
/// - Улучшения читаемости кода
enum ScoringConstants {
    
    // MARK: - Множители для точного заказа
    
    /// Множитель для K = V = C (точный заказ, все взятки)
    static let exactBidAllTricksMultiplier: Int = 100
    
    /// Множитель для K = V ≠ C (точный заказ, не все взятки)
    static let exactBidBaseMultiplier: Int = 50
    
    /// Бонус для K = V ≠ C
    static let exactBidBaseBonus: Int = 50
    
    // MARK: - Множители для перебора/недобора
    
    /// Стоимость каждой взятки при переборе (K > V)
    static let overbidTrickValue: Int = 10
    
    /// Штраф за каждую недостающую взятку (K < V)
    static let underbidPenaltyPerTrick: Int = 50
    
    /// Базовый штраф за недобор
    static let underbidBasePenalty: Int = 50
    
    /// Множитель для K = 0, V = C (нулевой заказ, все взятки)
    static let zeroBidAllTricksPenaltyMultiplier: Int = 100
    
    // MARK: - Blind множители
    
    /// Множитель для blind-ставок
    static let blindScoreMultiplier: Int = 2
    
    // MARK: - Премии
    
    /// Количество очков за нулевую премию
    static let zeroPremiumAmount: Int = 500
}
