//
//  BotRankingConstants.swift
//  Jocker
//
//  Created by Qwen Code on 05.03.2026.
//

import Foundation

/// Константы для AI ranking-логики
///
/// Все константы вынесены для:
/// - Упрощения тестирования
/// - Возможности внешней настройки
/// - Улучшения читаемости кода
enum BotRankingConstants {
    
    // MARK: - Block plan score scales
    
    /// Scale для 4-го блока
    static let fourthBlockScoreScale: Double = 180.0
    
    /// Scale для остальных блоков
    static let standardBlockScoreScale: Double = 260.0
    
    /// Weight для 4-го блока
    static let fourthBlockWeight: Double = 1.15
    
    // MARK: - Premium preserve
    
    /// База для premium preserve
    static let premiumPreserveBase: Double = 0.35
    
    /// Вес прогресса для premium preserve
    static let premiumPreserveProgressWeight: Double = 0.65
    
    /// База для deny premium
    static let denyPremiumBase: Double = 0.30
    
    /// Вес прогресса для deny premium
    static let denyPremiumProgressWeight: Double = 0.70
    
    // MARK: - Activation weights
    
    /// Базовый вес активации
    static let baseActivationWeight: Double = 0.05
    
    /// Вес прогресса активации
    static let progressActivationWeight: Double = 0.95
    
    /// Активация для финальных раундов (0-1)
    static let finalRoundsActivationFull: Double = 1.0
    
    /// Активация для финальных раундов (2)
    static let finalRoundsActivationHalf: Double = 0.75
    
    // MARK: - Endgame urgency
    
    /// Срочность для 0-1 раундов
    static let endgameUrgencyFull: Double = 1.0
    
    /// Срочность для 2 раундов
    static let endgameUrgencyTwoRounds: Double = 0.82
    
    /// Срочность для 3 раундов
    static let endgameUrgencyThreeRounds: Double = 0.68
    
    /// Срочность по умолчанию
    static let endgameUrgencyDefault: Double = 0.42
    
    // MARK: - Block plan weights
    
    /// Вес risk budget
    static let riskBudgetWeight: Double = 0.75
    
    /// Вес endgame urgency
    static let endgameUrgencyWeight: Double = 0.60
    
    /// Вес block progress
    static let blockProgressWeight: Double = 0.40
    
    /// Вес premium bias
    static let premiumBiasWeight: Double = 0.12
    
    // MARK: - Match catch-up utility
    
    /// Базовый вес opponent urgency multiplier
    static let matchCatchUpOpponentUrgencyBase: Double = 0.20
    
    /// Прогресс веса opponent urgency multiplier
    static let matchCatchUpOpponentUrgencyProgress: Double = 0.80
    
    /// Базовый вес urgency weight
    static let matchCatchUpUrgencyWeightBase: Double = 0.20
    
    /// Прогресс веса urgency weight
    static let matchCatchUpUrgencyWeightProgress: Double = 0.55
    
    /// Базовый вес chase aggression signal
    static let matchCatchUpChaseAggressionBase: Double = 120.0
    
    /// Вес threat в chase aggression
    static let matchCatchUpChaseAggressionThreatWeight: Double = 0.05
    
    /// Вес chase pressure в chase aggression
    static let matchCatchUpChaseAggressionPressureWeight: Double = 18.0
    
    /// Бонус за final trick urgency
    static let matchCatchUpFinalTrickUrgencyBonus: Double = 8.0
    
    /// Базовый вес preserve premium penalty
    static let matchCatchUpPreservePremiumPenalty: Double = 3.0
    
    /// Базовый вес conservative dump signal
    static let matchCatchUpConservativeDumpBase: Double = 96.0
    
    /// Вес threat в conservative dump
    static let matchCatchUpConservativeDumpThreatWeight: Double = 0.035
    
    /// Вес projected score в conservative dump
    static let matchCatchUpConservativeDumpScoreWeight: Double = 0.06
    
    /// Базовый вес deny opponent premium penalty
    static let matchCatchUpDenyOpponentPenaltyBase: Double = 2.5
    
    // MARK: - Premium preserve utility
    
    /// База evidence weight для premium preserve
    static let premiumPreserveEvidenceBase: Double = 0.25
    
    /// Прогресс evidence weight для premium preserve
    static let premiumPreserveEvidenceProgress: Double = 0.75
    
    /// Вес closing rounds (≤1)
    static let premiumPreserveClosingRoundsWeight: Double = 1.35
    
    /// Вес closing rounds (2)
    static let premiumPreserveClosingRoundsTwo: Double = 1.15
    
    /// Вес closing rounds (default)
    static let premiumPreserveClosingRoundsDefault: Double = 1.0
    
    /// База progress weight
    static let premiumPreserveProgressBase: Double = 0.20

    /// Прогресс progress weight для premium preserve evidence
    static let premiumPreserveEvidenceProgressWeight: Double = 1.10

    /// Множитель для must-win-all trajectory
    static let premiumPreserveMustWinAllMultiplier: Double = 1.30
    
    /// Дампер zero-premium конфликта
    static let premiumPreserveZeroConflictDampener: Double = 0.94
    
    /// Множитель exact bid preserve
    static let premiumPreserveExactBidMultiplier: Double = 1.45
    
    /// Множитель already broken
    static let premiumPreserveAlreadyBrokenMultiplier: Double = 0.15
    
    /// Вес premium preserve chase bonus
    static let premiumPreserveChaseBonusBase: Double = 10.0
    
    /// Прогресс premium preserve chase bonus
    static let premiumPreserveChaseBonusProgress: Double = 12.0
    
    /// Вес premium preserve dump bonus
    static let premiumPreserveDumpBonus: Double = 16.0
    
    /// Множитель exact zero protect
    static let premiumPreserveExactZeroMultiplier: Double = 1.60
    
    /// Штраф zero premium chase
    static let premiumPreserveZeroChasePenalty: Double = 28.0
    
    /// Бонус zero premium dump
    static let premiumPreserveZeroDumpBonus: Double = 24.0
    
    /// Множитель zero already broken
    static let premiumPreserveZeroAlreadyBrokenMultiplier: Double = 0.10
    
    // MARK: - Penalty avoid utility
    
    /// Минимальный вес threat count
    static let penaltyAvoidThreatCountMin: Double = 0.8
    
    /// Прогресс веса threat count
    static let penaltyAvoidThreatCountProgress: Double = 0.25
    
    /// Максимальный вес threat count
    static let penaltyAvoidThreatCountMax: Double = 1.6
    
    /// База evidence weight для penalty avoid
    static let penaltyAvoidEvidenceBase: Double = 0.25
    
    /// Прогресс evidence weight для penalty avoid
    static let penaltyAvoidEvidenceProgress: Double = 0.75
    
    /// База end block weight
    static let penaltyAvoidEndBlockBase: Double = 0.20
    
    /// Прогресс end block weight
    static let penaltyAvoidEndBlockProgress: Double = 1.00
    
    /// Вес projected score penalty
    static let penaltyAvoidProjectedScoreWeight: Double = 0.18
    
    /// Штраф overbid penalty
    static let penaltyAvoidOverbidPenalty: Double = 18.0
    
    /// Бонус dump bonus
    static let penaltyAvoidDumpBonus: Double = 10.8
    
    /// Буст late block penalty avoid
    static let penaltyAvoidLateBlockBoost: Double = 0.18
    
    // MARK: - Premium deny utility
    
    /// База evidence weight для premium deny
    static let premiumDenyEvidenceBase: Double = 0.25
    
    /// Прогресс evidence weight для premium deny
    static let premiumDenyEvidenceProgress: Double = 0.75
    
    /// База end block weight для premium deny
    static let premiumDenyEndBlockBase: Double = 0.20
    
    /// Прогресс end block weight для premium deny
    static let premiumDenyEndBlockProgress: Double = 1.00
    
    /// Вес left neighbor
    static let premiumDenyLeftNeighborWeight: Double = 1.0
    
    /// Вес other opponents
    static let premiumDenyOtherOpponentsWeight: Double = 0.55
    
    /// Максимальный вес other opponents
    static let premiumDenyOtherOpponentsMax: Double = 1.4
    
    /// Бонус chase bonus
    static let premiumDenyChaseBonus: Double = 10.0
    
    /// Штраф dump penalty
    static let premiumDenyDumpPenalty: Double = 12.0
    
    /// Множитель overbid relaxation
    static let premiumDenyOverbidRelaxation: Double = 1.20
    
    // MARK: - Opponent style multiplier
    
    /// Насыщение evidence rounds
    static let opponentStyleEvidenceSaturationRounds: Int = 4
    
    /// Минимальный multiplier
    static let opponentStyleMultiplierMin: Double = 0.85
    
    /// Максимальный multiplier
    static let opponentStyleMultiplierMax: Double = 1.25
    
    /// Вес discipline signal
    static let opponentStyleDisciplineWeight: Double = 0.22
    
    /// Вес aggression signal
    static let opponentStyleAggressionWeight: Double = 0.10
    
    /// Вес blind pressure signal
    static let opponentStyleBlindPressureWeight: Double = 0.04
    
    /// Базовый rate для exact
    static let opponentStyleExactBase: Double = 0.5
    
    /// Базовый rate для aggression
    static let opponentStyleAggressionBase: Double = 0.45
    
    /// Базовый rate для blind
    static let opponentStyleBlindBase: Double = 0.20
    
    /// Вес для lead joker anti-premium
    static let opponentLeadJokerAntiPremiumWeight: Double = 0.60
    
    /// Вес для match catch-up urgency
    static let opponentMatchCatchUpUrgencyWeight: Double = 0.35
    
    /// Вес для blind chase contest
    static let opponentBlindChaseContestWeight: Double = 0.25
    
    /// Базовый weight для late block
    static let opponentLateBlockWeightBase: Double = 0.15
    
    /// Прогресс weight для late block
    static let opponentLateBlockWeightProgress: Double = 0.85
    
    // MARK: - Opponent bid pressure
    
    /// Вес next opponent
    static let opponentBidPressureNextWeight: Double = 1.0
    
    /// Вес left neighbor
    static let opponentBidPressureLeftNeighborWeight: Double = 0.9
    
    /// Вес other opponents
    static let opponentBidPressureOtherWeight: Double = 0.45
    
    /// Максимальное normalized pressure
    static let opponentBidPressureMax: Double = 1.8
    
    /// Базовый chase bonus
    static let opponentBidPressureChaseBase: Double = 10.0
    
    /// Прогресс chase bonus
    static let opponentBidPressureChaseProgress: Double = 8.0
    
    /// Базовый dump penalty
    static let opponentBidPressureDumpBase: Double = 7.0
    
    /// Прогресс dump penalty
    static let opponentBidPressureDumpProgress: Double = 9.0
    
    // MARK: - Opponent intention
    
    /// Максимальное pressure
    static let opponentIntentionPressureMax: Double = 1.9
    
    /// Вес strongest pressure
    static let opponentIntentionStrongestWeight: Double = 1.0
    
    /// Вес aggregate pressure
    static let opponentIntentionAggregateWeight: Double = 0.22
    
    /// Базовый chase bonus
    static let opponentIntentionChaseBase: Double = 8.0
    
    /// Прогресс chase bonus
    static let opponentIntentionChaseProgress: Double = 7.5
    
    /// Базовый dump penalty
    static let opponentIntentionDumpBase: Double = 6.5
    
    /// Прогресс dump penalty
    static let opponentIntentionDumpProgress: Double = 8.5
    
    // MARK: - Lead joker declaration
    
    /// Максимальный early phase tricks
    static let leadJokerEarlyPhaseMaxTricks: Int = 4
    
    /// Множитель blind round
    static let leadJokerBlindMultiplier: Double = 1.15
    
    /// Базовый wish bonus
    static let leadJokerWishBonusBase: Double = 4.0
    
    /// Минимальный wish bonus
    static let leadJokerWishBonusMin: Double = 0.6
    
    /// Прогресс wish bonus
    static let leadJokerWishBonusProgress: Double = 0.4
    
    /// Штраф anti-premium
    static let leadJokerAntiPremiumPenalty: Double = 2.5
    
    /// Базовый control loss penalty
    static let leadJokerControlLossBase: Double = 8.0
    
    /// Прогресс control loss penalty
    static let leadJokerControlLossProgress: Double = 8.0
    
    /// Дампер pressure relief
    static let leadJokerPressureRelief: Double = 0.35
    
    /// Множитель no trump relief
    static let leadJokerNoTrumpRelief: Double = 0.80
    
    /// Множитель anti-premium control need
    static let leadJokerAntiPremiumControlNeed: Double = 1.15
    
    /// Минимальный low reserve amplifier
    static let leadJokerLowReserveAmpMin: Double = 0.85
    
    /// Прогресс low reserve amplifier
    static let leadJokerLowReserveAmpProgress: Double = 0.35
    
    /// Бонус high reserve wish relief
    static let leadJokerHighReserveWishBase: Double = 2.0
    
    /// Прогресс high reserve wish relief
    static let leadJokerHighReserveWishProgress: Double = 0.4
    
    /// Базовый early phase weight
    static let leadJokerEarlyPhaseBase: Double = 0.6
    
    /// Прогресс early phase weight
    static let leadJokerEarlyPhaseProgress: Double = 0.4
    
    /// Базовый wish dump bonus
    static let leadJokerWishDumpBase: Double = 2.0
    
    /// Прогресс wish dump bonus
    static let leadJokerWishDumpProgress: Double = 4.0
    
    /// Множитель blind wish dump
    static let leadJokerWishDumpBlind: Double = 1.05
    
    /// Штраф own premium protection
    static let leadJokerOwnPremiumPenalty: Double = 2.0
    
    /// Базовый above bonus
    static let leadJokerAboveBonusBase: Double = 4.0
    
    /// Прогресс above bonus
    static let leadJokerAboveBonusProgress: Double = 7.0
    
    /// Базовый above pressure bonus
    static let leadJokerAbovePressureBase: Double = 3.0
    
    /// Бонус за trump
    static let leadJokerTrumpBonus: Double = 3.0
    
    /// Бонус за preferred suit
    static let leadJokerPreferredSuitBonus: Double = 2.5
    
    /// Прогресс preferred suit bonus
    static let leadJokerPreferredSuitProgress: Double = 2.5
    
    /// Множитель final trick
    static let leadJokerFinalTrickMultiplier: Double = 0.55
    
    /// Множитель all-in chase
    static let leadJokerAllInChaseMultiplier: Double = 0.70
    
    /// Бонус anti-premium
    static let leadJokerAntiPremiumBonus: Double = 2.5
    
    /// Бонус all-in anti-premium
    static let leadJokerAllInAntiPremiumBonus: Double = 2.0
    
    /// Минимальный low reserve amplifier для above
    static let leadJokerAboveLowReserveAmpMin: Double = 0.90
    
    /// Прогресс low reserve amplifier для above
    static let leadJokerAboveLowReserveAmpProgress: Double = 0.30
    
    /// Базовый above dump penalty
    static let leadJokerAboveDumpBase: Double = 3.0
    
    /// Прогресс above dump penalty
    static let leadJokerAboveDumpProgress: Double = 5.0
    
    /// Базовый takes penalty
    static let leadJokerTakesPenaltyBase: Double = 5.0
    
    /// Прогресс takes penalty
    static let leadJokerTakesPenaltyProgress: Double = 8.0
    
    /// Множитель takes all-in
    static let leadJokerTakesAllInMultiplier: Double = 1.15
    
    /// Множитель takes final trick
    static let leadJokerTakesFinalMultiplier: Double = 0.75
    
    /// Минимальный takes low reserve amplifier
    static let leadJokerTakesLowReserveAmpMin: Double = 0.90
    
    /// Прогресс takes low reserve amplifier
    static let leadJokerTakesLowReserveAmpProgress: Double = 0.25
    
    /// Базовый takes dump bonus
    static let leadJokerTakesDumpBase: Double = 4.0
    
    /// Прогресс takes dump bonus
    static let leadJokerTakesDumpProgress: Double = 6.0
    
    /// Штраф takes trump dump
    static let leadJokerTakesTrumpDumpPenalty: Double = 5.0
    
    /// Бонус takes non-trump dump
    static let leadJokerTakesNonTrumpDumpBonus: Double = 3.0
    
    /// Бонус takes preferred suit dump
    static let leadJokerTakesPreferredDumpPenalty: Double = 1.5
    
    /// Прогресс takes preferred suit dump
    static let leadJokerTakesPreferredDumpProgress: Double = 1.5
    
    /// Бонус controlled loss lead
    static let leadJokerControlledLossBase: Double = 2.5
    
    /// Прогресс controlled loss lead
    static let leadJokerControlledLossProgress: Double = 2.0
    
    /// Максимальный overbid severity
    static let leadJokerOverbidSeverityMax: Double = 2.0
    
    /// Бонус controlled loss non-trump
    static let leadJokerControlledLossNonTrump: Double = 1.0
    
    /// Множитель controlled loss multiplier
    static let leadJokerControlledLossMultiplier: Double = 0.80
    
    /// Прогресс controlled loss multiplier
    static let leadJokerControlledLossProgressMult: Double = 0.20
    
    // MARK: - Lead joker goal-oriented
    
    /// Базовый secure trick wish
    static let goalSecureTrickWishChase: Double = 0.62
    
    /// Прогресс secure trick wish
    static let goalSecureTrickWishProgress: Double = 0.38
    
    /// Базовый secure trick wish dump
    static let goalSecureTrickWishDump: Double = 0.34
    
    /// Базовый preserve control wish
    static let goalPreserveControlWishBase: Double = 0.38
    
    /// Прогресс preserve control wish
    static let goalPreserveControlWishProgress: Double = 0.30
    
    /// Базовый controlled loss wish
    static let goalControlledLossWish: Double = 0.32
    
    /// Базовый secure trick above
    static let goalSecureTrickAboveBase: Double = 0.54
    
    /// Прогресс secure trick above chase
    static let goalSecureTrickAboveChase: Double = 0.18
    
    /// Бонус secure trick trump
    static let goalSecureTrickTrump: Double = 0.16
    
    /// Бонус secure trick preferred
    static let goalSecureTrickPreferredBase: Double = 0.08
    
    /// Прогресс secure trick preferred
    static let goalSecureTrickPreferredProgress: Double = 0.10
    
    /// Базовый preserve control above
    static let goalPreserveControlAboveBase: Double = 0.42
    
    /// Прогресс preserve control trump
    static let goalPreserveControlTrump: Double = 0.14
    
    /// Бонус preserve control preferred
    static let goalPreserveControlPreferredBase: Double = 0.10
    
    /// Прогресс preserve control preferred
    static let goalPreserveControlPreferredProgress: Double = 0.12
    
    /// Прогресс preserve control low reserve
    static let goalPreserveControlLowReserve: Double = 0.14
    
    /// Базовый secure trick takes
    static let goalSecureTrickTakesBase: Double = 0.28
    
    /// Бонус secure trick takes trump
    static let goalSecureTrickTakesTrump: Double = 0.08
    
    /// Базовый secure trick takes dump
    static let goalSecureTrickTakesDump: Double = 0.16
    
    /// Базовый preserve control takes
    static let goalPreserveControlTakesBase: Double = 0.18
    
    /// Штраф preserve control trump
    static let goalPreserveControlTakesTrump: Double = -0.10
    
    /// Бонус preserve control non-trump
    static let goalPreserveControlTakesNonTrump: Double = 0.04
    
    /// Прогресс preserve control takes low reserve
    static let goalPreserveControlTakesLowReserve: Double = 0.10
    
    /// Базовый controlled loss takes
    static let goalControlledLossTakesBase: Double = 0.54
    
    /// Бонус controlled loss takes non-trump
    static let goalControlledLossTakesNonTrump: Double = 0.18
    
    /// Штраф controlled loss takes penalty risk
    static let goalControlledLossTakesPenalty: Double = -0.12
    
    /// Бонус controlled loss takes penalty risk
    static let goalControlledLossTakesPenaltyBonus: Double = 0.10
    
    /// Базовый secure weight chase
    static let goalSecureWeightChaseBase: Double = 0.52
    
    /// Прогресс secure weight chase
    static let goalSecureWeightChaseProgress: Double = 0.34
    
    /// Бонус secure weight all-in
    static let goalSecureWeightAllIn: Double = 0.14
    
    /// Базовый control weight chase
    static let goalControlWeightChaseBase: Double = 0.26
    
    /// Прогресс control weight chase
    static let goalControlWeightChaseProgress: Double = 0.22
    
    /// Бонус control weight anti-premium
    static let goalControlWeightAntiPremium: Double = 0.10
    
    /// Базовый controlled loss weight chase
    static let goalControlledLossWeightChase: Double = -0.18
    
    /// Базовый secure weight dump
    static let goalSecureWeightDump: Double = -0.14
    
    /// Базовый control weight dump
    static let goalControlWeightDumpBase: Double = 0.20
    
    /// Бонус control weight dump anti-premium
    static let goalControlWeightDumpAntiPremium: Double = 0.06
    
    /// Базовый controlled loss weight dump
    static let goalControlledLossWeightDumpBase: Double = 0.58
    
    /// Бонус controlled loss weight dump penalty risk
    static let goalControlledLossWeightDumpPenalty: Double = 0.18
    
    /// Базовый scale chase
    static let goalScaleChaseBase: Double = 10.0
    
    /// Прогресс scale chase
    static let goalScaleChaseProgress: Double = 7.0
    
    /// Базовый scale dump
    static let goalScaleDumpBase: Double = 9.0
    
    /// Прогресс scale dump
    static let goalScaleDumpProgress: Double = 6.0
    
    // MARK: - Composite utility
    
    /// Базовый urgency chase pressure weight
    static let compositeUrgencyChaseWeight: Double = 0.58
    
    /// Базовый urgency block weight
    static let compositeUrgencyBlockWeight: Double = 0.42
    
    /// Базовый tactical multiplier
    static let compositeTacticalMultiplierBase: Double = 1.0
    
    /// Прогресс tactical multiplier
    static let compositeTacticalMultiplierProgress: Double = 0.04
    
    /// Бонус tactical multiplier chase
    static let compositeTacticalMultiplierChase: Double = 0.03
    
    /// Минимальный tactical multiplier
    static let compositeTacticalMultiplierMin: Double = 0.95
    
    /// Максимальный tactical multiplier
    static let compositeTacticalMultiplierMax: Double = 1.10
    
    /// Базовый risk multiplier
    static let compositeRiskMultiplierBase: Double = 1.0
    
    /// Прогресс risk multiplier
    static let compositeRiskMultiplierProgress: Double = 0.08
    
    /// Бонус risk multiplier penalty
    static let compositeRiskMultiplierPenalty: Double = 0.06
    
    /// Минимальный risk multiplier
    static let compositeRiskMultiplierMin: Double = 0.94
    
    /// Максимальный risk multiplier
    static let compositeRiskMultiplierMax: Double = 1.18
    
    /// Базовый opponent multiplier
    static let compositeOpponentMultiplierBase: Double = 1.0
    
    /// Прогресс opponent multiplier
    static let compositeOpponentMultiplierProgress: Double = 0.06
    
    /// Бонус opponent multiplier evidence
    static let compositeOpponentMultiplierEvidence: Double = 0.05
    
    /// Минимальный opponent multiplier
    static let compositeOpponentMultiplierMin: Double = 0.95
    
    /// Максимальный opponent multiplier
    static let compositeOpponentMultiplierMax: Double = 1.16
    
    /// Базовый joker multiplier chase
    static let compositeJokerMultiplierChaseBase: Double = 1.0
    
    /// Прогресс joker multiplier chase
    static let compositeJokerMultiplierChaseProgress: Double = 0.10
    
    /// Бонус joker multiplier chase
    static let compositeJokerMultiplierChaseBonus: Double = 0.05
    
    /// Бонус joker multiplier dump
    static let compositeJokerMultiplierDump: Double = 0.06
    
    /// Минимальный joker multiplier
    static let compositeJokerMultiplierMin: Double = 0.90
    
    /// Максимальный joker multiplier
    static let compositeJokerMultiplierMax: Double = 1.22
    
    /// Максимальный tactical cap
    static let compositeTacticalCap: Double = 180.0
    
    /// Максимальный risk cap
    static let compositeRiskCap: Double = 180.0
    
    /// Максимальный opponent cap
    static let compositeOpponentCap: Double = 120.0
    
    /// Максимальный joker cap
    static let compositeJokerCap: Double = 180.0
    
    /// Базовый stabilization window
    static let compositeStabilizationBase: Double = 90.0
    
    /// Прогресс stabilization win probability
    static let compositeStabilizationWinProb: Double = 50.0
    
    /// Вес stabilization threat
    static let compositeStabilizationThreat: Double = 0.15
    
    // MARK: - Move utility
    
    /// Базовый late block weight
    static let moveUtilityLateBlockBase: Double = 0.5
    
    /// Прогресс late block weight
    static let moveUtilityLateBlockProgress: Double = 0.5
    
    /// Бонус late block premium protection
    static let moveUtilityLateBlockPremium: Double = 64.0
    
    /// Максимальный overbid severity
    static let moveUtilityOverbidSeverityMax: Double = 2.0
    
    /// Бонус overbid tactical
    static let moveUtilityOverbidTacticalBase: Double = 14.0
    
    /// Базовый erratic tactical
    static let moveUtilityErraticTacticalBase: Double = 12.0
    
    /// Прогресс erratic tactical
    static let moveUtilityErraticTacticalProgress: Double = 20.0
    
    /// Бонус penalty risk dump
    static let moveUtilityPenaltyRiskDump: Double = 8.0
    
    /// Базовый blind reward
    static let moveUtilityBlindRewardBase: Double = 1.55
    
    /// Базовый blind risk
    static let moveUtilityBlindRiskBase: Double = 1.30
    
    /// Базовый wish penalty
    static let moveUtilityWishPenaltyBase: Double = 24.0
    
    /// Прогресс wish penalty
    static let moveUtilityWishPenaltyProgress: Double = 6.0
    
    /// Базовый wish chase multiplier
    static let moveUtilityWishChaseBase: Double = 1.0
    
    /// Прогресс wish chase multiplier
    static let moveUtilityWishChaseProgress: Double = 0.25
    
    /// Множитель blind wish penalty
    static let moveUtilityWishBlindPenalty: Double = 1.25
    
    /// Минимальный wish penalty reserve multiplier
    static let moveUtilityWishReserveMin: Double = 1.15
    
    /// Прогресс wish penalty reserve multiplier
    static let moveUtilityWishReserveProgress: Double = 0.45
    
    // MARK: - Utility tolerance
    
    /// Tolerance для tie-breaking
    static let utilityTieTolerance: Double = 0.000_001
}
