//
//  JockerTests.swift
//  JockerTests
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import XCTest
import UIKit
@testable import Jocker

final class JockerTests: XCTestCase {
    func testBotDifficultyRawValuesAndCaseOrder() {
        XCTAssertEqual(BotDifficulty.easy.rawValue, "easy")
        XCTAssertEqual(BotDifficulty.normal.rawValue, "normal")
        XCTAssertEqual(BotDifficulty.hard.rawValue, "hard")
        XCTAssertEqual(BotDifficulty.allCases, [.easy, .normal, .hard])
    }

    func testBotDifficultyInitializationFromRawValue() {
        XCTAssertEqual(BotDifficulty(rawValue: "easy"), .easy)
        XCTAssertEqual(BotDifficulty(rawValue: "normal"), .normal)
        XCTAssertEqual(BotDifficulty(rawValue: "hard"), .hard)
        XCTAssertNil(BotDifficulty(rawValue: "legendary"))
    }

    func testBlockResultStoresProvidedValues() {
        let roundsPlayer0 = [
            RoundResult(cardsInRound: 1, bid: 1, tricksTaken: 1, isBlind: false),
            RoundResult(cardsInRound: 2, bid: 0, tricksTaken: 0, isBlind: true),
        ]
        let roundsPlayer1 = [
            RoundResult(cardsInRound: 1, bid: 0, tricksTaken: 1, isBlind: false),
            RoundResult(cardsInRound: 2, bid: 2, tricksTaken: 1, isBlind: false),
        ]

        let result = BlockResult(
            roundResults: [roundsPlayer0, roundsPlayer1],
            baseScores: [150, -50],
            premiumPlayerIndices: [0],
            premiumBonuses: [100, 0],
            premiumPenalties: [0, 100],
            zeroPremiumPlayerIndices: [1],
            zeroPremiumBonuses: [0, 500],
            finalScores: [250, 350]
        )

        XCTAssertEqual(result.roundResults.count, 2)
        XCTAssertEqual(result.roundResults[0].count, 2)
        XCTAssertEqual(result.roundResults[0][0].bid, 1)
        XCTAssertTrue(result.roundResults[0][1].isBlind)
        XCTAssertEqual(result.roundResults[1][1].tricksTaken, 1)

        XCTAssertEqual(result.baseScores, [150, -50])
        XCTAssertEqual(result.premiumPlayerIndices, [0])
        XCTAssertEqual(result.premiumBonuses, [100, 0])
        XCTAssertEqual(result.premiumPenalties, [0, 100])
        XCTAssertEqual(result.zeroPremiumPlayerIndices, [1])
        XCTAssertEqual(result.zeroPremiumBonuses, [0, 500])
        XCTAssertEqual(result.finalScores, [250, 350])
    }

    func testTrickNodeSimulationMode_tracksCardsWithoutRenderingNodes() {
        let trickNode = TrickNode(rendersCards: false)

        _ = trickNode.playCard(
            .regular(suit: .hearts, rank: .queen),
            fromPlayer: 1,
            animated: false
        )
        _ = trickNode.playCard(
            .regular(suit: .hearts, rank: .king),
            fromPlayer: 2,
            animated: false
        )

        XCTAssertEqual(trickNode.playedCards.count, 2)
        XCTAssertEqual(trickNode.children.count, 0)
        XCTAssertEqual(trickNode.determineWinner(trump: nil), 2)

        var didCompleteClear = false
        trickNode.clearTrick(toPosition: .zero, animated: false) {
            didCompleteClear = true
        }

        XCTAssertTrue(didCompleteClear)
        XCTAssertTrue(trickNode.playedCards.isEmpty)
        XCTAssertEqual(trickNode.children.count, 0)
    }

    func testTrickNodeDefaultMode_keepsRenderingBehavior() {
        let trickNode = TrickNode()

        _ = trickNode.playCard(
            .regular(suit: .clubs, rank: .ace),
            fromPlayer: 1,
            animated: false
        )

        XCTAssertEqual(trickNode.playedCards.count, 1)
        XCTAssertEqual(trickNode.children.count, 1)
    }

    @MainActor
    func testSubtotalRowDisplaysScoresDividedByHundredWithOneFractionDigit() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        manager.recordRoundResults([
            makeRoundResult(cardsInRound: 2, bid: 2, tricksTaken: 2),   // 200 -> 2,0
            makeRoundResult(cardsInRound: 2, bid: 2, tricksTaken: 0),   // -200 -> -2,0
            makeRoundResult(cardsInRound: 2, bid: 1, tricksTaken: 1),   // 100 -> 1,0
            makeRoundResult(cardsInRound: 2, bid: 0, tricksTaken: 0)    // 50 -> 0,5
        ])
        
        let tableView = ScoreTableView(playerCount: 4)
        tableView.frame = CGRect(x: 0, y: 0, width: 420, height: 700)
        tableView.layoutIfNeeded()
        tableView.update(with: manager)
        
        let subtotalRowIndex = 8
        XCTAssertEqual(displayedPoints(at: subtotalRowIndex, in: tableView), ["2,0", "-2,0", "1,0", "0,5"])
    }
    
    @MainActor
    func testCumulativeRowDisplaysScoresDividedByHundredWithOneFractionDigit() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        
        manager.recordRoundResults([
            makeRoundResult(cardsInRound: 2, bid: 2, tricksTaken: 2),   // 200
            makeRoundResult(cardsInRound: 2, bid: 2, tricksTaken: 0),   // -200
            makeRoundResult(cardsInRound: 2, bid: 1, tricksTaken: 1),   // 100
            makeRoundResult(cardsInRound: 2, bid: 0, tricksTaken: 0)    // 50
        ])
        manager.finalizeBlock()
        
        manager.recordRoundResults([
            makeRoundResult(cardsInRound: 3, bid: 1, tricksTaken: 1),   // +100
            makeRoundResult(cardsInRound: 3, bid: 0, tricksTaken: 0),   // +50
            makeRoundResult(cardsInRound: 3, bid: 2, tricksTaken: 0),   // -150
            makeRoundResult(cardsInRound: 3, bid: 2, tricksTaken: 2)    // +150
        ])
        
        let tableView = ScoreTableView(playerCount: 4)
        tableView.frame = CGRect(x: 0, y: 0, width: 420, height: 700)
        tableView.layoutIfNeeded()
        tableView.update(with: manager)
        
        // Блок 2: subtotal = row 13, cumulative = row 14.
        // Кумулятивные очки: [300, -150, -50, 200] -> [3,0, -1,5, -0,5, 2,0].
        let cumulativeRowIndex = 14
        XCTAssertEqual(displayedPoints(at: cumulativeRowIndex, in: tableView), ["3,0", "-1,5", "-0,5", "2,0"])
    }
    
    private func makeRoundResult(cardsInRound: Int, bid: Int, tricksTaken: Int) -> RoundResult {
        return RoundResult(cardsInRound: cardsInRound, bid: bid, tricksTaken: tricksTaken, isBlind: false)
    }
    
    private func displayedPoints(at rowIndex: Int, in tableView: ScoreTableView) -> [String] {
        guard let pointsLabels = Mirror(reflecting: tableView).descendant("pointsLabels") as? [[UILabel]] else {
            XCTFail("Не удалось получить pointsLabels из ScoreTableView")
            return []
        }
        
        guard pointsLabels.indices.contains(rowIndex) else {
            XCTFail("Индекс строки \(rowIndex) вне диапазона")
            return []
        }
        
        return pointsLabels[rowIndex].map { $0.text ?? "" }
    }
}
