// Hand-crafted pixel-art basket: a deliberate sprite (limited palette, crisp
// edges, woven shading) rendered with an automatic dark outline + soft drop
// shadow. Renders one 1024 icon on the app gradient so we can iterate on the
// sprite. Run: swift tools/make_basket_art.swift <out.png>
import AppKit

let palette: [Character: NSColor] = [
    "L": NSColor(srgbRed: 0.86, green: 0.66, blue: 0.42, alpha: 1),  // light weave
    "M": NSColor(srgbRed: 0.74, green: 0.54, blue: 0.33, alpha: 1),  // mid weave
    "D": NSColor(srgbRed: 0.60, green: 0.42, blue: 0.25, alpha: 1),  // dark weave
    "R": NSColor(srgbRed: 0.64, green: 0.45, blue: 0.27, alpha: 1),  // rim
    "H": NSColor(srgbRed: 0.55, green: 0.38, blue: 0.23, alpha: 1),  // handle
    "W": NSColor(srgbRed: 0.98, green: 0.98, blue: 0.96, alpha: 1),  // cloth
    "S": NSColor(srgbRed: 0.82, green: 0.84, blue: 0.86, alpha: 1),  // cloth shadow
]
let outline = NSColor(srgbRed: 0.28, green: 0.18, blue: 0.12, alpha: 1)

func gradient() -> NSGradient {
    NSGradient(colors: [
        NSColor(srgbRed: 0.86, green: 0.93, blue: 0.83, alpha: 1),
        NSColor(srgbRed: 0.99, green: 0.97, blue: 0.94, alpha: 1),
        NSColor(srgbRed: 0.98, green: 0.88, blue: 0.85, alpha: 1),
    ])!
}
func rounded(_ r: NSRect, _ rad: CGFloat) -> NSBezierPath { NSBezierPath(roundedRect: r, xRadius: rad, yRadius: rad) }

// y = 0 is the top row. Vertical stakes (D) stay column-aligned; the weave
// alternates light/mid bands (L/M) between them for a woven look.
let basket: [String] = [
    "..........HHHHHH..........",
    ".........HH....HH.........",
    "........HH......HH........",
    "........H...WW...H........",
    ".......HH..WWWW..HH.......",
    ".......H..WWWWWW..H.......",
    "......RRRWWWWWWWWRRR......",
    ".....RRRRRRRRRRRRRRRR.....",
    ".....DLLDLLDLLDLLDLLD.....",
    ".....DMMDMMDMMDMMDMMD.....",
    ".....DLLDLLDLLDLLDLLD.....",
    ".....DMMDMMDMMDMMDMMD.....",
    "......LLDLLDLLDLLDLL......",
    "......MMDMMDMMDMMDMM......",
    ".......LDLLDLLDLLDL.......",
    ".......MDMMDMMDMMDM.......",
    "........DDDDDDDDDD........",
]

func render(_ map: [String], in rect: NSRect) {
    let rows = map.count, cols = map.map { $0.count }.max() ?? 0
    let grid: [[Character]] = map.map { var a = Array($0); while a.count < cols { a.append(".") }; return a }
    func ch(_ c: Int, _ r: Int) -> Character { (r < 0 || r >= rows || c < 0 || c >= cols) ? "." : grid[r][c] }
    func filled(_ c: Int, _ r: Int) -> Bool { ch(c, r) != "." }

    let pad = rect.width * 0.12
    let avail = rect.width - 2 * pad
    let cell = min(avail / CGFloat(cols + 2), avail / CGFloat(rows + 2))
    let gw = cell * CGFloat(cols), gh = cell * CGFloat(rows)
    let x0 = rect.midX - gw / 2, yTop = rect.midY + gh / 2
    func cellRect(_ c: Int, _ r: Int) -> NSRect {
        NSRect(x: x0 + CGFloat(c) * cell, y: yTop - CGFloat(r + 1) * cell, width: cell + 0.6, height: cell + 0.6)
    }

    NSColor(white: 0, alpha: 0.10).setFill()
    for r in 0..<rows { for c in 0..<cols where filled(c, r) {
        cellRect(c, r).offsetBy(dx: cell * 0.1, dy: -cell * 0.45).fill()
    } }
    outline.setFill()
    for r in -1...rows { for c in -1...cols where !filled(c, r) {
        if filled(c - 1, r) || filled(c + 1, r) || filled(c, r - 1) || filled(c, r + 1) { cellRect(c, r).fill() }
    } }
    for r in 0..<rows { for c in 0..<cols {
        guard let col = palette[grid[r][c]] else { continue }
        col.setFill(); cellRect(c, r).fill()
    } }
}

let side: CGFloat = 1024
let image = NSImage(size: NSSize(width: side, height: side))
image.lockFocus()
let rect = NSRect(x: 0, y: 0, width: side, height: side)
gradient().draw(in: rect, angle: -90)
render(basket, in: rect)
image.unlockFocus()

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "basket_art.png"
let tiff = image.tiffRepresentation!
let png = NSBitmapImageRep(data: tiff)!.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
