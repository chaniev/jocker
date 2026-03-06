//
//  DealHistoryPresentationBuilderTests.swift
//  JockerTests
//
//  Created by Codex on 06.03.2026.
//

import XCTest
@testable import Jocker

final class DealHistoryPresentationBuilderTests: XCTestCase {
    func testBuild_createsSectionsRowsAndExportPayload() throws {
        let dealHistory = DealHistory(
            key: DealHistoryKey(blockIndex: 0, roundIndex: 1),
            trump: .hearts,
            initialHands: [
                [.regular(suit: .spades, rank: .ace)],
                []
            ],
            tricks: [
                DealTrickHistory(
                    moves: [
                        DealTrickMove(playerIndex: 0, card: .regular(suit: .diamonds, rank: .six)),
                        DealTrickMove(playerIndex: 1, card: .joker, jokerPlayStyle: .faceDown)
                    ],
                    winnerPlayerIndex: 1
                )
            ]
        )

        let presentation = DealHistoryPresentationBuilder().build(
            dealHistory: dealHistory,
            playerNames: ["  Анна  ", "   "],
            playerControlTypes: [.human]
        )

        XCTAssertEqual(presentation.title, "Раздача 2, блок 1")
        XCTAssertEqual(presentation.trumpText, "Козырь: Черви")
        XCTAssertEqual(presentation.sections.count, 2)
        XCTAssertEqual(presentation.exportData.playerCount, 2)
        XCTAssertEqual(presentation.exportData.playerNames, ["Анна", "Игрок 2"])
        XCTAssertEqual(presentation.exportData.playerControlTypes, [.human, .bot])

        let handsSection = try XCTUnwrap(presentation.sections.first)
        XCTAssertEqual(handsSection.title, "Карты на руках после раздачи")
        XCTAssertEqual(handsSection.rows.count, 2)
        XCTAssertEqual(handsSection.rows[0].kind, .hand)
        XCTAssertEqual(handsSection.rows[0].title, "Анна (Человек)")
        XCTAssertEqual(handsSection.rows[0].detail, "A♠︎")
        XCTAssertEqual(handsSection.rows[1].title, "Игрок 2 (Бот)")
        XCTAssertEqual(handsSection.rows[1].detail, "Пусто")

        let trickSection = presentation.sections[1]
        XCTAssertEqual(trickSection.title, "Взятка 1 • Забрал: Игрок 2")
        XCTAssertEqual(trickSection.rows[0].title, "1. Анна: 6♦︎")
        XCTAssertEqual(trickSection.rows[1].title, "2. Игрок 2: 🃏 (рубашкой вверх)")
    }

    func testBuild_withoutPlayersAndTricks_returnsEmptyPresentation() {
        let dealHistory = DealHistory(
            key: DealHistoryKey(blockIndex: 2, roundIndex: 0),
            trump: nil,
            initialHands: [],
            tricks: []
        )

        let presentation = DealHistoryPresentationBuilder().build(
            dealHistory: dealHistory,
            playerNames: [],
            playerControlTypes: []
        )

        XCTAssertTrue(presentation.isEmpty)
        XCTAssertEqual(presentation.exportData.playerCount, 0)
        XCTAssertEqual(presentation.sections, [])
        XCTAssertEqual(presentation.trumpText, "Козырь: без козыря")
    }
}
