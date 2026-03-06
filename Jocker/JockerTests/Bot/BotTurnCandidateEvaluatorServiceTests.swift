//
//  BotTurnCandidateEvaluatorServiceTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
@testable import Jocker

final class BotTurnCandidateEvaluatorServiceTests: XCTestCase {
    private let fixture = BotTurnCandidateEvaluatorServiceTestFixture()

    func testBestMove_whenLegalCardsEmpty_returnsNil() {
        let trickNode = BotTrickNodeBuilder.make()

        let move = fixture.bestMove(
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
        let trickNode = BotTrickNodeBuilder.make()
        BotTrickNodeBuilder.play(card(.hearts, .queen), into: trickNode)
        let hand = [
            card(.hearts, .ace),
            card(.hearts, .king)
        ]

        let move = fixture.bestMove(
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
        let trickNode = BotTrickNodeBuilder.make()
        BotTrickNodeBuilder.play(card(.hearts, .ace), into: trickNode)
        BotTrickNodeBuilder.play(card(.hearts, .king), fromPlayer: 2, into: trickNode)
        let hand: [Card] = [.joker, card(.hearts, .seven)]

        let move = fixture.bestMove(
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
        let trickNode = BotTrickNodeBuilder.make()
        BotTrickNodeBuilder.play(card(.hearts, .ace), into: trickNode)

        let move = fixture.bestMove(
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
        let trickNode = BotTrickNodeBuilder.make()

        let move = fixture.bestMove(
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
        let move = fixture.bestMove(
            decisionContext: BotTurnDecisionContextBuilder(
                handCards: [.joker, card(.clubs, .six), card(.diamonds, .seven), card(.hearts, .eight)],
                legalCards: [.joker], // форсируем сравнение только объявлений джокера
                trickNode: BotTrickNodeBuilder.make(),
                trump: .spades,
                bid: 1,
                tricksTaken: 0,
                cardsInRound: 8,
                playerCount: 4,
                targetBid: 1,
                currentTricks: 0
            )
        )

        XCTAssertEqual(move?.card, .joker)
        XCTAssertEqual(move?.jokerDecision.style, .faceUp)
        XCTAssertEqual(move?.jokerDecision.leadDeclaration, .above(suit: .spades))
    }

    func testBestMove_whenForcedLeadJokerFinalAllInChase_preservesWishOverAbove() {
        let move = fixture.bestMove(
            decisionContext: BotTurnDecisionContextBuilder(
                handCards: [.joker],
                legalCards: [.joker], // форсируем сравнение только объявлений джокера
                trickNode: BotTrickNodeBuilder.make(),
                trump: .spades,
                bid: 1,
                tricksTaken: 0,
                cardsInRound: 1,
                playerCount: 4,
                targetBid: 1,
                currentTricks: 0
            )
        )

        XCTAssertEqual(move?.card, .joker)
        XCTAssertEqual(move?.jokerDecision.style, .faceUp)
        XCTAssertEqual(move?.jokerDecision.leadDeclaration, .wish)
    }

    func testBestMove_whenForcedLeadJokerDumping_prefersTakesNonTrumpDeclaration() {
        let move = fixture.bestMove(
            decisionContext: BotTurnDecisionContextBuilder(
                handCards: [.joker, card(.clubs, .six), card(.diamonds, .seven), card(.hearts, .eight)],
                legalCards: [.joker], // форсируем сравнение только объявлений джокера
                trickNode: BotTrickNodeBuilder.make(),
                trump: .spades,
                bid: 0,
                tricksTaken: 0,
                cardsInRound: 8,
                playerCount: 4,
                targetBid: 0,
                currentTricks: 0
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
        let trickNode = BotTrickNodeBuilder.make()
        BotTrickNodeBuilder.play(card(.hearts, .queen), into: trickNode)
        let hand = [
            card(.hearts, .ace),
            card(.hearts, .king)
        ]

        let baseline = fixture.bestMove(
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
        let withMatchContext = fixture.bestMove(
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
        let premium = BotMatchContextTestBuilder.premiumSnapshot(
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
        let withoutOpponents = BotMatchContextTestBuilder(
            premium: premium,
            opponents: nil
        ).build()
        let noEvidenceOpponents = BotMatchContextTestBuilder(
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
        ).build()

        func bestMove(matchContext: BotMatchContext) -> (card: Card, jokerDecision: JokerPlayDecision)? {
            fixture.bestMove(
                decisionContext: BotTurnDecisionContextBuilder(
                    handCards: [.joker, card(.clubs, .six), card(.diamonds, .seven), card(.hearts, .eight)],
                    legalCards: [.joker],
                    trickNode: BotTrickNodeBuilder.make(),
                    trump: .spades,
                    bid: 4,
                    tricksTaken: 0,
                    cardsInRound: 8,
                    playerCount: 4,
                    matchContext: matchContext,
                    targetBid: 4,
                    currentTricks: 0
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
        let premium = BotMatchContextTestBuilder.premiumSnapshot(
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
        let disciplinedContext = BotMatchContextTestBuilder(
            roundIndexInBlock: 5,
            premium: premium,
            opponents: disciplinedOpponents
        ).build()
        let erraticContext = BotMatchContextTestBuilder(
            roundIndexInBlock: 5,
            premium: premium,
            opponents: erraticOpponents
        ).build()

        let trickNode = BotTrickNodeBuilder.make()
        BotTrickNodeBuilder.play(card(.clubs, .queen), into: trickNode)
        BotTrickNodeBuilder.play(card(.clubs, .king), fromPlayer: 2, into: trickNode)
        BotTrickNodeBuilder.play(card(.clubs, .jack), fromPlayer: 3, into: trickNode)
        let hand = [card(.clubs, .ace), card(.clubs, .seven)]

        func bestMove(matchContext: BotMatchContext) -> (card: Card, jokerDecision: JokerPlayDecision)? {
            fixture.bestMove(
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

    func testBestMove_whenRolloutTriggeredBySmallHand_isDeterministic() {
        let trickNode = BotTrickNodeBuilder.make()
        BotTrickNodeBuilder.play(card(.hearts, .queen), into: trickNode)

        let hand: [Card] = [
            card(.hearts, .ace),
            card(.hearts, .king),
            card(.hearts, .seven)
        ]
        let roundState = BotMatchContextTestBuilder.roundSnapshot(
            bids: [2, 2, 0, 0],
            tricksTaken: [1, 1, 0, 0],
            isBlindBid: [false, false, false, false]
        )
        let context = BotMatchContextTestBuilder(
            round: roundState
        ).build()

        let firstDecision = fixture.bestMove(
            legalCards: hand,
            handCards: hand,
            trickNode: trickNode,
            trump: .clubs,
            targetBid: 2,
            currentTricks: 1,
            cardsInRound: 8,
            playerCount: 4,
            isBlind: false,
            matchContext: context,
            roundState: roundState,
            actingPlayerIndex: 0
        )
        let secondDecision = fixture.bestMove(
            legalCards: hand,
            handCards: hand,
            trickNode: trickNode,
            trump: .clubs,
            targetBid: 2,
            currentTricks: 1,
            cardsInRound: 8,
            playerCount: 4,
            isBlind: false,
            matchContext: context,
            roundState: roundState,
            actingPlayerIndex: 0
        )

        XCTAssertEqual(secondDecision?.card, firstDecision?.card)
        XCTAssertEqual(secondDecision?.jokerDecision, firstDecision?.jokerDecision)
    }

    func testBestMove_whenRoundStateNeedsSingleTrickAhead_canPreferControlCard() {
        let trickNode = BotTrickNodeBuilder.make()
        BotTrickNodeBuilder.play(card(.clubs, .queen), into: trickNode)

        let hand: [Card] = [
            card(.clubs, .ace),
            card(.clubs, .seven)
        ]
        let pressuredRoundState = BotMatchContextTestBuilder.roundSnapshot(
            bids: [0, 2, 0, 0],
            tricksTaken: [1, 1, 0, 0], // player 1 needs exactly one trick
            isBlindBid: [false, false, false, false]
        )
        let neutralRoundState = BotMatchContextTestBuilder.roundSnapshot(
            bids: [0, 2, 0, 0],
            tricksTaken: [1, 2, 0, 0],
            isBlindBid: [false, false, false, false]
        )
        let matchContext = BotMatchContextTestBuilder(
            roundIndexInBlock: 6,
            round: pressuredRoundState
        ).build()

        let neutralDecision = fixture.bestMove(
            legalCards: hand,
            handCards: hand,
            trickNode: trickNode,
            trump: .hearts,
            targetBid: 0,
            currentTricks: 1,
            cardsInRound: 8,
            playerCount: 4,
            isBlind: false,
            matchContext: matchContext,
            roundState: neutralRoundState,
            actingPlayerIndex: 0
        )
        let pressuredDecision = fixture.bestMove(
            legalCards: hand,
            handCards: hand,
            trickNode: trickNode,
            trump: .hearts,
            targetBid: 0,
            currentTricks: 1,
            cardsInRound: 8,
            playerCount: 4,
            isBlind: false,
            matchContext: matchContext,
            roundState: pressuredRoundState,
            actingPlayerIndex: 0
        )

        XCTAssertEqual(pressuredDecision?.card, card(.clubs, .ace))
        guard case .some(.regular(_, let neutralRank)) = neutralDecision?.card,
              case .some(.regular(_, let pressuredRank)) = pressuredDecision?.card else {
            XCTFail("Ожидались регулярные карты в сравнении pressure/neutral")
            return
        }
        XCTAssertGreaterThanOrEqual(pressuredRank.rawValue, neutralRank.rawValue)
    }

    func testBestMove_whenEndgameSolverTriggeredByHandSizeThree_isDeterministic() {
        let trickNode = BotTrickNodeBuilder.make()
        BotTrickNodeBuilder.play(card(.clubs, .queen), into: trickNode)

        let hand: [Card] = [
            card(.clubs, .ace),
            card(.clubs, .seven),
            card(.diamonds, .six)
        ]
        let context = BotMatchContextTestBuilder(
            totalScores: [120, 110, 95, 90],
            playerCount: 4
        ).build()

        let firstDecision = fixture.bestMove(
            legalCards: [card(.clubs, .ace), card(.clubs, .seven)],
            handCards: hand,
            trickNode: trickNode,
            trump: .hearts,
            targetBid: 1,
            currentTricks: 1,
            cardsInRound: 3,
            playerCount: 4,
            isBlind: false,
            matchContext: context,
            actingPlayerIndex: 0
        )
        let secondDecision = fixture.bestMove(
            legalCards: [card(.clubs, .ace), card(.clubs, .seven)],
            handCards: hand,
            trickNode: trickNode,
            trump: .hearts,
            targetBid: 1,
            currentTricks: 1,
            cardsInRound: 3,
            playerCount: 4,
            isBlind: false,
            matchContext: context,
            actingPlayerIndex: 0
        )

        XCTAssertEqual(secondDecision?.card, firstDecision?.card)
        XCTAssertEqual(secondDecision?.jokerDecision, firstDecision?.jokerDecision)
    }

    func testBestMove_whenEndgameDumpAndExactBidAtRisk_prefersControlledLossCard() {
        let trickNode = BotTrickNodeBuilder.make()
        BotTrickNodeBuilder.play(card(.clubs, .queen), into: trickNode)

        let hand: [Card] = [
            card(.clubs, .ace),
            card(.clubs, .seven),
            card(.diamonds, .six)
        ]

        let decision = fixture.bestMove(
            legalCards: [card(.clubs, .ace), card(.clubs, .seven)],
            handCards: hand,
            trickNode: trickNode,
            trump: .hearts,
            targetBid: 1,
            currentTricks: 1,
            cardsInRound: 3,
            playerCount: 4,
            isBlind: false,
            matchContext: nil,
            actingPlayerIndex: 0
        )

        XCTAssertEqual(decision?.card, card(.clubs, .seven))
    }

    private func card(_ suit: Suit, _ rank: Rank) -> Card {
        return BotTestCards.card(suit, rank)
    }

    private func sampleMatchContext() -> BotMatchContext {
        return BotMatchContextTestBuilder(
            block: .second,
            roundIndexInBlock: 1,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 2,
            dealerIndex: 1,
            playerCount: 4
        ).build()
    }

    private func makeOpponentModel(
        leftNeighborIndex: Int?,
        leftNeighbor: BotOpponentModel.OpponentSnapshot?,
        others: [BotOpponentModel.OpponentSnapshot]
    ) -> BotOpponentModel {
        return BotMatchContextTestBuilder.opponentModel(
            perspectivePlayerIndex: 0,
            leftNeighborIndex: leftNeighborIndex,
            leftNeighbor: leftNeighbor,
            others: others
        )
    }
}
