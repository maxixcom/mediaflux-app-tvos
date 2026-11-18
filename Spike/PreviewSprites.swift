import Foundation
import UIKit

/// Раскладка превью-спрайтов стримера (`MEDIA_PREVIEW.md` §8): `/preview/{code}/manifest.json`.
///
/// Тайл k изображает отрезок `[k·intervalSec, (k+1)·intervalSec)`. Правило выбора тайла — копия витрины
/// (`mediaflux-watch/app/utils/previewSprite.ts`: `frameIndexAt`, `spriteFrameByIndex`), чтобы кадр главы
/// на телевизоре совпадал с тем, что зритель видит на сайте.
struct PreviewManifest: Decodable {
    let intervalSec: Double
    let tileW: Int
    let tileH: Int
    let cols: Int
    let tilesPerSheet: Int
    let frameCount: Int
    let sheetPattern: String
    /// Отпечаток содержимого спрайтов — `?v=` к адресу листа: у листов долгий кэш по стабильному имени.
    let fingerprint: String?

    struct Tile: Hashable {
        let sheet: Int
        let col: Int
        let row: Int
    }

    /// Номер тайла, чей отрезок содержит момент `seconds`; за последним — последний (`frameIndexAt`).
    func frameIndex(at seconds: Double) -> Int {
        let f = Int((seconds / intervalSec).rounded(.down))
        return max(0, min(f, frameCount - 1))
    }

    /// Лист, колонка и строка тайла (`spriteFrameByIndex`).
    func tile(_ frame: Int) -> Tile {
        let f = max(0, min(frame, frameCount - 1))
        let t = f % tilesPerSheet
        return Tile(sheet: f / tilesPerSheet, col: t % cols, row: t / cols)
    }

    /// Имя листа по шаблону манифеста (`sprite-%03d.jpg`).
    func sheetName(_ sheet: Int) -> String {
        String(format: sheetPattern, Int32(sheet))
    }
}

/// Картинки плиток глав для штатного плеера tvOS (MF-97): кадр главы вырезается из листа превью-спрайтов.
///
/// Режет приложение, а не стример: листы открыты по коду медиа и кешируются CDN, а резка на сервере дала бы
/// тот же тайл 320×180 ценой декодирования картинок на пути отдачи.
enum ChapterArtwork {
    /// JPEG плитки на каждую главу; ключ — начало главы в мс. Каждый нужный лист качается один раз.
    /// Любой сбой (у медиа нет превью, `429` ограничителя, битая картинка) — пустой результат: главы остаются
    /// с названиями, а плеер ничего не ждёт.
    static func load(code: String, chapters: [PublicConfig.Chapter]) async -> [Int: Data] {
        guard !chapters.isEmpty else { return [:] }
        let base = Config.streamer.appendingPathComponent("preview").appendingPathComponent(code)
        do {
            let manifest = try JSONDecoder().decode(
                PreviewManifest.self, from: try await get(base.appendingPathComponent("manifest.json")))
            guard manifest.frameCount > 0 else { return [:] }

            var tiles: [Int: PreviewManifest.Tile] = [:]
            for ch in chapters {
                tiles[ch.startMs] = manifest.tile(manifest.frameIndex(at: Double(ch.startMs) / 1000))
            }

            var sheets: [Int: CGImage] = [:]
            for sheet in Set(tiles.values.map(\.sheet)).sorted() {
                var url = base.appendingPathComponent(manifest.sheetName(sheet))
                if let v = manifest.fingerprint {
                    url = url.appending(queryItems: [URLQueryItem(name: "v", value: v)])
                }
                guard let image = UIImage(data: try await get(url))?.cgImage else {
                    Log.line("главы: лист \(sheet) не разобрался")
                    continue
                }
                sheets[sheet] = image
            }

            var result: [Int: Data] = [:]
            for (startMs, t) in tiles {
                // Координаты — в пикселях листа: `UIImage(data:)` создаётся с масштабом 1.
                let rect = CGRect(x: t.col * manifest.tileW, y: t.row * manifest.tileH,
                                  width: manifest.tileW, height: manifest.tileH)
                guard let sheet = sheets[t.sheet], let cropped = sheet.cropping(to: rect),
                      let jpeg = UIImage(cgImage: cropped).jpegData(compressionQuality: 0.9) else { continue }
                result[startMs] = jpeg
            }
            Log.line("главы: картинок \(result.count) из \(chapters.count), листы \(sheets.keys.sorted()) — каждый скачан один раз")
            return result
        } catch {
            Log.line("главы: без картинок — \(error.localizedDescription)")
            return [:]
        }
    }

    private static func get(_ url: URL) async throws -> Data {
        let (data, resp) = try await URLSession.shared.data(from: url)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard code == 200 else { throw StreamerError.http(code, url.path) }
        return data
    }
}
