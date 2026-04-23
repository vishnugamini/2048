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
            backgroundLayer

            switch screen {
            case .menu:
                menuScreen
            case .game:
                gameScreen
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    Color(red: 0.08, green: 0.17, blue: 0.27),
                    Color(red: 0.10, green: 0.22, blue: 0.34),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: -150, y: -320)

            Circle()
                .fill(PremiumTheme.accent.opacity(0.16))
                .frame(width: 360, height: 360)
                .blur(radius: 120)
                .offset(x: 180, y: 340)

            RoundedRectangle(cornerRadius: 140, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .frame(width: 250, height: 680)
                .blur(radius: 50)
                .rotationEffect(.degrees(24))
                .offset(x: 170, y: -50)
        }
    }

    private var menuScreen: some View {
        GeometryReader { proxy in
            let safeTop = proxy.safeAreaInsets.top
            let safeBottom = max(proxy.safeAreaInsets.bottom, 24)
            let sidePadding: CGFloat = 24
            let boardSize = min(proxy.size.width - (sidePadding * 2), proxy.size.height * 0.42)

            VStack(spacing: 0) {
                HStack {
                    Text("2048")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    scoreBadge(value: viewModel.bestScore)
                }
                .padding(.horizontal, sidePadding)
                .padding(.top, safeTop + 12)

                Spacer(minLength: 18)

                BoardView(board: viewModel.board)
                    .frame(width: boardSize, height: boardSize)
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 24)

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
                .padding(.horizontal, sidePadding)
                .padding(.bottom, safeBottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var gameScreen: some View {
        GeometryReader { proxy in
            let safeTop = proxy.safeAreaInsets.top
            let safeBottom = max(proxy.safeAreaInsets.bottom, 18)
            let sidePadding: CGFloat = 18
            let width = proxy.size.width - (sidePadding * 2)
            let boardSpace = proxy.size.height - safeTop - safeBottom - 178
            let boardSize = min(width, max(280, boardSpace))

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    secondaryIconButton(systemImage: "house") {
                        viewModel.abandonCurrentGame()
                        screen = .menu
                    }

                    Spacer()

                    scoreCard(title: "Score", value: viewModel.score)
                    scoreCard(title: "Best", value: viewModel.bestScore)

                    secondaryIconButton(systemImage: "gearshape") {
                        viewModel.showingSettings = true
                    }
                }
                .padding(.horizontal, sidePadding)
                .padding(.top, safeTop + 10)

                Spacer(minLength: 14)

                BoardView(board: viewModel.board)
                    .frame(width: boardSize, height: boardSize)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 16)
                            .onEnded(handleDrag)
                    )

                Spacer(minLength: 14)

                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        statChip(value: viewModel.highestTile)
                        statChip(value: viewModel.stats.gamesPlayed)
                        statChip(value: viewModel.stats.totalMoves)
                    }

                    HStack(spacing: 12) {
                        secondaryButton(title: "Stats", systemImage: "chart.bar.fill") {
                            viewModel.showingStats = true
                        }
                        primaryButton(title: "New Game", systemImage: "arrow.clockwise") {
                            viewModel.startNewGame()
                        }
                    }
                }
                .padding(.horizontal, sidePadding)
                .padding(.bottom, safeBottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func scoreBadge(value: Int) -> some View {
        Text("Best \(value)")
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            )
    }

    private func scoreCard(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.58))
            Text("\(value)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.55)
        }
        .frame(width: 92, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.11), lineWidth: 1)
        )
    }

    private func statChip(value: Int) -> some View {
        Text("\(value)")
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
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

#Preview {
    ContentView()
}
