//
//  BotTurnCandidateRankingServiceTests.swift
//  JockerTests
//
//  Created by Codex on 22.02.2026.
//

import XCTest
@testable import Jocker

final class BotTurnCandidateRankingServiceTests: XCTestCase {
    private let service = BotTurnCandidateRankingService(tuning: BotTuning(difficulty: .hard))

    func testIsBetterCandidate_prefersHigherUtilityBeyondTolerance() {
        let current = evaluation(card: card(.hearts, .queen), utility: 10, immediateWinProbability: 0.5, threat: 5)
        let candidate = evaluation(card: card(.hearts, .king), utility: 25, immediateWinProbability: 0.1, threat: 20)

        XCTAssertTrue(service.isBetterCandidate(candidate, than: current, shouldChaseTrick: true))
        XCTAssertFalse(service.isBetterCandidate(current, than: candidate, shouldChaseTrick: true))
    }

    func testIsBetterCandidate_whenChasingUsesProbabilityThenThreatTieBreak() {
        let utility = 10.0
        let base = evaluation(card: card(.hearts, .queen), utility: utility, immediateWinProbability: 0.4, threat: 8)
        let betterWinChance = evaluation(card: card(.hearts, .king), utility: utility, immediateWinProbability: 0.8, threat: 20)
        let lowerThreat = evaluation(card: card(.spades, .ten), utility: utility, immediateWinProbability: 0.4, threat: 2)

        XCTAssertTrue(service.isBetterCandidate(betterWinChance, than: base, shouldChaseTrick: true))
        XCTAssertTrue(service.isBetterCandidate(lowerThreat, than: base, shouldChaseTrick: true))
    }

    func testIsBetterCandidate_whenDumpingUsesLowerWinChanceThenHigherThreatTieBreak() {
        let utility = 10.0
        let base = evaluation(card: card(.hearts, .queen), utility: utility, immediateWinProbability: 0.6, threat: 4)
        let betterDumpChance = evaluation(card: card(.hearts, .king), utility: utility, immediateWinProbability: 0.1, threat: 1)
        let higherThreat = evaluation(card: card(.spades, .ten), utility: utility, immediateWinProbability: 0.6, threat: 12)

        XCTAssertTrue(service.isBetterCandidate(betterDumpChance, than: base, shouldChaseTrick: false))
        XCTAssertTrue(service.isBetterCandidate(higherThreat, than: base, shouldChaseTrick: false))
    }

    func testIsBetterCandidate_whenFullyEqualUsesDeterministicCardThenDecisionTieBreak() {
        let cardA = card(.clubs, .ten)
        let cardB = card(.spades, .ten)
        let lower = cardA < cardB ? cardA : cardB
        let higher = cardA < cardB ? cardB : cardA

        let baseMetrics = (utility: 7.0, immediateWinProbability: 0.5, threat: 3.0)
        let lowerCardEval = evaluation(
            card: lower,
            decision: .defaultNonLead,
            utility: baseMetrics.utility,
            immediateWinProbability: baseMetrics.immediateWinProbability,
            threat: baseMetrics.threat
        )
        let higherCardEval = evaluation(
            card: higher,
            decision: .defaultNonLead,
            utility: baseMetrics.utility,
            immediateWinProbability: baseMetrics.immediateWinProbability,
            threat: baseMetrics.threat
        )

        XCTAssertTrue(service.isBetterCandidate(lowerCardEval, than: higherCardEval, shouldChaseTrick: true))

        let faceDown = evaluation(
            card: .joker,
            decision: JokerPlayDecision(style: .faceDown, leadDeclaration: nil),
            utility: baseMetrics.utility,
            immediateWinProbability: baseMetrics.immediateWinProbability,
            threat: baseMetrics.threat
        )
        let faceUp = evaluation(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: nil),
            utility: baseMetrics.utility,
            immediateWinProbability: baseMetrics.immediateWinProbability,
            threat: baseMetrics.threat
        )

        XCTAssertTrue(service.isBetterCandidate(faceDown, than: faceUp, shouldChaseTrick: false))
    }

    func testMoveUtility_whenChasingPenalizesSpendingJokerIfWinningNonJokerExists() {
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.hearts, .queen), fromPlayer: 1, animated: false)

        let commonParams = commonUtilityParams(
            trickNode: trickNode,
            trump: .clubs,
            shouldChaseTrick: true,
            hasWinningNonJoker: true,
            hasLosingNonJoker: false
        )

        let jokerUtility = service.moveUtility(
            projectedScore: commonParams.projectedScore,
            immediateWinProbability: commonParams.immediateWinProbability,
            threat: commonParams.threat,
            move: .init(card: .joker, decision: JokerPlayDecision(style: .faceUp, leadDeclaration: nil)),
            trickNode: commonParams.trickNode,
            trump: commonParams.trump,
            shouldChaseTrick: commonParams.shouldChaseTrick,
            hasWinningNonJoker: commonParams.hasWinningNonJoker,
            hasLosingNonJoker: commonParams.hasLosingNonJoker,
            tricksNeededToMatchBid: commonParams.tricksNeededToMatchBid,
            tricksRemainingIncludingCurrent: commonParams.tricksRemainingIncludingCurrent,
            chasePressure: commonParams.chasePressure
        )
        let nonJokerUtility = service.moveUtility(
            projectedScore: commonParams.projectedScore,
            immediateWinProbability: commonParams.immediateWinProbability,
            threat: commonParams.threat,
            move: .init(card: card(.hearts, .king), decision: .defaultNonLead),
            trickNode: commonParams.trickNode,
            trump: commonParams.trump,
            shouldChaseTrick: commonParams.shouldChaseTrick,
            hasWinningNonJoker: commonParams.hasWinningNonJoker,
            hasLosingNonJoker: commonParams.hasLosingNonJoker,
            tricksNeededToMatchBid: commonParams.tricksNeededToMatchBid,
            tricksRemainingIncludingCurrent: commonParams.tricksRemainingIncludingCurrent,
            chasePressure: commonParams.chasePressure
        )

        XCTAssertLessThan(jokerUtility, nonJokerUtility)
    }

    func testMoveUtility_whenDumpingPenalizesNonLeadFaceUpJokerComparedToFaceDown() {
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.clubs, .ace), fromPlayer: 1, animated: false)

        let commonParams = commonUtilityParams(
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false
        )

        let faceDown = service.moveUtility(
            projectedScore: commonParams.projectedScore,
            immediateWinProbability: commonParams.immediateWinProbability,
            threat: commonParams.threat,
            move: .init(card: .joker, decision: JokerPlayDecision(style: .faceDown, leadDeclaration: nil)),
            trickNode: commonParams.trickNode,
            trump: commonParams.trump,
            shouldChaseTrick: commonParams.shouldChaseTrick,
            hasWinningNonJoker: commonParams.hasWinningNonJoker,
            hasLosingNonJoker: commonParams.hasLosingNonJoker,
            tricksNeededToMatchBid: commonParams.tricksNeededToMatchBid,
            tricksRemainingIncludingCurrent: commonParams.tricksRemainingIncludingCurrent,
            chasePressure: commonParams.chasePressure
        )
        let faceUp = service.moveUtility(
            projectedScore: commonParams.projectedScore,
            immediateWinProbability: commonParams.immediateWinProbability,
            threat: commonParams.threat,
            move: .init(card: .joker, decision: JokerPlayDecision(style: .faceUp, leadDeclaration: nil)),
            trickNode: commonParams.trickNode,
            trump: commonParams.trump,
            shouldChaseTrick: commonParams.shouldChaseTrick,
            hasWinningNonJoker: commonParams.hasWinningNonJoker,
            hasLosingNonJoker: commonParams.hasLosingNonJoker,
            tricksNeededToMatchBid: commonParams.tricksNeededToMatchBid,
            tricksRemainingIncludingCurrent: commonParams.tricksRemainingIncludingCurrent,
            chasePressure: commonParams.chasePressure
        )

        XCTAssertGreaterThan(faceDown, faceUp)
    }

    func testMoveUtility_whenBlindChasing_canFlipChoiceTowardHigherWinChance() {
        let trickNode = TrickNode()
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

    func testMoveUtility_whenLeadJokerChasingEarly_prefersAboveDeclaringTrumpOverNonTrump() {
        let trickNode = TrickNode()
        let aboveTrump = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .above(suit: .spades))
        )
        let aboveNonTrump = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .above(suit: .hearts))
        )

        let trumpUtility = service.moveUtility(
            projectedScore: 30,
            immediateWinProbability: 0.95,
            threat: 100,
            move: aboveTrump,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 1,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.25
        )
        let nonTrumpUtility = service.moveUtility(
            projectedScore: 30,
            immediateWinProbability: 0.95,
            threat: 100,
            move: aboveNonTrump,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 1,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.25
        )

        XCTAssertGreaterThan(trumpUtility, nonTrumpUtility)
    }

    func testMoveUtility_whenLeadJokerDumpingEarly_penalizesAboveDeclaringTrumpMoreThanNonTrump() {
        let trickNode = TrickNode()
        let aboveTrump = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .above(suit: .spades))
        )
        let aboveNonTrump = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .above(suit: .hearts))
        )

        let trumpUtility = service.moveUtility(
            projectedScore: 15,
            immediateWinProbability: 0.90,
            threat: 100,
            move: aboveTrump,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.0
        )
        let nonTrumpUtility = service.moveUtility(
            projectedScore: 15,
            immediateWinProbability: 0.90,
            threat: 100,
            move: aboveNonTrump,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.0
        )

        XCTAssertLessThan(trumpUtility, nonTrumpUtility)
    }

    func testMoveUtility_whenLeadJokerChasingFinalAllIn_preservesWishOverAbove() {
        let trickNode = TrickNode()
        let wish = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .wish)
        )
        let aboveTrump = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .above(suit: .spades))
        )

        let wishUtility = service.moveUtility(
            projectedScore: 100,
            immediateWinProbability: 1.0,
            threat: 100,
            move: wish,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 1,
            tricksRemainingIncludingCurrent: 1,
            chasePressure: 1.0
        )
        let aboveUtility = service.moveUtility(
            projectedScore: 100,
            immediateWinProbability: 1.0,
            threat: 100,
            move: aboveTrump,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 1,
            tricksRemainingIncludingCurrent: 1,
            chasePressure: 1.0
        )

        XCTAssertGreaterThan(wishUtility, aboveUtility)
    }

    func testMoveUtility_whenLeadJokerDumpingEarly_prefersTakesNonTrumpOverTakesTrump() {
        let trickNode = TrickNode()
        let takesNonTrump = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .takes(suit: .hearts))
        )
        let takesTrump = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .takes(suit: .spades))
        )

        let nonTrumpUtility = service.moveUtility(
            projectedScore: 15,
            immediateWinProbability: 0.85,
            threat: 45,
            move: takesNonTrump,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.0
        )
        let trumpUtility = service.moveUtility(
            projectedScore: 15,
            immediateWinProbability: 0.85,
            threat: 45,
            move: takesTrump,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.0
        )

        XCTAssertGreaterThan(nonTrumpUtility, trumpUtility)
    }

    func testMoveUtility_whenLeadJokerChasingEarly_prefersAboveTrumpOverTakesTrump() {
        let trickNode = TrickNode()
        let aboveTrump = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .above(suit: .spades))
        )
        let takesTrump = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .takes(suit: .spades))
        )

        let aboveUtility = service.moveUtility(
            projectedScore: 30,
            immediateWinProbability: 0.95,
            threat: 95,
            move: aboveTrump,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 1,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.25
        )
        let takesUtility = service.moveUtility(
            projectedScore: 30,
            immediateWinProbability: 0.85,
            threat: 45,
            move: takesTrump,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 1,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.25
        )

        XCTAssertGreaterThan(aboveUtility, takesUtility)
    }

    func testMoveUtility_whenLeadJokerChasingEarly_lowControlReservePenalizesWishMore() {
        let trickNode = TrickNode()
        let wish = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .wish)
        )

        let lowReserveWish = service.moveUtility(
            projectedScore: 30,
            immediateWinProbability: 0.95,
            threat: 100,
            move: wish,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 1,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.25,
            leadControlReserveAfterMove: 0.0
        )
        let highReserveWish = service.moveUtility(
            projectedScore: 30,
            immediateWinProbability: 0.95,
            threat: 100,
            move: wish,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 1,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.25,
            leadControlReserveAfterMove: 1.0
        )

        XCTAssertLessThan(lowReserveWish, highReserveWish)
    }

    func testMoveUtility_whenLeadJokerChasingEarly_lowControlReserveIncreasesAboveTrumpAdvantageOverWish() {
        let trickNode = TrickNode()
        let wish = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .wish)
        )
        let aboveTrump = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .above(suit: .spades))
        )

        let wishLowReserve = service.moveUtility(
            projectedScore: 30,
            immediateWinProbability: 0.95,
            threat: 100,
            move: wish,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 1,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.25,
            leadControlReserveAfterMove: 0.0
        )
        let aboveLowReserve = service.moveUtility(
            projectedScore: 30,
            immediateWinProbability: 0.95,
            threat: 100,
            move: aboveTrump,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 1,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.25,
            leadControlReserveAfterMove: 0.0
        )
        let wishHighReserve = service.moveUtility(
            projectedScore: 30,
            immediateWinProbability: 0.95,
            threat: 100,
            move: wish,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 1,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.25,
            leadControlReserveAfterMove: 1.0
        )
        let aboveHighReserve = service.moveUtility(
            projectedScore: 30,
            immediateWinProbability: 0.95,
            threat: 100,
            move: aboveTrump,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 1,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.25,
            leadControlReserveAfterMove: 1.0
        )

        let lowReserveAdvantage = aboveLowReserve - wishLowReserve
        let highReserveAdvantage = aboveHighReserve - wishHighReserve
        XCTAssertGreaterThan(lowReserveAdvantage, highReserveAdvantage)
    }

    func testMoveUtility_withNeutralMatchContext_preservesBehavior() {
        let trickNode = TrickNode()
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

        let baseline = service.moveUtility(
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
            isBlindRound: true
        )
        let withMatchContext = service.moveUtility(
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

        XCTAssertEqual(withMatchContext, baseline, accuracy: 0.0001)
    }

    func testMoveUtility_withLateBlockScoreDeficit_increasesChaseRiskUtility() {
        let trickNode = TrickNode()
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

    func testMoveUtility_matchCatchUpBias_isNearZeroAtEarlyBlockStart() {
        let trickNode = TrickNode()
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

    func testMoveUtility_whenPremiumCandidateAndLateBlock_dumpingGetsExtraAvoidWinReward() {
        let trickNode = TrickNode()
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
        let trickNode = TrickNode()
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
        let trickNode = TrickNode()
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

    func testMoveUtility_premiumPreserveExactBidProtection_isStrongerThanAfterOverbidBreak() {
        let trickNode = TrickNode()
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
        let trickNode = TrickNode()
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
        let trickNode = TrickNode()
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

    func testMoveUtility_whenLeftNeighborPremiumCandidate_dumpingBecomesLessAttractive() {
        let trickNode = TrickNode()
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
        let trickNode = TrickNode()
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
        let trickNode = TrickNode()
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
        let trickNode = TrickNode()
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

    private func evaluation(
        card: Card,
        decision: JokerPlayDecision = .defaultNonLead,
        utility: Double,
        immediateWinProbability: Double,
        threat: Double
    ) -> BotTurnCandidateRankingService.Evaluation {
        return .init(
            move: .init(card: card, decision: decision),
            utility: utility,
            immediateWinProbability: immediateWinProbability,
            threat: threat
        )
    }

    private func commonUtilityParams(
        trickNode: TrickNode,
        trump: Suit?,
        shouldChaseTrick: Bool,
        hasWinningNonJoker: Bool,
        hasLosingNonJoker: Bool
    ) -> (
        projectedScore: Double,
        immediateWinProbability: Double,
        threat: Double,
        trickNode: TrickNode,
        trump: Suit?,
        shouldChaseTrick: Bool,
        hasWinningNonJoker: Bool,
        hasLosingNonJoker: Bool,
        tricksNeededToMatchBid: Int,
        tricksRemainingIncludingCurrent: Int,
        chasePressure: Double
    ) {
        return (
            projectedScore: 10,
            immediateWinProbability: shouldChaseTrick ? 0.85 : 0.15,
            threat: 5,
            trickNode: trickNode,
            trump: trump,
            shouldChaseTrick: shouldChaseTrick,
            hasWinningNonJoker: hasWinningNonJoker,
            hasLosingNonJoker: hasLosingNonJoker,
            tricksNeededToMatchBid: 1,
            tricksRemainingIncludingCurrent: 2,
            chasePressure: shouldChaseTrick ? 0.5 : 0.0
        )
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
            playerIndex: 0,
            dealerIndex: 2,
            playerCount: 4,
            premium: nil
        )
    }
}
