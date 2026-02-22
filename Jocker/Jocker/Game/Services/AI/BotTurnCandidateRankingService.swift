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
        trickNode: TrickNode,
        trump: Suit?,
        shouldChaseTrick: Bool,
        hasWinningNonJoker: Bool,
        hasLosingNonJoker: Bool,
        tricksNeededToMatchBid: Int,
        tricksRemainingIncludingCurrent: Int,
        chasePressure: Double
    ) -> Double {
        let strategy = tuning.turnStrategy
        var utility = projectedScore
        let isLeadJoker = move.card.isJoker && trickNode.playedCards.isEmpty
        let isNonFinalLeadWishJoker: Bool
        if isLeadJoker,
           move.decision.style == .faceUp,
           tricksRemainingIncludingCurrent > 1,
           case .some(.wish) = move.decision.leadDeclaration {
            isNonFinalLeadWishJoker = true
        } else {
            isNonFinalLeadWishJoker = false
        }

        if isNonFinalLeadWishJoker {
            // "wish" без заказа масти в ранних взятках ограничивает контроль стола.
            // В self-play и боевой логике смещаем выбор к "above"/"takes".
            let tricksAfterCurrent = max(1, tricksRemainingIncludingCurrent - 1)
            let basePenalty = 24.0 + Double(tricksAfterCurrent) * 6.0
            let chaseMultiplier = shouldChaseTrick ? (1.0 + chasePressure * 0.25) : 1.0
            utility -= basePenalty * chaseMultiplier
        }

        if shouldChaseTrick {
            let conservatism = max(0.0, 1.0 - chasePressure)
            utility += immediateWinProbability * strategy.chaseWinProbabilityWeight * (1.0 + chasePressure)
            utility -= threat * strategy.chaseThreatPenaltyWeight * conservatism

            if move.card.isJoker && hasWinningNonJoker {
                utility -= strategy.chaseSpendJokerPenalty * conservatism
            }

            if tricksNeededToMatchBid >= tricksRemainingIncludingCurrent {
                utility -= (1.0 - immediateWinProbability) * strategy.chaseSpendJokerPenalty
            }

            if isLeadJoker {
                if case .some(.wish) = move.decision.leadDeclaration {
                    utility += strategy.chaseLeadWishBonus * (0.5 + chasePressure * 0.5)
                }
            }
        } else {
            utility += (1.0 - immediateWinProbability) * strategy.dumpAvoidWinWeight
            utility += threat * strategy.dumpThreatRewardWeight

            if move.card.isJoker && hasLosingNonJoker {
                utility -= strategy.dumpSpendJokerPenalty
            }
            if move.card.isJoker && move.decision.style == .faceUp && !trickNode.playedCards.isEmpty {
                utility -= strategy.dumpFaceUpNonLeadJokerPenalty
            }

            if isLeadJoker, case .some(.takes(let suit)) = move.decision.leadDeclaration {
                if let trump, suit != trump {
                    utility += strategy.dumpLeadTakesNonTrumpBonus
                }
            }
        }

        return utility
    }
}
