import SwiftUI

struct ContentView: View {
    private enum Screen {
        case menu
        case game
    }

    @StateObject private var viewModel = GameViewModel()
    @State private var screen: Screen = .menu

    var body: some View {
        ZStack {
            PremiumTheme.background
                .ignoresSafeArea()

            switch screen {
            case .menu:
                menuScreen
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            case .game:
                gameScreen
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.88), value: screen)
        .sheet(isPresented: $viewModel.showingSettings) {
            settingsSheet
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $viewModel.showingStats) {
            statsSheet
                .presentationDetents([.medium])
        }
        .overlay {
            if let overlay = viewModel.overlayState, screen == .game {
                overlayView(for: overlay)
            }
        }
    }

    private var menuScreen: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: 22) {
                    VStack(spacing: 12) {
                        Text("2048")
                            .font(.system(size: 58, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Premium puzzle design for iPhone.")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.74))

                        Text("Start a fresh run or jump back into the board you left behind.")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.white.opacity(0.58))
                    }

                    VStack(spacing: 14) {
                        primaryButton(title: "New Game", systemImage: "sparkles") {
                            viewModel.startNewGame()
                            screen = .game
                        }

                        primaryButton(title: "Continue", systemImage: "play.fill") {
                            screen = .game
                        }
                        .opacity(viewModel.continueGameAvailable() ? 1 : 0.45)
                        .disabled(!viewModel.continueGameAvailable())

                        HStack(spacing: 12) {
                            secondaryButton(title: "Stats", systemImage: "chart.bar.fill") {
                                viewModel.showingStats = true
                            }
                            secondaryButton(title: "Settings", systemImage: "slider.horizontal.3") {
                                viewModel.showingSettings = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 420)
                .frame(maxWidth: .infinity)

                Spacer(minLength: 0)

                VStack(spacing: 10) {
                    Text("Best Score")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.56))
                    Text("\(viewModel.bestScore)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.bottom, max(proxy.safeAreaInsets.bottom, 28))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var gameScreen: some View {
        GeometryReader { proxy in
            let horizontalPadding: CGFloat = 20
            let contentWidth = proxy.size.width - (horizontalPadding * 2)
            let headerHeight: CGFloat = 172
            let footerHeight: CGFloat = 172
            let availableHeight = proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom - headerHeight - footerHeight
            let boardSize = min(contentWidth, max(250, availableHeight))

            VStack(spacing: 0) {
                gameTopBar
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, proxy.safeAreaInsets.top + 10)
                    .padding(.bottom, 16)

                Spacer(minLength: 0)

                BoardView(board: viewModel.board)
                    .frame(width: boardSize, height: boardSize)
                    .frame(maxWidth: .infinity)
                    .gesture(
                        DragGesture(minimumDistance: 18)
                            .onEnded(handleDrag)
                    )

                Spacer(minLength: 20)

                VStack(spacing: 14) {
                    statsSection

                    HStack(spacing: 12) {
                        secondaryButton(title: "Menu", systemImage: "chevron.left") {
                            viewModel.abandonCurrentGame()
                            screen = .menu
                        }
                        primaryButton(title: "New Game", systemImage: "arrow.clockwise") {
                            viewModel.startNewGame()
                        }
                    }

                    Text("Swipe on the board to move the tiles.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.62))
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, max(proxy.safeAreaInsets.bottom, 18))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var gameTopBar: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("2048")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Focus on the board.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.65))
                }

                Spacer(minLength: 12)

                HStack(spacing: 12) {
                    statPill(title: "Score", value: "\(viewModel.score)")
                    statPill(title: "Best", value: "\(viewModel.bestScore)")
                }
                .frame(maxWidth: 280)
            }

            HStack(spacing: 12) {
                secondaryButton(title: "Stats", systemImage: "chart.bar.fill") {
                    viewModel.showingStats = true
                }
                secondaryButton(title: "Settings", systemImage: "slider.horizontal.3") {
                    viewModel.showingSettings = true
                }
            }
        }
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            miniStat(title: "Highest Tile", value: "\(viewModel.highestTile)")
            miniStat(title: "Games", value: "\(viewModel.stats.gamesPlayed)")
            miniStat(title: "Moves", value: "\(viewModel.stats.totalMoves)")
        }
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.60))
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
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

    private func primaryButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.09, green: 0.11, blue: 0.18))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            LinearGradient(
                colors: [PremiumTheme.accent, Color.white.opacity(0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    private func secondaryButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
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
            Color.black.opacity(0.32).ignoresSafeArea()

            VStack(spacing: 14) {
                Text(overlay == .victory ? "2048 Reached" : "No More Moves")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(overlay == .victory ? "You made it. Keep playing or return to the menu." : "This run is over. Start another or head back to the menu.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white.opacity(0.70))

                HStack(spacing: 12) {
                    secondaryButton(title: "Menu", systemImage: "house") {
                        viewModel.dismissOverlay()
                        viewModel.abandonCurrentGame()
                        screen = .menu
                    }
                    primaryButton(title: "New Game", systemImage: "arrow.clockwise") {
                        viewModel.startNewGame()
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
