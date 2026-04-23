import SwiftUI

struct ContentView: View {
    private enum Screen {
        case menu
        case game
    }

    @StateObject private var viewModel = GameViewModel()
    @State private var screen: Screen = .menu

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundLayer

                switch screen {
                case .menu:
                    menuScreen(in: proxy)
                case .game:
                    gameScreen(in: proxy)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
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

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.08, blue: 0.14),
                    Color(red: 0.07, green: 0.16, blue: 0.26),
                    Color(red: 0.10, green: 0.24, blue: 0.36),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 340, height: 340)
                .blur(radius: 90)
                .offset(x: -160, y: -310)

            Circle()
                .fill(PremiumTheme.accent.opacity(0.18))
                .frame(width: 360, height: 360)
                .blur(radius: 120)
                .offset(x: 180, y: 320)

            RoundedRectangle(cornerRadius: 150, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .frame(width: 280, height: 720)
                .blur(radius: 52)
                .rotationEffect(.degrees(24))
                .offset(x: 170, y: -40)
        }
    }

    private func menuScreen(in proxy: GeometryProxy) -> some View {
        let metrics = LayoutMetrics(proxy: proxy)

        return VStack(spacing: 0) {
            HStack {
                Text("2048")
                    .font(.system(size: metrics.titleSize, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                pill(title: "Best", value: "\(viewModel.bestScore)")
                    .frame(width: metrics.scorePillWidth)
            }
            .padding(.horizontal, metrics.sidePadding)
            .padding(.top, metrics.topPadding)

            Spacer(minLength: metrics.verticalGap)

            VStack(spacing: metrics.menuSpacing) {
                BoardView(board: viewModel.board)
                    .frame(width: metrics.menuBoardSize, height: metrics.menuBoardSize)

                menuButtons(metrics: metrics)
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: metrics.bottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func menuButtons(metrics: LayoutMetrics) -> some View {
        VStack(spacing: metrics.buttonGap) {
            primaryButton(title: "New Game", systemImage: "sparkles") {
                viewModel.startNewGame()
                screen = .game
            }

            primaryButton(title: "Continue", systemImage: "play.fill") {
                screen = .game
            }
            .opacity(viewModel.continueGameAvailable() ? 1 : 0.45)
            .disabled(!viewModel.continueGameAvailable())

            HStack(spacing: metrics.buttonGap) {
                secondaryButton(title: "Stats", systemImage: "chart.bar.fill") {
                    viewModel.showingStats = true
                }
                secondaryButton(title: "Settings", systemImage: "slider.horizontal.3") {
                    viewModel.showingSettings = true
                }
            }
        }
        .padding(.horizontal, metrics.sidePadding)
    }

    private func gameScreen(in proxy: GeometryProxy) -> some View {
        let metrics = LayoutMetrics(proxy: proxy)

        return VStack(spacing: 0) {
            gameTopBar(metrics: metrics)

            Spacer(minLength: metrics.verticalGap)

            BoardView(board: viewModel.board)
                .frame(width: metrics.gameBoardSize, height: metrics.gameBoardSize)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 16)
                        .onEnded(handleDrag)
                )

            Spacer(minLength: metrics.verticalGap)

            gameBottomBar(metrics: metrics)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func gameTopBar(metrics: LayoutMetrics) -> some View {
        HStack(spacing: metrics.buttonGap) {
            secondaryIconButton(systemImage: "house") {
                viewModel.abandonCurrentGame()
                screen = .menu
            }

            Spacer(minLength: metrics.buttonGap)

            pill(title: "Score", value: "\(viewModel.score)")
                .frame(width: metrics.scorePillWidth)
            pill(title: "Best", value: "\(viewModel.bestScore)")
                .frame(width: metrics.scorePillWidth)

            secondaryIconButton(systemImage: "gearshape") {
                viewModel.showingSettings = true
            }
        }
        .padding(.horizontal, metrics.sidePadding)
        .padding(.top, metrics.topPadding)
    }

    private func gameBottomBar(metrics: LayoutMetrics) -> some View {
        VStack(spacing: metrics.buttonGap) {
            HStack(spacing: metrics.buttonGap) {
                statChip(value: viewModel.highestTile, metrics: metrics)
                statChip(value: viewModel.stats.gamesPlayed, metrics: metrics)
                statChip(value: viewModel.stats.totalMoves, metrics: metrics)
            }

            HStack(spacing: metrics.buttonGap) {
                secondaryButton(title: "Stats", systemImage: "chart.bar.fill") {
                    viewModel.showingStats = true
                }
                primaryButton(title: "New Game", systemImage: "arrow.clockwise") {
                    viewModel.startNewGame()
                }
            }
        }
        .padding(.horizontal, metrics.sidePadding)
        .padding(.bottom, metrics.bottomPadding)
    }

    private func pill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.58))
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.55)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.11), lineWidth: 1)
        )
    }

    private func statChip(value: Int, metrics: LayoutMetrics) -> some View {
        Text("\(value)")
            .font(.system(size: metrics.statFontSize, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, metrics.statVerticalPadding)
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
                .foregroundStyle(Color(red: 0.05, green: 0.08, blue: 0.14))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            LinearGradient(
                colors: [Color(red: 0.93, green: 0.97, blue: 1.0), PremiumTheme.accent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 12)
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
                .strokeBorder(Color.white.opacity(0.11), lineWidth: 1)
        )
    }

    private func secondaryIconButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.11), lineWidth: 1)
        )
    }

    private func overlayView(for overlay: GameViewModel.OverlayState) -> some View {
        ZStack {
            Color.black.opacity(0.36).ignoresSafeArea()

            VStack(spacing: 14) {
                Text(overlay == .victory ? "2048" : "Game Over")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

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

private struct LayoutMetrics {
    let proxy: GeometryProxy

    var width: CGFloat { proxy.size.width }
    var height: CGFloat { proxy.size.height }
    var safeWidth: CGFloat { width - proxy.safeAreaInsets.leading - proxy.safeAreaInsets.trailing }
    var safeHeight: CGFloat { height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom }

    private var isShortPhone: Bool { safeHeight < 760 }
    private var isNarrow: Bool { safeWidth < 380 }
    private var isTabletLike: Bool { safeWidth >= 700 }

    var topPadding: CGFloat { proxy.safeAreaInsets.top + (isShortPhone ? 8 : 14) }
    var bottomPadding: CGFloat { max(proxy.safeAreaInsets.bottom, isShortPhone ? 12 : 18) }
    var sidePadding: CGFloat {
        if isTabletLike { return 32 }
        return isNarrow ? 14 : 20
    }
    var verticalGap: CGFloat {
        if isTabletLike { return 22 }
        return isShortPhone ? 10 : 18
    }
    var buttonGap: CGFloat { isShortPhone ? 10 : 12 }
    var menuSpacing: CGFloat { isShortPhone ? 18 : 26 }
    var titleSize: CGFloat {
        if isTabletLike { return 64 }
        return isNarrow ? 38 : 50
    }
    var scorePillWidth: CGFloat { isNarrow ? 86 : 96 }
    var statFontSize: CGFloat { isShortPhone ? 15 : 17 }
    var statVerticalPadding: CGFloat { isShortPhone ? 12 : 14 }

    var menuBoardSize: CGFloat {
        let availableWidth = safeWidth - (sidePadding * 2)
        let availableHeight = safeHeight * (isShortPhone ? 0.28 : 0.34)
        return min(availableWidth, availableHeight, isTabletLike ? 360 : 330)
    }

    var gameBoardSize: CGFloat {
        let topRegion = topPadding + 52
        let bottomRegion = bottomPadding + (isShortPhone ? 108 : 132)
        let availableHeight = safeHeight - topRegion - bottomRegion - (verticalGap * 2)
        let availableWidth = safeWidth - (sidePadding * 2)
        let cap: CGFloat = isTabletLike ? 520 : 430
        return min(availableWidth, availableHeight, cap)
    }
}

#Preview {
    ContentView()
}
