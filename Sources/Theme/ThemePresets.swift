import SwiftUI

private func rgb(_ r: Double, _ g: Double, _ b: Double) -> Color {
    Color(red: r, green: g, blue: b)
}

// Fresh, light, fruity accent colours shared by the Cozy-pixel background studies.
private let mint = rgb(0.55, 0.85, 0.70)
private let lemon = rgb(0.99, 0.90, 0.50)
private let coral = rgb(0.99, 0.62, 0.55)
private let sky = rgb(0.60, 0.83, 0.87)
private let pink = rgb(0.99, 0.76, 0.79)
private let freshGreen = rgb(0.36, 0.72, 0.52)

extension ThemeStyle {
    /// A Cozy-pixel theme that holds cards + fonts + accents constant, varying
    /// only the paper colour and background — for the "fresh backgrounds" study.
    static func cozyFresh(_ id: String, _ name: String,
                          paper: Color, background: BackgroundStyle) -> ThemeStyle {
        ThemeStyle(
            id: id, name: name, isDark: false,
            paper: paper, card: rgb(1.0, 0.99, 0.965),
            ink: rgb(0.17, 0.21, 0.19), inkSoft: rgb(0.48, 0.52, 0.49),
            onPaper: rgb(0.17, 0.21, 0.19), onPaperSoft: rgb(0.42, 0.47, 0.44),
            leaf: freshGreen, tomato: rgb(0.95, 0.45, 0.42), sun: rgb(0.98, 0.80, 0.33),
            cardRadius: 8, borderWidth: 2, borderColor: rgb(0.88, 0.90, 0.85),
            cardShadow: Color.black.opacity(0.07), shadowRadius: 5,
            bodyFont: .custom("VT323", scale: 1.15),
            titleFont: .custom("Silkscreen", scale: 0.78),
            background: background)
    }

    static let fresh: [ThemeStyle] = [
        .cozyFresh("fresh1", "Cream Blooms", paper: rgb(0.992, 0.984, 0.957),
                   background: .freshBlooms([mint, lemon, coral, sky])),
        .cozyFresh("fresh2", "Mint Air", paper: rgb(0.93, 0.97, 0.93),
                   background: .wash(rgb(0.86, 0.95, 0.88), rgb(0.99, 0.99, 0.96))),
        .cozyFresh("fresh3", "Lemon Soda", paper: rgb(0.992, 0.984, 0.90),
                   background: .freshBlooms([lemon, mint])),
        .cozyFresh("fresh4", "Sky Field", paper: rgb(0.95, 0.98, 0.97),
                   background: .wash(rgb(0.78, 0.91, 0.92), rgb(0.97, 0.99, 0.93))),
        .cozyFresh("fresh5", "Berry Cream", paper: rgb(0.992, 0.95, 0.93),
                   background: .freshBlooms([coral, pink, lemon])),
        .cozyFresh("fresh6", "Garden Grid", paper: rgb(0.97, 0.985, 0.94),
                   background: .softGrid(freshGreen.opacity(0.14))),
        .cozyFresh("fresh7", "Pastel Dots", paper: rgb(0.992, 0.985, 0.96),
                   background: .dotted(freshGreen.opacity(0.18))),
        .cozyFresh("fresh8", "Seafoam Bands", paper: rgb(0.95, 0.98, 0.96),
                   background: .stripes(rgb(0.90, 0.96, 0.92), rgb(0.985, 0.99, 0.96))),
        .cozyFresh("fresh9", "Fruit Punch", paper: rgb(0.992, 0.975, 0.95),
                   background: .freshBlooms([coral, lemon, mint, sky])),
        .cozyFresh("fresh10", "Morning Light", paper: rgb(0.992, 0.985, 0.93),
                   background: .wash(rgb(0.99, 0.95, 0.78), rgb(0.88, 0.96, 0.90))),
    ]
}

extension ThemeStyle {
    /// The original — soft, friendly, rounded, with grocery-colour blooms.
    static let soft = ThemeStyle(
        id: "soft", name: "Soft & Friendly", isDark: false,
        paper: rgb(0.984, 0.972, 0.957), card: .white,
        ink: rgb(0.18, 0.17, 0.16), inkSoft: rgb(0.62, 0.60, 0.57),
        onPaper: rgb(0.18, 0.17, 0.16), onPaperSoft: rgb(0.62, 0.60, 0.57),
        leaf: rgb(0.42, 0.66, 0.40), tomato: rgb(0.92, 0.45, 0.42), sun: rgb(0.97, 0.80, 0.36),
        cardRadius: 18, borderWidth: 0, borderColor: .clear,
        cardShadow: Color.black.opacity(0.05), shadowRadius: 8,
        bodyFont: .rounded, titleFont: .rounded, background: .blooms)

    /// Terraria-style: dark earth, chunky parchment panels, pixel type.
    static let pixelPantry = ThemeStyle(
        id: "pixel", name: "Pixel Pantry", isDark: false,
        paper: rgb(0.125, 0.141, 0.114), card: rgb(0.867, 0.788, 0.627),
        ink: rgb(0.18, 0.141, 0.098), inkSoft: rgb(0.43, 0.37, 0.27),
        onPaper: rgb(0.918, 0.851, 0.69), onPaperSoft: rgb(0.718, 0.647, 0.494),
        leaf: rgb(0.435, 0.69, 0.29), tomato: rgb(0.773, 0.314, 0.243), sun: rgb(0.878, 0.698, 0.235),
        cardRadius: 3, borderWidth: 3, borderColor: rgb(0.18, 0.141, 0.098),
        cardShadow: Color.black.opacity(0.28), shadowRadius: 0,
        bodyFont: .custom("Silkscreen", scale: 0.95),
        titleFont: .custom("Press Start 2P", scale: 0.5),
        background: .pixelGrid)

    /// Dave-the-Diver-style: deep sea, teal panels, coral + sand accents.
    static let deepDive = ThemeStyle(
        id: "dive", name: "Deep Dive", isDark: true,
        paper: rgb(0.04, 0.118, 0.165), card: rgb(0.063, 0.235, 0.286),
        ink: rgb(0.918, 0.965, 0.957), inkSoft: rgb(0.561, 0.722, 0.745),
        onPaper: rgb(0.918, 0.965, 0.957), onPaperSoft: rgb(0.624, 0.761, 0.784),
        leaf: rgb(0.247, 0.753, 0.651), tomato: rgb(1.0, 0.478, 0.349), sun: rgb(1.0, 0.82, 0.4),
        cardRadius: 8, borderWidth: 1.5, borderColor: rgb(0.173, 0.42, 0.471),
        cardShadow: Color.black.opacity(0.3), shadowRadius: 6,
        bodyFont: .custom("VT323", scale: 1.15),
        titleFont: .custom("VT323", scale: 1.35),
        background: .ocean)

    /// Stardew-style: cosy parchment & wood, sage + terracotta, pixel type.
    static let cozyCabin = ThemeStyle(
        id: "cozy", name: "Cozy Cabin", isDark: false,
        paper: rgb(0.949, 0.902, 0.808), card: rgb(1.0, 0.984, 0.941),
        ink: rgb(0.29, 0.231, 0.165), inkSoft: rgb(0.6, 0.53, 0.42),
        onPaper: rgb(0.29, 0.231, 0.165), onPaperSoft: rgb(0.6, 0.53, 0.42),
        leaf: rgb(0.498, 0.635, 0.333), tomato: rgb(0.78, 0.482, 0.322), sun: rgb(0.902, 0.722, 0.298),
        cardRadius: 8, borderWidth: 2, borderColor: rgb(0.804, 0.725, 0.58),
        cardShadow: rgb(0.45, 0.34, 0.20).opacity(0.14), shadowRadius: 5,
        bodyFont: .custom("VT323", scale: 1.15),
        titleFont: .custom("Silkscreen", scale: 0.78),
        background: .parchment)

    /// Retro-arcade: near-black, neon glow, pixel type.
    static let nightArcade = ThemeStyle(
        id: "arcade", name: "Night Arcade", isDark: true,
        paper: rgb(0.055, 0.055, 0.086), card: rgb(0.102, 0.102, 0.149),
        ink: rgb(0.929, 0.929, 0.969), inkSoft: rgb(0.541, 0.541, 0.651),
        onPaper: rgb(0.929, 0.929, 0.969), onPaperSoft: rgb(0.604, 0.604, 0.722),
        leaf: rgb(0.224, 0.902, 0.659), tomato: rgb(1.0, 0.302, 0.427), sun: rgb(1.0, 0.882, 0.302),
        cardRadius: 4, borderWidth: 1.5, borderColor: rgb(0.224, 0.902, 0.659).opacity(0.55),
        cardShadow: rgb(0.224, 0.902, 0.659).opacity(0.25), shadowRadius: 8,
        bodyFont: .custom("VT323", scale: 1.15),
        titleFont: .custom("Press Start 2P", scale: 0.46),
        background: .neon)
}
