import XCTest

/// Недавние поиски (MF-114), как в приложении Apple TV: при пустой строке поиска — ряд материалов, на чьи карточки
/// переходили из поиска, свежие первыми; выбор из самого ряда поднимает материал наверх; очистка — в настройках.
///
/// Материалы — `TEST_RUNNER_SCENARIO_MEDIA` (по умолчанию `temp_38`) и `TEST_RUNNER_SCENARIO_PLAIN_MEDIA` (начало
/// названия, по умолчанию «Барсик») на tst. История общая на аккаунт: сценарии меняют её на сервере.
@MainActor
final class SearchRecentsScenarioTests: XCTestCase {
    private var first: String { ProcessInfo.processInfo.environment["SCENARIO_MEDIA"] ?? "temp_38" }
    private var second: String { ProcessInfo.processInfo.environment["SCENARIO_PLAIN_MEDIA"] ?? "Барсик" }

    override func setUp() {
        continueAfterFailure = false
    }

    func testSelectedFromSearchGoesToRecentsNewestFirst() {
        openFromSearch(first, name: "recents-a")
        openFromSearch(second, name: "recents-b")

        // Пустая строка: в ряду оба, последний выбранный — первым.
        var app = launchEmptySearch()
        var s = Scenario(app: app, name: "recents-row")
        XCTAssertTrue(app.staticTexts["Недавние поиски"].waitForExistence(timeout: 20), "нет ряда «Недавние поиски»")
        let a = card(app, first), b = card(app, second)
        XCTAssertTrue(a.waitForExistence(timeout: 5) && b.exists, "в ряду нет обоих выбранных материалов")
        s.shot("1-row")
        s.dump("1-row")
        XCTAssertLessThan(b.frame.minX, a.frame.minX, "последний выбранный («\(second)») — не первым в ряду")

        // Выбор из самого ряда — тоже выбор: материал поднимается наверх.
        XCTAssertTrue(s.focus(a), "фокус не дошёл до «\(first)» в ряду")
        s.remote.press(.select)
        XCTAssertTrue(playButton(app).waitForExistence(timeout: 10), "карточка из ряда не открылась")
        Thread.sleep(forTimeInterval: 1.5)
        s.remote.press(.menu)
        Thread.sleep(forTimeInterval: 1.5)
        app.terminate()

        app = launchEmptySearch()
        s = Scenario(app: app, name: "recents-reselect")
        let a2 = card(app, first), b2 = card(app, second)
        XCTAssertTrue(a2.waitForExistence(timeout: 20) && b2.exists, "в ряду нет обоих материалов")
        s.shot("1-row")
        XCTAssertLessThan(a2.frame.minX, b2.frame.minX, "выбор из ряда не поднял «\(first)» наверх")
    }

    /// Путь владельца в одном запуске (20.11.2026): видел историю → нашёл другое → карточка → «Назад» → стёр текст
    /// поиска → в ряду должен быть только что открытый, первым.
    func testRecentsUpdatedAfterReturnAndClearingText() {
        openFromSearch(first, name: "same-session-prepare")

        let app = XCUIApplication()
        app.launchArguments += ["-tab", "search", "-search", second]
        app.launch()
        let s = Scenario(app: app, name: "same-session")
        let result = card(app, second)
        XCTAssertTrue(result.waitForExistence(timeout: 20), "в результатах поиска нет «\(second)»")
        XCTAssertTrue(s.focus(result), "фокус не дошёл до «\(second)»")
        s.remote.press(.select)
        XCTAssertTrue(playButton(app).waitForExistence(timeout: 10), "карточка «\(second)» не открылась")
        Thread.sleep(forTimeInterval: 2)
        s.remote.press(.menu)
        XCTAssertTrue(s.wait { result.exists }, "«Назад» не вернул к результатам")
        Thread.sleep(forTimeInterval: 1)

        // Стереть текст поиска, как владелец: вверх на клавиатуру и клавишей удаления.
        XCTAssertTrue(app.searchFields.firstMatch.exists, "нет строки поиска")
        s.remote.press(.up)
        Thread.sleep(forTimeInterval: 1)
        s.shot("0-keyboard")
        app.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: second.count + 4))
        XCTAssertTrue(app.staticTexts["Недавние поиски"].waitForExistence(timeout: 10), "после очистки текста нет ряда")
        Thread.sleep(forTimeInterval: 2)
        s.shot("1-row-after-clear")
        s.dump("1-row-after-clear")
        let a = card(app, first), b = card(app, second)
        XCTAssertTrue(b.exists, "только что открытого «\(second)» нет в ряду недавних")
        XCTAssertTrue(a.exists, "прежнего «\(first)» нет в ряду недавних")
        XCTAssertLessThan(b.frame.minX, a.frame.minX, "только что открытый «\(second)» — не первым в ряду")
    }

    /// Очистка в настройках стирает историю аккаунта на сервере — запускать осознанно:
    /// `scripts/ui-check.sh <каталог> SearchRecentsScenarioTests/testClearSearchHistoryInSettings`.
    func testClearSearchHistoryInSettings() {
        openFromSearch(first, name: "clear-prepare")

        let app = XCUIApplication()
        app.launchArguments += ["-tab", "settings"]
        app.launch()
        let s = Scenario(app: app, name: "clear")
        // В списке настроек фокус встаёт на ячейку, кнопка с подписью — внутри неё (как у пунктов меню).
        let clear = app.cells.containing(NSPredicate(format: "elementType == %d AND label == %@",
                                                     XCUIElement.ElementType.button.rawValue, "Очистить историю поиска"))
            .firstMatch
        XCTAssertTrue(clear.waitForExistence(timeout: 20), "в настройках нет «Очистить историю поиска»")
        XCTAssertTrue(s.focus(clear, maxMoves: 20), "фокус не дошёл до «Очистить историю поиска»")
        s.remote.press(.select)
        // Подтверждение: «Отменить» и «Очистить» в ряд, фокус по умолчанию на безопасной «Отменить».
        let confirm = app.sheets.buttons["Очистить"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "нет подтверждения очистки")
        Thread.sleep(forTimeInterval: 1)
        s.shot("1-confirm")
        XCTAssertFalse(confirm.hasFocus, "фокус по умолчанию — на «Очистить», а должен быть на «Отменить»")
        for _ in 0..<3 where !confirm.hasFocus {
            s.remote.press(.right)
            Thread.sleep(forTimeInterval: 0.5)
        }
        XCTAssertTrue(confirm.hasFocus, "фокус не на «Очистить»")
        s.remote.press(.select)
        XCTAssertTrue(app.staticTexts["История поиска очищена"].waitForExistence(timeout: 10), "нет отметки об очистке")
        s.shot("2-cleared")
        app.terminate()

        let search = launchEmptySearch()
        Thread.sleep(forTimeInterval: 5)
        Scenario(app: search, name: "clear").shot("3-search-empty")
        XCTAssertFalse(search.staticTexts["Недавние поиски"].exists, "после очистки ряд «Недавние поиски» остался")
    }

    /// Найти материал по тексту, перейти на карточку и вернуться к результатам.
    private func openFromSearch(_ title: String, name: String) {
        let app = XCUIApplication()
        app.launchArguments += ["-tab", "search", "-search", title]
        app.launch()
        let s = Scenario(app: app, name: name)
        let result = card(app, title)
        XCTAssertTrue(result.waitForExistence(timeout: 20), "в результатах поиска нет «\(title)»")
        XCTAssertTrue(s.focus(result), "фокус не дошёл до «\(title)»")
        s.remote.press(.select)
        XCTAssertTrue(playButton(app).waitForExistence(timeout: 10), "карточка «\(title)» не открылась")
        Thread.sleep(forTimeInterval: 1.5)
        s.remote.press(.menu)
        XCTAssertTrue(s.wait { result.exists }, "«Назад» не вернул к результатам")
        app.terminate()
    }

    private func launchEmptySearch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-tab", "search"]
        app.launch()
        return app
    }

    /// Карточка медиа по началу названия (подпись кнопки — название).
    private func card(_ app: XCUIApplication, _ title: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
    }

    private func playButton(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Смотреть' OR label BEGINSWITH 'Продолжить'"))
            .firstMatch
    }
}
