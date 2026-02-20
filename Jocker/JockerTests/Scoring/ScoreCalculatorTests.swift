//
//  ScoreCalculatorTests.swift
//  JockerTests
//
//  Created by Чаниев Мурад on 08.02.2026.
//

import XCTest
@testable import Jocker

final class ScoreCalculatorTests: XCTestCase {
    
    // MARK: - K = V, V ≠ C → K×50 + 50
    
    func testBidMatchedNotAllCards_zeroTricks() {
        // V=0, K=0, C=3 → 0×50+50 = 50
        let score = ScoreCalculator.calculateRoundScore(
            cardsInRound: 3, bid: 0, tricksTaken: 0, isBlind: false
        )
        XCTAssertEqual(score, 50)
    }
    
    func testBidMatchedNotAllCards_oneTrick() {
        // V=1, K=1, C=3 → 1×50+50 = 100
        let score = ScoreCalculator.calculateRoundScore(
            cardsInRound: 3, bid: 1, tricksTaken: 1, isBlind: false
        )
        XCTAssertEqual(score, 100)
    }
    
    func testBidMatchedNotAllCards_multipleTricks() {
        // V=3, K=3, C=5 → 3×50+50 = 200
        let score = ScoreCalculator.calculateRoundScore(
            cardsInRound: 5, bid: 3, tricksTaken: 3, isBlind: false
        )
        XCTAssertEqual(score, 200)
    }
    
    // MARK: - K = V = C → K×100
    
    func testBidMatchedAllCards_oneCard() {
        // V=1, K=1, C=1 → 1×100 = 100
        let score = ScoreCalculator.calculateRoundScore(
            cardsInRound: 1, bid: 1, tricksTaken: 1, isBlind: false
        )
        XCTAssertEqual(score, 100)
    }
    
    func testBidMatchedAllCards_multipleCards() {
        // V=5, K=5, C=5 → 5×100 = 500
        let score = ScoreCalculator.calculateRoundScore(
            cardsInRound: 5, bid: 5, tricksTaken: 5, isBlind: false
        )
        XCTAssertEqual(score, 500)
    }
    
    func testBidMatchedAllCards_maxCards() {
        // V=8, K=8, C=8 → 8×100 = 800
        let score = ScoreCalculator.calculateRoundScore(
            cardsInRound: 8, bid: 8, tricksTaken: 8, isBlind: false
        )
        XCTAssertEqual(score, 800)
    }
    
    // MARK: - K > V → K×10
    
    func testTookMoreThanBid_oneExtra() {
        // V=2, K=3, C=5 → 3×10 = 30
        let score = ScoreCalculator.calculateRoundScore(
            cardsInRound: 5, bid: 2, tricksTaken: 3, isBlind: false
        )
        XCTAssertEqual(score, 30)
    }
    
    func testTookMoreThanBid_bidZero() {
        // V=0, K=2, C=5 → 2×10 = 20
        let score = ScoreCalculator.calculateRoundScore(
            cardsInRound: 5, bid: 0, tricksTaken: 2, isBlind: false
        )
        XCTAssertEqual(score, 20)
    }
    
    func testTookMoreThanBid_manyExtra() {
        // V=1, K=6, C=8 → 6×10 = 60
        let score = ScoreCalculator.calculateRoundScore(
            cardsInRound: 8, bid: 1, tricksTaken: 6, isBlind: false
        )
        XCTAssertEqual(score, 60)
    }
    
    // MARK: - K < V → -(V-K)×50 - 50
    
    func testTookLessThanBid_oneDeficit() {
        // V=3, K=2, C=5 → -(3-2)×50-50 = -100
        let score = ScoreCalculator.calculateRoundScore(
            cardsInRound: 5, bid: 3, tricksTaken: 2, isBlind: false
        )
        XCTAssertEqual(score, -100)
    }
    
    func testTookLessThanBid_largeDeficit() {
        // V=5, K=1, C=8 → -(5-1)×50-50 = -250
        let score = ScoreCalculator.calculateRoundScore(
            cardsInRound: 8, bid: 5, tricksTaken: 1, isBlind: false
        )
        XCTAssertEqual(score, -250)
    }
    
    func testTookLessThanBid_tookNone() {
        // V=2, K=0, C=5 → -(2-0)×50-50 = -150
        let score = ScoreCalculator.calculateRoundScore(
            cardsInRound: 5, bid: 2, tricksTaken: 0, isBlind: false
        )
        XCTAssertEqual(score, -150)
    }
    
    // MARK: - K = 0 и V = C → -V×100
    
    func testBidAllCardsTookNone_oneCard() {
        // V=1, K=0, C=1 → -1×100 = -100
        let score = ScoreCalculator.calculateRoundScore(
            cardsInRound: 1, bid: 1, tricksTaken: 0, isBlind: false
        )
        XCTAssertEqual(score, -100)
    }
    
    func testBidAllCardsTookNone_multipleCards() {
        // V=5, K=0, C=5 → -5×100 = -500
        let score = ScoreCalculator.calculateRoundScore(
            cardsInRound: 5, bid: 5, tricksTaken: 0, isBlind: false
        )
        XCTAssertEqual(score, -500)
    }
    
    func testBidAllCardsTookNone_maxCards() {
        // V=8, K=0, C=8 → -8×100 = -800
        let score = ScoreCalculator.calculateRoundScore(
            cardsInRound: 8, bid: 8, tricksTaken: 0, isBlind: false
        )
        XCTAssertEqual(score, -800)
    }
    
    // MARK: - Ставка «в тёмную» — очки удваиваются
    
    func testBlindBid_positive() {
        // V=2, K=2, C=5, blind → (2×50+50)×2 = 300
        let score = ScoreCalculator.calculateRoundScore(
            cardsInRound: 5, bid: 2, tricksTaken: 2, isBlind: true
        )
        XCTAssertEqual(score, 300)
    }
    
    func testBlindBid_negative() {
        // V=3, K=1, C=5, blind → (-(3-1)×50-50)×2 = -300
        let score = ScoreCalculator.calculateRoundScore(
            cardsInRound: 5, bid: 3, tricksTaken: 1, isBlind: true
        )
        XCTAssertEqual(score, -300)
    }
    
    func testBlindBid_allCards() {
        // V=3, K=3, C=3, blind → (3×100)×2 = 600
        let score = ScoreCalculator.calculateRoundScore(
            cardsInRound: 3, bid: 3, tricksTaken: 3, isBlind: true
        )
        XCTAssertEqual(score, 600)
    }
    
    func testBlindBid_tookMore() {
        // V=1, K=3, C=5, blind → (3×10)×2 = 60
        let score = ScoreCalculator.calculateRoundScore(
            cardsInRound: 5, bid: 1, tricksTaken: 3, isBlind: true
        )
        XCTAssertEqual(score, 60)
    }
    
    func testBlindBid_bidAllTookNone() {
        // V=4, K=0, C=4, blind → (-4×100)×2 = -800
        let score = ScoreCalculator.calculateRoundScore(
            cardsInRound: 4, bid: 4, tricksTaken: 0, isBlind: true
        )
        XCTAssertEqual(score, -800)
    }
    
    // MARK: - RoundResult
    
    func testRoundResult_scoreComputed() {
        let result = RoundResult(cardsInRound: 5, bid: 2, tricksTaken: 2, isBlind: false)
        XCTAssertEqual(result.score, 150)
        XCTAssertTrue(result.bidMatched)
    }
    
    func testRoundResult_bidNotMatched() {
        let result = RoundResult(cardsInRound: 5, bid: 3, tricksTaken: 1, isBlind: false)
        XCTAssertFalse(result.bidMatched)
        XCTAssertEqual(result.score, -150)
    }
    
    // MARK: - Премиальный бонус
    
    func testPremiumBonus_normalCase() {
        // Раунды: [50, 100, 200, 150]
        // Исключаем последний → [50, 100, 200] → max = 200
        let bonus = ScoreCalculator.calculatePremiumBonus(roundScores: [50, 100, 200, 150])
        XCTAssertEqual(bonus, 200)
    }
    
    func testPremiumBonus_twoRounds() {
        // Раунды: [100, 50]
        // Исключаем последний → [100] → max = 100
        let bonus = ScoreCalculator.calculatePremiumBonus(roundScores: [100, 50])
        XCTAssertEqual(bonus, 100)
    }
    
    func testPremiumBonus_oneRound() {
        // Только 1 раунд — нет предпоследней раздачи
        let bonus = ScoreCalculator.calculatePremiumBonus(roundScores: [100])
        XCTAssertEqual(bonus, 0)
    }
    
    func testPremiumBonus_emptyRounds() {
        let bonus = ScoreCalculator.calculatePremiumBonus(roundScores: [])
        XCTAssertEqual(bonus, 0)
    }
    
    // MARK: - Премиальный штраф
    
    func testPremiumPenalty_normalCase() {
        // Раунды: [50, -100, 200, 150]
        // Исключаем последний → [50, -100, 200] → max positive = 200
        let penalty = ScoreCalculator.calculatePremiumPenalty(roundScores: [50, -100, 200, 150])
        XCTAssertEqual(penalty, 200)
    }
    
    func testPremiumPenalty_allNegative() {
        // Раунды: [-50, -100, -200, 150]
        // Исключаем последний → [-50, -100, -200] → нет положительных → 0
        let penalty = ScoreCalculator.calculatePremiumPenalty(roundScores: [-50, -100, -200, 150])
        XCTAssertEqual(penalty, 0)
    }
    
    func testPremiumPenalty_onePositive() {
        // Раунды: [-50, 100, -200, 150]
        // Исключаем последний → [-50, 100, -200] → max positive = 100
        let penalty = ScoreCalculator.calculatePremiumPenalty(roundScores: [-50, 100, -200, 150])
        XCTAssertEqual(penalty, 100)
    }
    
    func testPremiumPenalty_oneRound() {
        let penalty = ScoreCalculator.calculatePremiumPenalty(roundScores: [100])
        XCTAssertEqual(penalty, 0)
    }
    
    // MARK: - Нулевая премия
    
    func testZeroPremiumAmount() {
        XCTAssertEqual(ScoreCalculator.zeroPremiumAmount, 500)
    }
    
    func testZeroPremiumEligible_allZeros() {
        let results = [
            RoundResult(cardsInRound: 1, bid: 0, tricksTaken: 0, isBlind: false),
            RoundResult(cardsInRound: 2, bid: 0, tricksTaken: 0, isBlind: false),
            RoundResult(cardsInRound: 3, bid: 0, tricksTaken: 0, isBlind: false)
        ]
        XCTAssertTrue(ScoreCalculator.isZeroPremiumEligible(roundResults: results))
    }
    
    func testZeroPremiumEligible_bidNonZero() {
        // Один раунд с bid != 0 — не подходит
        let results = [
            RoundResult(cardsInRound: 1, bid: 0, tricksTaken: 0, isBlind: false),
            RoundResult(cardsInRound: 2, bid: 1, tricksTaken: 1, isBlind: false),
            RoundResult(cardsInRound: 3, bid: 0, tricksTaken: 0, isBlind: false)
        ]
        XCTAssertFalse(ScoreCalculator.isZeroPremiumEligible(roundResults: results))
    }
    
    func testZeroPremiumEligible_tookTricks() {
        // Заказал 0, но взял взятки — не подходит
        let results = [
            RoundResult(cardsInRound: 1, bid: 0, tricksTaken: 0, isBlind: false),
            RoundResult(cardsInRound: 2, bid: 0, tricksTaken: 1, isBlind: false),
            RoundResult(cardsInRound: 3, bid: 0, tricksTaken: 0, isBlind: false)
        ]
        XCTAssertFalse(ScoreCalculator.isZeroPremiumEligible(roundResults: results))
    }
    
    func testZeroPremiumEligible_emptyResults() {
        XCTAssertFalse(ScoreCalculator.isZeroPremiumEligible(roundResults: []))
    }
    
    func testZeroPremiumEligible_singleRound() {
        let results = [
            RoundResult(cardsInRound: 1, bid: 0, tricksTaken: 0, isBlind: false)
        ]
        XCTAssertTrue(ScoreCalculator.isZeroPremiumEligible(roundResults: results))
    }
}
