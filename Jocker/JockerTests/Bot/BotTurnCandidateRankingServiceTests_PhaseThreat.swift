//
//  BotTurnCandidateRankingServiceTests_PhaseThreat.swift
//  JockerTests
//
//  Created by Codex on 04.03.2026.
//

import XCTest
@testable import Jocker

extension BotTurnCandidateRankingServiceTests {
    func testMoveUtility_withNeutralMatchContext_preservesBehavior() {
        let baselineService = service
        let neutralPhaseService = makeService()
        let trickNode = makeTrickNode()
        _ = trickNode.playCard(card(.clubs, .queen), fromPlayer: 1, animated: false)
        let params = commonUtilityParams(
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: true,
            hasWinningNonJoker: true,
            hasLosingNonJoker: false
        )
        let move = BotTurnCandidateRankingService.Move(
            card: card(.clubs, .king),
            decision: .defaultNonLead
        )

        let baseline = baselineService.moveUtility(
            projectedScore: params.projectedScore,
            immediateWinProbability: params.immediateWinProbability,
            threat: params.threat,
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
            matchContext: sampleMatchContext()
        )
        let withNeutralPhaseTuning = neutralPhaseService.moveUtility(
            projectedScore: params.projectedScore,
            immediateWinProbability: params.immediateWinProbability,
            threat: params.threat,
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
            matchContext: sampleMatchContext()
        )

        XCTAssertEqual(withNeutralPhaseTuning, baseline, accuracy: 0.0001)
    }

    func testMoveUtility_withLateBlockScoreDeficit_increasesChaseRiskUtility() {
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

        let noContext = service.moveUtility(
            projectedScore: params.projectedScore,
            immediateWinProbability: 0.86,
            threat: 40,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: params.tricksNeededToMatchBid,
            tricksRemainingIncludingCurrent: params.tricksRemainingIncludingCurrent,
            chasePressure: params.chasePressure
        )
        let trailingLateBlock = service.moveUtility(
            projectedScore: params.projectedScore,
            immediateWinProbability: 0.86,
            threat: 40,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: params.tricksNeededToMatchBid,
            tricksRemainingIncludingCurrent: params.tricksRemainingIncludingCurrent,
            chasePressure: params.chasePressure,
            matchContext: BotMatchContext(
                block: .fourth,
                roundIndexInBlock: 7,
                totalRoundsInBlock: 8,
                totalScores: [80, 160, 150, 140],
                playerIndex: 0,
                dealerIndex: 2,
                playerCount: 4
            )
        )
        let leadingLateBlock = service.moveUtility(
            projectedScore: params.projectedScore,
            immediateWinProbability: 0.86,
            threat: 40,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: params.tricksNeededToMatchBid,
            tricksRemainingIncludingCurrent: params.tricksRemainingIncludingCurrent,
            chasePressure: params.chasePressure,
            matchContext: BotMatchContext(
                block: .fourth,
                roundIndexInBlock: 7,
                totalRoundsInBlock: 8,
                totalScores: [180, 110, 95, 90],
                playerIndex: 0,
                dealerIndex: 2,
                playerCount: 4
            )
        )

        XCTAssertGreaterThan(trailingLateBlock, noContext)
        XCTAssertLessThan(leadingLateBlock, noContext)
    }

    func testMoveUtility_withPhaseRankingTuning_amplifiesLateCatchUpAndSoftensEarlyCatchUp() {
        let baselineService = service
        let tunedService = makeService(phaseRankingScale: 1.25)
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
        let earlyContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 1,
            totalRoundsInBlock: 8,
            totalScores: [80, 160, 150, 140],
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4
        )
        let lateContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [80, 160, 150, 140],
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4
        )

        func utility(
            using service: BotTurnCandidateRankingService,
            matchContext: BotMatchContext
        ) -> Double {
            service.moveUtility(
                projectedScore: params.projectedScore,
                immediateWinProbability: 0.86,
                threat: 40,
                move: move,
                trickNode: params.trickNode,
                trump: params.trump,
                shouldChaseTrick: params.shouldChaseTrick,
                hasWinningNonJoker: params.hasWinningNonJoker,
                hasLosingNonJoker: params.hasLosingNonJoker,
                tricksNeededToMatchBid: params.tricksNeededToMatchBid,
                tricksRemainingIncludingCurrent: params.tricksRemainingIncludingCurrent,
                chasePressure: params.chasePressure,
                matchContext: matchContext
            )
        }

        let baselineEarly = utility(using: baselineService, matchContext: earlyContext)
        let tunedEarly = utility(using: tunedService, matchContext: earlyContext)
        let baselineLate = utility(using: baselineService, matchContext: lateContext)
        let tunedLate = utility(using: tunedService, matchContext: lateContext)

        XCTAssertLessThan(tunedEarly, baselineEarly)
        XCTAssertGreaterThan(tunedLate, baselineLate)
    }

    func testMoveUtility_withLateBlockScoreDeficit_andDisciplinedObservedLeftNeighbor_increasesCatchUpUtility() {
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
        let trailingBaseContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [80, 160, 150, 140],
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4
        )
        let disciplinedContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [80, 160, 150, 140],
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
            totalScores: [80, 160, 150, 140],
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
                immediateWinProbability: 0.86,
                threat: 40,
                move: move,
                trickNode: params.trickNode,
                trump: params.trump,
                shouldChaseTrick: params.shouldChaseTrick,
                hasWinningNonJoker: params.hasWinningNonJoker,
                hasLosingNonJoker: params.hasLosingNonJoker,
                tricksNeededToMatchBid: params.tricksNeededToMatchBid,
                tricksRemainingIncludingCurrent: params.tricksRemainingIncludingCurrent,
                chasePressure: params.chasePressure,
                matchContext: matchContext
            )
        }

        let trailingNoOpponents = utility(matchContext: trailingBaseContext)
        let disciplinedUtility = utility(matchContext: disciplinedContext)
        let erraticUtility = utility(matchContext: erraticContext)

        XCTAssertGreaterThan(disciplinedUtility, trailingNoOpponents)
        XCTAssertLessThan(erraticUtility, trailingNoOpponents)
        XCTAssertGreaterThan(disciplinedUtility, erraticUtility)
    }

    func testMoveUtility_withLateBlockScoreDeficit_andOpponentModelHasNoEvidence_keepsCatchUpUtilityUnchanged() {
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
            totalScores: [80, 160, 150, 140],
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4,
            opponents: nil
        )
        let noEvidenceOpponents = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [80, 160, 150, 140],
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
                immediateWinProbability: 0.86,
                threat: 40,
                move: move,
                trickNode: params.trickNode,
                trump: params.trump,
                shouldChaseTrick: params.shouldChaseTrick,
                hasWinningNonJoker: params.hasWinningNonJoker,
                hasLosingNonJoker: params.hasLosingNonJoker,
                tricksNeededToMatchBid: params.tricksNeededToMatchBid,
                tricksRemainingIncludingCurrent: params.tricksRemainingIncludingCurrent,
                chasePressure: params.chasePressure,
                matchContext: matchContext
            )
        }

        let baseUtility = utility(matchContext: withoutOpponents)
        let noEvidenceUtility = utility(matchContext: noEvidenceOpponents)

        XCTAssertEqual(noEvidenceUtility, baseUtility, accuracy: 0.0001)
    }

    func testMoveUtility_withLateBlockLead_inDumpMode_prefersSaferLossTrajectory() {
        let trickNode = makeTrickNode()
        _ = trickNode.playCard(card(.hearts, .ace), fromPlayer: 1, animated: false)
        let params = commonUtilityParams(
            trickNode: trickNode,
            trump: .clubs,
            shouldChaseTrick: false,
            hasWinningNonJoker: true,
            hasLosingNonJoker: true
        )
        let move = BotTurnCandidateRankingService.Move(
            card: card(.hearts, .king),
            decision: .defaultNonLead
        )
        let leadingContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [190, 120, 110, 100],
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4
        )
        let trailingContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [90, 170, 150, 140],
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4
        )

        func utility(for context: BotMatchContext) -> Double {
            service.moveUtility(
                projectedScore: params.projectedScore,
                immediateWinProbability: 0.22,
                threat: 36,
                move: move,
                trickNode: params.trickNode,
                trump: params.trump,
                shouldChaseTrick: params.shouldChaseTrick,
                hasWinningNonJoker: params.hasWinningNonJoker,
                hasLosingNonJoker: params.hasLosingNonJoker,
                tricksNeededToMatchBid: params.tricksNeededToMatchBid,
                tricksRemainingIncludingCurrent: params.tricksRemainingIncludingCurrent,
                chasePressure: params.chasePressure,
                matchContext: context
            )
        }

        let leadingUtility = utility(for: leadingContext)
        let trailingUtility = utility(for: trailingContext)

        XCTAssertGreaterThan(leadingUtility, trailingUtility)
    }

    func testMoveUtility_matchCatchUpBias_isNearZeroAtEarlyBlockStart() {
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

        let baseline = service.moveUtility(
            projectedScore: params.projectedScore,
            immediateWinProbability: 0.86,
            threat: 40,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: params.tricksNeededToMatchBid,
            tricksRemainingIncludingCurrent: params.tricksRemainingIncludingCurrent,
            chasePressure: params.chasePressure
        )
        let earlyDeficit = service.moveUtility(
            projectedScore: params.projectedScore,
            immediateWinProbability: 0.86,
            threat: 40,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: params.tricksNeededToMatchBid,
            tricksRemainingIncludingCurrent: params.tricksRemainingIncludingCurrent,
            chasePressure: params.chasePressure,
            matchContext: BotMatchContext(
                block: .fourth,
                roundIndexInBlock: 0,
                totalRoundsInBlock: 8,
                totalScores: [80, 160, 150, 140],
                playerIndex: 0,
                dealerIndex: 2,
                playerCount: 4
            )
        )

        XCTAssertEqual(earlyDeficit, baseline, accuracy: 2.0)
    }
}
