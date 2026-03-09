//
//  BotTurnCandidateRankingServiceTests_PremiumPenalty.swift
//  JockerTests
//
//  Created by Codex on 04.03.2026.
//

import XCTest
@testable import Jocker

extension BotTurnCandidateRankingServiceTests {
    func testMoveUtility_whenPremiumCandidateAndLateBlock_dumpingGetsExtraAvoidWinReward() {
        let trickNode = makeTrickNode()
        _ = trickNode.playCard(card(.spades, .ace), fromPlayer: 1, animated: false)
        let params = commonUtilityParams(
            trickNode: trickNode,
            trump: .clubs,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: true
        )
        let move = BotTurnCandidateRankingService.Move(
            card: card(.spades, .seven),
            decision: .defaultNonLead
        )

        let noPremiumContext = service.moveUtility(
            projectedScore: params.projectedScore,
            immediateWinProbability: 0.20,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            chasePressure: params.chasePressure,
            matchContext: BotMatchContext(
                block: .fourth,
                roundIndexInBlock: 7,
                totalRoundsInBlock: 8,
                totalScores: [120, 120, 120, 120],
                playerIndex: 0,
                dealerIndex: 1,
                playerCount: 4,
                premium: nil
            )
        )
        let premiumCandidate = service.moveUtility(
            projectedScore: params.projectedScore,
            immediateWinProbability: 0.20,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            chasePressure: params.chasePressure,
            matchContext: BotMatchContext(
                block: .fourth,
                roundIndexInBlock: 7,
                totalRoundsInBlock: 8,
                totalScores: [120, 120, 120, 120],
                playerIndex: 0,
                dealerIndex: 1,
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

        XCTAssertGreaterThan(premiumCandidate, noPremiumContext)
    }

    func testMoveUtility_whenZeroPremiumCandidate_penalizesChaseEvenMore() {
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

        let noPremiumContext = service.moveUtility(
            projectedScore: params.projectedScore,
            immediateWinProbability: 0.9,
            threat: 15,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 1,
            tricksRemainingIncludingCurrent: 1,
            chasePressure: 1.0,
            matchContext: BotMatchContext(
                block: .third,
                roundIndexInBlock: 6,
                totalRoundsInBlock: 7,
                totalScores: [100, 100, 100, 100],
                playerIndex: 0,
                dealerIndex: 2,
                playerCount: 4,
                premium: nil
            )
        )
        let zeroPremiumCandidate = service.moveUtility(
            projectedScore: params.projectedScore,
            immediateWinProbability: 0.9,
            threat: 15,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 1,
            tricksRemainingIncludingCurrent: 1,
            chasePressure: 1.0,
            matchContext: BotMatchContext(
                block: .third,
                roundIndexInBlock: 6,
                totalRoundsInBlock: 7,
                totalScores: [100, 100, 100, 100],
                playerIndex: 0,
                dealerIndex: 2,
                playerCount: 4,
                premium: .init(
                    completedRoundsInBlock: 6,
                    remainingRoundsInBlock: 1,
                    isPremiumCandidateSoFar: true,
                    isZeroPremiumRelevantInBlock: true,
                    isZeroPremiumCandidateSoFar: true
                )
            )
        )

        XCTAssertLessThan(zeroPremiumCandidate, noPremiumContext)
    }

    func testMoveUtility_premiumPreserveEffect_isStrongerNearBlockEndThanEarly() {
        let trickNode = makeTrickNode()
        _ = trickNode.playCard(card(.spades, .ace), fromPlayer: 1, animated: false)
        let params = commonUtilityParams(
            trickNode: trickNode,
            trump: .clubs,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: true
        )
        let move = BotTurnCandidateRankingService.Move(
            card: card(.spades, .seven),
            decision: .defaultNonLead
        )

        let noPremium = service.moveUtility(
            projectedScore: params.projectedScore,
            immediateWinProbability: 0.20,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            chasePressure: params.chasePressure,
            matchContext: BotMatchContext(
                block: .fourth,
                roundIndexInBlock: 1,
                totalRoundsInBlock: 8,
                totalScores: [100, 100, 100, 100],
                playerIndex: 0,
                dealerIndex: 1,
                playerCount: 4,
                premium: nil
            )
        )
        let earlyPremiumCandidate = service.moveUtility(
            projectedScore: params.projectedScore,
            immediateWinProbability: 0.20,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            chasePressure: params.chasePressure,
            matchContext: BotMatchContext(
                block: .fourth,
                roundIndexInBlock: 1,
                totalRoundsInBlock: 8,
                totalScores: [100, 100, 100, 100],
                playerIndex: 0,
                dealerIndex: 1,
                playerCount: 4,
                premium: .init(
                    completedRoundsInBlock: 1,
                    remainingRoundsInBlock: 7,
                    isPremiumCandidateSoFar: true,
                    isZeroPremiumRelevantInBlock: false,
                    isZeroPremiumCandidateSoFar: false
                )
            )
        )
        let latePremiumCandidate = service.moveUtility(
            projectedScore: params.projectedScore,
            immediateWinProbability: 0.20,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            chasePressure: params.chasePressure,
            matchContext: BotMatchContext(
                block: .fourth,
                roundIndexInBlock: 7,
                totalRoundsInBlock: 8,
                totalScores: [100, 100, 100, 100],
                playerIndex: 0,
                dealerIndex: 1,
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

        let earlyDelta = earlyPremiumCandidate - noPremium
        let lateDelta = latePremiumCandidate - noPremium
        XCTAssertGreaterThan(earlyDelta, 0.0)
        XCTAssertGreaterThan(lateDelta, earlyDelta)
    }

    func testMoveUtility_withPhaseRankingTuning_amplifiesLatePremiumPressureAndSoftensEarlyPressure() {
        let baselineService = service
        let tunedService = makeService(phaseRankingScale: 1.25)
        let trickNode = makeTrickNode()
        _ = trickNode.playCard(card(.spades, .ace), fromPlayer: 1, animated: false)
        let params = commonUtilityParams(
            trickNode: trickNode,
            trump: .clubs,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: true
        )
        let move = BotTurnCandidateRankingService.Move(
            card: card(.spades, .seven),
            decision: .defaultNonLead
        )
        let earlyPremiumContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 1,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 1,
            playerCount: 4,
            premium: .init(
                completedRoundsInBlock: 1,
                remainingRoundsInBlock: 7,
                isPremiumCandidateSoFar: true,
                isZeroPremiumRelevantInBlock: false,
                isZeroPremiumCandidateSoFar: false
            )
        )
        let latePremiumContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 1,
            playerCount: 4,
            premium: .init(
                completedRoundsInBlock: 7,
                remainingRoundsInBlock: 1,
                isPremiumCandidateSoFar: true,
                isZeroPremiumRelevantInBlock: false,
                isZeroPremiumCandidateSoFar: false
            )
        )

        func utility(
            using service: BotTurnCandidateRankingService,
            matchContext: BotMatchContext
        ) -> Double {
            service.moveUtility(
                projectedScore: params.projectedScore,
                immediateWinProbability: 0.20,
                threat: params.threat,
                move: move,
                trickNode: params.trickNode,
                trump: params.trump,
                shouldChaseTrick: params.shouldChaseTrick,
                hasWinningNonJoker: params.hasWinningNonJoker,
                hasLosingNonJoker: params.hasLosingNonJoker,
                tricksNeededToMatchBid: 0,
                tricksRemainingIncludingCurrent: 2,
                chasePressure: params.chasePressure,
                matchContext: matchContext
            )
        }

        let baselineEarly = utility(using: baselineService, matchContext: earlyPremiumContext)
        let tunedEarly = utility(using: tunedService, matchContext: earlyPremiumContext)
        let baselineLate = utility(using: baselineService, matchContext: latePremiumContext)
        let tunedLate = utility(using: tunedService, matchContext: latePremiumContext)

        XCTAssertLessThan(tunedEarly, baselineEarly)
        XCTAssertGreaterThan(tunedLate, baselineLate)
    }

    func testMoveUtility_premiumPreserveExactBidProtection_isStrongerThanAfterOverbidBreak() {
        let trickNode = makeTrickNode()
        _ = trickNode.playCard(card(.spades, .ace), fromPlayer: 1, animated: false)
        let params = commonUtilityParams(
            trickNode: trickNode,
            trump: .clubs,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: true
        )
        let move = BotTurnCandidateRankingService.Move(
            card: card(.spades, .seven),
            decision: .defaultNonLead
        )
        let premiumContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 1,
            playerCount: 4,
            premium: .init(
                completedRoundsInBlock: 7,
                remainingRoundsInBlock: 1,
                isPremiumCandidateSoFar: true,
                isZeroPremiumRelevantInBlock: false,
                isZeroPremiumCandidateSoFar: false
            )
        )

        let exactBidDumpUtility = service.moveUtility(
            projectedScore: params.projectedScore,
            immediateWinProbability: 0.30,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            trickDeltaToBidBeforeMove: 0,
            chasePressure: params.chasePressure,
            matchContext: premiumContext
        )
        let alreadyBrokenOverbidDumpUtility = service.moveUtility(
            projectedScore: params.projectedScore,
            immediateWinProbability: 0.30,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            trickDeltaToBidBeforeMove: 1,
            chasePressure: params.chasePressure,
            matchContext: premiumContext
        )

        XCTAssertGreaterThan(exactBidDumpUtility, alreadyBrokenOverbidDumpUtility)
    }

    func testMoveUtility_zeroPremiumExactBidProtection_isStrongerThanAfterBreak() {
        let trickNode = makeTrickNode()
        _ = trickNode.playCard(card(.spades, .ace), fromPlayer: 1, animated: false)
        let params = commonUtilityParams(
            trickNode: trickNode,
            trump: .clubs,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: true
        )
        let move = BotTurnCandidateRankingService.Move(
            card: card(.spades, .seven),
            decision: .defaultNonLead
        )
        let zeroPremiumContext = BotMatchContext(
            block: .third,
            roundIndexInBlock: 6,
            totalRoundsInBlock: 7,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 1,
            playerCount: 4,
            premium: .init(
                completedRoundsInBlock: 6,
                remainingRoundsInBlock: 1,
                isPremiumCandidateSoFar: true,
                isZeroPremiumRelevantInBlock: true,
                isZeroPremiumCandidateSoFar: true
            )
        )

        let exactBidDumpUtility = service.moveUtility(
            projectedScore: params.projectedScore,
            immediateWinProbability: 0.30,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            trickDeltaToBidBeforeMove: 0,
            chasePressure: params.chasePressure,
            matchContext: zeroPremiumContext
        )
        let brokenDumpUtility = service.moveUtility(
            projectedScore: params.projectedScore,
            immediateWinProbability: 0.30,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            trickDeltaToBidBeforeMove: 1,
            chasePressure: params.chasePressure,
            matchContext: zeroPremiumContext
        )

        XCTAssertGreaterThan(exactBidDumpUtility, brokenDumpUtility)
    }

    func testMoveUtility_whenPenaltyTargetRiskAndPositiveProjectedScore_reducesUtility() {
        let trickNode = makeTrickNode()
        _ = trickNode.playCard(card(.clubs, .queen), fromPlayer: 1, animated: false)
        let params = commonUtilityParams(
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: true
        )
        let move = BotTurnCandidateRankingService.Move(
            card: card(.clubs, .seven),
            decision: .defaultNonLead
        )
        let noPenaltyRiskContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 1,
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
        let penaltyRiskContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 1,
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

        let noPenaltyRisk = service.moveUtility(
            projectedScore: 140,
            immediateWinProbability: 0.25,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            trickDeltaToBidBeforeMove: 1,
            chasePressure: params.chasePressure,
            matchContext: noPenaltyRiskContext
        )
        let penaltyRisk = service.moveUtility(
            projectedScore: 140,
            immediateWinProbability: 0.25,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            trickDeltaToBidBeforeMove: 1,
            chasePressure: params.chasePressure,
            matchContext: penaltyRiskContext
        )

        XCTAssertLessThan(penaltyRisk, noPenaltyRisk)
    }

    func testMoveUtility_whenPenaltyTargetRisk_andDisciplinedObservedOpponent_strengthensPenaltyAvoidAdjustment() {
        let trickNode = makeTrickNode()
        _ = trickNode.playCard(card(.clubs, .queen), fromPlayer: 1, animated: false)
        let params = commonUtilityParams(
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: true
        )
        let move = BotTurnCandidateRankingService.Move(
            card: card(.clubs, .seven),
            decision: .defaultNonLead
        )
        let premium = BotMatchContext.PremiumSnapshot(
            completedRoundsInBlock: 7,
            remainingRoundsInBlock: 1,
            isPremiumCandidateSoFar: false,
            isZeroPremiumRelevantInBlock: false,
            isZeroPremiumCandidateSoFar: false,
            leftNeighborIndex: 1,
            leftNeighborIsPremiumCandidateSoFar: false,
            isPenaltyTargetRiskSoFar: true,
            premiumCandidatesThreateningPenaltyCount: 1,
            opponentPremiumCandidatesSoFarCount: 0
        )

        let disciplinedContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 1,
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
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 1,
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

        let disciplinedUtility = service.moveUtility(
            projectedScore: 140,
            immediateWinProbability: 0.25,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            trickDeltaToBidBeforeMove: 1,
            chasePressure: params.chasePressure,
            matchContext: disciplinedContext
        )
        let erraticUtility = service.moveUtility(
            projectedScore: 140,
            immediateWinProbability: 0.25,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            trickDeltaToBidBeforeMove: 1,
            chasePressure: params.chasePressure,
            matchContext: erraticContext
        )

        XCTAssertLessThan(disciplinedUtility, erraticUtility)
    }

    func testMoveUtility_whenPenaltyTargetRisk_andOpponentModelHasNoEvidence_keepsPenaltyAvoidAdjustmentUnchanged() {
        let trickNode = makeTrickNode()
        _ = trickNode.playCard(card(.clubs, .queen), fromPlayer: 1, animated: false)
        let params = commonUtilityParams(
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: true
        )
        let move = BotTurnCandidateRankingService.Move(
            card: card(.clubs, .seven),
            decision: .defaultNonLead
        )
        let premium = BotMatchContext.PremiumSnapshot(
            completedRoundsInBlock: 7,
            remainingRoundsInBlock: 1,
            isPremiumCandidateSoFar: false,
            isZeroPremiumRelevantInBlock: false,
            isZeroPremiumCandidateSoFar: false,
            leftNeighborIndex: 1,
            leftNeighborIsPremiumCandidateSoFar: false,
            isPenaltyTargetRiskSoFar: true,
            premiumCandidatesThreateningPenaltyCount: 1,
            opponentPremiumCandidatesSoFarCount: 0
        )

        let withoutOpponents = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 1,
            playerCount: 4,
            premium: premium
        )
        let noEvidenceOpponents = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 1,
            playerCount: 4,
            premium: premium,
            opponents: makeOpponentModel(
                leftNeighborIndex: 1,
                leftNeighbor: .init(
                    playerIndex: 1,
                    observedRounds: 0,
                    blindBidRate: 0,
                    exactBidRate: 0,
                    overbidRate: 0,
                    underbidRate: 0,
                    averageBidAggression: 0
                ),
                others: [
                    .init(
                        playerIndex: 2,
                        observedRounds: 0,
                        blindBidRate: 0,
                        exactBidRate: 0,
                        overbidRate: 0,
                        underbidRate: 0,
                        averageBidAggression: 0
                    )
                ]
            )
        )

        let baselineUtility = service.moveUtility(
            projectedScore: 140,
            immediateWinProbability: 0.25,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            trickDeltaToBidBeforeMove: 1,
            chasePressure: params.chasePressure,
            matchContext: withoutOpponents
        )
        let noEvidenceUtility = service.moveUtility(
            projectedScore: 140,
            immediateWinProbability: 0.25,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            trickDeltaToBidBeforeMove: 1,
            chasePressure: params.chasePressure,
            matchContext: noEvidenceOpponents
        )

        XCTAssertEqual(noEvidenceUtility, baselineUtility, accuracy: 0.0001)
    }

    func testMoveUtility_whenLeftNeighborPremiumCandidate_dumpingBecomesLessAttractive() {
        let trickNode = makeTrickNode()
        _ = trickNode.playCard(card(.clubs, .queen), fromPlayer: 1, animated: false)
        let params = commonUtilityParams(
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: true
        )
        let move = BotTurnCandidateRankingService.Move(
            card: card(.clubs, .seven),
            decision: .defaultNonLead
        )
        let neutralContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 1,
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
        let leftNeighborPremiumCandidate = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 1,
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
                premiumCandidatesThreateningPenaltyCount: 0
            )
        )

        let neutralUtility = service.moveUtility(
            projectedScore: 40,
            immediateWinProbability: 0.20,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            trickDeltaToBidBeforeMove: 0,
            chasePressure: params.chasePressure,
            matchContext: neutralContext
        )
        let denyUtility = service.moveUtility(
            projectedScore: 40,
            immediateWinProbability: 0.20,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            trickDeltaToBidBeforeMove: 0,
            chasePressure: params.chasePressure,
            matchContext: leftNeighborPremiumCandidate
        )

        XCTAssertLessThan(denyUtility, neutralUtility)
    }

    func testMoveUtility_whenOwnPremiumCandidate_suppressesPremiumDenyAdjustment() {
        let trickNode = makeTrickNode()
        _ = trickNode.playCard(card(.clubs, .queen), fromPlayer: 1, animated: false)
        let params = commonUtilityParams(
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: true
        )
        let move = BotTurnCandidateRankingService.Move(
            card: card(.clubs, .seven),
            decision: .defaultNonLead
        )
        let ownPremiumCandidateNoLeftNeighborThreat = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 1,
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
                premiumCandidatesThreateningPenaltyCount: 0
            )
        )
        let ownPremiumCandidateWithLeftNeighborThreat = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 1,
            playerCount: 4,
            premium: .init(
                completedRoundsInBlock: 7,
                remainingRoundsInBlock: 1,
                isPremiumCandidateSoFar: true,
                isZeroPremiumRelevantInBlock: false,
                isZeroPremiumCandidateSoFar: false,
                leftNeighborIndex: 1,
                leftNeighborIsPremiumCandidateSoFar: true,
                isPenaltyTargetRiskSoFar: false,
                premiumCandidatesThreateningPenaltyCount: 0
            )
        )

        let noDeny = service.moveUtility(
            projectedScore: 40,
            immediateWinProbability: 0.20,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            trickDeltaToBidBeforeMove: 0,
            chasePressure: params.chasePressure,
            matchContext: ownPremiumCandidateNoLeftNeighborThreat
        )
        let denySuppressed = service.moveUtility(
            projectedScore: 40,
            immediateWinProbability: 0.20,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            trickDeltaToBidBeforeMove: 0,
            chasePressure: params.chasePressure,
            matchContext: ownPremiumCandidateWithLeftNeighborThreat
        )

        XCTAssertEqual(denySuppressed, noDeny, accuracy: 0.0001)
    }

    func testMoveUtility_whenNonLeftOpponentPremiumCandidate_dumpingAlsoBecomesLessAttractive() {
        let trickNode = makeTrickNode()
        _ = trickNode.playCard(card(.clubs, .queen), fromPlayer: 1, animated: false)
        let params = commonUtilityParams(
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: true
        )
        let move = BotTurnCandidateRankingService.Move(
            card: card(.clubs, .seven),
            decision: .defaultNonLead
        )
        let neutralContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 1,
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
        let nonLeftOpponentPremiumCandidate = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 1,
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
                opponentPremiumCandidatesSoFarCount: 1
            )
        )

        let neutralUtility = service.moveUtility(
            projectedScore: 40,
            immediateWinProbability: 0.20,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            trickDeltaToBidBeforeMove: 0,
            chasePressure: params.chasePressure,
            matchContext: neutralContext
        )
        let denyUtility = service.moveUtility(
            projectedScore: 40,
            immediateWinProbability: 0.20,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            trickDeltaToBidBeforeMove: 0,
            chasePressure: params.chasePressure,
            matchContext: nonLeftOpponentPremiumCandidate
        )

        XCTAssertLessThan(denyUtility, neutralUtility)
    }

    func testMoveUtility_leftNeighborPremiumCandidate_hasStrongerDenyPressureThanNonLeftOnly() {
        let trickNode = makeTrickNode()
        _ = trickNode.playCard(card(.clubs, .queen), fromPlayer: 1, animated: false)
        let params = commonUtilityParams(
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: true
        )
        let move = BotTurnCandidateRankingService.Move(
            card: card(.clubs, .seven),
            decision: .defaultNonLead
        )

        let nonLeftOnly = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 1,
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
                opponentPremiumCandidatesSoFarCount: 1
            )
        )
        let leftNeighborAndOther = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 1,
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
                opponentPremiumCandidatesSoFarCount: 2
            )
        )

        let nonLeftOnlyUtility = service.moveUtility(
            projectedScore: 40,
            immediateWinProbability: 0.20,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            trickDeltaToBidBeforeMove: 0,
            chasePressure: params.chasePressure,
            matchContext: nonLeftOnly
        )
        let leftNeighborPriorityUtility = service.moveUtility(
            projectedScore: 40,
            immediateWinProbability: 0.20,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            trickDeltaToBidBeforeMove: 0,
            chasePressure: params.chasePressure,
            matchContext: leftNeighborAndOther
        )

        XCTAssertLessThan(leftNeighborPriorityUtility, nonLeftOnlyUtility)
    }

    func testMoveUtility_whenLeftNeighborPremiumCandidate_andDisciplinedLeftNeighborObserved_strengthensDenyPressure() {
        let trickNode = makeTrickNode()
        _ = trickNode.playCard(card(.clubs, .queen), fromPlayer: 1, animated: false)
        let params = commonUtilityParams(
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: true
        )
        let move = BotTurnCandidateRankingService.Move(
            card: card(.clubs, .seven),
            decision: .defaultNonLead
        )
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

        let disciplinedLeftNeighborContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 1,
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
        let erraticLeftNeighborContext = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 1,
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

        let disciplinedUtility = service.moveUtility(
            projectedScore: 40,
            immediateWinProbability: 0.20,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            trickDeltaToBidBeforeMove: 0,
            chasePressure: params.chasePressure,
            matchContext: disciplinedLeftNeighborContext
        )
        let erraticUtility = service.moveUtility(
            projectedScore: 40,
            immediateWinProbability: 0.20,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            trickDeltaToBidBeforeMove: 0,
            chasePressure: params.chasePressure,
            matchContext: erraticLeftNeighborContext
        )

        XCTAssertLessThan(disciplinedUtility, erraticUtility)
    }

    func testMoveUtility_whenOpponentModelHasNoEvidence_keepsDenyPressureUnchanged() {
        let trickNode = makeTrickNode()
        _ = trickNode.playCard(card(.clubs, .queen), fromPlayer: 1, animated: false)
        let params = commonUtilityParams(
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: true
        )
        let move = BotTurnCandidateRankingService.Move(
            card: card(.clubs, .seven),
            decision: .defaultNonLead
        )
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

        let withoutOpponentModel = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 1,
            playerCount: 4,
            premium: premium
        )
        let noEvidenceOpponentModel = BotMatchContext(
            block: .fourth,
            roundIndexInBlock: 7,
            totalRoundsInBlock: 8,
            totalScores: [100, 100, 100, 100],
            playerIndex: 0,
            dealerIndex: 1,
            playerCount: 4,
            premium: premium,
            opponents: makeOpponentModel(
                leftNeighborIndex: 1,
                leftNeighbor: .init(
                    playerIndex: 1,
                    observedRounds: 0,
                    blindBidRate: 0,
                    exactBidRate: 0,
                    overbidRate: 0,
                    underbidRate: 0,
                    averageBidAggression: 0
                ),
                others: [
                    .init(
                        playerIndex: 2,
                        observedRounds: 0,
                        blindBidRate: 0,
                        exactBidRate: 0,
                        overbidRate: 0,
                        underbidRate: 0,
                        averageBidAggression: 0
                    )
                ]
            )
        )

        let baseline = service.moveUtility(
            projectedScore: 40,
            immediateWinProbability: 0.20,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            trickDeltaToBidBeforeMove: 0,
            chasePressure: params.chasePressure,
            matchContext: withoutOpponentModel
        )
        let noEvidence = service.moveUtility(
            projectedScore: 40,
            immediateWinProbability: 0.20,
            threat: params.threat,
            move: move,
            trickNode: params.trickNode,
            trump: params.trump,
            shouldChaseTrick: params.shouldChaseTrick,
            hasWinningNonJoker: params.hasWinningNonJoker,
            hasLosingNonJoker: params.hasLosingNonJoker,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 2,
            trickDeltaToBidBeforeMove: 0,
            chasePressure: params.chasePressure,
            matchContext: noEvidenceOpponentModel
        )

        XCTAssertEqual(noEvidence, baseline, accuracy: 0.0001)
    }
}
