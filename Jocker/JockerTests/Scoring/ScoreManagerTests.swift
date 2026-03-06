//
//  ScoreManagerTests.swift
//  JockerTests
//
//  Created by Чаниев Мурад on 08.02.2026.
//

import XCTest
@testable import Jocker

final class ScoreManagerTests: XCTestCase {
    
    // MARK: - Helpers

    private func validRoundResults(
        cardsInRound: Int,
        bids: [Int],
        tricksTaken: [Int],
        blindPlayerIndices: Set<Int> = []
    ) -> [RoundResult] {
        XCTAssertEqual(bids.count, tricksTaken.count)
        XCTAssertEqual(
            tricksTaken.reduce(0, +),
            cardsInRound,
            "Сумма взяток должна совпадать с количеством розданных карт."
        )
        XCTAssertNotEqual(
            bids.reduce(0, +),
            cardsInRound,
            "Сумма заказов не должна быть равна количеству розданных карт."
        )

        return bids.enumerated().map { index, bid in
            RoundResult(
                cardsInRound: cardsInRound,
                bid: bid,
                tricksTaken: tricksTaken[index],
                isBlind: blindPlayerIndices.contains(index)
            )
        }
    }
    
    /// Создать результат раунда с совпавшей ставкой
    private func matchedResult(bid: Int, cardsInRound: Int, isBlind: Bool = false) -> RoundResult {
        return RoundResult(cardsInRound: cardsInRound, bid: bid, tricksTaken: bid, isBlind: isBlind)
    }
    
    // MARK: - Запись результатов раунда
    
    func testRecordRoundResult_singlePlayer() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        let result = matchedResult(bid: 2, cardsInRound: 5)
        
        manager.recordRoundResult(playerIndex: 0, result: result)
        
        XCTAssertEqual(manager.currentBlockRoundResults[0].count, 1)
        XCTAssertEqual(manager.currentBlockRoundResults[0][0].bid, 2)
    }
    
    func testRecordRoundResults_allPlayers() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        let results = validRoundResults(
            cardsInRound: 3,
            bids: [1, 1, 1, 1],
            tricksTaken: [1, 1, 1, 0]
        )
        
        manager.recordRoundResults(results)
        
        for i in 0..<4 {
            XCTAssertEqual(manager.currentBlockRoundResults[i].count, 1)
        }
    }
    
    func testRecordRoundResults_wrongCount_ignored() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        let results = [
            matchedResult(bid: 1, cardsInRound: 3),
            matchedResult(bid: 0, cardsInRound: 3)
        ]
        
        manager.recordRoundResults(results)
        
        // Не записалось — несовпадение количества
        for i in 0..<4 {
            XCTAssertEqual(manager.currentBlockRoundResults[i].count, 0)
        }
    }

    func testInProgressRoundResults_matchByBlockAndRound() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        let inProgress = [
            RoundResult(cardsInRound: 5, bid: 2, tricksTaken: 0, isBlind: false),
            RoundResult(cardsInRound: 5, bid: 1, tricksTaken: 0, isBlind: false),
            RoundResult(cardsInRound: 5, bid: 1, tricksTaken: 0, isBlind: true),
            RoundResult(cardsInRound: 5, bid: 0, tricksTaken: 0, isBlind: false)
        ]

        manager.setInProgressRoundResults(inProgress, blockIndex: 1, roundIndex: 3)

        let player2 = manager.inProgressRoundResult(forBlockIndex: 1, roundIndex: 3, playerIndex: 2)
        XCTAssertEqual(player2?.bid, 1)
        XCTAssertEqual(player2?.tricksTaken, 0)
        XCTAssertEqual(player2?.isBlind, true)
    }

    func testInProgressRoundResults_clearAndMismatchReturnNil() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        let inProgress = [
            RoundResult(cardsInRound: 2, bid: 1, tricksTaken: 0, isBlind: false),
            RoundResult(cardsInRound: 2, bid: 0, tricksTaken: 0, isBlind: false),
            RoundResult(cardsInRound: 2, bid: 1, tricksTaken: 0, isBlind: false),
            RoundResult(cardsInRound: 2, bid: 0, tricksTaken: 0, isBlind: false)
        ]

        manager.setInProgressRoundResults(inProgress, blockIndex: 0, roundIndex: 1)

        XCTAssertNil(manager.inProgressRoundResult(forBlockIndex: 0, roundIndex: 0, playerIndex: 0))
        XCTAssertNil(manager.inProgressRoundResult(forBlockIndex: 1, roundIndex: 1, playerIndex: 0))

        manager.clearInProgressRoundResults()

        XCTAssertNil(manager.inProgressRoundResult(forBlockIndex: 0, roundIndex: 1, playerIndex: 0))
        XCTAssertNil(manager.inProgressRoundResults)
    }

    func testPlayerCountGetter_doesNotSynchronizeOrResetStateWhenProviderChanges() {
        var dynamicPlayerCount = 4
        let manager = ScoreManager(playerCountProvider: { dynamicPlayerCount })
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 1, 0, 0],
                tricksTaken: [1, 0, 0, 0]
            )
        )
        dynamicPlayerCount = 3

        XCTAssertEqual(manager.playerCount, 4, "Getter should be side-effect free and return cached value")
        XCTAssertEqual(manager.currentBlockRoundResults.count, 4, "State must not reset on property read")
        XCTAssertEqual(manager.currentBlockRoundResults[0].count, 1, "Existing data must be preserved")
    }

    func testSynchronizePlayerCountIfNeeded_updatesCacheAndResetsStateExplicitly() {
        var dynamicPlayerCount = 4
        let manager = ScoreManager(playerCountProvider: { dynamicPlayerCount })

        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 1, 0, 0],
                tricksTaken: [1, 0, 0, 0]
            )
        )
        manager.setInProgressRoundResults([
            RoundResult(cardsInRound: 2, bid: 1, tricksTaken: 0, isBlind: false),
            RoundResult(cardsInRound: 2, bid: 0, tricksTaken: 0, isBlind: false),
            RoundResult(cardsInRound: 2, bid: 1, tricksTaken: 0, isBlind: false),
            RoundResult(cardsInRound: 2, bid: 0, tricksTaken: 0, isBlind: false)
        ], blockIndex: 0, roundIndex: 1)
        _ = manager.finalizeBlock()

        dynamicPlayerCount = 3
        let didSync = manager.synchronizePlayerCountIfNeeded()

        XCTAssertTrue(didSync)
        XCTAssertEqual(manager.playerCount, 3)
        XCTAssertEqual(manager.currentBlockRoundResults.count, 3)
        XCTAssertTrue(manager.currentBlockRoundResults.allSatisfy(\.isEmpty))
        XCTAssertNil(manager.inProgressRoundResults)
        XCTAssertTrue(manager.completedBlocks.isEmpty, "Sync reset should drop state to avoid inconsistent snapshots")
    }
    
    // MARK: - Базовые очки текущего блока
    
    func testCurrentBlockBaseScores() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        
        // Раунд 1 (C=1)
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 1, 0, 0],
                tricksTaken: [1, 0, 0, 0]
            )
        )
        
        let scores = manager.currentBlockBaseScores
        XCTAssertEqual(scores[0], 100)
        XCTAssertEqual(scores[1], -100)
        XCTAssertEqual(scores[2], 50)
        XCTAssertEqual(scores[3], 50)
    }
    
    func testCurrentBlockBaseScores_multipleRounds() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        
        // Раунд 1 (C=1)
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 1, 0, 0],
                tricksTaken: [1, 0, 0, 0]
            )
        )
        
        // Раунд 2 (C=2)
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 2,
                bids: [1, 1, 1, 0],
                tricksTaken: [1, 1, 0, 0]
            )
        )
        
        let scores = manager.currentBlockBaseScores
        XCTAssertEqual(scores[0], 200)  // 100 + 100
        XCTAssertEqual(scores[1], 0)    // -100 + 100
        XCTAssertEqual(scores[2], -50)  // 50 - 100
        XCTAssertEqual(scores[3], 100)  // 50 + 50
    }

    // MARK: - Завершение блока без премий
    
    func testFinalizeBlock_noPremium() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 1, 1, 0],
                tricksTaken: [1, 0, 0, 0]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 2,
                bids: [1, 0, 1, 1],
                tricksTaken: [0, 1, 1, 0]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 3,
                bids: [2, 1, 2, 0],
                tricksTaken: [2, 1, 0, 0]
            )
        )
        
        let result = manager.finalizeBlock()
        
        XCTAssertTrue(result.premiumPlayerIndices.isEmpty)
        XCTAssertEqual(result.baseScores[0], 150)
        XCTAssertEqual(result.baseScores[1], 10)
        XCTAssertEqual(result.baseScores[2], -150)
        XCTAssertEqual(result.baseScores[3], 0)
        XCTAssertEqual(result.finalScores, result.baseScores)
    }
    
    // MARK: - Завершение блока с премией
    
    func testFinalizeBlock_onePremium() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        
        // Игрок 0 совпадает во всех раундах → получает премию
        // Раунд 1 (C=1)
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 1, 1, 0],
                tricksTaken: [1, 0, 0, 0]
            )
        )
        // Раунд 2 (C=2)
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 2,
                bids: [1, 1, 0, 1],
                tricksTaken: [1, 1, 0, 0]
            )
        )
        // Раунд 3 (C=3) — последний раунд блока
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 3,
                bids: [2, 1, 0, 1],
                tricksTaken: [2, 1, 0, 0]
            )
        )
        
        let result = manager.finalizeBlock()
        
        // Только игрок 0 получает премию
        XCTAssertEqual(result.premiumPlayerIndices, [0])
        
        // Бонус игрока 0: max(100, 100) = 100 (раунды 1 и 2, исключая последний)
        XCTAssertEqual(result.premiumBonuses[0], 100)
        
        // Штраф берётся с игрока слева от 0 → это игрок 1
        // Максимальное положительное очко игрока 1 (раунды 1 и 2): max(-100, 100) = 100
        XCTAssertEqual(result.premiumPenalties[1], 100)
        
        // Базовые очки (премия вшита в последнюю раздачу)
        XCTAssertEqual(result.baseScores[0], 450)  // 100+100+(150+100)
        XCTAssertEqual(result.baseScores[1], 100)  // -100+100+100
        XCTAssertEqual(result.baseScores[2], 0)    // 50+100-150
        XCTAssertEqual(result.baseScores[3], -150)

        // Последняя раздача P0 увеличена на размер премии
        XCTAssertEqual(result.roundResults[0][2].score, 250)  // 150 + 100
        
        // Итоговые очки
        XCTAssertEqual(result.finalScores[0], 450)
        XCTAssertEqual(result.finalScores[1], 0)    // 100 - 100 штраф
        XCTAssertEqual(result.finalScores[2], 0)    // без изменений
        XCTAssertEqual(result.finalScores[3], -150)
    }

    func testFinalizeBlock_onePremium_penaltyRoundWithEqualScoresChoosesEarliestDeal() {
        let manager = ScoreManager(playerCountProvider: { 4 })

        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 0, 1, 0],
                tricksTaken: [1, 0, 0, 0]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 2,
                bids: [1, 0, 1, 1],
                tricksTaken: [1, 0, 1, 0]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 3,
                bids: [1, 2, 1, 1],
                tricksTaken: [1, 0, 1, 1]
            )
        )

        let result = manager.finalizeBlock(blockNumber: 1)

        XCTAssertEqual(result.premiumPlayerIndices, [0])
        XCTAssertEqual(result.premiumPenalties[1], 50)
        XCTAssertEqual(result.premiumPenaltyRoundIndices[1], 0)
        XCTAssertEqual(result.premiumPenaltyRoundScores[1], 50)

        XCTAssertEqual(result.finalScores[1], result.baseScores[1] - 50)
    }

    func testFinalizeBlock_onePremium_penaltyAppliedToLeftNeighborFromRules() {
        let manager = ScoreManager(playerCountProvider: { 4 })

        // Сценарий из реальной партии (4 раздачи по 9 карт):
        // P0 (Мурад) совпадает во всех раздачах и получает премию.
        // По новым правилам слева от P0 находится P1, значит штраф должен идти в P1.
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 9,
                bids: [2, 3, 2, 3],
                tricksTaken: [2, 2, 1, 4]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 9,
                bids: [2, 2, 3, 3],
                tricksTaken: [2, 2, 2, 3]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 9,
                bids: [0, 3, 3, 2],
                tricksTaken: [0, 6, 3, 0]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 9,
                bids: [2, 2, 2, 2],
                tricksTaken: [2, 2, 5, 0]
            )
        )

        let result = manager.finalizeBlock()

        XCTAssertEqual(result.premiumPlayerIndices, [0])
        XCTAssertEqual(result.premiumBonuses[0], 150)    // max(150, 150, 50)
        XCTAssertEqual(result.roundResults[0][3].score, 300)

        // Штраф только с P1 (слева от P0): max positive P1 на 1..N-1 = max(-100, 150, 60) = 150
        XCTAssertEqual(result.premiumPenalties, [0, 150, 0, 0])
        XCTAssertEqual(result.baseScores, [650, 260, 50, -60])
        XCTAssertEqual(result.finalScores, [650, 110, 50, -60])
    }
    
    // MARK: - Премия: пропуск соседа с премией
    
    func testFinalizeBlock_premiumSkipsNeighborWithPremium() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        
        // Игроки 0 и 3 получают премию
        // Игрок 0: слева — игрок 1 (без премии) → штраф с игрока 1
        // Игрок 3: слева — игрок 0 (премия) → пропуск → игрок 1 → штраф с игрока 1
        
        // Раунд 1 (C=1)
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 0, 1, 0],
                tricksTaken: [1, 0, 0, 0]
            )
        )
        // Раунд 2 (C=2)
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 2,
                bids: [1, 1, 0, 1],
                tricksTaken: [1, 0, 0, 1]
            )
        )
        // Раунд 3 (C=3) — последний
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 3,
                bids: [2, 1, 1, 0],
                tricksTaken: [2, 1, 0, 0]
            )
        )
        
        let result = manager.finalizeBlock()
        
        // Игроки 0 и 3 получают премию
        XCTAssertEqual(Set(result.premiumPlayerIndices), Set([0, 3]))
        
        // Бонус игрока 0: max(100, 100) = 100
        XCTAssertEqual(result.premiumBonuses[0], 100)
        // Бонус игрока 3: max(50, 100) = 100
        XCTAssertEqual(result.premiumBonuses[3], 100)
        
        // Штраф: игрок 0 → слева 1 (без премии) → штраф с игрока 1
        // Игрок 3 → слева 0 (премия) → пропуск → игрок 1 (без премии) → штраф с игрока 1
        // Игрок 1 получает двойной штраф
        // Макс. положительное очко игрока 1 (раунды 1, 2): max(50, -100) = 50
        // Штраф × 2 (от двух премий) = 50 + 50 = 100
        XCTAssertEqual(result.premiumPenalties[1], 100)
        
        // Базовые очки (премии вшиты в последние раздачи)
        XCTAssertEqual(result.baseScores[0], 450)  // 100+100+(150+100)
        XCTAssertEqual(result.baseScores[1], 50)
        XCTAssertEqual(result.baseScores[2], -150)
        XCTAssertEqual(result.baseScores[3], 300)  // 50+100+(50+100)
        
        // Итоговые
        XCTAssertEqual(result.finalScores[0], 450)
        XCTAssertEqual(result.finalScores[1], -50)  // 50 - 100
        XCTAssertEqual(result.finalScores[2], -150)
        XCTAssertEqual(result.finalScores[3], 300)
    }
    
    // MARK: - Общие очки за несколько блоков
    
    func testTotalScores_multipleBlocks() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        
        // Блок 1: простой, без премий
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 1, 1, 0],
                tricksTaken: [1, 0, 0, 0]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 2,
                bids: [1, 0, 1, 1],
                tricksTaken: [0, 1, 1, 0]
            )
        )
        
        manager.finalizeBlock()
        
        let block1Scores = manager.totalScores
        XCTAssertEqual(block1Scores[0], 0)
        XCTAssertEqual(block1Scores[1], -90)
        XCTAssertEqual(block1Scores[2], 0)
        XCTAssertEqual(block1Scores[3], -50)
        
        // Блок 2: ещё раунды
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 3,
                bids: [2, 1, 1, 1],
                tricksTaken: [2, 0, 0, 1]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 3,
                bids: [1, 2, 1, 0],
                tricksTaken: [0, 1, 1, 1]
            )
        )
        
        manager.finalizeBlock()
        
        let totalAfterBlock2 = manager.totalScores
        XCTAssertEqual(totalAfterBlock2[0], 50)
        XCTAssertEqual(totalAfterBlock2[1], -290)
        XCTAssertEqual(totalAfterBlock2[2], 0)
        XCTAssertEqual(totalAfterBlock2[3], 60)
    }
    
    // MARK: - Общие очки с текущим незавершённым блоком
    
    func testTotalScoresIncludingCurrentBlock() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        
        // Завершаем блок 1
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 1, 1, 0],
                tricksTaken: [1, 0, 0, 0]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 2,
                bids: [1, 0, 1, 1],
                tricksTaken: [0, 1, 1, 0]
            )
        )
        manager.finalizeBlock()
        
        // Начинаем блок 2 (незавершённый)
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 3,
                bids: [2, 1, 0, 1],
                tricksTaken: [2, 0, 0, 1]
            )
        )
        
        let scoresWithCurrent = manager.totalScoresIncludingCurrentBlock
        let completedOnly = manager.totalScores
        
        // Общие = завершённые + текущий блок
        XCTAssertEqual(scoresWithCurrent[0], completedOnly[0] + 150)
        XCTAssertEqual(scoresWithCurrent[1], completedOnly[1] - 100)
        XCTAssertEqual(scoresWithCurrent[2], completedOnly[2] + 50)
        XCTAssertEqual(scoresWithCurrent[3], completedOnly[3] + 100)
    }
    
    // MARK: - Победитель
    
    func testGetWinnerIndex() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 1, 1, 0],
                tricksTaken: [1, 0, 0, 0]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 2,
                bids: [1, 0, 1, 1],
                tricksTaken: [1, 1, 0, 0]
            )
        )
        manager.finalizeBlock()
        
        let winner = manager.getWinnerIndex()
        XCTAssertEqual(winner, 0)
    }
    
    // MARK: - Таблица очков
    
    func testGetScoreboard() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 1, 0, 0],
                tricksTaken: [0, 1, 0, 0]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 2,
                bids: [0, 1, 1, 1],
                tricksTaken: [0, 1, 1, 0]
            )
        )
        manager.finalizeBlock()
        
        let scoreboard = manager.getScoreboard()
        
        // Проверяем, что отсортировано по убыванию
        for i in 0..<scoreboard.count - 1 {
            XCTAssertGreaterThanOrEqual(scoreboard[i].score, scoreboard[i + 1].score)
        }
    }
    
    // MARK: - Сброс
    
    func testReset() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 1, 1, 0],
                tricksTaken: [1, 0, 0, 0]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 2,
                bids: [1, 0, 1, 1],
                tricksTaken: [0, 1, 1, 0]
            )
        )
        manager.finalizeBlock()
        
        XCTAssertEqual(manager.completedBlocks.count, 1)
        
        manager.reset()
        
        XCTAssertEqual(manager.completedBlocks.count, 0)
        XCTAssertEqual(manager.totalScores, [0, 0, 0, 0])
        for i in 0..<4 {
            XCTAssertEqual(manager.currentBlockRoundResults[i].count, 0)
        }
    }
    
    // MARK: - Слепая ставка в блоке
    
    func testBlindBidInBlock() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        
        // Раунд 1: игрок 0 ставит в тёмную
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 1, 1, 0],
                tricksTaken: [1, 0, 0, 0],
                blindPlayerIndices: [0]
            )
        )
        // Раунд 2
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 2,
                bids: [1, 0, 1, 1],
                tricksTaken: [1, 1, 0, 0]
            )
        )
        
        let result = manager.finalizeBlock()
        
        // P0 получает премию (все ставки совпали)
        XCTAssertTrue(result.premiumPlayerIndices.contains(0))
        
        // Бонус P0: max(200) = 200 (слепая ставка удваивается и входит в бонус)
        XCTAssertEqual(result.premiumBonuses[0], 200)
        
        // Базовые очки P0: 200 + (100 + 200) = 500
        XCTAssertEqual(result.baseScores[0], 500)
    }
    
    // MARK: - Три игрока
    
    func testThreePlayers_leftNeighbor() {
        let manager = ScoreManager(playerCountProvider: { 3 })

        // Игрок 0 получает премию
        // Слева от 0 → игрок 1 (0+1)%3 = 1
        
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 1, 0],
                tricksTaken: [1, 0, 0]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 2,
                bids: [1, 0, 2],
                tricksTaken: [1, 0, 1]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 3,
                bids: [2, 1, 1],
                tricksTaken: [2, 1, 0]
            )
        )
        
        let result = manager.finalizeBlock()
        
        // Только P0 получает премию
        XCTAssertEqual(result.premiumPlayerIndices, [0])
        
        // Бонус P0: max(100, 100) = 100 (раунды 1, 2; не последний)
        XCTAssertEqual(result.premiumBonuses[0], 100)
        
        // Штраф с P1 (слева от P0): max positive P1 (раунды 1, 2) = max(-100, 50) = 50
        XCTAssertEqual(result.premiumPenalties[1], 50)
        
        // Итого P0: 450
        XCTAssertEqual(result.finalScores[0], 450)
        XCTAssertEqual(result.finalScores[1], 0)
        XCTAssertEqual(result.finalScores[2], -150)
    }
    
    // MARK: - Краевые случаи
    
    func testFinalizeBlock_emptyBlock() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        let result = manager.finalizeBlock()
        
        XCTAssertEqual(result.baseScores, [0, 0, 0, 0])
        XCTAssertEqual(result.finalScores, [0, 0, 0, 0])
        XCTAssertTrue(result.premiumPlayerIndices.isEmpty)
    }
    
    func testFinalizeBlock_singleRound() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        
        // 1 раунд — нет «предпоследнего», бонус = 0
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 1, 1, 1],
                tricksTaken: [1, 0, 0, 0]
            )
        )
        
        let result = manager.finalizeBlock()
        
        XCTAssertEqual(result.premiumPlayerIndices, [0])
        
        // Но бонус = 0 (нет предпоследнего раунда)
        XCTAssertEqual(result.premiumBonuses, [0, 0, 0, 0])
        
        // Штраф тоже 0
        XCTAssertEqual(result.premiumPenalties, [0, 0, 0, 0])
    }
    
    // MARK: - Нулевая премия
    
    func testZeroPremium_block1_eligible() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        
        // Игрок 1 заказывает 0 и берёт 0 во всех раундах
        // Раунд 1 (C=1)
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 0, 1, 0],
                tricksTaken: [1, 0, 0, 0]
            )
        )
        // Раунд 2 (C=2)
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 2,
                bids: [1, 0, 2, 1],
                tricksTaken: [1, 0, 1, 0]
            )
        )
        // Раунд 3 (C=3) — последний
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 3,
                bids: [2, 0, 1, 1],
                tricksTaken: [2, 0, 1, 0]
            )
        )
        
        let result = manager.finalizeBlock(blockNumber: 1)
        
        // P1 получает нулевую премию (всегда bid=0, K=0, блок 1)
        XCTAssertTrue(result.zeroPremiumPlayerIndices.contains(1))
        XCTAssertEqual(result.zeroPremiumBonuses[1], 500)
        
        // P1 базовые: 50+50+(50+500) = 650
        XCTAssertEqual(result.baseScores[1], 650)

        // Последняя раздача P1 увеличена на размер нулевой премии
        XCTAssertEqual(result.roundResults[1][2].score, 550)  // 50 + 500
        
        // P1 НЕ получает обычную премию — только одна из двух
        XCTAssertFalse(result.premiumPlayerIndices.contains(1))
        XCTAssertEqual(result.premiumBonuses[1], 0)
    }
    
    func testZeroPremium_block2_notEligible() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        
        // Тот же сценарий, но блок 2 — нулевая премия не применяется
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 0, 1, 0],
                tricksTaken: [1, 0, 0, 0]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 2,
                bids: [1, 0, 2, 1],
                tricksTaken: [1, 0, 1, 0]
            )
        )
        
        let result = manager.finalizeBlock(blockNumber: 2)
        
        // Нулевая премия не присуждается в блоке 2
        XCTAssertTrue(result.zeroPremiumPlayerIndices.isEmpty)
        XCTAssertEqual(result.zeroPremiumBonuses, [0, 0, 0, 0])
    }
    
    func testZeroPremium_block3_eligible() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        
        // P2 заказывает 0 и берёт 0 во всех раундах блока 3
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 3,
                bids: [1, 1, 0, 2],
                tricksTaken: [1, 2, 0, 0]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 2,
                bids: [2, 1, 0, 0],
                tricksTaken: [2, 0, 0, 0]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 1, 0, 0],
                tricksTaken: [1, 0, 0, 0]
            )
        )
        
        let result = manager.finalizeBlock(blockNumber: 3)
        
        // P2 получает нулевую премию (блок 3)
        XCTAssertTrue(result.zeroPremiumPlayerIndices.contains(2))
        XCTAssertEqual(result.zeroPremiumBonuses[2], 500)
        
        // P2 базовые: 50+50+(50+500) = 650
        XCTAssertEqual(result.baseScores[2], 650)
    }
    
    func testZeroPremium_block4_notEligible() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 0, 1, 0],
                tricksTaken: [1, 0, 0, 0]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 2,
                bids: [1, 0, 2, 1],
                tricksTaken: [1, 0, 1, 0]
            )
        )
        
        let result = manager.finalizeBlock(blockNumber: 4)
        
        // Нулевая премия не присуждается в блоке 4
        XCTAssertTrue(result.zeroPremiumPlayerIndices.isEmpty)
        XCTAssertEqual(result.zeroPremiumBonuses, [0, 0, 0, 0])
    }
    
    func testZeroPremium_playerTookTricks_notEligible() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        
        // P1 заказывает 0, но в одном раунде берёт взятку
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 0, 1, 0],
                tricksTaken: [1, 0, 0, 0]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 2,
                bids: [1, 0, 1, 1],
                tricksTaken: [1, 1, 0, 0]
            )
        )
        
        let result = manager.finalizeBlock(blockNumber: 1)
        
        // P1 не получает нулевую премию — взял взятку во 2-м раунде
        XCTAssertFalse(result.zeroPremiumPlayerIndices.contains(1))
        XCTAssertEqual(result.zeroPremiumBonuses[1], 0)
    }
    
    func testZeroPremium_exclusiveWithRegularPremium() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        
        // P3 заказывает 0 и берёт 0 во всех раундах → нулевая премия
        // P0 все ставки совпали → обычная премия
        // Обе премии защищают от штрафов и штрафуют соседа слева
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 1, 0, 0],
                tricksTaken: [1, 0, 0, 0]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 2,
                bids: [1, 1, 1, 0],
                tricksTaken: [1, 1, 0, 0]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 3,
                bids: [2, 1, 1, 0],
                tricksTaken: [2, 0, 1, 0]
            )
        )
        
        let result = manager.finalizeBlock(blockNumber: 1)
        
        // P3 получает нулевую премию (бонус 500)
        XCTAssertTrue(result.zeroPremiumPlayerIndices.contains(3))
        XCTAssertEqual(result.zeroPremiumBonuses[3], 500)
        
        // P3 НЕ получает обычную премию — только одну из двух
        XCTAssertFalse(result.premiumPlayerIndices.contains(3))
        XCTAssertEqual(result.premiumBonuses[3], 0)
        
        // P0 получает обычную премию
        XCTAssertTrue(result.premiumPlayerIndices.contains(0))
        XCTAssertFalse(result.zeroPremiumPlayerIndices.contains(0))
        
        // P3 защищён от штрафов (нулевая премия тоже защищает)
        // P0 штраф → слева P1 (без премии) → штраф с P1
        // P3 штраф → слева P0 (защищён) → пропуск → P1 (без премии) → штраф с P1
        // P1 получает двойной штраф
        // P1 очки за раунды 1,2: [-100, 100]. Max positive = 100. Штраф = 100 × 2 = 200
        XCTAssertEqual(result.premiumPenalties[1], 200)
        XCTAssertEqual(result.premiumPenalties[3], 0)
        
        // Базовые очки (премии вшиты в последние раздачи)
        XCTAssertEqual(result.baseScores[0], 450)  // 100+100+(150+100)
        XCTAssertEqual(result.baseScores[1], -100)
        XCTAssertEqual(result.baseScores[2], 50)
        XCTAssertEqual(result.baseScores[3], 650)  // 50+50+(50+500)
        
        // P0 итого: 450
        XCTAssertEqual(result.finalScores[0], 450)
        XCTAssertEqual(result.finalScores[1], -300)
        XCTAssertEqual(result.finalScores[2], 50)
        // P3 итого: 650
        XCTAssertEqual(result.finalScores[3], 650)
    }
    
    func testZeroPremium_noBlockNumber_notApplied() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 0, 1, 0],
                tricksTaken: [1, 0, 0, 0]
            )
        )
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 2,
                bids: [1, 0, 2, 1],
                tricksTaken: [1, 0, 1, 0]
            )
        )
        
        // Без blockNumber — нулевая премия не применяется
        let result = manager.finalizeBlock()
        
        XCTAssertTrue(result.zeroPremiumPlayerIndices.isEmpty)
        XCTAssertEqual(result.zeroPremiumBonuses, [0, 0, 0, 0])
    }
    
    // MARK: - Интеграционный тест: полный блок 4 игрока
    
    func testIntegration_fullBlock_4players() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        
        // Симулируем блок из 4 раундов
        // Раунд 1 (C=1): P0=100, P1=50, P2=50, P3=-100
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 1,
                bids: [1, 1, 0, 1],
                tricksTaken: [1, 0, 0, 0]
            )
        )
        // Раунд 2 (C=2): P0=200(V=C), P1=100, P2=-200(V=C,K=0), P3=50
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 2,
                bids: [2, 1, 2, 0],
                tricksTaken: [2, 0, 0, 0]
            )
        )
        // Раунд 3 (C=3): P0=200, P1=-100, P2=100, P3=50
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 3,
                bids: [2, 1, 1, 1],
                tricksTaken: [2, 1, 0, 0]
            )
        )
        // Раунд 4 (C=4) — последний: P0=100, P1=50, P2=50, P3=50
        manager.recordRoundResults(
            validRoundResults(
                cardsInRound: 4,
                bids: [0, 2, 1, 2],
                tricksTaken: [0, 2, 0, 2]
            )
        )
        
        let result = manager.finalizeBlock()
        
        // P0 совпал во всех раундах → премия
        XCTAssertTrue(result.premiumPlayerIndices.contains(0))
        
        // P0 базовые: 100 + 200 + 150 + (50 + 200) = 700
        XCTAssertEqual(result.baseScores[0], 700)
        
        // P0 бонус: max(100, 200, 150) = 200 (раунды 1-3, исключая последний)
        XCTAssertEqual(result.premiumBonuses[0], 200)
        
        // Штраф с P1 (слева от P0): max positive P1 (раунды 1-3) = max(50, 100, -100) = 100
        XCTAssertEqual(result.premiumPenalties[1], 100)
        
        // P0 итог: 700
        XCTAssertEqual(result.finalScores[0], 700)
    }
}
