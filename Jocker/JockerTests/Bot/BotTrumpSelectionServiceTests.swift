//
//  BotTrumpSelectionServiceTests.swift
//  JockerTests
//
//  Created by Codex on 15.02.2026.
//

import XCTest
@testable import Jocker

final class BotTrumpSelectionServiceTests: XCTestCase {
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

    func testSelectTrump_returnsNilWhenNoRegularCards() {
        let service = BotTrumpSelectionService()
        let hand: [Card] = [.joker, .joker]

        let trump = service.selectTrump(from: hand)

        XCTAssertNil(trump)
    }

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
}
