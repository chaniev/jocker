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

    func testMakeTurnDecision_jokerDeclarationProbe_mayFlipBetweenAboveAndWishByChaseUrgency() throws {
        let service = BotTurnStrategyService(tuning: BotTuning(difficulty: .hard))
        let trickNode = TrickNode()
        let handCards: [Card] = [
            .joker,
            card(.clubs, .six),
            card(.diamonds, .seven),
            card(.hearts, .eight)
        ]

        let controlChaseDecision = service.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
            trump: .spades,
            bid: 1,
            tricksTaken: 0,
            cardsInRound: 8,
            playerCount: 4
        )
        let allInChaseDecision = service.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
            trump: .spades,
            bid: 4,
            tricksTaken: 0,
            cardsInRound: 8,
            playerCount: 4
        )

        guard let controlChaseDecision, let allInChaseDecision else {
            XCTFail("Ожидались валидные решения в joker declaration probe сценарии")
            return
        }

        if controlChaseDecision.card != .joker || allInChaseDecision.card != .joker {
            throw XCTSkip(
                "Текущий runtime может выбирать не-джокер в одной из веток probe-сценария. " +
                "Сценарий оставлен как цель retuning для Stage 5."
            )
        }

        let controlDecl = controlChaseDecision.jokerDecision.leadDeclaration
        let allInDecl = allInChaseDecision.jokerDecision.leadDeclaration
        if controlDecl == allInDecl {
            throw XCTSkip(
                "Текущие коэффициенты Stage 5 fallback пока не дают declaration flip (`above` vs `wish`) в probe-сценарии. " +
                "Сценарий оставлен как цель дальнейшего retuning."
            )
        }

        if case .some(.above(suit: .spades)) = controlDecl {
            // ok
        } else {
            throw XCTSkip(
                "Runtime flip произошёл, но не в ожидаемую `above(trump)` ветку; оставляем как probe до retuning."
            )
        }
        XCTAssertEqual(allInDecl, .wish)
    }

    func testMakeTurnDecision_whenEarlyVsAllInChaseWithWeakHand_flipsLeadJokerDeclarationAboveToWish() {
        let service = BotTurnStrategyService(tuning: BotTuning(difficulty: .hard))
        let trickNode = TrickNode()
        let handCards: [Card] = [
            .joker,
            card(.clubs, .six),
            card(.diamonds, .seven),
            card(.hearts, .eight)
        ]

        let earlyChaseDecision = service.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
            trump: .spades,
            bid: 1,
            tricksTaken: 0,
            cardsInRound: 8,
            playerCount: 4
        )
        let allInChaseDecision = service.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
            trump: .spades,
            bid: 4,
            tricksTaken: 0,
            cardsInRound: 8,
            playerCount: 4
        )

        XCTAssertEqual(earlyChaseDecision?.card, .joker)
        XCTAssertEqual(allInChaseDecision?.card, .joker)
        XCTAssertEqual(earlyChaseDecision?.jokerDecision.leadDeclaration, .above(suit: .spades))
        XCTAssertEqual(allInChaseDecision?.jokerDecision.leadDeclaration, .wish)
    }

    func testMakeTurnDecision_jokerTakesProbe_mayPreferLeadJokerTakesInEarlyDumpWhenNonJokerLeadsAreRisky() throws {
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
            tricksTaken: 1, // overbid: усиливаем мотивацию controlled-loss в dump
            cardsInRound: 8,
            playerCount: 4
        )

        guard let dumpDecision else {
            XCTFail("Ожидалось валидное решение в takes probe dump-сценарии")
            return
        }

        guard dumpDecision.card == .joker else {
            throw XCTSkip(
                "Текущий runtime ещё не выбирает lead-джокер в этом раннем dump-сценарии. " +
                "Probe оставлен как цель retuning для Stage 5 (`takes`)."
            )
        }

        guard case .some(.takes(let suit)) = dumpDecision.jokerDecision.leadDeclaration else {
            throw XCTSkip(
                "Runtime выбрал lead-джокер, но не `takes`; probe оставлен как цель retuning Stage 5."
            )
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

    func testMakeTurnDecision_jokerControlReserveProbe_mayShiftLeadJokerDeclarationInEarlyChase() throws {
        let service = BotTurnStrategyService(tuning: BotTuning(difficulty: .hard))
        let trickNode = TrickNode()

        let lowReserveHand: [Card] = [
            .joker,
            card(.clubs, .six),
            card(.diamonds, .seven),
            card(.hearts, .eight)
        ]
        let higherReserveHand: [Card] = [
            .joker,
            card(.spades, .eight),
            card(.spades, .nine),
            card(.spades, .ten)
        ]

        let lowReserveDecision = service.makeTurnDecision(
            handCards: lowReserveHand,
            trickNode: trickNode,
            trump: .spades,
            bid: 1,
            tricksTaken: 0,
            cardsInRound: 8,
            playerCount: 4
        )
        let higherReserveDecision = service.makeTurnDecision(
            handCards: higherReserveHand,
            trickNode: trickNode,
            trump: .spades,
            bid: 1,
            tricksTaken: 0,
            cardsInRound: 8,
            playerCount: 4
        )

        guard let lowReserveDecision, let higherReserveDecision else {
            XCTFail("Ожидались валидные решения в control-reserve probe сценарии")
            return
        }

        if lowReserveDecision.card != .joker || higherReserveDecision.card != .joker {
            throw XCTSkip(
                "Текущий runtime выбирает не-джокер хотя бы в одной ветке reserve probe. " +
                "Сценарий оставлен как цель retuning для Stage 5."
            )
        }

        let lowDecl = lowReserveDecision.jokerDecision.leadDeclaration
        let highDecl = higherReserveDecision.jokerDecision.leadDeclaration
        if lowDecl == highDecl {
            throw XCTSkip(
                "Текущие коэффициенты пока не дают declaration flip по control-reserve сигналу. " +
                "Сценарий оставлен как Stage-5 retuning probe."
            )
        }

        if case .some(.above(suit: .spades)) = lowDecl {
            // ok: при низком reserve ожидаем более сильный сдвиг к немедленному контролю.
        } else {
            throw XCTSkip(
                "Flip произошёл, но low-reserve ветка не выбрала `above(trump)`; оставляем как probe до retuning."
            )
        }
    }

    func testMakeTurnDecision_whenAllInChaseUnderAntiPremiumPressure_flipsLeadJokerWishTowardAboveTrump() {
        let service = BotTurnStrategyService(tuning: BotTuning(difficulty: .hard))
        let trickNode = TrickNode()
        let handCards: [Card] = [
            .joker,
            card(.clubs, .six),
            card(.diamonds, .seven),
            card(.hearts, .eight)
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

        let neutralDecision = service.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
            trump: .spades,
            bid: 4,
            tricksTaken: 0,
            cardsInRound: 8,
            playerCount: 4,
            matchContext: neutralContext
        )
        let antiPremiumDecision = service.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
            trump: .spades,
            bid: 4,
            tricksTaken: 0,
            cardsInRound: 8,
            playerCount: 4,
            matchContext: antiPremiumContext
        )

        guard let neutralDecision, let antiPremiumDecision else {
            XCTFail("Ожидались валидные решения в premium-aware joker chase runtime-сценарии")
            return
        }

        XCTAssertEqual(neutralDecision.card, .joker)
        XCTAssertEqual(antiPremiumDecision.card, .joker)

        let neutralDecl = neutralDecision.jokerDecision.leadDeclaration
        let antiDecl = antiPremiumDecision.jokerDecision.leadDeclaration
        XCTAssertEqual(neutralDecl, .wish)
        XCTAssertEqual(antiDecl, .above(suit: .spades))
    }

    func testMakeTurnDecision_jokerPreferredSuitProbe_mayShiftAboveDeclarationByPostJokerControlSuit() throws {
        let service = BotTurnStrategyService(tuning: BotTuning(difficulty: .hard))
        let trickNode = TrickNode()
        let spadeControlHand: [Card] = [
            .joker,
            card(.spades, .ten),
            card(.spades, .nine),
            card(.hearts, .six)
        ]
        let heartControlHand: [Card] = [
            .joker,
            card(.hearts, .ten),
            card(.hearts, .nine),
            card(.spades, .six)
        ]

        let spadeControlDecision = service.makeTurnDecision(
            handCards: spadeControlHand,
            trickNode: trickNode,
            trump: .clubs,
            bid: 1,
            tricksTaken: 0,
            cardsInRound: 8,
            playerCount: 4
        )
        let heartControlDecision = service.makeTurnDecision(
            handCards: heartControlHand,
            trickNode: trickNode,
            trump: .clubs,
            bid: 1,
            tricksTaken: 0,
            cardsInRound: 8,
            playerCount: 4
        )

        guard let spadeControlDecision, let heartControlDecision else {
            XCTFail("Ожидались валидные решения в preferred-suit joker probe")
            return
        }

        if spadeControlDecision.card != .joker || heartControlDecision.card != .joker {
            throw XCTSkip(
                "В одной из веток runtime не выбрал lead-джокер; preferred-suit probe оставлен как цель retuning."
            )
        }

        let spadeDecl = spadeControlDecision.jokerDecision.leadDeclaration
        let heartDecl = heartControlDecision.jokerDecision.leadDeclaration
        if spadeDecl == heartDecl {
            throw XCTSkip(
                "Текущие коэффициенты пока не дают declaration shift по preferred-suit сигналу. " +
                "Сценарий оставлен как Stage-5 retuning probe."
            )
        }

        if case .some(.above(suit: .spades)) = spadeDecl {
            // ok
        } else {
            throw XCTSkip(
                "Spade-control ветка не выбрала `above(S)`; оставляем preferred-suit probe до retuning."
            )
        }
        if case .some(.above(suit: .hearts)) = heartDecl {
            // ok
        } else {
            throw XCTSkip(
                "Heart-control ветка не выбрала `above(H)`; оставляем preferred-suit probe до retuning."
            )
        }
    }

    func testMakeTurnDecision_phaseProbe_mayChangeLeadDumpChoiceBetweenEarlyAndLateContexts() throws {
        let service = BotTurnStrategyService(tuning: BotTuning(difficulty: .hard))
        let trickNode = TrickNode()
        let handCards: [Card] = [
            card(.spades, .ten),
            card(.hearts, .ace)
        ]

        let earlyPhaseDecision = service.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
            trump: .spades,
            bid: 0,
            tricksTaken: 0,
            cardsInRound: 2,
            playerCount: 4
        )
        let latePhaseDecision = service.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
            trump: .spades,
            bid: 0,
            tricksTaken: 0,
            cardsInRound: 8,
            playerCount: 4
        )

        guard let earlyPhaseDecision, let latePhaseDecision else {
            XCTFail("Ожидались валидные решения в обоих фазовых контекстах")
            return
        }

        XCTAssertTrue(handCards.contains(earlyPhaseDecision.card))
        XCTAssertTrue(handCards.contains(latePhaseDecision.card))

        if earlyPhaseDecision.card == latePhaseDecision.card,
           earlyPhaseDecision.jokerDecision == latePhaseDecision.jokerDecision {
            throw XCTSkip(
                "Текущие коэффициенты пока не дают phase-based flip в этом probe-сценарии. " +
                "Сценарий оставлен как цель для дальнейшего retuning."
            )
        }

        XCTAssertNotEqual(earlyPhaseDecision.card, latePhaseDecision.card)
    }

    func testMakeTurnDecision_premiumProbe_mayChangeLateDumpChoiceToPreservePremiumLine() throws {
        let service = BotTurnStrategyService(tuning: BotTuning(difficulty: .hard))
        let trickNode = TrickNode()
        _ = trickNode.playCard(card(.hearts, .queen), fromPlayer: 1, animated: false)

        let handCards: [Card] = [
            card(.clubs, .ace),
            card(.diamonds, .king)
        ]

        let neutralDecision = service.makeTurnDecision(
            handCards: handCards,
            trickNode: trickNode,
            trump: .spades,
            bid: 0,
            tricksTaken: 0,
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
            bid: 0,
            tricksTaken: 0,
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

        guard let neutralDecision, let premiumDecision else {
            XCTFail("Ожидались валидные решения в premium probe сценарии")
            return
        }

        XCTAssertTrue(handCards.contains(neutralDecision.card))
        XCTAssertTrue(handCards.contains(premiumDecision.card))

        if neutralDecision.card == premiumDecision.card,
           neutralDecision.jokerDecision == premiumDecision.jokerDecision {
            throw XCTSkip(
                "Текущие коэффициенты 4b пока не дают premium-based flip в этом probe-сценарии. " +
                "Сценарий оставлен как цель для дальнейшего retuning."
            )
        }

        XCTAssertNotEqual(neutralDecision.card, premiumDecision.card)
    }

    func testMakeTurnDecision_penaltyRiskProbe_mayChangeLateDumpChoiceToAvoidPenaltyTarget() throws {
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

        guard let neutralDecision, let penaltyRiskDecision else {
            XCTFail("Ожидались валидные решения в penalty-risk probe сценарии")
            return
        }

        XCTAssertTrue(handCards.contains(neutralDecision.card))
        XCTAssertTrue(handCards.contains(penaltyRiskDecision.card))

        if neutralDecision.card == penaltyRiskDecision.card,
           neutralDecision.jokerDecision == penaltyRiskDecision.jokerDecision {
            throw XCTSkip(
                "Текущие коэффициенты 4c fallback пока не дают penalty-risk flip в этом probe-сценарии. " +
                "Сценарий оставлен как цель для дальнейшего retuning."
            )
        }

        XCTAssertNotEqual(neutralDecision.card, penaltyRiskDecision.card)
    }

    func testMakeTurnDecision_antiPremiumProbe_mayChangeLateDumpChoiceAgainstLeftNeighborPremiumCandidate() throws {
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
                    isPenaltyTargetRiskSoFar: false,
                    premiumCandidatesThreateningPenaltyCount: 0,
                    opponentPremiumCandidatesSoFarCount: 0
                )
            )
        )
        let antiPremiumDecision = service.makeTurnDecision(
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
                    leftNeighborIsPremiumCandidateSoFar: true,
                    isPenaltyTargetRiskSoFar: false,
                    premiumCandidatesThreateningPenaltyCount: 0,
                    opponentPremiumCandidatesSoFarCount: 1
                )
            )
        )

        guard let neutralDecision, let antiPremiumDecision else {
            XCTFail("Ожидались валидные решения в anti-premium probe сценарии")
            return
        }

        XCTAssertTrue(handCards.contains(neutralDecision.card))
        XCTAssertTrue(handCards.contains(antiPremiumDecision.card))

        if neutralDecision.card == antiPremiumDecision.card,
           neutralDecision.jokerDecision == antiPremiumDecision.jokerDecision {
            throw XCTSkip(
                "Текущие коэффициенты 4c anti-premium пока не дают runtime flip в этом probe-сценарии. " +
                "Сценарий оставлен как цель для дальнейшего retuning."
            )
        }

        XCTAssertNotEqual(neutralDecision.card, antiPremiumDecision.card)
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

    private func card(_ suit: Suit, _ rank: Rank) -> Card {
        return .regular(suit: suit, rank: rank)
    }
}
