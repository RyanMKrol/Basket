// Renders Basket's 1024×1024 app icon natively on macOS (AppKit): a soft
// grocery-coloured gradient with a mini shopping-list card (a ticked first row).
// Run: swift tools/make_icon.swift <output.png>
import AppKit

let leaf = NSColor(srgbRed: 0.42, green: 0.66, blue: 0.40, alpha: 1)
let inkSoft = NSColor(srgbRed: 0.62, green: 0.60, blue: 0.57, alpha: 1)

let side: CGFloat = 1024
let image = NSImage(size: NSSize(width: side, height: side))
image.lockFocus()

// Warm gradient (green → cream → tomato), the app's palette.
NSGradient(colors: [
    NSColor(srgbRed: 0.86, green: 0.93, blue: 0.83, alpha: 1),
    NSColor(srgbRed: 0.99, green: 0.97, blue: 0.94, alpha: 1),
    NSColor(srgbRed: 0.98, green: 0.88, blue: 0.85, alpha: 1),
])!.draw(in: NSRect(x: 0, y: 0, width: side, height: side), angle: -90)

func rounded(_ r: NSRect, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius)
}

func checkPath(in box: NSRect) -> NSBezierPath {
    let p = NSBezierPath()
    p.move(to: NSPoint(x: box.minX + box.width * 0.22, y: box.minY + box.height * 0.52))
    p.line(to: NSPoint(x: box.minX + box.width * 0.42, y: box.minY + box.height * 0.30))
    p.line(to: NSPoint(x: box.minX + box.width * 0.78, y: box.minY + box.height * 0.72))
    p.lineWidth = box.width * 0.14
    p.lineCapStyle = .round
    p.lineJoinStyle = .round
    return p
}

// The white list card with a soft shadow.
let card = NSRect(x: 0, y: 0, width: side, height: side).insetBy(dx: side * 0.22, dy: side * 0.20)
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.10)
shadow.shadowBlurRadius = side * 0.03
shadow.shadowOffset = NSSize(width: 0, height: -side * 0.012)
NSGraphicsContext.saveGraphicsState()
shadow.set()
NSColor.white.setFill()
rounded(card, card.width * 0.12).fill()
NSGraphicsContext.restoreGraphicsState()

// Three rows: first ticked (green), the rest empty.
let rows = 3
let rowH = card.height / CGFloat(rows + 1)
for i in 0..<rows {
    let y = card.maxY - rowH * CGFloat(i + 1)
    let box = NSRect(x: card.minX + card.width * 0.13, y: y - rowH * 0.24,
                     width: rowH * 0.48, height: rowH * 0.48)
    if i == 0 {
        leaf.setFill(); NSBezierPath(ovalIn: box).fill()
        NSColor.white.setStroke(); checkPath(in: box).stroke()
    } else {
        inkSoft.withAlphaComponent(0.5).setStroke()
        let ring = NSBezierPath(ovalIn: box); ring.lineWidth = box.width * 0.11; ring.stroke()
    }
    let line = NSRect(x: box.maxX + card.width * 0.10, y: box.midY - rowH * 0.075,
                      width: card.width * 0.52, height: rowH * 0.15)
    (i == 0 ? inkSoft.withAlphaComponent(0.55) : inkSoft.withAlphaComponent(0.85)).setFill()
    rounded(line, line.height / 2).fill()
}

image.unlockFocus()

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"
guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fputs("failed to render icon\n", stderr); exit(1)
}
try! png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
