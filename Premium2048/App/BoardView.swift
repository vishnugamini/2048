import SwiftUI

struct BoardView: View {
    let board: BoardState

    var body: some View {
        GeometryReader { proxy in
            let boardSize = proxy.size.width
            let spacing = boardSize * 0.035
            let tileSize = (boardSize - (spacing * 5)) / 4

            ZStack {
                RoundedRectangle(cornerRadius: boardSize * 0.08, style: .continuous)
                    .fill(PremiumTheme.panelFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: boardSize * 0.08, style: .continuous)
                            .strokeBorder(PremiumTheme.boardStroke, lineWidth: 1)
                    )

                VStack(spacing: spacing) {
                    ForEach(Array(board.rows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: spacing) {
                            ForEach(Array(row.enumerated()), id: \.offset) { _, value in
                                TileView(value: value, size: tileSize)
                            }
                        }
                    }
                }
                .padding(spacing)
            }
            .frame(width: boardSize, height: boardSize)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipped()
    }
}
