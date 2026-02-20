//
//  GameRepeatResultsFlowUITests.swift
//  JockerUITests
//
//  Created by Codex on 20.02.2026.
//

import XCTest

final class GameRepeatResultsFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testRepeatedGameFlow_presentsFinalResultsWindowTwice() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-uiTestMode")
        app.launch()

        startFourPlayerGame(app)
        finishGameViaUITestControl(app)
        assertAndCloseGameResults(app)

        startFourPlayerGame(app)
        finishGameViaUITestControl(app)
        assertAndCloseGameResults(app)
    }

    private func startFourPlayerGame(_ app: XCUIApplication) {
        let fourPlayersButton = app.buttons["player_count_4_button"]
        XCTAssertTrue(
            fourPlayersButton.waitForExistence(timeout: 5),
            "Кнопка выбора 4 игроков не найдена."
        )
        fourPlayersButton.tap()
    }

    private func finishGameViaUITestControl(_ app: XCUIApplication) {
        let finishButton = app.buttons["ui_test_finish_game_button"]
        XCTAssertTrue(
            finishButton.waitForExistence(timeout: 5),
            "Тестовая кнопка завершения игры не появилась."
        )
        finishButton.tap()
    }

    private func assertAndCloseGameResults(_ app: XCUIApplication) {
        let closeButton = app.buttons["game_results_close_button"]
        XCTAssertTrue(
            closeButton.waitForExistence(timeout: 5),
            "Окно итогов игры не появилось."
        )
        closeButton.tap()
    }
}
