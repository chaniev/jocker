//
//  BotTrumpSelectionServiceTests.swift
//  JockerTests
//
//  Created by Codex on 15.02.2026.
//

import XCTest
@testable import Jocker

final class BotTrumpSelectionServiceTests: XCTestCase {
    /// Тестирует, что бот предпочитает сильную single suit для trump.
    /// Проверяет:
    /// - Рука с 3 diamonds + joker выбирает diamonds
    func testSelectTrump_prefersStrongSingleSuit() {
        let service = BotTrumpSelectionService()
        let hand: [Card] = [
            .regular(suit: .diamonds, rank: .ace),
            .regular(suit: .diamonds, rank: .king),
            .regular(suit: .diamonds, rank: .ten),
            .joker
        ]

        let trump = service.selectTrump(from: hand)

        XCTAssertEqual(trump, .diamonds)
    }

    /// Тестирует, что бот возвращает nil для слабой scattered руки.
    /// Проверяет:
    /// - Рука с разбросанными мелкими картами не выбирает trump
    func testSelectTrump_returnsNilForWeakScatteredHand() {
        let service = BotTrumpSelectionService()
        let hand: [Card] = [
            .regular(suit: .diamonds, rank: .seven),
            .regular(suit: .hearts, rank: .eight),
            .regular(suit: .clubs, rank: .seven),
            .joker
        ]

        let trump = service.selectTrump(from: hand)

        XCTAssertNil(trump)
    }

    /// Тестирует, что бот возвращает nil когда нет regular карт.
    /// Проверяет:
    /// - Рука только с джокерами не выбирает trump
    func testSelectTrump_returnsNilWhenNoRegularCards() {
        let service = BotTrumpSelectionService()
        let hand: [Card] = [.joker, .joker]

        let trump = service.selectTrump(from: hand)

        XCTAssertNil(trump)
    }

    /// Тестирует, что на этапе player choice stage бот предпочитает 2 из 3 same suit.
    /// Проверяет:
    /// - Рука с 2 hearts + 1 club выбирает hearts (с бонусом player choice)
    func testSelectTrump_playerChoiceStageBonus_prefersTwoOfThreeSameSuit() {
        let service = BotTrumpSelectionService()
        let hand: [Card] = [
            .regular(suit: .hearts, rank: .seven),
            .regular(suit: .hearts, rank: .eight),
            .regular(suit: .clubs, rank: .seven)
        ]

        let trump = service.selectTrump(
            from: hand,
            isPlayerChosenTrumpStage: true
        )

        XCTAssertEqual(trump, .hearts)
    }

    /// Тестирует, что без player choice stage bonus та же рука возвращает nil.
    /// Проверяет:
    /// - Рука с 2 hearts + 1 club не выбирает trump (без бонуса)
    func testSelectTrump_withoutPlayerChoiceStageBonus_sameHandReturnsNil() {
        let service = BotTrumpSelectionService()
        let hand: [Card] = [
            .regular(suit: .hearts, rank: .seven),
            .regular(suit: .hearts, rank: .eight),
            .regular(suit: .clubs, rank: .seven)
        ]

        let trump = service.selectTrump(
            from: hand,
            isPlayerChosenTrumpStage: false
        )

        XCTAssertNil(trump)
    }

    /// Тестирует multi-factor sequence и joker synergy для выбора trump.
    /// Проверяет:
    /// - Рука с AKQ spades + joker выбирает spades (control suit)
    func testSelectTrump_multifactorSequenceAndJokerSynergy_prefersControlSuit() {
        let service = BotTrumpSelectionService(tuning: BotTuning(difficulty: .hard))
        let hand: [Card] = [
            .joker,
            .regular(suit: .spades, rank: .ace),
            .regular(suit: .spades, rank: .king),
            .regular(suit: .spades, rank: .queen),
            .regular(suit: .hearts, rank: .ace),
            .regular(suit: .hearts, rank: .seven)
        ]

        let trump = service.selectTrump(from: hand)

        XCTAssertEqual(trump, .spades)
    }
}
