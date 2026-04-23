import SwiftUI

struct BoardView: View {
    let board: BoardState
    let palette: PremiumPalette
    let movePresentation: GameViewModel.MovePresentation?
    let hintedDirection: MoveDirection?

    @State private var activeMoveID: Int?
    @State private var travelProgress: CGFloat = 1
    @State private var spawnScale: CGFloat = 1
    @State private var settleBoard = true
    @State private var mergedPositions: Set<BoardPosition> = []

    var body: some View {
        GeometryReader { proxy in
            let metrics = BoardMetrics(size: proxy.size.width)

            ZStack {
                RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.20),
                                palette.accent.opacity(0.10),
                                Color.white.opacity(0.08),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1.2)
                    )
                    .shadow(color: palette.shadow.opacity(0.72), radius: metrics.boardShadow, x: 0, y: metrics.boardShadow * 0.48)

                RoundedRectangle(cornerRadius: metrics.cornerRadius * 0.78, style: .continuous)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    .padding(metrics.spacing * 1.15)

                ForEach(0..<BoardState.dimension, id: \.self) { row in
                    ForEach(0..<BoardState.dimension, id: \.self) { column in
                        TileView(
                            value: 0,
                            size: metrics.tileSize,
                            palette: palette,
                            opacity: 1
                        )
                        .position(metrics.center(for: BoardPosition(row: row, column: column)))
                    }
                }

                ForEach(Self.allPositions, id: \.self) { position in
                    let value = board[position.row, position.column]
                    if value != 0 {
                        TileView(
                            value: value,
                            size: metrics.tileSize,
                            palette: palette,
                            emphasis: mergedPositions.contains(position) ? .merged : (position == hintDestination ? .highlighted : .idle),
                            opacity: hiddenStablePositions.contains(position) && !settleBoard ? 0 : 1
                        )
                        .position(metrics.center(for: position))
                    }
                }

                if let movePresentation, !settleBoard {
                    movingTilesOverlay(movePresentation: movePresentation, metrics: metrics)
                }

                if let direction = hintedDirection {
                    hintArrow(direction: direction, metrics: metrics)
                }
            }
            .frame(width: metrics.size, height: metrics.size)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            guard let movePresentation else { return }
            prepareAnimation(for: movePresentation)
        }
        .onChange(of: movePresentation?.id) { _, _ in
            guard let movePresentation else { return }
            prepareAnimation(for: movePresentation)
        }
    }

    private var hiddenStablePositions: Set<BoardPosition> {
        guard let movePresentation else { return [] }

        var positions = Set(movePresentation.result.tileMotions.map(\.destination))
        if let spawnedTile = movePresentation.result.spawnedTile {
            positions.insert(spawnedTile.position)
        }
        return positions
    }

    private var hintDestination: BoardPosition? {
        guard let hintedDirection else { return nil }

        switch hintedDirection {
        case .up: return BoardPosition(row: 0, column: 1)
        case .down: return BoardPosition(row: BoardState.dimension - 1, column: 2)
        case .left: return BoardPosition(row: 1, column: 0)
        case .right: return BoardPosition(row: 2, column: BoardState.dimension - 1)
        }
    }

    private func movingTilesOverlay(
        movePresentation: GameViewModel.MovePresentation,
        metrics: BoardMetrics
    ) -> some View {
        ZStack {
            ForEach(Array(movePresentation.result.tileMotions.enumerated()), id: \.offset) { index, motion in
                TileView(
                    value: motion.value,
                    size: metrics.tileSize,
                    palette: palette,
                    emphasis: motion.mergedIntoDestination ? .highlighted : .idle,
                    opacity: motion.mergedIntoDestination ? Double(max(0.45, 1 - travelProgress * 0.4)) : Double(max(0.75, 1 - travelProgress * 0.1))
                )
                .position(interpolatedCenter(for: motion, metrics: metrics))
                .zIndex(Double(100 - index))
            }

            if let spawnedTile = movePresentation.result.spawnedTile, !settleBoard {
                TileView(
                    value: spawnedTile.value,
                    size: metrics.tileSize,
                    palette: palette,
                    emphasis: .spawned
                )
                .scaleEffect(spawnScale)
                .position(metrics.center(for: spawnedTile.position))
            }
        }
    }

    private func hintArrow(direction: MoveDirection, metrics: BoardMetrics) -> some View {
        Image(systemName: symbol(for: direction))
            .font(.system(size: metrics.tileSize * 0.18, weight: .black))
            .foregroundStyle(palette.textPrimary)
            .padding(.horizontal, metrics.tileSize * 0.18)
            .padding(.vertical, metrics.tileSize * 0.10)
            .background(
                Capsule()
                    .fill(palette.panelGradient)
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
            .position(metrics.hintPosition(for: direction))
            .transition(.scale.combined(with: .opacity))
    }

    private func interpolatedCenter(for motion: TileMotion, metrics: BoardMetrics) -> CGPoint {
        let start = metrics.center(for: motion.source)
        let end = metrics.center(for: motion.destination)
        let progress = movePresentation?.reducedMotion == true ? 1 : travelProgress

        return CGPoint(
            x: start.x + ((end.x - start.x) * progress),
            y: start.y + ((end.y - start.y) * progress)
        )
    }

    private func prepareAnimation(for presentation: GameViewModel.MovePresentation) {
        activeMoveID = presentation.id
        mergedPositions = []

        guard !presentation.reducedMotion else {
            travelProgress = 1
            spawnScale = 1
            settleBoard = true
            mergedPositions = Set(presentation.result.mergeEvents.map(\.destination))
            clearMergedPulseLater()
            return
        }

        travelProgress = 0
        spawnScale = 0.28
        settleBoard = false

        withAnimation(.interactiveSpring(response: 0.26, dampingFraction: 0.84, blendDuration: 0.16)) {
            travelProgress = 1
        }

        withAnimation(.spring(response: 0.34, dampingFraction: 0.68).delay(0.06)) {
            spawnScale = 1
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))
            guard activeMoveID == presentation.id else { return }
            settleBoard = true
            mergedPositions = Set(presentation.result.mergeEvents.map(\.destination))
            clearMergedPulseLater()
        }
    }

    private func clearMergedPulseLater() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))
            mergedPositions = []
        }
    }

    private func symbol(for direction: MoveDirection) -> String {
        switch direction {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .left: return "arrow.left"
        case .right: return "arrow.right"
        }
    }

    private static let allPositions: [BoardPosition] = (0..<BoardState.dimension).flatMap { row in
        (0..<BoardState.dimension).map { BoardPosition(row: row, column: $0) }
    }
}

private struct BoardMetrics {
    let size: CGFloat

    var spacing: CGFloat { size * 0.028 }
    var tileSize: CGFloat { (size - (spacing * 5)) / 4 }
    var cornerRadius: CGFloat { size * 0.072 }
    var boardShadow: CGFloat { size * 0.05 }

    func center(for position: BoardPosition) -> CGPoint {
        CGPoint(
            x: spacing + (tileSize / 2) + CGFloat(position.column) * (tileSize + spacing),
            y: spacing + (tileSize / 2) + CGFloat(position.row) * (tileSize + spacing)
        )
    }

    func hintPosition(for direction: MoveDirection) -> CGPoint {
        switch direction {
        case .up:
            return CGPoint(x: size / 2, y: spacing * 1.2)
        case .down:
            return CGPoint(x: size / 2, y: size - spacing * 1.2)
        case .left:
            return CGPoint(x: spacing * 1.2, y: size / 2)
        case .right:
            return CGPoint(x: size - spacing * 1.2, y: size / 2)
        }
    }
}
