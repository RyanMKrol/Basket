// Renders Basket's 1024×1024 app icon natively on macOS (AppKit): a soft
// grocery-coloured gradient behind a pixel-art basket of fruit. The art is
// composed procedurally on an N×N pixel grid (raise N for finer pixels), then
// each cell is drawn as a crisp square.
// Run: swift tools/make_icon.swift <output.png>
import AppKit

let side: CGFloat = 1024
let image = NSImage(size: NSSize(width: side, height: side))
image.lockFocus()

// Warm gradient (green → cream → tomato), the app's palette.
NSGradient(colors: [
    NSColor(srgbRed: 0.86, green: 0.93, blue: 0.83, alpha: 1),
    NSColor(srgbRed: 0.99, green: 0.97, blue: 0.94, alpha: 1),
    NSColor(srgbRed: 0.98, green: 0.88, blue: 0.85, alpha: 1),
])!.draw(in: NSRect(x: 0, y: 0, width: side, height: side), angle: -90)

// Palette.
let tomato    = NSColor(srgbRed: 0.91, green: 0.42, blue: 0.40, alpha: 1)
let apple     = NSColor(srgbRed: 0.55, green: 0.73, blue: 0.38, alpha: 1)
let orange    = NSColor(srgbRed: 0.96, green: 0.66, blue: 0.30, alpha: 1)
let stem      = NSColor(srgbRed: 0.44, green: 0.57, blue: 0.32, alpha: 1)
let weaveLite = NSColor(srgbRed: 0.85, green: 0.67, blue: 0.45, alpha: 1)
let weaveDark = NSColor(srgbRed: 0.73, green: 0.55, blue: 0.35, alpha: 1)
let rim       = NSColor(srgbRed: 0.65, green: 0.47, blue: 0.29, alpha: 1)

// N×N pixel grid (row 0 at the top). 22 reads finer than a chunky 13.
let N = 22
let center = Double(N - 1) / 2.0            // 10.5

// Three plump fruits sitting in the basket.
let fruitR = 3.6
let fruits: [(cx: Double, cy: Double, color: NSColor)] = [
    (center - 5.0, 8.5, tomato),
    (center,       7.3, apple),
    (center + 5.0, 8.5, orange),
]

// Basket bowl: rim at rows 11–12, tapered body to row 19 (smaller than the
// fruits are big, per the brief).
let rimRows = 11...12
let bodyTop = 13, bodyBot = 19
func halfWidth(_ row: Int) -> Double {
    let t = Double(row - rimRows.lowerBound) / Double(bodyBot - rimRows.lowerBound)
    return 7.3 * (1 - t) + 4.3 * t          // 7.3 at the rim → 4.3 at the base
}

func cellColor(_ col: Int, _ row: Int) -> NSColor? {
    let x = Double(col), y = Double(row)
    // Fruit (drawn in front of the basket) + a little stem on top of each.
    for f in fruits {
        let dx = x - f.cx, dy = y - f.cy
        if dx * dx + dy * dy <= fruitR * fruitR { return f.color }
        if col == Int(f.cx.rounded()) && row == Int((f.cy - fruitR - 1).rounded()) { return stem }
    }
    // Basket.
    if rimRows.contains(row), abs(x - center) <= halfWidth(rimRows.lowerBound) { return rim }
    if (bodyTop...bodyBot).contains(row), abs(x - center) <= halfWidth(row) {
        return (col + row).isMultiple(of: 2) ? weaveLite : weaveDark
    }
    return nil
}

let cell = side / CGFloat(N)
for row in 0..<N {
    for col in 0..<N {
        guard let c = cellColor(col, row) else { continue }
        c.setFill()
        let x = CGFloat(col) * cell
        let yTop = side - CGFloat(row + 1) * cell   // flip: row 0 at the top
        NSRect(x: x, y: yTop, width: cell + 0.5, height: cell + 0.5).fill()
    }
}

image.unlockFocus()

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"
guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fputs("failed to render icon\n", stderr); exit(1)
}
try! png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
