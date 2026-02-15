//
//  BotTuning.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

/// Centralized coefficients and timing presets for bot AI.
struct BotTuning {
    struct TurnStrategy {
        let utilityTieTolerance: Double

        let chaseWinProbabilityWeight: Double
        let chaseThreatPenaltyWeight: Double
        let chaseSpendJokerPenalty: Double
        let chaseLeadWishBonus: Double

        let dumpAvoidWinWeight: Double
        let dumpThreatRewardWeight: Double
        let dumpSpendJokerPenalty: Double
        let dumpFaceUpNonLeadJokerPenalty: Double
        let dumpLeadTakesNonTrumpBonus: Double

        let holdFromDistributionWeight: Double
        let powerConfidenceWeight: Double

        let futureJokerPower: Double
        let futureRegularBasePower: Double
        let futureRegularRankWeight: Double
        let futureTrumpBaseBonus: Double
        let futureTrumpRankWeight: Double
        let futureHighRankBonus: Double
        let futureLongSuitBonusPerCard: Double
        let futureTricksScale: Double

        let threatFaceDownLeadJoker: Double
        let threatFaceDownNonLeadJoker: Double
        let threatLeadTakesJoker: Double
        let threatLeadAboveJoker: Double
        let threatLeadWishJoker: Double
        let threatNonLeadFaceUpJoker: Double
        let threatTrumpBonus: Double
        let threatHighRankBonus: Double

        let powerFaceDownJoker: Int
        let powerLeadTakesJoker: Int
        let powerLeadAboveJoker: Int
        let powerLeadWishJoker: Int
        let powerNonLeadFaceUpJoker: Int
        let powerTrumpBonus: Int
        let powerLeadSuitBonus: Int
        let powerNormalizationValue: Double
    }

    struct Bidding {
        let expectedJokerPower: Double
        let expectedRankWeight: Double
        let expectedTrumpBaseBonus: Double
        let expectedTrumpRankWeight: Double
        let expectedHighRankBonus: Double

        let blindDesperateBehindThreshold: Int
        let blindCatchUpBehindThreshold: Int
        let blindSafeLeadThreshold: Int
        let blindDesperateTargetShare: Double
        let blindCatchUpTargetShare: Double
    }

    struct TrumpSelection {
        let cardBasePower: Double
        let minimumPowerToDeclareTrump: Double
    }

    struct Timing {
        let playingBotTurnDelay: TimeInterval
        let biddingStepDelay: TimeInterval
        let trickResolutionDelay: TimeInterval
    }

    let difficulty: BotDifficulty
    let turnStrategy: TurnStrategy
    let bidding: Bidding
    let trumpSelection: TrumpSelection
    let timing: Timing

    init(difficulty: BotDifficulty) {
        self = BotTuning.preset(for: difficulty)
    }

    init(
        difficulty: BotDifficulty,
        turnStrategy: TurnStrategy,
        bidding: Bidding,
        trumpSelection: TrumpSelection,
        timing: Timing
    ) {
        self.difficulty = difficulty
        self.turnStrategy = turnStrategy
        self.bidding = bidding
        self.trumpSelection = trumpSelection
        self.timing = timing
    }

    private static func preset(for difficulty: BotDifficulty) -> BotTuning {
        switch difficulty {
        case .easy:
            return BotTuning(
                difficulty: .easy,
                turnStrategy: TurnStrategy(
                    utilityTieTolerance: 0.001,

                    chaseWinProbabilityWeight: 42.0,
                    chaseThreatPenaltyWeight: 0.10,
                    chaseSpendJokerPenalty: 35.0,
                    chaseLeadWishBonus: 4.0,

                    dumpAvoidWinWeight: 42.0,
                    dumpThreatRewardWeight: 0.11,
                    dumpSpendJokerPenalty: 45.0,
                    dumpFaceUpNonLeadJokerPenalty: 20.0,
                    dumpLeadTakesNonTrumpBonus: 2.0,

                    holdFromDistributionWeight: 0.68,
                    powerConfidenceWeight: 0.32,

                    futureJokerPower: 1.05,
                    futureRegularBasePower: 0.10,
                    futureRegularRankWeight: 0.60,
                    futureTrumpBaseBonus: 0.24,
                    futureTrumpRankWeight: 0.20,
                    futureHighRankBonus: 0.08,
                    futureLongSuitBonusPerCard: 0.03,
                    futureTricksScale: 0.52,

                    threatFaceDownLeadJoker: 18.0,
                    threatFaceDownNonLeadJoker: 1.0,
                    threatLeadTakesJoker: 24.0,
                    threatLeadAboveJoker: 72.0,
                    threatLeadWishJoker: 90.0,
                    threatNonLeadFaceUpJoker: 90.0,
                    threatTrumpBonus: 7.0,
                    threatHighRankBonus: 2.0,

                    powerFaceDownJoker: 1,
                    powerLeadTakesJoker: 24,
                    powerLeadAboveJoker: 900,
                    powerLeadWishJoker: 960,
                    powerNonLeadFaceUpJoker: 960,
                    powerTrumpBonus: 80,
                    powerLeadSuitBonus: 24,
                    powerNormalizationValue: 960.0
                ),
                bidding: Bidding(
                    expectedJokerPower: 0.9,
                    expectedRankWeight: 0.58,
                    expectedTrumpBaseBonus: 0.35,
                    expectedTrumpRankWeight: 0.28,
                    expectedHighRankBonus: 0.10,

                    blindDesperateBehindThreshold: 320,
                    blindCatchUpBehindThreshold: 180,
                    blindSafeLeadThreshold: 140,
                    blindDesperateTargetShare: 0.45,
                    blindCatchUpTargetShare: 0.30
                ),
                trumpSelection: TrumpSelection(
                    cardBasePower: 0.35,
                    minimumPowerToDeclareTrump: 1.90
                ),
                timing: Timing(
                    playingBotTurnDelay: 0.55,
                    biddingStepDelay: 0.35,
                    trickResolutionDelay: 0.65
                )
            )

        case .normal:
            return BotTuning(
                difficulty: .normal,
                turnStrategy: TurnStrategy(
                    utilityTieTolerance: 0.000_1,

                    chaseWinProbabilityWeight: 50.0,
                    chaseThreatPenaltyWeight: 0.14,
                    chaseSpendJokerPenalty: 55.0,
                    chaseLeadWishBonus: 8.0,

                    dumpAvoidWinWeight: 50.0,
                    dumpThreatRewardWeight: 0.18,
                    dumpSpendJokerPenalty: 70.0,
                    dumpFaceUpNonLeadJokerPenalty: 35.0,
                    dumpLeadTakesNonTrumpBonus: 6.0,

                    holdFromDistributionWeight: 0.82,
                    powerConfidenceWeight: 0.18,

                    futureJokerPower: 1.25,
                    futureRegularBasePower: 0.15,
                    futureRegularRankWeight: 0.75,
                    futureTrumpBaseBonus: 0.35,
                    futureTrumpRankWeight: 0.30,
                    futureHighRankBonus: 0.12,
                    futureLongSuitBonusPerCard: 0.05,
                    futureTricksScale: 0.62,

                    threatFaceDownLeadJoker: 24.0,
                    threatFaceDownNonLeadJoker: 2.0,
                    threatLeadTakesJoker: 36.0,
                    threatLeadAboveJoker: 88.0,
                    threatLeadWishJoker: 100.0,
                    threatNonLeadFaceUpJoker: 100.0,
                    threatTrumpBonus: 9.0,
                    threatHighRankBonus: 3.0,

                    powerFaceDownJoker: 1,
                    powerLeadTakesJoker: 30,
                    powerLeadAboveJoker: 980,
                    powerLeadWishJoker: 1000,
                    powerNonLeadFaceUpJoker: 1000,
                    powerTrumpBonus: 100,
                    powerLeadSuitBonus: 40,
                    powerNormalizationValue: 1000.0
                ),
                bidding: Bidding(
                    expectedJokerPower: 1.1,
                    expectedRankWeight: 0.72,
                    expectedTrumpBaseBonus: 0.55,
                    expectedTrumpRankWeight: 0.45,
                    expectedHighRankBonus: 0.18,

                    blindDesperateBehindThreshold: 250,
                    blindCatchUpBehindThreshold: 130,
                    blindSafeLeadThreshold: 180,
                    blindDesperateTargetShare: 0.65,
                    blindCatchUpTargetShare: 0.45
                ),
                trumpSelection: TrumpSelection(
                    cardBasePower: 0.45,
                    minimumPowerToDeclareTrump: 1.55
                ),
                timing: Timing(
                    playingBotTurnDelay: 0.35,
                    biddingStepDelay: 0.25,
                    trickResolutionDelay: 0.55
                )
            )

        case .hard:
            return BotTuning(
                difficulty: .hard,
                turnStrategy: TurnStrategy(
                    utilityTieTolerance: 0.000_05,

                    chaseWinProbabilityWeight: 55.0,
                    chaseThreatPenaltyWeight: 0.18,
                    chaseSpendJokerPenalty: 70.0,
                    chaseLeadWishBonus: 10.0,

                    dumpAvoidWinWeight: 55.0,
                    dumpThreatRewardWeight: 0.24,
                    dumpSpendJokerPenalty: 85.0,
                    dumpFaceUpNonLeadJokerPenalty: 45.0,
                    dumpLeadTakesNonTrumpBonus: 8.0,

                    holdFromDistributionWeight: 0.90,
                    powerConfidenceWeight: 0.10,

                    futureJokerPower: 1.35,
                    futureRegularBasePower: 0.18,
                    futureRegularRankWeight: 0.82,
                    futureTrumpBaseBonus: 0.42,
                    futureTrumpRankWeight: 0.35,
                    futureHighRankBonus: 0.15,
                    futureLongSuitBonusPerCard: 0.07,
                    futureTricksScale: 0.70,

                    threatFaceDownLeadJoker: 28.0,
                    threatFaceDownNonLeadJoker: 3.0,
                    threatLeadTakesJoker: 45.0,
                    threatLeadAboveJoker: 95.0,
                    threatLeadWishJoker: 110.0,
                    threatNonLeadFaceUpJoker: 110.0,
                    threatTrumpBonus: 11.0,
                    threatHighRankBonus: 4.0,

                    powerFaceDownJoker: 1,
                    powerLeadTakesJoker: 45,
                    powerLeadAboveJoker: 995,
                    powerLeadWishJoker: 1000,
                    powerNonLeadFaceUpJoker: 1000,
                    powerTrumpBonus: 120,
                    powerLeadSuitBonus: 55,
                    powerNormalizationValue: 1000.0
                ),
                bidding: Bidding(
                    expectedJokerPower: 1.25,
                    expectedRankWeight: 0.82,
                    expectedTrumpBaseBonus: 0.65,
                    expectedTrumpRankWeight: 0.55,
                    expectedHighRankBonus: 0.24,

                    blindDesperateBehindThreshold: 210,
                    blindCatchUpBehindThreshold: 100,
                    blindSafeLeadThreshold: 240,
                    blindDesperateTargetShare: 0.72,
                    blindCatchUpTargetShare: 0.52
                ),
                trumpSelection: TrumpSelection(
                    cardBasePower: 0.52,
                    minimumPowerToDeclareTrump: 1.30
                ),
                timing: Timing(
                    playingBotTurnDelay: 0.22,
                    biddingStepDelay: 0.15,
                    trickResolutionDelay: 0.45
                )
            )
        }
    }
}
