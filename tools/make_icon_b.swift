// 20 variations on the "dark / moody" icon direction: a deep background, a warm
// woven basket, optional leaf/fruit accent, weave detail, soft glow and scale.
// Run: swift tools/make_icon_b.swift <out.png>
import AppKit

// dark backgrounds
let bgGreen  = NSColor(srgbRed: 0.16, green: 0.32, blue: 0.24, alpha: 1)
let bgForest = NSColor(srgbRed: 0.11, green: 0.25, blue: 0.18, alpha: 1)
let bgPine   = NSColor(srgbRed: 0.08, green: 0.17, blue: 0.13, alpha: 1)
let bgCharc  = NSColor(srgbRed: 0.17, green: 0.18, blue: 0.17, alpha: 1)
let bgTeal   = NSColor(srgbRed: 0.09, green: 0.27, blue: 0.29, alpha: 1)
let bgNavy   = NSColor(srgbRed: 0.13, green: 0.19, blue: 0.32, alpha: 1)
let bgPlum   = NSColor(srgbRed: 0.22, green: 0.14, blue: 0.26, alpha: 1)
let bgBrown  = NSColor(srgbRed: 0.20, green: 0.15, blue: 0.11, alpha: 1)
let bgOlive  = NSColor(srgbRed: 0.20, green: 0.23, blue: 0.13, alpha: 1)
let bgSlate  = NSColor(srgbRed: 0.18, green: 0.28, blue: 0.27, alpha: 1)

// basket warmth
let kraft  = NSColor(srgbRed: 0.82, green: 0.61, blue: 0.39, alpha: 1)
let kraftD = NSColor(srgbRed: 0.58, green: 0.41, blue: 0.24, alpha: 1)
let honey  = NSColor(srgbRed: 0.87, green: 0.66, blue: 0.34, alpha: 1)
let honeyD = NSColor(srgbRed: 0.66, green: 0.46, blue: 0.22, alpha: 1)
let tan    = NSColor(srgbRed: 0.89, green: 0.73, blue: 0.50, alpha: 1)
let tanD   = NSColor(srgbRed: 0.66, green: 0.50, blue: 0.30, alpha: 1)
let wick   = NSColor(srgbRed: 0.72, green: 0.52, blue: 0.32, alpha: 1)
let wickD  = NSColor(srgbRed: 0.50, green: 0.34, blue: 0.20, alpha: 1)

let cream  = NSColor(srgbRed: 0.98, green: 0.96, blue: 0.90, alpha: 1)
let lime   = NSColor(srgbRed: 0.74, green: 0.86, blue: 0.40, alpha: 1)
let leaf   = NSColor(srgbRed: 0.46, green: 0.68, blue: 0.40, alpha: 1)
let tomato = NSColor(srgbRed: 0.89, green: 0.42, blue: 0.38, alpha: 1)
let orange = NSColor(srgbRed: 0.95, green: 0.64, blue: 0.30, alpha: 1)
let yellow = NSColor(srgbRed: 0.96, green: 0.80, blue: 0.34, alpha: 1)
let ink    = NSColor(srgbRed: 0.22, green: 0.20, blue: 0.18, alpha: 1)

func P(_ R: NSRect, _ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: R.minX + x * R.width, y: R.maxY - y * R.height) }
func S(_ R: NSRect, _ v: CGFloat) -> CGFloat { v * R.width }
func fill(_ R: NSRect, _ c: NSColor) { c.setFill(); NSBezierPath(rect: R).fill() }
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
func glow(_ R: NSRect, _ c: NSColor) {
    let p = P(R, 0.5, 0.52); let rad = S(R, 0.46)
    NSGradient(colors: [c.withAlphaComponent(0.55), c.withAlphaComponent(0)])!
        .draw(in: NSRect(x: p.x - rad, y: p.y - rad, width: rad * 2, height: rad * 2), relativeCenterPosition: NSPoint(x: 0, y: 0.1))
}
func basket(_ R: NSRect, _ cx: CGFloat, _ cy: CGFloat, _ w: CGFloat,
            body: NSColor, rim: NSColor, handle: NSColor, cloth: NSColor, weave: NSColor?) {
    let h = w * 0.72
    curve(R, (cx - w * 0.30, cy - h * 0.10), (cx - w * 0.20, cy - h * 0.80), (cx + w * 0.20, cy - h * 0.80), (cx + w * 0.30, cy - h * 0.10), w * 0.085, handle)
    poly(R, [(cx - w * 0.26, cy - h * 0.10), (cx + w * 0.26, cy - h * 0.10), (cx, cy - h * 0.50)], cloth)
    poly(R, [(cx - w * 0.50, cy - h * 0.08), (cx + w * 0.50, cy - h * 0.08), (cx + w * 0.36, cy + h * 0.55), (cx - w * 0.36, cy + h * 0.55)], body)
    box(R, cx - w * 0.56, cy - h * 0.20, w * 1.12, h * 0.15, w * 0.05, rim)
    if let weave {
        for vy in [0.12, 0.32] { line(R, [(cx - w * 0.33, cy + h * CGFloat(vy)), (cx + w * 0.33, cy + h * CGFloat(vy))], w * 0.026, weave) }
        for vx in stride(from: CGFloat(-0.28), through: 0.28, by: 0.14) { line(R, [(cx + vx * w, cy - h * 0.04), (cx + vx * w * 0.78, cy + h * 0.5)], w * 0.018, weave) }
    }
}

typealias Acc = (NSRect, CGFloat, CGFloat) -> Void  // R, cx, cy(top of basket area)
let aLeaf: Acc = { R, cx, cy in leafShape(R, cx + 0.20, cy - 0.04, 0.10, lime) }
let aTwoLeaf: Acc = { R, cx, cy in leafShape(R, cx + 0.17, cy - 0.02, 0.09, lime); leafShape(R, cx + 0.25, cy + 0.04, 0.07, leaf) }
let aTomato: Acc = { R, cx, cy in disc(R, cx + 0.05, cy + 0.02, 0.075, tomato); leafShape(R, cx + 0.10, cy - 0.04, 0.045, lime) }
let aBerries: Acc = { R, cx, cy in disc(R, cx - 0.05, cy + 0.03, 0.04, tomato); disc(R, cx + 0.04, cy + 0.04, 0.04, tomato); disc(R, cx, cy, 0.04, tomato) }
let aMixed: Acc = { R, cx, cy in disc(R, cx - 0.07, cy + 0.03, 0.055, tomato); disc(R, cx + 0.05, cy + 0.03, 0.05, orange); disc(R, cx, cy - 0.03, 0.045, lime) }
let aLemon: Acc = { R, cx, cy in disc(R, cx + 0.03, cy + 0.02, 0.06, yellow) }
let aHerbs: Acc = { R, cx, cy in leafShape(R, cx - 0.03, cy - 0.02, 0.06, lime); leafShape(R, cx + 0.04, cy - 0.04, 0.06, leaf); leafShape(R, cx, cy, 0.05, lime) }
let aNone: Acc = { _, _, _ in }

struct V {
    let bg, body, rim, handle, cloth: NSColor
    let weave: NSColor?
    let acc: Acc
    var w: CGFloat = 0.52
    var cy: CGFloat = 0.54
    var glowC: NSColor? = nil
}

let variations: [V] = [
    V(bg: bgGreen,  body: kraft, rim: kraftD, handle: kraftD, cloth: cream, weave: kraftD, acc: aLeaf),
    V(bg: bgForest, body: kraft, rim: kraftD, handle: kraftD, cloth: cream, weave: kraftD, acc: aTomato),
    V(bg: bgPine,   body: honey, rim: honeyD, handle: honeyD, cloth: cream, weave: honeyD, acc: aMixed, glowC: leaf),
    V(bg: bgCharc,  body: tan,   rim: tanD,   handle: tanD,   cloth: cream, weave: tanD,   acc: aLeaf),
    V(bg: bgTeal,   body: kraft, rim: kraftD, handle: kraftD, cloth: cream, weave: kraftD, acc: aTwoLeaf),
    V(bg: bgNavy,   body: honey, rim: honeyD, handle: honeyD, cloth: cream, weave: honeyD, acc: aLemon),
    V(bg: bgPlum,   body: kraft, rim: kraftD, handle: kraftD, cloth: cream, weave: kraftD, acc: aBerries),
    V(bg: bgBrown,  body: tan,   rim: tanD,   handle: tanD,   cloth: cream, weave: tanD,   acc: aLeaf, glowC: honey),
    V(bg: bgOlive,  body: wick,  rim: wickD,  handle: wickD,  cloth: cream, weave: wickD,  acc: aMixed),
    V(bg: bgSlate,  body: kraft, rim: kraftD, handle: kraftD, cloth: cream, weave: kraftD, acc: aNone, glowC: leaf),
    V(bg: bgGreen,  body: wick,  rim: wickD,  handle: wickD,  cloth: cream, weave: wickD,  acc: aTomato),
    V(bg: bgForest, body: honey, rim: honeyD, handle: honeyD, cloth: cream, weave: honeyD, acc: aHerbs, glowC: leaf),
    V(bg: bgPine,   body: kraft, rim: kraftD, handle: kraftD, cloth: cream, weave: nil,    acc: aLeaf, glowC: leaf),
    V(bg: bgTeal,   body: tan,   rim: tanD,   handle: tanD,   cloth: cream, weave: tanD,   acc: aTomato),
    V(bg: bgNavy,   body: kraft, rim: kraftD, handle: kraftD, cloth: cream, weave: kraftD, acc: aTwoLeaf, glowC: leaf),
    V(bg: bgGreen,  body: honey, rim: honeyD, handle: honeyD, cloth: cream, weave: honeyD, acc: aBerries),
    V(bg: bgCharc,  body: honey, rim: honeyD, handle: honeyD, cloth: cream, weave: honeyD, acc: aMixed, glowC: honey),
    V(bg: bgPlum,   body: tan,   rim: tanD,   handle: tanD,   cloth: cream, weave: tanD,   acc: aLemon),
    V(bg: bgPine,   body: kraft, rim: kraftD, handle: kraftD, cloth: cream, weave: kraftD, acc: aLeaf, w: 0.62, cy: 0.56),
    V(bg: bgForest, body: kraft, rim: kraftD, handle: kraftD, cloth: cream, weave: kraftD, acc: aLeaf, w: 0.84, cy: 0.66, glowC: leaf),
]

let cols = 5, iconSize: CGFloat = 230, pad: CGFloat = 22, labelH: CGFloat = 26
let rows = (variations.count + cols - 1) / cols
let cellW = iconSize + pad, cellH = iconSize + labelH + pad
let W = CGFloat(cols) * cellW + pad, H = CGFloat(rows) * cellH + pad

let image = NSImage(size: NSSize(width: W, height: H))
image.lockFocus()
NSColor(white: 0.95, alpha: 1).setFill(); NSRect(x: 0, y: 0, width: W, height: H).fill()

for (i, v) in variations.enumerated() {
    let col = i % cols, row = i / cols
    let x = pad + CGFloat(col) * cellW
    let yTop = H - pad - CGFloat(row) * cellH
    let iconRect = NSRect(x: x, y: yTop - iconSize, width: iconSize, height: iconSize)
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: iconRect, xRadius: iconSize * 0.22, yRadius: iconSize * 0.22).addClip()
    fill(iconRect, v.bg)
    if let g = v.glowC { glow(iconRect, g) }
    basket(iconRect, 0.5, v.cy, v.w, body: v.body, rim: v.rim, handle: v.handle, cloth: v.cloth, weave: v.weave)
    let h = v.w * 0.72
    v.acc(iconRect, 0.5, v.cy - h * 0.42)   // accent near the basket mouth
    NSGraphicsContext.restoreGraphicsState()
    let p = NSMutableParagraphStyle(); p.alignment = .center
    ("B\(i + 1)" as NSString).draw(in: NSRect(x: x, y: yTop - iconSize - labelH + 4, width: iconSize, height: labelH),
        withAttributes: [.font: NSFont.systemFont(ofSize: 14, weight: .semibold), .foregroundColor: ink, .paragraphStyle: p])
}

image.unlockFocus()
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "b.png"
let tiff = image.tiffRepresentation!
let png = NSBitmapImageRep(data: tiff)!.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out) with \(variations.count) variations")
