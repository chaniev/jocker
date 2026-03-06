//
//  BotBiddingService.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

/// Фасад авто-заказа взяток для бота.
/// Делегирует обычный bid selection и blind bidding в отдельные policy/services.
final class BotBiddingService {
    private let bidSelectionService: BotBidSelectionService
    private let blindBidPolicy: BotBlindBidPolicy

    init(tuning: BotTuning = BotTuning(difficulty: .hard)) {
        let handStrengthModel = BotHandStrengthModel(tuning: tuning)
        let biddingPolicy = tuning.runtimePolicy.bidding
        let blindMonteCarloEstimator = BotBlindBidMonteCarloEstimator(
            policy: biddingPolicy.blindMonteCarlo,
            handStrengthModel: handStrengthModel
        )

        self.bidSelectionService = BotBidSelectionService(
            policy: biddingPolicy.bidSelection,
            handStrengthModel: handStrengthModel
        )
        self.blindBidPolicy = BotBlindBidPolicy(
            tuning: tuning.bidding,
            policy: biddingPolicy.blindPolicy,
            monteCarloEstimator: blindMonteCarloEstimator
        )
    }

    func makeBid(
        hand: [Card],
        cardsInRound: Int,
        trump: Suit?,
        forbiddenBid: Int?,
        matchContext: BotMatchContext? = nil
    ) -> Int {
        bidSelectionService.makeBid(
            hand: hand,
            cardsInRound: cardsInRound,
            trump: trump,
            forbiddenBid: forbiddenBid,
            matchContext: matchContext
        )
    }

    /// Решение бота о ставке «в тёмную» до раздачи.
    ///
    /// - Returns: значение blind-ставки или `nil`, если бот выбирает открытую ставку.
    func makePreDealBlindBid(
        playerIndex: Int,
        dealerIndex: Int,
        cardsInRound: Int,
        allowedBlindBids: [Int],
        canChooseBlind: Bool,
        totalScores: [Int],
        matchContext: BotMatchContext? = nil
    ) -> Int? {
        blindBidPolicy.makePreDealBlindBid(
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
