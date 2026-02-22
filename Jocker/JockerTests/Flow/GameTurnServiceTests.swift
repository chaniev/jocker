//
//  GameTurnServiceTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
@testable import Jocker

final class GameTurnServiceTests: XCTestCase {
    func testAutomaticTurnDecision_withNeutralMatchContext_preservesDecision() {
        let service = GameTurnService()
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.hearts, .queen), fromPlayer: 1, animated: false)
        let hand = [
            card(.hearts, .ace),
            card(.hearts, .king)
        ]

        let baseline = service.automaticTurnDecision(
            from: hand,
            trickNode: trickNode,
            trump: .clubs,
            bid: 1,
            tricksTaken: 0,
            cardsInRound: 2,
            playerCount: 4,
            isBlind: false
        )
        let withNeutralContext = service.automaticTurnDecision(
            from: hand,
            trickNode: trickNode,
            trump: .clubs,
            bid: 1,
            tricksTaken: 0,
            cardsInRound: 2,
            playerCount: 4,
            isBlind: false,
            matchContext: BotMatchContext(
                block: .second,
                roundIndexInBlock: 2,
                totalRoundsInBlock: 8,
                totalScores: [100, 100, 100, 100],
                playerIndex: 0,
                dealerIndex: 3,
                playerCount: 4,
                premium: nil
            )
        )

        XCTAssertEqual(withNeutralContext?.card, baseline?.card)
        XCTAssertEqual(withNeutralContext?.jokerDecision, baseline?.jokerDecision)
    }

    func testAutomaticTurnDecision_withPremiumCandidateLateBlock_canAffectDumpUtilityWithoutBreakingValidity() {
        let service = GameTurnService()
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.spades, .ace), fromPlayer: 1, animated: false)
        let hand = [
            card(.spades, .seven),
            .joker
        ]

        let decision = service.automaticTurnDecision(
            from: hand,
            trickNode: trickNode,
            trump: .clubs,
            bid: 0,
            tricksTaken: 0,
            cardsInRound: 2,
            playerCount: 4,
            isBlind: false,
            matchContext: BotMatchContext(
                block: .fourth,
                roundIndexInBlock: 7,
                totalRoundsInBlock: 8,
                totalScores: [120, 120, 120, 120],
                playerIndex: 0,
                dealerIndex: 1,
                playerCount: 4,
                premium: .init(
                    completedRoundsInBlock: 7,
                    remainingRoundsInBlock: 1,
                    isPremiumCandidateSoFar: true,
                    isZeroPremiumRelevantInBlock: false,
                    isZeroPremiumCandidateSoFar: false
                )
            )
        )

        XCTAssertNotNil(decision)
        XCTAssertTrue(trickNode.canPlayCard(decision!.card, fromHand: hand, trump: .clubs))
    }

    private func card(_ suit: Suit, _ rank: Rank) -> Card {
        return .regular(suit: suit, rank: rank)
    }
}
