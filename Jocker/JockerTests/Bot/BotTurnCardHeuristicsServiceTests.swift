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

    func testBeliefState_inferVoidSuit_whenPlayerDoesNotFollowLeadSuit() {
        let completedTrick: [PlayedTrickCard] = [
            PlayedTrickCard(playerIndex: 0, card: card(.hearts, .queen)),
            PlayedTrickCard(playerIndex: 1, card: card(.clubs, .ace)),
            PlayedTrickCard(playerIndex: 2, card: card(.hearts, .king))
        ]

        let belief = BotBeliefState.infer(
            playerCount: 4,
            completedTricks: [completedTrick],
            currentTrick: [],
            trump: .spades
        )

        XCTAssertTrue(belief.isVoid(.hearts, for: 1))
        XCTAssertFalse(belief.isVoid(.hearts, for: 2))
    }

    func testBeliefState_inferTrumpVoid_whenPlayerCannotFollowLeadAndDoesNotPlayTrump() {
        let completedTrick: [PlayedTrickCard] = [
            PlayedTrickCard(playerIndex: 0, card: card(.hearts, .queen)),
            PlayedTrickCard(playerIndex: 1, card: card(.clubs, .ace)),
            PlayedTrickCard(playerIndex: 2, card: card(.spades, .king))
        ]

        let belief = BotBeliefState.infer(
            playerCount: 4,
            completedTricks: [completedTrick],
            currentTrick: [],
            trump: .spades
        )

        XCTAssertTrue(belief.isVoid(.spades, for: 1))
        XCTAssertFalse(belief.isVoid(.spades, for: 2))
    }

    func testEstimateImmediateWinProbability_withBeliefVoidSuits_increasesHoldProbability() {
        let trick = BotTurnCardHeuristicsService.TrickSnapshot(
            playedCards: [
                PlayedTrickCard(playerIndex: 0, card: card(.hearts, .queen))
            ]
        )
        let unseenCards: [Card] = [
            card(.hearts, .ace),
            card(.hearts, .king),
            card(.hearts, .jack),
            card(.clubs, .ace),
            card(.clubs, .ten),
            card(.diamonds, .ace),
            card(.diamonds, .ten),
            card(.spades, .ace),
            card(.spades, .ten)
        ]
        let noBelief = service.estimateImmediateWinProbability(
            card: card(.hearts, .king),
            decision: .defaultNonLead,
            trick: trick,
            trump: nil,
            unseenCards: unseenCards,
            opponentsRemaining: 2,
            handSizeBeforeMove: 3
        )
        let belief = BotBeliefState(
            voidSuitsByPlayerIndex: [
                2: [.hearts],
                3: [.hearts]
            ]
        )
        let withBelief = service.estimateImmediateWinProbability(
            card: card(.hearts, .king),
            decision: .defaultNonLead,
            trick: trick,
            trump: nil,
            unseenCards: unseenCards,
            opponentsRemaining: 2,
            handSizeBeforeMove: 3,
            beliefState: belief,
            remainingOpponentPlayerIndices: [2, 3]
        )

        XCTAssertGreaterThan(withBelief, noBelief)
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

    func testCardThreat_withPositionContext_leadThreatIsHigherThanLastSeatThreat() {
        let leadTrick = TrickNode()
        let lastSeatTrick = TrickNode()
        _ = lastSeatTrick.playCard(card(.diamonds, .six), fromPlayer: 1, animated: false)
        _ = lastSeatTrick.playCard(card(.diamonds, .seven), fromPlayer: 2, animated: false)
        _ = lastSeatTrick.playCard(card(.diamonds, .eight), fromPlayer: 3, animated: false)

        let leadThreat = service.cardThreat(
            card: card(.clubs, .queen),
            decision: .defaultNonLead,
            trump: .spades,
            trickNode: leadTrick,
            cardsRemainingInHandBeforeMove: 5,
            cardsInRound: 8,
            playerCount: 4
        )
        let lastSeatThreat = service.cardThreat(
            card: card(.clubs, .queen),
            decision: .defaultNonLead,
            trump: .spades,
            trickNode: lastSeatTrick,
            cardsRemainingInHandBeforeMove: 5,
            cardsInRound: 8,
            playerCount: 4
        )

        XCTAssertGreaterThan(leadThreat, lastSeatThreat)
    }

    func testCardThreat_withRoundHistoryContext_whenHigherCardsAlreadyPlayed_increasesResourceThreat() {
        let trickNode = TrickNode()
        let baseline = service.cardThreat(
            card: card(.hearts, .queen),
            decision: .defaultNonLead,
            trump: nil,
            trickNode: trickNode,
            cardsRemainingInHandBeforeMove: 4,
            cardsInRound: 8
        )
        let completedTricks: [[PlayedTrickCard]] = [[
            PlayedTrickCard(playerIndex: 0, card: card(.hearts, .ace)),
            PlayedTrickCard(playerIndex: 1, card: card(.clubs, .seven)),
            PlayedTrickCard(playerIndex: 2, card: card(.hearts, .king)),
            PlayedTrickCard(playerIndex: 3, card: card(.spades, .seven))
        ]]
        let withHistory = service.cardThreat(
            card: card(.hearts, .queen),
            decision: .defaultNonLead,
            trump: nil,
            trickNode: trickNode,
            cardsRemainingInHandBeforeMove: 4,
            cardsInRound: 8,
            completedTricksInRound: completedTricks
        )

        XCTAssertGreaterThan(withHistory, baseline)
    }

    private func card(_ suit: Suit, _ rank: Rank) -> Card {
        return .regular(suit: suit, rank: rank)
    }
}
