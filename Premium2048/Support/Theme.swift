import SwiftUI

enum PremiumTheme {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.07, green: 0.10, blue: 0.17),
            Color(red: 0.10, green: 0.15, blue: 0.24),
            Color(red: 0.14, green: 0.20, blue: 0.29),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let boardBase = Color.white.opacity(0.10)
    static let boardStroke = Color.white.opacity(0.14)
    static let panelFill = LinearGradient(
        colors: [Color.white.opacity(0.15), Color.white.opacity(0.07)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accent = Color(red: 0.92, green: 0.80, blue: 0.58)
    static let secondaryAccent = Color(red: 0.65, green: 0.84, blue: 0.98)
    static let tileText = Color(red: 0.97, green: 0.98, blue: 1.00)
    static let emptyTile = Color.white.opacity(0.07)

    static func tileFill(for value: Int) -> LinearGradient {
        switch value {
        case 0:
            return LinearGradient(colors: [emptyTile, emptyTile], startPoint: .top, endPoint: .bottom)
        case 2:
            return LinearGradient(colors: [Color(red: 0.46, green: 0.56, blue: 0.70), Color(red: 0.30, green: 0.38, blue: 0.53)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 4:
            return LinearGradient(colors: [Color(red: 0.49, green: 0.64, blue: 0.78), Color(red: 0.34, green: 0.46, blue: 0.60)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 8:
            return LinearGradient(colors: [Color(red: 0.71, green: 0.56, blue: 0.42), Color(red: 0.57, green: 0.39, blue: 0.24)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 16:
            return LinearGradient(colors: [Color(red: 0.78, green: 0.61, blue: 0.45), Color(red: 0.66, green: 0.45, blue: 0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 32:
            return LinearGradient(colors: [Color(red: 0.84, green: 0.64, blue: 0.47), Color(red: 0.76, green: 0.48, blue: 0.24)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 64:
            return LinearGradient(colors: [Color(red: 0.91, green: 0.72, blue: 0.46), Color(red: 0.84, green: 0.57, blue: 0.22)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 128:
            return LinearGradient(colors: [Color(red: 0.63, green: 0.76, blue: 0.88), Color(red: 0.45, green: 0.55, blue: 0.72)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 256:
            return LinearGradient(colors: [Color(red: 0.69, green: 0.82, blue: 0.93), Color(red: 0.52, green: 0.62, blue: 0.79)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 512:
            return LinearGradient(colors: [Color(red: 0.90, green: 0.79, blue: 0.56), Color(red: 0.76, green: 0.62, blue: 0.28)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 1024:
            return LinearGradient(colors: [Color(red: 0.96, green: 0.85, blue: 0.61), Color(red: 0.83, green: 0.68, blue: 0.29)], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [accent, secondaryAccent], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
