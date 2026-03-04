//
//  BotSelfPlayEvolutionEngine+Genome.swift
//  Jocker
//
//  Created by Codex on 04.03.2026.
//

import Foundation

extension BotSelfPlayEvolutionEngine {
    struct EvolutionGenome {
        var chaseWinProbabilityScale: Double
        var chaseThreatPenaltyScale: Double
        var chaseSpendJokerPenaltyScale: Double
        var dumpAvoidWinScale: Double
        var dumpThreatRewardScale: Double
        var dumpSpendJokerPenaltyScale: Double
        var holdDistributionScale: Double
        var futureTricksScale: Double
        var futureJokerPowerScale: Double
        var threatPreservationScale: Double

        var biddingJokerPowerScale: Double
        var biddingRankWeightScale: Double
        var biddingTrumpBaseBonusScale: Double
        var biddingTrumpRankWeightScale: Double
        var biddingHighRankBonusScale: Double
        var biddingLongSuitBonusScale: Double
        var biddingTrumpDensityBonusScale: Double
        var biddingNoTrumpHighCardBonusScale: Double
        var biddingNoTrumpJokerSynergyScale: Double
        var blindDesperateBehindThresholdScale: Double
        var blindCatchUpBehindThresholdScale: Double
        var blindSafeLeadThresholdScale: Double
        var blindDesperateTargetShareScale: Double
        var blindCatchUpTargetShareScale: Double
        var blindCatchUpConservativeTargetShareScale: Double

        var trumpCardBasePowerScale: Double
        var trumpThresholdScale: Double

        static let identity = EvolutionGenome(
            chaseWinProbabilityScale: 1.0,
            chaseThreatPenaltyScale: 1.0,
            chaseSpendJokerPenaltyScale: 1.0,
            dumpAvoidWinScale: 1.0,
            dumpThreatRewardScale: 1.0,
            dumpSpendJokerPenaltyScale: 1.0,
            holdDistributionScale: 1.0,
            futureTricksScale: 1.0,
            futureJokerPowerScale: 1.0,
            threatPreservationScale: 1.0,
            biddingJokerPowerScale: 1.0,
            biddingRankWeightScale: 1.0,
            biddingTrumpBaseBonusScale: 1.0,
            biddingTrumpRankWeightScale: 1.0,
            biddingHighRankBonusScale: 1.0,
            biddingLongSuitBonusScale: 1.0,
            biddingTrumpDensityBonusScale: 1.0,
            biddingNoTrumpHighCardBonusScale: 1.0,
            biddingNoTrumpJokerSynergyScale: 1.0,
            blindDesperateBehindThresholdScale: 1.0,
            blindCatchUpBehindThresholdScale: 1.0,
            blindSafeLeadThresholdScale: 1.0,
            blindDesperateTargetShareScale: 1.0,
            blindCatchUpTargetShareScale: 1.0,
            blindCatchUpConservativeTargetShareScale: 1.0,
            trumpCardBasePowerScale: 1.0,
            trumpThresholdScale: 1.0
        )

        var lexicographicKey: [Double] {
            return [
                chaseWinProbabilityScale,
                chaseThreatPenaltyScale,
                chaseSpendJokerPenaltyScale,
                dumpAvoidWinScale,
                dumpThreatRewardScale,
                dumpSpendJokerPenaltyScale,
                holdDistributionScale,
                futureTricksScale,
                futureJokerPowerScale,
                threatPreservationScale,
                biddingJokerPowerScale,
                biddingRankWeightScale,
                biddingTrumpBaseBonusScale,
                biddingTrumpRankWeightScale,
                biddingHighRankBonusScale,
                biddingLongSuitBonusScale,
                biddingTrumpDensityBonusScale,
                biddingNoTrumpHighCardBonusScale,
                biddingNoTrumpJokerSynergyScale,
                blindDesperateBehindThresholdScale,
                blindCatchUpBehindThresholdScale,
                blindSafeLeadThresholdScale,
                blindDesperateTargetShareScale,
                blindCatchUpTargetShareScale,
                blindCatchUpConservativeTargetShareScale,
                trumpCardBasePowerScale,
                trumpThresholdScale
            ]
        }
    }

    struct SelfPlayRandomGenerator: RandomNumberGenerator {
        private var state: UInt64

        init(seed: UInt64) {
            state = seed == 0 ? 0xA409_3822_299F_31D0 : seed
        }

        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15

            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }

        mutating func nextUnit() -> Double {
            let bits = next() >> 11
            let max53 = Double(1 << 53)
            return Double(bits) / max53
        }
    }

    static func applyingEvolutionScopeMask(
        _ genome: EvolutionGenome,
        config: SelfPlayEvolutionConfig
    ) -> EvolutionGenome {
        if config.tuneTurnStrategy && config.tuneBidding && config.tuneTrumpSelection {
            return genome
        }

        var masked = genome

        if !config.tuneTurnStrategy {
            masked.chaseWinProbabilityScale = 1.0
            masked.chaseThreatPenaltyScale = 1.0
            masked.chaseSpendJokerPenaltyScale = 1.0
            masked.dumpAvoidWinScale = 1.0
            masked.dumpThreatRewardScale = 1.0
            masked.dumpSpendJokerPenaltyScale = 1.0
            masked.holdDistributionScale = 1.0
            masked.futureTricksScale = 1.0
            masked.futureJokerPowerScale = 1.0
            masked.threatPreservationScale = 1.0
        }

        if !config.tuneBidding {
            masked.biddingJokerPowerScale = 1.0
            masked.biddingRankWeightScale = 1.0
            masked.biddingTrumpBaseBonusScale = 1.0
            masked.biddingTrumpRankWeightScale = 1.0
            masked.biddingHighRankBonusScale = 1.0
            masked.biddingLongSuitBonusScale = 1.0
            masked.biddingTrumpDensityBonusScale = 1.0
            masked.biddingNoTrumpHighCardBonusScale = 1.0
            masked.biddingNoTrumpJokerSynergyScale = 1.0
            masked.blindDesperateBehindThresholdScale = 1.0
            masked.blindCatchUpBehindThresholdScale = 1.0
            masked.blindSafeLeadThresholdScale = 1.0
            masked.blindDesperateTargetShareScale = 1.0
            masked.blindCatchUpTargetShareScale = 1.0
            masked.blindCatchUpConservativeTargetShareScale = 1.0
        }

        if !config.tuneTrumpSelection {
            masked.trumpCardBasePowerScale = 1.0
            masked.trumpThresholdScale = 1.0
        }

        return masked
    }

    static func randomGenome(
        around base: EvolutionGenome,
        magnitude: Double,
        using rng: inout SelfPlayRandomGenerator
    ) -> EvolutionGenome {
        return EvolutionGenome(
            chaseWinProbabilityScale: randomizedScale(
                base.chaseWinProbabilityScale,
                magnitude: magnitude,
                range: 0.50...1.80,
                using: &rng
            ),
            chaseThreatPenaltyScale: randomizedScale(
                base.chaseThreatPenaltyScale,
                magnitude: magnitude,
                range: 0.45...1.90,
                using: &rng
            ),
            chaseSpendJokerPenaltyScale: randomizedScale(
                base.chaseSpendJokerPenaltyScale,
                magnitude: magnitude,
                range: 0.45...1.90,
                using: &rng
            ),
            dumpAvoidWinScale: randomizedScale(
                base.dumpAvoidWinScale,
                magnitude: magnitude,
                range: 0.50...1.80,
                using: &rng
            ),
            dumpThreatRewardScale: randomizedScale(
                base.dumpThreatRewardScale,
                magnitude: magnitude,
                range: 0.50...1.90,
                using: &rng
            ),
            dumpSpendJokerPenaltyScale: randomizedScale(
                base.dumpSpendJokerPenaltyScale,
                magnitude: magnitude,
                range: 0.45...1.90,
                using: &rng
            ),
            holdDistributionScale: randomizedScale(
                base.holdDistributionScale,
                magnitude: magnitude,
                range: 0.70...1.20,
                using: &rng
            ),
            futureTricksScale: randomizedScale(
                base.futureTricksScale,
                magnitude: magnitude,
                range: 0.55...1.60,
                using: &rng
            ),
            futureJokerPowerScale: randomizedScale(
                base.futureJokerPowerScale,
                magnitude: magnitude,
                range: 0.55...1.70,
                using: &rng
            ),
            threatPreservationScale: randomizedScale(
                base.threatPreservationScale,
                magnitude: magnitude,
                range: 0.55...1.70,
                using: &rng
            ),
            biddingJokerPowerScale: randomizedScale(
                base.biddingJokerPowerScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...4.00,
                using: &rng
            ),
            biddingRankWeightScale: randomizedScale(
                base.biddingRankWeightScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...12.00,
                using: &rng
            ),
            biddingTrumpBaseBonusScale: randomizedScale(
                base.biddingTrumpBaseBonusScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...12.00,
                using: &rng
            ),
            biddingTrumpRankWeightScale: randomizedScale(
                base.biddingTrumpRankWeightScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...12.00,
                using: &rng
            ),
            biddingHighRankBonusScale: randomizedScale(
                base.biddingHighRankBonusScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...15.00,
                using: &rng
            ),
            biddingLongSuitBonusScale: randomizedScale(
                base.biddingLongSuitBonusScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...15.00,
                using: &rng
            ),
            biddingTrumpDensityBonusScale: randomizedScale(
                base.biddingTrumpDensityBonusScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...15.00,
                using: &rng
            ),
            biddingNoTrumpHighCardBonusScale: randomizedScale(
                base.biddingNoTrumpHighCardBonusScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...15.00,
                using: &rng
            ),
            biddingNoTrumpJokerSynergyScale: randomizedScale(
                base.biddingNoTrumpJokerSynergyScale,
                magnitude: max(magnitude * 3.0, 0.35),
                range: 0.35...15.00,
                using: &rng
            ),
            blindDesperateBehindThresholdScale: randomizedScale(
                base.blindDesperateBehindThresholdScale,
                magnitude: magnitude,
                range: 0.60...1.70,
                using: &rng
            ),
            blindCatchUpBehindThresholdScale: randomizedScale(
                base.blindCatchUpBehindThresholdScale,
                magnitude: magnitude,
                range: 0.55...1.75,
                using: &rng
            ),
            blindSafeLeadThresholdScale: randomizedScale(
                base.blindSafeLeadThresholdScale,
                magnitude: magnitude,
                range: 0.55...1.80,
                using: &rng
            ),
            blindDesperateTargetShareScale: randomizedScale(
                base.blindDesperateTargetShareScale,
                magnitude: magnitude,
                range: 0.60...1.55,
                using: &rng
            ),
            blindCatchUpTargetShareScale: randomizedScale(
                base.blindCatchUpTargetShareScale,
                magnitude: magnitude,
                range: 0.55...1.65,
                using: &rng
            ),
            blindCatchUpConservativeTargetShareScale: randomizedScale(
                base.blindCatchUpConservativeTargetShareScale,
                magnitude: magnitude,
                range: 0.55...1.70,
                using: &rng
            ),
            trumpCardBasePowerScale: randomizedScale(
                base.trumpCardBasePowerScale,
                magnitude: magnitude,
                range: 0.50...1.65,
                using: &rng
            ),
            trumpThresholdScale: randomizedScale(
                base.trumpThresholdScale,
                magnitude: magnitude,
                range: 0.55...1.65,
                using: &rng
            )
        )
    }

    static func crossover(
        _ first: EvolutionGenome,
        _ second: EvolutionGenome,
        using rng: inout SelfPlayRandomGenerator
    ) -> EvolutionGenome {
        return EvolutionGenome(
            chaseWinProbabilityScale: mixedScale(
                first.chaseWinProbabilityScale,
                second.chaseWinProbabilityScale,
                range: 0.50...1.80,
                using: &rng
            ),
            chaseThreatPenaltyScale: mixedScale(
                first.chaseThreatPenaltyScale,
                second.chaseThreatPenaltyScale,
                range: 0.45...1.90,
                using: &rng
            ),
            chaseSpendJokerPenaltyScale: mixedScale(
                first.chaseSpendJokerPenaltyScale,
                second.chaseSpendJokerPenaltyScale,
                range: 0.45...1.90,
                using: &rng
            ),
            dumpAvoidWinScale: mixedScale(
                first.dumpAvoidWinScale,
                second.dumpAvoidWinScale,
                range: 0.50...1.80,
                using: &rng
            ),
            dumpThreatRewardScale: mixedScale(
                first.dumpThreatRewardScale,
                second.dumpThreatRewardScale,
                range: 0.50...1.90,
                using: &rng
            ),
            dumpSpendJokerPenaltyScale: mixedScale(
                first.dumpSpendJokerPenaltyScale,
                second.dumpSpendJokerPenaltyScale,
                range: 0.45...1.90,
                using: &rng
            ),
            holdDistributionScale: mixedScale(
                first.holdDistributionScale,
                second.holdDistributionScale,
                range: 0.70...1.20,
                using: &rng
            ),
            futureTricksScale: mixedScale(
                first.futureTricksScale,
                second.futureTricksScale,
                range: 0.55...1.60,
                using: &rng
            ),
            futureJokerPowerScale: mixedScale(
                first.futureJokerPowerScale,
                second.futureJokerPowerScale,
                range: 0.55...1.70,
                using: &rng
            ),
            threatPreservationScale: mixedScale(
                first.threatPreservationScale,
                second.threatPreservationScale,
                range: 0.55...1.70,
                using: &rng
            ),
            biddingJokerPowerScale: mixedScale(
                first.biddingJokerPowerScale,
                second.biddingJokerPowerScale,
                range: 0.35...4.00,
                using: &rng
            ),
            biddingRankWeightScale: mixedScale(
                first.biddingRankWeightScale,
                second.biddingRankWeightScale,
                range: 0.35...12.00,
                using: &rng
            ),
            biddingTrumpBaseBonusScale: mixedScale(
                first.biddingTrumpBaseBonusScale,
                second.biddingTrumpBaseBonusScale,
                range: 0.35...12.00,
                using: &rng
            ),
            biddingTrumpRankWeightScale: mixedScale(
                first.biddingTrumpRankWeightScale,
                second.biddingTrumpRankWeightScale,
                range: 0.35...12.00,
                using: &rng
            ),
            biddingHighRankBonusScale: mixedScale(
                first.biddingHighRankBonusScale,
                second.biddingHighRankBonusScale,
                range: 0.35...15.00,
                using: &rng
            ),
            biddingLongSuitBonusScale: mixedScale(
                first.biddingLongSuitBonusScale,
                second.biddingLongSuitBonusScale,
                range: 0.35...15.00,
                using: &rng
            ),
            biddingTrumpDensityBonusScale: mixedScale(
                first.biddingTrumpDensityBonusScale,
                second.biddingTrumpDensityBonusScale,
                range: 0.35...15.00,
                using: &rng
            ),
            biddingNoTrumpHighCardBonusScale: mixedScale(
                first.biddingNoTrumpHighCardBonusScale,
                second.biddingNoTrumpHighCardBonusScale,
                range: 0.35...15.00,
                using: &rng
            ),
            biddingNoTrumpJokerSynergyScale: mixedScale(
                first.biddingNoTrumpJokerSynergyScale,
                second.biddingNoTrumpJokerSynergyScale,
                range: 0.35...15.00,
                using: &rng
            ),
            blindDesperateBehindThresholdScale: mixedScale(
                first.blindDesperateBehindThresholdScale,
                second.blindDesperateBehindThresholdScale,
                range: 0.60...1.70,
                using: &rng
            ),
            blindCatchUpBehindThresholdScale: mixedScale(
                first.blindCatchUpBehindThresholdScale,
                second.blindCatchUpBehindThresholdScale,
                range: 0.55...1.75,
                using: &rng
            ),
            blindSafeLeadThresholdScale: mixedScale(
                first.blindSafeLeadThresholdScale,
                second.blindSafeLeadThresholdScale,
                range: 0.55...1.80,
                using: &rng
            ),
            blindDesperateTargetShareScale: mixedScale(
                first.blindDesperateTargetShareScale,
                second.blindDesperateTargetShareScale,
                range: 0.60...1.55,
                using: &rng
            ),
            blindCatchUpTargetShareScale: mixedScale(
                first.blindCatchUpTargetShareScale,
                second.blindCatchUpTargetShareScale,
                range: 0.55...1.65,
                using: &rng
            ),
            blindCatchUpConservativeTargetShareScale: mixedScale(
                first.blindCatchUpConservativeTargetShareScale,
                second.blindCatchUpConservativeTargetShareScale,
                range: 0.55...1.70,
                using: &rng
            ),
            trumpCardBasePowerScale: mixedScale(
                first.trumpCardBasePowerScale,
                second.trumpCardBasePowerScale,
                range: 0.50...1.65,
                using: &rng
            ),
            trumpThresholdScale: mixedScale(
                first.trumpThresholdScale,
                second.trumpThresholdScale,
                range: 0.55...1.65,
                using: &rng
            )
        )
    }

    static func mutateGenome(
        _ genome: EvolutionGenome,
        chance: Double,
        magnitude: Double,
        using rng: inout SelfPlayRandomGenerator
    ) -> EvolutionGenome {
        var mutated = genome
        mutateScale(
            &mutated.chaseWinProbabilityScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.50...1.80,
            using: &rng
        )
        mutateScale(
            &mutated.chaseThreatPenaltyScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.45...1.90,
            using: &rng
        )
        mutateScale(
            &mutated.chaseSpendJokerPenaltyScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.45...1.90,
            using: &rng
        )
        mutateScale(
            &mutated.dumpAvoidWinScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.50...1.80,
            using: &rng
        )
        mutateScale(
            &mutated.dumpThreatRewardScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.50...1.90,
            using: &rng
        )
        mutateScale(
            &mutated.dumpSpendJokerPenaltyScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.45...1.90,
            using: &rng
        )
        mutateScale(
            &mutated.holdDistributionScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.70...1.20,
            using: &rng
        )
        mutateScale(
            &mutated.futureTricksScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.55...1.60,
            using: &rng
        )
        mutateScale(
            &mutated.futureJokerPowerScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.55...1.70,
            using: &rng
        )
        mutateScale(
            &mutated.threatPreservationScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.55...1.70,
            using: &rng
        )
        mutateScale(
            &mutated.biddingJokerPowerScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...4.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingRankWeightScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...12.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingTrumpBaseBonusScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...12.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingTrumpRankWeightScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...12.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingHighRankBonusScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...15.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingLongSuitBonusScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...15.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingTrumpDensityBonusScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...15.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingNoTrumpHighCardBonusScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...15.00,
            using: &rng
        )
        mutateScale(
            &mutated.biddingNoTrumpJokerSynergyScale,
            chance: chance,
            magnitude: max(magnitude * 2.2, 0.22),
            range: 0.35...15.00,
            using: &rng
        )
        mutateScale(
            &mutated.blindDesperateBehindThresholdScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.60...1.70,
            using: &rng
        )
        mutateScale(
            &mutated.blindCatchUpBehindThresholdScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.55...1.75,
            using: &rng
        )
        mutateScale(
            &mutated.blindSafeLeadThresholdScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.55...1.80,
            using: &rng
        )
        mutateScale(
            &mutated.blindDesperateTargetShareScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.60...1.55,
            using: &rng
        )
        mutateScale(
            &mutated.blindCatchUpTargetShareScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.55...1.65,
            using: &rng
        )
        mutateScale(
            &mutated.blindCatchUpConservativeTargetShareScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.55...1.70,
            using: &rng
        )
        mutateScale(
            &mutated.trumpCardBasePowerScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.50...1.65,
            using: &rng
        )
        mutateScale(
            &mutated.trumpThresholdScale,
            chance: chance,
            magnitude: magnitude,
            range: 0.55...1.65,
            using: &rng
        )

        return mutated
    }

    static func tuning(
        byApplying genome: EvolutionGenome,
        to base: BotTuning
    ) -> BotTuning {
        let baseTurn = base.turnStrategy
        let holdWeight = clamp(
            baseTurn.holdFromDistributionWeight * genome.holdDistributionScale,
            to: 0.55...0.97
        )
        let powerWeight = 1.0 - holdWeight

        let turnStrategy = BotTuning.TurnStrategy(
            utilityTieTolerance: baseTurn.utilityTieTolerance,

            chaseWinProbabilityWeight: clamp(
                baseTurn.chaseWinProbabilityWeight * genome.chaseWinProbabilityScale,
                to: 15.0...140.0
            ),
            chaseThreatPenaltyWeight: clamp(
                baseTurn.chaseThreatPenaltyWeight * genome.chaseThreatPenaltyScale,
                to: 0.02...1.20
            ),
            chaseSpendJokerPenalty: clamp(
                baseTurn.chaseSpendJokerPenalty * genome.chaseSpendJokerPenaltyScale,
                to: 5.0...220.0
            ),
            chaseLeadWishBonus: baseTurn.chaseLeadWishBonus,

            dumpAvoidWinWeight: clamp(
                baseTurn.dumpAvoidWinWeight * genome.dumpAvoidWinScale,
                to: 15.0...140.0
            ),
            dumpThreatRewardWeight: clamp(
                baseTurn.dumpThreatRewardWeight * genome.dumpThreatRewardScale,
                to: 0.01...1.50
            ),
            dumpSpendJokerPenalty: clamp(
                baseTurn.dumpSpendJokerPenalty * genome.dumpSpendJokerPenaltyScale,
                to: 5.0...220.0
            ),
            dumpFaceUpNonLeadJokerPenalty: baseTurn.dumpFaceUpNonLeadJokerPenalty,
            dumpLeadTakesNonTrumpBonus: baseTurn.dumpLeadTakesNonTrumpBonus,

            holdFromDistributionWeight: holdWeight,
            powerConfidenceWeight: powerWeight,

            futureJokerPower: clamp(
                baseTurn.futureJokerPower * genome.futureJokerPowerScale,
                to: 0.40...2.60
            ),
            futureRegularBasePower: baseTurn.futureRegularBasePower,
            futureRegularRankWeight: baseTurn.futureRegularRankWeight,
            futureTrumpBaseBonus: baseTurn.futureTrumpBaseBonus,
            futureTrumpRankWeight: baseTurn.futureTrumpRankWeight,
            futureHighRankBonus: baseTurn.futureHighRankBonus,
            futureLongSuitBonusPerCard: baseTurn.futureLongSuitBonusPerCard,
            futureTricksScale: clamp(
                baseTurn.futureTricksScale * genome.futureTricksScale,
                to: 0.20...1.35
            ),

            threatFaceDownLeadJoker: baseTurn.threatFaceDownLeadJoker,
            threatFaceDownNonLeadJoker: baseTurn.threatFaceDownNonLeadJoker,
            threatLeadTakesJoker: baseTurn.threatLeadTakesJoker,
            threatLeadAboveJoker: baseTurn.threatLeadAboveJoker,
            threatLeadWishJoker: baseTurn.threatLeadWishJoker,
            threatNonLeadFaceUpJoker: baseTurn.threatNonLeadFaceUpJoker,
            threatTrumpBonus: clamp(
                baseTurn.threatTrumpBonus * genome.threatPreservationScale,
                to: 1.0...24.0
            ),
            threatHighRankBonus: clamp(
                baseTurn.threatHighRankBonus * genome.threatPreservationScale,
                to: 0.5...12.0
            ),

            powerFaceDownJoker: baseTurn.powerFaceDownJoker,
            powerLeadTakesJoker: baseTurn.powerLeadTakesJoker,
            powerLeadAboveJoker: baseTurn.powerLeadAboveJoker,
            powerLeadWishJoker: baseTurn.powerLeadWishJoker,
            powerNonLeadFaceUpJoker: baseTurn.powerNonLeadFaceUpJoker,
            powerTrumpBonus: baseTurn.powerTrumpBonus,
            powerLeadSuitBonus: baseTurn.powerLeadSuitBonus,
            powerNormalizationValue: baseTurn.powerNormalizationValue
        )

        let baseBidding = base.bidding
        let evolvedBlindDesperateBehindThreshold = Int(
            clamp(
                Double(baseBidding.blindDesperateBehindThreshold) * genome.blindDesperateBehindThresholdScale,
                to: 100.0...700.0
            ).rounded()
        )
        let evolvedBlindCatchUpBehindThreshold = Int(
            clamp(
                Double(baseBidding.blindCatchUpBehindThreshold) * genome.blindCatchUpBehindThresholdScale,
                to: 60.0...600.0
            ).rounded()
        )
        let resolvedBlindCatchUpBehindThreshold = min(
            evolvedBlindDesperateBehindThreshold,
            evolvedBlindCatchUpBehindThreshold
        )
        let resolvedBlindSafeLeadThreshold = Int(
            clamp(
                Double(baseBidding.blindSafeLeadThreshold) * genome.blindSafeLeadThresholdScale,
                to: 80.0...800.0
            ).rounded()
        )
        let evolvedBlindCatchUpTargetShare = clamp(
            baseBidding.blindCatchUpTargetShare * genome.blindCatchUpTargetShareScale,
            to: 0.10...0.90
        )
        let evolvedBlindCatchUpConservativeTargetShare = clamp(
            baseBidding.blindCatchUpConservativeTargetShare * genome.blindCatchUpConservativeTargetShareScale,
            to: 0.05...0.85
        )
        let resolvedBlindCatchUpConservativeTargetShare = min(
            evolvedBlindCatchUpTargetShare,
            evolvedBlindCatchUpConservativeTargetShare
        )
        let evolvedBlindDesperateTargetShare = clamp(
            baseBidding.blindDesperateTargetShare * genome.blindDesperateTargetShareScale,
            to: 0.15...0.95
        )
        let resolvedBlindDesperateTargetShare = max(
            evolvedBlindCatchUpTargetShare,
            evolvedBlindDesperateTargetShare
        )
        let bidding = BotTuning.Bidding(
            expectedJokerPower: clamp(
                baseBidding.expectedJokerPower * genome.biddingJokerPowerScale,
                to: 0.40...2.60
            ),
            expectedRankWeight: clamp(
                baseBidding.expectedRankWeight * genome.biddingRankWeightScale,
                to: 0.10...1.80
            ),
            expectedTrumpBaseBonus: clamp(
                baseBidding.expectedTrumpBaseBonus * genome.biddingTrumpBaseBonusScale,
                to: 0.05...2.20
            ),
            expectedTrumpRankWeight: clamp(
                baseBidding.expectedTrumpRankWeight * genome.biddingTrumpRankWeightScale,
                to: 0.05...2.20
            ),
            expectedHighRankBonus: clamp(
                baseBidding.expectedHighRankBonus * genome.biddingHighRankBonusScale,
                to: 0.02...1.20
            ),
            expectedLongSuitBonusPerCard: clamp(
                baseBidding.expectedLongSuitBonusPerCard * genome.biddingLongSuitBonusScale,
                to: 0.02...0.95
            ),
            expectedTrumpDensityBonus: clamp(
                baseBidding.expectedTrumpDensityBonus * genome.biddingTrumpDensityBonusScale,
                to: 0.05...1.80
            ),
            expectedNoTrumpHighCardBonus: clamp(
                baseBidding.expectedNoTrumpHighCardBonus * genome.biddingNoTrumpHighCardBonusScale,
                to: 0.02...1.20
            ),
            expectedNoTrumpJokerSynergy: clamp(
                baseBidding.expectedNoTrumpJokerSynergy * genome.biddingNoTrumpJokerSynergyScale,
                to: 0.05...2.20
            ),

            blindDesperateBehindThreshold: evolvedBlindDesperateBehindThreshold,
            blindCatchUpBehindThreshold: resolvedBlindCatchUpBehindThreshold,
            blindSafeLeadThreshold: resolvedBlindSafeLeadThreshold,
            blindDesperateTargetShare: resolvedBlindDesperateTargetShare,
            blindCatchUpTargetShare: evolvedBlindCatchUpTargetShare,
            blindCatchUpConservativeTargetShare: resolvedBlindCatchUpConservativeTargetShare
        )

        let baseTrump = base.trumpSelection
        let trumpSelection = BotTuning.TrumpSelection(
            cardBasePower: clamp(
                baseTrump.cardBasePower * genome.trumpCardBasePowerScale,
                to: 0.10...1.80
            ),
            minimumPowerToDeclareTrump: clamp(
                baseTrump.minimumPowerToDeclareTrump * genome.trumpThresholdScale,
                to: 0.35...3.20
            )
        )

        return BotTuning(
            difficulty: base.difficulty,
            turnStrategy: turnStrategy,
            bidding: bidding,
            trumpSelection: trumpSelection,
            timing: base.timing
        )
    }

    private static func randomizedScale(
        _ value: Double,
        magnitude: Double,
        range: ClosedRange<Double>,
        using rng: inout SelfPlayRandomGenerator
    ) -> Double {
        let offset = (rng.nextUnit() * 2.0 - 1.0) * magnitude
        return clamp(value * (1.0 + offset), to: range)
    }

    private static func mixedScale(
        _ first: Double,
        _ second: Double,
        range: ClosedRange<Double>,
        using rng: inout SelfPlayRandomGenerator
    ) -> Double {
        let alpha = rng.nextUnit()
        let mixed = first * (1.0 - alpha) + second * alpha
        return clamp(mixed, to: range)
    }

    private static func mutateScale(
        _ value: inout Double,
        chance: Double,
        magnitude: Double,
        range: ClosedRange<Double>,
        using rng: inout SelfPlayRandomGenerator
    ) {
        guard chance > 0.0 else { return }
        guard rng.nextUnit() < chance else { return }
        value = randomizedScale(value, magnitude: magnitude, range: range, using: &rng)
    }

    private static func clamp(
        _ value: Double,
        to range: ClosedRange<Double>
    ) -> Double {
        return min(max(value, range.lowerBound), range.upperBound)
    }
}
