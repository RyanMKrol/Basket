// Renders Basket's 1024×1024 app icon natively on macOS (AppKit): a warm woven
// basket (cream cloth, kraft weave, lime leaf) sitting on a darker "shelf",
// against a polka-dot green "wall". Edge-to-edge (iOS rounds the corners).
// Run: swift tools/make_icon.swift <output.png>
import AppKit

// Palette.
let wallTop = NSColor(srgbRed: 0.22, green: 0.40, blue: 0.30, alpha: 1)   // lighter wall (top)
let wallBot = NSColor(srgbRed: 0.17, green: 0.34, blue: 0.26, alpha: 1)
let shelf   = NSColor(srgbRed: 0.10, green: 0.22, blue: 0.16, alpha: 1)   // darker shelf band
let kraft  = NSColor(srgbRed: 0.82, green: 0.61, blue: 0.39, alpha: 1)
let kraftD = NSColor(srgbRed: 0.58, green: 0.41, blue: 0.24, alpha: 1)
let cream  = NSColor(srgbRed: 0.98, green: 0.96, blue: 0.90, alpha: 1)
let lime   = NSColor(srgbRed: 0.74, green: 0.86, blue: 0.40, alpha: 1)
let leaf   = NSColor(srgbRed: 0.46, green: 0.68, blue: 0.40, alpha: 1)

func P(_ R: NSRect, _ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: R.minX + x * R.width, y: R.maxY - y * R.height) }
func S(_ R: NSRect, _ v: CGFloat) -> CGFloat { v * R.width }
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
func line(_ R: NSRect, _ pts: [(CGFloat, CGFloat)], _ w: CGFloat, _ c: NSColor) {
    c.setStroke(); let path = NSBezierPath()
    for (i, p) in pts.enumerated() { let q = P(R, p.0, p.1); if i == 0 { path.move(to: q) } else { path.line(to: q) } }
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

func basket(_ R: NSRect, _ cx: CGFloat, _ cy: CGFloat, _ w: CGFloat) {
    let h = w * 0.72
    curve(R, (cx - w * 0.30, cy - h * 0.10), (cx - w * 0.20, cy - h * 0.80), (cx + w * 0.20, cy - h * 0.80), (cx + w * 0.30, cy - h * 0.10), w * 0.085, kraftD)
    poly(R, [(cx - w * 0.26, cy - h * 0.10), (cx + w * 0.26, cy - h * 0.10), (cx, cy - h * 0.50)], cream)
    poly(R, [(cx - w * 0.50, cy - h * 0.08), (cx + w * 0.50, cy - h * 0.08), (cx + w * 0.36, cy + h * 0.55), (cx - w * 0.36, cy + h * 0.55)], kraft)
    box(R, cx - w * 0.56, cy - h * 0.20, w * 1.12, h * 0.15, w * 0.05, kraftD)
    for vy in [0.12, 0.32] { line(R, [(cx - w * 0.33, cy + h * CGFloat(vy)), (cx + w * 0.33, cy + h * CGFloat(vy))], w * 0.026, kraftD) }
    for vx in stride(from: CGFloat(-0.28), through: 0.28, by: 0.14) {
        line(R, [(cx + vx * w, cy - h * 0.04), (cx + vx * w * 0.78, cy + h * 0.5)], w * 0.018, kraftD)
    }
}

let side: CGFloat = 1024
let image = NSImage(size: NSSize(width: side, height: side))
image.lockFocus()
let R = NSRect(x: 0, y: 0, width: side, height: side)
// Background: a polka-dot "wall" (lighter green) above a darker "shelf".
NSGradient(colors: [wallTop, wallBot])!.draw(in: R, angle: -90)
for row in 0..<7 { for col in 0..<8 {
    let dx = 0.06 + CGFloat(col) * 0.125, dy = 0.05 + CGFloat(row) * 0.105
    if dy < 0.66 { disc(R, dx, dy, 0.016, NSColor.white.withAlphaComponent(0.10)) }   // dots on the wall only
} }
box(R, 0, 0.70, 1.0, 0.30, 0, shelf)

let cx: CGFloat = 0.5, cy: CGFloat = 0.55, w: CGFloat = 0.57, h = w * 0.72
// Soft shadow grounding the basket on the shelf.
NSColor.black.withAlphaComponent(0.18).setFill()
let sp = P(R, cx, cy + h * 0.57), sw = S(R, w * 0.44), sh = S(R, w * 0.07)
NSBezierPath(ovalIn: NSRect(x: sp.x - sw, y: sp.y - sh, width: sw * 2, height: sh * 2)).fill()
basket(R, cx, cy, w)
leafShape(R, cx + 0.20, cy - h * 0.42 - 0.04, 0.11, lime)
image.unlockFocus()

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"
guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else { fputs("render failed\n", stderr); exit(1) }
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
