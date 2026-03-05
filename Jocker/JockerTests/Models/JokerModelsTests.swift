//
//  JokerModelsTests.swift
//  JockerTests
//
//  Created by Codex on 06.03.2026.
//

import XCTest
@testable import Jocker

final class JokerModelsTests: XCTestCase {
    func testJokerLeadDeclaration_wishCase_matchesExpectedPattern() {
        let declaration: JokerLeadDeclaration = .wish

        if case .wish = declaration {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .wish case")
        }
    }

    func testJokerLeadDeclaration_aboveCase_carriesSuit() {
        let declaration: JokerLeadDeclaration = .above(suit: .hearts)

        guard case .above(let suit) = declaration else {
            return XCTFail("Expected .above case")
        }
        XCTAssertEqual(suit, .hearts)
    }

    func testJokerLeadDeclaration_takesCase_carriesSuit() {
        let declaration: JokerLeadDeclaration = .takes(suit: .spades)

        guard case .takes(let suit) = declaration else {
            return XCTFail("Expected .takes case")
        }
        XCTAssertEqual(suit, .spades)
    }

    func testJokerPlayDecision_defaultNonLead_isFaceUpWithoutDeclaration() {
        let decision = JokerPlayDecision.defaultNonLead

        XCTAssertEqual(decision.style, .faceUp)
        XCTAssertNil(decision.leadDeclaration)
    }

    func testJokerPlayDecision_defaultLead_isFaceUpWithWishDeclaration() {
        let decision = JokerPlayDecision.defaultLead

        XCTAssertEqual(decision.style, .faceUp)
        XCTAssertEqual(decision.leadDeclaration, .wish)
    }

    func testJokerPlayDecision_customDecision_storesFields() {
        let decision = JokerPlayDecision(
            style: .faceDown,
            leadDeclaration: .takes(suit: .clubs)
        )

        XCTAssertEqual(decision.style, .faceDown)
        XCTAssertEqual(decision.leadDeclaration, .takes(suit: .clubs))
    }

    func testJokerPlayStyle_cases_areDistinct() {
        XCTAssertNotEqual(JokerPlayStyle.faceUp, JokerPlayStyle.faceDown)
    }

    func testPlayedTrickCard_regularCard_forcesFaceUpAndNilDeclaration() {
        let played = PlayedTrickCard(
            playerIndex: 1,
            card: .regular(suit: .diamonds, rank: .ace),
            jokerPlayStyle: .faceDown,
            jokerLeadDeclaration: .wish
        )

        XCTAssertEqual(played.jokerPlayStyle, .faceUp)
        XCTAssertNil(played.jokerLeadDeclaration)
    }

    func testPlayedTrickCard_joker_preservesStyleAndDeclaration() {
        let played = PlayedTrickCard(
            playerIndex: 2,
            card: .joker,
            jokerPlayStyle: .faceDown,
            jokerLeadDeclaration: .above(suit: .hearts)
        )

        XCTAssertEqual(played.jokerPlayStyle, .faceDown)
        XCTAssertEqual(played.jokerLeadDeclaration, .above(suit: .hearts))
    }

    func testPlayedTrickCard_isFaceUpJoker_returnsTrueForFaceUpJoker() {
        let played = PlayedTrickCard(playerIndex: 0, card: .joker, jokerPlayStyle: .faceUp)

        XCTAssertTrue(played.isFaceUpJoker)
    }

    func testPlayedTrickCard_isFaceUpJoker_returnsFalseForNonFaceUpCases() {
        let faceDownJoker = PlayedTrickCard(playerIndex: 0, card: .joker, jokerPlayStyle: .faceDown)
        let regularCard = PlayedTrickCard(playerIndex: 1, card: .regular(suit: .clubs, rank: .ten))

        XCTAssertFalse(faceDownJoker.isFaceUpJoker)
        XCTAssertFalse(regularCard.isFaceUpJoker)
    }
}
