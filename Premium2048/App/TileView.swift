import SwiftUI

struct TileView: View {
    let value: Int
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(PremiumTheme.tileFill(for: value))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .strokeBorder(Color.white.opacity(value == 0 ? 0.05 : 0.18), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(value == 0 ? 0.0 : 0.18), radius: value == 0 ? 0 : 20, x: 0, y: 10)

            if value != 0 {
                Text("\(value)")
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(PremiumTheme.tileText)
                    .minimumScaleFactor(0.45)
                    .lineLimit(1)
            }
        }
        .frame(width: size, height: size)
    }

    private var fontSize: CGFloat {
        switch value {
        case 0..<128: return size * 0.30
        case 128..<1024: return size * 0.24
        default: return size * 0.20
        }
    }
}
