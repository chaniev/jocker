//
//  BotTurnCandidateRankingServiceTests_JokerDeclaration.swift
//  JockerTests
//
//  Created by Codex on 04.03.2026.
//

import XCTest
@testable import Jocker

extension BotTurnCandidateRankingServiceTests {
    func testMoveUtility_whenChasingPenalizesSpendingJokerIfWinningNonJokerExists() {
        let trickNode = makeTrickNode()
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
        let trickNode = makeTrickNode()
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

    func testMoveUtility_whenLeadJokerChasingEarly_prefersAboveDeclaringTrumpOverNonTrump() {
        let trickNode = makeTrickNode()
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
        let trickNode = makeTrickNode()
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
        let trickNode = makeTrickNode()
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
        let trickNode = makeTrickNode()
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

    func testMoveUtility_whenLeadJokerDumpingOverbidWithoutLosingNonJoker_increasesTakesNonTrumpUtility() {
        let trickNode = makeTrickNode()
        let takesNonTrump = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .takes(suit: .hearts))
        )

        let exactUtility = service.moveUtility(
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
            trickDeltaToBidBeforeMove: 0,
            chasePressure: 0.0
        )
        let overbidNoSafeDumpUtility = service.moveUtility(
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
            trickDeltaToBidBeforeMove: 1,
            chasePressure: 0.0
        )
        let exactWithSafeDumpUtility = service.moveUtility(
            projectedScore: 15,
            immediateWinProbability: 0.85,
            threat: 45,
            move: takesNonTrump,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: true,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 4,
            trickDeltaToBidBeforeMove: 0,
            chasePressure: 0.0
        )
        let overbidWithSafeDumpUtility = service.moveUtility(
            projectedScore: 15,
            immediateWinProbability: 0.85,
            threat: 45,
            move: takesNonTrump,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: true,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 4,
            trickDeltaToBidBeforeMove: 1,
            chasePressure: 0.0
        )

        let noSafeDumpOverbidBoost = overbidNoSafeDumpUtility - exactUtility
        let safeDumpOverbidBoost = overbidWithSafeDumpUtility - exactWithSafeDumpUtility
        XCTAssertGreaterThan(noSafeDumpOverbidBoost, safeDumpOverbidBoost)
        XCTAssertGreaterThan(overbidNoSafeDumpUtility, exactUtility)
    }

    func testMoveUtility_whenLeadJokerChasingEarly_prefersAboveTrumpOverTakesTrump() {
        let trickNode = makeTrickNode()
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
        let trickNode = makeTrickNode()
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
        let trickNode = makeTrickNode()
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

    func testMoveUtility_whenLeadJokerChasingHighPressureNonAllIn_lowControlReserveAmplifiesAboveTrumpAdvantageOverWish() {
        let trickNode = makeTrickNode()
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
            tricksNeededToMatchBid: 3,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.75,
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
            tricksNeededToMatchBid: 3,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.75,
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
            tricksNeededToMatchBid: 3,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.75,
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
            tricksNeededToMatchBid: 3,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.75,
            leadControlReserveAfterMove: 1.0
        )

        let lowReserveAdvantage = aboveLowReserve - wishLowReserve
        let highReserveAdvantage = aboveHighReserve - wishHighReserve
        XCTAssertGreaterThan(lowReserveAdvantage, highReserveAdvantage)
    }

    func testMoveUtility_whenLeadJokerDumpingAndOwnPremiumCandidate_increasesTakesNonTrumpAdvantageOverWish() {
        let trickNode = makeTrickNode()
        let wish = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .wish)
        )
        let takesNonTrump = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .takes(suit: .hearts))
        )
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
                isZeroPremiumCandidateSoFar: false
            )
        )
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
                isZeroPremiumCandidateSoFar: false
            )
        )

        let wishNeutral = service.moveUtility(
            projectedScore: 15,
            immediateWinProbability: 0.85,
            threat: 110,
            move: wish,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.0,
            matchContext: neutralContext
        )
        let takesNeutral = service.moveUtility(
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
            chasePressure: 0.0,
            matchContext: neutralContext
        )
        let wishOwnPremium = service.moveUtility(
            projectedScore: 15,
            immediateWinProbability: 0.85,
            threat: 110,
            move: wish,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.0,
            matchContext: ownPremiumContext
        )
        let takesOwnPremium = service.moveUtility(
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
            chasePressure: 0.0,
            matchContext: ownPremiumContext
        )

        let neutralAdvantage = takesNeutral - wishNeutral
        let ownPremiumAdvantage = takesOwnPremium - wishOwnPremium
        XCTAssertGreaterThan(ownPremiumAdvantage, neutralAdvantage)
    }

    func testMoveUtility_whenLeadJokerChasingWithAntiPremiumPressure_increasesAboveTrumpAdvantageOverWish() {
        let trickNode = makeTrickNode()
        let wish = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .wish)
        )
        let aboveTrump = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .above(suit: .spades))
        )
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
                opponentPremiumCandidatesSoFarCount: 1
            )
        )

        let wishNeutral = service.moveUtility(
            projectedScore: 30,
            immediateWinProbability: 0.95,
            threat: 110,
            move: wish,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 1,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.25,
            matchContext: neutralContext
        )
        let aboveNeutral = service.moveUtility(
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
            chasePressure: 0.25,
            matchContext: neutralContext
        )
        let wishAntiPremium = service.moveUtility(
            projectedScore: 30,
            immediateWinProbability: 0.95,
            threat: 110,
            move: wish,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 1,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.25,
            matchContext: antiPremiumContext
        )
        let aboveAntiPremium = service.moveUtility(
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
            chasePressure: 0.25,
            matchContext: antiPremiumContext
        )

        let neutralAdvantage = aboveNeutral - wishNeutral
        let antiPremiumAdvantage = aboveAntiPremium - wishAntiPremium
        XCTAssertGreaterThan(antiPremiumAdvantage, neutralAdvantage)
    }

    func testMoveUtility_whenLeadJokerAllInChaseWithAntiPremiumPressure_penalizesWishAndBoostsAboveTrump() {
        let trickNode = makeTrickNode()
        let wish = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .wish)
        )
        let aboveTrump = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .above(suit: .spades))
        )
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
                isPenaltyTargetRiskSoFar: true,
                premiumCandidatesThreateningPenaltyCount: 1,
                opponentPremiumCandidatesSoFarCount: 2
            )
        )

        let wishNeutral = service.moveUtility(
            projectedScore: 32,
            immediateWinProbability: 0.96,
            threat: 115,
            move: wish,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 4,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 1.0,
            matchContext: neutralContext
        )
        let aboveNeutral = service.moveUtility(
            projectedScore: 32,
            immediateWinProbability: 0.96,
            threat: 96,
            move: aboveTrump,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 4,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 1.0,
            matchContext: neutralContext
        )
        let wishAntiPremium = service.moveUtility(
            projectedScore: 32,
            immediateWinProbability: 0.96,
            threat: 115,
            move: wish,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 4,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 1.0,
            matchContext: antiPremiumContext
        )
        let aboveAntiPremium = service.moveUtility(
            projectedScore: 32,
            immediateWinProbability: 0.96,
            threat: 96,
            move: aboveTrump,
            trickNode: trickNode,
            trump: .spades,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 4,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 1.0,
            matchContext: antiPremiumContext
        )

        XCTAssertLessThan(wishAntiPremium, wishNeutral)
        XCTAssertGreaterThan(aboveAntiPremium, aboveNeutral)
        XCTAssertGreaterThan(aboveAntiPremium - wishAntiPremium, aboveNeutral - wishNeutral)
    }

    func testMoveUtility_whenLeadJokerAllInChaseAndDisciplinedObservedLeftNeighbor_strengthensAntiPremiumShift() {
        let trickNode = makeTrickNode()
        let wish = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .wish)
        )
        let aboveTrump = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .above(suit: .spades))
        )
        let premium = BotMatchContext.PremiumSnapshot(
            completedRoundsInBlock: 7,
            remainingRoundsInBlock: 1,
            isPremiumCandidateSoFar: false,
            isZeroPremiumRelevantInBlock: false,
            isZeroPremiumCandidateSoFar: false,
            leftNeighborIndex: 1,
            leftNeighborIsPremiumCandidateSoFar: true,
            isPenaltyTargetRiskSoFar: true,
            premiumCandidatesThreateningPenaltyCount: 1,
            opponentPremiumCandidatesSoFarCount: 2
        )
        let disciplinedContext = BotMatchContext(
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

        func utility(_ move: BotTurnCandidateRankingService.Move, context: BotMatchContext) -> Double {
            service.moveUtility(
                projectedScore: 32,
                immediateWinProbability: 0.96,
                threat: move.decision.leadDeclaration == .wish ? 115 : 96,
                move: move,
                trickNode: trickNode,
                trump: .spades,
                shouldChaseTrick: true,
                hasWinningNonJoker: false,
                hasLosingNonJoker: false,
                tricksNeededToMatchBid: 4,
                tricksRemainingIncludingCurrent: 4,
                chasePressure: 1.0,
                matchContext: context
            )
        }

        let wishDisciplined = utility(wish, context: disciplinedContext)
        let aboveDisciplined = utility(aboveTrump, context: disciplinedContext)
        let wishErratic = utility(wish, context: erraticContext)
        let aboveErratic = utility(aboveTrump, context: erraticContext)

        XCTAssertLessThan(wishDisciplined, wishErratic)
        XCTAssertGreaterThan(aboveDisciplined, aboveErratic)
        XCTAssertGreaterThan(aboveDisciplined - wishDisciplined, aboveErratic - wishErratic)
    }

    func testMoveUtility_whenLeadJokerAntiPremiumContext_andOpponentModelHasNoEvidence_keepsShiftUnchanged() {
        let trickNode = makeTrickNode()
        let wish = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .wish)
        )
        let aboveTrump = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .above(suit: .spades))
        )
        let premium = BotMatchContext.PremiumSnapshot(
            completedRoundsInBlock: 7,
            remainingRoundsInBlock: 1,
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

        func utility(_ move: BotTurnCandidateRankingService.Move, context: BotMatchContext) -> Double {
            service.moveUtility(
                projectedScore: 32,
                immediateWinProbability: 0.96,
                threat: move.decision.leadDeclaration == .wish ? 115 : 96,
                move: move,
                trickNode: trickNode,
                trump: .spades,
                shouldChaseTrick: true,
                hasWinningNonJoker: false,
                hasLosingNonJoker: false,
                tricksNeededToMatchBid: 4,
                tricksRemainingIncludingCurrent: 4,
                chasePressure: 1.0,
                matchContext: context
            )
        }

        let wishWithoutOpponents = utility(wish, context: withoutOpponents)
        let aboveWithoutOpponents = utility(aboveTrump, context: withoutOpponents)
        let wishNoEvidence = utility(wish, context: noEvidenceOpponents)
        let aboveNoEvidence = utility(aboveTrump, context: noEvidenceOpponents)

        XCTAssertEqual(wishNoEvidence, wishWithoutOpponents, accuracy: 0.0001)
        XCTAssertEqual(aboveNoEvidence, aboveWithoutOpponents, accuracy: 0.0001)
    }

    func testMoveUtility_whenLeadJokerDumpingAntiPremiumContext_andDisciplinedObservedLeftNeighbor_increasesTakesUtility() {
        let trickNode = makeTrickNode()
        let takesNonTrump = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .takes(suit: .hearts))
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
        let disciplinedContext = BotMatchContext(
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
            chasePressure: 0.0,
            matchContext: disciplinedContext
        )
        let erraticUtility = service.moveUtility(
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
            chasePressure: 0.0,
            matchContext: erraticContext
        )

        XCTAssertGreaterThan(disciplinedUtility, erraticUtility)
    }

    func testMoveUtility_whenLeadJokerDumpingAntiPremiumContext_andOpponentModelHasNoEvidence_keepsTakesUtilityUnchanged() {
        let trickNode = makeTrickNode()
        let takesNonTrump = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .takes(suit: .hearts))
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

        let withoutOpponentsUtility = service.moveUtility(
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
            chasePressure: 0.0,
            matchContext: withoutOpponents
        )
        let noEvidenceUtility = service.moveUtility(
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
            chasePressure: 0.0,
            matchContext: noEvidenceOpponents
        )

        XCTAssertEqual(noEvidenceUtility, withoutOpponentsUtility, accuracy: 0.0001)
    }

    func testMoveUtility_whenLeadJokerChasing_preferredControlSuitBoostsMatchingAboveDeclaration() {
        let trickNode = makeTrickNode()
        let abovePreferred = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .above(suit: .spades))
        )
        let aboveOther = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .above(suit: .hearts))
        )

        let preferredUtility = service.moveUtility(
            projectedScore: 30,
            immediateWinProbability: 0.95,
            threat: 95,
            move: abovePreferred,
            trickNode: trickNode,
            trump: .clubs,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 1,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.25,
            leadPreferredControlSuitAfterMove: .spades,
            leadPreferredControlSuitStrengthAfterMove: 1.0
        )
        let otherUtility = service.moveUtility(
            projectedScore: 30,
            immediateWinProbability: 0.95,
            threat: 95,
            move: aboveOther,
            trickNode: trickNode,
            trump: .clubs,
            shouldChaseTrick: true,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 1,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.25,
            leadPreferredControlSuitAfterMove: .spades,
            leadPreferredControlSuitStrengthAfterMove: 1.0
        )

        XCTAssertGreaterThan(preferredUtility, otherUtility)
    }

    func testMoveUtility_whenLeadJokerDumping_preferredControlSuitPenalizesMatchingTakesDeclaration() {
        let trickNode = makeTrickNode()
        let takesPreferred = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .takes(suit: .spades))
        )
        let takesOther = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .takes(suit: .hearts))
        )

        let preferredUtility = service.moveUtility(
            projectedScore: 15,
            immediateWinProbability: 0.85,
            threat: 45,
            move: takesPreferred,
            trickNode: trickNode,
            trump: .clubs,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.0,
            leadPreferredControlSuitAfterMove: .spades,
            leadPreferredControlSuitStrengthAfterMove: 1.0
        )
        let otherUtility = service.moveUtility(
            projectedScore: 15,
            immediateWinProbability: 0.85,
            threat: 45,
            move: takesOther,
            trickNode: trickNode,
            trump: .clubs,
            shouldChaseTrick: false,
            hasWinningNonJoker: false,
            hasLosingNonJoker: false,
            tricksNeededToMatchBid: 0,
            tricksRemainingIncludingCurrent: 4,
            chasePressure: 0.0,
            leadPreferredControlSuitAfterMove: .spades,
            leadPreferredControlSuitStrengthAfterMove: 1.0
        )

        XCTAssertLessThan(preferredUtility, otherUtility)
    }

    func testMoveUtility_whenLeadJokerDumpingPenaltyRisk_goalOrientedLayerStrengthensControlledLossTakesOverWish() {
        let trickNode = makeTrickNode()
        let wish = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .wish)
        )
        let takesNonTrump = BotTurnCandidateRankingService.Move(
            card: .joker,
            decision: JokerPlayDecision(style: .faceUp, leadDeclaration: .takes(suit: .hearts))
        )
        let penaltyRiskContext = makeContext(
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
                isPenaltyTargetRiskSoFar: true,
                premiumCandidatesThreateningPenaltyCount: 1,
                opponentPremiumCandidatesSoFarCount: 2
            )
        )

        func utility(for move: BotTurnCandidateRankingService.Move, context: BotMatchContext?) -> Double {
            service.moveUtility(
                projectedScore: 12,
                immediateWinProbability: move.decision.leadDeclaration == .wish ? 0.86 : 0.80,
                threat: 42,
                move: move,
                trickNode: trickNode,
                trump: .spades,
                shouldChaseTrick: false,
                hasWinningNonJoker: false,
                hasLosingNonJoker: false,
                tricksNeededToMatchBid: 0,
                tricksRemainingIncludingCurrent: 3,
                trickDeltaToBidBeforeMove: 1,
                chasePressure: 0.0,
                leadControlReserveAfterMove: 0.15,
                leadPreferredControlSuitAfterMove: .spades,
                leadPreferredControlSuitStrengthAfterMove: 0.9,
                matchContext: context
            )
        }

        let wishNeutral = utility(for: wish, context: nil)
        let takesNeutral = utility(for: takesNonTrump, context: nil)
        let wishPenaltyRisk = utility(for: wish, context: penaltyRiskContext)
        let takesPenaltyRisk = utility(for: takesNonTrump, context: penaltyRiskContext)

        XCTAssertGreaterThan(takesPenaltyRisk, wishPenaltyRisk)
        XCTAssertGreaterThan(
            takesPenaltyRisk - wishPenaltyRisk,
            takesNeutral - wishNeutral
        )
    }
}
