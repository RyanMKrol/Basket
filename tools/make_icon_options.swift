// Renders a comparison sheet of app-icon concepts for Basket, all in the app's
// soft grocery theme. Run: swift tools/make_icon_options.swift <out.png>
import AppKit

let leaf = NSColor(srgbRed: 0.42, green: 0.66, blue: 0.40, alpha: 1)
let tomato = NSColor(srgbRed: 0.92, green: 0.45, blue: 0.42, alpha: 1)
let ink = NSColor(srgbRed: 0.18, green: 0.17, blue: 0.16, alpha: 1)
let inkSoft = NSColor(srgbRed: 0.62, green: 0.60, blue: 0.57, alpha: 1)

func gradient() -> NSGradient {
    NSGradient(colors: [
        NSColor(srgbRed: 0.86, green: 0.93, blue: 0.83, alpha: 1),
        NSColor(srgbRed: 0.99, green: 0.97, blue: 0.94, alpha: 1),
        NSColor(srgbRed: 0.98, green: 0.88, blue: 0.85, alpha: 1),
    ])!
}

func rounded(_ r: NSRect, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius)
}

func drawEmoji(_ glyph: String, in r: NSRect, seat: Bool = true) {
    if seat {
        let d = r.width * 0.62
        NSColor(white: 1, alpha: 0.55).setFill()
        NSBezierPath(ovalIn: NSRect(x: r.midX - d/2, y: r.midY - d/2, width: d, height: d)).fill()
    }
    let p = NSMutableParagraphStyle(); p.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: r.width * 0.5), .paragraphStyle: p]
    let s = glyph as NSString
    let sz = s.size(withAttributes: attrs)
    s.draw(at: NSPoint(x: r.midX - sz.width/2, y: r.midY - sz.height/2 - r.width * 0.01), withAttributes: attrs)
}

func checkPath(in box: NSRect) -> NSBezierPath {
    let p = NSBezierPath()
    p.move(to: NSPoint(x: box.minX + box.width * 0.22, y: box.minY + box.height * 0.52))
    p.line(to: NSPoint(x: box.minX + box.width * 0.42, y: box.minY + box.height * 0.32))
    p.line(to: NSPoint(x: box.minX + box.width * 0.78, y: box.minY + box.height * 0.70))
    p.lineWidth = box.width * 0.12
    p.lineCapStyle = .round
    p.lineJoinStyle = .round
    return p
}

// A shopping-list card: white card, three rows (check + line).
func drawChecklist(in r: NSRect) {
    let card = r.insetBy(dx: r.width * 0.22, dy: r.width * 0.20)
    NSColor.white.setFill()
    rounded(card, card.width * 0.12).fill()
    let rows = 3
    let rowH = card.height / CGFloat(rows + 1)
    for i in 0..<rows {
        let y = card.maxY - rowH * CGFloat(i + 1)
        let box = NSRect(x: card.minX + card.width * 0.12, y: y - rowH * 0.22, width: rowH * 0.44, height: rowH * 0.44)
        if i == 0 {
            leaf.setFill(); NSBezierPath(ovalIn: box).fill()
            NSColor.white.setStroke(); checkPath(in: box).stroke()
        } else {
            inkSoft.withAlphaComponent(0.5).setStroke()
            let ring = NSBezierPath(ovalIn: box); ring.lineWidth = box.width * 0.12; ring.stroke()
        }
        let line = NSRect(x: box.maxX + card.width * 0.10, y: box.midY - rowH * 0.07,
                          width: card.width * 0.5, height: rowH * 0.14)
        (i == 0 ? inkSoft.withAlphaComponent(0.6) : inkSoft.withAlphaComponent(0.85)).setFill()
        rounded(line, line.height/2).fill()
    }
}

// A big tick — the app's check-off action.
func drawTick(in r: NSRect) {
    let d = r.width * 0.52
    let circle = NSRect(x: r.midX - d/2, y: r.midY - d/2, width: d, height: d)
    leaf.setFill(); NSBezierPath(ovalIn: circle).fill()
    NSColor.white.setStroke(); checkPath(in: circle.insetBy(dx: d*0.06, dy: d*0.06)).stroke()
}

// A carrot-and-tick combo idea: emoji food + small green tick badge.
func drawFoodTick(in r: NSRect) {
    drawEmoji("🥕", in: r, seat: true)
    let d = r.width * 0.30
    let badge = NSRect(x: r.maxX - r.width*0.30 - d*0.2, y: r.minY + r.width*0.18, width: d, height: d)
    leaf.setFill(); NSBezierPath(ovalIn: badge).fill()
    NSColor.white.setStroke(); checkPath(in: badge.insetBy(dx: d*0.04, dy: d*0.04)).stroke()
}

struct Concept { let label: String; let draw: (NSRect) -> Void }
let concepts: [Concept] = [
    Concept(label: "1  Checklist") { drawChecklist(in: $0) },
    Concept(label: "2  Tick") { drawTick(in: $0) },
    Concept(label: "3  Cart") { drawEmoji("🛒", in: $0) },
    Concept(label: "4  Bags") { drawEmoji("🛍️", in: $0) },
    Concept(label: "5  Tote") { drawEmoji("👜", in: $0) },
    Concept(label: "6  Food + tick") { drawFoodTick(in: $0) },
    Concept(label: "7  Basket (now)") { drawEmoji("🧺", in: $0) },
    Concept(label: "8  Pin/marker") { drawEmoji("📋", in: $0) },
]

let cols = 4, iconSize: CGFloat = 240.0, pad: CGFloat = 28, labelH: CGFloat = 38
let rows = (concepts.count + cols - 1) / cols
let cellW = iconSize + pad, cellH = iconSize + labelH + pad
let W = CGFloat(cols) * cellW + pad, H = CGFloat(rows) * cellH + pad

let image = NSImage(size: NSSize(width: W, height: H))
image.lockFocus()
NSColor(white: 0.97, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: W, height: H).fill()

for (i, c) in concepts.enumerated() {
    let col = i % cols, row = i / cols
    let x = pad + CGFloat(col) * cellW
    let yTop = H - pad - CGFloat(row) * cellH
    let iconRect = NSRect(x: x, y: yTop - iconSize, width: iconSize, height: iconSize)

    NSGraphicsContext.saveGraphicsState()
    rounded(iconRect, iconSize * 0.22).addClip()
    gradient().draw(in: iconRect, angle: -90)
    c.draw(iconRect)
    NSGraphicsContext.restoreGraphicsState()

    let p = NSMutableParagraphStyle(); p.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 19, weight: .semibold),
        .foregroundColor: ink, .paragraphStyle: p]
    (c.label as NSString).draw(in: NSRect(x: x - 10, y: yTop - iconSize - labelH + 6, width: iconSize + 20, height: labelH),
                               withAttributes: attrs)
}

image.unlockFocus()
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "options.png"
let tiff = image.tiffRepresentation!
let png = NSBitmapImageRep(data: tiff)!.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
