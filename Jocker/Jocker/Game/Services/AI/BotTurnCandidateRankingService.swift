//
//  BotTurnCandidateRankingService.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import Foundation

/// Ранжирование кандидатов runtime-хода бота:
/// расчёт utility и tie-break между двумя оценёнными ходами.
struct BotTurnCandidateRankingService {
    struct Move {
        let card: Card
        let decision: JokerPlayDecision
    }

    struct Evaluation {
        let move: Move
        let utility: Double
        let immediateWinProbability: Double
        let threat: Double
    }

    struct UtilityContext {
        let trick: BotTurnCardHeuristicsService.TrickSnapshot
        let trump: Suit?
        let shouldChaseTrick: Bool
        let hasWinningNonJoker: Bool
        let hasLosingNonJoker: Bool
        let tricksNeededToMatchBid: Int
        let tricksRemainingIncludingCurrent: Int
        let trickDeltaToBidBeforeMove: Int
        let chasePressure: Double
        let isBlindRound: Bool
        let matchContext: BotMatchContext?

        init(
            trick: BotTurnCardHeuristicsService.TrickSnapshot,
            trump: Suit?,
            shouldChaseTrick: Bool,
            hasWinningNonJoker: Bool,
            hasLosingNonJoker: Bool,
            tricksNeededToMatchBid: Int,
            tricksRemainingIncludingCurrent: Int,
            trickDeltaToBidBeforeMove: Int = 0,
            chasePressure: Double,
            isBlindRound: Bool = false,
            matchContext: BotMatchContext? = nil
        ) {
            self.trick = trick
            self.trump = trump
            self.shouldChaseTrick = shouldChaseTrick
            self.hasWinningNonJoker = hasWinningNonJoker
            self.hasLosingNonJoker = hasLosingNonJoker
            self.tricksNeededToMatchBid = tricksNeededToMatchBid
            self.tricksRemainingIncludingCurrent = tricksRemainingIncludingCurrent
            self.trickDeltaToBidBeforeMove = trickDeltaToBidBeforeMove
            self.chasePressure = chasePressure
            self.isBlindRound = isBlindRound
            self.matchContext = matchContext
        }
    }

    private let tuning: BotTuning

    init(tuning: BotTuning) {
        self.tuning = tuning
    }

    /// Этап 4b (MVP): score-only матчевый риск-сигнал.
    /// Положительное значение => нужно агрессивнее догонять.
    /// Отрицательное значение => выгоднее сохранять текущую позицию.
    private func matchRiskBias(from matchContext: BotMatchContext?) -> Double {
        guard let matchContext else { return 0.0 }
        guard matchContext.playerCount > 1 else { return 0.0 }
        guard matchContext.playerIndex >= 0, matchContext.playerIndex < matchContext.playerCount else { return 0.0 }
        guard matchContext.totalScores.count >= matchContext.playerCount else { return 0.0 }

        let ownScore = matchContext.totalScores[matchContext.playerIndex]
        let opponentScores = matchContext.totalScores.enumerated()
            .filter { $0.offset != matchContext.playerIndex }
            .map(\.element)
        guard let leaderScore = matchContext.totalScores.max(), !opponentScores.isEmpty else { return 0.0 }

        let bestOpponentScore = opponentScores.max() ?? ownScore
        let behindLeader = max(0, leaderScore - ownScore)
        let safeLead = max(0, ownScore - bestOpponentScore)

        let scoreScale = matchContext.block == .fourth ? 180.0 : 260.0
        let behindSignal = min(1.0, Double(behindLeader) / scoreScale)
        let leadSignal = min(1.0, Double(safeLead) / scoreScale)
        let progressWeight = 0.20 + 0.80 * matchContext.blockProgressFraction
        let blockWeight = matchContext.block == .fourth ? 1.15 : 1.0

        return (behindSignal - leadSignal) * progressWeight * blockWeight
    }

    /// Этап 4b (MVP): стратегическая матч-надбавка по текущему счёту.
    /// Пока без premium-кандидатства; это первый шаг `matchCatchUpUtility`.
    private func matchCatchUpUtilityAdjustment(
        immediateWinProbability: Double,
        threat: Double,
        context: UtilityContext
    ) -> Double {
        let riskBias = matchRiskBias(from: context.matchContext)
        guard abs(riskBias) > 0.000_001 else { return 0.0 }

        // Пока применяем только в режиме добора, чтобы избежать резких сдвигов dump-логики.
        guard context.shouldChaseTrick else { return 0.0 }

        let chaseAggressionSignal =
            immediateWinProbability * 120.0 -
            threat * 0.05 +
            context.chasePressure * 18.0
        let finalTrickUrgencyBonus = context.tricksNeededToMatchBid >= context.tricksRemainingIncludingCurrent
            ? 8.0
            : 0.0

        return riskBias * (chaseAggressionSignal + finalTrickUrgencyBonus)
    }

    /// Этап 4b (MVP): защита собственной премиальной траектории без моделирования соперников.
    /// Использует только признаки "кандидат/не кандидат" на премию и zero-premium.
    private func premiumPreserveUtilityAdjustment(
        immediateWinProbability: Double,
        context: UtilityContext
    ) -> Double {
        guard let matchContext = context.matchContext else { return 0.0 }
        guard let premium = matchContext.premium else { return 0.0 }
        guard premium.isPremiumCandidateSoFar || premium.isZeroPremiumCandidateSoFar else { return 0.0 }

        let evidenceWeight = 0.25 + 0.75 * min(
            1.0,
            Double(max(0, premium.completedRoundsInBlock)) /
                Double(max(1, matchContext.totalRoundsInBlock - 1))
        )
        let closingRoundsWeight: Double
        switch premium.remainingRoundsInBlock {
        case ...1:
            closingRoundsWeight = 1.35
        case 2:
            closingRoundsWeight = 1.15
        default:
            closingRoundsWeight = 1.0
        }
        let progressWeight = (0.20 + 1.10 * matchContext.blockProgressFraction) * evidenceWeight * closingRoundsWeight
        var adjustment = 0.0
        let bidTrajectoryDelta = context.trickDeltaToBidBeforeMove
        let isExactlyOnBidBeforeMove = bidTrajectoryDelta == 0
        let hasAlreadyBrokenRoundExactBid = bidTrajectoryDelta > 0

        if premium.isPremiumCandidateSoFar {
            if context.shouldChaseTrick {
                let deficitUrgency = min(
                    1.0,
                    Double(context.tricksNeededToMatchBid) / Double(max(1, context.tricksRemainingIncludingCurrent))
                )
                let mustWinAllRemaining = context.tricksNeededToMatchBid >= context.tricksRemainingIncludingCurrent
                let trajectoryMultiplier = mustWinAllRemaining ? 1.30 : 1.0
                adjustment += immediateWinProbability *
                    (10.0 + 12.0 * deficitUrgency) *
                    progressWeight *
                    trajectoryMultiplier
            } else {
                let exactBidPreserveMultiplier = isExactlyOnBidBeforeMove ? 1.45 : 1.0
                let alreadyBrokenMultiplier = hasAlreadyBrokenRoundExactBid ? 0.15 : 1.0
                adjustment += (1.0 - immediateWinProbability) *
                    16.0 *
                    progressWeight *
                    exactBidPreserveMultiplier *
                    alreadyBrokenMultiplier
            }
        }

        if premium.isZeroPremiumCandidateSoFar {
            if context.shouldChaseTrick {
                let alreadyBrokenMultiplier = hasAlreadyBrokenRoundExactBid ? 0.10 : 1.0
                adjustment -= immediateWinProbability * 28.0 * progressWeight * alreadyBrokenMultiplier
            } else {
                let exactZeroProtectMultiplier = isExactlyOnBidBeforeMove ? 1.60 : 1.0
                let alreadyBrokenMultiplier = hasAlreadyBrokenRoundExactBid ? 0.10 : 1.0
                adjustment += (1.0 - immediateWinProbability) *
                    24.0 *
                    progressWeight *
                    exactZeroProtectMultiplier *
                    alreadyBrokenMultiplier
            }
        }

        return adjustment
    }

    /// Этап 4c (fallback MVP): защита от риска стать целью штрафа за чужую премию.
    /// Пока без `premiumDenyUtility`; только `penaltyAvoidUtility`.
    private func penaltyAvoidUtilityAdjustment(
        projectedScore: Double,
        immediateWinProbability: Double,
        context: UtilityContext
    ) -> Double {
        guard let matchContext = context.matchContext else { return 0.0 }
        guard let premium = matchContext.premium else { return 0.0 }
        guard premium.isPenaltyTargetRiskSoFar else { return 0.0 }
        guard premium.premiumCandidatesThreateningPenaltyCount > 0 else { return 0.0 }

        let threatCountWeight = min(1.6, 0.8 + 0.25 * Double(premium.premiumCandidatesThreateningPenaltyCount))
        let evidenceWeight = 0.25 + 0.75 * min(
            1.0,
            Double(max(0, premium.completedRoundsInBlock)) /
                Double(max(1, matchContext.totalRoundsInBlock - 1))
        )
        let endBlockWeight = 0.20 + 1.00 * matchContext.blockProgressFraction
        let riskWeight = threatCountWeight * evidenceWeight * endBlockWeight

        var adjustment = 0.0
        let positiveProjectedScore = max(0.0, projectedScore)
        if positiveProjectedScore > 0 {
            adjustment -= positiveProjectedScore * 0.18 * riskWeight
        }

        if context.shouldChaseTrick {
            if context.trickDeltaToBidBeforeMove > 0 {
                // Уже вышли в overbid и продолжаем добирать: при риске штрафа это особенно плохо.
                adjustment -= immediateWinProbability * 18.0 * riskWeight
            }
        } else {
            // В режиме dump под риском штрафа чуть сильнее поощряем безопасный проигрыш взятки.
            adjustment += (1.0 - immediateWinProbability) * 10.0 * riskWeight
        }

        return adjustment
    }

    /// Этап 4c (упрощённый anti-premium MVP):
    /// если сосед слева остаётся premium-кандидатом, слегка деформируем utility
    /// против "слишком безопасного dump", чтобы чаще ломать чужую премиальную траекторию.
    private func premiumDenyUtilityAdjustment(
        immediateWinProbability: Double,
        context: UtilityContext
    ) -> Double {
        guard let matchContext = context.matchContext else { return 0.0 }
        guard let premium = matchContext.premium else { return 0.0 }
        guard premium.opponentPremiumCandidatesSoFarCount > 0 else { return 0.0 }

        // Приоритет защиты своей премии/zero-premium остаётся за этапом 4b.
        if premium.isPremiumCandidateSoFar || premium.isZeroPremiumCandidateSoFar {
            return 0.0
        }

        let evidenceWeight = 0.25 + 0.75 * min(
            1.0,
            Double(max(0, premium.completedRoundsInBlock)) /
                Double(max(1, matchContext.totalRoundsInBlock - 1))
        )
        let endBlockWeight = 0.20 + 1.00 * matchContext.blockProgressFraction
        let leftNeighborWeight = premium.leftNeighborIsPremiumCandidateSoFar ? 1.0 : 0.0
        let otherOpponentCandidates = max(
            0,
            premium.opponentPremiumCandidatesSoFarCount - (premium.leftNeighborIsPremiumCandidateSoFar ? 1 : 0)
        )
        let otherOpponentsWeight = min(1.4, Double(otherOpponentCandidates) * 0.55)
        let denyWeight = (leftNeighborWeight + otherOpponentsWeight) * evidenceWeight * endBlockWeight
        guard denyWeight > 0 else { return 0.0 }
        let overbidRelaxation = context.trickDeltaToBidBeforeMove > 0 ? 1.20 : 1.0

        if context.shouldChaseTrick {
            return immediateWinProbability * 10.0 * denyWeight * overbidRelaxation
        }

        // В dump-режиме уменьшаем привлекательность "безопасного проигрыша взятки",
        // если это может сохранять премиальную линию соседа слева.
        return -(1.0 - immediateWinProbability) * 12.0 * denyWeight * overbidRelaxation
    }

    /// Этап 5 (MVP): контекстная оценка объявления ведущего джокера.
    /// На первом шаге даём отдельный utility для `wish/above/takes` без сложного моделирования ответов соперников.
    private func leadJokerDeclarationUtilityAdjustment(
        immediateWinProbability: Double,
        leadControlReserveAfterMove: Double,
        leadPreferredControlSuitAfterMove: Suit?,
        leadPreferredControlSuitStrengthAfterMove: Double,
        move: Move,
        context: UtilityContext
    ) -> Double {
        guard move.card.isJoker else { return 0.0 }
        guard context.trick.playedCards.isEmpty else { return 0.0 }
        guard move.decision.style == .faceUp else { return 0.0 }
        guard let declaration = move.decision.leadDeclaration else { return 0.0 }

        let tricksAfterCurrent = max(0, context.tricksRemainingIncludingCurrent - 1)
        let earlyPhaseWeight = min(1.0, Double(min(tricksAfterCurrent, 4)) / 4.0)
        let blindMultiplier = context.isBlindRound ? 1.15 : 1.0
        let isFinalTrick = context.tricksRemainingIncludingCurrent <= 1
        let isAllInChase = context.shouldChaseTrick &&
            context.tricksNeededToMatchBid >= context.tricksRemainingIncludingCurrent
        let controlReserve = min(1.0, max(0.0, leadControlReserveAfterMove))
        let lowReserveNeedForImmediateControl = 1.0 - controlReserve
        let preferredControlSuit = leadPreferredControlSuitAfterMove
        let preferredControlSuitStrength = min(1.0, max(0.0, leadPreferredControlSuitStrengthAfterMove))
        let premium = context.matchContext?.premium
        let ownPremiumProtectionContext = premium.map {
            $0.isPremiumCandidateSoFar || $0.isZeroPremiumCandidateSoFar
        } ?? false
        let antiPremiumPressureContext = premium.map {
            $0.leftNeighborIsPremiumCandidateSoFar ||
                $0.isPenaltyTargetRiskSoFar ||
                $0.opponentPremiumCandidatesSoFarCount > 0
        } ?? false

        switch declaration {
        case .wish:
            if context.shouldChaseTrick {
                if isFinalTrick || isAllInChase {
                    // В финале/аврале `wish` обычно силён, но при anti-premium давлении
                    // в all-in chase полезнее смещать выбор к немедленному контролю (`above`).
                    var bonus = 4.0 * (0.6 + 0.4 * immediateWinProbability)
                    if isAllInChase && !isFinalTrick && antiPremiumPressureContext {
                        bonus -= 2.5
                    }
                    return bonus
                }

                let controlLossPenalty = (8.0 + 8.0 * earlyPhaseWeight) * blindMultiplier
                let pressureRelief = 1.0 - 0.35 * context.chasePressure
                let noTrumpRelief = context.trump == nil ? 0.80 : 1.0
                let antiPremiumControlNeedMultiplier = antiPremiumPressureContext ? 1.15 : 1.0
                let lowReserveAmplifier = 0.85 + 0.35 * lowReserveNeedForImmediateControl
                return -controlLossPenalty *
                    pressureRelief *
                    noTrumpRelief *
                    antiPremiumControlNeedMultiplier *
                    lowReserveAmplifier
            }

            // В dump-режиме `wish` часто менее "контролирующий", чем `above`.
            var wishDumpBonus = (2.0 + 4.0 * earlyPhaseWeight) * (context.isBlindRound ? 1.05 : 1.0)
            if ownPremiumProtectionContext {
                wishDumpBonus -= 2.0
            }
            return wishDumpBonus

        case .above(let suit):
            let declaresTrump = context.trump == suit
            let matchesPreferredControlSuit = preferredControlSuit == suit

            if context.shouldChaseTrick {
                var bonus = (4.0 + 7.0 * earlyPhaseWeight + 3.0 * context.chasePressure) * blindMultiplier
                if declaresTrump {
                    bonus += 3.0
                }
                if matchesPreferredControlSuit {
                    bonus += 2.5 + 2.5 * preferredControlSuitStrength
                }
                if isFinalTrick {
                    bonus *= 0.55
                }
                if isAllInChase {
                    bonus *= 0.70
                }
                if antiPremiumPressureContext {
                    bonus += 2.5
                    if isAllInChase && !isFinalTrick {
                        bonus += 2.0
                    }
                }
                let lowReserveAmplifier = 0.90 + 0.30 * lowReserveNeedForImmediateControl
                return bonus * (0.65 + 0.35 * immediateWinProbability) * lowReserveAmplifier
            }

            var penalty = (3.0 + 5.0 * earlyPhaseWeight) * blindMultiplier
            if declaresTrump {
                penalty += 2.5
            }
            if let premium = context.matchContext?.premium,
               premium.isPremiumCandidateSoFar || premium.isZeroPremiumCandidateSoFar {
                penalty += 1.5
            }
            return -penalty

        case .takes(let suit):
            let declaresTrump = context.trump == suit
            let matchesPreferredControlSuit = preferredControlSuit == suit

            if context.shouldChaseTrick {
                // `takes` обычно слабее для контроля стола в chase, особенно в ранней фазе.
                var penalty = (5.0 + 8.0 * earlyPhaseWeight) * blindMultiplier
                if declaresTrump {
                    penalty += 2.0
                }
                if matchesPreferredControlSuit {
                    penalty += 1.5 + 1.5 * preferredControlSuitStrength
                }
                if isAllInChase {
                    penalty *= 1.15
                }
                if isFinalTrick {
                    penalty *= 0.75
                }
                let lowReserveAmplifier = 0.90 + 0.25 * lowReserveNeedForImmediateControl
                return -penalty * (0.65 + 0.35 * immediateWinProbability) * lowReserveAmplifier
            }

            // В dump `takes` часто полезен как controlled-loss lead.
            var bonus = (4.0 + 6.0 * earlyPhaseWeight) * blindMultiplier
            if declaresTrump {
                bonus -= 5.0
            } else {
                bonus += 3.0
            }
            if matchesPreferredControlSuit {
                // В dump чаще не хочется "сдавать" контроль по желаемой масти.
                bonus -= 1.5 + 1.5 * preferredControlSuitStrength
            }
            if isFinalTrick {
                bonus *= 0.70
            }
            if let premium = context.matchContext?.premium,
               premium.leftNeighborIsPremiumCandidateSoFar || premium.isPenaltyTargetRiskSoFar {
                // В anti-premium/penalty-aware контексте controlled-loss lead чуть ценнее.
                bonus += 1.5
            }
            if ownPremiumProtectionContext {
                bonus += 2.0
            }
            if context.trickDeltaToBidBeforeMove > 0 && !context.hasLosingNonJoker {
                // Stage 5 retune (JOKER-006): если бот уже перебрал и в руке нет безопасного
                // не-джокер сброса, `takes(non-trump)` должен заметнее выигрывать как controlled-loss lead.
                let overbidSeverity = min(2.0, Double(context.trickDeltaToBidBeforeMove))
                var controlledLossLeadBonus = (2.5 + 2.0 * earlyPhaseWeight) * overbidSeverity
                if !declaresTrump {
                    controlledLossLeadBonus += 1.0
                }
                bonus += controlledLossLeadBonus
            }
            let lowReserveAmplifier = 0.90 + 0.25 * lowReserveNeedForImmediateControl
            return bonus * (0.80 + 0.20 * (1.0 - immediateWinProbability)) * lowReserveAmplifier
        }
    }

    func isBetterCandidate(
        _ candidate: Evaluation,
        than current: Evaluation,
        shouldChaseTrick: Bool
    ) -> Bool {
        let tolerance = tuning.turnStrategy.utilityTieTolerance

        if candidate.utility > current.utility + tolerance {
            return true
        }
        if current.utility > candidate.utility + tolerance {
            return false
        }

        if shouldChaseTrick {
            if candidate.immediateWinProbability > current.immediateWinProbability + tolerance {
                return true
            }
            if current.immediateWinProbability > candidate.immediateWinProbability + tolerance {
                return false
            }
            if candidate.threat < current.threat - tolerance {
                return true
            }
            if current.threat < candidate.threat - tolerance {
                return false
            }
        } else {
            if candidate.immediateWinProbability < current.immediateWinProbability - tolerance {
                return true
            }
            if current.immediateWinProbability < candidate.immediateWinProbability - tolerance {
                return false
            }
            if candidate.threat > current.threat + tolerance {
                return true
            }
            if current.threat > candidate.threat + tolerance {
                return false
            }
        }

        // Детерминизм выбора при полном равенстве.
        if candidate.move.card != current.move.card {
            return candidate.move.card < current.move.card
        }
        return candidate.move.decision.style == .faceDown && current.move.decision.style == .faceUp
    }

    func moveUtility(
        projectedScore: Double,
        immediateWinProbability: Double,
        threat: Double,
        move: Move,
        leadControlReserveAfterMove: Double = 0.0,
        leadPreferredControlSuitAfterMove: Suit? = nil,
        leadPreferredControlSuitStrengthAfterMove: Double = 0.0,
        context: UtilityContext
    ) -> Double {
        let strategy = tuning.turnStrategy
        var utility = projectedScore
        utility += matchCatchUpUtilityAdjustment(
            immediateWinProbability: immediateWinProbability,
            threat: threat,
            context: context
        )
        utility += premiumPreserveUtilityAdjustment(
            immediateWinProbability: immediateWinProbability,
            context: context
        )
        utility += penaltyAvoidUtilityAdjustment(
            projectedScore: projectedScore,
            immediateWinProbability: immediateWinProbability,
            context: context
        )
        utility += premiumDenyUtilityAdjustment(
            immediateWinProbability: immediateWinProbability,
            context: context
        )
        utility += leadJokerDeclarationUtilityAdjustment(
            immediateWinProbability: immediateWinProbability,
            leadControlReserveAfterMove: leadControlReserveAfterMove,
            leadPreferredControlSuitAfterMove: leadPreferredControlSuitAfterMove,
            leadPreferredControlSuitStrengthAfterMove: leadPreferredControlSuitStrengthAfterMove,
            move: move,
            context: context
        )
        let blindRewardMultiplier = context.isBlindRound ? 1.55 : 1.0
        let blindRiskMultiplier = context.isBlindRound ? 1.30 : 1.0
        let isLeadJoker = move.card.isJoker && context.trick.playedCards.isEmpty
        let isNonFinalLeadWishJoker: Bool
        if isLeadJoker,
           move.decision.style == .faceUp,
           context.tricksRemainingIncludingCurrent > 1,
           case .some(.wish) = move.decision.leadDeclaration {
            isNonFinalLeadWishJoker = true
        } else {
            isNonFinalLeadWishJoker = false
        }

        if isNonFinalLeadWishJoker {
            // "wish" без заказа масти в ранних взятках ограничивает контроль стола.
            // В self-play и боевой логике смещаем выбор к "above"/"takes".
            let tricksAfterCurrent = max(1, context.tricksRemainingIncludingCurrent - 1)
            let basePenalty = 24.0 + Double(tricksAfterCurrent) * 6.0
            let chaseMultiplier = context.shouldChaseTrick ? (1.0 + context.chasePressure * 0.25) : 1.0
            let blindWishPenaltyMultiplier = context.isBlindRound ? 1.25 : 1.0
            utility -= basePenalty * chaseMultiplier * blindWishPenaltyMultiplier
        }

        if context.shouldChaseTrick {
            let conservatism = max(0.0, 1.0 - context.chasePressure)
            utility += immediateWinProbability *
                strategy.chaseWinProbabilityWeight *
                (1.0 + context.chasePressure) *
                blindRewardMultiplier
            utility -= threat *
                strategy.chaseThreatPenaltyWeight *
                conservatism *
                blindRiskMultiplier

            if move.card.isJoker && context.hasWinningNonJoker {
                utility -= strategy.chaseSpendJokerPenalty * conservatism * blindRiskMultiplier
            }

            if context.tricksNeededToMatchBid >= context.tricksRemainingIncludingCurrent {
                utility -= (1.0 - immediateWinProbability) *
                    strategy.chaseSpendJokerPenalty *
                    blindRiskMultiplier
            }

            if isLeadJoker {
                if case .some(.wish) = move.decision.leadDeclaration {
                    utility += strategy.chaseLeadWishBonus *
                        (0.5 + context.chasePressure * 0.5) *
                        (context.isBlindRound ? 1.15 : 1.0)
                }
            }
        } else {
            utility += (1.0 - immediateWinProbability) * strategy.dumpAvoidWinWeight * blindRewardMultiplier
            utility += threat * strategy.dumpThreatRewardWeight * blindRewardMultiplier

            if move.card.isJoker && context.hasLosingNonJoker {
                utility -= strategy.dumpSpendJokerPenalty * blindRiskMultiplier
            }
            if move.card.isJoker && move.decision.style == .faceUp && !context.trick.playedCards.isEmpty {
                utility -= strategy.dumpFaceUpNonLeadJokerPenalty * blindRiskMultiplier
            }

            if isLeadJoker, case .some(.takes(let suit)) = move.decision.leadDeclaration {
                if let trump = context.trump, suit != trump {
                    utility += strategy.dumpLeadTakesNonTrumpBonus * (context.isBlindRound ? 1.2 : 1.0)
                }
            }
        }

        return utility
    }

    func moveUtility(
        projectedScore: Double,
        immediateWinProbability: Double,
        threat: Double,
        move: Move,
        trickNode: TrickNode,
        trump: Suit?,
        shouldChaseTrick: Bool,
        hasWinningNonJoker: Bool,
        hasLosingNonJoker: Bool,
        tricksNeededToMatchBid: Int,
        tricksRemainingIncludingCurrent: Int,
        trickDeltaToBidBeforeMove: Int = 0,
        chasePressure: Double,
        leadControlReserveAfterMove: Double = 0.0,
        leadPreferredControlSuitAfterMove: Suit? = nil,
        leadPreferredControlSuitStrengthAfterMove: Double = 0.0,
        isBlindRound: Bool = false,
        matchContext: BotMatchContext? = nil
    ) -> Double {
        return moveUtility(
            projectedScore: projectedScore,
            immediateWinProbability: immediateWinProbability,
            threat: threat,
            move: move,
            leadControlReserveAfterMove: leadControlReserveAfterMove,
            leadPreferredControlSuitAfterMove: leadPreferredControlSuitAfterMove,
            leadPreferredControlSuitStrengthAfterMove: leadPreferredControlSuitStrengthAfterMove,
            context: .init(
                trick: .init(trickNode: trickNode),
                trump: trump,
                shouldChaseTrick: shouldChaseTrick,
                hasWinningNonJoker: hasWinningNonJoker,
                hasLosingNonJoker: hasLosingNonJoker,
                tricksNeededToMatchBid: tricksNeededToMatchBid,
                tricksRemainingIncludingCurrent: tricksRemainingIncludingCurrent,
                trickDeltaToBidBeforeMove: trickDeltaToBidBeforeMove,
                chasePressure: chasePressure,
                isBlindRound: isBlindRound,
                matchContext: matchContext
            )
        )
    }
}
