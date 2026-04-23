import SwiftUI

struct PremiumPalette {
    let name: VisualTheme
    let backgroundGradient: LinearGradient
    let heroGradient: LinearGradient
    let boardGradient: LinearGradient
    let boardStroke: Color
    let panelGradient: LinearGradient
    let panelStroke: Color
    let accent: Color
    let accentSecondary: Color
    let textPrimary: Color
    let textSecondary: Color
    let emptyTile: Color
    let glow: Color
    let shadow: Color

    func tileGradient(for value: Int) -> LinearGradient {
        switch value {
        case 0:
            return LinearGradient(colors: [emptyTile, emptyTile.opacity(0.84)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 2:
            return gradient(0.74, 0.58, 0.98, 0.48, 0.31, 0.82)
        case 4:
            return gradient(0.60, 0.73, 0.99, 0.38, 0.47, 0.88)
        case 8:
            return gradient(0.42, 0.91, 0.88, 0.16, 0.66, 0.78)
        case 16:
            return gradient(0.29, 0.90, 0.63, 0.16, 0.63, 0.47)
        case 32:
            return gradient(0.95, 0.83, 0.42, 0.88, 0.54, 0.17)
        case 64:
            return gradient(0.98, 0.60, 0.32, 0.90, 0.31, 0.18)
        case 128:
            return gradient(0.99, 0.50, 0.51, 0.80, 0.21, 0.42)
        case 256:
            return gradient(0.96, 0.43, 0.69, 0.70, 0.20, 0.62)
        case 512:
            return gradient(0.83, 0.39, 0.95, 0.54, 0.24, 0.88)
        case 1024:
            return gradient(0.70, 0.54, 1.00, 0.44, 0.33, 0.97)
        default:
            return LinearGradient(colors: [accent, accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func gradient(
        _ r1: Double,
        _ g1: Double,
        _ b1: Double,
        _ r2: Double,
        _ g2: Double,
        _ b2: Double
    ) -> LinearGradient {
        LinearGradient(
            colors: [
                Color(red: r1, green: g1, blue: b1),
                Color(red: r2, green: g2, blue: b2),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

enum PremiumTheme {
    static func palette(for selection: VisualTheme) -> PremiumPalette {
        switch selection {
        case .arcadePulse:
            return PremiumPalette(
                name: selection,
                backgroundGradient: LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.03, blue: 0.12),
                        Color(red: 0.11, green: 0.06, blue: 0.24),
                        Color(red: 0.22, green: 0.11, blue: 0.33),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                heroGradient: LinearGradient(
                    colors: [
                        Color(red: 0.97, green: 0.82, blue: 0.38),
                        Color(red: 1.00, green: 0.49, blue: 0.55),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                boardGradient: LinearGradient(
                    colors: [
                        Color.white.opacity(0.14),
                        Color.white.opacity(0.08),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                boardStroke: Color.white.opacity(0.12),
                panelGradient: LinearGradient(
                    colors: [
                        Color.white.opacity(0.18),
                        Color.white.opacity(0.08),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                panelStroke: Color.white.opacity(0.15),
                accent: Color(red: 1.00, green: 0.56, blue: 0.44),
                accentSecondary: Color(red: 0.99, green: 0.84, blue: 0.39),
                textPrimary: Color.white,
                textSecondary: Color.white.opacity(0.72),
                emptyTile: Color.white.opacity(0.06),
                glow: Color(red: 0.98, green: 0.44, blue: 0.62),
                shadow: Color.black.opacity(0.35)
            )
        case .sunsetSynth:
            return PremiumPalette(
                name: selection,
                backgroundGradient: LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.12, blue: 0.18),
                        Color(red: 0.14, green: 0.18, blue: 0.25),
                        Color(red: 0.25, green: 0.14, blue: 0.18),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                heroGradient: LinearGradient(
                    colors: [
                        Color(red: 0.99, green: 0.90, blue: 0.58),
                        Color(red: 0.96, green: 0.62, blue: 0.45),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                boardGradient: LinearGradient(
                    colors: [
                        Color(red: 1.00, green: 0.97, blue: 0.91).opacity(0.18),
                        Color(red: 1.00, green: 0.91, blue: 0.78).opacity(0.08),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                boardStroke: Color.white.opacity(0.14),
                panelGradient: LinearGradient(
                    colors: [
                        Color.white.opacity(0.16),
                        Color.white.opacity(0.09),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                panelStroke: Color.white.opacity(0.12),
                accent: Color(red: 0.98, green: 0.66, blue: 0.39),
                accentSecondary: Color(red: 0.99, green: 0.86, blue: 0.60),
                textPrimary: Color.white,
                textSecondary: Color.white.opacity(0.72),
                emptyTile: Color.white.opacity(0.05),
                glow: Color(red: 0.99, green: 0.65, blue: 0.35),
                shadow: Color.black.opacity(0.32)
            )
        }
    }
}
