//
//  BotTurnCardHeuristicsServiceTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
@testable import Jocker

final class BotTurnCardHeuristicsServiceTests: XCTestCase {
    private let service = BotTurnCardHeuristicsService(tuning: BotTuning(difficulty: .hard))

    func testCandidateDecisions_nonJoker_returnsDefaultNonLeadOnly() {
        let trickNode = TrickNode()
        let decisions = service.candidateDecisions(
            for: card(.hearts, .ace),
            trickNode: trickNode,
            shouldChaseTrick: true
        )

        XCTAssertEqual(decisions, [.defaultNonLead])
    }

    func testCandidateDecisions_nonLeadJoker_orderDependsOnChaseMode() {
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.clubs, .queen), fromPlayer: 1, animated: false)

        let chaseDecisions = service.candidateDecisions(
            for: .joker,
            trickNode: trickNode,
            shouldChaseTrick: true
        )
        let dumpDecisions = service.candidateDecisions(
            for: .joker,
            trickNode: trickNode,
            shouldChaseTrick: false
        )

        XCTAssertEqual(chaseDecisions.map(\.style), [.faceUp, .faceDown])
        XCTAssertEqual(dumpDecisions.map(\.style), [.faceDown, .faceUp])
    }

    func testCandidateDecisions_leadJoker_containsWishAndAllAboveTakesVariants() {
        let trickNode = TrickNode()

        let decisions = service.candidateDecisions(
            for: .joker,
            trickNode: trickNode,
            shouldChaseTrick: true
        )

        XCTAssertEqual(decisions.count, 1 + Suit.allCases.count * 2)
        XCTAssertTrue(decisions.contains(where: { $0.leadDeclaration == .wish }))
        for suit in Suit.allCases {
            XCTAssertTrue(decisions.contains(where: { $0.leadDeclaration == .above(suit: suit) }))
            XCTAssertTrue(decisions.contains(where: { $0.leadDeclaration == .takes(suit: suit) }))
        }
    }

    func testWinsTrickRightNow_returnsTrueForHigherFollowSuit() {
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.hearts, .queen), fromPlayer: 1, animated: false)

        XCTAssertTrue(
            service.winsTrickRightNow(
                with: card(.hearts, .king),
                decision: .defaultNonLead,
                trickNode: trickNode,
                trump: .clubs
            )
        )
    }

    func testEstimateImmediateWinProbability_returnsZeroWhenCardDoesNotWinImmediately() {
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.hearts, .ace), fromPlayer: 1, animated: false)

        let probability = service.estimateImmediateWinProbability(
            card: card(.hearts, .king),
            decision: .defaultNonLead,
            trickNode: trickNode,
            trump: .clubs,
            unseenCards: Deck().cards,
            opponentsRemaining: 2,
            handSizeBeforeMove: 3
        )

        XCTAssertEqual(probability, 0)
    }

    func testUnseenCards_excludesKnownCardsAndKeepsExpectedCount() {
        let hand = [.joker, card(.hearts, .ace)]
        let played = [.joker, card(.clubs, .king)]

        let unseen = service.unseenCards(excluding: hand, and: played)

        XCTAssertEqual(unseen.count, Deck().cards.count - hand.count - played.count)
        XCTAssertFalse(unseen.contains(card(.hearts, .ace)))
        XCTAssertFalse(unseen.contains(card(.clubs, .king)))
        XCTAssertFalse(unseen.contains(.joker), "Both jokers are already known in this setup")
    }

    func testCardThreat_withPhaseContext_highTrumpCardIsMoreThreateningEarlyThanLate() {
        let trickNode = TrickNode()
        let card = card(.hearts, .ace)

        let earlyThreat = service.cardThreat(
            card: card,
            decision: .defaultNonLead,
            trump: .hearts,
            trickNode: trickNode,
            cardsRemainingInHandBeforeMove: 8,
            cardsInRound: 8
        )
        let lateThreat = service.cardThreat(
            card: card,
            decision: .defaultNonLead,
            trump: .hearts,
            trickNode: trickNode,
            cardsRemainingInHandBeforeMove: 1,
            cardsInRound: 8
        )

        XCTAssertGreaterThan(earlyThreat, lateThreat)
    }

    func testCardThreat_withPhaseContext_leadJokerWishIsMoreThreateningEarlyThanLate() {
        let trickNode = TrickNode()
        let decision = JokerPlayDecision(style: .faceUp, leadDeclaration: .wish)

        let earlyThreat = service.cardThreat(
            card: .joker,
            decision: decision,
            trump: .spades,
            trickNode: trickNode,
            cardsRemainingInHandBeforeMove: 7,
            cardsInRound: 8
        )
        let lateThreat = service.cardThreat(
            card: .joker,
            decision: decision,
            trump: .spades,
            trickNode: trickNode,
            cardsRemainingInHandBeforeMove: 1,
            cardsInRound: 8
        )

        XCTAssertGreaterThan(earlyThreat, lateThreat)
    }

    func testCardThreat_withoutPhaseContext_matchesExplicitNilPhaseContext() {
        let trickNode = TrickNode()
        let card = card(.clubs, .queen)

        let implicit = service.cardThreat(
            card: card,
            decision: .defaultNonLead,
            trump: .spades,
            trickNode: trickNode
        )
        let explicitNil = service.cardThreat(
            card: card,
            decision: .defaultNonLead,
            trump: .spades,
            trickNode: trickNode,
            cardsRemainingInHandBeforeMove: nil,
            cardsInRound: nil
        )

        XCTAssertEqual(implicit, explicitNil, accuracy: 0.0001)
    }

    private func card(_ suit: Suit, _ rank: Rank) -> Card {
        return .regular(suit: suit, rank: rank)
    }
}
