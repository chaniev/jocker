//
//  OpponentPressureAdjuster.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

struct OpponentPressureAdjuster {
    private let opponentModelingPolicy: BotRuntimePolicy.OpponentModeling

    init(opponentModelingPolicy: BotRuntimePolicy.OpponentModeling) {
        self.opponentModelingPolicy = opponentModelingPolicy
    }

    func premiumDenyPressureMultiplier(from matchContext: BotMatchContext) -> Double {
        guard let opponents = matchContext.opponents else { return 1.0 }

        let prioritizedSnapshots: [BotOpponentModel.OpponentSnapshot]
        if let leftNeighborIndex = opponents.leftNeighborIndex,
           let leftNeighborSnapshot = opponents.snapshot(for: leftNeighborIndex) {
            prioritizedSnapshots = [leftNeighborSnapshot]
        } else {
            prioritizedSnapshots = opponents.snapshots
        }
        guard !prioritizedSnapshots.isEmpty else { return 1.0 }

        let evidenceSaturationRounds = Double(
            max(
                1,
                min(matchContext.totalRoundsInBlock, opponentModelingPolicy.opponentStyleEvidenceSaturationRounds)
            )
        )
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
        return min(
            opponentModelingPolicy.opponentStyleMultiplierMax,
            max(opponentModelingPolicy.opponentStyleMultiplierMin, 1.0 + normalizedSignal)
        )
    }

    func leadJokerAntiPremiumMultiplier(from matchContext: BotMatchContext?) -> Double {
        guard let matchContext else { return 1.0 }
        let denyPressureMultiplier = premiumDenyPressureMultiplier(from: matchContext)
        return 1.0 + (denyPressureMultiplier - 1.0) * opponentModelingPolicy.opponentLeadJokerAntiPremiumWeight
    }

    func matchCatchUpUrgencyMultiplier(from matchContext: BotMatchContext?) -> Double {
        guard let matchContext else { return 1.0 }
        let denyPressureMultiplier = premiumDenyPressureMultiplier(from: matchContext)
        let lateBlockWeight = opponentModelingPolicy.opponentLateBlockWeightBase +
            opponentModelingPolicy.opponentLateBlockWeightProgress * matchContext.blockProgressFraction
        return 1.0 + (denyPressureMultiplier - 1.0) *
            opponentModelingPolicy.opponentMatchCatchUpUrgencyWeight *
            lateBlockWeight
    }

    func blindChaseContestMultiplier(from matchContext: BotMatchContext?) -> Double {
        guard let matchContext else { return 1.0 }
        let denyPressureMultiplier = premiumDenyPressureMultiplier(from: matchContext)
        let lateBlockWeight = opponentModelingPolicy.opponentLateBlockWeightBase +
            opponentModelingPolicy.opponentLateBlockWeightProgress * matchContext.blockProgressFraction
        return 1.0 + (denyPressureMultiplier - 1.0) *
            opponentModelingPolicy.opponentBlindChaseContestWeight *
            lateBlockWeight
    }

    func disciplineSignal(from matchContext: BotMatchContext?) -> Double {
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

    func bidPressureUtilityAdjustment(
        immediateWinProbability: Double,
        context: BotTurnCandidateRankingService.UtilityContext
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
            return immediateWinProbability *
                (opponentModelingPolicy.opponentBidPressureChaseBase +
                    opponentModelingPolicy.opponentBidPressureChaseProgress * normalizedPressure)
        }

        return -(1.0 - immediateWinProbability) *
            (opponentModelingPolicy.opponentBidPressureDumpBase +
                opponentModelingPolicy.opponentBidPressureDumpProgress * normalizedPressure)
    }

    func intentionUtilityAdjustment(
        immediateWinProbability: Double,
        context: BotTurnCandidateRankingService.UtilityContext
    ) -> Double {
        guard let intention = context.opponentIntention else { return 0.0 }
        guard intention.hasEvidence else { return 0.0 }

        let strongest = max(0.0, intention.strongestDenyPressure)
        let aggregate = max(0.0, intention.totalDenyPressure)
        guard strongest > 0 || aggregate > 0 else { return 0.0 }

        let pressure = min(
            opponentModelingPolicy.opponentIntentionPressureMax,
            strongest + aggregate * opponentModelingPolicy.opponentIntentionAggregateWeight
        )
        if context.shouldChaseTrick {
            return immediateWinProbability *
                (opponentModelingPolicy.opponentIntentionChaseBase +
                    opponentModelingPolicy.opponentIntentionChaseProgress * pressure)
        }

        return -(1.0 - immediateWinProbability) *
            (opponentModelingPolicy.opponentIntentionDumpBase +
                opponentModelingPolicy.opponentIntentionDumpProgress * pressure)
    }

    private func normalizedPlayerIndex(_ value: Int, playerCount: Int) -> Int {
        guard playerCount > 0 else { return 0 }
        return ((value % playerCount) + playerCount) % playerCount
    }

    private func clamped(
        _ value: Double,
        min lowerBound: Double,
        max upperBound: Double
    ) -> Double {
        Swift.min(upperBound, Swift.max(lowerBound, value))
    }
}
