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

    func testDeckSelectFirstDealer_startsFromProvidedSeatAndFindsFirstAce() {
        var deck = Deck()

        let dealerIndex = deck.selectFirstDealer(playerCount: 4, startingPlayerIndex: 1)

        XCTAssertEqual(
            dealerIndex,
            0,
            "После сброса верхней карты в центр первый туз должен прийти игроку с индексом 0."
        )
    }
}
