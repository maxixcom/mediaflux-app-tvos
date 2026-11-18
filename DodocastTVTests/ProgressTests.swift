import XCTest
@testable import DodocastTV

/// Позиция просмотра без сети: очередь недосланного, формат времени, правило «продолжить».
final class ProgressTests: XCTestCase {

    private func report(_ media: String, _ pos: Int, at seconds: TimeInterval, final: Bool = false) -> ProgressReport {
        ProgressReport(mediaId: media, positionMs: pos, durationMs: 240_000,
                       reportedAt: Date(timeIntervalSince1970: seconds), final: final)
    }

    func testOutboxKeepsLatestPerMediaAndSurvivesRestart() async {
        let key = "test-\(UUID().uuidString)"
        let outbox = ProgressOutbox(serverKey: key)
        await outbox.keep(report("1", 10_000, at: 100))
        await outbox.keep(report("1", 5_000, at: 50))     // раньше записанного — не заменяет
        await outbox.keep(report("2", 7_000, at: 70))
        let all = await outbox.all().sorted { $0.mediaId < $1.mediaId }
        XCTAssertEqual(all.map(\.positionMs), [10_000, 7_000])

        let reopened = ProgressOutbox(serverKey: key)
        let isEmpty = await reopened.isEmpty
        XCTAssertFalse(isEmpty, "недосланное переживает перезапуск")
        await reopened.clear()
    }

    func testOutboxDropsOnlyDeliveredVersion() async {
        let outbox = ProgressOutbox(serverKey: "test-\(UUID().uuidString)")
        let older = report("1", 10_000, at: 100)
        let newer = report("1", 20_000, at: 200)
        await outbox.keep(older)
        await outbox.keep(newer)
        await outbox.drop(older)                           // ушёл старый — новый остаётся
        let left = await outbox.all()
        XCTAssertEqual(left.first?.positionMs, 20_000)
        await outbox.clear()
    }

    func testDateTimeIsUtcIso8601WithMillis() {
        let date = Date(timeIntervalSince1970: 1_795_000_000.125)
        let s = DateTimeFormat.string(date)
        XCTAssertTrue(s.hasSuffix("Z"), s)
        XCTAssertTrue(s.contains(".125"), s)
        XCTAssertEqual(DateTimeFormat.date(s)?.timeIntervalSince1970 ?? 0, 1_795_000_000.125, accuracy: 0.001)
        XCTAssertNotNil(DateTimeFormat.date("2026-11-18T12:00:00Z"), "без долей секунды тоже")
    }

    func testResumeOnlyFromThirtySecondsAndNotWatched() {
        func item(_ pos: Int, watched: Bool) -> MediaItem {
            MediaItem(id: "1", title: "t", durationMs: 240_000, coverURL: nil, favorite: false,
                      progress: ViewProgress(positionMs: pos, durationMs: 240_000, watched: watched))
        }
        XCTAssertNil(item(29_000, watched: false).resumeMs)
        XCTAssertEqual(item(30_000, watched: false).resumeMs, 30_000)
        XCTAssertNil(item(120_000, watched: true).resumeMs)
    }

    func testChapterMarkersCoverWholeMedia() {
        let group = Chapters.group([Chapter(startMs: 60_000, title: "Б"), Chapter(startMs: 0, title: "А")],
                                   durationMs: 240_000)
        let ranges = group.timedNavigationMarkers?.map(\.timeRange) ?? []
        XCTAssertEqual(ranges.count, 2)
        XCTAssertEqual(ranges[0].start.seconds, 0)
        XCTAssertEqual(ranges[0].end.seconds, 60)
        XCTAssertEqual(ranges[1].end.seconds, 240, "последняя глава — до конца ролика")
    }
}
