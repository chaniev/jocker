//
//  RulesTests.swift
//  JockerTests
//
//  Created by Codex on 06.03.2026.
//

import XCTest
@testable import Jocker

final class RulesTests: XCTestCase {
    func testWinnerPlayerIndex_emptyPlayedCards_returnsNil() {
        let playedCards: [PlayedTrickCard] = []
        XCTAssertNil(TrickTakingResolver.winnerPlayerIndex(playedCards: playedCards, trump: .hearts))
    }

    func testWinnerPlayerIndex_singleCard_returnsThatPlayer() {
        let played = [playedCard(playerIndex: 2, card: card(.clubs, .ace))]

        XCTAssertEqual(TrickTakingResolver.winnerPlayerIndex(playedCards: played, trump: .hearts), 2)
    }

    func testWinnerPlayerIndex_multipleCards_returnsHighestOfLeadSuit() {
        let played: [PlayedTrickCard] = [
            playedCard(playerIndex: 0, card: card(.hearts, .seven)),
            playedCard(playerIndex: 1, card: card(.hearts, .king)),
            playedCard(playerIndex: 2, card: card(.hearts, .ace)),
            playedCard(playerIndex: 3, card: card(.spades, .ace))
        ]

        XCTAssertEqual(TrickTakingResolver.winnerPlayerIndex(playedCards: played, trump: nil), 2)
    }

    func testWinnerPlayerIndex_trumpBeatsNonTrump() {
        let played: [PlayedTrickCard] = [
            playedCard(playerIndex: 0, card: card(.hearts, .ace)),
            playedCard(playerIndex: 1, card: card(.spades, .seven)),
            playedCard(playerIndex: 2, card: card(.hearts, .king))
        ]

        XCTAssertEqual(TrickTakingResolver.winnerPlayerIndex(playedCards: played, trump: .spades), 1)
    }

    func testWinnerPlayerIndex_jokerFaceUpBeatsAll() {
        let played: [PlayedTrickCard] = [
            playedCard(playerIndex: 0, card: card(.hearts, .ace)),
            playedCard(playerIndex: 1, card: .joker, style: .faceUp),
            playedCard(playerIndex: 2, card: card(.spades, .ace))
        ]

        XCTAssertEqual(TrickTakingResolver.winnerPlayerIndex(playedCards: played, trump: .spades), 1)
    }

    func testWinnerPlayerIndex_jokerFaceDownCannotWin() {
        let played: [PlayedTrickCard] = [
            playedCard(playerIndex: 0, card: card(.hearts, .ten)),
            playedCard(playerIndex: 1, card: .joker, style: .faceDown),
            playedCard(playerIndex: 2, card: card(.hearts, .king))
        ]

        XCTAssertEqual(TrickTakingResolver.winnerPlayerIndex(playedCards: played, trump: nil), 2)
    }

    func testWinnerPlayerIndex_leadJokerWish_winsUnlessOverridden() {
        let played: [PlayedTrickCard] = [
            playedCard(playerIndex: 0, card: .joker, declaration: .wish),
            playedCard(playerIndex: 1, card: card(.hearts, .ace)),
            playedCard(playerIndex: 2, card: card(.spades, .ace))
        ]

        XCTAssertEqual(TrickTakingResolver.winnerPlayerIndex(playedCards: played, trump: .spades), 0)
    }

    func testWinnerPlayerIndex_leadJokerWish_overriddenByLaterFaceUpJoker() {
        let played: [PlayedTrickCard] = [
            playedCard(playerIndex: 0, card: .joker, declaration: .wish),
            playedCard(playerIndex: 1, card: card(.hearts, .ace)),
            playedCard(playerIndex: 2, card: .joker, style: .faceUp)
        ]

        XCTAssertEqual(TrickTakingResolver.winnerPlayerIndex(playedCards: played, trump: .spades), 2)
    }

    func testWinnerPlayerIndex_leadJokerAbove_usesTrumpWhenTrumpDiffersFromRequestedSuit() {
        let played: [PlayedTrickCard] = [
            playedCard(playerIndex: 0, card: .joker, declaration: .above(suit: .hearts)),
            playedCard(playerIndex: 1, card: card(.hearts, .ace)),
            playedCard(playerIndex: 2, card: card(.spades, .seven)),
            playedCard(playerIndex: 3, card: card(.spades, .ace))
        ]

        XCTAssertEqual(TrickTakingResolver.winnerPlayerIndex(playedCards: played, trump: .spades), 3)
    }

    func testWinnerPlayerIndex_leadJokerTakes_usesRequestedSuitWhenNoTrump() {
        let played: [PlayedTrickCard] = [
            playedCard(playerIndex: 0, card: .joker, declaration: .takes(suit: .diamonds)),
            playedCard(playerIndex: 1, card: card(.diamonds, .seven)),
            playedCard(playerIndex: 2, card: card(.diamonds, .ace)),
            playedCard(playerIndex: 3, card: card(.clubs, .king))
        ]

        XCTAssertEqual(TrickTakingResolver.winnerPlayerIndex(playedCards: played, trump: nil), 2)
    }

    func testBiddingRules_forbiddenBidLogic() {
        let allowed = BiddingRules.allowedBids(
            forPlayer: 0,
            dealer: 0,
            cardsInRound: 3,
            bids: [0, 1, 1, 0],
            playerCount: 4
        )

        XCTAssertEqual(allowed, [0, 2, 3])
        XCTAssertEqual(
            BiddingRules.dealerForbiddenBid(
                forPlayer: 0,
                dealer: 0,
                cardsInRound: 3,
                bids: [0, 1, 1, 0],
                playerCount: 4
            ),
            1
        )
    }

    func testBiddingRules_blindBidValidation() {
        XCTAssertTrue(
            BiddingRules.canChooseBlindBid(
                forPlayer: 2,
                dealer: 0,
                blindSelections: [false, false, false, false],
                playerCount: 4
            )
        )
        XCTAssertFalse(
            BiddingRules.canChooseBlindBid(
                forPlayer: 0,
                dealer: 0,
                blindSelections: [false, true, false, true],
                playerCount: 4
            )
        )
        XCTAssertTrue(
            BiddingRules.canChooseBlindBid(
                forPlayer: 0,
                dealer: 0,
                blindSelections: [false, true, true, true],
                playerCount: 1
            )
        )
    }

    func testTrumpSelectionRules_ruleSelection_andChooserSeat() {
        let second = TrumpSelectionRules.rule(
            for: .second,
            cardsPerPlayer: 1,
            dealerIndex: 3,
            playerCount: 4
        )
        let fourth = TrumpSelectionRules.rule(
            for: .fourth,
            cardsPerPlayer: 12,
            dealerIndex: 1,
            playerCount: 3
        )

        XCTAssertEqual(second.strategy, .playerOnDealerLeft)
        XCTAssertEqual(second.chooserPlayerIndex, 0)
        XCTAssertEqual(second.cardsToDealBeforeChoicePerPlayer, 1)

        XCTAssertEqual(fourth.strategy, .playerOnDealerLeft)
        XCTAssertEqual(fourth.chooserPlayerIndex, 2)
        XCTAssertEqual(fourth.cardsToDealBeforeChoicePerPlayer, 4)
    }

    private func card(_ suit: Suit, _ rank: Rank) -> Card {
        return .regular(suit: suit, rank: rank)
    }

    private func playedCard(
        playerIndex: Int,
        card: Card,
        style: JokerPlayStyle = .faceUp,
        declaration: JokerLeadDeclaration? = nil
    ) -> PlayedTrickCard {
        return PlayedTrickCard(
            playerIndex: playerIndex,
            card: card,
            jokerPlayStyle: style,
            jokerLeadDeclaration: declaration
        )
    }
}
