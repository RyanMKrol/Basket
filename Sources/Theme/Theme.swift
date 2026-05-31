import SwiftUI

/// Central place for Basket's soft / friendly / playful look.
/// Warm off-white paper, faint grocery-coloured blushes (green + tomato),
/// rounded type, gentle shadows. No hard accents — just splashes of colour.
enum Theme {
    // Warm "paper" background the whole app sits on.
    static let paper = Color(red: 0.984, green: 0.972, blue: 0.957) // ~#FBF8F4

    // Soft grocery accents — kept gentle and desaturated.
    static let leaf = Color(red: 0.42, green: 0.66, blue: 0.40)  // soft green
    static let tomato = Color(red: 0.92, green: 0.45, blue: 0.42) // soft coral/red

    // Card + text colours.
    static let card = Color.white
    static let ink = Color(red: 0.18, green: 0.17, blue: 0.16)   // warm near-black
    static let inkSoft = Color(red: 0.55, green: 0.53, blue: 0.50)

    // Corner radii & shadow used across cards.
    static let cardRadius: CGFloat = 18
    static let cardShadow = Color.black.opacity(0.05)
}

/// The app's background: warm paper with two very-low-opacity radial washes,
/// soft green up top and soft tomato toward the bottom — the "slight blushing".
struct BasketBackground: View {
    var body: some View {
        ZStack {
            Theme.paper
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    RadialGradient(
                        colors: [Theme.leaf.opacity(0.16), .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: w * 0.95
                    )
                    RadialGradient(
                        colors: [Theme.tomato.opacity(0.14), .clear],
                        center: .bottomTrailing,
                        startRadius: 0,
                        endRadius: w * 1.05
                    )
                    .offset(y: h * 0.02)
                }
            }
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// A soft white rounded card with a gentle shadow.
    func basketCard() -> some View {
        self
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            .shadow(color: Theme.cardShadow, radius: 8, x: 0, y: 3)
    }
}
