//
//  BotTuning+Presets.swift
//  Jocker
//
//  Created by Codex on 07.03.2026.
//

import Foundation

extension BotTuning {
    static let hardBaselineTurnStrategy = TurnStrategy(
        utilityTieTolerance: 0.000_05,
        chaseWinProbabilityWeight: 91.964813,
        chaseThreatPenaltyWeight: 0.194321,
        chaseSpendJokerPenalty: 120.116961,
        chaseLeadWishBonus: 14.0,
        dumpAvoidWinWeight: 30.414311,
        dumpThreatRewardWeight: 0.642694,
        dumpSpendJokerPenalty: 93.217338,
        dumpFaceUpNonLeadJokerPenalty: 45.0,
        dumpLeadTakesNonTrumpBonus: 8.0,
        holdFromDistributionWeight: 0.921471,
        powerConfidenceWeight: 0.078529,
        futureJokerPower: 2.240398,
        futureRegularBasePower: 0.18,
        futureRegularRankWeight: 0.82,
        futureTrumpBaseBonus: 0.42,
        futureTrumpRankWeight: 0.35,
        futureHighRankBonus: 0.15,
        futureLongSuitBonusPerCard: 0.07,
        futureTricksScale: 0.205603,
        threatFaceDownLeadJoker: 28.0,
        threatFaceDownNonLeadJoker: 3.0,
        threatLeadTakesJoker: 45.0,
        threatLeadAboveJoker: 95.0,
        threatLeadWishJoker: 110.0,
        threatNonLeadFaceUpJoker: 110.0,
        threatTrumpBonus: 21.944013,
        threatHighRankBonus: 7.979640,
        powerFaceDownJoker: 1,
        powerLeadTakesJoker: 45,
        powerLeadAboveJoker: 995,
        powerLeadWishJoker: 1000,
        powerNonLeadFaceUpJoker: 1000,
        powerTrumpBonus: 120,
        powerLeadSuitBonus: 55,
        powerNormalizationValue: 1000.0
    )

    static let hardBaselineBidding = Bidding(
        expectedJokerPower: 0.826323,
        expectedRankWeight: 0.100000,
        expectedTrumpBaseBonus: 0.050000,
        expectedTrumpRankWeight: 0.051622,
        expectedHighRankBonus: 0.020000,
        expectedLongSuitBonusPerCard: 0.040768,
        expectedTrumpDensityBonus: 0.798904,
        expectedNoTrumpHighCardBonus: 0.260075,
        expectedNoTrumpJokerSynergy: 0.156046,
        blindDesperateBehindThreshold: 362,
        blindCatchUpBehindThreshold: 145,
        blindSafeLeadThreshold: 305,
        blindDesperateTargetShare: 0.458452,
        blindCatchUpTargetShare: 0.374449,
        blindCatchUpConservativeTargetShare: 0.229112
    )

    static let hardBaselineTrumpSelection = TrumpSelection(
        cardBasePower: 0.464914,
        minimumPowerToDeclareTrump: 1.977804,
        playerChosenPairBonus: 1.40,
        lengthBonusPerExtraCard: 0.36,
        densityBonusWeight: 0.90,
        sequenceBonusWeight: 0.62,
        controlBonusWeight: 0.46,
        jokerSynergyBase: 0.40,
        jokerSynergyControlWeight: 0.48
    )

    static let hardBaselineTiming = Timing(
        playingBotTurnDelay: 0.22,
        biddingStepDelay: 0.15,
        trickResolutionDelay: 0.45
    )

    static let hardBaselinePreset = BotTuning(
        difficulty: .hard,
        turnStrategy: hardBaselineTurnStrategy,
        bidding: hardBaselineBidding,
        trumpSelection: hardBaselineTrumpSelection,
        runtimePolicy: BotRuntimePolicy.preset(for: .hard),
        timing: hardBaselineTiming
    )

    static func normalPreset(from hard: BotTuning) -> BotTuning {
        BotTuning(
            difficulty: .normal,
            turnStrategy: normalTurnStrategy(from: hard.turnStrategy),
            bidding: normalBidding(from: hard.bidding),
            trumpSelection: normalTrumpSelection(from: hard.trumpSelection),
            runtimePolicy: BotRuntimePolicy.preset(for: .normal),
            timing: normalTiming(from: hard.timing)
        )
    }

    static func easyPreset(from hard: BotTuning) -> BotTuning {
        BotTuning(
            difficulty: .easy,
            turnStrategy: easyTurnStrategy(from: hard.turnStrategy),
            bidding: easyBidding(from: hard.bidding),
            trumpSelection: easyTrumpSelection(from: hard.trumpSelection),
            runtimePolicy: BotRuntimePolicy.preset(for: .easy),
            timing: easyTiming(from: hard.timing)
        )
    }

    private static func normalTurnStrategy(from base: TurnStrategy) -> TurnStrategy {
        var value = base
        value.utilityTieTolerance = 0.000_1
        value.chaseWinProbabilityWeight = 50.0
        value.chaseThreatPenaltyWeight = 0.14
        value.chaseSpendJokerPenalty = 55.0
        value.chaseLeadWishBonus = 8.0
        value.dumpAvoidWinWeight = 50.0
        value.dumpThreatRewardWeight = 0.18
        value.dumpSpendJokerPenalty = 70.0
        value.dumpFaceUpNonLeadJokerPenalty = 35.0
        value.dumpLeadTakesNonTrumpBonus = 6.0
        value.holdFromDistributionWeight = 0.82
        value.powerConfidenceWeight = 0.18
        value.futureJokerPower = 1.25
        value.futureRegularBasePower = 0.15
        value.futureRegularRankWeight = 0.75
        value.futureTrumpBaseBonus = 0.35
        value.futureTrumpRankWeight = 0.30
        value.futureHighRankBonus = 0.12
        value.futureLongSuitBonusPerCard = 0.05
        value.futureTricksScale = 0.62
        value.threatFaceDownLeadJoker = 24.0
        value.threatFaceDownNonLeadJoker = 2.0
        value.threatLeadTakesJoker = 36.0
        value.threatLeadAboveJoker = 88.0
        value.threatLeadWishJoker = 100.0
        value.threatNonLeadFaceUpJoker = 100.0
        value.threatTrumpBonus = 9.0
        value.threatHighRankBonus = 3.0
        value.powerLeadTakesJoker = 30
        value.powerLeadAboveJoker = 980
        value.powerTrumpBonus = 100
        value.powerLeadSuitBonus = 40
        value.powerNormalizationValue = 1000.0
        return value
    }

    private static func easyTurnStrategy(from base: TurnStrategy) -> TurnStrategy {
        var value = base
        value.utilityTieTolerance = 0.001
        value.chaseWinProbabilityWeight = 42.0
        value.chaseThreatPenaltyWeight = 0.10
        value.chaseSpendJokerPenalty = 35.0
        value.chaseLeadWishBonus = 4.0
        value.dumpAvoidWinWeight = 42.0
        value.dumpThreatRewardWeight = 0.11
        value.dumpSpendJokerPenalty = 45.0
        value.dumpFaceUpNonLeadJokerPenalty = 20.0
        value.dumpLeadTakesNonTrumpBonus = 2.0
        value.holdFromDistributionWeight = 0.68
        value.powerConfidenceWeight = 0.32
        value.futureJokerPower = 1.05
        value.futureRegularBasePower = 0.10
        value.futureRegularRankWeight = 0.60
        value.futureTrumpBaseBonus = 0.24
        value.futureTrumpRankWeight = 0.20
        value.futureHighRankBonus = 0.08
        value.futureLongSuitBonusPerCard = 0.03
        value.futureTricksScale = 0.52
        value.threatFaceDownLeadJoker = 18.0
        value.threatFaceDownNonLeadJoker = 1.0
        value.threatLeadTakesJoker = 24.0
        value.threatLeadAboveJoker = 72.0
        value.threatLeadWishJoker = 90.0
        value.threatNonLeadFaceUpJoker = 90.0
        value.threatTrumpBonus = 7.0
        value.threatHighRankBonus = 2.0
        value.powerLeadTakesJoker = 24
        value.powerLeadAboveJoker = 900
        value.powerLeadWishJoker = 960
        value.powerNonLeadFaceUpJoker = 960
        value.powerTrumpBonus = 80
        value.powerLeadSuitBonus = 24
        value.powerNormalizationValue = 960.0
        return value
    }

    private static func normalBidding(from base: Bidding) -> Bidding {
        var value = base
        value.expectedJokerPower = 1.1
        value.expectedRankWeight = 0.72
        value.expectedTrumpBaseBonus = 0.55
        value.expectedTrumpRankWeight = 0.45
        value.expectedHighRankBonus = 0.18
        value.expectedLongSuitBonusPerCard = 0.12
        value.expectedTrumpDensityBonus = 0.38
        value.expectedNoTrumpHighCardBonus = 0.16
        value.expectedNoTrumpJokerSynergy = 0.48
        value.blindDesperateBehindThreshold = 250
        value.blindCatchUpBehindThreshold = 130
        value.blindSafeLeadThreshold = 180
        value.blindDesperateTargetShare = 0.65
        value.blindCatchUpTargetShare = 0.45
        value.blindCatchUpConservativeTargetShare = 0.26
        return value
    }

    private static func easyBidding(from base: Bidding) -> Bidding {
        var value = base
        value.expectedJokerPower = 0.9
        value.expectedRankWeight = 0.58
        value.expectedTrumpBaseBonus = 0.35
        value.expectedTrumpRankWeight = 0.28
        value.expectedHighRankBonus = 0.10
        value.expectedLongSuitBonusPerCard = 0.08
        value.expectedTrumpDensityBonus = 0.25
        value.expectedNoTrumpHighCardBonus = 0.10
        value.expectedNoTrumpJokerSynergy = 0.30
        value.blindDesperateBehindThreshold = 320
        value.blindCatchUpBehindThreshold = 180
        value.blindSafeLeadThreshold = 140
        value.blindDesperateTargetShare = 0.45
        value.blindCatchUpTargetShare = 0.30
        value.blindCatchUpConservativeTargetShare = 0.20
        return value
    }

    private static func normalTrumpSelection(from base: TrumpSelection) -> TrumpSelection {
        var value = base
        value.cardBasePower = 0.45
        value.minimumPowerToDeclareTrump = 1.55
        return value
    }

    private static func easyTrumpSelection(from base: TrumpSelection) -> TrumpSelection {
        var value = base
        value.cardBasePower = 0.35
        value.minimumPowerToDeclareTrump = 1.90
        return value
    }

    private static func normalTiming(from base: Timing) -> Timing {
        var value = base
        value.playingBotTurnDelay = 0.35
        value.biddingStepDelay = 0.25
        value.trickResolutionDelay = 0.55
        return value
    }

    private static func easyTiming(from base: Timing) -> Timing {
        var value = base
        value.playingBotTurnDelay = 0.55
        value.biddingStepDelay = 0.35
        value.trickResolutionDelay = 0.65
        return value
    }
}
