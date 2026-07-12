import SwiftUI

private func rgb(_ r: Double, _ g: Double, _ b: Double) -> Color {
    Color(red: r, green: g, blue: b)
}

private let freshGreen = rgb(0.36, 0.72, 0.52)

extension ThemeStyle {
    /// The finalised look: Cozy-pixel with a soft green pastel-dot backdrop.
    static let pastelDots = ThemeStyle(
        id: "fresh7", name: "Pastel Dots", isDark: false,
        paper: rgb(0.992, 0.985, 0.96), card: rgb(1.0, 0.99, 0.965),
        ink: rgb(0.17, 0.21, 0.19), inkSoft: rgb(0.48, 0.52, 0.49),
        onPaper: rgb(0.17, 0.21, 0.19), onPaperSoft: rgb(0.42, 0.47, 0.44),
        leaf: freshGreen, tomato: rgb(0.95, 0.45, 0.42), sun: rgb(0.98, 0.80, 0.33),
        cardRadius: 8, borderWidth: 2, borderColor: rgb(0.88, 0.90, 0.85),
        cardShadow: Color.black.opacity(0.07), shadowRadius: 5,
        bodyFont: .custom("VT323", scale: 1.15),
        titleFont: .custom("Silkscreen", scale: 0.78),
        background: .dotted(freshGreen.opacity(0.18)))
}
