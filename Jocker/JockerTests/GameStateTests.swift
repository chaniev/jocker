//
//  GameStateTests.swift
//  JockerTests
//
//  Created by Codex on 12.02.2026.
//

import XCTest
@testable import Jocker

final class GameStateTests: XCTestCase {

    func testStartGame_hasOneCardPerPlayerInFirstRound() {
        let gameState = GameState(playerCount: 4)

        gameState.startGame()

        XCTAssertEqual(gameState.currentBlock, .first)
        XCTAssertEqual(gameState.currentRoundInBlock, 0)
        XCTAssertEqual(gameState.currentCardsPerPlayer, 1)
        XCTAssertEqual(gameState.currentDealer, 0)
    }

    func testStartGame_setsProvidedInitialDealer() {
        let gameState = GameState(playerCount: 4)

        gameState.startGame(initialDealerIndex: 2)

        XCTAssertEqual(gameState.currentDealer, 2)
        XCTAssertEqual(gameState.currentPlayer, 3)
    }

    func testStartNewRound_progressesCardsInFirstBlockAndMovesToSecond() {
        let gameState = GameState(playerCount: 4)
        gameState.startGame()

        for expectedCards in 2...8 {
            gameState.startNewRound()
            XCTAssertEqual(gameState.currentBlock, .first)
            XCTAssertEqual(gameState.currentCardsPerPlayer, expectedCards)
        }

        gameState.startNewRound()
        XCTAssertEqual(gameState.currentBlock, .second)
        XCTAssertEqual(gameState.currentRoundInBlock, 0)
        XCTAssertEqual(gameState.currentCardsPerPlayer, 9)
    }

    func testStartNewRound_movesToThirdBlockWithDescendingCards() {
        let gameState = GameState(playerCount: 4)
        gameState.startGame()

        for _ in 0..<8 {
            gameState.startNewRound()
        }

        for _ in 0..<4 {
            gameState.startNewRound()
        }

        XCTAssertEqual(gameState.currentBlock, .third)
        XCTAssertEqual(gameState.currentCardsPerPlayer, 8)

        for expectedCards in stride(from: 7, through: 1, by: -1) {
            gameState.startNewRound()
            XCTAssertEqual(gameState.currentBlock, .third)
            XCTAssertEqual(gameState.currentCardsPerPlayer, expectedCards)
        }
    }

    func testThreePlayers_usesUnifiedDealPlanInSecondBlock() {
        let gameState = GameState(playerCount: 3)
        gameState.startGame()

        XCTAssertEqual(gameState.currentCardsPerPlayer, 1)
        XCTAssertEqual(gameState.totalRoundsInBlock, 11)

        for expectedCards in 2...11 {
            gameState.startNewRound()
            XCTAssertEqual(gameState.currentBlock, .first)
            XCTAssertEqual(gameState.currentCardsPerPlayer, expectedCards)
        }

        gameState.startNewRound()
        XCTAssertEqual(gameState.currentBlock, .second)
        XCTAssertEqual(gameState.totalRoundsInBlock, 3)
        XCTAssertEqual(gameState.currentCardsPerPlayer, 12)

        gameState.startNewRound()
        XCTAssertEqual(gameState.currentCardsPerPlayer, 12)

        gameState.startNewRound()
        XCTAssertEqual(gameState.currentCardsPerPlayer, 12)
    }

    func testStartNewRound_rotatesDealerEachRound() {
        let gameState = GameState(playerCount: 4)
        gameState.startGame()

        XCTAssertEqual(gameState.currentDealer, 0)

        gameState.startNewRound()
        XCTAssertEqual(gameState.currentDealer, 1)

        gameState.startNewRound()
        XCTAssertEqual(gameState.currentDealer, 2)

        gameState.startNewRound()
        XCTAssertEqual(gameState.currentDealer, 3)

        gameState.startNewRound()
        XCTAssertEqual(gameState.currentDealer, 0)
    }

    func testAllowedBids_dealerWithOneCardAndOneBidAlreadyPlaced_excludesZero() {
        let gameState = GameState(playerCount: 4)
        gameState.startGame(initialDealerIndex: 0)

        // Игрок 2 заказал 1 взятку; дилер (Игрок 1) не может заказать 0,
        // иначе сумма ставок станет равной количеству карт (1).
        let bids = [0, 1, 0, 0]
        let allowed = gameState.allowedBids(forPlayer: 0, bids: bids)

        XCTAssertEqual(allowed, [1])
    }

    func testAllowedBids_dealerWithOneCardAndNoPositiveBids_excludesOne() {
        let gameState = GameState(playerCount: 4)
        gameState.startGame(initialDealerIndex: 0)

        let bids = [0, 0, 0, 0]
        let allowed = gameState.allowedBids(forPlayer: 0, bids: bids)

        XCTAssertEqual(allowed, [0])
    }

    func testAllowedBids_nonDealerKeepsFullRange() {
        let gameState = GameState(playerCount: 4)
        gameState.startGame(initialDealerIndex: 0)

        let bids = [0, 1, 0, 0]
        let allowed = gameState.allowedBids(forPlayer: 2, bids: bids)

        XCTAssertEqual(allowed, [0, 1])
    }

    func testCanChooseBlindBid_isAvailableOnlyInFourthBlock() {
        let gameState = GameState(playerCount: 4)
        gameState.startGame(initialDealerIndex: 0)

        let selections = [false, false, false, false]
        XCTAssertFalse(gameState.canChooseBlindBid(forPlayer: 1, blindSelections: selections))

        moveToFourthBlock(gameState)
        XCTAssertTrue(gameState.canChooseBlindBid(forPlayer: 1, blindSelections: selections))
    }

    func testCanChooseBlindBid_dealerRequiresAllOtherPlayersToChooseBlind() {
        let gameState = GameState(playerCount: 4)
        gameState.startGame(initialDealerIndex: 0)
        moveToFourthBlock(gameState)

        let dealerIndex = gameState.currentDealer
        var allOpen = Array(repeating: false, count: 4)
        let allBlindExceptDealer = (0..<4).map { index in
            index == dealerIndex ? false : true
        }

        XCTAssertFalse(gameState.canChooseBlindBid(forPlayer: dealerIndex, blindSelections: allOpen))

        allOpen[(dealerIndex + 1) % 4] = true
        XCTAssertFalse(gameState.canChooseBlindBid(forPlayer: dealerIndex, blindSelections: allOpen))

        XCTAssertTrue(gameState.canChooseBlindBid(forPlayer: dealerIndex, blindSelections: allBlindExceptDealer))
    }
    
    func testSetPlayerNames_appliesProvidedNamesAndFallbacksForEmptyValues() {
        let gameState = GameState(playerCount: 4)
        
        gameState.setPlayerNames(["Анна", "  ", "Борис"])
        
        XCTAssertEqual(gameState.players[0].name, "Анна")
        XCTAssertEqual(gameState.players[1].name, "Игрок 2")
        XCTAssertEqual(gameState.players[2].name, "Борис")
        XCTAssertEqual(gameState.players[3].name, "Игрок 4")
    }

    func testStartNewRound_onFinalRoundKeepsGameEndPhase() {
        let gameState = GameState(playerCount: 4)
        gameState.startGame()

        while gameState.currentBlock != .fourth || gameState.currentRoundInBlock < gameState.totalRoundsInBlock - 1 {
            gameState.startNewRound()
        }

        gameState.startNewRound()

        XCTAssertEqual(gameState.phase, .gameEnd)
    }

    func testDeckDealCards_firstCardGoesToStartingPlayer() {
        var deck = Deck()

        let result = deck.dealCards(playerCount: 4, cardsPerPlayer: 1, startingPlayerIndex: 1)

        XCTAssertEqual(result.hands[1], [.regular(suit: .diamonds, rank: .six)], "Первая карта должна уйти стартовому игроку")
        XCTAssertEqual(result.hands[2], [.regular(suit: .diamonds, rank: .seven)])
        XCTAssertEqual(result.hands[3], [.regular(suit: .diamonds, rank: .eight)])
        XCTAssertEqual(result.hands[0], [.regular(suit: .diamonds, rank: .nine)])
    }

    func testDeckDealCards_defaultStartIsPlayerZero() {
        var deck = Deck()

        let result = deck.dealCards(playerCount: 4, cardsPerPlayer: 1)

        XCTAssertEqual(result.hands[0], [.regular(suit: .diamonds, rank: .six)])
        XCTAssertEqual(result.hands[1], [.regular(suit: .diamonds, rank: .seven)])
        XCTAssertEqual(result.hands[2], [.regular(suit: .diamonds, rank: .eight)])
        XCTAssertEqual(result.hands[3], [.regular(suit: .diamonds, rank: .nine)])
    }

    func testDeckDealCards_fourPlayersNineCardsEach_dealsAllCardsWithoutTrump() {
        var deck = Deck()

        let result = deck.dealCards(playerCount: 4, cardsPerPlayer: 9)

        XCTAssertEqual(result.hands.count, 4)
        XCTAssertEqual(result.hands[0].count, 9)
        XCTAssertEqual(result.hands[1].count, 9)
        XCTAssertEqual(result.hands[2].count, 9)
        XCTAssertEqual(result.hands[3].count, 9)
        XCTAssertNil(result.trump, "При полной раздаче козырная карта не должна оставаться в колоде.")
        XCTAssertEqual(deck.count, 0)
    }

    func testDeckStagedDeal_fourPlayersFullRound_distributesThreeThenRemainingCards() {
        var deck = Deck()

        let firstStage = deck.dealCards(
            playerCount: 4,
            cardsPerPlayer: 3,
            startingPlayerIndex: 1
        )
        let secondStage = deck.dealCards(
            playerCount: 4,
            cardsPerPlayer: 6,
            startingPlayerIndex: 1
        )

        XCTAssertTrue(firstStage.hands.allSatisfy { $0.count == 3 })
        XCTAssertTrue(secondStage.hands.allSatisfy { $0.count == 6 })

        let combinedHands = zip(firstStage.hands, secondStage.hands).map { first, second in
            first + second
        }
        XCTAssertTrue(combinedHands.allSatisfy { $0.count == 9 })
        XCTAssertEqual(deck.count, 0)
        XCTAssertNil(secondStage.trump)
    }

    func testTrumpSelectionRules_usesAutomaticTopCardInFirstAndThirdBlocks() {
        let firstBlockRule = TrumpSelectionRules.rule(
            for: .first,
            cardsPerPlayer: 8,
            dealerIndex: 0,
            playerCount: 4
        )
        let thirdBlockRule = TrumpSelectionRules.rule(
            for: .third,
            cardsPerPlayer: 5,
            dealerIndex: 2,
            playerCount: 4
        )

        XCTAssertEqual(firstBlockRule.strategy, .automaticTopDeckCard)
        XCTAssertEqual(firstBlockRule.cardsToDealBeforeChoicePerPlayer, 8)
        XCTAssertEqual(firstBlockRule.chooserPlayerIndex, 1)

        XCTAssertEqual(thirdBlockRule.strategy, .automaticTopDeckCard)
        XCTAssertEqual(thirdBlockRule.cardsToDealBeforeChoicePerPlayer, 5)
        XCTAssertEqual(thirdBlockRule.chooserPlayerIndex, 3)
    }

    func testTrumpSelectionRules_usesPlayerOnDealerLeftInSecondAndFourthBlocks() {
        let secondBlockRule = TrumpSelectionRules.rule(
            for: .second,
            cardsPerPlayer: 9,
            dealerIndex: 3,
            playerCount: 4
        )
        let fourthBlockRule = TrumpSelectionRules.rule(
            for: .fourth,
            cardsPerPlayer: 12,
            dealerIndex: 2,
            playerCount: 3
        )

        XCTAssertEqual(secondBlockRule.strategy, .playerOnDealerLeft)
        XCTAssertEqual(secondBlockRule.chooserPlayerIndex, 0)
        XCTAssertEqual(secondBlockRule.cardsToDealBeforeChoicePerPlayer, 3)

        XCTAssertEqual(fourthBlockRule.strategy, .playerOnDealerLeft)
        XCTAssertEqual(fourthBlockRule.chooserPlayerIndex, 0)
        XCTAssertEqual(fourthBlockRule.cardsToDealBeforeChoicePerPlayer, 4)
    }

    func testDeckSelectFirstDealer_startsFromProvidedSeatAndFindsFirstAce() {
        var deck = Deck()

        let dealerIndex = deck.selectFirstDealer(playerCount: 4, startingPlayerIndex: 1)

        XCTAssertEqual(
            dealerIndex,
            0,
            "После сброса верхней карты в центр первый туз должен прийти игроку с индексом 0."
        )
    }

    private func moveToFourthBlock(_ gameState: GameState) {
        while gameState.currentBlock != .fourth {
            gameState.startNewRound()
        }
    }
}
