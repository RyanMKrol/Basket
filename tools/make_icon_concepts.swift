// Renders a comparison sheet of *completely different* app-icon concepts in a
// clean indie pixel-art style (Terraria / Dave the Diver feel): each sprite gets
// an automatic dark outline and a soft drop shadow for depth. Sprites are tiny
// ASCII maps; the renderer adds the polish. Run: swift tools/make_icon_concepts.swift <out.png>
import AppKit

let palette: [Character: NSColor] = [
    "r": NSColor(srgbRed: 0.87, green: 0.33, blue: 0.31, alpha: 1),  // red
    "d": NSColor(srgbRed: 0.67, green: 0.22, blue: 0.22, alpha: 1),  // deep red
    "o": NSColor(srgbRed: 0.95, green: 0.62, blue: 0.28, alpha: 1),  // orange
    "q": NSColor(srgbRed: 0.80, green: 0.45, blue: 0.18, alpha: 1),  // deep orange
    "y": NSColor(srgbRed: 0.97, green: 0.82, blue: 0.34, alpha: 1),  // yellow
    "g": NSColor(srgbRed: 0.47, green: 0.71, blue: 0.39, alpha: 1),  // leaf
    "G": NSColor(srgbRed: 0.30, green: 0.52, blue: 0.26, alpha: 1),  // dark leaf
    "m": NSColor(srgbRed: 0.63, green: 0.79, blue: 0.46, alpha: 1),  // mid green
    "l": NSColor(srgbRed: 0.83, green: 0.87, blue: 0.55, alpha: 1),  // pale flesh
    "b": NSColor(srgbRed: 0.81, green: 0.63, blue: 0.41, alpha: 1),  // kraft
    "B": NSColor(srgbRed: 0.62, green: 0.45, blue: 0.27, alpha: 1),  // dark kraft
    "t": NSColor(srgbRed: 0.71, green: 0.53, blue: 0.34, alpha: 1),  // tan
    "w": NSColor(srgbRed: 0.98, green: 0.98, blue: 0.96, alpha: 1),  // white
    "c": NSColor(srgbRed: 0.96, green: 0.94, blue: 0.88, alpha: 1),  // cream
    "e": NSColor(srgbRed: 0.97, green: 0.93, blue: 0.86, alpha: 1),  // eggshell
    "h": NSColor(srgbRed: 1.00, green: 1.00, blue: 1.00, alpha: 1),  // highlight
    "s": NSColor(srgbRed: 0.74, green: 0.76, blue: 0.78, alpha: 1),  // silver
    "S": NSColor(srgbRed: 0.55, green: 0.57, blue: 0.60, alpha: 1),  // dark silver
    "n": NSColor(srgbRed: 0.40, green: 0.62, blue: 0.82, alpha: 1),  // blue
    "p": NSColor(srgbRed: 0.95, green: 0.62, blue: 0.66, alpha: 1),  // pink
    "k": NSColor(srgbRed: 0.40, green: 0.34, blue: 0.30, alpha: 1),  // clip/dark
]
let outline = NSColor(srgbRed: 0.20, green: 0.17, blue: 0.15, alpha: 1)

func gradient() -> NSGradient {
    NSGradient(colors: [
        NSColor(srgbRed: 0.86, green: 0.93, blue: 0.83, alpha: 1),
        NSColor(srgbRed: 0.99, green: 0.97, blue: 0.94, alpha: 1),
        NSColor(srgbRed: 0.98, green: 0.88, blue: 0.85, alpha: 1),
    ])!
}
func rounded(_ r: NSRect, _ rad: CGFloat) -> NSBezierPath { NSBezierPath(roundedRect: r, xRadius: rad, yRadius: rad) }

func render(_ map: [String], in rect: NSRect) {
    let rows = map.count
    let cols = map.map { $0.count }.max() ?? 0
    guard rows > 0, cols > 0 else { return }
    let grid: [[Character]] = map.map { line in
        var a = Array(line); while a.count < cols { a.append(".") }; return a
    }
    func ch(_ c: Int, _ r: Int) -> Character {
        (r < 0 || r >= rows || c < 0 || c >= cols) ? "." : grid[r][c]
    }
    func filled(_ c: Int, _ r: Int) -> Bool { ch(c, r) != "." }

    // Fit the grid (plus a 1-cell outline margin) into ~80% of the icon.
    let pad = rect.width * 0.13
    let avail = rect.width - 2 * pad
    let cell = min(avail / CGFloat(cols + 2), avail / CGFloat(rows + 2))
    let gw = cell * CGFloat(cols), gh = cell * CGFloat(rows)
    let x0 = rect.midX - gw / 2, yTop = rect.midY + gh / 2
    func cellRect(_ c: Int, _ r: Int) -> NSRect {
        NSRect(x: x0 + CGFloat(c) * cell, y: yTop - CGFloat(r + 1) * cell, width: cell + 0.6, height: cell + 0.6)
    }

    // Soft drop shadow: the silhouette nudged down a touch.
    NSColor(white: 0, alpha: 0.10).setFill()
    for r in 0..<rows { for c in 0..<cols where filled(c, r) {
        cellRect(c, r).offsetBy(dx: cell * 0.12, dy: -cell * 0.5).fill()
    } }

    // Auto outline: any empty cell orthogonally adjacent to a filled one.
    outline.setFill()
    for r in -1...rows { for c in -1...cols where !filled(c, r) {
        if filled(c - 1, r) || filled(c + 1, r) || filled(c, r - 1) || filled(c, r + 1) {
            cellRect(c, r).fill()
        }
    } }

    // Fill.
    for r in 0..<rows { for c in 0..<cols {
        guard let col = palette[grid[r][c]] else { continue }
        col.setFill(); cellRect(c, r).fill()
    } }
}

struct Concept { let label: String; let map: [String] }
let concepts: [Concept] = [
    Concept(label: "1  tick", map: [
        "..........g",
        ".........gg",
        "g.......gg.",
        "gg.....gg..",
        ".gg...gg...",
        "..gg.gg....",
        "...ggg.....",
        "....g......",
    ]),
    Concept(label: "2  checkbox", map: [
        "wwwwwwww",
        "w......w",
        "w....g.w",
        "w...gg.w",
        "wg.gg..w",
        "wggg...w",
        "w.g....w",
        "wwwwwwww",
    ]),
    Concept(label: "3  heart", map: [
        ".rr..rr.",
        "rrrrrrrr",
        "rrrrrrrr",
        "rrrrrrrr",
        ".rrrrrr.",
        "..rrrr..",
        "...rr...",
    ]),
    Concept(label: "4  apple", map: [
        "....G...",
        "...Gg...",
        "..r..r..",
        ".rrrrrr.",
        "rrrrrrrr",
        "rrrrrrrr",
        "rrrrrrrr",
        ".rrrrrr.",
        "..r..r..",
    ]),
    Concept(label: "5  carrot", map: [
        ".g.g.g.",
        "GgGgGgG",
        "..ooo..",
        "..ooo..",
        "..ooo..",
        "...o...",
        "...o...",
    ]),
    Concept(label: "6  tomato", map: [
        ".G.GG.G.",
        ".rrrrrr.",
        "rrrrrrrr",
        "rrrrrrrr",
        "rrrrrrrr",
        ".rrrrrr.",
        "..rrrr..",
    ]),
    Concept(label: "7  milk", map: [
        "..cc..",
        ".cccc.",
        "cccccc",
        "cccccc",
        "cnnnnc",
        "cnnnnc",
        "cccccc",
        "cccccc",
        "cccccc",
    ]),
    Concept(label: "8  egg", map: [
        "..ee..",
        ".eeee.",
        "eeeeee",
        "eeeeee",
        "eeeeee",
        ".eeee.",
    ]),
    Concept(label: "9  bread", map: [
        "..bbbb..",
        ".bbbbbb.",
        "bbbbbbbb",
        "bBbBbBbB",
        "bbbbbbbb",
        "tttttttt",
    ]),
    Concept(label: "10  strawberry", map: [
        ".g.gg.g.",
        ".rrrrrr.",
        "ryrrryr.",
        "rrryrrrr",
        "ryrrryr.",
        ".rryrr..",
        "..rrr...",
        "...r....",
    ]),
    Concept(label: "11  bag", map: [
        "..g..g..",
        ".gGg.gG.",
        "bbbbbbbb",
        "bBBBBBBb",
        "bbbbbbbb",
        "bbbbbbbb",
        "bbbbbbbb",
        "bbbbbbbb",
        ".bbbbbb.",
    ]),
    Concept(label: "12  basket", map: [
        ".t....t.",
        ".t....t.",
        "tttttttt",
        ".bBbBbB.",
        ".BbBbBb.",
        ".bBbBbB.",
        "..bBBb..",
    ]),
    Concept(label: "13  jar", map: [
        ".tttt.",
        "tttttt",
        "wwwwww",
        "wrrrrw",
        "wrrrrw",
        "wrrrrw",
        "wwwwww",
        "wwwwww",
        ".wwww.",
    ]),
    Concept(label: "14  receipt", map: [
        "wwwwwww",
        "wSSSSSw",
        "w.....w",
        "wSSSSSw",
        "w.....w",
        "wSSSSSw",
        "w.....w",
        "wggSS.w",
        "w.w.w.w",
    ]),
    Concept(label: "15  clipboard", map: [
        "..kkk..",
        ".wwwww.",
        "wwwwwww",
        "wSSSSSw",
        "w.....w",
        "wSSSSSw",
        "wgSSS.w",
        "wwwwwww",
    ]),
    Concept(label: "16  chilli", map: [
        ".....gg",
        ".....g.",
        "....r..",
        "...rr..",
        "..rr...",
        ".rr....",
        ".r.....",
        "r......",
    ]),
    Concept(label: "17  broccoli", map: [
        ".GG.GG.",
        "GGGGGGG",
        "GmGmGmG",
        ".GmmmG.",
        "..mmm..",
        "..mmm..",
    ]),
    Concept(label: "18  avocado", map: [
        "..GGGG..",
        ".GllllG.",
        "GllllllG",
        "GllBBllG",
        "GllBBllG",
        "GllllllG",
        ".GllllG.",
        "..GGGG..",
    ]),
    Concept(label: "19  lemon", map: [
        "..yyy..",
        ".yyyyy.",
        "yyyyyyy",
        "yyyyyyy",
        ".yyyyy.",
        "..yyy..",
    ]),
    Concept(label: "20  B mark", map: [
        "ggggg..",
        "gg..gg.",
        "gg..gg.",
        "ggggg..",
        "gg..gg.",
        "gg..gg.",
        "ggggg..",
    ]),
]

let cols = 5, iconSize: CGFloat = 220, pad: CGFloat = 26, labelH: CGFloat = 34
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
    render(c.map, in: iconRect)
    NSGraphicsContext.restoreGraphicsState()

    let p = NSMutableParagraphStyle(); p.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 16, weight: .semibold),
        .foregroundColor: NSColor(srgbRed: 0.18, green: 0.17, blue: 0.16, alpha: 1),
        .paragraphStyle: p]
    (c.label as NSString).draw(in: NSRect(x: x - 10, y: yTop - iconSize - labelH + 4, width: iconSize + 20, height: labelH),
                               withAttributes: attrs)
}

image.unlockFocus()
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "concepts.png"
let tiff = image.tiffRepresentation!
let png = NSBitmapImageRep(data: tiff)!.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
