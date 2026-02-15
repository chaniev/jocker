//
//  AutoPlayFlowTests.swift
//  JockerTests
//
//  Created by Codex on 15.02.2026.
//

import XCTest
@testable import Jocker

final class AutoPlayFlowTests: XCTestCase {
    func testAutoRound_fourPlayersNineCardsEach_allTurnsAreLegalAndHandsExhausted() {
        let playerCount = 4
        let cardsPerPlayer = 9
        let dealerIndex = 0

        var deck = Deck()
        deck.shuffle()
        let trumpSelectionService = BotTrumpSelectionService()

        let deal = dealRound(
            block: .second,
            playerCount: playerCount,
            cardsPerPlayer: cardsPerPlayer,
            dealerIndex: dealerIndex,
            deck: &deck,
            trumpSelectionService: trumpSelectionService
        )

        XCTAssertEqual(deal.countByPlayer.count, playerCount)
        XCTAssertTrue(deal.countByPlayer.allSatisfy { $0 == cardsPerPlayer })

        let trump = deal.trump
        let biddingService = BotBiddingService()
        let turnService = GameTurnService()
        let trickNode = TrickNode()

        var hands = deal.hands
        var bids = Array(repeating: 0, count: playerCount)
        let biddingOrder = (0..<playerCount).map { ((dealerIndex + 1) + $0) % playerCount }

        for playerIndex in biddingOrder {
            let forbidden: Int?
            if playerIndex == dealerIndex {
                let totalWithoutDealer = bids.enumerated().reduce(0) { partial, pair in
                    let (index, bid) = pair
                    return partial + (index == dealerIndex ? 0 : bid)
                }
                let candidate = cardsPerPlayer - totalWithoutDealer
                forbidden = (0...cardsPerPlayer).contains(candidate) ? candidate : nil
            } else {
                forbidden = nil
            }

            bids[playerIndex] = biddingService.makeBid(
                hand: hands[playerIndex],
                cardsInRound: cardsPerPlayer,
                trump: trump,
                forbiddenBid: forbidden
            )
        }

        var tricksTaken = Array(repeating: 0, count: playerCount)
        var leadPlayer = (dealerIndex + 1) % playerCount

        for _ in 0..<cardsPerPlayer {
            trickNode.clearTrick(toPosition: .zero, animated: false)

            for offset in 0..<playerCount {
                let playerIndex = (leadPlayer + offset) % playerCount
                let hand = hands[playerIndex]
                XCTAssertFalse(hand.isEmpty, "Игрок \(playerIndex) неожиданно остался без карт до завершения раунда.")

                guard let decision = turnService.automaticTurnDecision(
                    from: hand,
                    trickNode: trickNode,
                    trump: trump,
                    bid: bids[playerIndex],
                    tricksTaken: tricksTaken[playerIndex],
                    cardsInRound: cardsPerPlayer,
                    playerCount: playerCount
                ) else {
                    XCTFail("Не удалось выбрать карту для игрока \(playerIndex).")
                    return
                }

                XCTAssertTrue(
                    trickNode.canPlayCard(decision.card, fromHand: hand, trump: trump),
                    "Выбрана невалидная карта для игрока \(playerIndex)."
                )

                guard let removeIndex = hands[playerIndex].firstIndex(of: decision.card) else {
                    XCTFail("Карта \(decision.card) отсутствует в руке игрока \(playerIndex).")
                    return
                }

                hands[playerIndex].remove(at: removeIndex)
                _ = trickNode.playCard(
                    decision.card,
                    fromPlayer: playerIndex + 1,
                    jokerPlayStyle: decision.jokerDecision.style,
                    jokerLeadDeclaration: decision.jokerDecision.leadDeclaration,
                    animated: false
                )
            }

            guard let winner = turnService.trickWinnerIndex(
                trickNode: trickNode,
                playerCount: playerCount,
                trump: trump
            ) else {
                XCTFail("Не удалось определить победителя взятки.")
                return
            }

            tricksTaken[winner] += 1
            leadPlayer = winner
        }

        XCTAssertTrue(hands.allSatisfy { $0.isEmpty })
        XCTAssertEqual(tricksTaken.reduce(0, +), cardsPerPlayer)
    }

    func testStressAutoFlow_manyRounds_noHandTurnDesync() {
        runStressSimulation(playerCount: 4, cycles: 20)
        runStressSimulation(playerCount: 3, cycles: 20)
    }

    // MARK: - Helpers

    private func runStressSimulation(playerCount: Int, cycles: Int) {
        let turnService = GameTurnService()
        let biddingService = BotBiddingService()
        let trumpSelectionService = BotTrumpSelectionService()
        let roundsTemplate: [(block: GameBlock, cardsPerPlayer: Int)] = GameBlock.allCases.flatMap { block in
            GameConstants.deals(for: block, playerCount: playerCount).map { cards in
                (block: block, cardsPerPlayer: cards)
            }
        }

        XCTAssertFalse(roundsTemplate.isEmpty)
        XCTAssertGreaterThan(cycles, 0)

        var dealerIndex = 0
        var globalRound = 0

        for cycle in 0..<cycles {
            for round in roundsTemplate {
                globalRound += 1
                let cardsPerPlayer = round.cardsPerPlayer

                var deck = Deck()
                deck.shuffle()

                let deal = dealRound(
                    block: round.block,
                    playerCount: playerCount,
                    cardsPerPlayer: cardsPerPlayer,
                    dealerIndex: dealerIndex,
                    deck: &deck,
                    trumpSelectionService: trumpSelectionService
                )

                XCTAssertEqual(
                    deal.countByPlayer.count,
                    playerCount,
                    "Round \(globalRound), cycle \(cycle): некорректное количество рук."
                )
                XCTAssertTrue(
                    deal.countByPlayer.allSatisfy { $0 == cardsPerPlayer },
                    "Round \(globalRound), cycle \(cycle): карты розданы неравномерно."
                )

                let trump = deal.trump
                var hands = deal.hands
                let bids = makeBids(
                    for: hands,
                    playerCount: playerCount,
                    cardsPerPlayer: cardsPerPlayer,
                    dealerIndex: dealerIndex,
                    trump: trump,
                    biddingService: biddingService
                )
                var tricksTaken = Array(repeating: 0, count: playerCount)
                var leadPlayer = (dealerIndex + 1) % playerCount

                for trick in 0..<cardsPerPlayer {
                    let trickNode = TrickNode()
                    let expectedAtTrickStart = cardsPerPlayer - trick

                    XCTAssertTrue(
                        hands.allSatisfy { $0.count == expectedAtTrickStart },
                        "Round \(globalRound), trick \(trick): рассинхрон размеров рук перед взяткой."
                    )

                    for offset in 0..<playerCount {
                        let playerIndex = (leadPlayer + offset) % playerCount
                        let hand = hands[playerIndex]

                        XCTAssertFalse(
                            hand.isEmpty,
                            "Round \(globalRound), trick \(trick): игрок \(playerIndex) остался без карт до своего хода."
                        )

                        guard let decision = turnService.automaticTurnDecision(
                            from: hand,
                            trickNode: trickNode,
                            trump: trump,
                            bid: bids[playerIndex],
                            tricksTaken: tricksTaken[playerIndex],
                            cardsInRound: cardsPerPlayer,
                            playerCount: playerCount
                        ) else {
                            XCTFail("Round \(globalRound), trick \(trick): не удалось выбрать ход для игрока \(playerIndex).")
                            return
                        }

                        XCTAssertTrue(
                            trickNode.canPlayCard(decision.card, fromHand: hand, trump: trump),
                            "Round \(globalRound), trick \(trick): выбран невалидный ход игрока \(playerIndex)."
                        )

                        guard let removeIndex = hands[playerIndex].firstIndex(of: decision.card) else {
                            XCTFail("Round \(globalRound), trick \(trick): выбранная карта отсутствует в руке игрока \(playerIndex).")
                            return
                        }

                        hands[playerIndex].remove(at: removeIndex)
                        _ = trickNode.playCard(
                            decision.card,
                            fromPlayer: playerIndex + 1,
                            jokerPlayStyle: decision.jokerDecision.style,
                            jokerLeadDeclaration: decision.jokerDecision.leadDeclaration,
                            animated: false
                        )
                    }

                    let expectedAtTrickEnd = expectedAtTrickStart - 1
                    XCTAssertTrue(
                        hands.allSatisfy { $0.count == expectedAtTrickEnd },
                        "Round \(globalRound), trick \(trick): рассинхрон размеров рук после взятки."
                    )

                    guard let winner = turnService.trickWinnerIndex(
                        trickNode: trickNode,
                        playerCount: playerCount,
                        trump: trump
                    ) else {
                        XCTFail("Round \(globalRound), trick \(trick): не удалось определить победителя взятки.")
                        return
                    }

                    tricksTaken[winner] += 1
                    leadPlayer = winner
                }

                XCTAssertTrue(
                    hands.allSatisfy { $0.isEmpty },
                    "Round \(globalRound), cycle \(cycle): после раунда остались карты в руках."
                )
                XCTAssertEqual(
                    tricksTaken.reduce(0, +),
                    cardsPerPlayer,
                    "Round \(globalRound), cycle \(cycle): сумма взяток не совпадает с количеством ходов."
                )

                dealerIndex = (dealerIndex + 1) % playerCount
            }
        }
    }

    func testSecondBlockTrumpSelection_usesOnlyFirstThirdOfCards() {
        let playerCount = 4
        let cardsPerPlayer = 9
        let dealerIndex = 0
        var deck = Deck()
        let trumpSelectionService = BotTrumpSelectionService()

        let deal = dealRound(
            block: .second,
            playerCount: playerCount,
            cardsPerPlayer: cardsPerPlayer,
            dealerIndex: dealerIndex,
            deck: &deck,
            trumpSelectionService: trumpSelectionService
        )

        XCTAssertEqual(deal.trump, .diamonds)
        XCTAssertTrue(deal.countByPlayer.allSatisfy { $0 == cardsPerPlayer })
        XCTAssertEqual(deck.count, 0)
    }

    private func makeBids(
        for hands: [[Card]],
        playerCount: Int,
        cardsPerPlayer: Int,
        dealerIndex: Int,
        trump: Suit?,
        biddingService: BotBiddingService
    ) -> [Int] {
        var bids = Array(repeating: 0, count: playerCount)
        let biddingOrder = (0..<playerCount).map { ((dealerIndex + 1) + $0) % playerCount }

        for playerIndex in biddingOrder {
            let forbidden: Int?
            if playerIndex == dealerIndex {
                let totalWithoutDealer = bids.enumerated().reduce(0) { partial, pair in
                    let (index, bid) = pair
                    return partial + (index == dealerIndex ? 0 : bid)
                }
                let candidate = cardsPerPlayer - totalWithoutDealer
                forbidden = (0...cardsPerPlayer).contains(candidate) ? candidate : nil
            } else {
                forbidden = nil
            }

            bids[playerIndex] = biddingService.makeBid(
                hand: hands[playerIndex],
                cardsInRound: cardsPerPlayer,
                trump: trump,
                forbiddenBid: forbidden
            )
        }

        return bids
    }

    private func dealRound(
        block: GameBlock,
        playerCount: Int,
        cardsPerPlayer: Int,
        dealerIndex: Int,
        deck: inout Deck,
        trumpSelectionService: BotTrumpSelectionService
    ) -> (hands: [[Card]], trump: Suit?, countByPlayer: [Int]) {
        let firstPlayerToDeal = (dealerIndex + 1) % playerCount
        let trumpRule = TrumpSelectionRules.rule(
            for: block,
            cardsPerPlayer: cardsPerPlayer,
            dealerIndex: dealerIndex,
            playerCount: playerCount
        )

        switch trumpRule.strategy {
        case .automaticTopDeckCard:
            let deal = deck.dealCards(
                playerCount: playerCount,
                cardsPerPlayer: cardsPerPlayer,
                startingPlayerIndex: firstPlayerToDeal
            )
            let trumpSuit: Suit?
            if case .regular(let suit, _) = deal.trump {
                trumpSuit = suit
            } else {
                trumpSuit = nil
            }
            return (
                hands: deal.hands,
                trump: trumpSuit,
                countByPlayer: deal.hands.map(\.count)
            )

        case .playerOnDealerLeft:
            let cardsBeforeChoice = min(cardsPerPlayer, trumpRule.cardsToDealBeforeChoicePerPlayer)
            let firstStage = deck.dealCards(
                playerCount: playerCount,
                cardsPerPlayer: cardsBeforeChoice,
                startingPlayerIndex: firstPlayerToDeal
            )

            let remainingCardsPerPlayer = max(0, cardsPerPlayer - cardsBeforeChoice)
            let secondStage = deck.dealCards(
                playerCount: playerCount,
                cardsPerPlayer: remainingCardsPerPlayer,
                startingPlayerIndex: firstPlayerToDeal
            )

            let combinedHands = zip(firstStage.hands, secondStage.hands).map { first, second in
                first + second
            }
            let chooserHand = firstStage.hands.indices.contains(trumpRule.chooserPlayerIndex)
                ? firstStage.hands[trumpRule.chooserPlayerIndex]
                : []
            let trumpSuit = trumpSelectionService.selectTrump(from: chooserHand)

            return (
                hands: combinedHands,
                trump: trumpSuit,
                countByPlayer: combinedHands.map(\.count)
            )
        }
    }
}
