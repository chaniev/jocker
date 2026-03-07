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

    private let blockPlanResolver: BlockPlanResolver
    private let premiumPreserveAdjuster: PremiumPreserveAdjuster
    private let penaltyAvoidAdjuster: PenaltyAvoidAdjuster
    private let premiumDenyAdjuster: PremiumDenyAdjuster
    private let opponentPressureAdjuster: OpponentPressureAdjuster
    private let jokerDeclarationAdjuster: JokerDeclarationAdjuster
    private let moveUtilityComposer: MoveUtilityComposer
    private let candidateTieBreakPolicy: CandidateTieBreakPolicy

    init(tuning: BotTuning) {
        let rankingPolicy = tuning.runtimePolicy.ranking
        let opponentPressureAdjuster = OpponentPressureAdjuster(
            opponentModelingPolicy: tuning.runtimePolicy.opponentModeling
        )

        self.blockPlanResolver = BlockPlanResolver(
            rankingPolicy: rankingPolicy,
            opponentPressureAdjuster: opponentPressureAdjuster
        )
        self.premiumPreserveAdjuster = PremiumPreserveAdjuster(rankingPolicy: rankingPolicy)
        self.penaltyAvoidAdjuster = PenaltyAvoidAdjuster(
            rankingPolicy: rankingPolicy,
            opponentPressureAdjuster: opponentPressureAdjuster
        )
        self.premiumDenyAdjuster = PremiumDenyAdjuster(
            rankingPolicy: rankingPolicy,
            opponentPressureAdjuster: opponentPressureAdjuster
        )
        self.opponentPressureAdjuster = opponentPressureAdjuster
        self.jokerDeclarationAdjuster = JokerDeclarationAdjuster(
            policy: rankingPolicy.jokerDeclaration,
            opponentPressureAdjuster: opponentPressureAdjuster
        )
        self.moveUtilityComposer = MoveUtilityComposer(
            strategy: tuning.turnStrategy,
            policy: rankingPolicy.moveComposition,
            opponentPressureAdjuster: opponentPressureAdjuster
        )
        self.candidateTieBreakPolicy = CandidateTieBreakPolicy(
            utilityTieTolerance: tuning.turnStrategy.utilityTieTolerance
        )
    }

    func isBetterCandidate(
        _ candidate: Evaluation,
        than current: Evaluation,
        shouldChaseTrick: Bool
    ) -> Bool {
        candidateTieBreakPolicy.isBetterCandidate(
            candidate,
            than: current,
            shouldChaseTrick: shouldChaseTrick
        )
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
        let isLeadFaceUpDeclaredJoker =
            move.card.isJoker &&
            context.trick.playedCards.isEmpty &&
            move.decision.style == .faceUp &&
            move.decision.leadDeclaration != nil

        let matchCatchUpAdjustment = blockPlanResolver.matchCatchUpUtilityAdjustment(
            projectedScore: projectedScore,
            immediateWinProbability: immediateWinProbability,
            threat: threat,
            context: context
        )
        let premiumPreserveAdjustment = premiumPreserveAdjuster.utilityAdjustment(
            immediateWinProbability: immediateWinProbability,
            context: context
        )
        let penaltyAvoidAdjustment = isLeadFaceUpDeclaredJoker
            ? 0.0
            : penaltyAvoidAdjuster.utilityAdjustment(
                projectedScore: projectedScore,
                immediateWinProbability: immediateWinProbability,
                context: context
            )
        let premiumDenyAdjustment = isLeadFaceUpDeclaredJoker
            ? 0.0
            : premiumDenyAdjuster.utilityAdjustment(
                immediateWinProbability: immediateWinProbability,
                context: context
            )
        let opponentBidPressureAdjustment = opponentPressureAdjuster.bidPressureUtilityAdjustment(
            immediateWinProbability: immediateWinProbability,
            context: context
        )
        let opponentIntentionAdjustment = opponentPressureAdjuster.intentionUtilityAdjustment(
            immediateWinProbability: immediateWinProbability,
            context: context
        )
        let jokerAdjustment = jokerDeclarationAdjuster.utilityAdjustment(
            immediateWinProbability: immediateWinProbability,
            leadControlReserveAfterMove: leadControlReserveAfterMove,
            leadPreferredControlSuitAfterMove: leadPreferredControlSuitAfterMove,
            leadPreferredControlSuitStrengthAfterMove: leadPreferredControlSuitStrengthAfterMove,
            move: move,
            context: context
        )

        return moveUtilityComposer.moveUtility(
            projectedScore: projectedScore,
            immediateWinProbability: immediateWinProbability,
            threat: threat,
            move: move,
            context: context,
            matchCatchUpAdjustment: matchCatchUpAdjustment,
            premiumPreserveAdjustment: premiumPreserveAdjustment,
            penaltyAvoidAdjustment: penaltyAvoidAdjustment,
            premiumDenyAdjustment: premiumDenyAdjustment,
            opponentBidPressureAdjustment: opponentBidPressureAdjustment,
            opponentIntentionAdjustment: opponentIntentionAdjustment,
            jokerAdjustment: jokerAdjustment
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
        moveUtility(
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
