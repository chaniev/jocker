//
//  BotBiddingServiceTestFixture.swift
//  JockerTests
//
//  Created by Codex on 06.03.2026.
//

@testable import Jocker

struct BotBiddingServiceTestFixture {
    let tuning: BotTuning
    let service: BotBiddingService

    init(difficulty: BotDifficulty = .hard) {
        let tuning = BotTuning(difficulty: difficulty)
        self.tuning = tuning
        self.service = BotBiddingService(tuning: tuning)
    }

    func makeBid(
        hand: [Card],
        cardsInRound: Int,
        trump: Suit?,
        forbiddenBid: Int?,
        matchContext: BotMatchContext? = nil
    ) -> Int {
        return service.makeBid(
            hand: hand,
            cardsInRound: cardsInRound,
            trump: trump,
            forbiddenBid: forbiddenBid,
            matchContext: matchContext
        )
    }

    func makePreDealBlindBid(
        playerIndex: Int,
        dealerIndex: Int,
        cardsInRound: Int,
        allowedBlindBids: [Int],
        canChooseBlind: Bool = true,
        totalScores: [Int],
        matchContext: BotMatchContext? = nil
    ) -> Int? {
        return service.makePreDealBlindBid(
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
