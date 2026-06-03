// Explores different icon DESIGN LANGUAGES (not just symbols) — solid fields,
// dark/moody, full-bleed, duotone, long-shadow, monogram, pattern, sticker,
// line-art, a little scene, a bold gradient — to move away from the generic
// "pastel gradient + tiny floating object" look.
// Run: swift tools/make_icon_styles.swift <out.png>
import AppKit

let leaf    = NSColor(srgbRed: 0.42, green: 0.66, blue: 0.40, alpha: 1)
let leafDk  = NSColor(srgbRed: 0.16, green: 0.32, blue: 0.24, alpha: 1)
let lime    = NSColor(srgbRed: 0.74, green: 0.86, blue: 0.40, alpha: 1)
let tomato  = NSColor(srgbRed: 0.89, green: 0.40, blue: 0.37, alpha: 1)
let coral   = NSColor(srgbRed: 0.96, green: 0.55, blue: 0.45, alpha: 1)
let mustard = NSColor(srgbRed: 0.93, green: 0.74, blue: 0.32, alpha: 1)
let kraft   = NSColor(srgbRed: 0.82, green: 0.61, blue: 0.39, alpha: 1)
let kraftDk = NSColor(srgbRed: 0.60, green: 0.42, blue: 0.25, alpha: 1)
let tan     = NSColor(srgbRed: 0.90, green: 0.74, blue: 0.52, alpha: 1)
let cream   = NSColor(srgbRed: 0.98, green: 0.96, blue: 0.90, alpha: 1)
let paper   = NSColor(srgbRed: 0.96, green: 0.93, blue: 0.86, alpha: 1)
let ink     = NSColor(srgbRed: 0.24, green: 0.22, blue: 0.20, alpha: 1)

func P(_ R: NSRect, _ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: R.minX + x * R.width, y: R.maxY - y * R.height) }
func S(_ R: NSRect, _ v: CGFloat) -> CGFloat { v * R.width }
func fill(_ R: NSRect, _ c: NSColor) { c.setFill(); NSBezierPath(rect: R).fill() }
func grad(_ R: NSRect, _ a: NSColor, _ b: NSColor, _ angle: CGFloat) { NSGradient(colors: [a, b])!.draw(in: R, angle: angle) }
func disc(_ R: NSRect, _ cx: CGFloat, _ cy: CGFloat, _ rad: CGFloat, _ c: NSColor) {
    c.setFill(); let p = P(R, cx, cy)
    NSBezierPath(ovalIn: NSRect(x: p.x - S(R, rad), y: p.y - S(R, rad), width: S(R, rad) * 2, height: S(R, rad) * 2)).fill()
}
func box(_ R: NSRect, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ rad: CGFloat, _ c: NSColor) {
    c.setFill(); let tl = P(R, x, y)
    NSBezierPath(roundedRect: NSRect(x: tl.x, y: tl.y - S(R, h), width: S(R, w), height: S(R, h)), xRadius: S(R, rad), yRadius: S(R, rad)).fill()
}
func poly(_ R: NSRect, _ pts: [(CGFloat, CGFloat)], _ c: NSColor) {
    c.setFill(); let path = NSBezierPath()
    for (i, p) in pts.enumerated() { let q = P(R, p.0, p.1); if i == 0 { path.move(to: q) } else { path.line(to: q) } }
    path.close(); path.fill()
}
func line(_ R: NSRect, _ pts: [(CGFloat, CGFloat)], _ w: CGFloat, _ c: NSColor, closed: Bool = false) {
    c.setStroke(); let path = NSBezierPath()
    for (i, p) in pts.enumerated() { let q = P(R, p.0, p.1); if i == 0 { path.move(to: q) } else { path.line(to: q) } }
    if closed { path.close() }
    path.lineWidth = S(R, w); path.lineCapStyle = .round; path.lineJoinStyle = .round; path.stroke()
}
func curve(_ R: NSRect, _ a: (CGFloat, CGFloat), _ c1: (CGFloat, CGFloat), _ c2: (CGFloat, CGFloat), _ b: (CGFloat, CGFloat), _ w: CGFloat, _ col: NSColor) {
    col.setStroke(); let path = NSBezierPath(); path.move(to: P(R, a.0, a.1))
    path.curve(to: P(R, b.0, b.1), controlPoint1: P(R, c1.0, c1.1), controlPoint2: P(R, c2.0, c2.1))
    path.lineWidth = S(R, w); path.lineCapStyle = .round; path.stroke()
}
func leafShape(_ R: NSRect, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat, _ c: NSColor) {
    c.setFill(); let path = NSBezierPath()
    let base = P(R, cx - s * 0.55, cy + s * 0.55), tip = P(R, cx + s * 0.55, cy - s * 0.55)
    path.move(to: base)
    path.curve(to: tip, controlPoint1: P(R, cx - s * 0.5, cy - s * 0.3), controlPoint2: P(R, cx + s * 0.05, cy - s * 0.65))
    path.curve(to: base, controlPoint1: P(R, cx + s * 0.3, cy + s * 0.05), controlPoint2: P(R, cx - s * 0.05, cy + s * 0.65))
    path.fill()
}
func text(_ R: NSRect, _ s: String, _ size: CGFloat, _ weight: NSFont.Weight, _ c: NSColor, _ cy: CGFloat) {
    let p = NSMutableParagraphStyle(); p.alignment = .center
    let f = NSFont.systemFont(ofSize: S(R, size), weight: weight)
    let attrs: [NSAttributedString.Key: Any] = [.font: f, .foregroundColor: c, .paragraphStyle: p]
    let str = s as NSString; let sz = str.size(withAttributes: attrs)
    let center = P(R, 0.5, cy)
    str.draw(at: NSPoint(x: center.x - sz.width / 2, y: center.y - sz.height / 2), withAttributes: attrs)
}

// A reusable flat basket centred at (cx,cy), width w (normalized).
func basket(_ R: NSRect, _ cx: CGFloat, _ cy: CGFloat, _ w: CGFloat,
            body: NSColor, rim: NSColor, handle: NSColor, cloth: NSColor? = nil, weave: NSColor? = nil) {
    let h = w * 0.72
    curve(R, (cx - w * 0.30, cy - h * 0.10), (cx - w * 0.20, cy - h * 0.78), (cx + w * 0.20, cy - h * 0.78), (cx + w * 0.30, cy - h * 0.10), w * 0.08, handle)
    if let cloth { poly(R, [(cx - w * 0.26, cy - h * 0.10), (cx + w * 0.26, cy - h * 0.10), (cx, cy - h * 0.48)], cloth) }
    poly(R, [(cx - w * 0.50, cy - h * 0.08), (cx + w * 0.50, cy - h * 0.08), (cx + w * 0.36, cy + h * 0.55), (cx - w * 0.36, cy + h * 0.55)], body)
    box(R, cx - w * 0.56, cy - h * 0.20, w * 1.12, h * 0.15, w * 0.05, rim)
    if let weave {
        for vy in [0.12, 0.32] { line(R, [(cx - w * 0.34, cy + h * CGFloat(vy)), (cx + w * 0.34, cy + h * CGFloat(vy))], w * 0.028, weave) }
        for vx in stride(from: CGFloat(-0.3), through: 0.3, by: 0.15) { line(R, [(cx + vx * w, cy - h * 0.05), (cx + vx * w * 0.78, cy + h * 0.5)], w * 0.02, weave) }
    }
}
func basketLine(_ R: NSRect, _ cx: CGFloat, _ cy: CGFloat, _ w: CGFloat, _ c: NSColor, _ lw: CGFloat) {
    let h = w * 0.72
    line(R, [(cx - w * 0.5, cy - h * 0.15), (cx + w * 0.5, cy - h * 0.15), (cx + w * 0.36, cy + h * 0.55), (cx - w * 0.36, cy + h * 0.55)], lw, c, closed: true)
    curve(R, (cx - w * 0.30, cy - h * 0.15), (cx - w * 0.20, cy - h * 0.80), (cx + w * 0.20, cy - h * 0.80), (cx + w * 0.30, cy - h * 0.15), lw, c)
    line(R, [(cx - w * 0.40, cy + h * 0.15), (cx + w * 0.40, cy + h * 0.15)], lw, c)
}

typealias Draw = (NSRect) -> Void
struct Style { let label: String; let draw: Draw }

let styles: [Style] = [
    Style(label: "A solid · knockout") { R in
        fill(R, leaf); basket(R, 0.5, 0.52, 0.5, body: cream, rim: cream, handle: cream, cloth: leaf)
    },
    Style(label: "B dark · moody") { R in
        fill(R, leafDk); basket(R, 0.5, 0.54, 0.52, body: kraft, rim: tan, handle: kraftDk, cloth: cream, weave: kraftDk)
        leafShape(R, 0.72, 0.30, 0.10, lime)
    },
    Style(label: "C full-bleed") { R in
        fill(R, paper); basket(R, 0.5, 0.74, 0.95, body: kraft, rim: kraftDk, handle: kraftDk, cloth: cream, weave: kraftDk)
    },
    Style(label: "D duotone") { R in
        fill(R, cream); basket(R, 0.5, 0.54, 0.58, body: tomato, rim: tomato, handle: tomato, cloth: cream)
    },
    Style(label: "E long shadow") { R in
        fill(R, coral)
        poly(R, [(0.5, 0.30), (1.0, 0.80), (1.0, 1.0), (0.30, 1.0)], NSColor(white: 0, alpha: 0.12))
        basket(R, 0.46, 0.50, 0.5, body: leafDk, rim: leafDk, handle: leafDk, cloth: cream)
    },
    Style(label: "F monogram") { R in
        fill(R, leaf); text(R, "B", 0.62, .black, cream, 0.52)
    },
    Style(label: "G oversized crop") { R in
        fill(R, mustard); basket(R, 0.34, 0.40, 1.0, body: leafDk, rim: leafDk, handle: leafDk, cloth: cream)
    },
    Style(label: "H pattern") { R in
        fill(R, leaf)
        for r in 0..<5 { for c in 0..<5 {
            let x = 0.1 + CGFloat(c) * 0.2, y = 0.1 + CGFloat(r) * 0.2
            if (r + c) % 2 == 0 { disc(R, x, y, 0.045, cream.withAlphaComponent(0.9)) }
            else { leafShape(R, x, y, 0.06, cream.withAlphaComponent(0.85)) }
        } }
    },
    Style(label: "I sticker") { R in
        fill(R, mustard)
        // white sticker outline behind the basket
        basket(R, 0.5, 0.53, 0.56, body: cream, rim: cream, handle: cream)
        basket(R, 0.5, 0.52, 0.5, body: tomato, rim: kraftDk, handle: kraftDk, cloth: cream, weave: tomato)
    },
    Style(label: "J line-art") { R in
        fill(R, leafDk); basketLine(R, 0.5, 0.54, 0.5, cream, 0.03)
    },
    Style(label: "K scene · shelf") { R in
        fill(R, NSColor(srgbRed: 0.97, green: 0.90, blue: 0.80, alpha: 1))
        box(R, 0.0, 0.66, 1.0, 0.34, 0.0, kraft)            // shelf
        disc(R, 0.78, 0.30, 0.10, mustard)                  // sun / fruit accent
        basket(R, 0.45, 0.60, 0.5, body: kraftDk, rim: ink, handle: ink, cloth: cream, weave: tan)
    },
    Style(label: "L bold gradient") { R in
        grad(R, leafDk, lime, -45); basket(R, 0.5, 0.53, 0.5, body: cream, rim: cream, handle: cream, cloth: leafDk)
    },
]

let cols = 4, iconSize: CGFloat = 260, pad: CGFloat = 26, labelH: CGFloat = 32
let rows = (styles.count + cols - 1) / cols
let cellW = iconSize + pad, cellH = iconSize + labelH + pad
let W = CGFloat(cols) * cellW + pad, H = CGFloat(rows) * cellH + pad

let image = NSImage(size: NSSize(width: W, height: H))
image.lockFocus()
NSColor(white: 0.95, alpha: 1).setFill(); NSRect(x: 0, y: 0, width: W, height: H).fill()

for (i, s) in styles.enumerated() {
    let col = i % cols, row = i / cols
    let x = pad + CGFloat(col) * cellW
    let yTop = H - pad - CGFloat(row) * cellH
    let iconRect = NSRect(x: x, y: yTop - iconSize, width: iconSize, height: iconSize)
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: iconRect, xRadius: iconSize * 0.22, yRadius: iconSize * 0.22).addClip()
    s.draw(iconRect)
    NSGraphicsContext.restoreGraphicsState()
    let p = NSMutableParagraphStyle(); p.alignment = .center
    (s.label as NSString).draw(in: NSRect(x: x - 4, y: yTop - iconSize - labelH + 6, width: iconSize + 8, height: labelH),
        withAttributes: [.font: NSFont.systemFont(ofSize: 15, weight: .semibold), .foregroundColor: ink, .paragraphStyle: p])
}

image.unlockFocus()
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "styles.png"
let tiff = image.tiffRepresentation!
let png = NSBitmapImageRep(data: tiff)!.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out) with \(styles.count) styles")
