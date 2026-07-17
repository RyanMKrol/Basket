import SwiftUI

/// How body/title text is rendered.
enum FontKind {
    case rounded
    case monospaced
    case custom(String, scale: CGFloat)   // bundled font; scale tunes its metrics
}

/// Background treatment.
enum BackgroundStyle {
    case dotted(Color)            // pixel polka-dots
}

/// The app's single look, Pastel Dots.
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
    /// The one and only look: Pastel Dots.
    static let current: ThemeStyle = .pastelDots

    // MARK: live accessors (views read these)
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

    static func body(_ size: CGFloat, weight: Font.Weight = .regular, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        font(current.bodyFont, size: size, weight: weight, relativeTo: textStyle)
    }
    static func title(_ size: CGFloat, weight: Font.Weight = .bold, relativeTo textStyle: Font.TextStyle = .title) -> Font {
        font(current.titleFont, size: size, weight: weight, relativeTo: textStyle)
    }
    private static func font(_ kind: FontKind, size: CGFloat, weight: Font.Weight, relativeTo textStyle: Font.TextStyle) -> Font {
        switch kind {
        // `.rounded`/`.monospaced` aren't used by pastelDots (both fonts are `.custom`); they
        // don't yet participate in Dynamic Type. Revisit if a non-custom theme is ever added.
        case .rounded: return .system(size: size, weight: weight, design: .rounded)
        case .monospaced: return .system(size: size, weight: weight, design: .monospaced)
        case .custom(let name, let scale): return .custom(name, size: size * scale, relativeTo: textStyle)
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

/// The app's background: a soft pixel polka-dot backdrop.
struct BasketBackground: View {
    /// Injectable so snapshot tests can pin the time-of-day tint; production
    /// uses the app clock. Mirrors `EmptyStateView.now`.
    var now: Date = AppClock.now

    var body: some View {
        ZStack {
            Theme.paper
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                switch Theme.current.background {
                case .dotted(let c): dots(c, w, h)
                }
            }
            // A whisper of time-of-day colour over the light backdrop — cool in
            // the morning, golden in the evening. Kept very faint so it never
            // fights the theme.
            timeTint
        }
        .ignoresSafeArea()
    }

    @ViewBuilder private var timeTint: some View {
        switch Seasonality.timeOfDay(now) {
        case .morning:   Color(red: 0.50, green: 0.62, blue: 0.85).opacity(0.05)
        case .afternoon: Color.clear
        case .evening:   Color(red: 0.96, green: 0.64, blue: 0.34).opacity(0.06)
        case .night:     Color(red: 0.32, green: 0.34, blue: 0.56).opacity(0.05)
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
}
