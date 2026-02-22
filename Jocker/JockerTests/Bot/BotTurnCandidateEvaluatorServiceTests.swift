//
//  BotTurnCandidateEvaluatorServiceTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
@testable import Jocker

final class BotTurnCandidateEvaluatorServiceTests: XCTestCase {
    private lazy var evaluator: BotTurnCandidateEvaluatorService = {
        let tuning = BotTuning(difficulty: .hard)
        return BotTurnCandidateEvaluatorService(
            cardHeuristics: BotTurnCardHeuristicsService(tuning: tuning),
            roundProjection: BotTurnRoundProjectionService(tuning: tuning),
            candidateRanking: BotTurnCandidateRankingService(tuning: tuning)
        )
    }()

    func testBestMove_whenLegalCardsEmpty_returnsNil() {
        let trickNode = TrickNode()

        let move = evaluator.bestMove(
            legalCards: [],
            handCards: [card(.hearts, .ace)],
            trickNode: trickNode,
            trump: .clubs,
            targetBid: 1,
            currentTricks: 0,
            cardsInRound: 1,
            playerCount: 4
        )

        XCTAssertNil(move)
    }

    func testBestMove_whenChasingChoosesWeakestWinningCard() {
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.hearts, .queen), fromPlayer: 1, animated: false)
        let hand = [
            card(.hearts, .ace),
            card(.hearts, .king)
        ]

        let move = evaluator.bestMove(
            legalCards: hand,
            handCards: hand,
            trickNode: trickNode,
            trump: .clubs,
            targetBid: 1,
            currentTricks: 0,
            cardsInRound: hand.count,
            playerCount: 4
        )

        XCTAssertEqual(move?.card, card(.hearts, .king))
    }

    func testBestMove_whenDumpingPrefersLosingNonJoker() {
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.hearts, .ace), fromPlayer: 1, animated: false)
        _ = trickNode.playCard(card(.hearts, .king), fromPlayer: 2, animated: false)
        let hand: [Card] = [.joker, card(.hearts, .seven)]

        let move = evaluator.bestMove(
            legalCards: hand,
            handCards: hand,
            trickNode: trickNode,
            trump: .spades,
            targetBid: 0,
            currentTricks: 0,
            cardsInRound: hand.count,
            playerCount: 4
        )

        XCTAssertEqual(move?.card, card(.hearts, .seven))
    }

    func testBestMove_whenDumpingWithOnlyNonLeadJoker_usesFaceDownStyle() {
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.hearts, .ace), fromPlayer: 1, animated: false)

        let move = evaluator.bestMove(
            legalCards: [.joker],
            handCards: [.joker],
            trickNode: trickNode,
            trump: .spades,
            targetBid: 0,
            currentTricks: 0,
            cardsInRound: 1,
            playerCount: 4
        )

        XCTAssertEqual(move?.card, .joker)
        XCTAssertEqual(move?.jokerDecision.style, .faceDown)
    }

    func testBestMove_whenLeadJokerAndNeedTricks_usesWishDeclaration() {
        let trickNode = TrickNode()

        let move = evaluator.bestMove(
            legalCards: [.joker],
            handCards: [.joker],
            trickNode: trickNode,
            trump: .spades,
            targetBid: 1,
            currentTricks: 0,
            cardsInRound: 1,
            playerCount: 4
        )

        XCTAssertEqual(move?.card, .joker)
        XCTAssertEqual(move?.jokerDecision.style, .faceUp)
        XCTAssertEqual(move?.jokerDecision.leadDeclaration, .wish)
    }

    private func card(_ suit: Suit, _ rank: Rank) -> Card {
        return .regular(suit: suit, rank: rank)
    }
}
