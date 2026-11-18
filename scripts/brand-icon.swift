import AppKit

// Слои иконки tvOS и картинки полки из логотипа брендбука.
//   swift scripts/brand-icon.swift ../dodocast.com/docs/brand/logo/dodocast-logo-horizontal-on-dark.svg /tmp/icon
// Результат раскладывается в DodocastTV/Brand/Assets.xcassets/App Icon & Top Shelf Image.brandassets (front/back — слои
// иконки 400×240 и 800×480, *-store — 1280×768, topshelf* — полка).
// Фон — тёмный dodocast (#0a0c16) с мягким свечением в углах, как у страниц входа; передний слой — логотип
// на прозрачном. Иконка tvOS — стопка слоёв: при фокусе система двигает их друг относительно друга.

let logo = NSImage(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))!
let out = URL(fileURLWithPath: CommandLine.arguments[2])
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

func render(_ name: String, _ w: Int, _ h: Int, _ draw: (CGContext, CGSize) -> Void) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx
    draw(ctx.cgContext, CGSize(width: w, height: h))
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: out.appending(path: name))
    print(name, w, h)
}

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: a)
}

/// Фон: #0a0c16 и два мягких пятна — фиолетовое слева сверху, коралловое справа сверху (тема входа dodocast).
func background(_ c: CGContext, _ s: CGSize) {
    c.setFillColor(rgb(10, 12, 22))
    c.fill(CGRect(origin: .zero, size: s))
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    func glow(_ color: (CGFloat, CGFloat, CGFloat, CGFloat), at p: CGPoint, radius: CGFloat) {
        let g = CGGradient(colorsSpace: space, colors: [rgb(color.0, color.1, color.2, color.3), rgb(color.0, color.1, color.2, 0)] as CFArray,
                           locations: [0, 1])!
        c.drawRadialGradient(g, startCenter: p, startRadius: 0, endCenter: p, endRadius: radius, options: [])
    }
    let r = max(s.width, s.height)
    glow((123, 63, 228, 0.34), at: CGPoint(x: 0, y: s.height), radius: r * 0.75)
    glow((255, 75, 92, 0.16), at: CGPoint(x: s.width, y: s.height), radius: r * 0.6)
}

/// Логотип по центру, шириной `share` от холста.
func centeredLogo(_ s: CGSize, share: CGFloat) {
    let w = s.width * share
    let h = w * logo.size.height / logo.size.width
    logo.draw(in: CGRect(x: (s.width - w) / 2, y: (s.height - h) / 2, width: w, height: h))
}

// Иконка: 400×240 (@1x), 800×480 (@2x), для магазина — 1280×768.
for (suffix, w, h) in [("", 400, 240), ("@2x", 800, 480), ("-store", 1280, 768)] {
    render("back\(suffix).png", w, h) { c, s in background(c, s) }
    render("front\(suffix).png", w, h) { _, s in centeredLogo(s, share: 0.72) }
}
// Полка: обычная 1920×720 / 3840×1440 и широкая 2320×720 / 4640×1440.
for (name, w, h) in [("topshelf", 1920, 720), ("topshelf@2x", 3840, 1440),
                     ("topshelf-wide", 2320, 720), ("topshelf-wide@2x", 4640, 1440)] {
    render("\(name).png", w, h) { c, s in
        background(c, s)
        centeredLogo(s, share: 0.36 * 1920 / s.width * (s.width / 1920))
    }
}
