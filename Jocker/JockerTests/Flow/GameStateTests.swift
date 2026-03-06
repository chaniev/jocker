//
//  GameStateTests.swift
//  JockerTests
//
//  Created by Codex on 12.02.2026.
//

import XCTest
@testable import Jocker

final class GameStateTests: XCTestCase {

    /// Тестирует, что первый раунд в первом блоке имеет 1 карту на игрока.
    /// Проверяет:
    /// - currentBlock = .first
    /// - currentRoundInBlock = 0
    /// - currentCardsPerPlayer = 1
    /// - currentDealer = 0
    func testStartGame_hasOneCardPerPlayerInFirstRound() {
        let gameState = GameState(playerCount: 4)

        gameState.startGame()

        XCTAssertEqual(gameState.currentBlock, .first)
        XCTAssertEqual(gameState.currentRoundInBlock, 0)
        XCTAssertEqual(gameState.currentCardsPerPlayer, 1)
        XCTAssertEqual(gameState.currentDealer, 0)
    }

    /// Тестирует, что startGame устанавливает предоставленного initial dealer.
    /// Проверяет:
    /// - currentDealer = 2 (предоставленный)
    /// - currentPlayer = 3 (dealer + 1)
    func testStartGame_setsProvidedInitialDealer() {
        let gameState = GameState(playerCount: 4)

        gameState.startGame(initialDealerIndex: 2)

        XCTAssertEqual(gameState.currentDealer, 2)
        XCTAssertEqual(gameState.currentPlayer, 3)
    }

    func testStartGame_resetsAllPlayerRuntimeValuesForNewSession() {
        let gameState = GameState(playerCount: 4)
        gameState.startGame(initialDealerIndex: 0)

        gameState.setBid(1, forPlayerAt: 0, isBlind: true, lockBeforeDeal: true)
        gameState.setBid(0, forPlayerAt: 1)
        gameState.setBid(0, forPlayerAt: 2)
        gameState.setBid(0, forPlayerAt: 3)
        gameState.beginPlayingAfterBids()
        gameState.completeTrick(winner: 0)
        gameState.completeRound()

        XCTAssertTrue(gameState.players.contains { $0.currentBid != 0 || $0.tricksTaken != 0 || $0.isBlindBid || $0.isBidLockedBeforeDeal })

        gameState.startGame(initialDealerIndex: 1)

        XCTAssertEqual(gameState.currentBlock, .first)
        XCTAssertEqual(gameState.currentRoundInBlock, 0)
        XCTAssertEqual(gameState.currentCardsPerPlayer, 1)
        XCTAssertEqual(gameState.currentDealer, 1)
        XCTAssertEqual(gameState.currentPlayer, 2)
        XCTAssertEqual(gameState.phase, .bidding)

        for player in gameState.players {
            XCTAssertEqual(player.currentBid, 0)
            XCTAssertEqual(player.tricksTaken, 0)
            XCTAssertFalse(player.isBlindBid)
            XCTAssertFalse(player.isBidLockedBeforeDeal)
        }
    }

    /// Тестирует, что startNewRound прогрессирует карты в первом блоке и переходит ко второму.
    /// Проверяет:
    /// - Карты увеличиваются с 2 до 8 в первом блоке
    /// - После 8 карт переход во второй блок с 9 картами
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

    /// Тестирует, что startNewRound переходит к третьему блоку с убывающими картами.
    /// Проверяет:
    /// - После первого и второго блока переход к третьему
    /// - Карты уменьшаются с 8 до 1
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

    /// Тестирует, что для 3 игроков используется unified deal plan во втором блоке.
    /// Проверяет:
    /// - totalRoundsInBlock = 11 в первом блоке
    /// - Во втором блоке 3 раунда по 12 карт
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

    /// Тестирует, что startNewRound ротирует дилера каждый раунд.
    /// Проверяет:
    /// - dealer увеличивается: 0 → 1 → 2 → 3 → 0
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

    /// Тестирует, что дилер с 1 картой и уже сделанной ставкой исключает 0 из allowed bids.
    /// Проверяет:
    /// - Игрок 2 заказал 1 взятку
    /// - Дилер (Игрок 1) не может заказать 0
    /// - allowed = [1]
    func testAllowedBids_dealerWithOneCardAndOneBidAlreadyPlaced_excludesZero() {
        let gameState = GameState(playerCount: 4)
        gameState.startGame(initialDealerIndex: 0)

        // Игрок 2 заказал 1 взятку; дилер (Игрок 1) не может заказать 0,
        // иначе сумма ставок станет равной количеству карт (1).
        let bids = [0, 1, 0, 0]
        let allowed = gameState.allowedBids(forPlayer: 0, bids: bids)

        XCTAssertEqual(allowed, [1])
    }

    /// Тестирует, что дилер с 1 картой и без положительных ставок исключает 1.
    /// Проверяет:
    /// - Все игроки заказали 0
    /// - allowed = [0]
    func testAllowedBids_dealerWithOneCardAndNoPositiveBids_excludesOne() {
        let gameState = GameState(playerCount: 4)
        gameState.startGame(initialDealerIndex: 0)

        let bids = [0, 0, 0, 0]
        let allowed = gameState.allowedBids(forPlayer: 0, bids: bids)

        XCTAssertEqual(allowed, [0])
    }

    /// Тестирует, что не-дилер сохраняет полный диапазон ставок.
    /// Проверяет:
    /// - allowed = [0, 1] для не-дилера
    func testAllowedBids_nonDealerKeepsFullRange() {
        let gameState = GameState(playerCount: 4)
        gameState.startGame(initialDealerIndex: 0)

        let bids = [0, 1, 0, 0]
        let allowed = gameState.allowedBids(forPlayer: 2, bids: bids)

        XCTAssertEqual(allowed, [0, 1])
    }

    /// Тестирует, что canChooseBlindBid доступен только в четвёртом блоке.
    /// Проверяет:
    /// - В первых трёх блоках = false
    /// - В четвёртом блоке = true
    func testCanChooseBlindBid_isAvailableOnlyInFourthBlock() {
        let gameState = GameState(playerCount: 4)
        gameState.startGame(initialDealerIndex: 0)

        let selections = [false, false, false, false]
        XCTAssertFalse(gameState.canChooseBlindBid(forPlayer: 1, blindSelections: selections))

        moveToFourthBlock(gameState)
        XCTAssertTrue(gameState.canChooseBlindBid(forPlayer: 1, blindSelections: selections))
    }

    /// Тестирует, что дилер требует чтобы все остальные игроки выбрали blind.
    /// Проверяет:
    /// - allOpen = false → дилер не может выбрать blind
    /// - allBlindExceptDealer = true → дилер может выбрать blind
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

    func testCompleteRound_keepsRoundStateAvailableForScoreSnapshots() {
        let gameState = GameState(playerCount: 4)
        gameState.startGame(initialDealerIndex: 0)

        gameState.setBid(1, forPlayerAt: 0, isBlind: true, lockBeforeDeal: true)
        gameState.setBid(0, forPlayerAt: 1)
        gameState.setBid(0, forPlayerAt: 2)
        gameState.setBid(0, forPlayerAt: 3)
        gameState.beginPlayingAfterBids()
        gameState.completeTrick(winner: 0)
        gameState.completeRound()

        let results = GameRoundResultsBuilder.build(from: gameState, playerCount: 4)

        XCTAssertEqual(gameState.phase, .roundEnd)
        XCTAssertEqual(results?.count, 4)
        XCTAssertEqual(results?[0].bid, 1)
        XCTAssertEqual(results?[0].tricksTaken, 1)
        XCTAssertEqual(results?[0].isBlind, true)
        XCTAssertEqual(results?[0].score, 200)
    }

    /// Тестирует, что setPlayerNames применяет имена и fallback для пустых значений.
    /// Проверяет:
    /// - "Анна" → "Анна"
    /// - "  " → "Игрок 2" (fallback)
    /// - "Борис" → "Борис"
    /// - Пустой → "Игрок 4" (fallback)
    func testSetPlayerNames_appliesProvidedNamesAndFallbacksForEmptyValues() {
        let gameState = GameState(playerCount: 4)
        
        gameState.setPlayerNames(["Анна", "  ", "Борис"])
        
        XCTAssertEqual(gameState.players[0].name, "Анна")
        XCTAssertEqual(gameState.players[1].name, "Игрок 2")
        XCTAssertEqual(gameState.players[2].name, "Борис")
        XCTAssertEqual(gameState.players[3].name, "Игрок 4")
    }

    /// Тестирует, что startNewRound на последнем раунде сохраняет gameEnd phase.
    /// Проверяет:
    /// - После последнего раунда phase = .gameEnd
    func testStartNewRound_onFinalRoundKeepsGameEndPhase() {
        let gameState = GameState(playerCount: 4)
        gameState.startGame()

        while gameState.currentBlock != .fourth || gameState.currentRoundInBlock < gameState.totalRoundsInBlock - 1 {
            gameState.startNewRound()
        }

        gameState.startNewRound()

        XCTAssertEqual(gameState.phase, .gameEnd)
    }

    /// Тестирует, что первая карта идёт стартовому игроку при раздаче.
    /// Проверяет:
    /// - startingPlayerIndex = 1 → первая карта игроку 1
    /// - Остальные карты по порядку
    func testDeckDealCards_firstCardGoesToStartingPlayer() {
        var deck = Deck()

        let result = deck.dealCards(playerCount: 4, cardsPerPlayer: 1, startingPlayerIndex: 1)

        XCTAssertEqual(result.hands[1], [.regular(suit: .diamonds, rank: .six)], "Первая карта должна уйти стартовому игроку")
        XCTAssertEqual(result.hands[2], [.regular(suit: .diamonds, rank: .seven)])
        XCTAssertEqual(result.hands[3], [.regular(suit: .diamonds, rank: .eight)])
        XCTAssertEqual(result.hands[0], [.regular(suit: .diamonds, rank: .nine)])
    }

    /// Тестирует, что start по умолчанию = игрок 0.
    /// Проверяет:
    /// - Игрок 0 получает первую карту
    func testDeckDealCards_defaultStartIsPlayerZero() {
        var deck = Deck()

        let result = deck.dealCards(playerCount: 4, cardsPerPlayer: 1)

        XCTAssertEqual(result.hands[0], [.regular(suit: .diamonds, rank: .six)])
        XCTAssertEqual(result.hands[1], [.regular(suit: .diamonds, rank: .seven)])
        XCTAssertEqual(result.hands[2], [.regular(suit: .diamonds, rank: .eight)])
        XCTAssertEqual(result.hands[3], [.regular(suit: .diamonds, rank: .nine)])
    }

    /// Тестирует, что shuffle сохраняет карты и обычно меняет порядок.
    /// Проверяет:
    /// - Количество карт сохраняется
    /// - Set карт одинаковый
    /// - Порядок обычно отличается
    func testDeckShuffle_preservesCardsAndUsuallyChangesOrder() {
        var deck = Deck()
        let originalOrder = deck.cards

        deck.shuffle()

        XCTAssertEqual(deck.cards.count, originalOrder.count)
        XCTAssertEqual(Set(deck.cards), Set(originalOrder))
        XCTAssertNotEqual(
            deck.cards,
            originalOrder,
            "После shuffle порядок карт должен отличаться от исходного."
        )
    }

    /// Тестирует, что при полной раздаче 4 игрокам по 9 карт все карты раздаются без trump.
    /// Проверяет:
    /// - 4 руки по 9 карт
    /// - trump = nil
    /// - deck.count = 0
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

    /// Тестирует staged deal: сначала 3 карты, потом остальные 6.
    /// Проверяет:
    /// - firstStage: 4 руки по 3 карты
    /// - secondStage: 4 руки по 6 карт
    /// - combined: 4 руки по 9 карт
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

    /// Тестирует, что trump selection использует automatic top card в первом и третьем блоках.
    /// Проверяет:
    /// - strategy = .automaticTopDeckCard
    /// - cardsToDealBeforeChoicePerPlayer = 8 (первый блок), 5 (третий блок)
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

    /// Тестирует, что trump selection использует player on dealer left во втором и четвёртом блоках.
    /// Проверяет:
    /// - strategy = .playerOnDealerLeft
    /// - chooserPlayerIndex = 0 (слева от дилера)
    /// - cardsToDealBeforeChoicePerPlayer = 3 (второй блок), 4 (четвёртый блок)
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

    /// Тестирует, что selectFirstDealer начинает с предоставленного seat и находит первый Ace.
    /// Проверяет:
    /// - startingPlayerIndex = 1
    /// - dealerIndex = 0 (первый туз)
    func testDeckSelectFirstDealer_startsFromProvidedSeatAndFindsFirstAce() {
        var deck = Deck()

        let dealerIndex = deck.selectFirstDealer(playerCount: 4, startingPlayerIndex: 1)

        XCTAssertEqual(
            dealerIndex,
            0,
            "После сброса верхней карты в центр первый туз должен прийти игроку с индексом 0."
        )
    }

    /// Тестирует, что prepareFirstDealerSelection предоставляет visual sequence и winning Ace.
    /// Проверяет:
    /// - tableCard = верхняя карта (diamonds six)
    /// - dealtCards не пустой
    /// - dealerIndex = 0
    /// - Последняя карта в dealtCards = Ace
    func testPrepareFirstDealerSelection_providesVisualSequenceAndWinningAce() {
        var deck = Deck()

        let selection = deck.prepareFirstDealerSelection(playerCount: 4, startingPlayerIndex: 1)

        XCTAssertEqual(selection.tableCard, .regular(suit: .diamonds, rank: .six))
        XCTAssertFalse(selection.dealtCards.isEmpty)
        XCTAssertEqual(selection.dealerIndex, 0)
        XCTAssertEqual(selection.dealtCards.last?.playerIndex, selection.dealerIndex)
        XCTAssertEqual(selection.dealtCards.last?.card.rank, .ace)
    }

    private func moveToFourthBlock(_ gameState: GameState) {
        while gameState.currentBlock != .fourth {
            gameState.startNewRound()
        }
    }
}
