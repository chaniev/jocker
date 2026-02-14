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
    
    @MainActor
    func testSubtotalRowDisplaysScoresDividedByTen() {
        let manager = ScoreManager(playerCountProvider: { 4 })
        manager.recordRoundResults([
            makeRoundResult(cardsInRound: 2, bid: 2, tricksTaken: 2),   // 200 -> 20
            makeRoundResult(cardsInRound: 2, bid: 2, tricksTaken: 0),   // -200 -> -20
            makeRoundResult(cardsInRound: 2, bid: 1, tricksTaken: 1),   // 100 -> 10
            makeRoundResult(cardsInRound: 2, bid: 0, tricksTaken: 0)    // 50 -> 5
        ])
        
        let tableView = ScoreTableView(playerCount: 4)
        tableView.frame = CGRect(x: 0, y: 0, width: 420, height: 700)
        tableView.layoutIfNeeded()
        tableView.update(with: manager)
        
        let subtotalRowIndex = 8
        XCTAssertEqual(displayedPoints(at: subtotalRowIndex, in: tableView), ["20", "-20", "10", "5"])
    }
    
    @MainActor
    func testCumulativeRowDisplaysScoresDividedByTen() {
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
        // Кумулятивные очки: [300, -150, -50, 200] -> [30, -15, -5, 20].
        let cumulativeRowIndex = 14
        XCTAssertEqual(displayedPoints(at: cumulativeRowIndex, in: tableView), ["30", "-15", "-5", "20"])
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
