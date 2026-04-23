import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        GeometryReader { proxy in
            let horizontalPadding: CGFloat = 20
            let contentWidth = proxy.size.width - (horizontalPadding * 2)
            let boardSize = min(contentWidth, 520)

            ZStack {
                PremiumTheme.background
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerSection
                        scoreSection(compact: proxy.size.width < 390)
                        boardSection(boardSize: boardSize)
                        statsSection
                        actionSection
                        swipeHint
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, proxy.safeAreaInsets.top + 12)
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom, 24))
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingSettings) {
            settingsSheet
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $viewModel.showingStats) {
            statsSheet
                .presentationDetents([.medium])
        }
        .overlay {
            if let overlay = viewModel.overlayState {
                overlayView(for: overlay)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("2048")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Luxury finish. Clean movement. One more move.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.72))
                }
                Spacer(minLength: 12)
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

    private func scoreSection(compact: Bool) -> some View {
        HStack(spacing: 12) {
            statPill(title: "Score", value: "\(viewModel.score)")
            statPill(title: "Best", value: "\(viewModel.bestScore)")
        }
        .frame(maxWidth: compact ? .infinity : 420, alignment: .leading)
    }

    private func boardSection(boardSize: CGFloat) -> some View {
        BoardView(board: viewModel.board)
            .frame(width: boardSize, height: boardSize)
            .frame(maxWidth: .infinity)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded(handleDrag)
            )
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            miniStat(title: "Highest Tile", value: "\(viewModel.highestTile)")
            miniStat(title: "Games", value: "\(viewModel.stats.gamesPlayed)")
            miniStat(title: "Moves", value: "\(viewModel.stats.totalMoves)")
        }
    }

    private var actionSection: some View {
        VStack(spacing: 12) {
            glassButton(title: "New Game", systemImage: "arrow.clockwise") {
                viewModel.restartGame()
            }

            if viewModel.overlayState == .victory {
                glassButton(title: "Keep Going", systemImage: "sparkle") {
                    viewModel.dismissOverlay()
                }
            }
        }
    }

    private var swipeHint: some View {
        Text("Swipe on the board to move the tiles.")
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.62))
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.60))
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                .minimumScaleFactor(0.7)
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
                .padding(.vertical, 16)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
