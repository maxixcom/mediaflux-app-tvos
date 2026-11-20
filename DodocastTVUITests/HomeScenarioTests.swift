import XCTest

/// Главная: ленты обновляются после своих изменений (MF-116) — по номеру версии состояния зрителя, а не «при
/// появлении» (с боковым меню при возврате из стека раздела оно не приходит).
///
/// Меняют данные аккаунта на tst (избранное, позицию) — поэтому: `continueAfterFailure = false`, нужная карточка
/// проверяется по заголовку на самом экране карточки (`media-detail-title`; главная остаётся в дереве под ней), отметку
/// избранного сценарий возвращает как было.
@MainActor
final class HomeScenarioTests: XCTestCase {
    /// Материал без шифрования для плеера: симулятор SAMPLE-AES не играет.
    private var plain: String { ProcessInfo.processInfo.environment["SCENARIO_PLAIN_MEDIA"] ?? "Барсик" }

    override func setUp() {
        continueAfterFailure = false
    }

    /// Карточка из «Недавно добавленных» → «В избранное» → «Назад»: у карточки на главной новое состояние и лента
    /// «Избранное» тоже; затем вернуть как было тем же путём.
    func testFavoritesRowRefreshesAfterCard() {
        let app = XCUIApplication()
        app.launchArguments += ["-tab", "home"]
        app.launch()
        let s = Scenario(app: app, name: "home-favorites")

        let recentTitle = app.staticTexts["Недавно добавленные"]
        XCTAssertTrue(recentTitle.waitForExistence(timeout: 20), "на главной нет ленты «Недавно добавленные»")
        Thread.sleep(forTimeInterval: 2)
        guard let title = cards(app, below: recentTitle).first?.label else {
            return XCTFail("в ленте «Недавно добавленные» нет карточек")
        }
        let before = isFavorite(app, title)
        XCTAssertEqual(before, inFavoritesRow(app, title), "значок на карточке и лента «Избранное» расходятся")
        s.shot("0-before")

        toggleFavorite(app, s, title, step: "1")
        XCTAssertTrue(s.wait(10) { self.isFavorite(app, title) != before },
                      "после возврата с карточки значок на главной прежний (было: \(before ? "в избранном" : "нет"))")
        XCTAssertTrue(s.wait(5) { self.inFavoritesRow(app, title) != before }, "после возврата лента «Избранное» прежняя")
        s.shot("1-after-toggle")

        toggleFavorite(app, s, title, step: "2")
        XCTAssertTrue(s.wait(10) { self.isFavorite(app, title) == before && self.inFavoritesRow(app, title) == before },
                      "после второго возврата главная не обновилась")
        s.shot("2-restored")
    }

    /// Главная загружена → «Поиск» в меню → материал → «С начала» ~35 с → «Назад» → «Главная» в меню: он первым в
    /// «Продолжить просмотр». Главная жила в своём разделе всё это время — обновить её может только номер версии.
    /// В ленту сервер берёт позицию от 30 с и не досмотренное (до 95 %): материал — около минуты.
    func testContinueWatchingAfterPlayer() {
        let app = XCUIApplication()
        app.launchArguments += ["-tab", "home", "-search", plain]
        app.launch()
        let s = Scenario(app: app, name: "home-continue")

        let continueTitle = app.staticTexts["Продолжить просмотр"]
        XCTAssertTrue(continueTitle.waitForExistence(timeout: 20), "на главной нет ленты «Продолжить просмотр»")
        Thread.sleep(forTimeInterval: 2)
        let firstBefore = cards(app, below: continueTitle).first?.label ?? ""
        s.shot("0-before")

        selectInSidebar(app, s, "Поиск")
        let result = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", plain)).firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 20), "в результатах поиска нет «\(plain)…»")
        let title = result.label
        XCTAssertTrue(s.focus(result), "фокус не дошёл до «\(title)»")
        s.remote.press(.select)
        XCTAssertTrue(detailTitle(app).waitForExistence(timeout: 10) && detailTitle(app).label == title,
                      "открылась не карточка «\(title)»")

        // С начала: позиция должна дойти до 30 с, иначе материала в ленте не будет.
        let fromStart = app.buttons["С начала"].firstMatch
        let play = fromStart.exists ? fromStart : app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Смотреть'")).firstMatch
        XCTAssertTrue(play.exists, "на карточке нет «С начала»/«Смотреть»")
        XCTAssertTrue(s.focus(play), "фокус не дошёл до «\(play.label)»")
        s.remote.press(.select)
        XCTAssertTrue(s.wait(10) { !play.hasFocus }, "плеер не открылся")
        Thread.sleep(forTimeInterval: 35)
        s.shot("1-player")
        // «Назад» у плеера AVKit — по шагам (панель управления, выход).
        for _ in 1...4 where !play.hasFocus {
            s.remote.press(.menu)
            Thread.sleep(forTimeInterval: 1.5)
        }
        XCTAssertTrue(play.hasFocus, "«Назад» из плеера не вернул на карточку")
        s.remote.press(.menu)
        XCTAssertTrue(s.wait { result.exists && !self.detailTitle(app).exists }, "«Назад» не вернул к результатам")

        selectInSidebar(app, s, "Главная")
        let first = s.wait(10) { self.cards(app, below: continueTitle).first?.label == title }
        s.shot("2-home-after-player")
        s.dump("2-home-after-player")
        XCTAssertTrue(first, "«\(title)» после плеера не первым в «Продолжить просмотр» (было первым: «\(firstBefore)»)")
    }

    // MARK: - Шаги

    /// Карточка из ленты «Недавно добавленные» → проверка заголовка → «В избранное» / «В избранном» → «Назад».
    private func toggleFavorite(_ app: XCUIApplication, _ s: Scenario, _ title: String, step: String) {
        let recentTitle = app.staticTexts["Недавно добавленные"]
        guard let card = cards(app, below: recentTitle).first(where: { $0.label == title }) else {
            return XCTFail("в ленте «Недавно добавленные» нет «\(title)»")
        }
        XCTAssertTrue(s.focus(card), "фокус не дошёл до «\(title)»")
        s.remote.press(.select)
        XCTAssertTrue(detailTitle(app).waitForExistence(timeout: 10), "карточка не открылась")
        XCTAssertEqual(detailTitle(app).label, title, "открылась не та карточка")
        let favorite = app.buttons.matching(NSPredicate(format: "label == 'В избранное' OR label == 'В избранном'")).firstMatch
        XCTAssertTrue(favorite.waitForExistence(timeout: 5), "на карточке нет кнопки избранного")
        let label = favorite.label
        XCTAssertTrue(s.focus(favorite), "фокус не дошёл до «\(label)»")
        s.remote.press(.select)
        XCTAssertTrue(s.wait { favorite.label != label }, "кнопка избранного не переключилась")
        s.shot("\(step)-card")
        s.remote.press(.menu)
        XCTAssertTrue(s.wait { !self.detailTitle(app).exists }, "«Назад» не закрыл карточку")
    }

    /// Пункт бокового меню: влево до меню, вверх/вниз до пункта, выбрать.
    private func selectInSidebar(_ app: XCUIApplication, _ s: Scenario, _ title: String) {
        let item = app.cells.containing(NSPredicate(format: "elementType == %d AND label == %@",
                                                    XCUIElement.ElementType.button.rawValue, title)).firstMatch
        for _ in 0..<6 where !(item.exists && item.frame.minX < 1) {
            s.remote.press(.left)
            Thread.sleep(forTimeInterval: 0.6)
        }
        let order = ["Поиск", "Главная", "Медиатека", "Настройки"]
        for _ in 0..<6 where !item.hasFocus {
            let focused = app.cells.element(matching: NSPredicate(format: "hasFocus == true"))
            let now = order.firstIndex { focused.exists && focused.buttons[$0].exists } ?? 0
            s.remote.press((order.firstIndex(of: title) ?? 0) < now ? .up : .down)
            Thread.sleep(forTimeInterval: 0.5)
        }
        XCTAssertTrue(item.hasFocus, "фокус не дошёл до «\(title)» в меню")
        s.remote.press(.select)
        Thread.sleep(forTimeInterval: 1.5)
    }

    // MARK: - Что на экране

    private func detailTitle(_ app: XCUIApplication) -> XCUIElement {
        app.staticTexts.matching(identifier: "media-detail-title").firstMatch
    }

    /// Карточки ленты под заголовком: кнопки, чей верх — сразу под ним (ряд горизонтальный, все на одной высоте).
    /// Карточка — выше 200 точек: пункты бокового меню на той же высоте ниже и в ленту не попадают.
    private func cards(_ app: XCUIApplication, below rowTitle: XCUIElement) -> [XCUIElement] {
        guard rowTitle.exists else { return [] }
        let top = rowTitle.frame.maxY
        return app.buttons.allElementsBoundByIndex
            .filter { $0.frame.minY > top && $0.frame.minY < top + 120 && $0.frame.height > 200 && !$0.label.isEmpty }
            .sorted { $0.frame.minX < $1.frame.minX }
    }

    /// Значок «в избранном» на карточке в «Недавно добавленных» — из её состояния для VoiceOver.
    private func isFavorite(_ app: XCUIApplication, _ title: String) -> Bool {
        let card = cards(app, below: app.staticTexts["Недавно добавленные"]).first { $0.label == title }
        return (card?.value as? String)?.contains("В избранном") ?? false
    }

    private func inFavoritesRow(_ app: XCUIApplication, _ title: String) -> Bool {
        cards(app, below: app.staticTexts["Избранное"]).contains { $0.label == title }
    }
}
