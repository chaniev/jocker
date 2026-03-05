//
//  HandFeatureExtractorTests.swift
//  JockerTests
//
//  Created by Codex on 05.03.2026.
//

import XCTest
@testable import Jocker

final class HandFeatureExtractorTests: XCTestCase {
    private let extractor = HandFeatureExtractor()

    func testExtract_fromEmptyHand_returnsZeroFeatures() {
        let features = extractor.extract(from: [])

        XCTAssertTrue(features.regularCards.isEmpty)
        XCTAssertTrue(features.suitCounts.isEmpty)
        XCTAssertEqual(features.jokerCount, 0)
        XCTAssertEqual(features.highCardCount, 0)
        XCTAssertEqual(features.regularCardsCount, 0)
        XCTAssertEqual(features.longestSuitCount, 0)
    }

    func testExtract_fromJokersOnly_countsOnlyJokers() {
        let features = extractor.extract(from: [.joker, .joker])

        XCTAssertTrue(features.regularCards.isEmpty)
        XCTAssertTrue(features.suitCounts.isEmpty)
        XCTAssertEqual(features.jokerCount, 2)
        XCTAssertEqual(features.highCardCount, 0)
    }

    func testExtract_fromRegularCards_countsSuitsAndRegularCards() {
        let hand: [Card] = [
            card(.hearts, .seven),
            card(.hearts, .ace),
            card(.clubs, .ten),
            card(.spades, .queen)
        ]

        let features = extractor.extract(from: hand)

        XCTAssertEqual(features.regularCardsCount, 4)
        XCTAssertEqual(features.suitCounts[.hearts], 2)
        XCTAssertEqual(features.suitCounts[.clubs], 1)
        XCTAssertEqual(features.suitCounts[.spades], 1)
        XCTAssertEqual(features.jokerCount, 0)
    }

    func testExtract_highCardCount_countsOnlyQueenKingAce() {
        let hand: [Card] = [
            card(.hearts, .jack),
            card(.hearts, .queen),
            card(.clubs, .king),
            card(.spades, .ace),
            card(.diamonds, .ten)
        ]

        let features = extractor.extract(from: hand)

        XCTAssertEqual(features.highCardCount, 3)
    }

    func testExtract_longestSuitCount_returnsMaxSuitLength() {
        let hand: [Card] = [
            card(.hearts, .six),
            card(.hearts, .seven),
            card(.hearts, .eight),
            card(.clubs, .ace),
            card(.spades, .king)
        ]

        let features = extractor.extract(from: hand)

        XCTAssertEqual(features.longestSuitCount, 3)
    }

    func testExtract_mixedHand_combinesRegularAndJokerFeatures() {
        let hand: [Card] = [
            .joker,
            card(.diamonds, .ace),
            card(.diamonds, .king),
            card(.spades, .seven)
        ]

        let features = extractor.extract(from: hand)

        XCTAssertEqual(features.jokerCount, 1)
        XCTAssertEqual(features.regularCardsCount, 3)
        XCTAssertEqual(features.suitCounts[.diamonds], 2)
        XCTAssertEqual(features.suitCounts[.spades], 1)
        XCTAssertEqual(features.highCardCount, 2)
    }

    func testExtract_duplicateCards_countsEachOccurrence() {
        let hand: [Card] = [
            card(.hearts, .queen),
            card(.hearts, .queen),
            .joker
        ]

        let features = extractor.extract(from: hand)

        XCTAssertEqual(features.regularCardsCount, 2)
        XCTAssertEqual(features.suitCounts[.hearts], 2)
        XCTAssertEqual(features.highCardCount, 2)
        XCTAssertEqual(features.jokerCount, 1)
    }

    func testExtract_allSuitsRepresented_tracksEachSuitCount() {
        let hand: [Card] = [
            card(.hearts, .six),
            card(.diamonds, .seven),
            card(.clubs, .eight),
            card(.spades, .nine)
        ]

        let features = extractor.extract(from: hand)

        XCTAssertEqual(features.suitCounts.count, 4)
        XCTAssertEqual(features.suitCounts[.hearts], 1)
        XCTAssertEqual(features.suitCounts[.diamonds], 1)
        XCTAssertEqual(features.suitCounts[.clubs], 1)
        XCTAssertEqual(features.suitCounts[.spades], 1)
    }

    func testExtract_singleSuitHand_setsLongestSuitToHandSize() {
        let hand: [Card] = [
            card(.clubs, .six),
            card(.clubs, .seven),
            card(.clubs, .eight),
            card(.clubs, .nine)
        ]

        let features = extractor.extract(from: hand)

        XCTAssertEqual(features.regularCardsCount, 4)
        XCTAssertEqual(features.longestSuitCount, 4)
        XCTAssertEqual(features.suitCounts.count, 1)
        XCTAssertEqual(features.suitCounts[.clubs], 4)
    }

    func testExtract_regularCards_keepsSuitAndRankInformation() {
        let hand: [Card] = [
            card(.hearts, .ace),
            card(.spades, .ten)
        ]

        let features = extractor.extract(from: hand)
        XCTAssertEqual(features.regularCards.count, 2)
        XCTAssertTrue(features.regularCards.contains(where: { $0.suit == .hearts && $0.rank == .ace }))
        XCTAssertTrue(features.regularCards.contains(where: { $0.suit == .spades && $0.rank == .ten }))
    }

    func testExtract_performance_doesNotDegradeWithTypicalHandSize() {
        let hand: [Card] = [
            .joker,
            .joker,
            card(.hearts, .ace),
            card(.hearts, .king),
            card(.hearts, .queen),
            card(.diamonds, .jack),
            card(.diamonds, .ten),
            card(.clubs, .nine),
            card(.spades, .eight)
        ]

        measure {
            for _ in 0..<1_000 {
                _ = extractor.extract(from: hand)
            }
        }
    }

    private func card(_ suit: Suit, _ rank: Rank) -> Card {
        return .regular(suit: suit, rank: rank)
    }
}
