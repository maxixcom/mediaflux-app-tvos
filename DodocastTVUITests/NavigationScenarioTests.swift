import XCTest

/// Боковое меню разделов (tvOS 18+, как у приложения Apple TV): поиск из меню, «Назад», повторный выбор раздела.
@MainActor
final class NavigationScenarioTests: XCTestCase {
    private var mediaTitle: String { ProcessInfo.processInfo.environment["SCENARIO_MEDIA"] ?? "temp_38" }

    override func setUp() {
        continueAfterFailure = false
    }

    /// Путь как в приложении Apple TV: меню → «Поиск» → карточка → «Назад» → форма поиска → «Назад» → меню.
    func testSearchFromSidebarAndBack() {
        let app = XCUIApplication()
        app.launchArguments += ["-search", mediaTitle]
        app.launch()
        let s = Scenario(app: app, name: "sidebar-search")
        let searchItem = sidebarItem(app, "Поиск")
        XCTAssertTrue(searchItem.waitForExistence(timeout: 20), "нет пункта «Поиск» в меню")

        for _ in 0..<4 where !searchItem.hasFocus {
            s.remote.press(.up)
            Thread.sleep(forTimeInterval: 0.5)
        }
        XCTAssertTrue(searchItem.hasFocus, "фокус не дошёл до «Поиск» в меню")
        s.remote.press(.select)
        let card = app.buttons[mediaTitle]
        XCTAssertTrue(card.waitForExistence(timeout: 20), "в результатах поиска нет «\(mediaTitle)»")
        Thread.sleep(forTimeInterval: 1)
        s.shot("1-search")
        s.dump("1-search")

        XCTAssertTrue(s.focus(card), "фокус не дошёл до карточки")
        s.remote.press(.select)
        let play = playButton(app)
        XCTAssertTrue(play.waitForExistence(timeout: 10), "карточка медиа не открылась")
        Thread.sleep(forTimeInterval: 1)
        s.shot("2-card")

        s.remote.press(.menu)
        XCTAssertTrue(s.wait { !play.exists && card.exists }, "«Назад» не вернул к форме поиска")
        Thread.sleep(forTimeInterval: 1)
        s.shot("3-back-to-search")

        s.remote.press(.menu)
        Thread.sleep(forTimeInterval: 1.5)
        s.shot("4-back-again")
        s.dump("4-back-again")
    }

    /// Открыта карточка из поиска → влево до меню → выбрать «Поиск» ещё раз.
    func testReselectSearchFromSidebar() {
        let app = XCUIApplication()
        app.launchArguments += ["-tab", "search", "-search", mediaTitle]
        app.launch()
        let s = Scenario(app: app, name: "sidebar-reselect")

        let card = app.buttons[mediaTitle]
        XCTAssertTrue(card.waitForExistence(timeout: 20), "в результатах поиска нет «\(mediaTitle)»")
        XCTAssertTrue(s.focus(card), "фокус не дошёл до карточки")
        s.remote.press(.select)
        let play = playButton(app)
        XCTAssertTrue(play.waitForExistence(timeout: 10), "карточка медиа не открылась")

        let searchItem = sidebarItem(app, "Поиск")
        for _ in 0..<5 where !searchItem.hasFocus {
            s.remote.press(.left)
            Thread.sleep(forTimeInterval: 0.6)
        }
        s.shot("1-menu-over-card")
        s.dump("1-menu-over-card")
        XCTAssertTrue(searchItem.hasFocus, "влево из карточки не открыло меню на «Поиск»")

        s.remote.press(.select)
        Thread.sleep(forTimeInterval: 1.5)
        s.shot("2-after-select")
        s.dump("2-after-select")
        XCTAssertTrue(s.wait { !play.exists && card.exists }, "повторный выбор «Поиск» в меню не вернул к форме поиска")
    }

    /// Снимки разделов со свёрнутым меню: старт, затем фокус вправо в содержимое.
    func testSectionScreens() {
        for tab in ["home", "library", "settings"] {
            let app = XCUIApplication()
            app.launchArguments += ["-tab", tab]
            app.launch()
            let s = Scenario(app: app, name: "section-\(tab)")
            Thread.sleep(forTimeInterval: 4)
            s.shot("1-launch")
            s.remote.press(.right)
            Thread.sleep(forTimeInterval: 1.5)
            s.shot("2-content")
            app.terminate()
        }
    }

    /// Пункт меню: фокус встаёт на ячейку, кнопка с подписью — внутри неё.
    private func sidebarItem(_ app: XCUIApplication, _ title: String) -> XCUIElement {
        app.cells.containing(NSPredicate(format: "elementType == %d AND label == %@",
                                         XCUIElement.ElementType.button.rawValue, title)).firstMatch
    }

    private func playButton(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Смотреть' OR label BEGINSWITH 'Продолжить'"))
            .firstMatch
    }
}
