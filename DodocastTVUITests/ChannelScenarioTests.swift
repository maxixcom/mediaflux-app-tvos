import XCTest

/// Обложки каналов и подборок (MF-115): плитка канала на главной, экран канала, вкладка «Сведения» в плеере канала;
/// плитки подборок в «Медиатеке».
///
/// Канал — `TEST_RUNNER_SCENARIO_CHANNEL` (по умолчанию «Мой персональный канал» на tst: без шифрования — симулятор
/// SAMPLE-AES не играет), подборка — `TEST_RUNNER_SCENARIO_PLAYLIST` (по умолчанию «Лиля»).
@MainActor
final class ChannelScenarioTests: XCTestCase {
    private var channelTitle: String { ProcessInfo.processInfo.environment["SCENARIO_CHANNEL"] ?? "Мой персональный канал" }
    private var playlistTitle: String { ProcessInfo.processInfo.environment["SCENARIO_PLAYLIST"] ?? "Лиля" }

    override func setUp() {
        continueAfterFailure = false
    }

    func testChannelCoverOnHomeScreenAndPlayer() {
        let app = XCUIApplication()
        app.launchArguments += ["-tab", "home"]
        app.launch()
        let s = Scenario(app: app, name: "channel-cover")

        let channel = app.buttons[channelTitle]
        XCTAssertTrue(reach(channel, s), "на главной нет канала «\(channelTitle)»")
        XCTAssertTrue(s.focus(channel), "фокус не дошёл до канала")
        Thread.sleep(forTimeInterval: 1.5)
        s.shot("1-home-channels")
        s.dump("1-home-channels")

        s.remote.press(.select)
        let watch = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Смотреть'")).firstMatch
        XCTAssertTrue(watch.waitForExistence(timeout: 10), "экран канала не открылся")
        Thread.sleep(forTimeInterval: 1.5)
        s.shot("2-channel-screen")

        // Плеер — поверх экрана канала: признак — фокус ушёл со «Смотреть». «Сведения» — смахиванием вниз.
        XCTAssertTrue(s.wait { watch.hasFocus }, "фокус не на «Смотреть»")
        s.remote.press(.select)
        XCTAssertTrue(s.wait(10) { !watch.hasFocus }, "плеер не открылся")
        Thread.sleep(forTimeInterval: 6)
        s.remote.press(.down)
        Thread.sleep(forTimeInterval: 2)
        s.shot("3-player-info")
        s.dump("3-player-info")

        // «Назад» у штатного плеера AVKit — по шагам: «Сведения» → панель управления → выход из плеера.
        for step in 1...3 where !watch.hasFocus {
            s.remote.press(.menu)
            Thread.sleep(forTimeInterval: 2)
            s.shot("4-back-\(step)")
            s.dump("4-back-\(step)")
        }
        XCTAssertTrue(s.wait(10) { watch.hasFocus }, "«Назад» из плеера не вернул на экран канала")
    }

    func testPlaylistCoverInLibrary() {
        let app = XCUIApplication()
        app.launchArguments += ["-tab", "library"]
        app.launch()
        let s = Scenario(app: app, name: "playlist-cover")

        let playlist = app.buttons[playlistTitle]
        XCTAssertTrue(reach(playlist, s), "в «Медиатеке» нет подборки «\(playlistTitle)»")
        XCTAssertTrue(s.focus(playlist), "фокус не дошёл до подборки")
        Thread.sleep(forTimeInterval: 1.5)
        s.shot("1-library-playlists")
    }

    /// Ряды главной строятся лениво: плитки ниже экрана в иерархии нет, пока до неё не прокрутили. Листаем пультом
    /// вниз по содержимому; если фокус в боковом меню — сначала вправо, иначе «вниз» листает пункты меню.
    private func reach(_ element: XCUIElement, _ s: Scenario, maxMoves: Int = 12) -> Bool {
        if element.waitForExistence(timeout: 10) { return true }
        for _ in 0..<maxMoves where !element.exists {
            let focused = s.app.descendants(matching: .any).element(matching: NSPredicate(format: "hasFocus == true"))
            let inSidebar = focused.exists && focused.elementType == .cell && focused.frame.minX < 1
            s.remote.press(inSidebar ? .right : .down)
            Thread.sleep(forTimeInterval: 0.7)
        }
        if !element.exists {
            s.shot("reach-failed")
            s.dump("reach-failed")
        }
        return element.exists
    }
}
