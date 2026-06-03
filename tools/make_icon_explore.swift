// Renders 20 variations on the dark woven-basket icon — sweeping background
// treatment (gradient / glow / vignette / shelf / circle / dots), basket depth
// (flat vs gradient body, drop shadow), warmth, accent (leaf / fruit / herbs /
// none) and scale — to find a richer, less-basic direction.
// Run: swift tools/make_icon_explore.swift <out.png>
import AppKit

let gDeep  = NSColor(srgbRed: 0.16, green: 0.32, blue: 0.24, alpha: 1)
let gDeep2 = NSColor(srgbRed: 0.12, green: 0.26, blue: 0.19, alpha: 1)
let forest = NSColor(srgbRed: 0.11, green: 0.25, blue: 0.18, alpha: 1)
let pine   = NSColor(srgbRed: 0.08, green: 0.17, blue: 0.13, alpha: 1)
let teal   = NSColor(srgbRed: 0.09, green: 0.27, blue: 0.29, alpha: 1)

let kraftT = NSColor(srgbRed: 0.85, green: 0.64, blue: 0.42, alpha: 1)
let kraftB = NSColor(srgbRed: 0.71, green: 0.51, blue: 0.31, alpha: 1)
let rimC   = NSColor(srgbRed: 0.58, green: 0.41, blue: 0.24, alpha: 1)
let handle = NSColor(srgbRed: 0.55, green: 0.38, blue: 0.23, alpha: 1)
let weaveC = NSColor(srgbRed: 0.55, green: 0.39, blue: 0.23, alpha: 1)
let honeyT = NSColor(srgbRed: 0.89, green: 0.68, blue: 0.36, alpha: 1)
let honeyB = NSColor(srgbRed: 0.75, green: 0.54, blue: 0.26, alpha: 1)
let tanT   = NSColor(srgbRed: 0.90, green: 0.75, blue: 0.52, alpha: 1)
let tanB   = NSColor(srgbRed: 0.78, green: 0.62, blue: 0.40, alpha: 1)
let cream  = NSColor(srgbRed: 0.98, green: 0.96, blue: 0.90, alpha: 1)
let lime   = NSColor(srgbRed: 0.74, green: 0.86, blue: 0.40, alpha: 1)
let leafG  = NSColor(srgbRed: 0.50, green: 0.72, blue: 0.42, alpha: 1)
let tomato = NSColor(srgbRed: 0.89, green: 0.42, blue: 0.38, alpha: 1)
let orange = NSColor(srgbRed: 0.95, green: 0.64, blue: 0.30, alpha: 1)
let ink    = NSColor(srgbRed: 0.20, green: 0.18, blue: 0.16, alpha: 1)

func P(_ R: NSRect, _ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: R.minX + x * R.width, y: R.maxY - y * R.height) }
func S(_ R: NSRect, _ v: CGFloat) -> CGFloat { v * R.width }
func fill(_ R: NSRect, _ c: NSColor) { c.setFill(); NSBezierPath(rect: R).fill() }
func grad(_ R: NSRect, _ a: NSColor, _ b: NSColor) { NSGradient(colors: [a, b])!.draw(in: R, angle: -90) }
func disc(_ R: NSRect, _ cx: CGFloat, _ cy: CGFloat, _ rad: CGFloat, _ c: NSColor) {
    c.setFill(); let p = P(R, cx, cy)
    NSBezierPath(ovalIn: NSRect(x: p.x - S(R, rad), y: p.y - S(R, rad), width: S(R, rad) * 2, height: S(R, rad) * 2)).fill()
}
func box(_ R: NSRect, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ rad: CGFloat, _ c: NSColor) {
    c.setFill(); let tl = P(R, x, y)
    NSBezierPath(roundedRect: NSRect(x: tl.x, y: tl.y - S(R, h), width: S(R, w), height: S(R, h)), xRadius: S(R, rad), yRadius: S(R, rad)).fill()
}
func pathPoly(_ R: NSRect, _ pts: [(CGFloat, CGFloat)]) -> NSBezierPath {
    let path = NSBezierPath()
    for (i, p) in pts.enumerated() { let q = P(R, p.0, p.1); if i == 0 { path.move(to: q) } else { path.line(to: q) } }
    path.close(); return path
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
func glow(_ R: NSRect, _ c: NSColor) {
    let p = P(R, 0.5, 0.55); let rad = S(R, 0.5)
    NSGradient(colors: [c.withAlphaComponent(0.55), c.withAlphaComponent(0)])!
        .draw(in: NSRect(x: p.x - rad, y: p.y - rad, width: rad * 2, height: rad * 2), relativeCenterPosition: .zero)
}
func vignette(_ R: NSRect) {
    let p = P(R, 0.5, 0.5); let rad = S(R, 0.75)
    NSGradient(colors: [NSColor.clear, NSColor.black.withAlphaComponent(0.28)])!
        .draw(in: NSRect(x: p.x - rad, y: p.y - rad, width: rad * 2, height: rad * 2), relativeCenterPosition: .zero)
}

func basket(_ R: NSRect, _ cx: CGFloat, _ cy: CGFloat, _ w: CGFloat,
            top: NSColor, bot: NSColor, rim: NSColor, hdl: NSColor, weave: NSColor, cloth: NSColor,
            gradientBody: Bool, shadow: Bool) {
    let h = w * 0.72
    if shadow {
        NSColor.black.withAlphaComponent(0.16).setFill()
        let p = P(R, cx, cy + h * 0.56); let rw = S(R, w * 0.42), rh = S(R, w * 0.08)
        NSBezierPath(ovalIn: NSRect(x: p.x - rw, y: p.y - rh, width: rw * 2, height: rh * 2)).fill()
    }
    curve(R, (cx - w * 0.30, cy - h * 0.10), (cx - w * 0.20, cy - h * 0.80), (cx + w * 0.20, cy - h * 0.80), (cx + w * 0.30, cy - h * 0.10), w * 0.085, hdl)
    let cl = pathPoly(R, [(cx - w * 0.26, cy - h * 0.10), (cx + w * 0.26, cy - h * 0.10), (cx, cy - h * 0.50)]); cloth.setFill(); cl.fill()
    let body = pathPoly(R, [(cx - w * 0.50, cy - h * 0.08), (cx + w * 0.50, cy - h * 0.08), (cx + w * 0.36, cy + h * 0.55), (cx - w * 0.36, cy + h * 0.55)])
    if gradientBody {
        NSGraphicsContext.saveGraphicsState(); body.addClip(); grad(body.bounds, top, bot); NSGraphicsContext.restoreGraphicsState()
    } else { top.setFill(); body.fill() }
    box(R, cx - w * 0.56, cy - h * 0.20, w * 1.12, h * 0.15, w * 0.05, rim)
    for vy in [0.12, 0.32] { line(R, [(cx - w * 0.33, cy + h * CGFloat(vy)), (cx + w * 0.33, cy + h * CGFloat(vy))], w * 0.026, weave) }
    for vx in stride(from: CGFloat(-0.28), through: 0.28, by: 0.14) { line(R, [(cx + vx * w, cy - h * 0.04), (cx + vx * w * 0.78, cy + h * 0.5)], w * 0.018, weave) }
}

// Accent helpers, positioned relative to the basket mouth.
func accLeaf(_ R: NSRect, _ cx: CGFloat, _ top: CGFloat) { leafShape(R, cx + 0.20, top - 0.04, 0.11, lime) }
func accFruit(_ R: NSRect, _ cx: CGFloat, _ top: CGFloat) {
    disc(R, cx - 0.10, top + 0.04, 0.075, tomato); disc(R, cx + 0.02, top + 0.05, 0.07, orange); disc(R, cx + 0.12, top + 0.03, 0.07, leafG)
}
func accApple(_ R: NSRect, _ cx: CGFloat, _ top: CGFloat) { disc(R, cx + 0.02, top + 0.02, 0.085, tomato); leafShape(R, cx + 0.10, top - 0.05, 0.05, lime) }
func accHerbs(_ R: NSRect, _ cx: CGFloat, _ top: CGFloat) { leafShape(R, cx - 0.05, top - 0.02, 0.07, lime); leafShape(R, cx + 0.05, top - 0.05, 0.07, leafG); leafShape(R, cx, top + 0.01, 0.06, lime) }

struct V {
    let label: String
    let draw: (NSRect) -> Void
}

func make(bg: @escaping (NSRect) -> Void, warmth: (NSColor, NSColor), grad gradientBody: Bool, shadow: Bool,
          scale: CGFloat = 0.58, accent: ((NSRect, CGFloat, CGFloat) -> Void)? = nil, cy: CGFloat = 0.54) -> (NSRect) -> Void {
    return { R in
        bg(R)
        basket(R, 0.5, cy, scale, top: warmth.0, bot: warmth.1, rim: rimC, hdl: handle, weave: weaveC, cloth: cream, gradientBody: gradientBody, shadow: shadow)
        accent?(R, 0.5, cy - scale * 0.72 * 0.42)
    }
}

let bgGradient: (NSRect) -> Void = { grad($0, gDeep, gDeep2) }
let bgSolid: (NSRect) -> Void = { fill($0, gDeep) }
let bgGlow: (NSRect) -> Void = { fill($0, gDeep); glow($0, leafG) }
let bgVignette: (NSRect) -> Void = { grad($0, gDeep, gDeep2); vignette($0) }
let bgForest: (NSRect) -> Void = { grad($0, forest, pine) }
let bgPine: (NSRect) -> Void = { fill($0, pine); glow($0, NSColor(srgbRed: 0.3, green: 0.5, blue: 0.35, alpha: 1)) }
let bgTeal: (NSRect) -> Void = { grad($0, teal, NSColor(srgbRed: 0.06, green: 0.18, blue: 0.20, alpha: 1)) }
let bgShelf: (NSRect) -> Void = { R in grad(R, gDeep, gDeep2); box(R, 0, 0.70, 1.0, 0.30, 0, NSColor(srgbRed: 0.10, green: 0.22, blue: 0.16, alpha: 1)) }
let bgCircle: (NSRect) -> Void = { R in fill(R, gDeep); disc(R, 0.5, 0.52, 0.40, NSColor(srgbRed: 0.22, green: 0.40, blue: 0.30, alpha: 1)) }
let bgDots: (NSRect) -> Void = { R in grad(R, gDeep, gDeep2)
    for r in 0..<7 { for c in 0..<7 { disc(R, 0.07 + CGFloat(c) * 0.14, 0.07 + CGFloat(r) * 0.14, 0.012, NSColor.white.withAlphaComponent(0.05)) } } }

let variations: [V] = [
    V(label: "1 baseline+10%") { make(bg: bgGradient, warmth: (kraftT, kraftT), grad: false, shadow: false, accent: accLeaf)($0) },
    V(label: "2 gradient body") { make(bg: bgGradient, warmth: (kraftT, kraftB), grad: true, shadow: false, accent: accLeaf)($0) },
    V(label: "3 + drop shadow") { make(bg: bgGradient, warmth: (kraftT, kraftB), grad: true, shadow: true, accent: accLeaf)($0) },
    V(label: "4 + glow") { make(bg: bgGlow, warmth: (kraftT, kraftB), grad: true, shadow: false, accent: accLeaf)($0) },
    V(label: "5 fruit trio") { make(bg: bgGradient, warmth: (kraftT, kraftB), grad: true, shadow: true, accent: accFruit)($0) },
    V(label: "6 bigger") { make(bg: bgGradient, warmth: (kraftT, kraftB), grad: true, shadow: true, scale: 0.66, accent: accLeaf, cy: 0.55)($0) },
    V(label: "7 solid + shadow") { make(bg: bgSolid, warmth: (kraftT, kraftB), grad: true, shadow: true, accent: accLeaf)($0) },
    V(label: "8 shelf") { make(bg: bgShelf, warmth: (kraftT, kraftB), grad: true, shadow: true, accent: accLeaf, cy: 0.55)($0) },
    V(label: "9 circle backdrop") { make(bg: bgCircle, warmth: (kraftT, kraftB), grad: true, shadow: false, accent: accLeaf)($0) },
    V(label: "10 honey") { make(bg: bgGradient, warmth: (honeyT, honeyB), grad: true, shadow: true, accent: accLeaf)($0) },
    V(label: "11 vignette+glow") { make(bg: bgVignette, warmth: (kraftT, kraftB), grad: true, shadow: false, accent: accLeaf)($0) },
    V(label: "12 apple") { make(bg: bgGradient, warmth: (kraftT, kraftB), grad: true, shadow: true, accent: accApple)($0) },
    V(label: "13 dots") { make(bg: bgDots, warmth: (kraftT, kraftB), grad: true, shadow: true, accent: accLeaf)($0) },
    V(label: "14 forest+tan") { make(bg: bgForest, warmth: (tanT, tanB), grad: true, shadow: true, accent: accLeaf)($0) },
    V(label: "15 herbs") { make(bg: bgGradient, warmth: (kraftT, kraftB), grad: true, shadow: true, accent: accHerbs)($0) },
    V(label: "16 pine+glow") { make(bg: bgPine, warmth: (honeyT, honeyB), grad: true, shadow: true, accent: accLeaf)($0) },
    V(label: "17 teal") { make(bg: bgTeal, warmth: (kraftT, kraftB), grad: true, shadow: true, accent: accLeaf)($0) },
    V(label: "18 minimal") { make(bg: bgGradient, warmth: (kraftT, kraftB), grad: true, shadow: true, scale: 0.62, accent: nil)($0) },
    V(label: "19 overflowing") { make(bg: bgGlow, warmth: (kraftT, kraftB), grad: true, shadow: true, accent: accFruit, cy: 0.56)($0) },
    V(label: "20 the works") { make(bg: bgPine, warmth: (kraftT, kraftB), grad: true, shadow: true, scale: 0.6, accent: accLeaf)($0) },
]

let cols = 5, iconSize: CGFloat = 230, pad: CGFloat = 22, labelH: CGFloat = 28
let rows = (variations.count + cols - 1) / cols
let cellW = iconSize + pad, cellH = iconSize + labelH + pad
let W = CGFloat(cols) * cellW + pad, H = CGFloat(rows) * cellH + pad
let image = NSImage(size: NSSize(width: W, height: H))
image.lockFocus()
NSColor(white: 0.95, alpha: 1).setFill(); NSRect(x: 0, y: 0, width: W, height: H).fill()
for (i, v) in variations.enumerated() {
    let col = i % cols, row = i / cols
    let x = pad + CGFloat(col) * cellW, yTop = H - pad - CGFloat(row) * cellH
    let iconRect = NSRect(x: x, y: yTop - iconSize, width: iconSize, height: iconSize)
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: iconRect, xRadius: iconSize * 0.22, yRadius: iconSize * 0.22).addClip()
    v.draw(iconRect)
    NSGraphicsContext.restoreGraphicsState()
    let p = NSMutableParagraphStyle(); p.alignment = .center
    (v.label as NSString).draw(in: NSRect(x: x - 4, y: yTop - iconSize - labelH + 6, width: iconSize + 8, height: labelH),
        withAttributes: [.font: NSFont.systemFont(ofSize: 13, weight: .semibold), .foregroundColor: ink, .paragraphStyle: p])
}
image.unlockFocus()
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "explore.png"
let tiff = image.tiffRepresentation!
let png = NSBitmapImageRep(data: tiff)!.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out) with \(variations.count) variations")
