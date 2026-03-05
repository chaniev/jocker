//
//  BotTurnCandidateRankingServiceTests_Blind.swift
//  JockerTests
//
//  Created by Codex on 04.03.2026.
//

import XCTest
@testable import Jocker

extension BotTurnCandidateRankingServiceTests {
    func testMoveUtility_whenBlindChasing_canFlipChoiceTowardHigherWinChance() {
        let trickNode = makeTrickNode()
        _ = trickNode.playCard(card(.hearts, .queen), fromPlayer: 1, animated: false)
        let params = commonUtilityParams(
            trickNode: trickNode,
            trump: .clubs,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false
        )

        let highWinHighThreatMove = BotTurnCandidateRankingService.Move(
            card: card(.hearts, .ace),
            decision: .defaultNonLead
        )
        let lowerWinLowThreatMove = BotTurnCandidateRankingService.Move(
            card: card(.hearts, .king),
            decision: .defaultNonLead
        )

        let regularHighWin = service.moveUtility(
            projectedScore: params.projectedScore,
            immediateWinProbability: 0.85,
            threat: 88,
            move: highWinHighThreatMove,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: params.tricksNeededToMatchBid,
            tricksRemainingIncludingCurrent: params.tricksRemainingIncludingCurrent,
            chasePressure: params.chasePressure,
            isBlindRound: false
        )
        let regularLowThreat = service.moveUtility(
            projectedScore: params.projectedScore,
            immediateWinProbability: 0.80,
            threat: 6,
            move: lowerWinLowThreatMove,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: params.tricksNeededToMatchBid,
            tricksRemainingIncludingCurrent: params.tricksRemainingIncludingCurrent,
            chasePressure: params.chasePressure,
            isBlindRound: false
        )

        let blindHighWin = service.moveUtility(
            projectedScore: params.projectedScore,
            immediateWinProbability: 0.85,
            threat: 88,
            move: highWinHighThreatMove,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: params.tricksNeededToMatchBid,
            tricksRemainingIncludingCurrent: params.tricksRemainingIncludingCurrent,
            chasePressure: params.chasePressure,
            isBlindRound: true
        )
        let blindLowThreat = service.moveUtility(
            projectedScore: params.projectedScore,
            immediateWinProbability: 0.80,
            threat: 6,
            move: lowerWinLowThreatMove,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: params.tricksNeededToMatchBid,
            tricksRemainingIncludingCurrent: params.tricksRemainingIncludingCurrent,
            chasePressure: params.chasePressure,
            isBlindRound: true
        )

        XCTAssertLessThan(regularHighWin, regularLowThreat)
        XCTAssertGreaterThan(blindHighWin, blindLowThreat)
    }

    func testMoveUtility_whenBlindChasing_andDisciplinedObservedLeftNeighbor_increasesBlindContestUtility() {
        let trickNode = makeTrickNode()
        _ = trickNode.playCard(card(.hearts, .queen), fromPlayer: 1, animated: false)
        let params = commonUtilityParams(
            trickNode: trickNode,
            trump: .clubs,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false
        )
        let move = BotTurnCandidateRankingService.Move(
            card: card(.hearts, .ace),
            decision: .defaultNonLead
        )
        let disciplinedContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4,
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
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4,
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

        func utility(matchContext: BotMatchContext) -> Double {
            service.moveUtility(
                projectedScore: params.projectedScore,
                immediateWinProbability: 0.85,
                threat: 6,
                move: move,
                trickNode: params.trickNode,
                trump: params.trump,
                shouldChaseTrick: params.shouldChaseTrick,
                hasWinningNonJoker: params.hasWinningNonJoker,
                hasLosingNonJoker: params.hasLosingNonJoker,
                tricksNeededToMatchBid: params.tricksNeededToMatchBid,
                tricksRemainingIncludingCurrent: params.tricksRemainingIncludingCurrent,
                chasePressure: params.chasePressure,
                isBlindRound: true,
                matchContext: matchContext
            )
        }

        let disciplinedUtility = utility(matchContext: disciplinedContext)
        let erraticUtility = utility(matchContext: erraticContext)

        XCTAssertGreaterThan(disciplinedUtility, erraticUtility)
    }

    func testMoveUtility_whenBlindChasing_andOpponentModelHasNoEvidence_keepsBlindContestUtilityUnchanged() {
        let trickNode = makeTrickNode()
        _ = trickNode.playCard(card(.hearts, .queen), fromPlayer: 1, animated: false)
        let params = commonUtilityParams(
            trickNode: trickNode,
            trump: .clubs,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false
        )
        let move = BotTurnCandidateRankingService.Move(
            card: card(.hearts, .ace),
            decision: .defaultNonLead
        )
        let withoutOpponents = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4,
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

        func utility(matchContext: BotMatchContext) -> Double {
            service.moveUtility(
                projectedScore: params.projectedScore,
                immediateWinProbability: 0.85,
                threat: 6,
                move: move,
                trickNode: params.trickNode,
                trump: params.trump,
                shouldChaseTrick: params.shouldChaseTrick,
                hasWinningNonJoker: params.hasWinningNonJoker,
                hasLosingNonJoker: params.hasLosingNonJoker,
                tricksNeededToMatchBid: params.tricksNeededToMatchBid,
                tricksRemainingIncludingCurrent: params.tricksRemainingIncludingCurrent,
                chasePressure: params.chasePressure,
                isBlindRound: true,
                matchContext: matchContext
            )
        }

        let baseUtility = utility(matchContext: withoutOpponents)
        let noEvidenceUtility = utility(matchContext: noEvidenceOpponents)

        XCTAssertEqual(noEvidenceUtility, baseUtility, accuracy: 0.0001)
    }

    func testMoveUtility_whenOpponentNeedsSingleTrick_inChase_increasesControlUtility() {
        let trickNode = makeTrickNode()
        _ = trickNode.playCard(card(.hearts, .queen), fromPlayer: 1, animated: false)
        let move = BotTurnCandidateRankingService.Move(
            card: card(.hearts, .ace),
            decision: .defaultNonLead
        )
        let roundStateWithNeed = BotMatchContext.RoundSnapshot(
            bids: [2, 2, 0, 0],
            tricksTaken: [1, 1, 0, 0], // player 1 needs exactly 1 trick
            isBlindBid: [false, false, false, false]
        )
        let neutralRoundState = BotMatchContext.RoundSnapshot(
            bids: [2, 2, 0, 0],
            tricksTaken: [1, 2, 0, 0], // player 1 already matched bid
            isBlindBid: [false, false, false, false]
        )
        let matchContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 6,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4,
            round: roundStateWithNeed
        )

        let baseUtility = service.moveUtility(
            projectedScore: 20,
            immediateWinProbability: 0.85,
            threat: 8,
            move: move,
            context: .init(
                trick: .init(trickNode: trickNode),
                trump: .clubs,
                shouldChaseTrick: true,
                hasWinningNonJoker: false,
                hasLosingNonJoker: false,
                tricksNeededToMatchBid: 1,
                tricksRemainingIncludingCurrent: 2,
                chasePressure: 0.5,
                matchContext: matchContext,
                roundState: neutralRoundState,
                actingPlayerIndex: 0,
                remainingOpponentPlayerIndices: [1, 2]
            )
        )
        let pressuredUtility = service.moveUtility(
            projectedScore: 20,
            immediateWinProbability: 0.85,
            threat: 8,
            move: move,
            context: .init(
                trick: .init(trickNode: trickNode),
                trump: .clubs,
                shouldChaseTrick: true,
                hasWinningNonJoker: false,
                hasLosingNonJoker: false,
                tricksNeededToMatchBid: 1,
                tricksRemainingIncludingCurrent: 2,
                chasePressure: 0.5,
                matchContext: matchContext,
                roundState: roundStateWithNeed,
                actingPlayerIndex: 0,
                remainingOpponentPlayerIndices: [1, 2]
            )
        )

        XCTAssertGreaterThan(pressuredUtility, baseUtility)
    }

    func testMoveUtility_whenOpponentNeedsSingleTrick_inDump_penalizesSafeLoss() {
        let trickNode = makeTrickNode()
        _ = trickNode.playCard(card(.clubs, .queen), fromPlayer: 1, animated: false)
        let losingMove = BotTurnCandidateRankingService.Move(
            card: card(.clubs, .seven),
            decision: .defaultNonLead
        )
        let roundStateWithNeed = BotMatchContext.RoundSnapshot(
            bids: [0, 2, 0, 0],
            tricksTaken: [1, 1, 0, 0], // player 1 needs exactly 1 trick
            isBlindBid: [false, false, false, false]
        )
        let neutralRoundState = BotMatchContext.RoundSnapshot(
            bids: [0, 2, 0, 0],
            tricksTaken: [1, 2, 0, 0],
            isBlindBid: [false, false, false, false]
        )
        let matchContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 6,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4,
            round: roundStateWithNeed
        )

        let baseUtility = service.moveUtility(
            projectedScore: 5,
            immediateWinProbability: 0.10,
            threat: 4,
            move: losingMove,
            context: .init(
                trick: .init(trickNode: trickNode),
                trump: .hearts,
                shouldChaseTrick: false,
                hasWinningNonJoker: true,
                hasLosingNonJoker: true,
                tricksNeededToMatchBid: 0,
                tricksRemainingIncludingCurrent: 2,
                trickDeltaToBidBeforeMove: 1,
                chasePressure: 0.0,
                matchContext: matchContext,
                roundState: neutralRoundState,
                actingPlayerIndex: 0,
                remainingOpponentPlayerIndices: [1]
            )
        )
        let pressuredUtility = service.moveUtility(
            projectedScore: 5,
            immediateWinProbability: 0.10,
            threat: 4,
            move: losingMove,
            context: .init(
                trick: .init(trickNode: trickNode),
                trump: .hearts,
                shouldChaseTrick: false,
                hasWinningNonJoker: true,
                hasLosingNonJoker: true,
                tricksNeededToMatchBid: 0,
                tricksRemainingIncludingCurrent: 2,
                trickDeltaToBidBeforeMove: 1,
                chasePressure: 0.0,
                matchContext: matchContext,
                roundState: roundStateWithNeed,
                actingPlayerIndex: 0,
                remainingOpponentPlayerIndices: [1]
            )
        )

        XCTAssertLessThan(pressuredUtility, baseUtility)
    }

    func testMoveUtility_whenOpponentIntentionModelHasNoEvidence_keepsUtilityUnchanged() {
        let trickNode = makeTrickNode()
        _ = trickNode.playCard(card(.hearts, .queen), fromPlayer: 1, animated: false)
        let move = BotTurnCandidateRankingService.Move(
            card: card(.hearts, .ace),
            decision: .defaultNonLead
        )
        let noEvidenceModel = BotTurnCandidateRankingService.OpponentIntentionModel(
            opponentSignals: [
                .init(
                    playerIndex: 1,
                    needsTricks: 1,
                    likelyToContestCurrentTrick: 0.95,
                    denyPressure: 0.95,
                    evidenceWeight: 0.0
                )
            ],
            strongestTargetIndex: 1,
            strongestDenyPressure: 0.95,
            totalDenyPressure: 0.95,
            hasEvidence: false
        )

        let baselineUtility = service.moveUtility(
            projectedScore: 12,
            immediateWinProbability: 0.70,
            threat: 8,
            move: move,
            context: .init(
                trick: .init(trickNode: trickNode),
                trump: .clubs,
                shouldChaseTrick: true,
                hasWinningNonJoker: false,
                hasLosingNonJoker: false,
                tricksNeededToMatchBid: 1,
                tricksRemainingIncludingCurrent: 2,
                chasePressure: 0.5
            )
        )
        let noEvidenceUtility = service.moveUtility(
            projectedScore: 12,
            immediateWinProbability: 0.70,
            threat: 8,
            move: move,
            context: .init(
                trick: .init(trickNode: trickNode),
                trump: .clubs,
                shouldChaseTrick: true,
                hasWinningNonJoker: false,
                hasLosingNonJoker: false,
                tricksNeededToMatchBid: 1,
                tricksRemainingIncludingCurrent: 2,
                chasePressure: 0.5,
                opponentIntention: noEvidenceModel
            )
        )

        XCTAssertEqual(noEvidenceUtility, baselineUtility, accuracy: 0.0001)
    }
}
