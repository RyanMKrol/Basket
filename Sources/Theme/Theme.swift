import SwiftUI

/// How body/title text is rendered for a theme.
enum FontKind {
    case rounded
    case monospaced
    case custom(String, scale: CGFloat)   // bundled font; scale tunes its metrics
}

/// Background treatment for a theme.
enum BackgroundStyle {
    case blooms       // soft grocery colour blooms (the original)
    case pixelGrid    // dark slate with a faint graph-paper grid
    case ocean        // deep-sea vertical gradient + light rays
    case parchment    // warm paper with a soft vignette
    case neon         // near-black with a faint grid + neon glow
    // Fresh, light backdrops (parameterised) for the Cozy-pixel explorations:
    case freshBlooms([Color])     // soft light colour blooms in the corners
    case wash(Color, Color)       // vertical gradient (top → bottom)
    case softGrid(Color)          // faint pixel graph-paper grid in a colour
    case dotted(Color)            // pixel polka-dots
    case stripes(Color, Color)    // soft horizontal bands
}

/// A complete look. Themes are swapped at launch via the BASKET_THEME env var.
struct ThemeStyle {
    let id: String
    let name: String
    let isDark: Bool

    // Surfaces
    let paper: Color
    let card: Color
    // Text on cards
    let ink: Color
    let inkSoft: Color
    // Text on the background
    let onPaper: Color
    let onPaperSoft: Color
    // Accents
    let leaf: Color     // primary (checks, the + button)
    let tomato: Color   // secondary
    let sun: Color      // tertiary

    // Card chrome
    let cardRadius: CGFloat
    let borderWidth: CGFloat
    let borderColor: Color
    let cardShadow: Color
    let shadowRadius: CGFloat

    // Type & backdrop
    let bodyFont: FontKind
    let titleFont: FontKind
    let background: BackgroundStyle
}

enum Theme {
    /// The active theme. Defaults to the finalised Pastel Dots look; can be
    /// overridden at launch via the BASKET_THEME env var (for experimentation).
    static var current: ThemeStyle = .pastelDots

    static let all: [ThemeStyle] = [.soft, .pixelPantry, .deepDive, .cozyCabin, .nightArcade] + ThemeStyle.fresh

    static func select(id: String?) {
        if let id, let match = all.first(where: { $0.id == id }) { current = match }
    }

    // MARK: live accessors (views read these; they follow `current`)
    static var paper: Color { current.paper }
    static var card: Color { current.card }
    static var ink: Color { current.ink }
    static var inkSoft: Color { current.inkSoft }
    static var onPaper: Color { current.onPaper }
    static var onPaperSoft: Color { current.onPaperSoft }
    static var leaf: Color { current.leaf }
    static var tomato: Color { current.tomato }
    static var sun: Color { current.sun }
    static var cardRadius: CGFloat { current.cardRadius }
    static var borderWidth: CGFloat { current.borderWidth }
    static var borderColor: Color { current.borderColor }
    static var cardShadow: Color { current.cardShadow }
    static var shadowRadius: CGFloat { current.shadowRadius }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        font(current.bodyFont, size: size, weight: weight)
    }
    static func title(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        font(current.titleFont, size: size, weight: weight)
    }
    private static func font(_ kind: FontKind, size: CGFloat, weight: Font.Weight) -> Font {
        switch kind {
        case .rounded: return .system(size: size, weight: weight, design: .rounded)
        case .monospaced: return .system(size: size, weight: weight, design: .monospaced)
        case .custom(let name, let scale): return .custom(name, size: size * scale)
        }
    }
}

extension View {
    /// A themed card: fill, optional border, gentle shadow.
    func basketCard() -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
        return self
            .background(Theme.card, in: shape)
            .overlay(shape.strokeBorder(Theme.borderColor, lineWidth: Theme.borderWidth))
            .shadow(color: Theme.cardShadow, radius: Theme.shadowRadius, x: 0, y: 2)
    }
}

/// The app's background — switches treatment per theme.
struct BasketBackground: View {
    var body: some View {
        ZStack {
            Theme.paper
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                switch Theme.current.background {
                case .blooms: blooms(w, h)
                case .pixelGrid: grid(w, h, line: Color.white.opacity(0.04), step: 18)
                case .ocean: ocean(w, h)
                case .parchment: vignette(w, h)
                case .neon: neon(w, h)
                case .freshBlooms(let colors): freshBlooms(colors, w, h)
                case .wash(let top, let bottom):
                    LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
                case .softGrid(let c): grid(w, h, line: c, step: 20)
                case .dotted(let c): dots(c, w, h)
                case .stripes(let a, let b): stripes(a, b, h)
                }
            }
        }
        .ignoresSafeArea()
    }

    private func blooms(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            RadialGradient(colors: [Theme.leaf.opacity(0.28), .clear], center: .topLeading, startRadius: 0, endRadius: w * 0.95)
            RadialGradient(colors: [Theme.sun.opacity(0.26), .clear], center: .topTrailing, startRadius: 0, endRadius: w * 0.9)
            RadialGradient(colors: [Theme.tomato.opacity(0.26), .clear], center: .bottomTrailing, startRadius: 0, endRadius: w * 1.05)
            RadialGradient(colors: [Theme.tomato.opacity(0.15), .clear], center: .bottomLeading, startRadius: 0, endRadius: w * 0.8)
        }
    }

    private func grid(_ w: CGFloat, _ h: CGFloat, line: Color, step: CGFloat) -> some View {
        Canvas { ctx, size in
            var p = Path()
            var x: CGFloat = 0
            while x <= size.width { p.move(to: .init(x: x, y: 0)); p.addLine(to: .init(x: x, y: size.height)); x += step }
            var y: CGFloat = 0
            while y <= size.height { p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: size.width, y: y)); y += step }
            ctx.stroke(p, with: .color(line), lineWidth: 1)
        }
    }

    private func ocean(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.05, green: 0.30, blue: 0.40),
                                    Color(red: 0.03, green: 0.13, blue: 0.22)],
                           startPoint: .top, endPoint: .bottom)
            // soft light rays from the surface
            LinearGradient(colors: [Color.white.opacity(0.10), .clear], startPoint: .top, endPoint: .center)
                .rotationEffect(.degrees(12)).blendMode(.screen)
            RadialGradient(colors: [Color(red: 0.25, green: 0.7, blue: 0.75).opacity(0.18), .clear],
                           center: .top, startRadius: 0, endRadius: w)
        }
    }

    private func vignette(_ w: CGFloat, _ h: CGFloat) -> some View {
        RadialGradient(colors: [.clear, Color(red: 0.45, green: 0.34, blue: 0.20).opacity(0.18)],
                       center: .center, startRadius: w * 0.3, endRadius: w * 0.95)
    }

    private func neon(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            grid(w, h, line: Color.white.opacity(0.05), step: 22)
            RadialGradient(colors: [Theme.leaf.opacity(0.18), .clear], center: .topLeading, startRadius: 0, endRadius: w * 0.8)
            RadialGradient(colors: [Theme.tomato.opacity(0.18), .clear], center: .bottomTrailing, startRadius: 0, endRadius: w * 0.9)
        }
    }

    /// Soft, light colour blooms in the four corners (cycles the given colours).
    private func freshBlooms(_ colors: [Color], _ w: CGFloat, _ h: CGFloat) -> some View {
        let corners: [UnitPoint] = [.topLeading, .topTrailing, .bottomTrailing, .bottomLeading]
        return ZStack {
            ForEach(Array(corners.enumerated()), id: \.offset) { i, corner in
                if !colors.isEmpty {
                    RadialGradient(colors: [colors[i % colors.count].opacity(0.42), .clear],
                                   center: corner, startRadius: 0, endRadius: w * 0.95)
                }
            }
        }
    }

    private func dots(_ color: Color, _ w: CGFloat, _ h: CGFloat) -> some View {
        Canvas { ctx, size in
            let step: CGFloat = 26, r: CGFloat = 2.4
            var y: CGFloat = step / 2
            while y <= size.height {
                var x: CGFloat = step / 2
                while x <= size.width {
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                             with: .color(color))
                    x += step
                }
                y += step
            }
        }
    }

    private func stripes(_ a: Color, _ b: Color, _ h: CGFloat) -> some View {
        Canvas { ctx, size in
            let band: CGFloat = 26
            var y: CGFloat = 0
            var on = true
            while y < size.height {
                ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: band)),
                         with: .color(on ? a : b))
                y += band; on.toggle()
            }
        }
    }
}
