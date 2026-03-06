//
//  CandidateTieBreakPolicy.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

struct CandidateTieBreakPolicy {
    private let utilityTieTolerance: Double

    init(utilityTieTolerance: Double) {
        self.utilityTieTolerance = utilityTieTolerance
    }

    func isBetterCandidate(
        _ candidate: BotTurnCandidateRankingService.Evaluation,
        than current: BotTurnCandidateRankingService.Evaluation,
        shouldChaseTrick: Bool
    ) -> Bool {
        if candidate.utility > current.utility + utilityTieTolerance {
            return true
        }
        if current.utility > candidate.utility + utilityTieTolerance {
            return false
        }

        if shouldChaseTrick {
            if candidate.immediateWinProbability > current.immediateWinProbability + utilityTieTolerance {
                return true
            }
            if current.immediateWinProbability > candidate.immediateWinProbability + utilityTieTolerance {
                return false
            }
            if candidate.threat < current.threat - utilityTieTolerance {
                return true
            }
            if current.threat < candidate.threat - utilityTieTolerance {
                return false
            }
        } else {
            if candidate.immediateWinProbability < current.immediateWinProbability - utilityTieTolerance {
                return true
            }
            if current.immediateWinProbability < candidate.immediateWinProbability - utilityTieTolerance {
                return false
            }
            if candidate.threat > current.threat + utilityTieTolerance {
                return true
            }
            if current.threat > candidate.threat + utilityTieTolerance {
                return false
            }
        }

        if candidate.move.card != current.move.card {
            return candidate.move.card < current.move.card
        }
        return candidate.move.decision.style == .faceDown &&
            current.move.decision.style == .faceUp
    }
}
