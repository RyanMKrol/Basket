// Tiles the 10 fresh-background screenshots into one labelled contact sheet.
// Run: swift tools/montage.swift screenshots/fresh_montage.png
import AppKit

let names = ["1 Cream Blooms", "2 Mint Air", "3 Lemon Soda", "4 Sky Field",
             "5 Berry Cream", "6 Garden Grid", "7 Pastel Dots", "8 Seafoam Bands",
             "9 Fruit Punch", "10 Morning Light"]
let dir = "screenshots/fresh"
let cols = 5, rows = 2
let thumbW: CGFloat = 230, pad: CGFloat = 16, labelH: CGFloat = 30
let cellW = thumbW + pad
var thumbH: CGFloat = 0

// Load images
var imgs: [NSImage] = []
for n in 1...10 {
    if let img = NSImage(contentsOfFile: "\(dir)/fresh\(n).png") {
        imgs.append(img)
        if thumbH == 0 { thumbH = thumbW * (img.size.height / img.size.width) }
    }
}
let cellH = thumbH + labelH + pad
let W = CGFloat(cols) * cellW + pad
let H = CGFloat(rows) * cellH + pad

let canvas = NSImage(size: NSSize(width: W, height: H))
canvas.lockFocus()
NSColor(white: 0.96, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: W, height: H).fill()

for (i, img) in imgs.enumerated() {
    let col = i % cols, row = i / cols
    let x = pad + CGFloat(col) * cellW
    let yTop = H - pad - CGFloat(row) * cellH
    let rect = NSRect(x: x, y: yTop - thumbH, width: thumbW, height: thumbH)
    img.draw(in: rect, from: .zero, operation: .copy, fraction: 1)

    let p = NSMutableParagraphStyle(); p.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 16, weight: .semibold),
        .foregroundColor: NSColor.black, .paragraphStyle: p]
    (names[i] as NSString).draw(in: NSRect(x: x - 6, y: yTop - thumbH - labelH + 4, width: thumbW + 12, height: labelH),
                                withAttributes: attrs)
}

canvas.unlockFocus()
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "montage.png"
let tiff = canvas.tiffRepresentation!
let png = NSBitmapImageRep(data: tiff)!.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
