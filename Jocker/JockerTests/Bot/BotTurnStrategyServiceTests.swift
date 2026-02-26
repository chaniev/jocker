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

    func testMakeTurnDecision_whenEarlyOverbidDumpAndNoSafeNonJokerLead_prefersLeadJokerTakesNonTrump() {
        let service = BotTurnStrategyService(tuning: BotTuning(difficulty: .hard))
        let trickNode = TrickNode()
        let handCards: [Card] = [
            .joker,
            card(.spades, .ace),
            card(.spades, .king),
            card(.spades, .queen)
        ]

        let dumpDecision = service.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
            trump: .spades,
            bid: 0,
            tricksTaken: 2, // overbid (2): усиливаем мотивацию controlled-loss в dump
            cardsInRound: 8,
            playerCount: 4
        )

        XCTAssertEqual(dumpDecision?.card, .joker)
        guard case .some(.takes(let suit)) = dumpDecision?.jokerDecision.leadDeclaration else {
            XCTFail("Ожидался lead-джокер + takes в раннем overbid dump без safe non-joker lead")
            return
        }

        XCTAssertNotEqual(suit, .spades)
    }

    func testMakeTurnDecision_whenEarlyOverbidDumpAndOwnPremiumProtection_prefersLeadJokerTakesNonTrump() {
        let service = BotTurnStrategyService(tuning: BotTuning(difficulty: .hard))
        let trickNode = TrickNode()
        let handCards: [Card] = [
            .joker,
            card(.spades, .ace),
            card(.spades, .king),
            card(.spades, .queen)
        ]
        let ownPremiumContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4,
            premium: .init(
                completedRoundsInBlock: 7,
                remainingRoundsInBlock: 1,
                isPremiumCandidateSoFar: true,
                isZeroPremiumRelevantInBlock: false,
                isZeroPremiumCandidateSoFar: false,
                leftNeighborIndex: 1,
                leftNeighborIsPremiumCandidateSoFar: false,
                isPenaltyTargetRiskSoFar: false,
                premiumCandidatesThreateningPenaltyCount: 0,
                opponentPremiumCandidatesSoFarCount: 0
            )
        )

        let decision = service.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
            trump: .spades,
            bid: 0,
            tricksTaken: 1, // overbid: controlled-loss lead becomes especially valuable
            cardsInRound: 8,
            playerCount: 4,
            matchContext: ownPremiumContext
        )

        XCTAssertEqual(decision?.card, .joker)
        guard case .some(.takes(let suit)) = decision?.jokerDecision.leadDeclaration else {
            XCTFail("Ожидалось объявление takes в early overbid dump при own-premium protection")
            return
        }
        XCTAssertNotEqual(suit, .spades)
    }

    func testMakeTurnDecision_whenLateOwnPremiumCandidate_dumpingPrefersLosingFollowCard() {
        let service = BotTurnStrategyService(tuning: BotTuning(difficulty: .hard))
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.clubs, .six), fromPlayer: 1, animated: false)

        let handCards: [Card] = [
            card(.clubs, .ace),
            card(.clubs, .seven)
        ]

        let neutralDecision = service.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
            trump: .spades,
            bid: 1,
            tricksTaken: 1,
            cardsInRound: 8,
            playerCount: 4,
            matchContext: .init(
                block: .fourth,
                roundIndexInBlock: 7,
                totalRoundsInBlock: 8,
                totalScores: [100, 100, 100, 100],
                playerIndex: 0,
                dealerIndex: 2,
                playerCount: 4,
                premium: nil
            )
        )
        let premiumDecision = service.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
            trump: .spades,
            bid: 1,
            tricksTaken: 1,
            cardsInRound: 8,
            playerCount: 4,
            matchContext: .init(
                block: .fourth,
                roundIndexInBlock: 7,
                totalRoundsInBlock: 8,
                totalScores: [100, 100, 100, 100],
                playerIndex: 0,
                dealerIndex: 2,
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

        XCTAssertEqual(neutralDecision?.card, card(.clubs, .ace))
        XCTAssertEqual(premiumDecision?.card, card(.clubs, .seven))
    }

    func testMakeTurnDecision_whenPenaltyTargetRisk_flipsLateDumpChoiceTowardSafeLoss() {
        let service = BotTurnStrategyService(tuning: BotTuning(difficulty: .hard))
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.clubs, .queen), fromPlayer: 1, animated: false)

        let handCards: [Card] = [
            card(.clubs, .ace),
            card(.clubs, .seven)
        ]

        let neutralDecision = service.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
            trump: .hearts,
            bid: 0,
            tricksTaken: 1, // уже overbid -> антиштрафной сигнал уместнее
            cardsInRound: 8,
            playerCount: 4,
            matchContext: .init(
                block: .fourth,
                roundIndexInBlock: 7,
                totalRoundsInBlock: 8,
                totalScores: [100, 100, 100, 100],
                playerIndex: 0,
                dealerIndex: 2,
                playerCount: 4,
                premium: .init(
                    completedRoundsInBlock: 7,
                    remainingRoundsInBlock: 1,
                    isPremiumCandidateSoFar: false,
                    isZeroPremiumRelevantInBlock: false,
                    isZeroPremiumCandidateSoFar: false,
                    leftNeighborIndex: 1,
                    leftNeighborIsPremiumCandidateSoFar: false,
                    isPenaltyTargetRiskSoFar: false,
                    premiumCandidatesThreateningPenaltyCount: 0
                )
            )
        )
        let penaltyRiskDecision = service.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
            trump: .hearts,
            bid: 0,
            tricksTaken: 1,
            cardsInRound: 8,
            playerCount: 4,
            matchContext: .init(
                block: .fourth,
                roundIndexInBlock: 7,
                totalRoundsInBlock: 8,
                totalScores: [100, 100, 100, 100],
                playerIndex: 0,
                dealerIndex: 2,
                playerCount: 4,
                premium: .init(
                    completedRoundsInBlock: 7,
                    remainingRoundsInBlock: 1,
                    isPremiumCandidateSoFar: false,
                    isZeroPremiumRelevantInBlock: false,
                    isZeroPremiumCandidateSoFar: false,
                    leftNeighborIndex: 1,
                    leftNeighborIsPremiumCandidateSoFar: false,
                    isPenaltyTargetRiskSoFar: true,
                    premiumCandidatesThreateningPenaltyCount: 1
                )
            )
        )

        XCTAssertEqual(neutralDecision?.card, card(.clubs, .ace))
        XCTAssertEqual(penaltyRiskDecision?.card, card(.clubs, .seven))
    }

    func testMakeTurnDecision_whenStrongAntiPremiumPressureExists_flipsLastSeatDumpChoice() {
        let service = BotTurnStrategyService(tuning: BotTuning(difficulty: .hard))
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.clubs, .queen), fromPlayer: 1, animated: false)
        _ = trickNode.playCard(card(.clubs, .king), fromPlayer: 2, animated: false)
        _ = trickNode.playCard(card(.clubs, .jack), fromPlayer: 3, animated: false)

        let handCards: [Card] = [
            card(.clubs, .ace),
            card(.clubs, .seven)
        ]
        let neutralContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4,
            premium: .init(
                completedRoundsInBlock: 7,
                remainingRoundsInBlock: 1,
                isPremiumCandidateSoFar: false,
                isZeroPremiumRelevantInBlock: false,
                isZeroPremiumCandidateSoFar: false,
                leftNeighborIndex: 1,
                leftNeighborIsPremiumCandidateSoFar: false,
                isPenaltyTargetRiskSoFar: false,
                premiumCandidatesThreateningPenaltyCount: 0,
                opponentPremiumCandidatesSoFarCount: 0
            )
        )
        let strongAntiPremiumContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4,
            premium: .init(
                completedRoundsInBlock: 7,
                remainingRoundsInBlock: 1,
                isPremiumCandidateSoFar: false,
                isZeroPremiumRelevantInBlock: false,
                isZeroPremiumCandidateSoFar: false,
                leftNeighborIndex: 1,
                leftNeighborIsPremiumCandidateSoFar: true,
                isPenaltyTargetRiskSoFar: false,
                premiumCandidatesThreateningPenaltyCount: 0,
                opponentPremiumCandidatesSoFarCount: 4
            )
        )

        let neutralDecision = service.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
            trump: .hearts,
            bid: 0,
            tricksTaken: 1, // уже overbid, в нейтральном контексте бот обычно продолжает dump
            cardsInRound: 8,
            playerCount: 4,
            matchContext: neutralContext
        )
        let antiPremiumDecision = service.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
            trump: .hearts,
            bid: 0,
            tricksTaken: 1,
            cardsInRound: 8,
            playerCount: 4,
            matchContext: strongAntiPremiumContext
        )

        XCTAssertEqual(neutralDecision?.card, card(.clubs, .seven))
        XCTAssertEqual(antiPremiumDecision?.card, card(.clubs, .ace))
    }

    func testMakeTurnDecision_whenAllInChaseAntiPremiumContext_andOpponentModelHasNoEvidence_keepsDecisionUnchanged() {
        let service = BotTurnStrategyService(tuning: BotTuning(difficulty: .hard))
        let trickNode = TrickNode()
        let handCards: [Card] = [
            .joker,
            card(.clubs, .six),
            card(.diamonds, .seven),
            card(.hearts, .eight)
        ]
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

        let baselineDecision = service.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
            trump: .spades,
            bid: 4,
            tricksTaken: 0,
            cardsInRound: 8,
            playerCount: 4,
            matchContext: withoutOpponents
        )
        let noEvidenceDecision = service.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
            trump: .spades,
            bid: 4,
            tricksTaken: 0,
            cardsInRound: 8,
            playerCount: 4,
            matchContext: noEvidenceOpponents
        )

        XCTAssertEqual(noEvidenceDecision?.card, baselineDecision?.card)
        XCTAssertEqual(noEvidenceDecision?.jokerDecision, baselineDecision?.jokerDecision)
        XCTAssertEqual(baselineDecision?.jokerDecision.leadDeclaration, .above(suit: .spades))
    }

    func testMakeTurnDecision_whenModeratePremiumDenyContext_andDisciplinedObservedLeftNeighborFlipsDumpChoiceComparedToErratic() {
        let service = BotTurnStrategyService(tuning: BotTuning(difficulty: .hard))
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.clubs, .queen), fromPlayer: 1, animated: false)
        _ = trickNode.playCard(card(.clubs, .king), fromPlayer: 2, animated: false)
        _ = trickNode.playCard(card(.clubs, .jack), fromPlayer: 3, animated: false)
        let handCards: [Card] = [
            card(.clubs, .ace),
            card(.clubs, .seven)
        ]
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
        let disciplinedContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 5,
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
                    observedRounds: 4,
                    blindBidRate: 0.50,
                    exactBidRate: 0.75,
                    overbidRate: 0.10,
                    underbidRate: 0.15,
                    averageBidAggression: 0.72
                ),
                others: []
            )
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
            opponents: makeOpponentModel(
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
        )

        let disciplinedDecision = service.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
            trump: .hearts,
            bid: 0,
            tricksTaken: 1,
            cardsInRound: 8,
            playerCount: 4,
            matchContext: disciplinedContext
        )
        let erraticDecision = service.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
            trump: .hearts,
            bid: 0,
            tricksTaken: 1,
            cardsInRound: 8,
            playerCount: 4,
            matchContext: erraticContext
        )

        XCTAssertEqual(disciplinedDecision?.card, card(.clubs, .ace))
        XCTAssertEqual(erraticDecision?.card, card(.clubs, .seven))
    }

    func testLatencyBaseline_makeTurnDecision_reportsBatchAverage() {
        let service = BotTurnStrategyService(tuning: BotTuning(difficulty: .hard))

        let leadJokerDumpTrick = TrickNode()
        let latePremiumDumpTrick = TrickNode()
        _ = latePremiumDumpTrick.playCard(card(.clubs, .six), fromPlayer: 1, animated: false)
        let penaltyRiskTrick = TrickNode()
        _ = penaltyRiskTrick.playCard(card(.clubs, .queen), fromPlayer: 1, animated: false)
        let antiPremiumLateDumpTrick = TrickNode()
        _ = antiPremiumLateDumpTrick.playCard(card(.clubs, .queen), fromPlayer: 1, animated: false)
        _ = antiPremiumLateDumpTrick.playCard(card(.clubs, .king), fromPlayer: 2, animated: false)
        _ = antiPremiumLateDumpTrick.playCard(card(.clubs, .jack), fromPlayer: 3, animated: false)
        let simpleFollowTrick = TrickNode()
        _ = simpleFollowTrick.playCard(card(.hearts, .queen), fromPlayer: 1, animated: false)

        let latePremiumContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4,
            premium: .init(
                completedRoundsInBlock: 7,
                remainingRoundsInBlock: 1,
                isPremiumCandidateSoFar: true,
                isZeroPremiumRelevantInBlock: false,
                isZeroPremiumCandidateSoFar: false
            )
        )
        let penaltyRiskContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4,
            premium: .init(
                completedRoundsInBlock: 7,
                remainingRoundsInBlock: 1,
                isPremiumCandidateSoFar: false,
                isZeroPremiumRelevantInBlock: false,
                isZeroPremiumCandidateSoFar: false,
                leftNeighborIndex: 1,
                leftNeighborIsPremiumCandidateSoFar: false,
                isPenaltyTargetRiskSoFar: true,
                premiumCandidatesThreateningPenaltyCount: 1
            )
        )
        let antiPremiumContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4,
            premium: .init(
                completedRoundsInBlock: 7,
                remainingRoundsInBlock: 1,
                isPremiumCandidateSoFar: false,
                isZeroPremiumRelevantInBlock: false,
                isZeroPremiumCandidateSoFar: false,
                leftNeighborIndex: 1,
                leftNeighborIsPremiumCandidateSoFar: true,
                isPenaltyTargetRiskSoFar: false,
                premiumCandidatesThreateningPenaltyCount: 0,
                opponentPremiumCandidatesSoFarCount: 4
            )
        )

        let scenarios: [() -> Void] = [
            {
                _ = service.makeTurnDecision(
                    handCards: [.joker, self.card(.spades, .ace), self.card(.spades, .king), self.card(.spades, .queen)],
                    trickNode: leadJokerDumpTrick,
                    trump: .spades,
                    bid: 0,
                    tricksTaken: 2,
                    cardsInRound: 8,
                    playerCount: 4
                )
            },
            {
                _ = service.makeTurnDecision(
                    handCards: [self.card(.clubs, .ace), self.card(.clubs, .seven)],
                    trickNode: latePremiumDumpTrick,
                    trump: .spades,
                    bid: 1,
                    tricksTaken: 1,
                    cardsInRound: 8,
                    playerCount: 4,
                    matchContext: latePremiumContext
                )
            },
            {
                _ = service.makeTurnDecision(
                    handCards: [self.card(.clubs, .ace), self.card(.clubs, .seven)],
                    trickNode: penaltyRiskTrick,
                    trump: .hearts,
                    bid: 0,
                    tricksTaken: 1,
                    cardsInRound: 8,
                    playerCount: 4,
                    matchContext: penaltyRiskContext
                )
            },
            {
                _ = service.makeTurnDecision(
                    handCards: [self.card(.clubs, .ace), self.card(.clubs, .seven)],
                    trickNode: antiPremiumLateDumpTrick,
                    trump: .hearts,
                    bid: 0,
                    tricksTaken: 1,
                    cardsInRound: 8,
                    playerCount: 4,
                    matchContext: antiPremiumContext
                )
            },
            {
                _ = service.makeTurnDecision(
                    handCards: [self.card(.hearts, .ace), self.card(.hearts, .king)],
                    trickNode: simpleFollowTrick,
                    trump: .clubs,
                    bid: 1,
                    tricksTaken: 0,
                    cardsInRound: 8,
                    playerCount: 4,
                    isBlind: false
                )
            }
        ]

        // Warm up to reduce one-time costs (caches, lazy paths).
        for _ in 0..<200 {
            for scenario in scenarios { scenario() }
        }

        let measuredBatches = 2_000
        var decisions = 0
        let startNanos = DispatchTime.now().uptimeNanoseconds
        for _ in 0..<measuredBatches {
            for scenario in scenarios {
                scenario()
                decisions += 1
            }
        }
        let endNanos = DispatchTime.now().uptimeNanoseconds

        let elapsedNanos = endNanos - startNanos
        let avgMicros = Double(elapsedNanos) / Double(max(1, decisions)) / 1_000.0
        let totalMillis = Double(elapsedNanos) / 1_000_000.0

        print(
            String(
                format: "BOT_LATENCY_BASELINE makeTurnDecision decisions=%d total_ms=%.3f avg_us=%.3f",
                decisions,
                totalMillis,
                avgMicros
            )
        )

        XCTAssertEqual(decisions, measuredBatches * scenarios.count)
    }

    private func card(_ suit: Suit, _ rank: Rank) -> Card {
        return .regular(suit: suit, rank: rank)
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
