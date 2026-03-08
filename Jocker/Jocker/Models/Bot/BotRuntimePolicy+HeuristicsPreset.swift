//
//  BotRuntimePolicy+HeuristicsPreset.swift
//  Jocker
//
//  Created by Codex on 07.03.2026.
//

import Foundation

extension BotRuntimePolicy {
    static let hardBaselineSimulation = Simulation(
        chaseJokerPower: 20_000.0,
        dumpJokerPower: 12_000.0,
        trumpBonus: 18.0,
        leadSuitBonus: 5.0,
        highRankThreshold: .queen,
        highRankBonus: 4.0
    )

    static let hardBaselineHandStrength = HandStrength(
        trumpSelectionControlTopRankWeight: 0.58,
        trumpSelectionControlSequenceWeight: 0.42,
        noTrumpJokerSupportHighCardWeight: 0.35,
        noTrumpJokerSupportLongSuitWeight: 0.65,
        sequenceStrengthNormalizationDivisor: 3.0
    )

    static let hardBaselineHeuristics = Heuristics(
        legalAwareMinIterations: 20,
        legalAwareMaxIterations: 48,
        legalAwareReducedMinIterations: 8,
        legalAwareReducedMaxIterations: 20,
        legalAwareRotationStride: 7,
        legalAwareReducedMaxCardsPerOpponentSample: 3,
        legalAwareEndgameHandSizeThreshold: 4,
        holdBlend: Heuristics.HoldBlend(
            legalAwareSimulationWeight: 0.72,
            distributionWeight: 0.28
        ),
        legalAwareSimulationCardPower: Heuristics.LegalAwareSimulationCardPower(
            jokerPower: 10_000.0,
            trumpBonus: 100.0,
            leadSuitBonus: 40.0
        ),
        threatPhase: Heuristics.ThreatPhase(
            jokerResourceWeight: 1.0,
            trumpResourceWeight: 0.8,
            highRankThreshold: .queen,
            highRankResourceWeight: 0.65,
            midRankThreshold: .jack,
            midRankResourceWeight: 0.35,
            lowRankResourceWeight: 0.15,
            earlyPreservationBonusWeight: 0.28,
            lateConversionDiscountWeight: 0.38,
            finalCardReliefWeight: 0.05,
            minMultiplier: 0.55,
            maxMultiplier: 1.35
        ),
        threatPosition: Heuristics.ThreatPosition(
            leadMultiplier: 1.08,
            secondSeatMultiplier: 1.03,
            middleSeatMultiplier: 0.97,
            lastSeatMultiplier: 0.90
        ),
        threatHistory: Heuristics.ThreatHistory(
            jokerSeenBoost: 1.08,
            jokerLeadPositionMultiplier: 1.02,
            jokerFollowPositionMultiplier: 0.98,
            jokerMinMultiplier: 0.86,
            jokerMaxMultiplier: 1.16,
            topCardTerminalReliefLate: 0.96,
            topCardTerminalReliefDefault: 1.02,
            topCardMinMultiplier: 0.90,
            topCardMaxMultiplier: 1.08,
            roundContextBase: 0.98,
            roundContextDepletionWeight: 0.14,
            inTrickReliefPerHigherCard: 0.05,
            inTrickReliefMin: 0.86,
            trumpResourceBase: 1.04,
            trumpResourceDepletionWeight: 0.06,
            regularMinMultiplier: 0.80,
            regularMaxMultiplier: 1.22
        )
    )
}
