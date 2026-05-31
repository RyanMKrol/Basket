// Renders Basket's 1024×1024 app icon natively on macOS (AppKit) — a soft
// grocery-coloured gradient with a basket glyph. Run:
//   swift tools/make_icon.swift <output.png>
import AppKit

let outPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "icon-1024.png"

let side: CGFloat = 1024
let image = NSImage(size: NSSize(width: side, height: side))
image.lockFocus()

// Warm gradient: soft green (top) → cream → soft tomato (bottom), the app's palette.
let gradient = NSGradient(colors: [
    NSColor(srgbRed: 0.86, green: 0.93, blue: 0.83, alpha: 1),
    NSColor(srgbRed: 0.99, green: 0.97, blue: 0.94, alpha: 1),
    NSColor(srgbRed: 0.98, green: 0.88, blue: 0.85, alpha: 1),
])!
gradient.draw(in: NSRect(x: 0, y: 0, width: side, height: side), angle: -90)

// A soft white circle to seat the glyph.
let d: CGFloat = side * 0.62
let circle = NSBezierPath(ovalIn: NSRect(x: (side - d) / 2, y: (side - d) / 2, width: d, height: d))
NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.55).setFill()
circle.fill()

// The basket glyph, centred.
let glyph = "🧺" as NSString
let para = NSMutableParagraphStyle()
para.alignment = .center
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: side * 0.5),
    .paragraphStyle: para,
]
let gSize = glyph.size(withAttributes: attrs)
glyph.draw(at: NSPoint(x: (side - gSize.width) / 2, y: (side - gSize.height) / 2 - side * 0.01),
           withAttributes: attrs)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fputs("failed to render icon\n", stderr)
    exit(1)
}
try! png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
