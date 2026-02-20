//
//  BotTurnStrategyServiceTests.swift
//  JockerTests
//
//  Created by Codex on 15.02.2026.
//

import XCTest
@testable import Jocker

final class BotTurnStrategyServiceTests: XCTestCase {
    func testMakeTurnDecision_whenChasingChoosesWeakestWinningCard() {
        let service = BotTurnStrategyService()
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.hearts, .queen), fromPlayer: 1, animated: false)

        let decision = service.makeTurnDecision(
            handCards: [
                card(.hearts, .ace),
                card(.hearts, .king)
            ],
            trickNode: trickNode,
            trump: .clubs,
            bid: 1,
            tricksTaken: 0
        )

        XCTAssertEqual(decision?.card, card(.hearts, .king))
    }

    func testMakeTurnDecision_whenDumpingPrefersLosingNonJokerCard() {
        let service = BotTurnStrategyService()
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.hearts, .ace), fromPlayer: 1, animated: false)
        _ = trickNode.playCard(card(.hearts, .king), fromPlayer: 2, animated: false)

        let decision = service.makeTurnDecision(
            handCards: [
                .joker,
                card(.hearts, .seven)
            ],
            trickNode: trickNode,
            trump: .spades,
            bid: 0,
            tricksTaken: 0
        )

        XCTAssertEqual(decision?.card, card(.hearts, .seven))
    }

    func testMakeTurnDecision_whenDumpingWithOnlyNonLeadJoker_usesFaceDownStyle() {
        let service = BotTurnStrategyService()
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.hearts, .ace), fromPlayer: 1, animated: false)

        let decision = service.makeTurnDecision(
            handCards: [.joker],
            trickNode: trickNode,
            trump: .spades,
            bid: 0,
            tricksTaken: 0
        )

        XCTAssertEqual(decision?.card, .joker)
        XCTAssertEqual(decision?.jokerDecision.style, .faceDown)
    }

    func testMakeTurnDecision_whenLeadJokerAndNeedTricks_usesWishDeclaration() {
        let service = BotTurnStrategyService()
        let trickNode = TrickNode()

        let decision = service.makeTurnDecision(
            handCards: [.joker],
            trickNode: trickNode,
            trump: .spades,
            bid: 1,
            tricksTaken: 0
        )

        XCTAssertEqual(decision?.card, .joker)
        XCTAssertEqual(decision?.jokerDecision.style, .faceUp)
        XCTAssertEqual(decision?.jokerDecision.leadDeclaration, .wish)
    }

    func testMakeTurnDecision_whenChasingAndWinningNonJokerExists_doesNotSpendJoker() {
        let service = BotTurnStrategyService()
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.hearts, .queen), fromPlayer: 1, animated: false)

        let decision = service.makeTurnDecision(
            handCards: [
                .joker,
                card(.hearts, .king)
            ],
            trickNode: trickNode,
            trump: .clubs,
            bid: 1,
            tricksTaken: 0
        )

        XCTAssertEqual(decision?.card, card(.hearts, .king))
    }

    func testMakeTurnDecision_whenMustWinAllRemaining_prefersReliableJokerWin() {
        let service = BotTurnStrategyService()
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.clubs, .ten), fromPlayer: 1, animated: false)

        let decision = service.makeTurnDecision(
            handCards: [
                .joker,
                card(.hearts, .six)
            ],
            trickNode: trickNode,
            trump: .hearts,
            bid: 2,
            tricksTaken: 0,
            cardsInRound: 2,
            playerCount: 4
        )

        XCTAssertEqual(decision?.card, .joker)
        XCTAssertEqual(decision?.jokerDecision.style, .faceUp)
    }

    func testMakeTurnDecision_whenLeadJokerAboveWithTrumpRequested_playsHighestTrump() {
        let service = BotTurnStrategyService()
        let trickNode = TrickNode()
        _ = trickNode.playCard(
            .joker,
            fromPlayer: 1,
            jokerLeadDeclaration: .above(suit: .spades),
            animated: false
        )

        let decision = service.makeTurnDecision(
            handCards: [
                card(.spades, .seven),
                card(.spades, .ace),
                card(.clubs, .king)
            ],
            trickNode: trickNode,
            trump: .spades,
            bid: 0,
            tricksTaken: 0
        )

        XCTAssertEqual(decision?.card, card(.spades, .ace))
    }

    func testMakeTurnDecision_whenLeadJokerAboveWithRequestedSuitInHand_playsHighestRequestedSuit() {
        let service = BotTurnStrategyService()
        let trickNode = TrickNode()
        _ = trickNode.playCard(
            .joker,
            fromPlayer: 1,
            jokerLeadDeclaration: .above(suit: .hearts),
            animated: false
        )

        let decision = service.makeTurnDecision(
            handCards: [
                card(.hearts, .seven),
                card(.hearts, .ace),
                card(.spades, .king)
            ],
            trickNode: trickNode,
            trump: .spades,
            bid: 0,
            tricksTaken: 0
        )

        XCTAssertEqual(decision?.card, card(.hearts, .ace))
    }

    func testMakeTurnDecision_whenLeadJokerAndDumping_usesTakesDeclarationNotTrump() {
        let service = BotTurnStrategyService()
        let trickNode = TrickNode()

        let decision = service.makeTurnDecision(
            handCards: [.joker],
            trickNode: trickNode,
            trump: .spades,
            bid: 0,
            tricksTaken: 0
        )

        guard let declaration = decision?.jokerDecision.leadDeclaration else {
            XCTFail("Ожидалось объявление takes для лидирующего джокера в режиме сброса")
            return
        }

        switch declaration {
        case .takes(let suit):
            XCTAssertNotEqual(suit, .spades)
        default:
            XCTFail("Ожидалось объявление takes")
        }
    }

    private func card(_ suit: Suit, _ rank: Rank) -> Card {
        return .regular(suit: suit, rank: rank)
    }
}
