// Pixel-art version of the *actual* 🧺 emoji: render Apple's basket glyph large,
// downsample it to an N×N grid (averaging), then upscale crisp (nearest-neighbour)
// so it reads as pixel art. Bigger N = finer pixels. Renders a comparison of a
// few N values on the app gradient. Run: swift tools/make_basket_pixel.swift <out.png> [glyph]
import AppKit

let glyph = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "🧺"

func gradient() -> NSGradient {
    NSGradient(colors: [
        NSColor(srgbRed: 0.86, green: 0.93, blue: 0.83, alpha: 1),
        NSColor(srgbRed: 0.99, green: 0.97, blue: 0.94, alpha: 1),
        NSColor(srgbRed: 0.98, green: 0.88, blue: 0.85, alpha: 1),
    ])!
}
func rounded(_ r: NSRect, _ rad: CGFloat) -> NSBezierPath { NSBezierPath(roundedRect: r, xRadius: rad, yRadius: rad) }

// Render the emoji into a crisp, transparent high-res bitmap.
func emojiRep(_ s: String, px: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                              bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                              colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    let p = NSMutableParagraphStyle(); p.alignment = .center
    let f = NSFont.systemFont(ofSize: CGFloat(px) * 0.86)
    let attrs: [NSAttributedString.Key: Any] = [.font: f, .paragraphStyle: p]
    let str = s as NSString
    let sz = str.size(withAttributes: attrs)
    str.draw(at: NSPoint(x: (CGFloat(px) - sz.width) / 2, y: (CGFloat(px) - sz.height) / 2), withAttributes: attrs)
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

// Downsample the source to N×N (averaging), then harden alpha so edges stay crisp.
func pixelate(_ src: NSBitmapImageRep, n: Int) -> NSBitmapImageRep {
    let small = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: n, pixelsHigh: n,
                                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: small)!
    ctx.imageInterpolation = .high
    NSGraphicsContext.current = ctx
    src.draw(in: NSRect(x: 0, y: 0, width: n, height: n))
    NSGraphicsContext.restoreGraphicsState()
    // Harden alpha: a downsampled glyph has soft, semi-transparent edges; snap
    // them so the pixels read as solid blocks.
    for y in 0..<n { for x in 0..<n {
        guard let c = small.colorAt(x: x, y: y) else { continue }
        let a = c.alphaComponent
        let na: CGFloat = a < 0.45 ? 0 : 1
        small.setColor(NSColor(srgbRed: c.redComponent, green: c.greenComponent, blue: c.blueComponent, alpha: na), atX: x, y: y)
    } }
    return small
}

let tile: CGFloat = 300, pad: CGFloat = 30, labelH: CGFloat = 40
let levels = [24, 32, 44, 60]
let cols = levels.count
let W = CGFloat(cols) * (tile + pad) + pad
let H = tile + labelH + 2 * pad

let hi = emojiRep(glyph, px: 512)

let image = NSImage(size: NSSize(width: W, height: H))
image.lockFocus()
NSColor(white: 0.97, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: W, height: H).fill()

for (i, n) in levels.enumerated() {
    let x = pad + CGFloat(i) * (tile + pad)
    let rect = NSRect(x: x, y: labelH + pad, width: tile, height: tile)

    NSGraphicsContext.saveGraphicsState()
    rounded(rect, tile * 0.22).addClip()
    gradient().draw(in: rect, angle: -90)
    // Upscale the pixelated basket crisply into the tile, with a little padding.
    NSGraphicsContext.current?.imageInterpolation = .none
    let inset = rect.insetBy(dx: tile * 0.1, dy: tile * 0.1)
    pixelate(hi, n: n).draw(in: inset, from: .zero, operation: .sourceOver, fraction: 1,
                            respectFlipped: true, hints: [.interpolation: NSImageInterpolation.none])
    NSGraphicsContext.restoreGraphicsState()

    let p = NSMutableParagraphStyle(); p.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 20, weight: .semibold),
        .foregroundColor: NSColor(srgbRed: 0.18, green: 0.17, blue: 0.16, alpha: 1),
        .paragraphStyle: p]
    ("\(n)×\(n) px" as NSString).draw(in: NSRect(x: x, y: pad - 4, width: tile, height: labelH), withAttributes: attrs)
}

image.unlockFocus()
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "basket_pixel.png"
let tiff = image.tiffRepresentation!
let png = NSBitmapImageRep(data: tiff)!.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
