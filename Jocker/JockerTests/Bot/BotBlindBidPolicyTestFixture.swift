//
//  BotBlindBidPolicyTestFixture.swift
//  JockerTests
//
//  Created by Codex on 06.03.2026.
//

import Foundation
@testable import Jocker

struct BotBlindBidPolicyTestFixture {
    let tuning: BotTuning
    let policy: BotBlindBidPolicy

    init(difficulty: BotDifficulty = .hard) {
        let tuning = BotTuning(difficulty: difficulty)
        let handStrengthModel = BotHandStrengthModel(tuning: tuning)
        let blindMonteCarloEstimator = BotBlindBidMonteCarloEstimator(
            policy: tuning.runtimePolicy.bidding.blindMonteCarlo,
            handStrengthModel: handStrengthModel
        )

        self.tuning = tuning
        self.policy = BotBlindBidPolicy(
            tuning: tuning.bidding,
            policy: tuning.runtimePolicy.bidding.blindPolicy,
            monteCarloEstimator: blindMonteCarloEstimator
        )
    }

    func makeBlindBid(
        playerIndex: Int,
        dealerIndex: Int,
        cardsInRound: Int,
        allowedBlindBids: [Int],
        canChooseBlind: Bool = true,
        totalScores: [Int],
        matchContext: BotMatchContext? = nil
    ) -> Int? {
        policy.makePreDealBlindBid(
            playerIndex: playerIndex,
            dealerIndex: dealerIndex,
            cardsInRound: cardsInRound,
            allowedBlindBids: allowedBlindBids,
            canChooseBlind: canChooseBlind,
            totalScores: totalScores,
            matchContext: matchContext
        )
    }
}
