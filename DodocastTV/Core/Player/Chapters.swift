import AVFoundation
import AVKit
import UIKit

/// Главы → маркеры навигации штатного плеера tvOS, картинки плиток — из превью-спрайтов (MF-97, перенесено из Spike).
enum Chapters {
    /// Маркеры с названиями — сразу; картинки догружаются, и маркеры переназначаются уже с ними (панель «Главы»
    /// это подхватывает). Старт воспроизведения картинок не ждёт.
    @MainActor
    static func attach(to item: AVPlayerItem, chapters: [Chapter], durationMs: Int?, previewManifest: URL?) {
        guard !chapters.isEmpty else { return }
        item.navigationMarkerGroups = [group(chapters, durationMs: durationMs)]
        guard let previewManifest else { return }
        Task { @MainActor in
            let artwork = await ChapterArtwork.load(manifestURL: previewManifest, chapters: chapters)
            guard !artwork.isEmpty else { return }
            item.navigationMarkerGroups = [group(chapters, durationMs: durationMs, artwork: artwork)]
            Log.line("главы: картинки \(artwork.count) из \(chapters.count)")
        }
    }

    /// Конец главы — начало следующей, у последней — конец ролика. `artwork` — JPEG плитки по началу главы (мс).
    static func group(_ chapters: [Chapter], durationMs: Int?, artwork: [Int: Data] = [:]) -> AVNavigationMarkersGroup {
        let sorted = chapters.sorted { $0.startMs < $1.startMs }
        let markers: [AVTimedMetadataGroup] = sorted.enumerated().map { index, ch in
            let endMs = index + 1 < sorted.count ? sorted[index + 1].startMs : (durationMs ?? ch.startMs + 1000)
            let range = CMTimeRange(start: CMTime(value: CMTimeValue(ch.startMs), timescale: 1000),
                                    duration: CMTime(value: CMTimeValue(max(endMs - ch.startMs, 1)), timescale: 1000))
            var items: [AVMetadataItem] = [Metadata.item(.commonIdentifierTitle, ch.title as NSString)]
            if let jpeg = artwork[ch.startMs] {
                // Картинку плитки штатный плеер берёт из `commonIdentifierArtwork` группы маркера.
                items.append(Metadata.item(.commonIdentifierArtwork, jpeg as NSData,
                                           dataType: kCMMetadataBaseDataType_JPEG as String))
            }
            return AVTimedMetadataGroup(items: items, timeRange: range)
        }
        return AVNavigationMarkersGroup(title: nil, timedNavigationMarkers: markers)
    }
}

enum Metadata {
    static func item(_ id: AVMetadataIdentifier, _ value: NSCopying & NSObjectProtocol, dataType: String? = nil) -> AVMetadataItem {
        let m = AVMutableMetadataItem()
        m.identifier = id
        m.value = value
        if let dataType { m.dataType = dataType }
        m.extendedLanguageTag = "und"
        return m
    }

    /// Вкладка «Инфо» штатного плеера: название, описание, обложка (находка Э0 — без этого вкладка пустая).
    static func external(title: String, description: String?, artwork: Data?) -> [AVMetadataItem] {
        var items = [item(.commonIdentifierTitle, title as NSString)]
        if let description, !description.isEmpty {
            items.append(item(.commonIdentifierDescription, description as NSString))
        }
        if let artwork {
            items.append(item(.commonIdentifierArtwork, artwork as NSData, dataType: kCMMetadataBaseDataType_JPEG as String))
        }
        return items
    }
}

/// Раскладка превью-спрайтов стримера (`MEDIA_PREVIEW.md` §8). Правило выбора тайла — копия витрины
/// (`mediaflux-watch/app/utils/previewSprite.ts`), чтобы кадр главы совпадал с сайтом.
struct PreviewManifest: Decodable, Sendable {
    let intervalSec: Double
    let tileW: Int
    let tileH: Int
    let cols: Int
    let tilesPerSheet: Int
    let frameCount: Int
    let sheetPattern: String
    /// Отпечаток содержимого — `?v=` к адресу листа: у листов долгий кэш по стабильному имени.
    let fingerprint: String?

    struct Tile: Hashable {
        let sheet: Int
        let col: Int
        let row: Int
    }

    func frameIndex(at seconds: Double) -> Int {
        let f = Int((seconds / intervalSec).rounded(.down))
        return max(0, min(f, frameCount - 1))
    }

    func tile(_ frame: Int) -> Tile {
        let f = max(0, min(frame, frameCount - 1))
        let t = f % tilesPerSheet
        return Tile(sheet: f / tilesPerSheet, col: t % cols, row: t / cols)
    }

    func sheetName(_ sheet: Int) -> String {
        String(format: sheetPattern, Int32(sheet))
    }
}

/// Плитки глав из листа превью (MF-97): режет приложение — листы открыты по коду и кешируются CDN.
enum ChapterArtwork {
    /// JPEG на каждую главу; ключ — начало главы в мс. Каждый нужный лист качается один раз. Любой сбой — пусто:
    /// главы остаются с названиями.
    static func load(manifestURL: URL, chapters: [Chapter]) async -> [Int: Data] {
        let base = manifestURL.deletingLastPathComponent()
        do {
            let manifest = try JSONDecoder().decode(PreviewManifest.self, from: try await get(manifestURL))
            guard manifest.frameCount > 0 else { return [:] }
            var tiles: [Int: PreviewManifest.Tile] = [:]
            for ch in chapters {
                tiles[ch.startMs] = manifest.tile(manifest.frameIndex(at: Double(ch.startMs) / 1000))
            }
            var sheets: [Int: CGImage] = [:]
            for sheet in Set(tiles.values.map(\.sheet)).sorted() {
                var url = base.appending(path: manifest.sheetName(sheet))
                if let v = manifest.fingerprint { url = url.appending(queryItems: [URLQueryItem(name: "v", value: v)]) }
                if let image = UIImage(data: try await get(url))?.cgImage { sheets[sheet] = image }
            }
            var result: [Int: Data] = [:]
            for (startMs, t) in tiles {
                let rect = CGRect(x: t.col * manifest.tileW, y: t.row * manifest.tileH,
                                  width: manifest.tileW, height: manifest.tileH)
                guard let sheet = sheets[t.sheet], let cropped = sheet.cropping(to: rect),
                      let jpeg = UIImage(cgImage: cropped).jpegData(compressionQuality: 0.9) else { continue }
                result[startMs] = jpeg
            }
            return result
        } catch {
            Log.line("главы: без картинок — \(error.localizedDescription)")
            return [:]
        }
    }

    private static func get(_ url: URL) async throws -> Data {
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return data
    }
}
