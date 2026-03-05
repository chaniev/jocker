//
//  BotHandStrengthModelTests.swift
//  JockerTests
//
//  Created by Codex on 05.03.2026.
//

import XCTest
@testable import Jocker

final class BotHandStrengthModelTests: XCTestCase {
    private let model = BotHandStrengthModel(tuning: BotTuning(difficulty: .hard))

    /// Тестирует, что более сильная рука получает более высокую оценку ожидаемых взяток.
    /// Проверяет:
    /// - Слабая рука с мелкими картами получает низкую оценку
    /// - Сильная рука с джокером и тузами получает высокую оценку
    func testBiddingExpectedTricks_strongerHandProducesHigherEstimate() {
        let weakHand: [Card] = [
            card(.diamonds, .six),
            card(.clubs, .seven),
            card(.spades, .eight),
            card(.hearts, .nine)
        ]
        let strongHand: [Card] = [
            .joker,
            card(.hearts, .ace),
            card(.hearts, .king),
            card(.hearts, .queen)
        ]

        let weakEstimate = model.biddingExpectedTricks(
            hand: weakHand,
            cardsInRound: 4,
            trump: .hearts
        )
        let strongEstimate = model.biddingExpectedTricks(
            hand: strongHand,
            cardsInRound: 4,
            trump: .hearts
        )

        XCTAssertGreaterThan(strongEstimate, weakEstimate)
    }

    /// Тестирует projected future tricks для trump-dense руки против scattered руки.
    /// Проверяет:
    /// - Плотная trump-рука (5 spades) получает более высокую проекцию
    /// - Разбросанная рука получает более низкую проекцию
    func testProjectedFutureTricks_withTrumpDenseHand_isHigherThanScatteredHand() {
        let denseHand: [Card] = [
            card(.spades, .ace),
            card(.spades, .king),
            card(.spades, .queen),
            card(.spades, .jack),
            card(.clubs, .seven)
        ]
        let scatteredHand: [Card] = [
            card(.spades, .ace),
            card(.hearts, .king),
            card(.clubs, .queen),
            card(.diamonds, .jack),
            card(.clubs, .seven)
        ]

        let denseProjection = model.projectedFutureTricks(
            hand: denseHand,
            trump: .spades
        )
        let scatteredProjection = model.projectedFutureTricks(
            hand: scatteredHand,
            trump: .spades
        )

        XCTAssertGreaterThan(denseProjection, scatteredProjection)
    }

    /// Тестирует, что trump hand summary правильно определяет sequence strength.
    /// Проверяет:
    /// - Рука с последовательностью AKQ получает высокую sequenceStrength
    /// - Рука без последовательности получает низкую sequenceStrength
    func testTrumpHandSummary_sequenceStrength_detectsConsecutiveRun() {
        let sequenceHand: [Card] = [
            card(.hearts, .ace),
            card(.hearts, .king),
            card(.hearts, .queen),
            card(.clubs, .seven)
        ]
        let nonSequenceHand: [Card] = [
            card(.hearts, .ace),
            card(.hearts, .ten),
            card(.hearts, .seven),
            card(.clubs, .seven)
        ]

        let sequenceSummary = model.trumpHandSummary(hand: sequenceHand)
        let nonSequenceSummary = model.trumpHandSummary(hand: nonSequenceHand)

        let sequenceStrength = sequenceSummary.suitProfiles[.hearts]?.sequenceStrength ?? 0.0
        let nonSequenceStrength = nonSequenceSummary.suitProfiles[.hearts]?.sequenceStrength ?? 0.0
        XCTAssertGreaterThan(sequenceStrength, nonSequenceStrength)
    }

    private func card(_ suit: Suit, _ rank: Rank) -> Card {
        return .regular(suit: suit, rank: rank)
    }
}
