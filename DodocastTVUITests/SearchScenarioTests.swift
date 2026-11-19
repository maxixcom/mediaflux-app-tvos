import XCTest

/// Поиск: карточка из результатов и возврат «Назад».
///
/// Нужен вход на симуляторе (сервер и сессия — из его Keychain) и материал, который находится по `-search`.
@MainActor
final class SearchScenarioTests: XCTestCase {
    /// Материал для сценария: `TEST_RUNNER_SCENARIO_MEDIA` (по умолчанию `temp_38` на tst).
    private var mediaTitle: String { ProcessInfo.processInfo.environment["SCENARIO_MEDIA"] ?? "temp_38" }

    override func setUp() {
        continueAfterFailure = false
    }

    func testBackFromCardOpenedInSearch() {
        let app = XCUIApplication()
        app.launchArguments += ["-tab", "search", "-search", mediaTitle]
        app.launch()
        let s = Scenario(app: app, name: "search-back")

        let card = app.buttons[mediaTitle]
        XCTAssertTrue(card.waitForExistence(timeout: 20), "в результатах поиска нет «\(mediaTitle)»")
        s.shot("1-results")
        XCTAssertTrue(s.focus(card), "фокус не дошёл до карточки «\(mediaTitle)»")

        s.remote.press(.select)
        let play = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Смотреть' OR label BEGINSWITH 'Продолжить'"))
            .firstMatch
        XCTAssertTrue(play.waitForExistence(timeout: 10), "карточка медиа не открылась")
        s.shot("2-card")

        s.remote.press(.menu)
        let back = s.wait { !play.exists && card.exists }
        s.shot("3-after-back")
        XCTAssertTrue(back, "«Назад» не вернул к результатам поиска")
    }

    /// Поиск → карточка → плеер → «Назад» из плеера → «Назад» из карточки. Материал — без шифрования: симулятор
    /// SAMPLE-AES не играет (`TEST_RUNNER_SCENARIO_PLAIN_MEDIA`, по умолчанию «Барсик…» на tst).
    func testBackFromCardAfterPlayer() {
        let prefix = ProcessInfo.processInfo.environment["SCENARIO_PLAIN_MEDIA"] ?? "Барсик"
        let app = XCUIApplication()
        app.launchArguments += ["-tab", "search", "-search", prefix]
        app.launch()
        let s = Scenario(app: app, name: "search-player-back")

        let card = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 20), "в результатах поиска нет «\(prefix)…»")
        XCTAssertTrue(s.focus(card), "фокус не дошёл до карточки")
        s.remote.press(.select)
        let play = playButton(app)
        XCTAssertTrue(play.waitForExistence(timeout: 10), "карточка медиа не открылась")
        XCTAssertTrue(s.wait { play.hasFocus }, "фокус не на «Смотреть»")

        // Плеер — поверх карточки, она остаётся в иерархии: признак плеера — фокус ушёл с «Смотреть».
        s.remote.press(.select)
        XCTAssertTrue(s.wait(10) { !play.hasFocus }, "плеер не открылся")
        Thread.sleep(forTimeInterval: 6)
        s.shot("1-player")
        s.remote.press(.menu)
        XCTAssertTrue(s.wait(10) { play.hasFocus }, "«Назад» из плеера не вернул на карточку")
        s.shot("2-card-after-player")

        s.remote.press(.menu)
        let back = s.wait { !play.exists && card.exists }
        s.shot("3-after-back")
        XCTAssertTrue(back, "«Назад» после плеера не вернул к результатам поиска")
    }

    private func playButton(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Смотреть' OR label BEGINSWITH 'Продолжить'"))
            .firstMatch
    }
}
