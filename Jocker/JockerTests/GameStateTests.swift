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

    func testDeckDealCards_firstCardGoesToStartingPlayer() {
        var deck = Deck()

        let result = deck.dealCards(playerCount: 4, cardsPerPlayer: 1, startingPlayerIndex: 1)

        XCTAssertEqual(result.hands[1], [.joker], "Первая карта должна уйти стартовому игроку")
        XCTAssertEqual(result.hands[2], [.regular(suit: .diamonds, rank: .seven)])
        XCTAssertEqual(result.hands[3], [.regular(suit: .diamonds, rank: .eight)])
        XCTAssertEqual(result.hands[0], [.regular(suit: .diamonds, rank: .nine)])
    }

    func testDeckDealCards_defaultStartIsPlayerZero() {
        var deck = Deck()

        let result = deck.dealCards(playerCount: 4, cardsPerPlayer: 1)

        XCTAssertEqual(result.hands[0], [.joker])
        XCTAssertEqual(result.hands[1], [.regular(suit: .diamonds, rank: .seven)])
        XCTAssertEqual(result.hands[2], [.regular(suit: .diamonds, rank: .eight)])
        XCTAssertEqual(result.hands[3], [.regular(suit: .diamonds, rank: .nine)])
    }
}
