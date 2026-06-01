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

// 🧺 emoji with a small leaf check badge — the current icon, but "done".
func drawBasketBadge(in r: NSRect) {
    drawEmoji("🧺", in: r, seat: false)
    let d = r.width * 0.30
    let badge = NSRect(x: r.maxX - r.width*0.30 - d*0.2, y: r.minY + r.width*0.18, width: d, height: d)
    leaf.setFill(); NSBezierPath(ovalIn: badge).fill()
    NSColor.white.setStroke(); checkPath(in: badge.insetBy(dx: d*0.04, dy: d*0.04)).stroke()
}

// A soft, rounded leaf-green "B" monogram.
func drawMonogram(in r: NSRect) {
    let p = NSMutableParagraphStyle(); p.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: r.width * 0.66, weight: .bold),
        .foregroundColor: leaf, .paragraphStyle: p]
    let s = "B" as NSString
    let sz = s.size(withAttributes: attrs)
    s.draw(at: NSPoint(x: r.midX - sz.width/2, y: r.midY - sz.height/2 - r.width*0.02), withAttributes: attrs)
}

// The big tick, ringed by the gold spark-burst the app plays on check-off.
func drawSparkTick(in r: NSRect) {
    drawTick(in: r)
    let gold = NSColor(srgbRed: 0.96, green: 0.80, blue: 0.33, alpha: 1)
    gold.setFill()
    let cx = r.midX, cy = r.midY, rad = r.width * 0.36, s = r.width * 0.030
    for i in 0..<8 {
        let a = CGFloat(i) / 8 * .pi * 2 + 0.2
        let px = cx + cos(a) * rad, py = cy + sin(a) * rad
        let star = NSBezierPath()
        star.move(to: NSPoint(x: px, y: py + s*2)); star.line(to: NSPoint(x: px + s, y: py))
        star.line(to: NSPoint(x: px, y: py - s*2)); star.line(to: NSPoint(x: px - s, y: py))
        star.close(); star.fill()
    }
}

// An illustrated woven basket: a tapered bowl with a cross-weave and a few
// colourful groceries poking over the rim. The "premium" direction.
func drawWovenBasket(in r: NSRect) {
    let cx = r.midX
    let tanLight = NSColor(srgbRed: 0.84, green: 0.66, blue: 0.44, alpha: 1)
    let tanDark  = NSColor(srgbRed: 0.68, green: 0.50, blue: 0.30, alpha: 1)
    let wheat    = NSColor(srgbRed: 0.95, green: 0.80, blue: 0.48, alpha: 1)

    // groceries peeking out behind the rim
    let itemY = r.minY + r.height * 0.50
    let peek: [(NSColor, CGFloat, CGFloat)] = [(tomato, -0.17, 0.20), (leaf, 0.02, 0.24), (wheat, 0.19, 0.18)]
    for (col, dx, h) in peek {
        col.setFill()
        let w = r.width * 0.20
        NSBezierPath(ovalIn: NSRect(x: cx + dx*r.width - w/2, y: itemY, width: w, height: r.height*h)).fill()
    }

    // basket bowl (trapezoid)
    let bodyTop = r.minY + r.height * 0.55, bodyBot = r.minY + r.height * 0.18
    let topHalf = r.width * 0.33, botHalf = r.width * 0.24
    let body = NSBezierPath()
    body.move(to: NSPoint(x: cx - topHalf, y: bodyTop)); body.line(to: NSPoint(x: cx + topHalf, y: bodyTop))
    body.line(to: NSPoint(x: cx + botHalf, y: bodyBot)); body.line(to: NSPoint(x: cx - botHalf, y: bodyBot))
    body.close()
    tanLight.setFill(); body.fill()

    // cross-weave lines, clipped to the bowl
    NSGraphicsContext.saveGraphicsState()
    body.addClip()
    tanDark.setStroke()
    for k in stride(from: -1.0, through: 1.0, by: 0.34) {
        let up = NSBezierPath(); up.lineWidth = r.width*0.022
        up.move(to: NSPoint(x: cx + CGFloat(k)*r.width*0.5 - r.width*0.2, y: bodyBot))
        up.line(to: NSPoint(x: cx + CGFloat(k)*r.width*0.5 + r.width*0.2, y: bodyTop)); up.stroke()
        let dn = NSBezierPath(); dn.lineWidth = r.width*0.022
        dn.move(to: NSPoint(x: cx + CGFloat(k)*r.width*0.5 + r.width*0.2, y: bodyBot))
        dn.line(to: NSPoint(x: cx + CGFloat(k)*r.width*0.5 - r.width*0.2, y: bodyTop)); dn.stroke()
    }
    NSGraphicsContext.restoreGraphicsState()

    // rim
    let rim = NSRect(x: cx - topHalf - r.width*0.03, y: bodyTop - r.height*0.035,
                     width: (topHalf + r.width*0.03)*2, height: r.height*0.075)
    tanDark.setFill(); rounded(rim, rim.height/2).fill()
}

// A chunky pixel-art basket — a nod to the app's VT323/Silkscreen heritage.
func drawPixelBasket(in r: NSRect) {
    let map = [
        "....DDDDD....",
        "...D.....D...",
        "...D.....D...",
        ".RR..GG..RR..",
        "WWWWWWWWWWWWW",
        "LdLdLdLdLdLdL",
        "dLdLdLdLdLdLd",
        "LdLdLdLdLdLdL",
        ".dLdLdLdLdLd.",
        "..LdLdLdLdL..",
        "...LLLLLLL...",
    ]
    let cols = 13, rowsN = map.count
    let cell = min(r.width / 14.5, r.height / (CGFloat(rowsN) + 1.5))
    let gridW = CGFloat(cols) * cell, gridH = CGFloat(rowsN) * cell
    let x0 = r.midX - gridW/2, yTop = r.midY + gridH/2
    let palette: [Character: NSColor] = [
        "L": NSColor(srgbRed: 0.84, green: 0.66, blue: 0.44, alpha: 1),  // light weave
        "d": NSColor(srgbRed: 0.68, green: 0.50, blue: 0.30, alpha: 1),  // dark weave
        "D": NSColor(srgbRed: 0.62, green: 0.45, blue: 0.27, alpha: 1),  // handle
        "W": NSColor(srgbRed: 0.74, green: 0.55, blue: 0.34, alpha: 1),  // rim
        "R": tomato, "G": leaf,
    ]
    for (rowIdx, line) in map.enumerated() {
        for (colIdx, ch) in line.enumerated() {
            guard let c = palette[ch] else { continue }
            c.setFill()
            let px = x0 + CGFloat(colIdx) * cell
            let py = yTop - CGFloat(rowIdx + 1) * cell
            NSRect(x: px, y: py, width: cell + 0.5, height: cell + 0.5).fill()
        }
    }
}

// A checklist card with a checked-off grocery on the top row.
func drawChecklistFood(in r: NSRect) {
    drawChecklist(in: r)
    let card = r.insetBy(dx: r.width * 0.22, dy: r.width * 0.20)
    drawEmoji("🍅", in: NSRect(x: card.maxX - card.width*0.30, y: card.maxY - card.height*0.34,
                               width: card.width*0.24, height: card.width*0.24), seat: false)
}

struct Concept { let label: String; let draw: (NSRect) -> Void }
let concepts: [Concept] = [
    Concept(label: "1  Woven basket") { drawWovenBasket(in: $0) },
    Concept(label: "2  Pixel basket") { drawPixelBasket(in: $0) },
    Concept(label: "3  Basket + tick") { drawBasketBadge(in: $0) },
    Concept(label: "4  Monogram B") { drawMonogram(in: $0) },
    Concept(label: "5  Spark tick") { drawSparkTick(in: $0) },
    Concept(label: "6  Checklist + food") { drawChecklistFood(in: $0) },
    Concept(label: "7  Checklist") { drawChecklist(in: $0) },
    Concept(label: "8  Tick") { drawTick(in: $0) },
    Concept(label: "9  Food + tick") { drawFoodTick(in: $0) },
    Concept(label: "10  Cart") { drawEmoji("🛒", in: $0) },
    Concept(label: "11  Basket (now)") { drawEmoji("🧺", in: $0) },
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
