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

    func testBestMove_whenForcedLeadJokerEarlyChase_prefersAboveTrumpOverWish() {
        let move = evaluator.bestMove(
            context: .init(
                legalCards: [.joker], // форсируем сравнение только объявлений джокера
                handCards: [.joker, card(.clubs, .six), card(.diamonds, .seven), card(.hearts, .eight)],
                trick: .init(playedCards: []),
                trump: .spades,
                targetBid: 1,
                currentTricks: 0,
                cardsInRound: 8,
                playerCount: 4,
                isBlind: false,
                matchContext: nil
            )
        )

        XCTAssertEqual(move?.card, .joker)
        XCTAssertEqual(move?.jokerDecision.style, .faceUp)
        XCTAssertEqual(move?.jokerDecision.leadDeclaration, .above(suit: .spades))
    }

    func testBestMove_whenForcedLeadJokerFinalAllInChase_preservesWishOverAbove() {
        let move = evaluator.bestMove(
            context: .init(
                legalCards: [.joker], // форсируем сравнение только объявлений джокера
                handCards: [.joker],
                trick: .init(playedCards: []),
                trump: .spades,
                targetBid: 1,
                currentTricks: 0,
                cardsInRound: 1,
                playerCount: 4,
                isBlind: false,
                matchContext: nil
            )
        )

        XCTAssertEqual(move?.card, .joker)
        XCTAssertEqual(move?.jokerDecision.style, .faceUp)
        XCTAssertEqual(move?.jokerDecision.leadDeclaration, .wish)
    }

    func testBestMove_whenForcedLeadJokerDumping_prefersTakesNonTrumpDeclaration() {
        let move = evaluator.bestMove(
            context: .init(
                legalCards: [.joker], // форсируем сравнение только объявлений джокера
                handCards: [.joker, card(.clubs, .six), card(.diamonds, .seven), card(.hearts, .eight)],
                trick: .init(playedCards: []),
                trump: .spades,
                targetBid: 0,
                currentTricks: 0,
                cardsInRound: 8,
                playerCount: 4,
                isBlind: false,
                matchContext: nil
            )
        )

        XCTAssertEqual(move?.card, .joker)
        XCTAssertEqual(move?.jokerDecision.style, .faceUp)
        guard case .some(.takes(let suit)) = move?.jokerDecision.leadDeclaration else {
            XCTFail("Ожидалось объявление takes в dump-сценарии с форсированным lead-joker")
            return
        }
        XCTAssertNotEqual(suit, .spades)
    }

    func testBestMove_withNeutralMatchContext_preservesDecision() {
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.hearts, .queen), fromPlayer: 1, animated: false)
        let hand = [
            card(.hearts, .ace),
            card(.hearts, .king)
        ]

        let baseline = evaluator.bestMove(
            legalCards: hand,
            handCards: hand,
            trickNode: trickNode,
            trump: .clubs,
            targetBid: 1,
            currentTricks: 0,
            cardsInRound: hand.count,
            playerCount: 4,
            isBlind: true
        )
        let withMatchContext = evaluator.bestMove(
            legalCards: hand,
            handCards: hand,
            trickNode: trickNode,
            trump: .clubs,
            targetBid: 1,
            currentTricks: 0,
            cardsInRound: hand.count,
            playerCount: 4,
            isBlind: true,
            matchContext: sampleMatchContext()
        )

        XCTAssertEqual(withMatchContext?.card, baseline?.card)
        XCTAssertEqual(withMatchContext?.jokerDecision, baseline?.jokerDecision)
    }

    private func card(_ suit: Suit, _ rank: Rank) -> Card {
        return .regular(suit: suit, rank: rank)
    }

    private func sampleMatchContext() -> BotMatchContext {
        return BotMatchContext(
            block: .second,
            roundIndexInBlock: 1,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 2,
            dealerIndex: 1,
            playerCount: 4,
            premium: nil
        )
    }
}
