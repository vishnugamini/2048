import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        GeometryReader { proxy in
            let safeWidth = proxy.size.width - 40
            let safeHeight = proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom - 52
            let reservedHeight: CGFloat = 290
            let boardSize = max(240, min(safeWidth, safeHeight - reservedHeight))

            ZStack {
                PremiumTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 18) {
                    topBar(compact: proxy.size.height < 760)
                    boardHero(boardSize: boardSize)
                    actionBar
                    swipeHint
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, 20)
                .padding(.top, proxy.safeAreaInsets.top + 12)
                .padding(.bottom, max(proxy.safeAreaInsets.bottom, 16))
            }
        }
        .sheet(isPresented: $viewModel.showingSettings) {
            settingsSheet
                .presentationDetents([.fraction(0.34)])
        }
        .sheet(isPresented: $viewModel.showingStats) {
            statsSheet
                .presentationDetents([.fraction(0.34)])
        }
        .overlay {
            if let overlay = viewModel.overlayState {
                overlayView(for: overlay)
            }
        }
    }

    private func topBar(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("2048")
                        .font(.system(size: compact ? 40 : 48, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("A minimal puzzle, finished like a luxury object.")
                        .font(.system(size: compact ? 14 : 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.72))
                }

                Spacer()

                VStack(spacing: 10) {
                    statPill(title: "Score", value: "\(viewModel.score)")
                    statPill(title: "Best", value: "\(viewModel.bestScore)")
                }
            }

            HStack(spacing: 12) {
                glassButton(title: "Stats", systemImage: "chart.bar.fill") {
                    viewModel.showingStats = true
                }
                glassButton(title: "Settings", systemImage: "slider.horizontal.3") {
                    viewModel.showingSettings = true
                }
            }
        }
    }

    private func boardHero(boardSize: CGFloat) -> some View {
        VStack(spacing: 18) {
            BoardView(board: viewModel.board)
                .frame(width: boardSize, height: boardSize)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            handleDrag(value)
                        }
                )

            HStack(spacing: 12) {
                miniStat(title: "Highest Tile", value: "\(viewModel.highestTile)")
                miniStat(title: "Games", value: "\(viewModel.stats.gamesPlayed)")
                miniStat(title: "Moves", value: "\(viewModel.stats.totalMoves)")
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            glassButton(title: "New Game", systemImage: "arrow.clockwise") {
                viewModel.restartGame()
            }
            .frame(maxWidth: .infinity)

            glassButton(title: "Keep Going", systemImage: "sparkle") {
                viewModel.dismissOverlay()
            }
            .frame(maxWidth: .infinity)
            .opacity(viewModel.overlayState == .victory ? 1 : 0.55)
            .disabled(viewModel.overlayState != .victory)
        }
    }

    private var swipeHint: some View {
        Text("Swipe anywhere on the board to move the tiles.")
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.62))
            .padding(.top, 2)
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.60))
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(minWidth: 104, idealWidth: 114, maxWidth: 118, alignment: .leading)
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func miniStat(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.62))
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func glassButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func overlayView(for overlay: GameViewModel.OverlayState) -> some View {
        ZStack {
            Color.black.opacity(0.28).ignoresSafeArea()

            VStack(spacing: 14) {
                Text(overlay == .victory ? "2048 Reached" : "No More Moves")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(overlay == .victory ? "You made it. Keep playing or start fresh." : "Take a breath, then start another run.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white.opacity(0.70))

                HStack(spacing: 12) {
                    glassButton(title: "Dismiss", systemImage: "xmark") {
                        viewModel.dismissOverlay()
                    }
                    glassButton(title: "Restart", systemImage: "arrow.clockwise") {
                        viewModel.restartGame()
                    }
                }
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            )
            .padding(.horizontal, 28)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    private var settingsSheet: some View {
        NavigationStack {
            Form {
                Toggle("Sound", isOn: Binding(
                    get: { viewModel.settings.soundEnabled },
                    set: {
                        viewModel.settings.soundEnabled = $0
                        viewModel.saveSettings()
                    }
                ))
                Toggle("Haptics", isOn: Binding(
                    get: { viewModel.settings.hapticsEnabled },
                    set: {
                        viewModel.settings.hapticsEnabled = $0
                        viewModel.saveSettings()
                    }
                ))
            }
            .navigationTitle("Settings")
        }
    }

    private var statsSheet: some View {
        NavigationStack {
            List {
                statRow(title: "Best Score", value: "\(viewModel.bestScore)")
                statRow(title: "Highest Tile", value: "\(viewModel.highestTile)")
                statRow(title: "Games Played", value: "\(viewModel.stats.gamesPlayed)")
                statRow(title: "Total Moves", value: "\(viewModel.stats.totalMoves)")
            }
            .navigationTitle("Stats")
        }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }

    private func handleDrag(_ value: DragGesture.Value) {
        let horizontal = value.translation.width
        let vertical = value.translation.height

        if abs(horizontal) > abs(vertical) {
            viewModel.handleSwipe(horizontal > 0 ? .right : .left)
        } else {
            viewModel.handleSwipe(vertical > 0 ? .down : .up)
        }
    }
}

#Preview {
    ContentView()
}
