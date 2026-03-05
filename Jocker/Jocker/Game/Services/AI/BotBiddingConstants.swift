//
//  BotBiddingConstants.swift
//  Jocker
//
//  Created by Qwen Code on 05.03.2026.
//

import Foundation

/// Константы для AI bidding-логики
///
/// Все константы вынесены для:
/// - Упрощения тестирования
/// - Возможности внешней настройки
/// - Улучшения читаемости кода
enum BotBiddingConstants {
    
    // MARK: - Blind Monte Carlo конфигурация
    
    /// Минимальное количество итераций
    static let blindMonteCarloMinIterations: Int = 24
    
    /// Максимальное количество итераций
    static let blindMonteCarloMaxIterations: Int = 56
    
    /// Множитель для расчёта количества итераций (на карту)
    static let blindMonteCarloIterationsPerCard: Int = 5
    
    /// Множитель для расчёта количества итераций (на ставку)
    static let blindMonteCarloIterationsPerBid: Int = 2
    
    // MARK: - Utility tolerance
    
    /// Tolerance для tie-breaking
    static let bidUtilityTieTolerance: Double = 0.000_001
    
    // MARK: - Blind risk score база
    
    /// Базовое значение blind risk score
    static let blindRiskScoreBase: Double = -0.55
    
    /// Бонус за достижение catch-up порога
    static let blindCatchUpThresholdBonus: Double = 0.35
    
    /// Бонус за достижение desperate порога
    static let blindDesperateThresholdBonus: Double = 0.35
    
    // MARK: - Pressure multipliers
    
    /// Множитель catch-up давления
    static let blindCatchUpPressureMultiplier: Double = 1.2
    
    /// Множитель desperate давления
    static let blindDesperatePressureMultiplier: Double = 0.95
    
    /// Множитель safety penalty
    static let blindSafetyPenaltyMultiplier: Double = 1.1
    
    /// Штраф за лидерство (когда игрок лидирует)
    static let blindLeaderPenalty: Double = 0.5
    
    // MARK: - Position adjustments
    
    /// Штраф дилера
    static let blindDealerPenalty: Double = 0.2
    
    /// Бонус не-дилера
    static let blindNonDealerBonus: Double = 0.08
    
    /// Штраф за лидерство в таблице
    static let blindTableLeaderPenalty: Double = 0.35
    
    // MARK: - Round length adjustments
    
    /// Бонус за длинный раунд (максимум)
    static let blindLongRoundBonusCap: Double = 0.35
    
    /// Порог длинного раунда
    static let blindLongRoundThreshold: Int = 4
    
    /// Делитель бонуса за длинный раунд
    static let blindLongRoundBonusDivisor: Double = 10.0
    
    // MARK: - Range adjustments
    
    /// Штраф за минимальную ставку
    static let blindMinAllowedPenalty: Double = 0.35
    
    /// Штраф за узкий диапазон (≤2)
    static let blindNarrowRangePenalty: Double = 0.2
    
    /// Штраф за средний диапазон (≤4)
    static let blindMediumRangePenalty: Double = 0.1
    
    /// Бонус за широкий диапазон
    static let blindWideRangeBonus: Double = 0.05
    
    /// Порог для проверки risk score
    static let blindRiskScoreThreshold: Double = 0.05
    
    // MARK: - Target share конфигурация
    
    /// Консервативная целевая доля
    static let blindCatchUpConservativeTargetShare: Double = 0.0
    
    /// Целевая доля для catch-up режима
    static let blindCatchUpTargetShare: Double = 0.85
    
    /// Целевая доля для desperate режима
    static let blindDesperateTargetShare: Double = 0.95
    
    // MARK: - Mode thresholds
    
    /// Порог desperate mode по risk score
    static let blindDesperateModeThreshold: Double = 1.6
    
    /// Делитель overflow
    static let blindOverflowDivisor: Double = 1.2
    
    /// Бонус desperate overflow
    static let blindDesperateOverflowBonus: Double = 0.08
    
    /// Порог catch-up mode по risk score
    static let blindCatchUpModeThreshold: Double = 0.85
    
    /// Делитель progress
    static let blindModeProgressDivisor: Double = 0.75
    
    /// Вес catch-up to desperate
    static let blindCatchUpToDesperateWeight: Double = 0.35
    
    /// Делитель conservative progress
    static let blindConservativeProgressDivisor: Double = 0.8
    
    /// Вес conservative to catch-up
    static let blindConservativeToCatchUpWeight: Double = 0.45
    
    // MARK: - Target adjustments
    
    /// Adjustment дилера
    static let blindDealerPositionAdjustment: Double = -0.03
    
    /// Adjustment не-дилера
    static let blindNonDealerAdjustment: Double = 0.02
    
    /// Adjustment за длинный раунд
    static let blindLongRoundAdjustment: Double = 0.03
    
    /// Порог длинного раунда для adjustment
    static let blindLongRoundAdjustmentThreshold: Int = 8
    
    /// Safety adjustment
    static let blindSafetyAdjustment: Double = -0.05
    
    /// Cap target share
    static let blindTargetShareCap: Double = 0.95
    
    // MARK: - Bid utility weights
    
    /// Базовый вес optimality penalty
    static let bidUtilityOptimalityPenaltyBase: Double = 7.4
    
    /// Прогресс веса optimality penalty
    static let bidUtilityOptimalityPenaltyProgress: Double = 2.8
    
    /// Базовый вес optimality penalty (без forbidden)
    static let bidUtilityOptimalityPenaltyBaseNoForbidden: Double = 3.0
    
    /// Прогресс веса optimality penalty (без forbidden)
    static let bidUtilityOptimalityPenaltyProgressNoForbidden: Double = 1.2
    
    /// Базовый вес expected penalty
    static let bidUtilityExpectedPenaltyBase: Double = 1.7
    
    /// Прогресс веса expected penalty
    static let bidUtilityExpectedPenaltyProgress: Double = 0.9
    
    /// Вес score gap penalty (с forbidden)
    static let bidUtilityScoreGapPenaltyForbidden: Double = 0.70
    
    /// Вес score gap penalty (без forbidden)
    static let bidUtilityScoreGapPenaltyNoForbidden: Double = 0.38
    
    // MARK: - Monte Carlo variance penalty
    
    /// Базовый вес variance penalty
    static let mcVariancePenaltyBase: Double = 0.50
    
    /// Максимальный вес safe lead pressure
    static let mcSafeLeadPressureMax: Double = 0.55
    
    /// Вес desperate penalty
    static let mcDesperatePenaltyWeight: Double = 0.35
    
    /// Минимальный variance penalty weight
    static let mcVariancePenaltyWeightMin: Double = 0.08
    
    /// Максимальный variance penalty weight
    static let mcVariancePenaltyWeightMax: Double = 1.35
    
    /// Risk budget modifier для variance penalty
    static let mcVarianceRiskBudgetModifier: Double = 0.55
    
    // MARK: - Monte Carlo другие веса
    
    /// Базовый вес deviation penalty
    static let mcDeviationPenaltyBase: Double = 1.2
    
    /// Множитель risk budget для deviation penalty
    static let mcDeviationRiskBudgetMultiplier: Double = 3.6
    
    /// Базовый вес overshoot penalty
    static let mcOvershootPenaltyBase: Double = 1.4
    
    /// Множитель safe lead pressure для overshoot penalty
    static let mcOvershootSafeLeadMultiplier: Double = 1.1
    
    /// Базовый вес catch-up aggression
    static let mcCatchUpAggressionBase: Double = 1.7
    
    /// Множитель catch-up pressure для aggression
    static let mcCatchUpAggressionPressureMultiplier: Double = 1.1
    
    // MARK: - Minimum aggressive bid floor
    
    /// Минимальный порог для desperate mode
    static let minAggressiveBidDesperateMin: Int = 2
    
    /// Доля target bid для desperate mode
    static let minAggressiveBidDesperateShare: Double = 0.62
    
    /// Базовая доля для catch-up mode
    static let minAggressiveBidCatchUpBase: Double = 0.28
    
    /// Прогресс доли для catch-up mode
    static let minAggressiveBidCatchUpProgress: Double = 0.20
    
    // MARK: - Deterministic RNG константы
    
    /// Seed по умолчанию для RNG
    static let defaultRNGSeed: UInt64 = 0xA24B_AED4_963E_E407
    
    /// Multiplier для RNG
    static let rngMultiplier: UInt64 = 6364136223846793005
    
    /// Increment для RNG
    static let rngIncrement: UInt64 = 1442695040888963407
    
    // MARK: - Hash константы
    
    /// Base seed для Monte Carlo
    static let monteCarloBaseSeed: UInt64 = 0x9E37_79B9_7F4A_7C15
    
    /// Shift right 1 для hash mixing
    static let hashShiftRight1: UInt64 = 21
    
    /// Shift left для hash mixing
    static let hashShiftLeft: UInt64 = 37
    
    /// Shift right 2 для hash mixing
    static let hashShiftRight2: UInt64 = 4
    
    // MARK: - Blind bidding пороги (из BotTuning)
    
    /// Порог отставания для catch-up режима
    static let blindCatchUpBehindThreshold: Int = 50
    
    /// Порог отставания для desperate режима
    static let blindDesperateBehindThreshold: Int = 80
    
    /// Порог лидерства для безопасной игры
    static let blindSafeLeadThreshold: Int = 30
}
