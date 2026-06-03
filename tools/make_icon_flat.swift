// Renders a wide comparison sheet of FLAT-iconography app-icon concepts: clean
// vector shapes, a limited flat palette, on the app gradient. Themes: baskets /
// bags / carts, lists & checks, fruit & veg, groceries. Run:
//   swift tools/make_icon_flat.swift <out.png>
import AppKit

let leaf   = NSColor(srgbRed: 0.42, green: 0.66, blue: 0.40, alpha: 1)
let leafD  = NSColor(srgbRed: 0.30, green: 0.50, blue: 0.28, alpha: 1)
let tomato = NSColor(srgbRed: 0.90, green: 0.42, blue: 0.40, alpha: 1)
let tomatoD = NSColor(srgbRed: 0.74, green: 0.30, blue: 0.30, alpha: 1)
let orange = NSColor(srgbRed: 0.96, green: 0.66, blue: 0.32, alpha: 1)
let yellow = NSColor(srgbRed: 0.97, green: 0.80, blue: 0.34, alpha: 1)
let berry  = NSColor(srgbRed: 0.89, green: 0.45, blue: 0.56, alpha: 1)
let purple = NSColor(srgbRed: 0.60, green: 0.45, blue: 0.72, alpha: 1)
let kraft  = NSColor(srgbRed: 0.82, green: 0.61, blue: 0.39, alpha: 1)
let kraftD = NSColor(srgbRed: 0.66, green: 0.47, blue: 0.28, alpha: 1)
let cream  = NSColor(srgbRed: 0.99, green: 0.98, blue: 0.95, alpha: 1)
let ink    = NSColor(srgbRed: 0.28, green: 0.26, blue: 0.24, alpha: 1)
let inkSoft = NSColor(srgbRed: 0.62, green: 0.60, blue: 0.57, alpha: 1)
let blue   = NSColor(srgbRed: 0.46, green: 0.63, blue: 0.83, alpha: 1)

func gradient() -> NSGradient {
    NSGradient(colors: [
        NSColor(srgbRed: 0.86, green: 0.93, blue: 0.83, alpha: 1),
        NSColor(srgbRed: 0.99, green: 0.97, blue: 0.94, alpha: 1),
        NSColor(srgbRed: 0.98, green: 0.88, blue: 0.85, alpha: 1),
    ])!
}
// Normalized coords: x,y in 0..1, y measured DOWN from the top of the tile.
func P(_ R: NSRect, _ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: R.minX + x * R.width, y: R.maxY - y * R.height) }
func S(_ R: NSRect, _ v: CGFloat) -> CGFloat { v * R.width }
func disc(_ R: NSRect, _ cx: CGFloat, _ cy: CGFloat, _ rad: CGFloat, _ c: NSColor) {
    c.setFill(); let p = P(R, cx, cy)
    NSBezierPath(ovalIn: NSRect(x: p.x - S(R, rad), y: p.y - S(R, rad), width: S(R, rad) * 2, height: S(R, rad) * 2)).fill()
}
func ovalIn(_ R: NSRect, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: NSColor) {
    c.setFill(); let tl = P(R, x, y); NSBezierPath(ovalIn: NSRect(x: tl.x, y: tl.y - S(R, h), width: S(R, w), height: S(R, h))).fill()
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
func tick(_ R: NSRect, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat, _ w: CGFloat, _ c: NSColor) {
    line(R, [(cx - s, cy + s * 0.05), (cx - s * 0.25, cy + s * 0.7), (cx + s, cy - s * 0.7)], w, c)
}
// A simple pointed leaf, tip up-right.
func leafShape(_ R: NSRect, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat, _ c: NSColor) {
    c.setFill(); let path = NSBezierPath()
    let base = P(R, cx - s * 0.55, cy + s * 0.55), tip = P(R, cx + s * 0.55, cy - s * 0.55)
    path.move(to: base)
    path.curve(to: tip, controlPoint1: P(R, cx - s * 0.5, cy - s * 0.3), controlPoint2: P(R, cx + s * 0.05, cy - s * 0.65))
    path.curve(to: base, controlPoint1: P(R, cx + s * 0.3, cy + s * 0.05), controlPoint2: P(R, cx - s * 0.05, cy + s * 0.65))
    path.fill()
}
// A rounded "blob" (fruit body) via an oval.
func blob(_ R: NSRect, _ cx: CGFloat, _ cy: CGFloat, _ rw: CGFloat, _ rh: CGFloat, _ c: NSColor) {
    ovalIn(R, cx - rw, cy - rh, rw * 2, rh * 2, c)
}

typealias Draw = (NSRect) -> Void
struct Concept { let label: String; let draw: Draw }

func basketBody(_ R: NSRect, _ c: NSColor, _ rim: NSColor) {
    poly(R, [(0.28, 0.46), (0.72, 0.46), (0.66, 0.80), (0.34, 0.80)], c)
    box(R, 0.24, 0.42, 0.52, 0.08, 0.04, rim)
}

let concepts: [Concept] = [
    // ---- vessels: baskets, bags, carts ----
    Concept(label: "1 basket") { R in
        basketBody(R, kraft, kraftD)
        curve(R, (0.34, 0.45), (0.40, 0.24), (0.60, 0.24), (0.66, 0.45), 0.04, kraftD)
        line(R, [(0.37, 0.60), (0.63, 0.60)], 0.02, kraftD); line(R, [(0.39, 0.70), (0.61, 0.70)], 0.02, kraftD)
    },
    Concept(label: "2 basket weave") { R in
        basketBody(R, kraft, kraftD)
        for x in stride(from: CGFloat(0.36), through: 0.64, by: 0.07) { line(R, [(x, 0.49), (x, 0.79)], 0.015, kraftD) }
        line(R, [(0.33, 0.62), (0.67, 0.62)], 0.015, kraftD)
    },
    Concept(label: "3 basket green") { R in
        basketBody(R, leaf, leafD)
        curve(R, (0.34, 0.45), (0.40, 0.24), (0.60, 0.24), (0.66, 0.45), 0.045, leafD)
    },
    Concept(label: "4 cart") { R in
        line(R, [(0.24, 0.30), (0.34, 0.30), (0.40, 0.62), (0.72, 0.62)], 0.045, leaf)
        poly(R, [(0.36, 0.40), (0.74, 0.40), (0.70, 0.60), (0.40, 0.60)], leaf)
        disc(R, 0.45, 0.72, 0.05, leafD); disc(R, 0.66, 0.72, 0.05, leafD)
    },
    Concept(label: "5 paper bag") { R in
        box(R, 0.32, 0.34, 0.36, 0.46, 0.04, kraft)
        poly(R, [(0.32, 0.34), (0.40, 0.26), (0.60, 0.26), (0.68, 0.34)], kraftD)
        line(R, [(0.40, 0.28), (0.45, 0.40)], 0.02, kraftD); line(R, [(0.60, 0.28), (0.55, 0.40)], 0.02, kraftD)
    },
    Concept(label: "6 tote bag") { R in
        box(R, 0.32, 0.40, 0.36, 0.40, 0.05, leaf)
        curve(R, (0.40, 0.40), (0.42, 0.24), (0.50, 0.24), (0.50, 0.24), 0.028, leafD)
        curve(R, (0.50, 0.24), (0.50, 0.24), (0.58, 0.24), (0.60, 0.40), 0.028, leafD)
    },
    Concept(label: "7 bag handles") { R in
        box(R, 0.30, 0.42, 0.40, 0.38, 0.05, tomato)
        curve(R, (0.38, 0.42), (0.40, 0.26), (0.50, 0.26), (0.50, 0.26), 0.03, tomatoD)
        curve(R, (0.50, 0.26), (0.50, 0.26), (0.60, 0.26), (0.62, 0.42), 0.03, tomatoD)
    },
    Concept(label: "8 basket + apple") { R in
        disc(R, 0.5, 0.40, 0.10, tomato); line(R, [(0.5, 0.32), (0.52, 0.27)], 0.02, leafD)
        basketBody(R, kraft, kraftD)
    },
    Concept(label: "9 basket outline") { R in
        line(R, [(0.28, 0.46), (0.72, 0.46), (0.66, 0.80), (0.34, 0.80)], 0.03, leafD, closed: true)
        curve(R, (0.34, 0.46), (0.40, 0.26), (0.60, 0.26), (0.66, 0.46), 0.03, leafD)
    },
    Concept(label: "10 shop bag heart") { R in
        box(R, 0.30, 0.40, 0.40, 0.40, 0.05, leaf)
        curve(R, (0.38, 0.40), (0.40, 0.25), (0.50, 0.27), (0.50, 0.27), 0.028, leafD)
        curve(R, (0.50, 0.27), (0.50, 0.27), (0.60, 0.25), (0.62, 0.40), 0.028, leafD)
        disc(R, 0.455, 0.57, 0.035, cream); disc(R, 0.545, 0.57, 0.035, cream)
        poly(R, [(0.42, 0.59), (0.58, 0.59), (0.5, 0.70)], cream)
    },
    // ---- lists & checks ----
    Concept(label: "11 checklist") { R in
        box(R, 0.30, 0.28, 0.40, 0.48, 0.05, cream)
        for (i, y) in [0.40, 0.52, 0.64].enumerated() {
            let on = i == 0
            box(R, 0.35, CGFloat(y) - 0.03, 0.06, 0.06, 0.015, on ? leaf : inkSoft.withAlphaComponent(0.4))
            box(R, 0.45, CGFloat(y) - 0.018, 0.18, 0.035, 0.017, inkSoft.withAlphaComponent(0.6))
        }
    },
    Concept(label: "12 clipboard") { R in
        box(R, 0.30, 0.26, 0.40, 0.50, 0.05, cream)
        box(R, 0.42, 0.22, 0.16, 0.07, 0.03, leafD)
        tick(R, 0.40, 0.45, 0.05, 0.028, leaf)
        line(R, [(0.48, 0.45), (0.62, 0.45)], 0.03, inkSoft.withAlphaComponent(0.6))
        line(R, [(0.38, 0.58), (0.62, 0.58)], 0.03, inkSoft.withAlphaComponent(0.5))
    },
    Concept(label: "13 receipt") { R in
        poly(R, [(0.34, 0.24), (0.66, 0.24), (0.66, 0.74), (0.62, 0.70), (0.58, 0.74), (0.54, 0.70), (0.50, 0.74), (0.46, 0.70), (0.42, 0.74), (0.38, 0.70), (0.34, 0.74)], cream)
        for y in [0.36, 0.46, 0.56] { line(R, [(0.40, CGFloat(y)), (0.60, CGFloat(y))], 0.022, inkSoft.withAlphaComponent(0.5)) }
    },
    Concept(label: "14 note + check") { R in
        box(R, 0.30, 0.28, 0.40, 0.46, 0.05, cream)
        tick(R, 0.5, 0.50, 0.12, 0.05, leaf)
    },
    Concept(label: "15 check circle") { R in
        disc(R, 0.5, 0.5, 0.24, leaf); tick(R, 0.5, 0.52, 0.11, 0.05, cream)
    },
    Concept(label: "16 tick") { R in tick(R, 0.5, 0.52, 0.20, 0.07, leaf) },
    Concept(label: "17 checkbox") { R in
        box(R, 0.30, 0.30, 0.40, 0.40, 0.09, leaf); tick(R, 0.5, 0.52, 0.11, 0.05, cream)
    },
    Concept(label: "18 list + pencil") { R in
        for y in [0.38, 0.50, 0.62] {
            disc(R, 0.34, CGFloat(y), 0.022, leaf); line(R, [(0.40, CGFloat(y)), (0.62, CGFloat(y))], 0.028, inkSoft.withAlphaComponent(0.6))
        }
    },
    Concept(label: "19 tag + check") { R in
        poly(R, [(0.30, 0.34), (0.56, 0.30), (0.70, 0.50), (0.46, 0.70), (0.26, 0.56)], tomato)
        disc(R, 0.37, 0.42, 0.022, cream); tick(R, 0.52, 0.52, 0.07, 0.03, cream)
    },
    Concept(label: "20 bullets") { R in
        for y in [0.36, 0.50, 0.64] {
            box(R, 0.32, CGFloat(y) - 0.025, 0.05, 0.05, 0.012, leaf)
            line(R, [(0.42, CGFloat(y)), (0.66, CGFloat(y))], 0.03, inkSoft.withAlphaComponent(0.6))
        }
    },
    // ---- fruit & veg ----
    Concept(label: "21 apple") { R in
        blob(R, 0.5, 0.55, 0.18, 0.19, tomato); line(R, [(0.5, 0.40), (0.52, 0.30)], 0.022, kraftD); leafShape(R, 0.57, 0.34, 0.07, leaf)
    },
    Concept(label: "22 pear") { R in
        disc(R, 0.5, 0.62, 0.16, leaf); disc(R, 0.5, 0.42, 0.10, leaf); line(R, [(0.5, 0.34), (0.52, 0.26)], 0.02, kraftD); leafShape(R, 0.58, 0.30, 0.06, leafD)
    },
    Concept(label: "23 carrot") { R in
        poly(R, [(0.40, 0.42), (0.60, 0.42), (0.5, 0.78)], orange)
        leafShape(R, 0.43, 0.36, 0.07, leaf); leafShape(R, 0.5, 0.33, 0.07, leaf); leafShape(R, 0.57, 0.36, 0.07, leaf)
    },
    Concept(label: "24 tomato") { R in
        blob(R, 0.5, 0.56, 0.19, 0.17, tomato)
        for a in stride(from: CGFloat(0), to: .pi * 2, by: .pi / 2.5) { leafShape(R, 0.5 + cos(a) * 0.06, 0.40 + sin(a) * 0.05, 0.05, leaf) }
    },
    Concept(label: "25 strawberry") { R in
        poly(R, [(0.34, 0.46), (0.66, 0.46), (0.5, 0.80)], tomato)
        for x in [0.42, 0.5, 0.58] { leafShape(R, CGFloat(x), 0.42, 0.05, leaf) }
        for p in [(0.45, 0.56), (0.55, 0.56), (0.5, 0.66)] { disc(R, CGFloat(p.0), CGFloat(p.1), 0.012, yellow) }
    },
    Concept(label: "26 avocado") { R in
        blob(R, 0.5, 0.55, 0.17, 0.21, leafD); blob(R, 0.5, 0.55, 0.12, 0.16, leaf); disc(R, 0.5, 0.60, 0.06, kraftD)
    },
    Concept(label: "27 broccoli") { R in
        for p in [(0.42, 0.42), (0.58, 0.42), (0.5, 0.36), (0.5, 0.48)] { disc(R, CGFloat(p.0), CGFloat(p.1), 0.09, leaf) }
        box(R, 0.45, 0.50, 0.10, 0.24, 0.03, leafD)
    },
    Concept(label: "28 leaf") { R in
        leafShape(R, 0.5, 0.5, 0.24, leaf); line(R, [(0.36, 0.64), (0.62, 0.38)], 0.014, cream)
    },
    Concept(label: "29 cherries") { R in
        disc(R, 0.40, 0.64, 0.10, tomato); disc(R, 0.60, 0.64, 0.10, tomato)
        curve(R, (0.40, 0.55), (0.46, 0.34), (0.55, 0.34), (0.60, 0.55), 0.02, leafD); leafShape(R, 0.56, 0.36, 0.06, leaf)
    },
    Concept(label: "30 banana") { R in
        curve(R, (0.34, 0.40), (0.40, 0.78), (0.74, 0.72), (0.70, 0.44), 0.10, yellow)
    },
    Concept(label: "31 lemon") { R in
        blob(R, 0.5, 0.52, 0.20, 0.15, yellow); disc(R, 0.30, 0.52, 0.02, yellow); disc(R, 0.70, 0.52, 0.02, yellow)
    },
    Concept(label: "32 grapes") { R in
        let pts = [(0.5, 0.44), (0.43, 0.52), (0.57, 0.52), (0.5, 0.58), (0.37, 0.60), (0.63, 0.60), (0.46, 0.66), (0.54, 0.66), (0.5, 0.73)]
        for p in pts { disc(R, CGFloat(p.0), CGFloat(p.1), 0.055, purple) }
        leafShape(R, 0.57, 0.38, 0.07, leaf)
    },
    Concept(label: "33 chilli") { R in
        curve(R, (0.40, 0.36), (0.30, 0.70), (0.66, 0.78), (0.64, 0.50), 0.07, tomato)
        line(R, [(0.40, 0.36), (0.50, 0.30)], 0.025, leaf)
    },
    Concept(label: "34 aubergine") { R in
        blob(R, 0.52, 0.58, 0.15, 0.20, purple); leafShape(R, 0.44, 0.38, 0.07, leaf); line(R, [(0.46, 0.40), (0.5, 0.46)], 0.02, leafD)
    },
    Concept(label: "35 pepper") { R in
        poly(R, [(0.36, 0.46), (0.64, 0.46), (0.60, 0.72), (0.5, 0.66), (0.40, 0.72)], tomato)
        box(R, 0.47, 0.36, 0.06, 0.10, 0.02, leaf)
    },
    Concept(label: "36 mushroom") { R in
        poly(R, [(0.32, 0.52), (0.68, 0.52), (0.60, 0.40), (0.40, 0.40)], tomato)
        ovalIn(R, 0.32, 0.42, 0.36, 0.16, tomato); box(R, 0.44, 0.52, 0.12, 0.22, 0.04, cream)
    },
    Concept(label: "37 watermelon") { R in
        let p = P(R, 0.5, 0.42); let rr = S(R, 0.24)
        let path = NSBezierPath(); path.appendArc(withCenter: p, radius: rr, startAngle: 0, endAngle: 180)
        path.close(); leaf.setFill(); path.fill()
        let path2 = NSBezierPath(); path2.appendArc(withCenter: p, radius: rr * 0.78, startAngle: 0, endAngle: 180); path2.close(); tomato.setFill(); path2.fill()
        for x in [0.42, 0.5, 0.58] { disc(R, CGFloat(x), 0.52, 0.014, ink) }
    },
    Concept(label: "38 orange slice") { R in
        disc(R, 0.5, 0.5, 0.22, orange); disc(R, 0.5, 0.5, 0.17, cream)
        for a in stride(from: CGFloat(0), to: .pi * 2, by: .pi / 4) {
            poly(R, [(0.5, 0.5), (0.5 + cos(a) * 0.16, 0.5 + sin(a) * 0.16), (0.5 + cos(a + 0.32) * 0.16, 0.5 + sin(a + 0.32) * 0.16)], orange)
        }
    },
    Concept(label: "39 corn") { R in
        ovalIn(R, 0.42, 0.40, 0.16, 0.36, yellow); leafShape(R, 0.40, 0.50, 0.10, leaf); leafShape(R, 0.60, 0.50, 0.10, leafD)
    },
    Concept(label: "40 sprout") { R in
        line(R, [(0.5, 0.74), (0.5, 0.46)], 0.03, leafD); leafShape(R, 0.40, 0.42, 0.10, leaf); leafShape(R, 0.60, 0.42, 0.10, leaf)
    },
    // ---- groceries & abstract ----
    Concept(label: "41 milk carton") { R in
        box(R, 0.38, 0.40, 0.24, 0.36, 0.02, cream)
        poly(R, [(0.38, 0.40), (0.5, 0.30), (0.62, 0.40)], cream)
        box(R, 0.42, 0.52, 0.16, 0.10, 0.01, blue)
    },
    Concept(label: "42 bottle") { R in
        box(R, 0.46, 0.28, 0.08, 0.10, 0.01, leafD)
        poly(R, [(0.46, 0.38), (0.54, 0.38), (0.60, 0.48), (0.60, 0.76), (0.40, 0.76), (0.40, 0.48)], leaf)
    },
    Concept(label: "43 egg") { R in blob(R, 0.5, 0.54, 0.15, 0.20, cream) },
    Concept(label: "44 bread") { R in
        let p = P(R, 0.5, 0.58); let rr = S(R, 0.22)
        let path = NSBezierPath(); path.appendArc(withCenter: p, radius: rr, startAngle: 0, endAngle: 180); path.close(); kraft.setFill(); path.fill()
        box(R, 0.30, 0.56, 0.40, 0.10, 0.03, kraftD)
        for x in [0.42, 0.5, 0.58] { line(R, [(CGFloat(x), 0.44), (CGFloat(x) + 0.02, 0.52)], 0.016, kraftD) }
    },
    Concept(label: "45 jar") { R in
        box(R, 0.40, 0.30, 0.20, 0.06, 0.02, kraftD); box(R, 0.38, 0.36, 0.24, 0.40, 0.04, leaf.withAlphaComponent(0.85))
        box(R, 0.42, 0.46, 0.16, 0.06, 0.02, cream)
    },
    Concept(label: "46 basket + check") { R in
        basketBody(R, leaf, leafD); disc(R, 0.66, 0.40, 0.10, cream); tick(R, 0.66, 0.41, 0.05, 0.025, leaf)
    },
    Concept(label: "47 leaf + check") { R in
        leafShape(R, 0.5, 0.5, 0.22, leaf); tick(R, 0.5, 0.54, 0.09, 0.035, cream)
    },
    Concept(label: "48 B mark") { R in
        line(R, [(0.40, 0.30), (0.40, 0.72)], 0.05, leaf)
        curve(R, (0.40, 0.31), (0.66, 0.30), (0.66, 0.48), (0.40, 0.50), 0.05, leaf)
        curve(R, (0.40, 0.50), (0.68, 0.50), (0.68, 0.72), (0.40, 0.72), 0.05, leaf)
    },
    Concept(label: "49 fruit trio") { R in
        disc(R, 0.42, 0.46, 0.10, tomato); disc(R, 0.60, 0.46, 0.09, orange); disc(R, 0.50, 0.62, 0.10, leaf)
    },
    Concept(label: "50 heart leaf") { R in
        disc(R, 0.43, 0.46, 0.09, leaf); disc(R, 0.57, 0.46, 0.09, leaf)
        poly(R, [(0.345, 0.49), (0.655, 0.49), (0.5, 0.70)], leaf); leafShape(R, 0.5, 0.40, 0.06, leafD)
    },
]

let cols = 7, iconSize: CGFloat = 200, pad: CGFloat = 22, labelH: CGFloat = 30
let rows = (concepts.count + cols - 1) / cols
let cellW = iconSize + pad, cellH = iconSize + labelH + pad
let W = CGFloat(cols) * cellW + pad, H = CGFloat(rows) * cellH + pad

let image = NSImage(size: NSSize(width: W, height: H))
image.lockFocus()
NSColor(white: 0.97, alpha: 1).setFill(); NSRect(x: 0, y: 0, width: W, height: H).fill()

for (i, c) in concepts.enumerated() {
    let col = i % cols, row = i / cols
    let x = pad + CGFloat(col) * cellW
    let yTop = H - pad - CGFloat(row) * cellH
    let iconRect = NSRect(x: x, y: yTop - iconSize, width: iconSize, height: iconSize)
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: iconRect, xRadius: iconSize * 0.22, yRadius: iconSize * 0.22).addClip()
    gradient().draw(in: iconRect, angle: -90)
    c.draw(iconRect)
    NSGraphicsContext.restoreGraphicsState()
    let p = NSMutableParagraphStyle(); p.alignment = .center
    (c.label as NSString).draw(in: NSRect(x: x - 6, y: yTop - iconSize - labelH + 6, width: iconSize + 12, height: labelH),
        withAttributes: [.font: NSFont.systemFont(ofSize: 14, weight: .semibold), .foregroundColor: ink, .paragraphStyle: p])
}

image.unlockFocus()
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "flat.png"
let tiff = image.tiffRepresentation!
let png = NSBitmapImageRep(data: tiff)!.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out) with \(concepts.count) concepts")
