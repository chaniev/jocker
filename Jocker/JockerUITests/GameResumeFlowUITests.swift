import XCTest

final class GameResumeFlowUITests: XCTestCase {
    override func setUpWithError() throws { self.continueAfterFailure = false }

    func testThreeIndependentVariantsSurviveTerminationAndCanBeReplaced() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestMode", "-sessionTestID", UUID().uuidString]
        app.launch()
        for variant in 0..<3 {
            self.selectVariant(variant, app: app)
            self.exitGame(app)
        }
        app.terminate()
        app.launch()
        for variant in 0..<3 {
            self.selectVariant(variant, app: app)
            let resume = app.buttons["Продолжить сохранённую игру"]
            XCTAssertTrue(resume.waitForExistence(timeout: 5))
            resume.tap()
            self.exitGame(app)
        }
        self.selectVariant(0, app: app)
        let replace = app.buttons["Начать новую"]
        XCTAssertTrue(replace.waitForExistence(timeout: 5))
        XCTAssertTrue(app.alerts.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "безвозвратно")).firstMatch.exists)
        replace.tap()
        self.exitGame(app)
        self.selectVariant(2, app: app)
        XCTAssertTrue(app.buttons["Продолжить сохранённую игру"].waitForExistence(timeout: 5))
    }

    func testForegroundTwiceKeepsGameUsableAndResumeDoesNotRequireNewSetup() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestMode", "-sessionTestID", UUID().uuidString]
        app.launch()
        self.selectVariant(0, app: app)
        XCTAssertTrue(app.buttons["session_exit_button"].waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home)
        app.activate()
        XCUIDevice.shared.press(.home)
        app.activate()
        self.exitGame(app)
        self.selectVariant(0, app: app)
        app.buttons["Продолжить сохранённую игру"].tap()
        XCTAssertTrue(app.buttons["session_exit_button"].waitForExistence(timeout: 5))
        self.exitGame(app)
    }

    func testExitAfterWriteFailureWarnsAndReturnsToMenu() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestMode", "-sessionTestID", UUID().uuidString, "-failSessionWrites"]
        app.launch()
        self.selectVariant(0, app: app)
        XCTAssertTrue(app.buttons["session_exit_button"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.alerts["Прогресс не сохранён"].exists)
        app.buttons["session_exit_button"].tap()
        XCTAssertTrue(app.alerts["Прогресс не сохранён"].waitForExistence(timeout: 5))
        app.buttons["Выйти в меню"].tap()
        XCTAssertTrue(app.buttons["player_count_3_button"].waitForExistence(timeout: 5))
    }

    func testPendingBidSurvivesBackgroundAndProcessTermination() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestMode", "-sessionTestID", UUID().uuidString]
        app.launch()
        self.selectVariant(0, app: app)
        XCTAssertTrue(app.buttons["session_exit_button"].waitForExistence(timeout: 5))
        let table = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        table.name = "table-exit-layout"
        table.lifetime = .keepAlways
        self.add(table)
        let deal = app.otherElements["Раздать карты"].firstMatch
        XCTAssertTrue(deal.waitForExistence(timeout: 5))
        deal.tap()
        XCTAssertTrue(app.staticTexts["Ваше слово"].waitForExistence(timeout: 10))
        let before = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        before.name = "pending-bid-exit-layout"
        before.lifetime = .keepAlways
        self.add(before)
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.staticTexts["Ваше слово"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(identifier: "Ваше слово").count, 1)
        app.terminate()
        app.launch()
        self.selectVariant(0, app: app)
        XCTAssertTrue(app.buttons["Продолжить сохранённую игру"].waitForExistence(timeout: 5))
        app.buttons["Продолжить сохранённую игру"].tap()
        XCTAssertTrue(app.staticTexts["Ваше слово"].waitForExistence(timeout: 5))
        self.exitGame(app)
    }

    private func selectVariant(_ variant: Int, app: XCUIApplication) {
        let button = app.buttons[variant == 0 ? "player_count_3_button" : "player_count_4_button"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
        if variant != 0 {
            let mode = app.buttons[variant == 1 ? "Каждый сам за себя" : "Пара на пару"]
            XCTAssertTrue(mode.waitForExistence(timeout: 5))
            mode.tap()
        }
    }
    private func exitGame(_ app: XCUIApplication) {
        let modalExit = app.buttons["session_modal_exit_button"]
        let exit = modalExit.exists ? modalExit : app.buttons["session_exit_button"]
        XCTAssertTrue(exit.waitForExistence(timeout: 5))
        exit.tap()
        XCTAssertTrue(app.buttons["player_count_3_button"].waitForExistence(timeout: 5))
    }
}
