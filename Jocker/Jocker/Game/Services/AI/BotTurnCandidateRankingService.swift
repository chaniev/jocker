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

    /// Этап P1-1: компактная модель намерений соперников в текущей взятке/раунде.
    struct OpponentIntentionModel {
        struct OpponentSignal {
            let playerIndex: Int
            let needsTricks: Int
            let likelyToContestCurrentTrick: Double
            let denyPressure: Double
            let evidenceWeight: Double
        }

        let opponentSignals: [OpponentSignal]
        let strongestTargetIndex: Int?
        let strongestDenyPressure: Double
        let totalDenyPressure: Double
        let hasEvidence: Bool
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
        let roundState: BotMatchContext.RoundSnapshot?
        let actingPlayerIndex: Int?
        let remainingOpponentPlayerIndices: [Int]?
        let opponentIntention: OpponentIntentionModel?

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
            matchContext: BotMatchContext? = nil,
            roundState: BotMatchContext.RoundSnapshot? = nil,
            actingPlayerIndex: Int? = nil,
            remainingOpponentPlayerIndices: [Int]? = nil,
            opponentIntention: OpponentIntentionModel? = nil
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
            self.roundState = roundState
            self.actingPlayerIndex = actingPlayerIndex
            self.remainingOpponentPlayerIndices = remainingOpponentPlayerIndices
            self.opponentIntention = opponentIntention
        }
    }

    private let tuning: BotTuning
    private let rankingPolicy: BotRuntimePolicy.Ranking
    private let opponentModelingPolicy: BotRuntimePolicy.OpponentModeling
    private let jokerPolicy: BotTuning.JokerPolicy

    init(tuning: BotTuning) {
        self.tuning = tuning
        self.rankingPolicy = tuning.runtimePolicy.ranking
        self.opponentModelingPolicy = tuning.runtimePolicy.opponentModeling
        self.jokerPolicy = tuning.jokerPolicy
    }

    private struct BlockPlan {
        let urgency: Double
        let riskBudget: Double
        let preserveOwnPremiumBias: Double
        let denyOpponentPremiumBias: Double
    }

    /// Этап P0-2: компактный block-level план для управления агрессией/консервативностью.
    private func blockPlan(from matchContext: BotMatchContext?) -> BlockPlan? {
        guard let matchContext else { return nil }
        guard matchContext.playerCount > 1 else { return nil }
        guard matchContext.playerIndex >= 0, matchContext.playerIndex < matchContext.playerCount else { return nil }
        guard matchContext.totalScores.count >= matchContext.playerCount else { return nil }

        let ownScore = matchContext.totalScores[matchContext.playerIndex]
        let opponentScores = matchContext.totalScores.enumerated()
            .filter { $0.offset != matchContext.playerIndex }
            .map(\.element)
        guard let leaderScore = matchContext.totalScores.max(), !opponentScores.isEmpty else { return nil }

        let bestOpponentScore = opponentScores.max() ?? ownScore
        let behindLeader = max(0, leaderScore - ownScore)
        let safeLead = max(0, ownScore - bestOpponentScore)

        let scoreScale = matchContext.block == .fourth ? rankingPolicy.fourthBlockScoreScale : rankingPolicy.standardBlockScoreScale
        let behindSignal = min(1.0, Double(behindLeader) / scoreScale)
        let leadSignal = min(1.0, Double(safeLead) / scoreScale)
        let blockWeight = matchContext.block == .fourth ? rankingPolicy.fourthBlockWeight : 1.0

        let premium = matchContext.premium
        let preserveOwnPremiumBias: Double = {
            guard let premium else { return 0.0 }
            guard premium.isPremiumCandidateSoFar || premium.isZeroPremiumCandidateSoFar else { return 0.0 }
            return rankingPolicy.premiumPreserveBase + rankingPolicy.premiumPreserveProgressWeight * matchContext.blockProgressFraction
        }()
        let denyOpponentPremiumBias: Double = {
            guard let premium else { return 0.0 }
            guard premium.leftNeighborIsPremiumCandidateSoFar ||
                    premium.isPenaltyTargetRiskSoFar ||
                    premium.opponentPremiumCandidatesSoFarCount > 0 else {
                return 0.0
            }
            return rankingPolicy.denyPremiumBase + rankingPolicy.denyPremiumProgressWeight * matchContext.blockProgressFraction
        }()

        var riskBudget = (behindSignal - leadSignal) * blockWeight
        let baseActivationWeight = rankingPolicy.baseActivationWeight + rankingPolicy.progressActivationWeight * matchContext.blockProgressFraction
        let roundsRemainingForActivation = max(0, matchContext.totalRoundsInBlock - matchContext.roundIndexInBlock - 1)
        let finalRoundsActivationBoost: Double
        switch roundsRemainingForActivation {
        case 0...1:
            finalRoundsActivationBoost = rankingPolicy.finalRoundsActivationFull
        case 2:
            finalRoundsActivationBoost = rankingPolicy.finalRoundsActivationHalf
        default:
            finalRoundsActivationBoost = baseActivationWeight
        }
        riskBudget *= min(1.0, max(0.0, finalRoundsActivationBoost))
        riskBudget = min(1.0, max(-1.0, riskBudget))

        let roundsRemaining: Int = {
            if let premium {
                return max(0, premium.remainingRoundsInBlock)
            }
            let estimated = matchContext.totalRoundsInBlock - matchContext.roundIndexInBlock - 1
            return max(0, estimated)
        }()
        let endgameUrgency: Double
        switch roundsRemaining {
        case 0...1:
            endgameUrgency = rankingPolicy.endgameUrgencyFull
        case 2:
            endgameUrgency = rankingPolicy.endgameUrgencyTwoRounds
        case 3:
            endgameUrgency = rankingPolicy.endgameUrgencyThreeRounds
        default:
            endgameUrgency = rankingPolicy.endgameUrgencyDefault
        }
        let urgency = min(
            1.0,
            max(
                0.0,
                max(
                    abs(riskBudget) * rankingPolicy.riskBudgetWeight,
                    endgameUrgency * rankingPolicy.endgameUrgencyWeight +
                        matchContext.blockProgressFraction * rankingPolicy.blockProgressWeight +
                        max(preserveOwnPremiumBias, denyOpponentPremiumBias) * rankingPolicy.premiumBiasWeight
                )
            )
        )

        return BlockPlan(
            urgency: urgency,
            riskBudget: riskBudget,
            preserveOwnPremiumBias: preserveOwnPremiumBias,
            denyOpponentPremiumBias: denyOpponentPremiumBias
        )
    }

    /// Этап P0-2: block-level utility надбавка (risk budget + urgency).
    private func matchCatchUpUtilityAdjustment(
        projectedScore: Double,
        immediateWinProbability: Double,
        threat: Double,
        context: UtilityContext
    ) -> Double {
        guard let plan = blockPlan(from: context.matchContext) else { return 0.0 }
        guard abs(plan.riskBudget) > rankingPolicy.utilityTieTolerance else { return 0.0 }

        let chaseAggressionSignal =
            immediateWinProbability * rankingPolicy.matchCatchUpChaseAggressionBase -
            threat * rankingPolicy.matchCatchUpChaseAggressionThreatWeight +
            context.chasePressure * rankingPolicy.matchCatchUpChaseAggressionPressureWeight
        let finalTrickUrgencyBonus = context.tricksNeededToMatchBid >= context.tricksRemainingIncludingCurrent && context.shouldChaseTrick
            ? rankingPolicy.matchCatchUpFinalTrickUrgencyBonus
            : 0.0
        let opponentUrgencyMultiplier = opponentMatchCatchUpUrgencyMultiplier(from: context.matchContext)
        let urgencyWeight = rankingPolicy.matchCatchUpOpponentUrgencyBase + rankingPolicy.matchCatchUpUrgencyWeightProgress * plan.urgency

        if context.shouldChaseTrick {
            var adjustment = plan.riskBudget *
                opponentUrgencyMultiplier *
                (chaseAggressionSignal + finalTrickUrgencyBonus) *
                urgencyWeight
            if plan.preserveOwnPremiumBias > 0, context.trickDeltaToBidBeforeMove >= 0 {
                adjustment -= immediateWinProbability * rankingPolicy.matchCatchUpPreservePremiumPenalty * plan.preserveOwnPremiumBias
            }
            return adjustment
        }

        let conservativeDumpSignal =
            (1.0 - immediateWinProbability) * rankingPolicy.matchCatchUpConservativeDumpBase +
            threat * rankingPolicy.matchCatchUpConservativeDumpThreatWeight +
            max(0.0, projectedScore) * rankingPolicy.matchCatchUpConservativeDumpScoreWeight
        var adjustment = (-plan.riskBudget) *
            opponentUrgencyMultiplier *
            conservativeDumpSignal *
            (rankingPolicy.matchCatchUpUrgencyWeightBase + rankingPolicy.matchCatchUpUrgencyWeightProgress * urgencyWeight)
        if plan.denyOpponentPremiumBias > 0 {
            adjustment -=
                (1.0 - immediateWinProbability) *
                rankingPolicy.matchCatchUpDenyOpponentPenaltyBase *
                plan.denyOpponentPremiumBias
        }
        return adjustment
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

        let evidenceWeight = rankingPolicy.premiumPreserveEvidenceBase + rankingPolicy.premiumPreserveEvidenceProgress * min(
            1.0,
            Double(max(0, premium.completedRoundsInBlock)) /
                Double(max(1, matchContext.totalRoundsInBlock - 1))
        )
        let closingRoundsWeight: Double
        switch premium.remainingRoundsInBlock {
        case ...1:
            closingRoundsWeight = rankingPolicy.premiumPreserveClosingRoundsWeight
        case 2:
            closingRoundsWeight = rankingPolicy.premiumPreserveClosingRoundsTwo
        default:
            closingRoundsWeight = rankingPolicy.premiumPreserveClosingRoundsDefault
        }
        let progressWeight = (rankingPolicy.premiumPreserveProgressBase + rankingPolicy.premiumPreserveEvidenceProgressWeight * matchContext.blockProgressFraction) * evidenceWeight * closingRoundsWeight
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
                let trajectoryMultiplier = mustWinAllRemaining ? rankingPolicy.premiumPreserveMustWinAllMultiplier : 1.0
                // Если одновременно релевантен zero-premium, избегаем ситуации, где обычный
                // premium-chase бонус полностью "перебивает" zero-premium осторожность.
                let zeroPremiumConflictDampener = premium.isZeroPremiumCandidateSoFar ? rankingPolicy.premiumPreserveZeroConflictDampener : 1.0
                adjustment += immediateWinProbability *
                    (rankingPolicy.premiumPreserveChaseBonusBase + rankingPolicy.premiumPreserveChaseBonusProgress * deficitUrgency) *
                    progressWeight *
                    trajectoryMultiplier *
                    zeroPremiumConflictDampener
            } else {
                let exactBidPreserveMultiplier = isExactlyOnBidBeforeMove ? rankingPolicy.premiumPreserveExactBidMultiplier : 1.0
                let alreadyBrokenMultiplier = hasAlreadyBrokenRoundExactBid ? rankingPolicy.premiumPreserveAlreadyBrokenMultiplier : 1.0
                adjustment += (1.0 - immediateWinProbability) *
                    rankingPolicy.premiumPreserveDumpBonus *
                    progressWeight *
                    exactBidPreserveMultiplier *
                    alreadyBrokenMultiplier
            }
        }

        if premium.isZeroPremiumCandidateSoFar {
            if context.shouldChaseTrick {
                let alreadyBrokenMultiplier = hasAlreadyBrokenRoundExactBid ? rankingPolicy.premiumPreserveZeroAlreadyBrokenMultiplier : 1.0
                adjustment -= immediateWinProbability * rankingPolicy.premiumPreserveZeroChasePenalty * progressWeight * alreadyBrokenMultiplier
            } else {
                let exactZeroProtectMultiplier = isExactlyOnBidBeforeMove ? rankingPolicy.premiumPreserveExactZeroMultiplier : 1.0
                let alreadyBrokenMultiplier = hasAlreadyBrokenRoundExactBid ? rankingPolicy.premiumPreserveZeroAlreadyBrokenMultiplier : 1.0
                adjustment += (1.0 - immediateWinProbability) *
                    rankingPolicy.premiumPreserveZeroDumpBonus *
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

        let threatCountWeight = min(rankingPolicy.penaltyAvoidThreatCountMax, rankingPolicy.penaltyAvoidThreatCountMin + rankingPolicy.penaltyAvoidThreatCountProgress * Double(premium.premiumCandidatesThreateningPenaltyCount))
        let evidenceWeight = rankingPolicy.penaltyAvoidEvidenceBase + rankingPolicy.penaltyAvoidEvidenceProgress * min(
            1.0,
            Double(max(0, premium.completedRoundsInBlock)) /
                Double(max(1, matchContext.totalRoundsInBlock - 1))
        )
        let endBlockWeight = rankingPolicy.penaltyAvoidEndBlockBase + rankingPolicy.penaltyAvoidEndBlockProgress * matchContext.blockProgressFraction
        let opponentStyleMultiplier = opponentPremiumDenyPressureMultiplier(from: matchContext)
        let riskWeight = threatCountWeight * evidenceWeight * endBlockWeight * opponentStyleMultiplier
        // Retune (Stage 4c/6): усиливаем penalty-avoid в поздней части блока,
        // чтобы реже сохранять штрафоопасную траекторию соперников.
        let lateBlockPenaltyAvoidBoost = 1.0 + rankingPolicy.penaltyAvoidLateBlockBoost * matchContext.blockProgressFraction

        var adjustment = 0.0
        let positiveProjectedScore = max(0.0, projectedScore)
        if positiveProjectedScore > 0 {
            adjustment -= positiveProjectedScore * rankingPolicy.penaltyAvoidProjectedScoreWeight * riskWeight
        }

        if context.shouldChaseTrick {
            if context.trickDeltaToBidBeforeMove > 0 {
                // Уже вышли в overbid и продолжаем добирать: при риске штрафа это особенно плохо.
                adjustment -= immediateWinProbability * rankingPolicy.penaltyAvoidOverbidPenalty * riskWeight * lateBlockPenaltyAvoidBoost
            }
        } else {
            // В режиме dump под риском штрафа чуть сильнее поощряем безопасный проигрыш взятки.
            adjustment += (1.0 - immediateWinProbability) * rankingPolicy.penaltyAvoidDumpBonus * riskWeight * lateBlockPenaltyAvoidBoost
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
        guard premium.leftNeighborIsPremiumCandidateSoFar || premium.opponentPremiumCandidatesSoFarCount > 0 else {
            return 0.0
        }

        // Приоритет защиты своей премии/zero-premium остаётся за этапом 4b.
        if premium.isPremiumCandidateSoFar || premium.isZeroPremiumCandidateSoFar {
            return 0.0
        }

        let evidenceWeight = rankingPolicy.premiumDenyEvidenceBase + rankingPolicy.premiumDenyEvidenceProgress * min(
            1.0,
            Double(max(0, premium.completedRoundsInBlock)) /
                Double(max(1, matchContext.totalRoundsInBlock - 1))
        )
        let endBlockWeight = rankingPolicy.premiumDenyEndBlockBase + rankingPolicy.premiumDenyEndBlockProgress * matchContext.blockProgressFraction
        let leftNeighborWeight = premium.leftNeighborIsPremiumCandidateSoFar ? rankingPolicy.premiumDenyLeftNeighborWeight : 0.0
        let otherOpponentCandidates = max(
            0,
            premium.opponentPremiumCandidatesSoFarCount - (premium.leftNeighborIsPremiumCandidateSoFar ? 1 : 0)
        )
        let otherOpponentsWeight = min(rankingPolicy.premiumDenyOtherOpponentsMax, Double(otherOpponentCandidates) * rankingPolicy.premiumDenyOtherOpponentsWeight)
        let opponentStyleMultiplier = opponentPremiumDenyPressureMultiplier(from: matchContext)
        let denyWeight = (leftNeighborWeight + otherOpponentsWeight) *
            evidenceWeight *
            endBlockWeight *
            opponentStyleMultiplier
        guard denyWeight > 0 else { return 0.0 }
        let overbidRelaxation = context.trickDeltaToBidBeforeMove > 0 ? rankingPolicy.premiumDenyOverbidRelaxation : 1.0

        if context.shouldChaseTrick {
            return immediateWinProbability * rankingPolicy.premiumDenyChaseBonus * denyWeight * overbidRelaxation
        }

        // В dump-режиме уменьшаем привлекательность "безопасного проигрыша взятки",
        // если это может сохранять премиальную линию соседа слева.
        return -(1.0 - immediateWinProbability) * rankingPolicy.premiumDenyDumpPenalty * denyWeight * overbidRelaxation
    }

    /// Этап 6b (MVP): лёгкая калибровка anti-premium давления по наблюдаемому стилю.
    /// Положительный multiplier усиливает `premiumDenyUtility` против дисциплинированного/
    /// агрессивного соперника; при нулевой/слабой evidence эффект нейтральный.
    private func opponentPremiumDenyPressureMultiplier(from matchContext: BotMatchContext) -> Double {
        guard let opponents = matchContext.opponents else { return 1.0 }

        let prioritizedSnapshots: [BotOpponentModel.OpponentSnapshot]
        if let leftNeighborIndex = opponents.leftNeighborIndex,
           let leftNeighborSnapshot = opponents.snapshot(for: leftNeighborIndex) {
            prioritizedSnapshots = [leftNeighborSnapshot]
        } else {
            prioritizedSnapshots = opponents.snapshots
        }
        guard !prioritizedSnapshots.isEmpty else { return 1.0 }

        let evidenceSaturationRounds = Double(max(1, min(matchContext.totalRoundsInBlock, opponentModelingPolicy.opponentStyleEvidenceSaturationRounds)))
        var weightedStyleSignal = 0.0
        var totalWeight = 0.0

        for snapshot in prioritizedSnapshots {
            let observedRounds = max(0, snapshot.observedRounds)
            guard observedRounds > 0 else { continue }

            let evidenceWeight = min(1.0, Double(observedRounds) / evidenceSaturationRounds)
            guard evidenceWeight > 0 else { continue }

            let exact = min(1.0, max(0.0, snapshot.exactBidRate))
            let over = min(1.0, max(0.0, snapshot.overbidRate))
            let under = min(1.0, max(0.0, snapshot.underbidRate))
            let blind = min(1.0, max(0.0, snapshot.blindBidRate))
            let aggression = min(1.0, max(0.0, snapshot.averageBidAggression))

            let disciplineSignal = exact - opponentModelingPolicy.opponentStyleExactBase * (over + under)
            let aggressionSignal = aggression - opponentModelingPolicy.opponentStyleAggressionBase
            let blindPressureSignal = blind - opponentModelingPolicy.opponentStyleBlindBase
            let styleSignal =
                disciplineSignal * opponentModelingPolicy.opponentStyleDisciplineWeight +
                aggressionSignal * opponentModelingPolicy.opponentStyleAggressionWeight +
                blindPressureSignal * opponentModelingPolicy.opponentStyleBlindPressureWeight

            weightedStyleSignal += styleSignal * evidenceWeight
            totalWeight += evidenceWeight
        }

        guard totalWeight > 0 else { return 1.0 }
        let normalizedSignal = weightedStyleSignal / totalWeight
        return min(opponentModelingPolicy.opponentStyleMultiplierMax, max(opponentModelingPolicy.opponentStyleMultiplierMin, 1.0 + normalizedSignal))
    }

    /// Stage 6b: более мягкая версия style-signal для lead-joker anti-premium корректировок.
    /// Нам нужен заметный, но не "ломающий" JOKER-эвристику сдвиг.
    private func opponentLeadJokerAntiPremiumMultiplier(from matchContext: BotMatchContext?) -> Double {
        guard let matchContext else { return 1.0 }
        let denyPressureMultiplier = opponentPremiumDenyPressureMultiplier(from: matchContext)
        return 1.0 + (denyPressureMultiplier - 1.0) * opponentModelingPolicy.opponentLeadJokerAntiPremiumWeight
    }

    /// Stage 6b: очень мягкая калибровка match catch-up urgency по opponent-style сигналу.
    /// Нам важно не сломать score-based bias, а только слегка усилить/ослабить его поздно в блоке.
    private func opponentMatchCatchUpUrgencyMultiplier(from matchContext: BotMatchContext?) -> Double {
        guard let matchContext else { return 1.0 }
        let denyPressureMultiplier = opponentPremiumDenyPressureMultiplier(from: matchContext)
        let lateBlockWeight = opponentModelingPolicy.opponentLateBlockWeightBase + opponentModelingPolicy.opponentLateBlockWeightProgress * matchContext.blockProgressFraction
        return 1.0 + (denyPressureMultiplier - 1.0) * opponentModelingPolicy.opponentMatchCatchUpUrgencyWeight * lateBlockWeight
    }

    /// Stage 6b: очень мягкая blind-chase калибровка.
    /// Усиливает награду за "боевой" blind-chase против дисциплинированных/агрессивных соперников.
    private func opponentBlindChaseContestMultiplier(from matchContext: BotMatchContext?) -> Double {
        guard let matchContext else { return 1.0 }
        let denyPressureMultiplier = opponentPremiumDenyPressureMultiplier(from: matchContext)
        let lateBlockWeight = opponentModelingPolicy.opponentLateBlockWeightBase + opponentModelingPolicy.opponentLateBlockWeightProgress * matchContext.blockProgressFraction
        return 1.0 + (denyPressureMultiplier - 1.0) * opponentModelingPolicy.opponentBlindChaseContestWeight * lateBlockWeight
    }

    private func opponentDisciplineSignal(from matchContext: BotMatchContext?) -> Double {
        guard let matchContext, let opponents = matchContext.opponents else { return 0.5 }
        let prioritizedSnapshots: [BotOpponentModel.OpponentSnapshot]
        if let leftNeighborIndex = opponents.leftNeighborIndex,
           let leftNeighborSnapshot = opponents.snapshot(for: leftNeighborIndex) {
            prioritizedSnapshots = [leftNeighborSnapshot]
        } else {
            prioritizedSnapshots = opponents.snapshots
        }
        guard let snapshot = prioritizedSnapshots.first, snapshot.observedRounds > 0 else {
            return 0.5
        }

        let exact = min(1.0, max(0.0, snapshot.exactBidRate))
        let over = min(1.0, max(0.0, snapshot.overbidRate))
        let under = min(1.0, max(0.0, snapshot.underbidRate))
        let rawSignal = exact - 0.5 * (over + under)
        return clamped(0.5 + 0.5 * rawSignal, min: 0.0, max: 1.0)
    }

    /// Этап P1-2: pressure от раундового дефицита соперников (`needsTricks == 1`)
    /// с локальным фокусом на следующем по ходу/левом соседе.
    private func opponentBidPressureUtilityAdjustment(
        immediateWinProbability: Double,
        context: UtilityContext
    ) -> Double {
        guard let roundState = context.roundState else { return 0.0 }

        let resolvedPlayerCount = context.matchContext?.playerCount ?? roundState.bids.count
        guard resolvedPlayerCount > 1 else { return 0.0 }

        let actingPlayerIndex: Int = {
            if let explicit = context.actingPlayerIndex {
                return normalizedPlayerIndex(explicit, playerCount: resolvedPlayerCount)
            }
            if let fromMatchContext = context.matchContext?.playerIndex {
                return normalizedPlayerIndex(fromMatchContext, playerCount: resolvedPlayerCount)
            }
            return 0
        }()

        let leftNeighborIndex = context.matchContext?.premium?.leftNeighborIndex.map {
            normalizedPlayerIndex($0, playerCount: resolvedPlayerCount)
        }
        let nextOpponentIndex = context.remainingOpponentPlayerIndices?.first.map {
            normalizedPlayerIndex($0, playerCount: resolvedPlayerCount)
        }
        let opponents = (0..<resolvedPlayerCount).filter { $0 != actingPlayerIndex }

        var pressure = 0.0
        for opponentIndex in opponents {
            guard let needs = roundState.needsTricks(for: opponentIndex) else { continue }
            guard needs == 1 else { continue }

            var weight = 0.0
            if opponentIndex == nextOpponentIndex {
                weight = max(weight, opponentModelingPolicy.opponentBidPressureNextWeight)
            }
            if opponentIndex == leftNeighborIndex {
                weight = max(weight, opponentModelingPolicy.opponentBidPressureLeftNeighborWeight)
            }
            if weight == 0 {
                weight = opponentModelingPolicy.opponentBidPressureOtherWeight
            }
            pressure += weight
        }

        guard pressure > 0 else { return 0.0 }
        let normalizedPressure = min(opponentModelingPolicy.opponentBidPressureMax, pressure)

        if context.shouldChaseTrick {
            // Нужно добирать: чуть сильнее ценим контроль текущей взятки, если он ломает exact-линию соперника.
            return immediateWinProbability * (opponentModelingPolicy.opponentBidPressureChaseBase + opponentModelingPolicy.opponentBidPressureChaseProgress * normalizedPressure)
        }

        // Режим dump: избегаем "безопасного" проигрыша, который отдает точный добор сопернику.
        return -(1.0 - immediateWinProbability) * (opponentModelingPolicy.opponentBidPressureDumpBase + opponentModelingPolicy.opponentBidPressureDumpProgress * normalizedPressure)
    }

    /// Этап P1-1: надбавка по compact intention-model.
    /// При отсутствии evidence должна быть нейтральной.
    private func opponentIntentionUtilityAdjustment(
        immediateWinProbability: Double,
        context: UtilityContext
    ) -> Double {
        guard let intention = context.opponentIntention else { return 0.0 }
        guard intention.hasEvidence else { return 0.0 }

        let strongest = max(0.0, intention.strongestDenyPressure)
        let aggregate = max(0.0, intention.totalDenyPressure)
        guard strongest > 0 || aggregate > 0 else { return 0.0 }

        let pressure = min(opponentModelingPolicy.opponentIntentionPressureMax, strongest + aggregate * opponentModelingPolicy.opponentIntentionAggregateWeight)
        if context.shouldChaseTrick {
            return immediateWinProbability * (opponentModelingPolicy.opponentIntentionChaseBase + opponentModelingPolicy.opponentIntentionChaseProgress * pressure)
        }

        return -(1.0 - immediateWinProbability) * (opponentModelingPolicy.opponentIntentionDumpBase + opponentModelingPolicy.opponentIntentionDumpProgress * pressure)
    }

    private func normalizedPlayerIndex(_ value: Int, playerCount: Int) -> Int {
        guard playerCount > 0 else { return 0 }
        return ((value % playerCount) + playerCount) % playerCount
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
        let antiPremiumStyleMultiplier = antiPremiumPressureContext
            ? opponentLeadJokerAntiPremiumMultiplier(from: context.matchContext)
            : 1.0

        switch declaration {
        case .wish:
            if context.shouldChaseTrick {
                if isFinalTrick || isAllInChase {
                    // В финале/аврале `wish` обычно силён, но при anti-premium давлении
                    // в all-in chase полезнее смещать выбор к немедленному контролю (`above`).
                    var bonus = 4.0 * (0.6 + 0.4 * immediateWinProbability)
                    if isAllInChase && !isFinalTrick && antiPremiumPressureContext {
                        bonus -= 2.5 * antiPremiumStyleMultiplier
                    }
                    return bonus
                }

                let controlLossPenalty = (8.0 + 8.0 * earlyPhaseWeight) * blindMultiplier
                let pressureRelief = 1.0 - 0.35 * context.chasePressure
                let noTrumpRelief = context.trump == nil ? 0.80 : 1.0
                let antiPremiumControlNeedMultiplier = antiPremiumPressureContext ? 1.15 : 1.0
                let lowReserveAmplifier = 0.85 + 0.35 * lowReserveNeedForImmediateControl
                let highReserveWishRelief = 2.0 * controlReserve * (0.4 + 0.6 * earlyPhaseWeight)
                return -controlLossPenalty *
                    pressureRelief *
                    noTrumpRelief *
                    antiPremiumControlNeedMultiplier *
                    lowReserveAmplifier +
                    highReserveWishRelief
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
                    bonus += 2.5 * antiPremiumStyleMultiplier
                    if isAllInChase && !isFinalTrick {
                        bonus += 2.0 * antiPremiumStyleMultiplier
                    }
                }
                let lowReserveAmplifier = 0.90 + 0.30 * lowReserveNeedForImmediateControl
                let highReserveAboveRelaxation = isAllInChase ? 1.0 : (1.0 - 0.12 * controlReserve)
                return bonus *
                    (0.65 + 0.35 * immediateWinProbability) *
                    lowReserveAmplifier *
                    highReserveAboveRelaxation
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
                bonus += 1.5 * antiPremiumStyleMultiplier
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

    private struct CompositeUtilityComponents {
        let base: Double
        let tactical: Double
        let risk: Double
        let opponent: Double
        let joker: Double
    }

    private func clamped(
        _ value: Double,
        min lowerBound: Double,
        max upperBound: Double
    ) -> Double {
        return min(upperBound, max(lowerBound, value))
    }

    private func leadJokerGoalOrientedUtilityAdjustment(
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

        let controlReserve = clamped(leadControlReserveAfterMove, min: 0.0, max: 1.0)
        let preferredControlSuitStrength = clamped(
            leadPreferredControlSuitStrengthAfterMove,
            min: 0.0,
            max: 1.0
        )
        let lowReserveNeed = 1.0 - controlReserve
        let isAllInChase = context.shouldChaseTrick &&
            context.tricksNeededToMatchBid >= context.tricksRemainingIncludingCurrent
        let isPenaltyRiskContext = context.matchContext?.premium.map {
            $0.isPenaltyTargetRiskSoFar && $0.premiumCandidatesThreateningPenaltyCount > 0
        } ?? false
        let antiPremiumContext = context.matchContext?.premium.map {
            $0.leftNeighborIsPremiumCandidateSoFar ||
                $0.opponentPremiumCandidatesSoFarCount > 0 ||
                $0.isPenaltyTargetRiskSoFar
        } ?? false

        let secureTrick: Double
        let preserveControl: Double
        let controlledLoss: Double
        switch declaration {
        case .wish:
            secureTrick = context.shouldChaseTrick
                ? clamped(0.62 + 0.38 * immediateWinProbability, min: 0.0, max: 1.0)
                : 0.34
            preserveControl = clamped(0.38 + 0.30 * controlReserve, min: 0.0, max: 1.0)
            controlledLoss = context.shouldChaseTrick ? 0.0 : 0.32
        case .above(let suit):
            let declaresTrump = context.trump == suit
            let matchesPreferredSuit = leadPreferredControlSuitAfterMove == suit
            secureTrick = clamped(
                0.54 +
                    (context.shouldChaseTrick ? 0.18 : 0.0) +
                    (declaresTrump ? 0.16 : 0.0) +
                    (matchesPreferredSuit ? 0.08 + 0.10 * preferredControlSuitStrength : 0.0),
                min: 0.0,
                max: 1.0
            )
            preserveControl = clamped(
                0.42 +
                    (declaresTrump ? 0.14 : 0.0) +
                    (matchesPreferredSuit ? 0.10 + 0.12 * preferredControlSuitStrength : 0.0) +
                    0.14 * lowReserveNeed,
                min: 0.0,
                max: 1.0
            )
            controlledLoss = context.shouldChaseTrick ? 0.0 : (declaresTrump ? 0.14 : 0.24)
        case .takes(let suit):
            let declaresTrump = context.trump == suit
            let nonTrumpTakes = context.trump.map { $0 != suit } ?? true
            secureTrick = context.shouldChaseTrick
                ? clamped(0.28 + (declaresTrump ? 0.08 : 0.0), min: 0.0, max: 1.0)
                : 0.16
            preserveControl = clamped(
                0.18 +
                    (declaresTrump ? -0.10 : 0.0) +
                    (nonTrumpTakes ? 0.04 : 0.0) +
                    0.10 * lowReserveNeed,
                min: 0.0,
                max: 1.0
            )
            controlledLoss = context.shouldChaseTrick
                ? 0.0
                : clamped(
                    0.54 +
                        (nonTrumpTakes ? 0.18 : -0.12) +
                        (isPenaltyRiskContext ? 0.10 : 0.0),
                    min: 0.0,
                    max: 1.0
                )
        }

        let secureWeight: Double
        let controlWeight: Double
        let controlledLossWeight: Double
        if context.shouldChaseTrick {
            secureWeight = clamped(
                0.52 + 0.34 * context.chasePressure + (isAllInChase ? 0.14 : 0.0),
                min: 0.0,
                max: 1.0
            )
            controlWeight = clamped(
                0.26 + 0.22 * lowReserveNeed + (antiPremiumContext ? 0.10 : 0.0),
                min: 0.0,
                max: 1.0
            )
            controlledLossWeight = -0.18
        } else {
            secureWeight = -0.14
            controlWeight = 0.20 + (antiPremiumContext ? 0.06 : 0.0)
            controlledLossWeight = clamped(
                0.58 + (isPenaltyRiskContext ? 0.18 : 0.0),
                min: 0.0,
                max: 1.0
            )
        }

        let weightedGoalScore =
            secureTrick * secureWeight +
            preserveControl * controlWeight +
            controlledLoss * controlledLossWeight
        let scale: Double = context.shouldChaseTrick
            ? (10.0 + 7.0 * context.chasePressure)
            : (9.0 + 6.0 * (1.0 - immediateWinProbability))
        return weightedGoalScore * scale
    }

    private func composeUtility(
        components: CompositeUtilityComponents,
        immediateWinProbability: Double,
        threat: Double,
        move: Move,
        context: UtilityContext
    ) -> Double {
        let blockUrgency = context.matchContext?.blockProgressFraction ?? 0.0
        let urgency = clamped(
            0.58 * context.chasePressure + 0.42 * blockUrgency,
            min: 0.0,
            max: 1.0
        )
        let penaltyRisk = context.matchContext?.premium?.isPenaltyTargetRiskSoFar == true
        let hasOpponentEvidence = context.opponentIntention?.hasEvidence == true

        let tacticalMultiplier = clamped(
            1.0 + 0.04 * urgency + (context.shouldChaseTrick ? 0.03 : 0.0),
            min: 0.95,
            max: 1.10
        )
        let riskMultiplier = clamped(
            1.0 + 0.08 * urgency + (penaltyRisk ? 0.06 : 0.0),
            min: 0.94,
            max: 1.18
        )
        let opponentMultiplier = clamped(
            1.0 + 0.06 * urgency + (hasOpponentEvidence ? 0.05 : 0.0),
            min: 0.95,
            max: 1.16
        )
        let jokerMultiplier = move.card.isJoker
            ? clamped(
                1.0 + 0.10 * urgency + (context.shouldChaseTrick ? 0.05 : 0.06),
                min: 0.90,
                max: 1.22
            )
            : 1.0

        let cappedTactical = clamped(components.tactical, min: -180.0, max: 180.0)
        let cappedRisk = clamped(components.risk, min: -180.0, max: 180.0)
        let cappedOpponent = clamped(components.opponent, min: -120.0, max: 120.0)
        let cappedJoker = clamped(components.joker, min: -180.0, max: 180.0)

        let composed =
            components.base +
            cappedTactical * tacticalMultiplier +
            cappedRisk * riskMultiplier +
            cappedOpponent * opponentMultiplier +
            cappedJoker * jokerMultiplier

        // Не даём композиции сносить базовую шкалу в крайних комбинациях сигналов.
        let baselineAnchor = components.base + cappedTactical + cappedRisk + cappedOpponent + cappedJoker
        let stabilizationWindow = 90.0 + 50.0 * (1.0 - immediateWinProbability) + 0.15 * threat
        let minValue = baselineAnchor - stabilizationWindow
        let maxValue = baselineAnchor + stabilizationWindow
        return clamped(composed, min: minValue, max: maxValue)
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
        let joker = jokerPolicy
        let premiumSnapshot = context.matchContext?.premium
        let isOwnPremiumProtectionContext = premiumSnapshot.map {
            $0.isPremiumCandidateSoFar || $0.isZeroPremiumCandidateSoFar
        } ?? false
        let hasOpponentPremiumPressureContext = premiumSnapshot.map {
            $0.leftNeighborIsPremiumCandidateSoFar || $0.opponentPremiumCandidatesSoFarCount > 0
        } ?? false
        let isPenaltyTargetRiskContext = premiumSnapshot.map {
            $0.isPenaltyTargetRiskSoFar && $0.premiumCandidatesThreateningPenaltyCount > 0
        } ?? false
        let isLeadFaceUpDeclaredJoker =
            move.card.isJoker &&
            context.trick.playedCards.isEmpty &&
            move.decision.style == .faceUp &&
            move.decision.leadDeclaration != nil
        let matchCatchUpAdjustment = matchCatchUpUtilityAdjustment(
            projectedScore: projectedScore,
            immediateWinProbability: immediateWinProbability,
            threat: threat,
            context: context
        )
        let premiumPreserveAdjustment = premiumPreserveUtilityAdjustment(
            immediateWinProbability: immediateWinProbability,
            context: context
        )
        let opponentBidPressureAdjustment = opponentBidPressureUtilityAdjustment(
            immediateWinProbability: immediateWinProbability,
            context: context
        )
        let opponentIntentionAdjustment = opponentIntentionUtilityAdjustment(
            immediateWinProbability: immediateWinProbability,
            context: context
        )

        let penaltyAvoidAdjustment: Double
        let premiumDenyAdjustment: Double
        if !isLeadFaceUpDeclaredJoker {
            // Stage 5 already models anti-premium declaration shifts for lead face-up joker.
            // Skipping generic anti-premium utilities here avoids double-counting the same signal.
            penaltyAvoidAdjustment = penaltyAvoidUtilityAdjustment(
                projectedScore: projectedScore,
                immediateWinProbability: immediateWinProbability,
                context: context
            )
            premiumDenyAdjustment = premiumDenyUtilityAdjustment(
                immediateWinProbability: immediateWinProbability,
                context: context
            )
        } else {
            penaltyAvoidAdjustment = 0.0
            premiumDenyAdjustment = 0.0
        }

        let leadJokerDeclarationAdjustment = leadJokerDeclarationUtilityAdjustment(
            immediateWinProbability: immediateWinProbability,
            leadControlReserveAfterMove: leadControlReserveAfterMove,
            leadPreferredControlSuitAfterMove: leadPreferredControlSuitAfterMove,
            leadPreferredControlSuitStrengthAfterMove: leadPreferredControlSuitStrengthAfterMove,
            move: move,
            context: context
        )
        let leadJokerGoalOrientedAdjustment = leadJokerGoalOrientedUtilityAdjustment(
            immediateWinProbability: immediateWinProbability,
            leadControlReserveAfterMove: leadControlReserveAfterMove,
            leadPreferredControlSuitAfterMove: leadPreferredControlSuitAfterMove,
            leadPreferredControlSuitStrengthAfterMove: leadPreferredControlSuitStrengthAfterMove,
            move: move,
            context: context
        )

        var tacticalComponent = 0.0
        var riskComponent =
            matchCatchUpAdjustment +
            premiumPreserveAdjustment +
            penaltyAvoidAdjustment +
            premiumDenyAdjustment
        let opponentComponent = opponentBidPressureAdjustment + opponentIntentionAdjustment
        var jokerComponent = leadJokerDeclarationAdjustment + leadJokerGoalOrientedAdjustment

        if !context.shouldChaseTrick {
            if isOwnPremiumProtectionContext && context.trickDeltaToBidBeforeMove == 0 {
                // Late exact-bid premium/zero-premium: сильнее поощряем безопасный проигрыш взятки.
                let lateBlockWeight = 0.5 + 0.5 * (context.matchContext?.blockProgressFraction ?? 0.0)
                riskComponent += (1.0 - immediateWinProbability) * 64.0 * lateBlockWeight
            }

            if context.trickDeltaToBidBeforeMove > 0 &&
                !isOwnPremiumProtectionContext &&
                !hasOpponentPremiumPressureContext &&
                !isPenaltyTargetRiskContext {
                // Уже ушли в overbid: в нейтральном контексте полезно добирать очки (K > V → K×10).
                let overbidSeverity = min(2.0, Double(context.trickDeltaToBidBeforeMove))
                tacticalComponent += immediateWinProbability * 14.0 * overbidSeverity
            }

            if context.trickDeltaToBidBeforeMove > 0 && hasOpponentPremiumPressureContext {
                // В overbid+dump усиливаем safe-loss только против erratic соперника.
                // Для disciplined/no-evidence оставляем окно для deny-игры.
                let disciplineSignal = opponentDisciplineSignal(from: context.matchContext)
                let erraticSignal = clamped(
                    (0.5 - disciplineSignal) * 2.0,
                    min: 0.0,
                    max: 1.0
                )
                let overbidSeverity = min(2.0, Double(context.trickDeltaToBidBeforeMove))
                tacticalComponent +=
                    (1.0 - immediateWinProbability) *
                    (12.0 + 20.0 * overbidSeverity) *
                    erraticSignal
            }

            if isPenaltyTargetRiskContext {
                // Под штрафным риском наоборот приоритизируем controlled-loss dump.
                riskComponent += (1.0 - immediateWinProbability) * 8.0
            }
        }
        let blindChaseOpponentMultiplier = (context.isBlindRound && context.shouldChaseTrick)
            ? opponentBlindChaseContestMultiplier(from: context.matchContext)
            : 1.0
        let blindRewardMultiplier = context.isBlindRound ? 1.55 * blindChaseOpponentMultiplier : 1.0
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
            let isAllInChase = context.shouldChaseTrick &&
                context.tricksNeededToMatchBid >= context.tricksRemainingIncludingCurrent
            let wishPenaltyReserveMultiplier: Double
            if context.shouldChaseTrick && !isAllInChase {
                let controlReserve = min(1.0, max(0.0, leadControlReserveAfterMove))
                // Stage 5 retune (JOKER-008): при высоком post-joker reserve штраф за ранний `wish`
                // должен заметнее ослабляться, чтобы runtime мог стабильно менять декларацию.
                wishPenaltyReserveMultiplier = 1.15 - 0.45 * controlReserve
            } else {
                wishPenaltyReserveMultiplier = 1.0
            }
            jokerComponent -= basePenalty *
                chaseMultiplier *
                blindWishPenaltyMultiplier *
                wishPenaltyReserveMultiplier
        }

        if context.shouldChaseTrick {
            let conservatism = max(0.0, 1.0 - context.chasePressure)
            let mustWinAllRemaining = context.tricksNeededToMatchBid >= context.tricksRemainingIncludingCurrent
            tacticalComponent += immediateWinProbability *
                strategy.chaseWinProbabilityWeight *
                (1.0 + context.chasePressure) *
                blindRewardMultiplier
            tacticalComponent -= threat *
                strategy.chaseThreatPenaltyWeight *
                conservatism *
                blindRiskMultiplier

            if move.card.isJoker && context.hasWinningNonJoker {
                jokerComponent -= joker.chaseSpendJokerPenalty * conservatism * blindRiskMultiplier
            }

            if move.card.isJoker && context.hasWinningNonJoker && !mustWinAllRemaining {
                // Дополнительная защита от раннего расхода джокера, когда есть рабочий non-joker.
                jokerComponent -= joker.chaseSpendJokerPenalty *
                    (0.55 + 0.45 * context.chasePressure) *
                    blindRiskMultiplier
            }

            if mustWinAllRemaining {
                jokerComponent -= (1.0 - immediateWinProbability) *
                    joker.chaseSpendJokerPenalty *
                    blindRiskMultiplier
            }

            if isLeadJoker {
                if case .some(.wish) = move.decision.leadDeclaration {
                    jokerComponent += joker.chaseLeadWishBonus *
                        (0.5 + context.chasePressure * 0.5) *
                        (context.isBlindRound ? 1.15 : 1.0)
                }
            }
        } else {
            tacticalComponent +=
                (1.0 - immediateWinProbability) * strategy.dumpAvoidWinWeight * blindRewardMultiplier
            tacticalComponent +=
                threat * strategy.dumpThreatRewardWeight * blindRewardMultiplier

            if move.card.isJoker && context.hasLosingNonJoker {
                jokerComponent -= joker.dumpSpendJokerPenalty * blindRiskMultiplier
            }
            if move.card.isJoker && move.decision.style == .faceUp && !context.trick.playedCards.isEmpty {
                jokerComponent -= joker.dumpFaceUpNonLeadJokerPenalty * blindRiskMultiplier
            }

            if isLeadJoker, case .some(.takes(let suit)) = move.decision.leadDeclaration {
                if let trump = context.trump, suit != trump {
                    jokerComponent +=
                        joker.dumpLeadTakesNonTrumpBonus * (context.isBlindRound ? 1.2 : 1.0)
                }
            }
        }

        return composeUtility(
            components: .init(
                base: projectedScore,
                tactical: tacticalComponent,
                risk: riskComponent,
                opponent: opponentComponent,
                joker: jokerComponent
            ),
            immediateWinProbability: immediateWinProbability,
            threat: threat,
            move: move,
            context: context
        )
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
