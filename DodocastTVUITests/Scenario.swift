import XCTest

/// Сценарий на симуляторе: пульт `XCUIRemote`, фокус, снимки экрана.
///
/// Снимки — в каталог из переменной `SCENARIO_SHOTS` (её задаёт `scripts/ui-check.sh` через `TEST_RUNNER_…`) и
/// вложениями в результат прогона.
@MainActor
struct Scenario {
    let app: XCUIApplication
    let name: String
    let remote = XCUIRemote.shared

    /// Снимок экрана: `<каталог>/<сценарий>-<шаг>.png`.
    func shot(_ step: String) {
        let png = XCUIScreen.main.screenshot().pngRepresentation
        if let dir = ProcessInfo.processInfo.environment["SCENARIO_SHOTS"], !dir.isEmpty {
            try? png.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name)-\(step).png"))
        }
        let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
        attachment.name = "\(name)-\(step)"
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: step) { $0.add(attachment) }
    }

    /// Дерево элементов экрана — текстом рядом со снимками: по нему ищутся подписи и роли для сценариев.
    func dump(_ step: String) {
        guard let dir = ProcessInfo.processInfo.environment["SCENARIO_SHOTS"], !dir.isEmpty else { return }
        try? app.debugDescription.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name)-\(step).txt"),
                                        atomically: true, encoding: .utf8)
    }

    /// Довести фокус до элемента: из бокового меню — вправо в содержимое, затем вниз до ряда элемента и вправо по ряду.
    func focus(_ element: XCUIElement, maxMoves: Int = 12) -> Bool {
        for _ in 0..<maxMoves where !element.hasFocus {
            let focused = app.descendants(matching: .any).element(matching: NSPredicate(format: "hasFocus == true"))
            let inSidebar = focused.exists && focused.elementType == .cell && focused.frame.minX < 1
            let onRow = focused.exists && abs(focused.frame.midY - element.frame.midY) < 20
            remote.press(inSidebar || onRow ? .right : .down)
            Thread.sleep(forTimeInterval: 0.5)
        }
        return element.hasFocus
    }

    /// Подождать, пока условие станет верным (анимации переходов tvOS).
    func wait(_ seconds: TimeInterval = 5, until condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            if condition() { return true }
            Thread.sleep(forTimeInterval: 0.25)
        }
        return condition()
    }
}
