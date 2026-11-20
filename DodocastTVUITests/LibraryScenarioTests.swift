import XCTest

/// Библиотека (сетка со страницами) после своих изменений (MF-116): перечитывает уже загруженные страницы по номеру
/// версии состояния зрителя — значки на карточках свежие, прокрутка на месте.
///
/// Меняет избранное на tst и возвращает как было; нужная карточка проверяется по её заголовку (`media-detail-title`).
@MainActor
final class LibraryScenarioTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    func testLibraryGridRefreshesAfterCard() {
        let app = XCUIApplication()
        app.launchArguments += ["-tab", "library"]
        app.launch()
        let s = Scenario(app: app, name: "library-grid")

        // Первая библиотека в «Медиатеке».
        let librariesTitle = app.staticTexts["Библиотеки"]
        XCTAssertTrue(librariesTitle.waitForExistence(timeout: 20), "в «Медиатеке» нет ленты «Библиотеки»")
        Thread.sleep(forTimeInterval: 2)
        guard let library = cards(app, below: librariesTitle).first else { return XCTFail("нет библиотек") }
        let libraryTitle = library.label
        XCTAssertTrue(s.focus(library), "фокус не дошёл до библиотеки «\(libraryTitle)»")
        s.remote.press(.select)
        let gridTitle = app.staticTexts[libraryTitle]
        XCTAssertTrue(s.wait(10) { self.firstGridCard(app, below: gridTitle) != nil }, "библиотека «\(libraryTitle)» не открылась")
        Thread.sleep(forTimeInterval: 1.5)
        guard let title = firstGridCard(app, below: gridTitle)?.label else { return XCTFail("в библиотеке нет карточек") }
        let before = isFavorite(app, gridTitle, title)
        s.shot("0-grid")

        toggleFavorite(app, s, gridTitle, title, step: "1")
        XCTAssertTrue(s.wait(10) { self.isFavorite(app, gridTitle, title) != before },
                      "после возврата с карточки значок в сетке библиотеки прежний")
        s.shot("1-after-toggle")

        toggleFavorite(app, s, gridTitle, title, step: "2")
        XCTAssertTrue(s.wait(10) { self.isFavorite(app, gridTitle, title) == before }, "после второго возврата сетка не обновилась")
        s.shot("2-restored")
    }

    private func toggleFavorite(_ app: XCUIApplication, _ s: Scenario, _ gridTitle: XCUIElement, _ title: String, step: String) {
        guard let card = firstGridCard(app, below: gridTitle), card.label == title else {
            return XCTFail("первая карточка сетки — не «\(title)»")
        }
        XCTAssertTrue(s.focus(card), "фокус не дошёл до «\(title)»")
        s.remote.press(.select)
        let detail = app.staticTexts.matching(identifier: "media-detail-title").firstMatch
        XCTAssertTrue(detail.waitForExistence(timeout: 10), "карточка не открылась")
        XCTAssertEqual(detail.label, title, "открылась не та карточка")
        let favorite = app.buttons.matching(NSPredicate(format: "label == 'В избранное' OR label == 'В избранном'")).firstMatch
        XCTAssertTrue(favorite.waitForExistence(timeout: 5), "на карточке нет кнопки избранного")
        let label = favorite.label
        XCTAssertTrue(s.focus(favorite), "фокус не дошёл до «\(label)»")
        s.remote.press(.select)
        XCTAssertTrue(s.wait { favorite.label != label }, "кнопка избранного не переключилась")
        s.shot("\(step)-card")
        s.remote.press(.menu)
        XCTAssertTrue(s.wait { !detail.exists }, "«Назад» не закрыл карточку")
    }

    /// Карточки ленты под заголовком (выше 200 точек — не пункты меню).
    private func cards(_ app: XCUIApplication, below rowTitle: XCUIElement) -> [XCUIElement] {
        guard rowTitle.exists else { return [] }
        let top = rowTitle.frame.maxY
        return app.buttons.allElementsBoundByIndex
            .filter { $0.frame.minY > top && $0.frame.minY < top + 120 && $0.frame.height > 200 && !$0.label.isEmpty }
            .sorted { $0.frame.minX < $1.frame.minX }
    }

    /// Первая карточка сетки библиотеки — верхняя левая под заголовком.
    private func firstGridCard(_ app: XCUIApplication, below gridTitle: XCUIElement) -> XCUIElement? {
        cards(app, below: gridTitle).first
    }

    private func isFavorite(_ app: XCUIApplication, _ gridTitle: XCUIElement, _ title: String) -> Bool {
        let card = cards(app, below: gridTitle).first { $0.label == title }
        return (card?.value as? String)?.contains("В избранном") ?? false
    }
}
