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

    func testBestMove_whenLeadJokerAntiPremiumContext_andOpponentModelHasNoEvidence_keepsDecisionUnchanged() {
        let premium = BotMatchContext.PremiumSnapshot(
            completedRoundsInBlock: 5,
            remainingRoundsInBlock: 3,
            isPremiumCandidateSoFar: false,
            isZeroPremiumRelevantInBlock: false,
            isZeroPremiumCandidateSoFar: false,
            leftNeighborIndex: 1,
            leftNeighborIsPremiumCandidateSoFar: true,
            isPenaltyTargetRiskSoFar: true,
            premiumCandidatesThreateningPenaltyCount: 1,
            opponentPremiumCandidatesSoFarCount: 2
        )
        let withoutOpponents = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4,
            premium: premium,
            opponents: nil
        )
        let noEvidenceOpponents = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4,
            premium: premium,
            opponents: makeOpponentModel(
                leftNeighborIndex: 1,
                leftNeighbor: .init(
                    playerIndex: 1,
                    observedRounds: 0,
                    blindBidRate: 1.0,
                    exactBidRate: 1.0,
                    overbidRate: 0.0,
                    underbidRate: 0.0,
                    averageBidAggression: 1.0
                ),
                others: []
            )
        )

        func bestMove(matchContext: BotMatchContext) -> (card: Card, jokerDecision: JokerPlayDecision)? {
            evaluator.bestMove(
                context: .init(
                    legalCards: [.joker],
                    handCards: [.joker, card(.clubs, .six), card(.diamonds, .seven), card(.hearts, .eight)],
                    trick: .init(playedCards: []),
                    trump: .spades,
                    targetBid: 4,
                    currentTricks: 0,
                    cardsInRound: 8,
                    playerCount: 4,
                    isBlind: false,
                    matchContext: matchContext
                )
            )
        }

        let baseline = bestMove(matchContext: withoutOpponents)
        let noEvidence = bestMove(matchContext: noEvidenceOpponents)

        XCTAssertEqual(noEvidence?.card, baseline?.card)
        XCTAssertEqual(noEvidence?.jokerDecision, baseline?.jokerDecision)
        XCTAssertEqual(baseline?.jokerDecision.leadDeclaration, .above(suit: .spades))
    }

    func testBestMove_whenModeratePremiumDenyContext_andDisciplinedObservedLeftNeighborFlipsDumpChoiceComparedToErratic() {
        let premium = BotMatchContext.PremiumSnapshot(
            completedRoundsInBlock: 7,
            remainingRoundsInBlock: 1,
            isPremiumCandidateSoFar: false,
            isZeroPremiumRelevantInBlock: false,
            isZeroPremiumCandidateSoFar: false,
            leftNeighborIndex: 1,
            leftNeighborIsPremiumCandidateSoFar: true,
            isPenaltyTargetRiskSoFar: false,
            premiumCandidatesThreateningPenaltyCount: 0,
            opponentPremiumCandidatesSoFarCount: 1
        )
        let disciplinedOpponents = makeOpponentModel(
            leftNeighborIndex: 1,
            leftNeighbor: .init(
                playerIndex: 1,
                observedRounds: 4,
                blindBidRate: 0.50,
                exactBidRate: 0.75,
                overbidRate: 0.10,
                underbidRate: 0.15,
                averageBidAggression: 0.72
            ),
            others: []
        )
        let erraticOpponents = makeOpponentModel(
            leftNeighborIndex: 1,
            leftNeighbor: .init(
                playerIndex: 1,
                observedRounds: 4,
                blindBidRate: 0.0,
                exactBidRate: 0.20,
                overbidRate: 0.45,
                underbidRate: 0.35,
                averageBidAggression: 0.35
            ),
            others: []
        )
        let disciplinedContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 5,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4,
            premium: premium,
            opponents: disciplinedOpponents
        )
        let erraticContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 5,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4,
            premium: premium,
            opponents: erraticOpponents
        )

        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.clubs, .queen), fromPlayer: 1, animated: false)
        _ = trickNode.playCard(card(.clubs, .king), fromPlayer: 2, animated: false)
        _ = trickNode.playCard(card(.clubs, .jack), fromPlayer: 3, animated: false)
        let hand = [card(.clubs, .ace), card(.clubs, .seven)]

        func bestMove(matchContext: BotMatchContext) -> (card: Card, jokerDecision: JokerPlayDecision)? {
            evaluator.bestMove(
                legalCards: hand,
                handCards: hand,
                trickNode: trickNode,
                trump: .hearts,
                targetBid: 0,
                currentTricks: 1,
                cardsInRound: 8,
                playerCount: 4,
                isBlind: false,
                matchContext: matchContext
            )
        }

        let disciplinedDecision = bestMove(matchContext: disciplinedContext)
        let erraticDecision = bestMove(matchContext: erraticContext)

        XCTAssertEqual(disciplinedDecision?.card, card(.clubs, .ace))
        XCTAssertEqual(erraticDecision?.card, card(.clubs, .seven))
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

    private func makeOpponentModel(
        leftNeighborIndex: Int?,
        leftNeighbor: BotOpponentModel.OpponentSnapshot?,
        others: [BotOpponentModel.OpponentSnapshot]
    ) -> BotOpponentModel {
        var snapshots = others
        if let leftNeighbor {
            snapshots.insert(leftNeighbor, at: 0)
        }

        return BotOpponentModel(
            perspectivePlayerIndex: 0,
            leftNeighborIndex: leftNeighborIndex,
            snapshots: snapshots
        )
    }
}
