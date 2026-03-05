//
//  BotMatchContextConstants.swift
//  Jocker
//
//  Created by Qwen Code on 05.03.2026.
//

import Foundation

/// Константы для BotMatchContext-логики
///
/// Все константы вынесены для:
/// - Упрощения тестирования
/// - Возможности внешней настройки
/// - Улучшения читаемости кода
enum BotMatchContextConstants {
    
    // MARK: - Evidence weights
    
    /// База веса доказательств
    static let evidenceWeightBase: Double = 0.25
    
    /// Прогресс веса доказательств
    static let evidenceWeightProgress: Double = 0.75
    
    // MARK: - End block weights
    
    /// База веса конца блока
    static let endBlockWeightBase: Double = 0.20
    
    /// Прогресс веса конца блока
    static let endBlockWeightProgress: Double = 1.00
    
    // MARK: - Trajectory multipliers
    
    /// Множитель для must-win-all
    static let mustWinAllTrajectoryMultiplier: Double = 1.30
    
    /// Дампер конфликта zero-premium
    static let zeroPremiumConflictDampener: Double = 0.94
    
    // MARK: - Preserve multipliers
    
    /// Множитель exact bid preserve
    static let exactBidPreserveMultiplier: Double = 1.45
    
    /// Множитель already broken
    static let alreadyBrokenMultiplier: Double = 0.15
    
    /// Вес premium preserve
    static let premiumPreserveWeight: Double = 16.0
    
    // MARK: - Zero premium
    
    /// Штраф zero premium chase
    static let zeroPremiumChasePenalty: Double = 28.0
    
    /// Бонус zero premium dump
    static let zeroPremiumDumpBonus: Double = 24.0
    
    /// Множитель exact zero protect
    static let exactZeroProtectMultiplier: Double = 1.60
    
    // MARK: - Penalty
    
    /// Вес penalty threat
    static let penaltyThreatWeight: Double = 0.18
    
    /// Бонус penalty avoid dump
    static let penaltyAvoidDumpBonus: Double = 10.8
    
    /// Буст late block penalty
    static let lateBlockPenaltyBoost: Double = 0.18
}
