import SwiftUI

struct TileView: View {
    enum Emphasis {
        case idle
        case merged
        case spawned
        case highlighted
    }

    let value: Int
    let size: CGFloat
    let palette: PremiumPalette
    var emphasis: Emphasis = .idle
    var opacity: Double = 1

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                .fill(palette.tileGradient(for: value))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: value == 0 ? 1 : 1.2)
                )
                .shadow(color: glowColor.opacity(value == 0 ? 0.0 : 0.22), radius: size * 0.14, x: 0, y: size * 0.07)

            if value != 0 {
                VStack(spacing: size * 0.02) {
                    Text("\(value)")
                        .font(.system(size: fontSize, weight: .black, design: .rounded))
                        .foregroundStyle(palette.textPrimary)
                        .minimumScaleFactor(0.42)
                        .lineLimit(1)

                    if value >= 128 {
                        Capsule()
                            .fill(Color.white.opacity(0.22))
                            .frame(width: size * 0.34, height: size * 0.05)
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(scaleEffect)
        .opacity(opacity)
    }

    private var fontSize: CGFloat {
        switch value {
        case 0..<128: return size * 0.30
        case 128..<1024: return size * 0.24
        default: return size * 0.20
        }
    }

    private var scaleEffect: CGFloat {
        switch emphasis {
        case .idle: return 1
        case .merged: return 1.08
        case .spawned: return 0.96
        case .highlighted: return 1.04
        }
    }

    private var borderColor: Color {
        switch emphasis {
        case .highlighted:
            return Color.white.opacity(0.42)
        case .merged, .spawned:
            return Color.white.opacity(0.28)
        case .idle:
            return Color.white.opacity(value == 0 ? 0.05 : 0.16)
        }
    }

    private var glowColor: Color {
        switch emphasis {
        case .merged, .spawned, .highlighted:
            return palette.glow
        case .idle:
            return palette.shadow
        }
    }
}
