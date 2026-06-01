// Renders a comparison sheet of pixel-art basket icon VARIANTS — same motif as
// the app icon, but sweeping basket size, fruit size/count and pixel coarseness
// so we can pick a favourite. Composition is in normalized [0,1] space (y down),
// quantised to an N×N grid, so N controls only pixel coarseness, independent of
// the layout. Run: swift tools/make_icon_variants.swift <out.png>
import AppKit

let tomato    = NSColor(srgbRed: 0.91, green: 0.42, blue: 0.40, alpha: 1)
let apple     = NSColor(srgbRed: 0.55, green: 0.73, blue: 0.38, alpha: 1)
let orange    = NSColor(srgbRed: 0.96, green: 0.66, blue: 0.30, alpha: 1)
let stem      = NSColor(srgbRed: 0.44, green: 0.57, blue: 0.32, alpha: 1)
let weaveLite = NSColor(srgbRed: 0.85, green: 0.67, blue: 0.45, alpha: 1)
let weaveDark = NSColor(srgbRed: 0.73, green: 0.55, blue: 0.35, alpha: 1)
let rimColor  = NSColor(srgbRed: 0.65, green: 0.47, blue: 0.29, alpha: 1)
let ink       = NSColor(srgbRed: 0.18, green: 0.17, blue: 0.16, alpha: 1)

func gradient() -> NSGradient {
    NSGradient(colors: [
        NSColor(srgbRed: 0.86, green: 0.93, blue: 0.83, alpha: 1),
        NSColor(srgbRed: 0.99, green: 0.97, blue: 0.94, alpha: 1),
        NSColor(srgbRed: 0.98, green: 0.88, blue: 0.85, alpha: 1),
    ])!
}
func rounded(_ r: NSRect, _ rad: CGFloat) -> NSBezierPath { NSBezierPath(roundedRect: r, xRadius: rad, yRadius: rad) }

struct Variant {
    let label: String
    let N: Int             // grid resolution (pixel coarseness)
    let fruitR: Double      // fruit radius (normalized)
    let fruitCount: Int
    let fruitCY: Double     // fruit centre row (0 = top)
    let spread: Double      // gap between fruit centres
    let rimY: Double        // basket rim (top of bowl)
    let baseY: Double       // bottom of bowl
    let rimHalf: Double     // half-width at the rim
    let baseHalf: Double    // half-width at the base
}

func draw(_ v: Variant, in rect: NSRect) {
    let cx = 0.5
    let colors = [tomato, apple, orange]
    let start = -Double(v.fruitCount - 1) / 2.0
    let fruits: [(Double, Double, NSColor)] = (0..<v.fruitCount).map { i in
        (cx + (start + Double(i)) * v.spread, v.fruitCY, colors[i % colors.count])
    }
    let g = 1.0 / Double(v.N)   // one cell, normalized

    func cellColor(_ nx: Double, _ ny: Double) -> NSColor? {
        for f in fruits {
            let dx = nx - f.0, dy = ny - f.1
            if dx * dx + dy * dy <= v.fruitR * v.fruitR { return f.2 }
            if abs(nx - f.0) <= 0.6 * g, abs(ny - (f.1 - v.fruitR - 0.5 * g)) <= 0.6 * g { return stem }
        }
        if ny >= v.rimY, ny <= v.baseY {
            let t = (ny - v.rimY) / (v.baseY - v.rimY)
            let half = v.rimHalf * (1 - t) + v.baseHalf * t
            if abs(nx - cx) <= half {
                if ny < v.rimY + (v.baseY - v.rimY) * 0.14 { return rimColor }
                let col = Int(nx * Double(v.N)), row = Int(ny * Double(v.N))
                return (col + row) % 2 == 0 ? weaveLite : weaveDark
            }
        }
        return nil
    }

    let cell = rect.width / CGFloat(v.N)
    for row in 0..<v.N {
        for col in 0..<v.N {
            let nx = (Double(col) + 0.5) / Double(v.N)
            let ny = (Double(row) + 0.5) / Double(v.N)
            guard let c = cellColor(nx, ny) else { continue }
            c.setFill()
            let x = rect.minX + CGFloat(col) * cell
            let y = rect.minY + rect.height - CGFloat(row + 1) * cell
            NSRect(x: x, y: y, width: cell + 0.5, height: cell + 0.5).fill()
        }
    }
}

// 15 variants, all smaller (basket + fruit) than the first cut, sweeping size,
// fruit count and coarseness.
let variants: [Variant] = [
    Variant(label: "1  small · N24",   N: 24, fruitR: 0.085, fruitCount: 3, fruitCY: 0.46, spread: 0.135, rimY: 0.54, baseY: 0.78, rimHalf: 0.20, baseHalf: 0.13),
    Variant(label: "2  small · N28",   N: 28, fruitR: 0.085, fruitCount: 3, fruitCY: 0.46, spread: 0.135, rimY: 0.54, baseY: 0.78, rimHalf: 0.20, baseHalf: 0.13),
    Variant(label: "3  small · N32",   N: 32, fruitR: 0.085, fruitCount: 3, fruitCY: 0.46, spread: 0.135, rimY: 0.54, baseY: 0.78, rimHalf: 0.20, baseHalf: 0.13),
    Variant(label: "4  tiny fruit",    N: 28, fruitR: 0.068, fruitCount: 3, fruitCY: 0.48, spread: 0.115, rimY: 0.55, baseY: 0.77, rimHalf: 0.18, baseHalf: 0.12),
    Variant(label: "5  airy/small",    N: 28, fruitR: 0.075, fruitCount: 3, fruitCY: 0.44, spread: 0.125, rimY: 0.56, baseY: 0.75, rimHalf: 0.16, baseHalf: 0.11),
    Variant(label: "6  two fruit",     N: 28, fruitR: 0.095, fruitCount: 2, fruitCY: 0.46, spread: 0.150, rimY: 0.55, baseY: 0.78, rimHalf: 0.18, baseHalf: 0.12),
    Variant(label: "7  one fruit",     N: 28, fruitR: 0.110, fruitCount: 1, fruitCY: 0.45, spread: 0.000, rimY: 0.55, baseY: 0.78, rimHalf: 0.16, baseHalf: 0.11),
    Variant(label: "8  deep bowl",     N: 28, fruitR: 0.080, fruitCount: 3, fruitCY: 0.42, spread: 0.130, rimY: 0.50, baseY: 0.80, rimHalf: 0.19, baseHalf: 0.12),
    Variant(label: "9  shallow bowl",  N: 28, fruitR: 0.082, fruitCount: 3, fruitCY: 0.48, spread: 0.135, rimY: 0.58, baseY: 0.75, rimHalf: 0.21, baseHalf: 0.15),
    Variant(label: "10  centered",     N: 28, fruitR: 0.080, fruitCount: 3, fruitCY: 0.38, spread: 0.130, rimY: 0.47, baseY: 0.70, rimHalf: 0.19, baseHalf: 0.12),
    Variant(label: "11  chunky · N20", N: 20, fruitR: 0.090, fruitCount: 3, fruitCY: 0.46, spread: 0.140, rimY: 0.54, baseY: 0.78, rimHalf: 0.20, baseHalf: 0.13),
    Variant(label: "12  fine · N36",   N: 36, fruitR: 0.078, fruitCount: 3, fruitCY: 0.46, spread: 0.125, rimY: 0.55, baseY: 0.78, rimHalf: 0.18, baseHalf: 0.12),
    Variant(label: "13  tight fruit",  N: 28, fruitR: 0.082, fruitCount: 3, fruitCY: 0.46, spread: 0.100, rimY: 0.55, baseY: 0.78, rimHalf: 0.17, baseHalf: 0.11),
    Variant(label: "14  petite",       N: 30, fruitR: 0.070, fruitCount: 3, fruitCY: 0.47, spread: 0.110, rimY: 0.57, baseY: 0.76, rimHalf: 0.15, baseHalf: 0.10),
    Variant(label: "15  balanced",     N: 28, fruitR: 0.083, fruitCount: 3, fruitCY: 0.45, spread: 0.128, rimY: 0.53, baseY: 0.77, rimHalf: 0.185, baseHalf: 0.125),
]

let cols = 5, iconSize: CGFloat = 220, pad: CGFloat = 26, labelH: CGFloat = 34
let rows = (variants.count + cols - 1) / cols
let cellW = iconSize + pad, cellH = iconSize + labelH + pad
let W = CGFloat(cols) * cellW + pad, H = CGFloat(rows) * cellH + pad

let image = NSImage(size: NSSize(width: W, height: H))
image.lockFocus()
NSColor(white: 0.97, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: W, height: H).fill()

for (i, v) in variants.enumerated() {
    let col = i % cols, row = i / cols
    let x = pad + CGFloat(col) * cellW
    let yTop = H - pad - CGFloat(row) * cellH
    let iconRect = NSRect(x: x, y: yTop - iconSize, width: iconSize, height: iconSize)

    NSGraphicsContext.saveGraphicsState()
    rounded(iconRect, iconSize * 0.22).addClip()
    gradient().draw(in: iconRect, angle: -90)
    draw(v, in: iconRect)
    NSGraphicsContext.restoreGraphicsState()

    let p = NSMutableParagraphStyle(); p.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 17, weight: .semibold),
        .foregroundColor: ink, .paragraphStyle: p]
    (v.label as NSString).draw(in: NSRect(x: x - 10, y: yTop - iconSize - labelH + 4, width: iconSize + 20, height: labelH),
                               withAttributes: attrs)
}

image.unlockFocus()
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "variants.png"
let tiff = image.tiffRepresentation!
let png = NSBitmapImageRep(data: tiff)!.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
