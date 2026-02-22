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
        let chasePressure: Double
    }

    private let tuning: BotTuning

    init(tuning: BotTuning) {
        self.tuning = tuning
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
        context: UtilityContext
    ) -> Double {
        let strategy = tuning.turnStrategy
        var utility = projectedScore
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
            utility -= basePenalty * chaseMultiplier
        }

        if context.shouldChaseTrick {
            let conservatism = max(0.0, 1.0 - context.chasePressure)
            utility += immediateWinProbability * strategy.chaseWinProbabilityWeight * (1.0 + context.chasePressure)
            utility -= threat * strategy.chaseThreatPenaltyWeight * conservatism

            if move.card.isJoker && context.hasWinningNonJoker {
                utility -= strategy.chaseSpendJokerPenalty * conservatism
            }

            if context.tricksNeededToMatchBid >= context.tricksRemainingIncludingCurrent {
                utility -= (1.0 - immediateWinProbability) * strategy.chaseSpendJokerPenalty
            }

            if isLeadJoker {
                if case .some(.wish) = move.decision.leadDeclaration {
                    utility += strategy.chaseLeadWishBonus * (0.5 + context.chasePressure * 0.5)
                }
            }
        } else {
            utility += (1.0 - immediateWinProbability) * strategy.dumpAvoidWinWeight
            utility += threat * strategy.dumpThreatRewardWeight

            if move.card.isJoker && context.hasLosingNonJoker {
                utility -= strategy.dumpSpendJokerPenalty
            }
            if move.card.isJoker && move.decision.style == .faceUp && !context.trick.playedCards.isEmpty {
                utility -= strategy.dumpFaceUpNonLeadJokerPenalty
            }

            if isLeadJoker, case .some(.takes(let suit)) = move.decision.leadDeclaration {
                if let trump = context.trump, suit != trump {
                    utility += strategy.dumpLeadTakesNonTrumpBonus
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
        chasePressure: Double
    ) -> Double {
        return moveUtility(
            projectedScore: projectedScore,
            immediateWinProbability: immediateWinProbability,
            threat: threat,
            move: move,
            context: .init(
                trick: .init(trickNode: trickNode),
                trump: trump,
                shouldChaseTrick: shouldChaseTrick,
                hasWinningNonJoker: hasWinningNonJoker,
                hasLosingNonJoker: hasLosingNonJoker,
                tricksNeededToMatchBid: tricksNeededToMatchBid,
                tricksRemainingIncludingCurrent: tricksRemainingIncludingCurrent,
                chasePressure: chasePressure
            )
        )
    }
}
