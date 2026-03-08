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

        var rankingMatchCatchUpScale: Double
        var rankingPremiumScale: Double
        var rankingPenaltyAvoidScale: Double
        var jokerDeclarationScale: Double
        var rolloutActivationScale: Double
        var rolloutAdjustmentScale: Double
        var endgameActivationScale: Double
        var endgameAdjustmentScale: Double
        var opponentPressureScale: Double

        var phaseRankingScale: Double
        var phaseRolloutScale: Double
        var phaseJokerScale: Double
        var phaseBlindScale: Double

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
            trumpThresholdScale: 1.0,
            rankingMatchCatchUpScale: 1.0,
            rankingPremiumScale: 1.0,
            rankingPenaltyAvoidScale: 1.0,
            jokerDeclarationScale: 1.0,
            rolloutActivationScale: 1.0,
            rolloutAdjustmentScale: 1.0,
            endgameActivationScale: 1.0,
            endgameAdjustmentScale: 1.0,
            opponentPressureScale: 1.0,
            phaseRankingScale: 1.0,
            phaseRolloutScale: 1.0,
            phaseJokerScale: 1.0,
            phaseBlindScale: 1.0
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
                trumpThresholdScale,
                rankingMatchCatchUpScale,
                rankingPremiumScale,
                rankingPenaltyAvoidScale,
                jokerDeclarationScale,
                rolloutActivationScale,
                rolloutAdjustmentScale,
                endgameActivationScale,
                endgameAdjustmentScale,
                opponentPressureScale,
                phaseRankingScale,
                phaseRolloutScale,
                phaseJokerScale,
                phaseBlindScale
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

    private enum RuntimePolicyGeneSpec {
        static let rankingMatchCatchUpRange = 0.60...1.60
        static let rankingPremiumRange = 0.60...1.60
        static let rankingPenaltyAvoidRange = 0.60...1.60
        static let jokerDeclarationRange = 0.60...1.60
        static let rolloutActivationRange = 0.65...1.50
        static let rolloutAdjustmentRange = 0.60...1.60
        static let endgameActivationRange = 0.65...1.50
        static let endgameAdjustmentRange = 0.60...1.60
        static let opponentPressureRange = 0.60...1.60
        static let phaseScaleRange = 0.60...1.60

        static let rankingMatchCatchUpMutationDelta = 0.12
        static let rankingPremiumMutationDelta = 0.12
        static let rankingPenaltyAvoidMutationDelta = 0.12
        static let jokerDeclarationMutationDelta = 0.10
        static let rolloutActivationMutationDelta = 0.10
        static let rolloutAdjustmentMutationDelta = 0.12
        static let endgameActivationMutationDelta = 0.10
        static let endgameAdjustmentMutationDelta = 0.12
        static let opponentPressureMutationDelta = 0.12
        static let phaseScaleMutationDelta = 0.10
    }

    struct RuntimePolicyEvolutionPatch {
        var rankingMatchCatchUpScale: Double
        var rankingPremiumScale: Double
        var rankingPenaltyAvoidScale: Double
        var jokerDeclarationScale: Double
        var rolloutActivationScale: Double
        var rolloutAdjustmentScale: Double
        var endgameActivationScale: Double
        var endgameAdjustmentScale: Double
        var opponentPressureScale: Double
        var phaseRankingScale: Double
        var phaseRolloutScale: Double
        var phaseJokerScale: Double
        var phaseBlindScale: Double

        static let identity = RuntimePolicyEvolutionPatch(
            rankingMatchCatchUpScale: 1.0,
            rankingPremiumScale: 1.0,
            rankingPenaltyAvoidScale: 1.0,
            jokerDeclarationScale: 1.0,
            rolloutActivationScale: 1.0,
            rolloutAdjustmentScale: 1.0,
            endgameActivationScale: 1.0,
            endgameAdjustmentScale: 1.0,
            opponentPressureScale: 1.0,
            phaseRankingScale: 1.0,
            phaseRolloutScale: 1.0,
            phaseJokerScale: 1.0,
            phaseBlindScale: 1.0
        )

        static func extract(
            from policy: BotRuntimePolicy,
            relativeTo baseline: BotRuntimePolicy
        ) -> RuntimePolicyEvolutionPatch {
            RuntimePolicyEvolutionPatch(
                rankingMatchCatchUpScale: BotSelfPlayEvolutionEngine.averageScale(
                    [
                        (policy.ranking.matchCatchUpChaseAggressionBase, baseline.ranking.matchCatchUpChaseAggressionBase),
                        (policy.ranking.matchCatchUpChaseAggressionPressureWeight, baseline.ranking.matchCatchUpChaseAggressionPressureWeight),
                        (policy.ranking.matchCatchUpFinalTrickUrgencyBonus, baseline.ranking.matchCatchUpFinalTrickUrgencyBonus),
                        (policy.ranking.matchCatchUpOpponentUrgencyBase, baseline.ranking.matchCatchUpOpponentUrgencyBase),
                        (policy.ranking.matchCatchUpPreservePremiumPenalty, baseline.ranking.matchCatchUpPreservePremiumPenalty),
                        (policy.ranking.matchCatchUpUrgencyWeightBase, baseline.ranking.matchCatchUpUrgencyWeightBase),
                        (policy.ranking.matchCatchUpUrgencyWeightProgress, baseline.ranking.matchCatchUpUrgencyWeightProgress),
                        (policy.ranking.matchCatchUpConservativeDumpBase, baseline.ranking.matchCatchUpConservativeDumpBase),
                        (policy.ranking.matchCatchUpConservativeDumpThreatWeight, baseline.ranking.matchCatchUpConservativeDumpThreatWeight),
                        (policy.ranking.matchCatchUpConservativeDumpScoreWeight, baseline.ranking.matchCatchUpConservativeDumpScoreWeight),
                        (policy.ranking.matchCatchUpDenyOpponentPenaltyBase, baseline.ranking.matchCatchUpDenyOpponentPenaltyBase)
                    ],
                    range: RuntimePolicyGeneSpec.rankingMatchCatchUpRange
                ),
                rankingPremiumScale: BotSelfPlayEvolutionEngine.averageScale(
                    [
                        (policy.ranking.premiumPreserveChaseBonusBase, baseline.ranking.premiumPreserveChaseBonusBase),
                        (policy.ranking.premiumPreserveChaseBonusProgress, baseline.ranking.premiumPreserveChaseBonusProgress),
                        (policy.ranking.premiumPreserveDumpBonus, baseline.ranking.premiumPreserveDumpBonus),
                        (policy.ranking.premiumPreserveZeroChasePenalty, baseline.ranking.premiumPreserveZeroChasePenalty),
                        (policy.ranking.premiumPreserveZeroDumpBonus, baseline.ranking.premiumPreserveZeroDumpBonus),
                        (policy.ranking.premiumDenyChaseBonus, baseline.ranking.premiumDenyChaseBonus),
                        (policy.ranking.premiumDenyDumpPenalty, baseline.ranking.premiumDenyDumpPenalty)
                    ],
                    range: RuntimePolicyGeneSpec.rankingPremiumRange
                ),
                rankingPenaltyAvoidScale: BotSelfPlayEvolutionEngine.averageScale(
                    [
                        (policy.ranking.penaltyAvoidOverbidPenalty, baseline.ranking.penaltyAvoidOverbidPenalty),
                        (policy.ranking.penaltyAvoidDumpBonus, baseline.ranking.penaltyAvoidDumpBonus),
                        (policy.ranking.penaltyAvoidProjectedScoreWeight, baseline.ranking.penaltyAvoidProjectedScoreWeight),
                        (policy.ranking.penaltyAvoidLateBlockBoost, baseline.ranking.penaltyAvoidLateBlockBoost)
                    ],
                    range: RuntimePolicyGeneSpec.rankingPenaltyAvoidRange
                ),
                jokerDeclarationScale: BotSelfPlayEvolutionEngine.averageScale(
                    [
                        (policy.ranking.jokerDeclaration.wishFinalChaseBonusBase, baseline.ranking.jokerDeclaration.wishFinalChaseBonusBase),
                        (policy.ranking.jokerDeclaration.aboveChaseBonusBase, baseline.ranking.jokerDeclaration.aboveChaseBonusBase),
                        (policy.ranking.jokerDeclaration.takesDumpBonusBase, baseline.ranking.jokerDeclaration.takesDumpBonusBase),
                        (policy.ranking.jokerDeclaration.goalChaseScaleBase, baseline.ranking.jokerDeclaration.goalChaseScaleBase),
                        (policy.ranking.jokerDeclaration.goalDumpScaleBase, baseline.ranking.jokerDeclaration.goalDumpScaleBase),
                        (policy.ranking.jokerDeclaration.earlyWishPenaltyBase, baseline.ranking.jokerDeclaration.earlyWishPenaltyBase)
                    ],
                    range: RuntimePolicyGeneSpec.jokerDeclarationRange
                ),
                rolloutActivationScale: BotSelfPlayEvolutionEngine.averageScale(
                    [
                        (policy.rollout.chaseUrgencyBase, baseline.rollout.chaseUrgencyBase),
                        (policy.rollout.dumpUrgencyBase, baseline.rollout.dumpUrgencyBase)
                    ],
                    range: RuntimePolicyGeneSpec.rolloutActivationRange
                ),
                rolloutAdjustmentScale: BotSelfPlayEvolutionEngine.averageScale(
                    [
                        (policy.rollout.adjustmentBase, baseline.rollout.adjustmentBase),
                        (policy.rollout.adjustmentUrgencyWeight, baseline.rollout.adjustmentUrgencyWeight)
                    ],
                    range: RuntimePolicyGeneSpec.rolloutAdjustmentRange
                ),
                endgameActivationScale: BotSelfPlayEvolutionEngine.averageScale(
                    [
                        (policy.endgame.weightBase, baseline.endgame.weightBase),
                        (policy.endgame.weightUrgencyMultiplier, baseline.endgame.weightUrgencyMultiplier)
                    ],
                    range: RuntimePolicyGeneSpec.endgameActivationRange
                ),
                endgameAdjustmentScale: BotSelfPlayEvolutionEngine.averageScale(
                    [(policy.endgame.adjustmentCap, baseline.endgame.adjustmentCap)],
                    range: RuntimePolicyGeneSpec.endgameAdjustmentRange
                ),
                opponentPressureScale: BotSelfPlayEvolutionEngine.averageScale(
                    [
                        (policy.opponentModeling.opponentBidPressureChaseBase, baseline.opponentModeling.opponentBidPressureChaseBase),
                        (policy.opponentModeling.opponentBidPressureChaseProgress, baseline.opponentModeling.opponentBidPressureChaseProgress),
                        (policy.opponentModeling.opponentBidPressureDumpBase, baseline.opponentModeling.opponentBidPressureDumpBase),
                        (policy.opponentModeling.opponentBidPressureDumpProgress, baseline.opponentModeling.opponentBidPressureDumpProgress),
                        (policy.opponentModeling.opponentIntentionChaseBase, baseline.opponentModeling.opponentIntentionChaseBase),
                        (policy.opponentModeling.opponentIntentionChaseProgress, baseline.opponentModeling.opponentIntentionChaseProgress),
                        (policy.opponentModeling.opponentIntentionDumpBase, baseline.opponentModeling.opponentIntentionDumpBase),
                        (policy.                opponentModeling.opponentIntentionDumpProgress, baseline.opponentModeling.opponentIntentionDumpProgress)
                    ],
                    range: RuntimePolicyGeneSpec.opponentPressureRange
                ),
                phaseRankingScale: 1.0,
                phaseRolloutScale: 1.0,
                phaseJokerScale: 1.0,
                phaseBlindScale: 1.0
            )
        }

        func apply(to baseline: BotRuntimePolicy) -> BotRuntimePolicy {
            var ranking = baseline.ranking

            ranking.matchCatchUpChaseAggressionBase *= rankingMatchCatchUpScale
            ranking.matchCatchUpChaseAggressionPressureWeight *= rankingMatchCatchUpScale
            ranking.matchCatchUpFinalTrickUrgencyBonus *= rankingMatchCatchUpScale
            ranking.matchCatchUpOpponentUrgencyBase *= rankingMatchCatchUpScale
            ranking.matchCatchUpPreservePremiumPenalty *= rankingMatchCatchUpScale
            ranking.matchCatchUpUrgencyWeightBase *= rankingMatchCatchUpScale
            ranking.matchCatchUpUrgencyWeightProgress *= rankingMatchCatchUpScale
            ranking.matchCatchUpConservativeDumpBase *= rankingMatchCatchUpScale
            ranking.matchCatchUpConservativeDumpThreatWeight *= rankingMatchCatchUpScale
            ranking.matchCatchUpConservativeDumpScoreWeight *= rankingMatchCatchUpScale
            ranking.matchCatchUpDenyOpponentPenaltyBase *= rankingMatchCatchUpScale

            ranking.premiumPreserveChaseBonusBase *= rankingPremiumScale
            ranking.premiumPreserveChaseBonusProgress *= rankingPremiumScale
            ranking.premiumPreserveDumpBonus *= rankingPremiumScale
            ranking.premiumPreserveZeroChasePenalty *= rankingPremiumScale
            ranking.premiumPreserveZeroDumpBonus *= rankingPremiumScale
            ranking.premiumDenyChaseBonus *= rankingPremiumScale
            ranking.premiumDenyDumpPenalty *= rankingPremiumScale

            ranking.penaltyAvoidOverbidPenalty *= rankingPenaltyAvoidScale
            ranking.penaltyAvoidDumpBonus *= rankingPenaltyAvoidScale
            ranking.penaltyAvoidProjectedScoreWeight *= rankingPenaltyAvoidScale
            ranking.penaltyAvoidLateBlockBoost *= rankingPenaltyAvoidScale

            ranking.phaseMatchCatchUp = PhaseMultipliers(
                early: ranking.phaseMatchCatchUp.early * phaseRankingScale,
                mid: ranking.phaseMatchCatchUp.mid * phaseRankingScale,
                late: ranking.phaseMatchCatchUp.late * phaseRankingScale
            )
            ranking.phasePremiumPressure = PhaseMultipliers(
                early: ranking.phasePremiumPressure.early * phaseRankingScale,
                mid: ranking.phasePremiumPressure.mid * phaseRankingScale,
                late: ranking.phasePremiumPressure.late * phaseRankingScale
            )
            ranking.phasePenaltyAvoid = PhaseMultipliers(
                early: ranking.phasePenaltyAvoid.early * phaseRankingScale,
                mid: ranking.phasePenaltyAvoid.mid * phaseRankingScale,
                late: ranking.phasePenaltyAvoid.late * phaseRankingScale
            )

            ranking.jokerDeclaration.wishFinalChaseBonusBase *= jokerDeclarationScale
            ranking.jokerDeclaration.aboveChaseBonusBase *= jokerDeclarationScale
            ranking.jokerDeclaration.takesDumpBonusBase *= jokerDeclarationScale
            ranking.jokerDeclaration.goalChaseScaleBase *= jokerDeclarationScale
            ranking.jokerDeclaration.goalDumpScaleBase *= jokerDeclarationScale
            ranking.jokerDeclaration.earlyWishPenaltyBase *= jokerDeclarationScale
            ranking.jokerDeclaration.phaseEarlySpend = PhaseMultipliers(
                early: ranking.jokerDeclaration.phaseEarlySpend.early * phaseJokerScale,
                mid: ranking.jokerDeclaration.phaseEarlySpend.mid * phaseJokerScale,
                late: ranking.jokerDeclaration.phaseEarlySpend.late * phaseJokerScale
            )
            ranking.jokerDeclaration.phaseLateSpend = PhaseMultipliers(
                early: ranking.jokerDeclaration.phaseLateSpend.early * phaseJokerScale,
                mid: ranking.jokerDeclaration.phaseLateSpend.mid * phaseJokerScale,
                late: ranking.jokerDeclaration.phaseLateSpend.late * phaseJokerScale
            )
            ranking.jokerDeclaration.phaseDeclarationPressure = PhaseMultipliers(
                early: ranking.jokerDeclaration.phaseDeclarationPressure.early * phaseJokerScale,
                mid: ranking.jokerDeclaration.phaseDeclarationPressure.mid * phaseJokerScale,
                late: ranking.jokerDeclaration.phaseDeclarationPressure.late * phaseJokerScale
            )

            var rollout = baseline.rollout
            rollout.chaseUrgencyBase *= rolloutActivationScale
            rollout.dumpUrgencyBase *= rolloutActivationScale
            rollout.adjustmentBase *= rolloutAdjustmentScale
            rollout.adjustmentUrgencyWeight *= rolloutAdjustmentScale
            rollout.phaseActivation = PhaseMultipliers(
                early: rollout.phaseActivation.early * phaseRolloutScale,
                mid: rollout.phaseActivation.mid * phaseRolloutScale,
                late: rollout.phaseActivation.late * phaseRolloutScale
            )
            rollout.phaseUtilityAdjustment = PhaseMultipliers(
                early: rollout.phaseUtilityAdjustment.early * phaseRolloutScale,
                mid: rollout.phaseUtilityAdjustment.mid * phaseRolloutScale,
                late: rollout.phaseUtilityAdjustment.late * phaseRolloutScale
            )

            var endgame = baseline.endgame
            endgame.weightBase *= endgameActivationScale
            endgame.weightUrgencyMultiplier *= endgameActivationScale
            endgame.adjustmentCap *= endgameAdjustmentScale

            var opponentModeling = baseline.opponentModeling
            opponentModeling.opponentBidPressureChaseBase *= opponentPressureScale
            opponentModeling.opponentBidPressureChaseProgress *= opponentPressureScale
            opponentModeling.opponentBidPressureDumpBase *= opponentPressureScale
            opponentModeling.opponentBidPressureDumpProgress *= opponentPressureScale
            opponentModeling.opponentIntentionChaseBase *= opponentPressureScale
            opponentModeling.opponentIntentionChaseProgress *= opponentPressureScale
            opponentModeling.opponentIntentionDumpBase *= opponentPressureScale
            opponentModeling.opponentIntentionDumpProgress *= opponentPressureScale

            var bidding = baseline.bidding
            var blindPolicy = bidding.blindPolicy
            blindPolicy.phaseBlock4 = PhaseMultipliers(
                early: blindPolicy.phaseBlock4.early * phaseBlindScale,
                mid: blindPolicy.phaseBlock4.mid * phaseBlindScale,
                late: blindPolicy.phaseBlock4.late * phaseBlindScale
            )
            bidding.blindPolicy = blindPolicy

            return BotRuntimePolicy(
                ranking: ranking,
                bidding: bidding,
                evaluator: baseline.evaluator,
                rollout: rollout,
                endgame: endgame,
                simulation: baseline.simulation,
                handStrength: baseline.handStrength,
                heuristics: baseline.heuristics,
                opponentModeling: opponentModeling
            )
        }
    }

    static func runtimePolicyPatch(
        from genome: EvolutionGenome
    ) -> RuntimePolicyEvolutionPatch {
        RuntimePolicyEvolutionPatch(
            rankingMatchCatchUpScale: genome.rankingMatchCatchUpScale,
            rankingPremiumScale: genome.rankingPremiumScale,
            rankingPenaltyAvoidScale: genome.rankingPenaltyAvoidScale,
            jokerDeclarationScale: genome.jokerDeclarationScale,
            rolloutActivationScale: genome.rolloutActivationScale,
            rolloutAdjustmentScale: genome.rolloutAdjustmentScale,
            endgameActivationScale: genome.endgameActivationScale,
            endgameAdjustmentScale: genome.endgameAdjustmentScale,
            opponentPressureScale: genome.opponentPressureScale,
            phaseRankingScale: genome.phaseRankingScale,
            phaseRolloutScale: genome.phaseRolloutScale,
            phaseJokerScale: genome.phaseJokerScale,
            phaseBlindScale: genome.phaseBlindScale
        )
    }

    static func runtimePolicyPatch(
        from policy: BotRuntimePolicy,
        difficulty: BotDifficulty
    ) -> RuntimePolicyEvolutionPatch {
        runtimePolicyPatch(
            from: policy,
            relativeTo: BotRuntimePolicy.preset(for: difficulty)
        )
    }

    static func runtimePolicyPatch(
        from policy: BotRuntimePolicy,
        relativeTo baseline: BotRuntimePolicy
    ) -> RuntimePolicyEvolutionPatch {
        RuntimePolicyEvolutionPatch.extract(
            from: policy,
            relativeTo: baseline
        )
    }

    static func applyingEvolutionScopeMask(
        _ genome: EvolutionGenome,
        config: SelfPlayEvolutionConfig
    ) -> EvolutionGenome {
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

        if !config.tuneRankingPolicy {
            masked.rankingMatchCatchUpScale = 1.0
            masked.rankingPremiumScale = 1.0
            masked.rankingPenaltyAvoidScale = 1.0
        }

        if !config.tuneRolloutPolicy {
            masked.rolloutActivationScale = 1.0
            masked.rolloutAdjustmentScale = 1.0
        }

        if !config.tuneEndgamePolicy {
            masked.endgameActivationScale = 1.0
            masked.endgameAdjustmentScale = 1.0
        }

        if !config.tuneOpponentModelingPolicy {
            masked.opponentPressureScale = 1.0
        }

        if !config.tuneJokerDeclarationPolicy {
            masked.jokerDeclarationScale = 1.0
        }

        if !config.tunePhasePolicy {
            masked.phaseRankingScale = 1.0
            masked.phaseRolloutScale = 1.0
            masked.phaseJokerScale = 1.0
            masked.phaseBlindScale = 1.0
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
            ),
            rankingMatchCatchUpScale: randomizedScale(
                base.rankingMatchCatchUpScale,
                magnitude: magnitude,
                range: RuntimePolicyGeneSpec.rankingMatchCatchUpRange,
                using: &rng
            ),
            rankingPremiumScale: randomizedScale(
                base.rankingPremiumScale,
                magnitude: magnitude,
                range: RuntimePolicyGeneSpec.rankingPremiumRange,
                using: &rng
            ),
            rankingPenaltyAvoidScale: randomizedScale(
                base.rankingPenaltyAvoidScale,
                magnitude: magnitude,
                range: RuntimePolicyGeneSpec.rankingPenaltyAvoidRange,
                using: &rng
            ),
            jokerDeclarationScale: randomizedScale(
                base.jokerDeclarationScale,
                magnitude: magnitude,
                range: RuntimePolicyGeneSpec.jokerDeclarationRange,
                using: &rng
            ),
            rolloutActivationScale: randomizedScale(
                base.rolloutActivationScale,
                magnitude: magnitude,
                range: RuntimePolicyGeneSpec.rolloutActivationRange,
                using: &rng
            ),
            rolloutAdjustmentScale: randomizedScale(
                base.rolloutAdjustmentScale,
                magnitude: magnitude,
                range: RuntimePolicyGeneSpec.rolloutAdjustmentRange,
                using: &rng
            ),
            endgameActivationScale: randomizedScale(
                base.endgameActivationScale,
                magnitude: magnitude,
                range: RuntimePolicyGeneSpec.endgameActivationRange,
                using: &rng
            ),
            endgameAdjustmentScale: randomizedScale(
                base.endgameAdjustmentScale,
                magnitude: magnitude,
                range: RuntimePolicyGeneSpec.endgameAdjustmentRange,
                using: &rng
            ),
            opponentPressureScale: randomizedScale(
                base.opponentPressureScale,
                magnitude: magnitude,
                range: RuntimePolicyGeneSpec.opponentPressureRange,
                using: &rng
            ),
            phaseRankingScale: randomizedScale(
                base.phaseRankingScale,
                magnitude: magnitude,
                range: RuntimePolicyGeneSpec.phaseScaleRange,
                using: &rng
            ),
            phaseRolloutScale: randomizedScale(
                base.phaseRolloutScale,
                magnitude: magnitude,
                range: RuntimePolicyGeneSpec.phaseScaleRange,
                using: &rng
            ),
            phaseJokerScale: randomizedScale(
                base.phaseJokerScale,
                magnitude: magnitude,
                range: RuntimePolicyGeneSpec.phaseScaleRange,
                using: &rng
            ),
            phaseBlindScale: randomizedScale(
                base.phaseBlindScale,
                magnitude: magnitude,
                range: RuntimePolicyGeneSpec.phaseScaleRange,
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
            ),
            rankingMatchCatchUpScale: mixedScale(
                first.rankingMatchCatchUpScale,
                second.rankingMatchCatchUpScale,
                range: RuntimePolicyGeneSpec.rankingMatchCatchUpRange,
                using: &rng
            ),
            rankingPremiumScale: mixedScale(
                first.rankingPremiumScale,
                second.rankingPremiumScale,
                range: RuntimePolicyGeneSpec.rankingPremiumRange,
                using: &rng
            ),
            rankingPenaltyAvoidScale: mixedScale(
                first.rankingPenaltyAvoidScale,
                second.rankingPenaltyAvoidScale,
                range: RuntimePolicyGeneSpec.rankingPenaltyAvoidRange,
                using: &rng
            ),
            jokerDeclarationScale: mixedScale(
                first.jokerDeclarationScale,
                second.jokerDeclarationScale,
                range: RuntimePolicyGeneSpec.jokerDeclarationRange,
                using: &rng
            ),
            rolloutActivationScale: mixedScale(
                first.rolloutActivationScale,
                second.rolloutActivationScale,
                range: RuntimePolicyGeneSpec.rolloutActivationRange,
                using: &rng
            ),
            rolloutAdjustmentScale: mixedScale(
                first.rolloutAdjustmentScale,
                second.rolloutAdjustmentScale,
                range: RuntimePolicyGeneSpec.rolloutAdjustmentRange,
                using: &rng
            ),
            endgameActivationScale: mixedScale(
                first.endgameActivationScale,
                second.endgameActivationScale,
                range: RuntimePolicyGeneSpec.endgameActivationRange,
                using: &rng
            ),
            endgameAdjustmentScale: mixedScale(
                first.endgameAdjustmentScale,
                second.endgameAdjustmentScale,
                range: RuntimePolicyGeneSpec.endgameAdjustmentRange,
                using: &rng
            ),
            opponentPressureScale: mixedScale(
                first.opponentPressureScale,
                second.opponentPressureScale,
                range: RuntimePolicyGeneSpec.opponentPressureRange,
                using: &rng
            ),
            phaseRankingScale: mixedScale(
                first.phaseRankingScale,
                second.phaseRankingScale,
                range: RuntimePolicyGeneSpec.phaseScaleRange,
                using: &rng
            ),
            phaseRolloutScale: mixedScale(
                first.phaseRolloutScale,
                second.phaseRolloutScale,
                range: RuntimePolicyGeneSpec.phaseScaleRange,
                using: &rng
            ),
            phaseJokerScale: mixedScale(
                first.phaseJokerScale,
                second.phaseJokerScale,
                range: RuntimePolicyGeneSpec.phaseScaleRange,
                using: &rng
            ),
            phaseBlindScale: mixedScale(
                first.phaseBlindScale,
                second.phaseBlindScale,
                range: RuntimePolicyGeneSpec.phaseScaleRange,
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
        mutateScale(
            &mutated.rankingMatchCatchUpScale,
            chance: chance,
            magnitude: mutationMagnitude(
                base: magnitude,
                delta: RuntimePolicyGeneSpec.rankingMatchCatchUpMutationDelta
            ),
            range: RuntimePolicyGeneSpec.rankingMatchCatchUpRange,
            using: &rng
        )
        mutateScale(
            &mutated.rankingPremiumScale,
            chance: chance,
            magnitude: mutationMagnitude(
                base: magnitude,
                delta: RuntimePolicyGeneSpec.rankingPremiumMutationDelta
            ),
            range: RuntimePolicyGeneSpec.rankingPremiumRange,
            using: &rng
        )
        mutateScale(
            &mutated.rankingPenaltyAvoidScale,
            chance: chance,
            magnitude: mutationMagnitude(
                base: magnitude,
                delta: RuntimePolicyGeneSpec.rankingPenaltyAvoidMutationDelta
            ),
            range: RuntimePolicyGeneSpec.rankingPenaltyAvoidRange,
            using: &rng
        )
        mutateScale(
            &mutated.jokerDeclarationScale,
            chance: chance,
            magnitude: mutationMagnitude(
                base: magnitude,
                delta: RuntimePolicyGeneSpec.jokerDeclarationMutationDelta
            ),
            range: RuntimePolicyGeneSpec.jokerDeclarationRange,
            using: &rng
        )
        mutateScale(
            &mutated.rolloutActivationScale,
            chance: chance,
            magnitude: mutationMagnitude(
                base: magnitude,
                delta: RuntimePolicyGeneSpec.rolloutActivationMutationDelta
            ),
            range: RuntimePolicyGeneSpec.rolloutActivationRange,
            using: &rng
        )
        mutateScale(
            &mutated.rolloutAdjustmentScale,
            chance: chance,
            magnitude: mutationMagnitude(
                base: magnitude,
                delta: RuntimePolicyGeneSpec.rolloutAdjustmentMutationDelta
            ),
            range: RuntimePolicyGeneSpec.rolloutAdjustmentRange,
            using: &rng
        )
        mutateScale(
            &mutated.endgameActivationScale,
            chance: chance,
            magnitude: mutationMagnitude(
                base: magnitude,
                delta: RuntimePolicyGeneSpec.endgameActivationMutationDelta
            ),
            range: RuntimePolicyGeneSpec.endgameActivationRange,
            using: &rng
        )
        mutateScale(
            &mutated.endgameAdjustmentScale,
            chance: chance,
            magnitude: mutationMagnitude(
                base: magnitude,
                delta: RuntimePolicyGeneSpec.endgameAdjustmentMutationDelta
            ),
            range: RuntimePolicyGeneSpec.endgameAdjustmentRange,
            using: &rng
        )
        mutateScale(
            &mutated.opponentPressureScale,
            chance: chance,
            magnitude: mutationMagnitude(
                base: magnitude,
                delta: RuntimePolicyGeneSpec.opponentPressureMutationDelta
            ),
            range: RuntimePolicyGeneSpec.opponentPressureRange,
            using: &rng
        )
        mutateScale(
            &mutated.phaseRankingScale,
            chance: chance,
            magnitude: mutationMagnitude(
                base: magnitude,
                delta: RuntimePolicyGeneSpec.phaseScaleMutationDelta
            ),
            range: RuntimePolicyGeneSpec.phaseScaleRange,
            using: &rng
        )
        mutateScale(
            &mutated.phaseRolloutScale,
            chance: chance,
            magnitude: mutationMagnitude(
                base: magnitude,
                delta: RuntimePolicyGeneSpec.phaseScaleMutationDelta
            ),
            range: RuntimePolicyGeneSpec.phaseScaleRange,
            using: &rng
        )
        mutateScale(
            &mutated.phaseJokerScale,
            chance: chance,
            magnitude: mutationMagnitude(
                base: magnitude,
                delta: RuntimePolicyGeneSpec.phaseScaleMutationDelta
            ),
            range: RuntimePolicyGeneSpec.phaseScaleRange,
            using: &rng
        )
        mutateScale(
            &mutated.phaseBlindScale,
            chance: chance,
            magnitude: mutationMagnitude(
                base: magnitude,
                delta: RuntimePolicyGeneSpec.phaseScaleMutationDelta
            ),
            range: RuntimePolicyGeneSpec.phaseScaleRange,
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
            ),
            playerChosenPairBonus: baseTrump.playerChosenPairBonus,
            lengthBonusPerExtraCard: baseTrump.lengthBonusPerExtraCard,
            densityBonusWeight: baseTrump.densityBonusWeight,
            sequenceBonusWeight: baseTrump.sequenceBonusWeight,
            controlBonusWeight: baseTrump.controlBonusWeight,
            jokerSynergyBase: baseTrump.jokerSynergyBase,
            jokerSynergyControlWeight: baseTrump.jokerSynergyControlWeight
        )

        let patch = runtimePolicyPatch(from: genome)
        let patchedRuntimePolicy = patch.apply(to: base.runtimePolicy)

        return BotTuning(
            difficulty: base.difficulty,
            turnStrategy: turnStrategy,
            bidding: bidding,
            trumpSelection: trumpSelection,
            runtimePolicy: patchedRuntimePolicy,
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

    private static func mutationMagnitude(
        base: Double,
        delta: Double
    ) -> Double {
        guard base > 0.0 else { return 0.0 }
        let referenceMagnitude = 0.18
        return base * (delta / referenceMagnitude)
    }

    private static func averageScale(
        _ pairs: [(Double, Double)],
        range: ClosedRange<Double>
    ) -> Double {
        let ratios = pairs.compactMap { current, baseline -> Double? in
            guard abs(baseline) > 1e-9 else { return nil }
            return current / baseline
        }

        guard !ratios.isEmpty else { return 1.0 }
        let meanRatio = ratios.reduce(0.0, +) / Double(ratios.count)
        return clamp(meanRatio, to: range)
    }

    private static func clamp(
        _ value: Double,
        to range: ClosedRange<Double>
    ) -> Double {
        return min(max(value, range.lowerBound), range.upperBound)
    }
}
